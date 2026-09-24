--  Ordered_Subset_EM body — Hudson & Larkin OSEM / Shepp–Vardi MLEM.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Ordered_Subset_EM
  with SPARK_Mode => Off
is

   use Ada.Numerics.Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   procedure Enforce_Nonnegative (X : in out Image) is
   begin
      for J in X'Range loop
         if X (J) < 0.0 then
            X (J) := 0.0;
         end if;
      end loop;
   end Enforce_Nonnegative;

   function Zero_Image (J : Positive) return Image is
   begin
      if J > Max_Pixels then
         raise Capacity_Exceeded with "Zero_Image: J > Max_Pixels";
      end if;
      return [for K in 1 .. J => 0.0];
   end Zero_Image;

   function Zero_Projection (I : Positive) return Projection is
   begin
      if I > Max_Bins then
         raise Capacity_Exceeded with "Zero_Projection: I > Max_Bins";
      end if;
      return [for K in 1 .. I => 0.0];
   end Zero_Projection;

   function Zero_Matrix (I, J : Positive) return System_Matrix is
   begin
      if I > Max_Bins or else J > Max_Pixels then
         raise Capacity_Exceeded with "Zero_Matrix: capacity";
      end if;
      return [for R in 1 .. I => [for C in 1 .. J => 0.0]];
   end Zero_Matrix;

   function Ones_Image
     (J : Positive; Value : Real := 1.0) return Image
   is
   begin
      if J > Max_Pixels then
         raise Capacity_Exceeded with "Ones_Image: capacity";
      end if;
      return [for K in 1 .. J => Value];
   end Ones_Image;

   ---------------------------------------------------------------------------
   -- Forward / back / sensitivity
   ---------------------------------------------------------------------------

   function Forward_Project
     (A : System_Matrix;
      X : Image) return Projection
   is
      Y : Projection (A'Range (1));
      Acc : Real;
   begin
      if A'Length (2) /= X'Length or else A'First (2) /= X'First then
         raise Invalid_Argument with "Forward_Project: dim mismatch";
      end if;
      for I in A'Range (1) loop
         Acc := 0.0;
         for J in X'Range loop
            Acc := Acc + A (I, J) * X (J);
         end loop;
         Y (I) := Acc;
      end loop;
      return Y;
   end Forward_Project;

   function Back_Project
     (A : System_Matrix;
      Y : Projection) return Image
   is
      B : Image (A'Range (2));
      Acc : Real;
   begin
      if A'Length (1) /= Y'Length or else A'First (1) /= Y'First then
         raise Invalid_Argument with "Back_Project: dim mismatch";
      end if;
      for J in A'Range (2) loop
         Acc := 0.0;
         for I in Y'Range loop
            Acc := Acc + A (I, J) * Y (I);
         end loop;
         B (J) := Acc;
      end loop;
      return B;
   end Back_Project;

   function Back_Project_Subset
     (A         : System_Matrix;
      Y         : Projection;
      Subsets   : Subset_Map;
      Subset_Id : Subset_Index) return Image
   is
      B : Image (A'Range (2));
      Acc : Real;
   begin
      if A'Length (1) /= Y'Length
        or else Y'Length /= Subsets'Length
        or else A'First (1) /= Y'First
        or else Y'First /= Subsets'First
      then
         raise Invalid_Argument with "Back_Project_Subset: dim mismatch";
      end if;
      for J in A'Range (2) loop
         Acc := 0.0;
         for I in Y'Range loop
            if Subsets (I) = Subset_Id then
               Acc := Acc + A (I, J) * Y (I);
            end if;
         end loop;
         B (J) := Acc;
      end loop;
      return B;
   end Back_Project_Subset;

   function Sensitivity (A : System_Matrix) return Image is
      S : Image (A'Range (2));
      Acc : Real;
   begin
      for J in A'Range (2) loop
         Acc := 0.0;
         for I in A'Range (1) loop
            Acc := Acc + A (I, J);
         end loop;
         S (J) := Acc;
      end loop;
      return S;
   end Sensitivity;

   function Sensitivity_Subset
     (A         : System_Matrix;
      Subsets   : Subset_Map;
      Subset_Id : Subset_Index) return Image
   is
      S : Image (A'Range (2));
      Acc : Real;
   begin
      if A'Length (1) /= Subsets'Length
        or else A'First (1) /= Subsets'First
      then
         raise Invalid_Argument with "Sensitivity_Subset: dim mismatch";
      end if;
      for J in A'Range (2) loop
         Acc := 0.0;
         for I in Subsets'Range loop
            if Subsets (I) = Subset_Id then
               Acc := Acc + A (I, J);
            end if;
         end loop;
         S (J) := Acc;
      end loop;
      return S;
   end Sensitivity_Subset;

   ---------------------------------------------------------------------------
   -- Ratio vector for EM updates: r_i = y_i / ŷ_i (with zero care)
   ---------------------------------------------------------------------------

   function Ratio_Vector
     (Y_Obs : Projection;
      Y_Hat : Projection) return Projection
   is
      R : Projection (Y_Obs'Range);
   begin
      for I in Y_Obs'Range loop
         if abs (Y_Hat (I)) <= Zero_Proj_Tol then
            --  If observation also ~0, ratio contributes nothing; else
            --  model cannot explain counts — skip (ratio 0) for stability.
            R (I) := 0.0;
         else
            R (I) := Y_Obs (I) / Y_Hat (I);
         end if;
      end loop;
      return R;
   end Ratio_Vector;

   ---------------------------------------------------------------------------
   -- Monitors
   ---------------------------------------------------------------------------

   function Poisson_NLL
     (Y_Obs : Projection;
      Y_Hat : Projection) return Real
   is
      Acc : Real := 0.0;
      Yi, Yh : Real;
   begin
      for I in Y_Obs'Range loop
         Yi := Y_Obs (I);
         Yh := Y_Hat (I);
         if Yh <= Zero_Proj_Tol then
            if Yi > Zero_Proj_Tol then
               Acc := Acc + 1.0E6;  --  large penalty
            end if;
         else
            Acc := Acc + Yh - Yi * Real (Log (Float (Yh)));
         end if;
      end loop;
      return Acc;
   end Poisson_NLL;

   function KL_Divergence
     (Y_Obs : Projection;
      Y_Hat : Projection) return Real
   is
      Acc : Real := 0.0;
      Yi, Yh : Real;
   begin
      for I in Y_Obs'Range loop
         Yi := Y_Obs (I);
         Yh := Y_Hat (I);
         if Yi <= Zero_Proj_Tol then
            Acc := Acc + Yh;  --  0·log(...) → 0; −0 + ŷ
         elsif Yh <= Zero_Proj_Tol then
            Acc := Acc + 1.0E6;
         else
            Acc := Acc
              + Yi * Real (Log (Float (Yi / Yh)))
              - Yi
              + Yh;
         end if;
      end loop;
      if Acc < 0.0 then
         return 0.0;  --  numerical floor
      end if;
      return Acc;
   end KL_Divergence;

   function RMSE (X, Truth : Image) return Real is
      Acc : Real := 0.0;
      D   : Real;
      N   : constant Real := Real (X'Length);
   begin
      for J in X'Range loop
         D := X (J) - Truth (J);
         Acc := Acc + D * D;
      end loop;
      return Real (Sqrt (Float (Acc / N)));
   end RMSE;

   ---------------------------------------------------------------------------
   -- MLEM
   ---------------------------------------------------------------------------

   procedure MLEM_Step
     (X : in out Image;
      A : System_Matrix;
      Y : Projection)
   is
      Y_Hat : constant Projection := Forward_Project (A, X);
      Ratio : constant Projection := Ratio_Vector (Y, Y_Hat);
      Sens  : constant Image := Sensitivity (A);
      Corr  : constant Image := Back_Project (A, Ratio);
      Any_Sens : Boolean := False;
   begin
      for J in X'Range loop
         if Sens (J) > Zero_Proj_Tol then
            Any_Sens := True;
            X (J) := X (J) / Sens (J) * Corr (J);
         end if;
         --  else leave X (J) unchanged (unobserved pixel)
      end loop;
      if not Any_Sens then
         raise Degenerate_Geometry with "MLEM_Step: all sensitivities zero";
      end if;
      Enforce_Nonnegative (X);
   end MLEM_Step;

   procedure MLEM_Iterate
     (X          : in out Image;
      A          : System_Matrix;
      Y          : Projection;
      Iterations : Positive)
   is
   begin
      for K in 1 .. Iterations loop
         MLEM_Step (X, A, Y);
      end loop;
   end MLEM_Iterate;

   ---------------------------------------------------------------------------
   -- Ordered subsets
   ---------------------------------------------------------------------------

   function Make_Ordered_Subsets
     (I_Bins : Positive;
      M      : Positive;
      Kind   : Subset_Kind := Contiguous) return Subset_Map
   is
   begin
      if I_Bins > Max_Bins or else M > Max_Subsets then
         raise Capacity_Exceeded with "Make_Ordered_Subsets: capacity";
      end if;
      if M > I_Bins then
         raise Invalid_Argument
           with "Make_Ordered_Subsets: M > I_Bins (empty subset)";
      end if;
      declare
         Map : Subset_Map (1 .. I_Bins);
         Base, Extra, Idx, Take : Natural;
         Start : Natural;
      begin
         case Kind is
            when Interleaved =>
               for I in 1 .. I_Bins loop
                  Map (I) := Subset_Index (1 + ((I - 1) mod M));
               end loop;

            when Contiguous =>
               Base := I_Bins / M;
               Extra := I_Bins mod M;
               Idx  := 1;
               for S in 1 .. M loop
                  Take := Base;
                  if S <= Extra then
                     Take := Take + 1;
                  end if;
                  Start := Idx;
                  for K in 0 .. Take - 1 loop
                     Map (Start + K) := Subset_Index (S);
                  end loop;
                  Idx := Idx + Take;
               end loop;
         end case;
         return Map;
      end;
   end Make_Ordered_Subsets;

   function Subset_Covers_Exactly_Once
     (Subsets : Subset_Map;
      M       : Subset_Count) return Boolean
   is
      Counts : array (1 .. M) of Natural := [others => 0];
   begin
      for I in Subsets'Range loop
         if Natural (Subsets (I)) > M then
            return False;
         end if;
         Counts (Subsets (I)) := Counts (Subsets (I)) + 1;
      end loop;
      for S in 1 .. M loop
         if Counts (S) = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Subset_Covers_Exactly_Once;

   procedure OSEM_Step_Subset
     (X         : in out Image;
      A         : System_Matrix;
      Y         : Projection;
      Subsets   : Subset_Map;
      Subset_Id : Subset_Index)
   is
      Y_Hat : constant Projection := Forward_Project (A, X);
      Ratio : constant Projection := Ratio_Vector (Y, Y_Hat);
      Sens  : constant Image :=
        Sensitivity_Subset (A, Subsets, Subset_Id);
      Corr  : constant Image :=
        Back_Project_Subset (A, Ratio, Subsets, Subset_Id);
   begin
      for J in X'Range loop
         if Sens (J) > Zero_Proj_Tol then
            X (J) := X (J) / Sens (J) * Corr (J);
         end if;
      end loop;
      Enforce_Nonnegative (X);
   end OSEM_Step_Subset;

   procedure OSEM_Iterate
     (X          : in out Image;
      A          : System_Matrix;
      Y          : Projection;
      Subsets    : Subset_Map;
      M          : Subset_Count;
      Iterations : Positive)
   is
   begin
      if M = 0 then
         raise Invalid_Argument with "OSEM_Iterate: M = 0";
      end if;
      if not Subset_Covers_Exactly_Once (Subsets, M) then
         raise Invalid_Argument
           with "OSEM_Iterate: invalid subset partition";
      end if;
      for K in 1 .. Iterations loop
         for S in 1 .. M loop
            OSEM_Step_Subset (X, A, Y, Subsets, Subset_Index (S));
         end loop;
      end loop;
   end OSEM_Iterate;

   ---------------------------------------------------------------------------
   -- Toy geometry
   ---------------------------------------------------------------------------

   function Make_1D_Strip_Matrix
     (J_Pixels : Positive;
      I_Bins   : Positive) return System_Matrix
   is
   begin
      if J_Pixels > Max_Pixels or else I_Bins > Max_Bins then
         raise Capacity_Exceeded with "Make_1D_Strip_Matrix: capacity";
      end if;
      declare
         A : System_Matrix (1 .. I_Bins, 1 .. J_Pixels);
         --  Window half-width in pixel units (at least 1).
         Half : constant Natural :=
           Natural'Max (1, (J_Pixels + I_Bins - 1) / I_Bins);
         Center : Real;
         Dist   : Real;
         W      : Real;
      begin
      for I in 1 .. I_Bins loop
         --  Bin centers evenly spaced over [1, J].
         if I_Bins = 1 then
            Center := Real (J_Pixels + 1) / 2.0;
         else
            Center := 1.0
              + Real (I - 1) * Real (J_Pixels - 1) / Real (I_Bins - 1);
         end if;
         for J in 1 .. J_Pixels loop
            Dist := abs (Real (J) - Center);
            if Dist <= Real (Half) then
               W := 1.0 - Dist / Real (Half + 1);
               if W < 0.0 then
                  W := 0.0;
               end if;
               A (I, J) := W;
            else
               A (I, J) := 0.0;
            end if;
         end loop;
      end loop;
      return A;
      end;
   end Make_1D_Strip_Matrix;

   function Make_2D_Parallel_Beam_Matrix
     (N_Side   : Positive;
      N_Angles : Positive;
      N_Rays   : Positive) return System_Matrix
   is
      J_Pix : constant Positive := N_Side * N_Side;
      I_Bin : constant Positive := N_Angles * N_Rays;
   begin
      if J_Pix > Max_Pixels or else I_Bin > Max_Bins then
         raise Capacity_Exceeded
           with "Make_2D_Parallel_Beam_Matrix: capacity";
      end if;
      declare
         A : System_Matrix (1 .. I_Bin, 1 .. J_Pix);
         Pi : constant Float := 3.141592653589793;
         Ang, Cx, Cy, Tx, Ty, Proj, Ray_Pos, Dist, W : Float;
         Bin : Positive;
         Pix : Positive;
         Half_Ray : constant Float := Float (N_Side) / 2.0;
      begin

      for Ang_Idx in 0 .. N_Angles - 1 loop
         Ang := Float (Ang_Idx) * Pi / Float (N_Angles);
         for Ray_Idx in 0 .. N_Rays - 1 loop
            Bin := Ang_Idx * N_Rays + Ray_Idx + 1;
            Ray_Pos := -Half_Ray
              + (Float (Ray_Idx) + 0.5) * Float (N_Side) / Float (N_Rays);
            for Row in 0 .. N_Side - 1 loop
               for Col in 0 .. N_Side - 1 loop
                  Pix := Row * N_Side + Col + 1;
                  --  Pixel center in [-Half_Ray+0.5, ...]
                  Cx := Float (Col) + 0.5 - Half_Ray;
                  Cy := Float (Row) + 0.5 - Half_Ray;
                  --  Project onto detector axis perpendicular to angle.
                  Tx := Cos (Ang);
                  Ty := Sin (Ang);
                  Proj := Cx * (-Ty) + Cy * Tx;  --  perpendicular coord
                  Dist := abs (Proj - Ray_Pos);
                  if Dist < 1.0 then
                     W := 1.0 - Dist;
                     if W < 0.0 then
                        W := 0.0;
                     end if;
                     A (Bin, Pix) := Real (W);
                  else
                     A (Bin, Pix) := 0.0;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      return A;
      end;
   end Make_2D_Parallel_Beam_Matrix;

   function Make_Box_Phantom_1D (J_Pixels : Positive) return Image is
   begin
      if J_Pixels > Max_Pixels then
         raise Capacity_Exceeded with "Make_Box_Phantom_1D: capacity";
      end if;
      declare
         X : Image (1 .. J_Pixels);
         Lo, Hi : Positive;
      begin
      Lo := J_Pixels / 4 + 1;
      Hi := (3 * J_Pixels) / 4;
      for J in 1 .. J_Pixels loop
         if J >= Lo and then J <= Hi then
            X (J) := 4.0;
         else
            X (J) := 0.5;
         end if;
      end loop;
      return X;
      end;
   end Make_Box_Phantom_1D;

   function Make_Box_Phantom_2D (N_Side : Positive) return Image is
      J_Pix : constant Positive := N_Side * N_Side;
   begin
      if J_Pix > Max_Pixels then
         raise Capacity_Exceeded with "Make_Box_Phantom_2D: capacity";
      end if;
      declare
         X : Image (1 .. J_Pix);
         R, C : Natural;
         Lo, Hi : Natural;
      begin
      Lo := N_Side / 4;
      Hi := (3 * N_Side) / 4;
      for Row in 0 .. N_Side - 1 loop
         for Col in 0 .. N_Side - 1 loop
            R := Row;
            C := Col;
            if R >= Lo and then R < Hi
              and then C >= Lo and then C < Hi
            then
               X (Row * N_Side + Col + 1) := 5.0;
            else
               X (Row * N_Side + Col + 1) := 0.2;
            end if;
         end loop;
      end loop;
      return X;
      end;
   end Make_Box_Phantom_2D;

end Ordered_Subset_EM;
