--  Frank_Wolfe_Algorithm body — conditional gradient / Frank–Wolfe
--  (Frank & Wolfe 1956; Wikipedia). Projection-free constrained
--  minimization via linear minimization oracles and convex-combination
--  steps; duality-gap stopping.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Frank_Wolfe_Algorithm
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use EF;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Point_Near
     (A, B : Point; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if abs (A (I) - B (I - A'First + B'First)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Point_Near;

   function Norm2 (X : Point) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return Non_Negative (Sqrt (S));
   end Norm2;

   function Dot (A, B : Point) return Real is
      S : Real := 0.0;
      J : Dim_Index := B'First;
   begin
      for I in A'Range loop
         S := S + A (I) * B (J);
         if J < B'Last then
            J := J + 1;
         end if;
      end loop;
      return S;
   end Dot;

   function Add (A, B : Point) return Point is
      R : Point (A'Range);
      J : Dim_Index := B'First;
   begin
      for I in A'Range loop
         R (I) := A (I) + B (J);
         if J < B'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Add;

   function Sub (A, B : Point) return Point is
      R : Point (A'Range);
      J : Dim_Index := B'First;
   begin
      for I in A'Range loop
         R (I) := A (I) - B (J);
         if J < B'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Sub;

   function Scale (C : Real; X : Point) return Point is
      R : Point (X'Range);
   begin
      for I in X'Range loop
         R (I) := C * X (I);
      end loop;
      return R;
   end Scale;

   function Convex_Combination
     (Gamma : Unit_Interval; X, S : Point) return Point
   is
      R : Point (X'Range);
      J : Dim_Index := S'First;
      One_Minus : constant Real := 1.0 - Real (Gamma);
   begin
      for I in X'Range loop
         R (I) := One_Minus * X (I) + Real (Gamma) * S (J);
         if J < S'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Convex_Combination;

   ---------------------------------------------------------------------------
   -- FD gradient / step sizes / gap / line search
   ---------------------------------------------------------------------------

   function Finite_Difference_Gradient
     (Obj : Objective_Fn;
      X   : Point;
      Eps : Positive_Real := 1.0E-7) return Point
   is
      G  : Point (X'Range);
      Xp : Point (X'Range);
      Xm : Point (X'Range);
      H  : Real;
      Fp : Real;
      Fm : Real;
   begin
      Xp := X;
      Xm := X;
      for I in X'Range loop
         H := Eps * (1.0 + abs (X (I)));
         Xp (I) := X (I) + H;
         Xm (I) := X (I) - H;
         Fp := Obj (Xp);
         Fm := Obj (Xm);
         G (I) := (Fp - Fm) / (2.0 * H);
         Xp (I) := X (I);
         Xm (I) := X (I);
      end loop;
      return G;
   end Finite_Difference_Gradient;

   function Open_Loop_Step (K : Natural) return Unit_Interval is
      Den : constant Real := Real (K) + 2.0;
   begin
      return Unit_Interval (2.0 / Den);
   end Open_Loop_Step;

   function Duality_Gap (Grad, X, S : Point) return Non_Negative is
      Gap : constant Real := Dot (Grad, Sub (X, S));
   begin
      if Gap <= 0.0 then
         return 0.0;
      else
         return Non_Negative (Gap);
      end if;
   end Duality_Gap;

   function Duality_Gap
     (Grad : Point; X : Point; LMO : LMO_Fn) return Non_Negative
   is
      S : constant Point := LMO (Grad);
   begin
      return Duality_Gap (Grad, X, S);
   end Duality_Gap;

   function Armijo_Accept
     (F_New, F_Old, Gamma, C1, Dir_Deriv : Real) return Boolean
   is
   begin
      return F_New <= F_Old + C1 * Gamma * Dir_Deriv;
   end Armijo_Accept;

   function Exact_Line_Search
     (Obj       : Objective_Fn;
      X, S      : Point;
      Tol       : Positive_Real;
      Max_Evals : Positive) return Unit_Interval
   is
      --  Golden-section search of φ(γ) = f((1−γ)x + γ s) on [0,1].
      Phi   : constant Real := (Sqrt (5.0) - 1.0) / 2.0;  -- 1/φ ≈ 0.618
      A     : Real := 0.0;
      B     : Real := 1.0;
      C     : Real;
      D     : Real;
      Fc    : Real;
      Fd    : Real;
      Evals : Natural := 0;

      function Phi_Of (Gamma : Real) return Real is
         Trial : constant Point :=
           Convex_Combination (Unit_Interval (Gamma), X, S);
      begin
         Evals := Evals + 1;
         return Obj (Trial);
      end Phi_Of;
   begin
      if Point_Near (X, S, 1.0E-15) then
         return 0.0;
      end if;

      C := B - Phi * (B - A);
      D := A + Phi * (B - A);
      Fc := Phi_Of (C);
      Fd := Phi_Of (D);

      while Evals < Max_Evals and then (B - A) > Tol loop
         if Fc < Fd then
            B := D;
            D := C;
            Fd := Fc;
            C := B - Phi * (B - A);
            Fc := Phi_Of (C);
         else
            A := C;
            C := D;
            Fc := Fd;
            D := A + Phi * (B - A);
            Fd := Phi_Of (D);
         end if;
      end loop;

      declare
         Mid : constant Real := 0.5 * (A + B);
      begin
         if Mid <= 0.0 then
            return 0.0;
         elsif Mid >= 1.0 then
            return 1.0;
         else
            return Unit_Interval (Mid);
         end if;
      end;
   end Exact_Line_Search;

   function Armijo_Line_Search
     (Obj    : Objective_Fn;
      X, S   : Point;
      F, Dir_Deriv : Real;
      C1     : Positive_Real;
      Rho    : Positive_Real;
      Max_LS : Positive) return Unit_Interval
   is
      Gamma   : Real := 1.0;
      X_Trial : Point (X'Range);
      F_Trial : Real;
   begin
      for K in 1 .. Max_LS loop
         X_Trial := Convex_Combination (Unit_Interval (Gamma), X, S);
         F_Trial := Obj (X_Trial);
         if Armijo_Accept (F_Trial, F, Gamma, C1, Dir_Deriv) then
            return Unit_Interval (Gamma);
         end if;
         Gamma := Rho * Gamma;
         if Gamma < 1.0E-16 then
            exit;
         end if;
      end loop;
      raise Line_Search_Failed;
   end Armijo_Line_Search;

   ---------------------------------------------------------------------------
   -- Linear minimization oracles
   ---------------------------------------------------------------------------

   function LMO_Simplex (G : Point) return Point is
      S     : Point (G'Range) := [others => 0.0];
      Best  : Dim_Index := G'First;
      BestV : Real := G (G'First);
   begin
      for I in G'Range loop
         if G (I) < BestV then
            BestV := G (I);
            Best := I;
         end if;
      end loop;
      S (Best) := 1.0;
      return S;
   end LMO_Simplex;

   function LMO_Box (G, Lower, Upper : Point) return Point is
      S : Point (G'Range);
      J : Dim_Index := Lower'First;
      K : Dim_Index := Upper'First;
   begin
      for I in G'Range loop
         if G (I) > 0.0 then
            S (I) := Lower (J);
         else
            --  g_i ≤ 0 → pick Upper (including g_i = 0 arbitrarily at U)
            S (I) := Upper (K);
         end if;
         if J < Lower'Last then
            J := J + 1;
         end if;
         if K < Upper'Last then
            K := K + 1;
         end if;
      end loop;
      return S;
   end LMO_Box;

   function LMO_L1_Ball
     (G : Point; Radius : Non_Negative := 1.0) return Point
   is
      S      : Point (G'Range) := [others => 0.0];
      Best   : Dim_Index := G'First;
      BestAbs : Real := abs (G (G'First));
      All_Zero : Boolean := True;
   begin
      for I in G'Range loop
         if G (I) /= 0.0 then
            All_Zero := False;
         end if;
         if abs (G (I)) > BestAbs then
            BestAbs := abs (G (I));
            Best := I;
         end if;
      end loop;

      if All_Zero or else Radius = 0.0 then
         return S;
      end if;

      if G (Best) > 0.0 then
         S (Best) := -Real (Radius);
      else
         S (Best) := Real (Radius);
      end if;
      return S;
   end LMO_L1_Ball;

   --  Active box / ℓ₁ state for LMO_Fn adapters
   Active_Box_N : Dim_Count := 1;
   Active_Box_L : Point (1 .. Max_Dim) := [others => 0.0];
   Active_Box_U : Point (1 .. Max_Dim) := [others => 1.0];
   Active_L1_R  : Non_Negative := 1.0;

   procedure Set_Box_Bounds (Lower, Upper : Point) is
      N : constant Dim_Count := Lower'Length;
      J : Dim_Index := Lower'First;
      K : Dim_Index := Upper'First;
   begin
      Active_Box_N := N;
      for I in 1 .. N loop
         Active_Box_L (I) := Lower (J);
         Active_Box_U (I) := Upper (K);
         if J < Lower'Last then
            J := J + 1;
         end if;
         if K < Upper'Last then
            K := K + 1;
         end if;
      end loop;
   end Set_Box_Bounds;

   function Active_Box_LMO (G : Point) return Point is
   begin
      if G'Length /= Active_Box_N then
         raise Invalid_Argument;
      end if;
      return LMO_Box
        (G, Active_Box_L (1 .. Active_Box_N), Active_Box_U (1 .. Active_Box_N));
   end Active_Box_LMO;

   procedure Set_L1_Radius (Radius : Non_Negative) is
   begin
      Active_L1_R := Radius;
   end Set_L1_Radius;

   function Active_L1_LMO (G : Point) return Point is
   begin
      return LMO_L1_Ball (G, Active_L1_R);
   end Active_L1_LMO;

   ---------------------------------------------------------------------------
   -- Demo objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere;

   function Sphere_Grad (X : Point) return Point is
      G : Point (X'Range);
   begin
      for I in X'Range loop
         G (I) := 2.0 * X (I);
      end loop;
      return G;
   end Sphere_Grad;

   function Shifted_Quadratic (X : Point) return Real is
      N : constant Real := Real (X'Length);
      T : constant Real := 1.0 / N;
      S : Real := 0.0;
      D : Real;
   begin
      for I in X'Range loop
         D := X (I) - T;
         S := S + D * D;
      end loop;
      return 0.5 * S;
   end Shifted_Quadratic;

   function Shifted_Quadratic_Grad (X : Point) return Point is
      N : constant Real := Real (X'Length);
      T : constant Real := 1.0 / N;
      G : Point (X'Range);
   begin
      for I in X'Range loop
         G (I) := X (I) - T;
      end loop;
      return G;
   end Shifted_Quadratic_Grad;

   function Weighted_Quadratic (X : Point) return Real is
      S : Real := 0.0;
      W : Real;
      Off : constant Natural := X'First - 1;
   begin
      for I in X'Range loop
         W := Real (I - Off);  -- 1 .. n
         S := S + W * X (I) * X (I);
      end loop;
      return 0.5 * S;
   end Weighted_Quadratic;

   function Weighted_Quadratic_Grad (X : Point) return Point is
      G : Point (X'Range);
      W : Real;
      Off : constant Natural := X'First - 1;
   begin
      for I in X'Range loop
         W := Real (I - Off);
         G (I) := W * X (I);
      end loop;
      return G;
   end Weighted_Quadratic_Grad;

   function Linear_Ones (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I);
      end loop;
      return S;
   end Linear_Ones;

   function Linear_Ones_Grad (X : Point) return Point is
      G : constant Point (X'Range) := [others => 1.0];
   begin
      return G;
   end Linear_Ones_Grad;

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      LMO       : LMO_Fn;
      Grad      : Grad_Fn := null;
      Cfg       : Config := Default_Config) return Result
   is
      N : constant Dim_Count := X0'Length;
      X : Point (X0'Range) := X0;
      G : Point (X0'Range);
      S : Point (X0'Range);
      X_New : Point (X0'Range);
      F : Real;
      Gap : Non_Negative;
      Gamma : Unit_Interval;
      Dir_Deriv : Real;
      Dx : Point (X0'Range);
      R : Result;
      Success_Flag : Boolean := False;
      Iters : Natural := 0;
   begin
      R.Dim := N;

      for K in 0 .. Cfg.Max_Iterations - 1 loop
         F := Objective (X);
         if Grad /= null then
            G := Grad (X);
         else
            G := Finite_Difference_Gradient (Objective, X, Cfg.Fd_Eps);
         end if;

         S := LMO (G);
         Gap := Duality_Gap (G, X, S);
         Iters := K + 1;

         if Gap <= Cfg.Gap_Tol then
            Success_Flag := True;
            exit;
         end if;

         Dir_Deriv := Dot (G, Sub (S, X));

         case Cfg.Step_Mode is
            when Open_Loop =>
               Gamma := Open_Loop_Step (K);
            when Exact_Line_Search =>
               Gamma := Exact_Line_Search
                 (Objective, X, S, Cfg.Exact_Tol, Cfg.Max_Line_Search);
            when Armijo =>
               begin
                  Gamma := Armijo_Line_Search
                    (Objective, X, S, F, Dir_Deriv,
                     Cfg.Armijo_C, Cfg.Line_Search_Rho, Cfg.Max_Line_Search);
               exception
                  when Line_Search_Failed =>
                     --  Keep current point; report gap so far.
                     exit;
               end;
         end case;

         X_New := Convex_Combination (Gamma, X, S);
         Dx := Sub (X_New, X);
         X := X_New;

         if Norm2 (Dx) <= Cfg.Step_Tol then
            Success_Flag := Gap <= Cfg.Gap_Tol;
            exit;
         end if;
      end loop;

      --  Final evaluation
      F := Objective (X);
      if Grad /= null then
         G := Grad (X);
      else
         G := Finite_Difference_Gradient (Objective, X, Cfg.Fd_Eps);
      end if;
      S := LMO (G);
      Gap := Duality_Gap (G, X, S);
      if Gap <= Cfg.Gap_Tol then
         Success_Flag := True;
      end if;

      R.Final_Point (1 .. N) := X;
      R.Final_Value := F;
      R.Final_Gap := Gap;
      R.Iterations := Iters;
      R.Success := Success_Flag;
      return R;
   end Minimize;

end Frank_Wolfe_Algorithm;
