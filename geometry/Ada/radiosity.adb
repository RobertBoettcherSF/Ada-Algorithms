--  Package: Radiosity
--  Body: Implementation of Radiosity Global Illumination Solvers
--  Standard: Ada 2023 (ISO/IEC 8652:2023)

with Ada.Numerics.Generic_Elementary_Functions;

package body Radiosity is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   PI_Val : constant Real := 3.14159265358979323846;

   ---------------------------------------------------------------------------
   -- Norm
   ---------------------------------------------------------------------------
   function Norm (V : Vector_3D) return Non_Negative_Real is
      Sum_Sq : constant Real := V.X * V.X + V.Y * V.Y + V.Z * V.Z;
   begin
      if Sum_Sq <= 0.0 then
         return 0.0;
      else
         return Sqrt (Sum_Sq);
      end if;
   end Norm;

   ---------------------------------------------------------------------------
   -- Normalize
   ---------------------------------------------------------------------------
   function Normalize (V : Vector_3D) return Vector_3D is
      Len : constant Non_Negative_Real := Norm (V);
   begin
      if Len = 0.0 then
         raise Invalid_Patch_Error with "Cannot normalize a zero-length vector";
      end if;
      return (X => V.X / Len, Y => V.Y / Len, Z => V.Z / Len);
   end Normalize;

   ---------------------------------------------------------------------------
   -- Is_Valid_Patch
   ---------------------------------------------------------------------------
   function Is_Valid_Patch (P : Patch) return Boolean is
      Normal_Len : constant Real := Norm (P.Normal);
   begin
      if Normal_Len < 0.99 or else Normal_Len > 1.01 then
         return False;
      end if;
      if P.Area <= 0.0 then
         return False;
      end if;
      if P.Albedo < 0.0 or else P.Albedo > 1.0 then
         return False;
      end if;
      if P.Emission < 0.0 then
         return False;
      end if;
      return True;
   end Is_Valid_Patch;

   ---------------------------------------------------------------------------
   -- Is_Valid_Scene
   ---------------------------------------------------------------------------
   function Is_Valid_Scene (Scene : Patch_List) return Boolean is
      Count : constant Natural := Natural (Scene.Length);
   begin
      if Count = 0 then
         return False;
      end if;
      for I in 1 .. Count loop
         declare
            P : constant Patch := Scene.Element (Patch_Id (I));
         begin
            if P.Id /= Patch_Id (I) then
               return False;
            end if;
            if not Is_Valid_Patch (P) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Valid_Scene;

   ---------------------------------------------------------------------------
   -- Compute_Point_Form_Factor
   ---------------------------------------------------------------------------
   function Compute_Point_Form_Factor
     (Source_Center : Vector_3D;
      Source_Normal : Vector_3D;
      Target_Center : Vector_3D;
      Target_Normal : Vector_3D;
      Target_Area   : Positive_Real) return Form_Factor
   is
      Disp : constant Vector_3D := Target_Center - Source_Center;
      Dist : constant Non_Negative_Real := Norm (Disp);
   begin
      --  Coincident or extremely close patches do not transfer via point-to-point
      if Dist < 1.0e-6 then
         return 0.0;
      end if;

      declare
         Inv_Dist : constant Real := 1.0 / Dist;
         Dir      : constant Vector_3D := Inv_Dist * Disp;
         Neg_Dir  : constant Vector_3D := (-1.0) * Dir;

         Cos_Theta_I : constant Real := Dot_Product (Source_Normal, Dir);
         Cos_Theta_J : constant Real := Dot_Product (Target_Normal, Neg_Dir);
      begin
         --  Surface orientation check: radiation only exchanges between mutually facing surfaces
         if Cos_Theta_I <= 0.0 or else Cos_Theta_J <= 0.0 then
            return 0.0;
         end if;

         --  Standard differential area formula:
         --  dF_ij = (cos(theta_i) * cos(theta_j) / (pi * r^2)) * Area_j
         declare
            Geom : constant Real :=
              (Cos_Theta_I * Cos_Theta_J) / (PI_Val * Dist * Dist);
            Val  : constant Real := Geom * Target_Area;
         begin
            if Val <= 0.0 then
               return 0.0;
            elsif Val >= 1.0 then
               return 1.0;
            else
               return Val;
            end if;
         end;
      end;
   end Compute_Point_Form_Factor;

   ---------------------------------------------------------------------------
   -- Compute_Scene_Form_Factors
   ---------------------------------------------------------------------------
   function Compute_Scene_Form_Factors (Scene : Patch_List) return Form_Factor_Matrix is
      N : constant Natural := Natural (Scene.Length);
      Result : Form_Factor_Matrix (1 .. Patch_Id (N), 1 .. Patch_Id (N));
   begin
      for I in 1 .. Patch_Id (N) loop
         for J in 1 .. Patch_Id (N) loop
            if I = J then
               --  Planar patches cannot see themselves
               Result (I, J) := 0.0;
            else
               declare
                  P_I : constant Patch := Scene.Element (I);
                  P_J : constant Patch := Scene.Element (J);
               begin
                  Result (I, J) := Compute_Point_Form_Factor
                    (Source_Center => P_I.Center,
                     Source_Normal => P_I.Normal,
                     Target_Center => P_J.Center,
                     Target_Normal => P_J.Normal,
                     Target_Area   => P_J.Area);
               end;
            end if;
         end loop;
      end loop;
      return Result;
   end Compute_Scene_Form_Factors;

   ---------------------------------------------------------------------------
   -- Solve_Matrix_Direct
   ---------------------------------------------------------------------------
   procedure Solve_Matrix_Direct
     (Scene        : in  Patch_List;
      Form_Factors : in  Form_Factor_Matrix;
      Radiosities  : out Radiosity_Array)
   is
      N : constant Natural := Natural (Scene.Length);
      type Real_Matrix is array (1 .. N, 1 .. N) of Real;
      type Real_Vector is array (1 .. N) of Real;

      A : Real_Matrix;
      B : Real_Vector;
   begin
      if Scene.Is_Empty then
         raise Empty_Scene_Error with "Empty scene provided to direct solver";
      end if;

      --  Construct the linear system:
      --  M_ij = delta_ij - rho_i * F_ij
      --  RHS_i = E_i
      for I in 1 .. N loop
         declare
            P_I : constant Patch := Scene.Element (Patch_Id (I));
         begin
            B (I) := P_I.Emission;
            for J in 1 .. N loop
               if I = J then
                  A (I, J) := 1.0 - (P_I.Albedo * Form_Factors (Patch_Id (I), Patch_Id (J)));
               else
                  A (I, J) := - (P_I.Albedo * Form_Factors (Patch_Id (I), Patch_Id (J)));
               end if;
            end loop;
         end;
      end loop;

      --  Gaussian elimination with partial pivoting
      for K in 1 .. N loop
         --  Locate pivot row
         declare
            Max_Row : Natural := K;
            Max_Val : Real := abs (A (K, K));
         begin
            for Row in K + 1 .. N loop
               if abs (A (Row, K)) > Max_Val then
                  Max_Val := abs (A (Row, K));
                  Max_Row := Row;
               end if;
            end loop;

            if Max_Val < 1.0e-12 then
               raise Matrix_Singular_Error with "Singular matrix in direct radiosity solve";
            end if;

            --  Swap rows in A and B
            if Max_Row /= K then
               for Col in K .. N loop
                  declare
                     Tmp : constant Real := A (K, Col);
                  begin
                     A (K, Col) := A (Max_Row, Col);
                     A (Max_Row, Col) := Tmp;
                  end;
               end loop;
               declare
                  Tmp_B : constant Real := B (K);
               begin
                  B (K) := B (Max_Row);
                  B (Max_Row) := Tmp_B;
               end;
            end if;
         end;

         --  Elimination
         for Row in K + 1 .. N loop
            declare
               Factor : constant Real := A (Row, K) / A (K, K);
            begin
               A (Row, K) := 0.0;
               for Col in K + 1 .. N loop
                  A (Row, Col) := A (Row, Col) - Factor * A (K, Col);
               end loop;
               B (Row) := B (Row) - Factor * B (K);
            end;
         end loop;
      end loop;

      --  Back-substitution
      for I in reverse 1 .. N loop
         declare
            Sum : Real := B (I);
         begin
            for J in I + 1 .. N loop
               Sum := Sum - A (I, J) * B (J);
            end loop;
            B (I) := Sum / A (I, I);
         end;
      end loop;

      --  Store results with non-negative clamp
      for I in 1 .. N loop
         if B (I) < 0.0 then
            Radiosities (Patch_Id (I)) := 0.0;
         else
            Radiosities (Patch_Id (I)) := B (I);
         end if;
      end loop;
   end Solve_Matrix_Direct;

   ---------------------------------------------------------------------------
   -- Solve_Jacobi_Gathering
   ---------------------------------------------------------------------------
   procedure Solve_Jacobi_Gathering
     (Scene        : in  Patch_List;
      Form_Factors : in  Form_Factor_Matrix;
      Max_Steps    : in  Positive;
      Tolerance    : in  Positive_Real;
      Radiosities  : out Radiosity_Array;
      Steps_Done   : out Natural)
   is
      N : constant Natural := Natural (Scene.Length);
      Current_B : Radiosity_Array (1 .. Patch_Id (N));
      Next_B    : Radiosity_Array (1 .. Patch_Id (N));
      Max_Diff  : Real;
   begin
      --  Initialize with self-emission E_i
      for I in 1 .. Patch_Id (N) loop
         Current_B (I) := Scene.Element (I).Emission;
      end loop;

      Steps_Done := 0;

      for Step in 1 .. Max_Steps loop
         Steps_Done := Step;
         Max_Diff := 0.0;

         for I in 1 .. Patch_Id (N) loop
            declare
               P_I : constant Patch := Scene.Element (I);
               Incident_Flux : Real := 0.0;
            begin
               --  Gather synchronous contributions from previous iteration
               for J in 1 .. Patch_Id (N) loop
                  Incident_Flux := Incident_Flux + Form_Factors (I, J) * Current_B (J);
               end loop;

               Next_B (I) := P_I.Emission + (P_I.Albedo * Incident_Flux);

               declare
                  Diff : constant Real := abs (Next_B (I) - Current_B (I));
               begin
                  if Diff > Max_Diff then
                     Max_Diff := Diff;
                  end if;
               end;
            end;
         end loop;

         Current_B := Next_B;

         if Max_Diff < Tolerance then
            exit;
         end if;
      end loop;

      Radiosities := Current_B;
   end Solve_Jacobi_Gathering;

   ---------------------------------------------------------------------------
   -- Solve_Gauss_Seidel
   ---------------------------------------------------------------------------
   procedure Solve_Gauss_Seidel
     (Scene        : in  Patch_List;
      Form_Factors : in  Form_Factor_Matrix;
      Max_Steps    : in  Positive;
      Tolerance    : in  Positive_Real;
      Radiosities  : out Radiosity_Array;
      Steps_Done   : out Natural)
   is
      N : constant Natural := Natural (Scene.Length);
      B : Radiosity_Array (1 .. Patch_Id (N));
      Max_Diff : Real;
   begin
      for I in 1 .. Patch_Id (N) loop
         B (I) := Scene.Element (I).Emission;
      end loop;

      Steps_Done := 0;

      for Step in 1 .. Max_Steps loop
         Steps_Done := Step;
         Max_Diff := 0.0;

         for I in 1 .. Patch_Id (N) loop
            declare
               P_I : constant Patch := Scene.Element (I);
               Incident_Flux : Real := 0.0;
               Old_Val : constant Real := B (I);
               New_Val : Real;
            begin
               --  Asynchronous in-place gathering: uses updated values as soon as available
               for J in 1 .. Patch_Id (N) loop
                  Incident_Flux := Incident_Flux + Form_Factors (I, J) * B (J);
               end loop;

               New_Val := P_I.Emission + (P_I.Albedo * Incident_Flux);
               B (I) := New_Val;

               declare
                  Diff : constant Real := abs (New_Val - Old_Val);
               begin
                  if Diff > Max_Diff then
                     Max_Diff := Diff;
                  end if;
               end;
            end;
         end loop;

         if Max_Diff < Tolerance then
            exit;
         end if;
      end loop;

      Radiosities := B;
   end Solve_Gauss_Seidel;

   ---------------------------------------------------------------------------
   -- Solve_Progressive_Shooting
   ---------------------------------------------------------------------------
   procedure Solve_Progressive_Shooting
     (Scene        : in  Patch_List;
      Form_Factors : in  Form_Factor_Matrix;
      Max_Steps    : in  Positive;
      Tolerance    : in  Positive_Real;
      Radiosities  : out Radiosity_Array;
      Steps_Done   : out Natural)
   is
      N : constant Natural := Natural (Scene.Length);
      Total_B   : Radiosity_Array (1 .. Patch_Id (N));
      Unshot_B  : Radiosity_Array (1 .. Patch_Id (N));
   begin
      for I in 1 .. Patch_Id (N) loop
         Total_B (I)  := Scene.Element (I).Emission;
         Unshot_B (I) := Scene.Element (I).Emission;
      end loop;

      Steps_Done := 0;

      for Step in 1 .. Max_Steps loop
         Steps_Done := Step;

         --  Select shooter patch with maximum unshot power: Delta_B_i * Area_i
         declare
            Shooter      : Patch_Id := 1;
            Max_Power    : Real := 0.0;
         begin
            for I in 1 .. Patch_Id (N) loop
               declare
                  P_I   : constant Patch := Scene.Element (I);
                  Power : constant Real := Unshot_B (I) * P_I.Area;
               begin
                  if Power > Max_Power then
                     Max_Power := Power;
                     Shooter   := I;
                  end if;
               end;
            end loop;

            --  Termination if the maximum unshot energy falls below threshold
            if Max_Power < Tolerance then
               exit;
            end if;

            declare
               Shooter_Patch : constant Patch := Scene.Element (Shooter);
               Shooting_Flux : constant Real := Unshot_B (Shooter);
            begin
               Unshot_B (Shooter) := 0.0;

               --  Shoot energy to all other receiving patches
               --  Using reciprocity: A_j * F_ji = A_i * F_ij
               --  Energy received by j from i is: Delta_B_i * (A_i / A_j) * F_ij
               for J in 1 .. Patch_Id (N) loop
                  if J /= Shooter then
                     declare
                        P_J : constant Patch := Scene.Element (J);
                        --  F_Shooter_To_J: fraction leaving Shooter hitting J
                        F_Shooter_J : constant Form_Factor :=
                          Form_Factors (Shooter, J);
                        --  Fraction leaving Shooter arriving at J per unit area of J:
                        Delta_Rad : constant Real :=
                          P_J.Albedo * Shooting_Flux * (Shooter_Patch.Area / P_J.Area) * F_Shooter_J;
                     begin
                        Total_B (J)  := Total_B (J) + Delta_Rad;
                        Unshot_B (J) := Unshot_B (J) + Delta_Rad;
                     end;
                  end if;
               end loop;
            end;
         end;
      end loop;

      Radiosities := Total_B;
   end Solve_Progressive_Shooting;

   ---------------------------------------------------------------------------
   -- Compute_Single_Bounce
   ---------------------------------------------------------------------------
   function Compute_Single_Bounce
     (Scene        : Patch_List;
      Form_Factors : Form_Factor_Matrix) return Radiosity_Array
   is
      N : constant Natural := Natural (Scene.Length);
      Result : Radiosity_Array (1 .. Patch_Id (N));
   begin
      for I in 1 .. Patch_Id (N) loop
         declare
            P_I : constant Patch := Scene.Element (I);
            Incident : Real := 0.0;
         begin
            for J in 1 .. Patch_Id (N) loop
               Incident := Incident + Form_Factors (I, J) * Scene.Element (J).Emission;
            end loop;
            Result (I) := P_I.Emission + (P_I.Albedo * Incident);
         end;
      end loop;
      return Result;
   end Compute_Single_Bounce;

   ---------------------------------------------------------------------------
   -- Total_Emitted_Power
   ---------------------------------------------------------------------------
   function Total_Emitted_Power (Scene : Patch_List) return Non_Negative_Real is
      Total : Real := 0.0;
   begin
      for I in 1 .. Natural (Scene.Length) loop
         declare
            P : constant Patch := Scene.Element (Patch_Id (I));
         begin
            Total := Total + (P.Emission * P.Area);
         end;
      end loop;
      return Total;
   end Total_Emitted_Power;

   ---------------------------------------------------------------------------
   -- Total_Scene_Power
   ---------------------------------------------------------------------------
   function Total_Scene_Power
     (Scene       : Patch_List;
      Radiosities : Radiosity_Array) return Non_Negative_Real
   is
      Total : Real := 0.0;
   begin
      for I in 1 .. Natural (Scene.Length) loop
         declare
            P : constant Patch := Scene.Element (Patch_Id (I));
         begin
            Total := Total + (Radiosities (Patch_Id (I)) * P.Area);
         end;
      end loop;
      return Total;
   end Total_Scene_Power;

end Radiosity;
