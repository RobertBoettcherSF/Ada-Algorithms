--  Implementation of Variational_Method (calculus of variations + QM trial).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Variational_Method
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   function Sqrt (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (X)));
   end Sqrt;

   function Sin (X : Real) return Real is
   begin
      return Real (Math.Sin (Long_Float (X)));
   end Sin;

   function Exp (X : Real) return Real is
   begin
      if X < -80.0 then
         return 0.0;
      elsif X > 80.0 then
         return Real'Last / 4.0;
      end if;
      return Real (Math.Exp (Long_Float (X)));
   end Exp;

   Pi : constant Real := 3.14159265358979323846;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Clamp (V, Lo, Hi : Real) return Real is
   begin
      if V < Lo then
         return Lo;
      elsif V > Hi then
         return Hi;
      else
         return V;
      end if;
   end Clamp;

   -------------------------------------------------------------------------
   -- Path construction
   -------------------------------------------------------------------------

   function Linear_Interpolation_Y
     (X0, Y0, X1, Y1, X : Real) return Real
   is
      T : constant Real := (X - X0) / (X1 - X0);
   begin
      return Y0 + T * (Y1 - Y0);
   end Linear_Interpolation_Y;

   function Straight_Line_Path
     (X0, Y0, X1, Y1 : Real;
      N              : Point_Count) return Path
   is
      Result : Path (1 .. N);
      T      : Real;
   begin
      for I in 1 .. N loop
         T := Real (I - 1) / Real (N - 1);
         Result (I).X := X0 + T * (X1 - X0);
         Result (I).Y := Y0 + T * (Y1 - Y0);
      end loop;
      return Result;
   end Straight_Line_Path;

   function Bowed_Path
     (X0, Y0, X1, Y1 : Real;
      N              : Point_Count;
      Amplitude      : Real) return Path
   is
      Result : Path (1 .. N);
      T      : Real;
   begin
      for I in 1 .. N loop
         T := Real (I - 1) / Real (N - 1);
         Result (I).X := X0 + T * (X1 - X0);
         Result (I).Y := Y0 + T * (Y1 - Y0)
           + Amplitude * Sin (Pi * T);
      end loop;
      return Result;
   end Bowed_Path;

   -------------------------------------------------------------------------
   -- Functionals
   -------------------------------------------------------------------------

   function Segment_Count (P : Path) return Natural is
   begin
      if P'Length = 0 then
         return 0;
      else
         return P'Length - 1;
      end if;
   end Segment_Count;

   function Path_Length (P : Path) return Non_Negative is
      Acc : Real := 0.0;
      DX, DY : Real;
   begin
      if P'Length <= 1 then
         return 0.0;
      end if;
      for I in P'First .. P'Last - 1 loop
         DX := P (I + 1).X - P (I).X;
         DY := P (I + 1).Y - P (I).Y;
         Acc := Acc + Sqrt (DX * DX + DY * DY);
      end loop;
      return Acc;
   end Path_Length;

   function Dirichlet_Energy (P : Path) return Non_Negative is
      Acc : Real := 0.0;
      DX, DY : Real;
   begin
      for I in P'First .. P'Last - 1 loop
         DX := P (I + 1).X - P (I).X;
         DY := P (I + 1).Y - P (I).Y;
         if abs (DX) < 1.0E-30 then
            raise Degenerate;
         end if;
         Acc := Acc + (DY * DY) / abs (DX);
      end loop;
      return Acc;
   end Dirichlet_Energy;

   function Functional_Trapezoid_Arc (P : Path) return Non_Negative is
   begin
      return Path_Length (P);
   end Functional_Trapezoid_Arc;

   function Functional_Trapezoid_Dirichlet (P : Path) return Non_Negative is
   begin
      return Dirichlet_Energy (P);
   end Functional_Trapezoid_Dirichlet;

   function Uniform_DX (P : Path) return Boolean is
      Ref, DX : Real;
   begin
      if P'Length < 3 then
         return True;
      end if;
      Ref := P (P'First + 1).X - P (P'First).X;
      for I in P'First + 1 .. P'Last - 1 loop
         DX := P (I + 1).X - P (I).X;
         if abs (DX - Ref) > 1.0E-9 * (1.0 + abs (Ref)) then
            return False;
         end if;
      end loop;
      return True;
   end Uniform_DX;

   function Functional_Simpson_Arc (P : Path) return Non_Negative is
      N   : constant Natural := P'Length;
      Acc : Real := 0.0;
      DX  : Real;
      YP  : Real;
      W   : Real;
      H   : Real;
   begin
      if not Uniform_DX (P) or else N < 3 or else (N mod 2) = 0 then
         return Path_Length (P);
      end if;
      H := P (P'First + 1).X - P (P'First).X;
      --  Composite Simpson on L(x) = √(1+(y')²) with centered differences.
      for K in 0 .. N - 1 loop
         declare
            I : constant Point_Index := Point_Index (P'First + K);
         begin
            if I = P'First then
               YP := (P (I + 1).Y - P (I).Y) / H;
            elsif I = P'Last then
               YP := (P (I).Y - P (I - 1).Y) / H;
            else
               YP := (P (I + 1).Y - P (I - 1).Y) / (2.0 * H);
            end if;
            if K = 0 or else K = N - 1 then
               W := 1.0;
            elsif (K mod 2) = 1 then
               W := 4.0;
            else
               W := 2.0;
            end if;
            Acc := Acc + W * Sqrt (1.0 + YP * YP);
         end;
      end loop;
      DX := H / 3.0;
      return Acc * DX;
   end Functional_Simpson_Arc;

   -------------------------------------------------------------------------
   -- Euler–Lagrange residuals
   -------------------------------------------------------------------------

   function Mean_Abs_Second_Difference (P : Path) return Non_Negative is
      Acc : Real := 0.0;
      Cnt : Natural := 0;
      D2  : Real;
      H   : Real;
      Scale : Real;
   begin
      H := P (P'First + 1).X - P (P'First).X;
      if abs (H) < 1.0E-30 then
         raise Degenerate;
      end if;
      Scale := 1.0 / (H * H);
      for I in P'First + 1 .. P'Last - 1 loop
         D2 := (P (I + 1).Y - 2.0 * P (I).Y + P (I - 1).Y) * Scale;
         Acc := Acc + abs (D2);
         Cnt := Cnt + 1;
      end loop;
      if Cnt = 0 then
         return 0.0;
      end if;
      return Acc / Real (Cnt);
   end Mean_Abs_Second_Difference;

   function Euler_Lagrange_Residual_Dirichlet
     (P : Path) return Non_Negative
   is
   begin
      return Mean_Abs_Second_Difference (P);
   end Euler_Lagrange_Residual_Dirichlet;

   function Length_Partial_Y
     (P : Path; I : Point_Index) return Real
   is
      --  Analytic ∂/∂y_i of sum of segment lengths (endpoints excluded).
      Xm, Xp, Ym, Yp, Yi : Real;
      L_Left, L_Right : Real;
      G : Real := 0.0;
   begin
      Yi := P (I).Y;
      if I > P'First then
         Xm := P (I - 1).X;
         Ym := P (I - 1).Y;
         L_Left := Sqrt ((P (I).X - Xm) ** 2 + (Yi - Ym) ** 2);
         if L_Left > 1.0E-30 then
            G := G + (Yi - Ym) / L_Left;
         end if;
      end if;
      if I < P'Last then
         Xp := P (I + 1).X;
         Yp := P (I + 1).Y;
         L_Right := Sqrt ((Xp - P (I).X) ** 2 + (Yp - Yi) ** 2);
         if L_Right > 1.0E-30 then
            G := G + (Yi - Yp) / L_Right;
         end if;
      end if;
      return G;
   end Length_Partial_Y;

   function Dirichlet_Partial_Y
     (P : Path; I : Point_Index) return Real
   is
      --  ∂/∂y_i of Σ (Δy)²/|Δx|.
      G  : Real := 0.0;
      DX : Real;
   begin
      if I > P'First then
         DX := abs (P (I).X - P (I - 1).X);
         if DX > 1.0E-30 then
            G := G + 2.0 * (P (I).Y - P (I - 1).Y) / DX;
         end if;
      end if;
      if I < P'Last then
         DX := abs (P (I + 1).X - P (I).X);
         if DX > 1.0E-30 then
            G := G + 2.0 * (P (I).Y - P (I + 1).Y) / DX;
         end if;
      end if;
      return G;
   end Dirichlet_Partial_Y;

   function Max_Abs_Length_Gradient (P : Path) return Non_Negative is
      M : Real := 0.0;
      G : Real;
   begin
      for I in P'First + 1 .. P'Last - 1 loop
         G := abs (Length_Partial_Y (P, I));
         if G > M then
            M := G;
         end if;
      end loop;
      return M;
   end Max_Abs_Length_Gradient;

   -------------------------------------------------------------------------
   -- Path improvement
   -------------------------------------------------------------------------

   procedure Improve_Path_Gradient
     (P          : in out Path;
      Step       : Real := 0.05;
      Iterations : Natural := 50;
      Objective  : Natural := 0)
   is
      Grad : array (1 .. Max_Points) of Real := [others => 0.0];
      G    : Real;
      Norm : Real;
   begin
      for Iter in 1 .. Iterations loop
         Norm := 0.0;
         for I in P'First + 1 .. P'Last - 1 loop
            if Objective = 0 then
               G := Length_Partial_Y (P, I);
            else
               G := Dirichlet_Partial_Y (P, I);
            end if;
            Grad (I) := G;
            Norm := Norm + G * G;
         end loop;
         Norm := Sqrt (Norm);
         if Norm < 1.0E-14 then
            exit;
         end if;
         for I in P'First + 1 .. P'Last - 1 loop
            P (I).Y := P (I).Y - Step * Grad (I) / (1.0 + Norm);
         end loop;
      end loop;
   end Improve_Path_Gradient;

   procedure Improve_Path_Coordinate
     (P          : in out Path;
      Step       : Real := 0.1;
      Iterations : Natural := 40;
      Objective  : Natural := 0)
   is
      function Obj (Q : Path) return Real is
      begin
         if Objective = 0 then
            return Real (Path_Length (Q));
         else
            return Real (Dirichlet_Energy (Q));
         end if;
      end Obj;

      Best, Trial_Up, Trial_Dn : Real;
      Saved : Real;
      S : Real := Step;
   begin
      for Iter in 1 .. Iterations loop
         for I in P'First + 1 .. P'Last - 1 loop
            Best := Obj (P);
            Saved := P (I).Y;
            P (I).Y := Saved + S;
            Trial_Up := Obj (P);
            P (I).Y := Saved - S;
            Trial_Dn := Obj (P);
            if Trial_Up <= Best and then Trial_Up <= Trial_Dn then
               P (I).Y := Saved + S;
            elsif Trial_Dn < Best then
               P (I).Y := Saved - S;
            else
               P (I).Y := Saved;
            end if;
         end loop;
         S := S * 0.95;
      end loop;
   end Improve_Path_Coordinate;

   -------------------------------------------------------------------------
   -- Quantum variational
   -------------------------------------------------------------------------

   function Harmonic_Ground_Exact return Real is
   begin
      return 1.0;
   end Harmonic_Ground_Exact;

   function Gaussian_Trial_Energy_Analytic
     (Alpha : Positive_Real) return Real
   is
   begin
      return Alpha / 2.0 + 1.0 / (2.0 * Alpha);
   end Gaussian_Trial_Energy_Analytic;

   function Optimal_Gaussian_Alpha return Positive_Real is
   begin
      return 1.0;
   end Optimal_Gaussian_Alpha;

   function Discrete_Norm2
     (Psi : Wave; DX : Positive_Real) return Non_Negative
   is
      Acc : Real := 0.0;
   begin
      for I in Psi'Range loop
         Acc := Acc + Psi (I) * Psi (I);
      end loop;
      return Acc * DX;
   end Discrete_Norm2;

   function Normalize
     (Psi : Wave; DX : Positive_Real) return Wave
   is
      N2 : constant Real := Discrete_Norm2 (Psi, DX);
      Result : Wave (Psi'Range);
      Inv : Real;
   begin
      if N2 <= 1.0E-30 then
         raise Degenerate;
      end if;
      Inv := 1.0 / Sqrt (N2);
      for I in Psi'Range loop
         Result (I) := Psi (I) * Inv;
      end loop;
      return Result;
   end Normalize;

   function Make_Uniform_Grid
     (X_Min : Real;
      X_Max : Real;
      N     : Grid_Count) return Wave
   is
      Result : Wave (1 .. N);
      H : constant Real := (X_Max - X_Min) / Real (N - 1);
   begin
      for I in 1 .. N loop
         Result (I) := X_Min + Real (I - 1) * H;
      end loop;
      return Result;
   end Make_Uniform_Grid;

   function Make_Gaussian_Wave
     (Alpha : Positive_Real;
      X_Min : Real;
      X_Max : Real;
      N     : Grid_Count) return Wave
   is
      X : constant Wave := Make_Uniform_Grid (X_Min, X_Max, N);
      Result : Wave (1 .. N);
   begin
      for I in 1 .. N loop
         Result (I) := Exp (-0.5 * Alpha * X (I) * X (I));
      end loop;
      return Result;
   end Make_Gaussian_Wave;

   function Rayleigh_Energy
     (Psi : Wave;
      X   : Wave;
      DX  : Positive_Real) return Real
   is
      NPsi : constant Wave := Normalize (Psi, DX);
      Kinetic : Real := 0.0;
      Potential : Real := 0.0;
      Lap : Real;
   begin
      --  Second-difference Laplacian; endpoints use one-sided / zero BC feel.
      for I in NPsi'First + 1 .. NPsi'Last - 1 loop
         Lap := (NPsi (I + 1) - 2.0 * NPsi (I) + NPsi (I - 1))
           / (DX * DX);
         Kinetic := Kinetic + NPsi (I) * (-Lap);
         Potential := Potential + X (I) * X (I) * NPsi (I) * NPsi (I);
      end loop;
      --  Endpoint potential contribution (kinetic ~0 with ψ≈0 at edges).
      Kinetic := Kinetic * DX;
      Potential := Potential * DX;
      Potential := Potential
        + DX * X (NPsi'First) * X (NPsi'First)
            * NPsi (NPsi'First) * NPsi (NPsi'First)
        + DX * X (NPsi'Last) * X (NPsi'Last)
            * NPsi (NPsi'Last) * NPsi (NPsi'Last);
      return Kinetic + Potential;
   end Rayleigh_Energy;

   function Quantum_Trial_Energy
     (Alpha : Positive_Real;
      X_Min : Real := -6.0;
      X_Max : Real := 6.0;
      N     : Grid_Count := 61) return Real
   is
      X   : constant Wave := Make_Uniform_Grid (X_Min, X_Max, N);
      Psi : constant Wave := Make_Gaussian_Wave (Alpha, X_Min, X_Max, N);
      DX  : constant Real := (X_Max - X_Min) / Real (N - 1);
   begin
      return Rayleigh_Energy (Psi, X, DX);
   end Quantum_Trial_Energy;

   function Optimize_Gaussian_Alpha
     (Alpha_Lo : Positive_Real := 0.3;
      Alpha_Hi : Positive_Real := 3.0;
      Steps    : Positive := 40;
      X_Min    : Real := -6.0;
      X_Max    : Real := 6.0;
      N        : Grid_Count := 61) return Real
   is
      Best_A : Real := Alpha_Lo;
      Best_E : Real := Real'Last;
      A, E   : Real;
      H      : constant Real :=
        (Alpha_Hi - Alpha_Lo) / Real (Steps);
   begin
      for K in 0 .. Steps loop
         A := Alpha_Lo + Real (K) * H;
         if A < Real'Model_Small then
            A := Real'Model_Small;
         end if;
         E := Quantum_Trial_Energy (A, X_Min, X_Max, N);
         if E < Best_E then
            Best_E := E;
            Best_A := A;
         end if;
      end loop;
      return Best_A;
   end Optimize_Gaussian_Alpha;

end Variational_Method;
