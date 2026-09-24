--  Line_Search body — Armijo / Wolfe backtracking, golden-section /
--  Fibonacci exact 1-D search, fixed step, exact quadratic φ.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Line_Search
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use EF;

   Golden_Ratio_Inv : constant Real := 2.0 / (1.0 + Sqrt (5.0));
   --  1/φ ≈ 0.6180339887…

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

   ---------------------------------------------------------------------------
   -- Acceptance predicates
   ---------------------------------------------------------------------------

   function Armijo_Accept
     (Phi_Alpha, Phi_0, Alpha, C1, Phi_Prime_0 : Real) return Boolean
   is
   begin
      return Phi_Alpha <= Phi_0 + C1 * Alpha * Phi_Prime_0;
   end Armijo_Accept;

   function Wolfe_Curvature_Accept
     (Phi_Prime_Alpha, Phi_Prime_0, C2 : Real;
      Strong : Boolean := True) return Boolean
   is
   begin
      if Strong then
         return abs (Phi_Prime_Alpha) <= C2 * abs (Phi_Prime_0);
      else
         return Phi_Prime_Alpha >= C2 * Phi_Prime_0;
      end if;
   end Wolfe_Curvature_Accept;

   function Directional_Derivative
     (Grad : Point; P : Point) return Real
   is
   begin
      return Dot (Grad, P);
   end Directional_Derivative;

   function Directional_Derivative_FD
     (Obj : Objective_Fn;
      X   : Point;
      P   : Point;
      Eps : Positive_Real := 1.0E-8) return Real
   is
      Xp : constant Point := Add (X, Scale (Real (Eps), P));
      Xm : constant Point := Sub (X, Scale (Real (Eps), P));
   begin
      return (Obj (Xp) - Obj (Xm)) / (2.0 * Real (Eps));
   end Directional_Derivative_FD;

   ---------------------------------------------------------------------------
   -- Internal: evaluate f(x + α p) and count
   ---------------------------------------------------------------------------

   function Eval_Along
     (Obj   : Objective_Fn;
      X     : Point;
      P     : Point;
      Alpha : Real;
      Evals : in out Natural) return Real
   is
   begin
      Evals := Evals + 1;
      return Obj (Add (X, Scale (Alpha, P)));
   end Eval_Along;

   function Phi_Prime_At
     (Obj   : Objective_Fn;
      Grad  : Grad_Fn;
      X     : Point;
      P     : Point;
      Alpha : Real;
      Eps   : Positive_Real;
      Evals : in out Natural) return Real
   is
      Xa : constant Point := Add (X, Scale (Alpha, P));
   begin
      if Grad /= null then
         return Dot (Grad (Xa), P);
      else
         --  Central FD of φ at α: [f(x+(α+ε)p) − f(x+(α−ε)p)] / (2ε)
         declare
            Fp : constant Real :=
              Eval_Along (Obj, X, P, Alpha + Real (Eps), Evals);
            Fm : constant Real :=
              Eval_Along (Obj, X, P, Alpha - Real (Eps), Evals);
         begin
            return (Fp - Fm) / (2.0 * Real (Eps));
         end;
      end if;
   end Phi_Prime_At;

   ---------------------------------------------------------------------------
   -- Armijo backtracking
   ---------------------------------------------------------------------------

   function Armijo_Backtrack
     (Obj  : Objective_Fn;
      X    : Point;
      P    : Point;
      Grad : Grad_Fn := null;
      Cfg  : Config  := Default_Config) return Result
   is
      R          : Result;
      Alpha      : Real := Real (Cfg.Alpha0);
      Phi_0      : Real;
      Phi_Prime0 : Real;
      Phi_A      : Real;
   begin
      if Cfg.C1 >= 1.0 or else Cfg.Rho >= 1.0 then
         raise Invalid_Argument;
      end if;

      R.Evals := 0;
      Phi_0 := Eval_Along (Obj, X, P, 0.0, R.Evals);

      if Grad /= null then
         Phi_Prime0 := Dot (Grad (X), P);
      else
         Phi_Prime0 :=
           Directional_Derivative_FD (Obj, X, P, Cfg.Fd_Eps);
         R.Evals := R.Evals + 2;
      end if;

      --  Ascent / flat direction: no useful Armijo step expected.
      if Phi_Prime0 >= 0.0 then
         R.Alpha   := 0.0;
         R.Success := False;
         return R;
      end if;

      for Attempt in 1 .. Cfg.Max_Backtracks loop
         pragma Unreferenced (Attempt);
         Phi_A := Eval_Along (Obj, X, P, Alpha, R.Evals);
         if Armijo_Accept (Phi_A, Phi_0, Alpha, Real (Cfg.C1), Phi_Prime0)
         then
            R.Alpha   := Alpha;
            R.Success := True;
            return R;
         end if;
         Alpha := Real (Cfg.Rho) * Alpha;
         if Alpha <= 0.0 then
            exit;
         end if;
      end loop;

      R.Alpha   := Alpha;
      R.Success := False;
      return R;
   end Armijo_Backtrack;

   ---------------------------------------------------------------------------
   -- Wolfe / strong Wolfe backtracking
   ---------------------------------------------------------------------------

   function Wolfe_Line_Search
     (Obj  : Objective_Fn;
      X    : Point;
      P    : Point;
      Grad : Grad_Fn := null;
      Cfg  : Config  := Default_Config) return Result
   is
      R          : Result;
      Alpha      : Real := Real (Cfg.Alpha0);
      Phi_0      : Real;
      Phi_Prime0 : Real;
      Phi_A      : Real;
      Phi_PA     : Real;
   begin
      if Cfg.C1 >= Cfg.C2 or else Cfg.C2 >= 1.0 or else Cfg.Rho >= 1.0 then
         raise Invalid_Argument;
      end if;

      R.Evals := 0;
      Phi_0 := Eval_Along (Obj, X, P, 0.0, R.Evals);

      if Grad /= null then
         Phi_Prime0 := Dot (Grad (X), P);
      else
         Phi_Prime0 :=
           Directional_Derivative_FD (Obj, X, P, Cfg.Fd_Eps);
         R.Evals := R.Evals + 2;
      end if;

      if Phi_Prime0 >= 0.0 then
         R.Alpha   := 0.0;
         R.Success := False;
         return R;
      end if;

      for Attempt in 1 .. Cfg.Max_Backtracks loop
         pragma Unreferenced (Attempt);
         Phi_A := Eval_Along (Obj, X, P, Alpha, R.Evals);
         if Armijo_Accept (Phi_A, Phi_0, Alpha, Real (Cfg.C1), Phi_Prime0)
         then
            Phi_PA :=
              Phi_Prime_At
                (Obj, Grad, X, P, Alpha, Cfg.Fd_Eps, R.Evals);
            if Wolfe_Curvature_Accept
                 (Phi_PA, Phi_Prime0, Real (Cfg.C2), Cfg.Strong_Wolfe)
            then
               R.Alpha   := Alpha;
               R.Success := True;
               return R;
            end if;
         end if;
         Alpha := Real (Cfg.Rho) * Alpha;
         if Alpha <= 0.0 then
            exit;
         end if;
      end loop;

      R.Alpha   := Alpha;
      R.Success := False;
      return R;
   end Wolfe_Line_Search;

   ---------------------------------------------------------------------------
   -- Golden-section search
   ---------------------------------------------------------------------------

   function Golden_Section
     (Phi : Scalar_Fn;
      Lo  : Real;
      Hi  : Real;
      Cfg : Config := Default_Config) return Result
   is
      R     : Result;
      A     : Real := Lo;
      B     : Real := Hi;
      C     : Real;
      D     : Real;
      Fc    : Real;
      Fd    : Real;
      Width : Real;
   begin
      if Lo >= Hi then
         raise Invalid_Argument;
      end if;

      R.Evals := 0;
      Width := B - A;
      C := B - Golden_Ratio_Inv * Width;
      D := A + Golden_Ratio_Inv * Width;
      Fc := Phi (C);
      Fd := Phi (D);
      R.Evals := 2;

      for Iter in 1 .. Cfg.Max_Iterations loop
         pragma Unreferenced (Iter);
         if abs (B - A) <= Real (Cfg.Tol) then
            exit;
         end if;
         if Fc < Fd then
            B  := D;
            D  := C;
            Fd := Fc;
            C  := B - Golden_Ratio_Inv * (B - A);
            Fc := Phi (C);
            R.Evals := R.Evals + 1;
         else
            A  := C;
            C  := D;
            Fc := Fd;
            D  := A + Golden_Ratio_Inv * (B - A);
            Fd := Phi (D);
            R.Evals := R.Evals + 1;
         end if;
      end loop;

      R.Alpha   := 0.5 * (A + B);
      R.Success := abs (B - A) <= Real (Cfg.Tol) * 10.0
                   or else abs (B - A) <= Real (Cfg.Tol) + 1.0E-12;
      --  Always report the midpoint; mark success when bracket is tight
      --  enough (or after exhausting iterations with a reasonably small
      --  bracket relative to initial width).
      if not R.Success then
         R.Success := abs (B - A) <= 1.0E-4 * (Hi - Lo) + Real (Cfg.Tol);
      end if;
      return R;
   end Golden_Section;

   ---------------------------------------------------------------------------
   -- Fibonacci search
   ---------------------------------------------------------------------------

   function Fibonacci_Search
     (Phi : Scalar_Fn;
      Lo  : Real;
      Hi  : Real;
      Cfg : Config := Default_Config) return Result
   is
      R     : Result;
      A     : Real := Lo;
      B     : Real := Hi;
      N     : Natural := 2;
      F_Prev : Real := 1.0;
      F_Curr : Real := 1.0;
      F_Next : Real;
      Ratio  : Real;
      C, D   : Real;
      Fc, Fd : Real;
   begin
      if Lo >= Hi then
         raise Invalid_Argument;
      end if;

      --  Choose smallest N such that F_N >= (Hi-Lo)/Tol (capped).
      while F_Curr < (Hi - Lo) / Real (Cfg.Tol) and then N < Cfg.Max_Iterations
      loop
         F_Next := F_Curr + F_Prev;
         F_Prev := F_Curr;
         F_Curr := F_Next;
         N := N + 1;
      end loop;

      R.Evals := 0;
      --  Rebuild Fibonacci numbers downward during the search.
      declare
         Fib : array (0 .. N) of Real;
      begin
         Fib (0) := 0.0;
         if N >= 1 then
            Fib (1) := 1.0;
         end if;
         for I in 2 .. N loop
            Fib (I) := Fib (I - 1) + Fib (I - 2);
         end loop;

         for K in reverse 2 .. N loop
            if Fib (K) <= 0.0 then
               exit;
            end if;
            Ratio := Fib (K - 2) / Fib (K);
            if Ratio < 0.0 then
               Ratio := 0.0;
            elsif Ratio > 1.0 then
               Ratio := 1.0;
            end if;
            C := A + Ratio * (B - A);
            D := A + (1.0 - Ratio) * (B - A);
            if C > D then
               declare
                  Tmp : constant Real := C;
               begin
                  C := D;
                  D := Tmp;
               end;
            end if;
            --  Ensure distinct interior points.
            if Near (C, D, 1.0E-15) then
               exit;
            end if;
            Fc := Phi (C);
            Fd := Phi (D);
            R.Evals := R.Evals + 2;
            if Fc < Fd then
               B := D;
            else
               A := C;
            end if;
            if abs (B - A) <= Real (Cfg.Tol) then
               exit;
            end if;
         end loop;
      end;

      R.Alpha   := 0.5 * (A + B);
      R.Success := abs (B - A) <= Real (Cfg.Tol) * 10.0
                   or else abs (B - A) <= 1.0E-4 * (Hi - Lo) + Real (Cfg.Tol);
      return R;
   end Fibonacci_Search;

   ---------------------------------------------------------------------------
   -- Fixed step / exact quadratic
   ---------------------------------------------------------------------------

   function Fixed_Step (Alpha : Positive_Real) return Result is
      R : Result;
   begin
      R.Alpha   := Real (Alpha);
      R.Success := True;
      R.Evals   := 0;
      return R;
   end Fixed_Step;

   function Exact_Quadratic
     (A, B, C : Real) return Result
   is
      pragma Unreferenced (A);
      R : Result;
   begin
      if C <= 0.0 then
         R.Alpha   := 0.0;
         R.Success := False;
         R.Evals   := 0;
         return R;
      end if;
      R.Alpha   := -B / (2.0 * C);
      R.Success := True;
      R.Evals   := 0;
      return R;
   end Exact_Quadratic;

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

   function Rosenbrock (X : Point) return Real is
      Xx, Yy : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      Xx := X (X'First);
      Yy := X (X'First + 1);
      return (1.0 - Xx) ** 2 + 100.0 * (Yy - Xx ** 2) ** 2;
   end Rosenbrock;

   function Rosenbrock_Grad (X : Point) return Point is
      G  : Point (X'Range) := [others => 0.0];
      Xx, Yy : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      Xx := X (X'First);
      Yy := X (X'First + 1);
      G (X'First)     := -2.0 * (1.0 - Xx) - 400.0 * Xx * (Yy - Xx ** 2);
      G (X'First + 1) := 200.0 * (Yy - Xx ** 2);
      return G;
   end Rosenbrock_Grad;

   function Quadratic_1D (Alpha : Real) return Real is
   begin
      return (Alpha - 2.0) ** 2;
   end Quadratic_1D;

   function Quartic_Unimodal (Alpha : Real) return Real is
      T : constant Real := Alpha - 1.5;
   begin
      return T ** 4 + 0.1 * T ** 2;
   end Quartic_Unimodal;

end Line_Search;
