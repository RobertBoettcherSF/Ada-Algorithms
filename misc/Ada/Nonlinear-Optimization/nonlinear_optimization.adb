--  Nonlinear_Optimization body — educational GD / Newton / Armijo /
--  FD / box projection / method taxonomy for Wikipedia nonlinear
--  programming (nonlinear optimization).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Nonlinear_Optimization
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

   function Mat_Vec (A : Matrix; X : Point) return Point is
      R  : Point (X'Range) := [others => 0.0];
      N  : constant Dim_Count := X'Length;
      XR : constant Dim_Index := X'First;
      AR : constant Dim_Index := A'First (1);
      AC : constant Dim_Index := A'First (2);
   begin
      for I in 0 .. N - 1 loop
         declare
            Acc : Real := 0.0;
         begin
            for J in 0 .. N - 1 loop
               Acc := Acc + A (AR + I, AC + J) * X (XR + J);
            end loop;
            R (XR + I) := Acc;
         end;
      end loop;
      return R;
   end Mat_Vec;

   function Identity (N : Dim_Count) return Matrix is
      H : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         H (I, I) := 1.0;
      end loop;
      return H;
   end Identity;

   ---------------------------------------------------------------------------
   -- Solve_SPD (Gaussian elimination with partial pivoting)
   ---------------------------------------------------------------------------

   function Solve_SPD
     (A : Matrix; B : Point) return Point
   is
      N      : constant Dim_Count := B'Length;
      M      : array (1 .. N, 1 .. N) of Real;
      Rhs    : array (1 .. N) of Real;
      X      : Point (1 .. N) := [others => 0.0];
      Pivot  : Dim_Index;
      Max_Abs : Real;
      Tmp    : Real;
      Factor : Real;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            M (I, J) := A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
         Rhs (I) := B (B'First + (I - 1));
      end loop;

      for K in 1 .. N loop
         Pivot := K;
         Max_Abs := abs (M (K, K));
         for I in K + 1 .. N loop
            if abs (M (I, K)) > Max_Abs then
               Max_Abs := abs (M (I, K));
               Pivot := I;
            end if;
         end loop;

         if Max_Abs < 1.0E-18 then
            raise Singular_System;
         end if;

         if Pivot /= K then
            for J in K .. N loop
               Tmp := M (K, J);
               M (K, J) := M (Pivot, J);
               M (Pivot, J) := Tmp;
            end loop;
            Tmp := Rhs (K);
            Rhs (K) := Rhs (Pivot);
            Rhs (Pivot) := Tmp;
         end if;

         for I in K + 1 .. N loop
            Factor := M (I, K) / M (K, K);
            M (I, K) := 0.0;
            for J in K + 1 .. N loop
               M (I, J) := M (I, J) - Factor * M (K, J);
            end loop;
            Rhs (I) := Rhs (I) - Factor * Rhs (K);
         end loop;
      end loop;

      for I in reverse 1 .. N loop
         declare
            S : Real := Rhs (I);
         begin
            for J in I + 1 .. N loop
               S := S - M (I, J) * X (J);
            end loop;
            if abs (M (I, I)) < 1.0E-18 then
               raise Singular_System;
            end if;
            X (I) := S / M (I, I);
         end;
      end loop;

      return X;
   end Solve_SPD;

   ---------------------------------------------------------------------------
   -- Armijo / line search
   ---------------------------------------------------------------------------

   function Armijo_Accept
     (F_New, F_Old, Alpha, C1, Dir_Deriv : Real) return Boolean
   is
   begin
      return F_New <= F_Old + C1 * Alpha * Dir_Deriv;
   end Armijo_Accept;

   function Line_Search
     (Obj    : Objective_Fn;
      X      : Point;
      F      : Real;
      G      : Point;
      P      : Point;
      C1     : Positive_Real;
      Rho    : Positive_Real;
      Max_LS : Positive) return Positive_Real
   is
      Alpha     : Real := 1.0;
      Dir_Deriv : constant Real := Dot (G, P);
      X_Trial   : Point (X'Range);
      F_Trial   : Real;
   begin
      for K in 1 .. Max_LS loop
         X_Trial := Add (X, Scale (Alpha, P));
         F_Trial := Obj (X_Trial);
         if Armijo_Accept (F_Trial, F, Alpha, C1, Dir_Deriv) then
            return Positive_Real (Alpha);
         end if;
         Alpha := Alpha * Rho;
      end loop;
      raise Line_Search_Failed;
   end Line_Search;

   ---------------------------------------------------------------------------
   -- Finite differences
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

   function Finite_Difference_Hessian
     (Obj : Objective_Fn;
      X   : Point;
      Eps : Positive_Real := 1.0E-5) return Matrix
   is
      N  : constant Dim_Count := X'Length;
      Hm : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      XF : constant Dim_Index := X'First;
      Xp : Point (X'Range);
      Xm : Point (X'Range);
      Xpp, Xpm, Xmp, Xmm : Point (X'Range);
      Hi, Hj : Real;
      Fpp, Fpm, Fmp, Fmm, F0 : Real;
   begin
      F0 := Obj (X);
      for I in 0 .. N - 1 loop
         Hi := Eps * (1.0 + abs (X (XF + I)));
         --  Diagonal via second derivative central formula.
         Xp := X;
         Xm := X;
         Xp (XF + I) := X (XF + I) + Hi;
         Xm (XF + I) := X (XF + I) - Hi;
         Hm (1 + I, 1 + I) :=
           (Obj (Xp) - 2.0 * F0 + Obj (Xm)) / (Hi * Hi);
         for J in I + 1 .. N - 1 loop
            Hj := Eps * (1.0 + abs (X (XF + J)));
            Xpp := X;
            Xpm := X;
            Xmp := X;
            Xmm := X;
            Xpp (XF + I) := X (XF + I) + Hi;
            Xpp (XF + J) := X (XF + J) + Hj;
            Xpm (XF + I) := X (XF + I) + Hi;
            Xpm (XF + J) := X (XF + J) - Hj;
            Xmp (XF + I) := X (XF + I) - Hi;
            Xmp (XF + J) := X (XF + J) + Hj;
            Xmm (XF + I) := X (XF + I) - Hi;
            Xmm (XF + J) := X (XF + J) - Hj;
            Fpp := Obj (Xpp);
            Fpm := Obj (Xpm);
            Fmp := Obj (Xmp);
            Fmm := Obj (Xmm);
            Hm (1 + I, 1 + J) :=
              (Fpp - Fpm - Fmp + Fmm) / (4.0 * Hi * Hj);
            Hm (1 + J, 1 + I) := Hm (1 + I, 1 + J);
         end loop;
      end loop;
      return Hm;
   end Finite_Difference_Hessian;

   ---------------------------------------------------------------------------
   -- Stationarity / box
   ---------------------------------------------------------------------------

   function Grad_Norm (G : Point) return Non_Negative is
   begin
      return Norm2 (G);
   end Grad_Norm;

   function Is_Stationary
     (G : Point; Tol : Non_Negative := 1.0E-8) return Boolean
   is
   begin
      return Grad_Norm (G) <= Tol;
   end Is_Stationary;

   function Make_Box (Lo, Hi : Point) return Box is
      B : Box;
      N : constant Dim_Count := Lo'Length;
   begin
      B.Dim := N;
      for I in 0 .. N - 1 loop
         if Lo (Lo'First + I) > Hi (Hi'First + I) then
            raise Invalid_Argument;
         end if;
         B.Lo (1 + I) := Lo (Lo'First + I);
         B.Hi (1 + I) := Hi (Hi'First + I);
      end loop;
      return B;
   end Make_Box;

   function Project_Box (X : Point; B : Box) return Point is
      R : Point (X'Range);
      N : constant Dim_Count := X'Length;
   begin
      for I in 0 .. N - 1 loop
         declare
            V  : Real := X (X'First + I);
            Lo : constant Real := B.Lo (1 + I);
            Hi : constant Real := B.Hi (1 + I);
         begin
            if V < Lo then
               V := Lo;
            elsif V > Hi then
               V := Hi;
            end if;
            R (X'First + I) := V;
         end;
      end loop;
      return R;
   end Project_Box;

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
   begin
      return Scale (2.0, X);
   end Sphere_Grad;

   function Sphere_Hess (X : Point) return Matrix is
      N : constant Dim_Count := X'Length;
      H : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         H (I, I) := 2.0;
      end loop;
      return H;
   end Sphere_Hess;

   function Rosenbrock (X : Point) return Real is
      A : constant Real := 1.0;
      B : constant Real := 100.0;
      XV, YV : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      XV := X (X'First);
      YV := X (X'First + 1);
      return (A - XV) ** 2 + B * (YV - XV ** 2) ** 2;
   end Rosenbrock;

   function Rosenbrock_Grad (X : Point) return Point is
      A : constant Real := 1.0;
      B : constant Real := 100.0;
      XV, YV : Real;
      G : Point (X'Range) := [others => 0.0];
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      XV := X (X'First);
      YV := X (X'First + 1);
      G (X'First)     := -2.0 * (A - XV) - 4.0 * B * XV * (YV - XV ** 2);
      G (X'First + 1) := 2.0 * B * (YV - XV ** 2);
      return G;
   end Rosenbrock_Grad;

   function Rosenbrock_Hess (X : Point) return Matrix is
      B : constant Real := 100.0;
      XV, YV : Real;
      N : constant Dim_Count := X'Length;
      H : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      XV := X (X'First);
      YV := X (X'First + 1);
      --  Analytical 2x2 Rosenbrock Hessian: d2f/dx2 = 2 + 12 b x^2 - 4 b y
      H (1, 1) := 2.0 + 12.0 * B * XV * XV - 4.0 * B * YV;
      H (1, 2) := -4.0 * B * XV;
      H (2, 1) := H (1, 2);
      H (2, 2) := 2.0 * B;
      return H;
   end Rosenbrock_Hess;

   function Quadratic_Bowl (X : Point) return Real is
      S : Real := 0.0;
      K : Real := 1.0;
   begin
      for I in X'Range loop
         S := S + 0.5 * K * X (I) * X (I);
         K := K + 1.0;
      end loop;
      return S;
   end Quadratic_Bowl;

   function Quadratic_Bowl_Grad (X : Point) return Point is
      G : Point (X'Range);
      K : Real := 1.0;
   begin
      for I in X'Range loop
         G (I) := K * X (I);
         K := K + 1.0;
      end loop;
      return G;
   end Quadratic_Bowl_Grad;

   function Quadratic_Bowl_Hess (X : Point) return Matrix is
      N : constant Dim_Count := X'Length;
      H : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      K : Real := 1.0;
   begin
      for I in 1 .. N loop
         H (I, I) := K;
         K := K + 1.0;
      end loop;
      return H;
   end Quadratic_Bowl_Hess;

   function Himmelblau (X : Point) return Real is
      XV, YV : Real;
      T1, T2 : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      XV := X (X'First);
      YV := X (X'First + 1);
      T1 := XV * XV + YV - 11.0;
      T2 := XV + YV * YV - 7.0;
      return T1 * T1 + T2 * T2;
   end Himmelblau;

   function Himmelblau_Grad (X : Point) return Point is
      XV, YV : Real;
      T1, T2 : Real;
      G : Point (X'Range) := [others => 0.0];
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      XV := X (X'First);
      YV := X (X'First + 1);
      T1 := XV * XV + YV - 11.0;
      T2 := XV + YV * YV - 7.0;
      G (X'First)     := 4.0 * XV * T1 + 2.0 * T2;
      G (X'First + 1) := 2.0 * T1 + 4.0 * YV * T2;
      return G;
   end Himmelblau_Grad;

   ---------------------------------------------------------------------------
   -- Steps
   ---------------------------------------------------------------------------

   function Gradient_Descent_Step
     (X : Point; G : Point; Alpha : Real) return Point
   is
   begin
      return Sub (X, Scale (Alpha, G));
   end Gradient_Descent_Step;

   function Projected_Gradient_Step
     (X : Point; G : Point; Alpha : Real; Bounds : Box) return Point
   is
   begin
      return Project_Box (Gradient_Descent_Step (X, G, Alpha), Bounds);
   end Projected_Gradient_Step;

   function Newton_Direction
     (H : Matrix; G : Point) return Point
   is
   begin
      return Scale (-1.0, Solve_SPD (H, G));
   end Newton_Direction;

   ---------------------------------------------------------------------------
   -- Shared eval helpers for drivers
   ---------------------------------------------------------------------------

   function Copy_Result
     (X : Point; F : Real; Gn : Non_Negative;
      Iters : Natural; Ok : Boolean) return Result
   is
      R : Result;
      N : constant Dim_Count := X'Length;
   begin
      R.Dim := N;
      R.Final_Value := F;
      R.Final_Grad_Norm := Gn;
      R.Iterations := Iters;
      R.Success := Ok;
      for I in 0 .. N - 1 loop
         R.Final_Point (1 + I) := X (X'First + I);
      end loop;
      return R;
   end Copy_Result;

   ---------------------------------------------------------------------------
   -- Minimize_GD
   ---------------------------------------------------------------------------

   function Minimize_GD
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Gradient_Fn := null;
      Cfg       : Config := Default_Config) return Result
   is
      X : Point (X0'Range) := X0;
      G : Point (X0'Range);
      P : Point (X0'Range);
      F : Real;
      Alpha : Real;
      Gn : Non_Negative;
      Step_Len : Non_Negative;

      function Eval_Grad (Y : Point) return Point is
      begin
         if Grad /= null then
            return Grad (Y);
         else
            return Finite_Difference_Gradient (Objective, Y, Cfg.Fd_Eps);
         end if;
      end Eval_Grad;
   begin
      F := Objective (X);
      G := Eval_Grad (X);
      Gn := Grad_Norm (G);

      for Iter in 1 .. Cfg.Max_Iterations loop
         if Gn <= Cfg.Grad_Tol then
            return Copy_Result (X, F, Gn, Iter - 1, True);
         end if;

         P := Scale (-1.0, G);

         if Cfg.Use_Armijo then
            begin
               Alpha := Real (Line_Search
                 (Objective, X, F, G, P,
                  Cfg.Armijo_C, Cfg.Line_Search_Rho, Cfg.Max_Line_Search));
            exception
               when Line_Search_Failed =>
                  return Copy_Result (X, F, Gn, Iter - 1, False);
            end;
         else
            Alpha := Real (Cfg.Step_Size);
         end if;

         declare
            X_New : constant Point := Add (X, Scale (Alpha, P));
         begin
            Step_Len := Norm2 (Sub (X_New, X));
            X := X_New;
         end;
         F := Objective (X);
         G := Eval_Grad (X);
         Gn := Grad_Norm (G);

         if Step_Len <= Cfg.Step_Tol then
            return Copy_Result (X, F, Gn, Iter, Gn <= Cfg.Grad_Tol);
         end if;
      end loop;

      return Copy_Result (X, F, Gn, Cfg.Max_Iterations, Gn <= Cfg.Grad_Tol);
   end Minimize_GD;

   ---------------------------------------------------------------------------
   -- Minimize_Newton
   ---------------------------------------------------------------------------

   function Minimize_Newton
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Gradient_Fn := null;
      Hess      : Hessian_Fn := null;
      Cfg       : Config := Default_Config) return Result
   is
      X : Point (X0'Range) := X0;
      G : Point (X0'Range);
      P : Point (X0'Range);
      H : Matrix (1 .. X0'Length, 1 .. X0'Length);
      F : Real;
      Alpha : Real;
      Gn : Non_Negative;
      Step_Len : Non_Negative;
      Dir_Deriv : Real;

      function Eval_Grad (Y : Point) return Point is
      begin
         if Grad /= null then
            return Grad (Y);
         else
            return Finite_Difference_Gradient (Objective, Y, Cfg.Fd_Eps);
         end if;
      end Eval_Grad;

      function Eval_Hess (Y : Point) return Matrix is
      begin
         if Hess /= null then
            return Hess (Y);
         else
            return Finite_Difference_Hessian (Objective, Y, 1.0E-5);
         end if;
      end Eval_Hess;
   begin
      F := Objective (X);
      G := Eval_Grad (X);
      Gn := Grad_Norm (G);

      for Iter in 1 .. Cfg.Max_Iterations loop
         if Gn <= Cfg.Grad_Tol then
            return Copy_Result (X, F, Gn, Iter - 1, True);
         end if;
         begin
            H := Eval_Hess (X);
            P := Newton_Direction (H, G);
         exception
            when Singular_System =>
               --  Fall back to steepest descent if Hessian is singular.
               P := Scale (-1.0, G);
         end;

         Dir_Deriv := Dot (G, P);
         if Dir_Deriv >= 0.0 then
            --  Not a descent direction → steepest descent fallback.
            P := Scale (-1.0, G);
         end if;

         if Cfg.Use_Armijo then
            begin
               Alpha := Real (Line_Search
                 (Objective, X, F, G, P,
                  Cfg.Armijo_C, Cfg.Line_Search_Rho, Cfg.Max_Line_Search));
            exception
               when Line_Search_Failed =>
                  return Copy_Result (X, F, Gn, Iter - 1, False);
            end;
         else
            Alpha := 1.0;
         end if;

         declare
            X_New : constant Point := Add (X, Scale (Alpha, P));
         begin
            Step_Len := Norm2 (Sub (X_New, X));
            X := X_New;
         end;
         F := Objective (X);
         G := Eval_Grad (X);
         Gn := Grad_Norm (G);

         if Step_Len <= Cfg.Step_Tol then
            return Copy_Result (X, F, Gn, Iter, Gn <= Cfg.Grad_Tol);
         end if;
      end loop;

      return Copy_Result (X, F, Gn, Cfg.Max_Iterations, Gn <= Cfg.Grad_Tol);
   end Minimize_Newton;

   ---------------------------------------------------------------------------
   -- Minimize_Projected_GD
   ---------------------------------------------------------------------------

   function Minimize_Projected_GD
     (Objective : Objective_Fn;
      X0        : Point;
      Bounds    : Box;
      Grad      : Gradient_Fn := null;
      Cfg       : Config := Default_Config) return Result
   is
      X : Point (X0'Range) := Project_Box (X0, Bounds);
      G : Point (X0'Range);
      F : Real;
      Alpha : Real;
      Gn : Non_Negative;
      Step_Len : Non_Negative;
      X_New : Point (X0'Range);

      function Eval_Grad (Y : Point) return Point is
      begin
         if Grad /= null then
            return Grad (Y);
         else
            return Finite_Difference_Gradient (Objective, Y, Cfg.Fd_Eps);
         end if;
      end Eval_Grad;
   begin
      F := Objective (X);
      G := Eval_Grad (X);
      Gn := Grad_Norm (G);

      for Iter in 1 .. Cfg.Max_Iterations loop
         --  For bound constraints, stationarity is more subtle; use
         --  projected gradient residual ‖x − Π(x − g)‖ as a proxy,
         --  plus plain ‖g‖ when interior.
         declare
            Residual : constant Point :=
              Sub (X, Project_Box (Sub (X, G), Bounds));
            Res_Norm : constant Non_Negative := Norm2 (Residual);
         begin
            if Res_Norm <= Cfg.Grad_Tol then
               return Copy_Result (X, F, Gn, Iter - 1, True);
            end if;
         end;

         if Cfg.Use_Armijo then
            --  Simple Armijo along projected direction with fixed
            --  backtracking on the projected point.
            Alpha := 1.0;
            declare
               Accepted : Boolean := False;
               F_Trial  : Real;
               Dir_Deriv : constant Real := -Dot (G, G);
            begin
               for K in 1 .. Cfg.Max_Line_Search loop
                  X_New := Projected_Gradient_Step (X, G, Alpha, Bounds);
                  F_Trial := Objective (X_New);
                  if Armijo_Accept
                    (F_Trial, F, Alpha, Cfg.Armijo_C, Dir_Deriv)
                  then
                     Accepted := True;
                     exit;
                  end if;
                  Alpha := Alpha * Real (Cfg.Line_Search_Rho);
               end loop;
               if not Accepted then
                  return Copy_Result (X, F, Gn, Iter - 1, False);
               end if;
            end;
         else
            Alpha := Real (Cfg.Step_Size);
            X_New := Projected_Gradient_Step (X, G, Alpha, Bounds);
         end if;

         Step_Len := Norm2 (Sub (X_New, X));
         X := X_New;
         F := Objective (X);
         G := Eval_Grad (X);
         Gn := Grad_Norm (G);

         if Step_Len <= Cfg.Step_Tol then
            return Copy_Result (X, F, Gn, Iter, True);
         end if;
      end loop;

      return Copy_Result (X, F, Gn, Cfg.Max_Iterations, False);
   end Minimize_Projected_GD;

   ---------------------------------------------------------------------------
   -- Method catalog
   ---------------------------------------------------------------------------

   function Classify_Method (K : Method_Kind) return Method_Info is
   begin
      case K is
         when Gradient_Descent =>
            return (Gradient_Descent, True, False, False);
         when Newton =>
            return (Newton, True, True, False);
         when Quasi_Newton_BFGS =>
            return (Quasi_Newton_BFGS, True, False, False);
         when Gauss_Newton =>
            return (Gauss_Newton, True, False, False);
         when Levenberg_Marquardt =>
            return (Levenberg_Marquardt, True, False, False);
         when Nelder_Mead =>
            return (Nelder_Mead, False, False, True);
         when Simulated_Annealing =>
            return (Simulated_Annealing, False, False, True);
      end case;
   end Classify_Method;

   function Method_Name (K : Method_Kind) return String is
   begin
      case K is
         when Gradient_Descent =>
            return "Gradient Descent";
         when Newton =>
            return "Newton";
         when Quasi_Newton_BFGS =>
            return "Quasi-Newton BFGS";
         when Gauss_Newton =>
            return "Gauss-Newton";
         when Levenberg_Marquardt =>
            return "Levenberg-Marquardt";
         when Nelder_Mead =>
            return "Nelder-Mead";
         when Simulated_Annealing =>
            return "Simulated Annealing";
      end case;
   end Method_Name;

   function Method_Count return Positive is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
        - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

   ---------------------------------------------------------------------------
   -- Compare_Fixed_Step_GD
   ---------------------------------------------------------------------------

   function Compare_Fixed_Step_GD
     (Objective  : Objective_Fn;
      X0         : Point;
      Grad       : Gradient_Fn;
      Step_Sizes : Point;
      Max_Iters  : Positive := 100;
      Grad_Tol   : Non_Negative := 1.0E-8) return Compare_Table
   is
      T : Compare_Table (1 .. Step_Sizes'Length);
      Cfg : Config;
      R : Result;
      Idx : Positive := 1;
   begin
      Cfg := Default_Config;
      Cfg.Use_Armijo := False;
      Cfg.Max_Iterations := Max_Iters;
      Cfg.Grad_Tol := Grad_Tol;

      for I in Step_Sizes'Range loop
         Cfg.Step_Size := Positive_Real (Step_Sizes (I));
         R := Minimize_GD (Objective, X0, Grad, Cfg);
         T (Idx) :=
           (Step_Size   => Positive_Real (Step_Sizes (I)),
            Final_Value => R.Final_Value,
            Grad_Norm   => R.Final_Grad_Norm,
            Iterations  => R.Iterations,
            Success     => R.Success);
         Idx := Idx + 1;
      end loop;
      return T;
   end Compare_Fixed_Step_GD;

end Nonlinear_Optimization;
