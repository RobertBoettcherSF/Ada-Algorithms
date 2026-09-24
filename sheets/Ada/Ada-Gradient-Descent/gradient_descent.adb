--  Gradient_Descent body — fixed-step / Armijo / heavy-ball first-order
--  unconstrained minimization and ascent (Cauchy 1847; Wikipedia).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Gradient_Descent
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

   ---------------------------------------------------------------------------
   -- FD gradient / Armijo / steps
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
      Alpha0 : Positive_Real;
      C1     : Positive_Real;
      Rho    : Positive_Real;
      Max_LS : Positive) return Positive_Real
   is
      Alpha     : Real := Real (Alpha0);
      Dir_Deriv : constant Real := Dot (G, P);
      X_Trial   : Point (X'Range);
      F_Trial   : Real;
   begin
      for K in 1 .. Max_LS loop
         X_Trial := Add (X, Scale (Alpha, P));
         F_Trial := Obj (X_Trial);
         if Armijo_Accept (F_Trial, F, Alpha, C1, Dir_Deriv) then
            if Alpha <= 0.0 then
               raise Line_Search_Failed;
            end if;
            return Positive_Real (Alpha);
         end if;
         Alpha := Alpha * Rho;
      end loop;
      raise Line_Search_Failed;
   end Line_Search;

   function Descent_Step
     (X : Point; G : Point; Eta : Real) return Point
   is
   begin
      return Sub (X, Scale (Eta, G));
   end Descent_Step;

   function Ascent_Step
     (X : Point; G : Point; Eta : Real) return Point
   is
   begin
      return Add (X, Scale (Eta, G));
   end Ascent_Step;

   function Momentum_Step
     (X : Point; V : in out Point; G : Point; Eta, Beta : Real) return Point
   is
   begin
      --  v ← β v − η g
      V := Sub (Scale (Beta, V), Scale (Eta, G));
      --  x ← x + v
      return Add (X, V);
   end Momentum_Step;

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


   function Negated_Sphere (X : Point) return Real is
   begin
      return -Sphere (X);
   end Negated_Sphere;

   function Negated_Sphere_Grad (X : Point) return Point is
   begin
      return Scale (-1.0, Sphere_Grad (X));
   end Negated_Sphere_Grad;


   ---------------------------------------------------------------------------
   -- Shared result packing / gradient eval
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
   -- Minimize
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Grad_Fn := null;
      Cfg       : Config := Default_Config) return Result
   is
      X        : Point (X0'Range) := X0;
      G        : Point (X0'Range);
      P        : Point (X0'Range);
      F        : Real;
      Alpha    : Real;
      Gn       : Non_Negative;
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
      F  := Objective (X);
      G  := Eval_Grad (X);
      Gn := Norm2 (G);

      for Iter in 1 .. Cfg.Max_Iterations loop
         if Gn <= Cfg.Grad_Tol then
            return Copy_Result (X, F, Gn, Iter - 1, True);
         end if;

         P := Scale (-1.0, G);

         if Cfg.Use_Line_Search then
            begin
               Alpha := Real (Line_Search
                 (Objective, X, F, G, P,
                  Cfg.Step, Cfg.Armijo_C, Cfg.Line_Search_Rho,
                  Cfg.Max_Line_Search));
            exception
               when Line_Search_Failed =>
                  return Copy_Result (X, F, Gn, Iter - 1, False);
            end;
         else
            Alpha := Real (Cfg.Step);
         end if;

         declare
            X_New : constant Point := Add (X, Scale (Alpha, P));
         begin
            Step_Len := Norm2 (Sub (X_New, X));
            X := X_New;
         end;
         F  := Objective (X);
         G  := Eval_Grad (X);
         Gn := Norm2 (G);

         if Step_Len <= Cfg.Step_Tol then
            return Copy_Result (X, F, Gn, Iter, Gn <= Cfg.Grad_Tol);
         end if;
      end loop;

      return Copy_Result (X, F, Gn, Cfg.Max_Iterations, Gn <= Cfg.Grad_Tol);
   end Minimize;

   ---------------------------------------------------------------------------
   -- Maximize (gradient ascent)
   ---------------------------------------------------------------------------

   function Maximize
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Grad_Fn := null;
      Cfg       : Config := Default_Config) return Result
   is
      X        : Point (X0'Range) := X0;
      G        : Point (X0'Range);
      P        : Point (X0'Range);
      F        : Real;
      Alpha    : Real;
      Gn       : Non_Negative;
      Step_Len : Non_Negative;
      Accepted : Boolean;

      function Eval_Grad (Y : Point) return Point is
      begin
         if Grad /= null then
            return Grad (Y);
         else
            return Finite_Difference_Gradient (Objective, Y, Cfg.Fd_Eps);
         end if;
      end Eval_Grad;
   begin
      F  := Objective (X);
      G  := Eval_Grad (X);
      Gn := Norm2 (G);

      for Iter in 1 .. Cfg.Max_Iterations loop
         if Gn <= Cfg.Grad_Tol then
            return Copy_Result (X, F, Gn, Iter - 1, True);
         end if;

         --  Ascent direction +∇f. Armijo on −f:
         --  −f(x+αp) ≤ −f(x) + c1 α (−gᵀp)  ⇔  f increases enough.
         P := G;

         if Cfg.Use_Line_Search then
            Alpha := Real (Cfg.Step);
            Accepted := False;
            declare
               Dir_Deriv_Neg : constant Real := -Dot (G, P);
               --  φ'(0) for φ=−f along p=+g is −‖g‖².
               X_Trial : Point (X'Range);
               F_Trial : Real;
            begin
               for K in 1 .. Cfg.Max_Line_Search loop
                  X_Trial := Add (X, Scale (Alpha, P));
                  F_Trial := Objective (X_Trial);
                  --  Armijo for −f: −F_Trial ≤ −F + c1 α Dir_Deriv_Neg
                  if Armijo_Accept
                    (-F_Trial, -F, Alpha, Cfg.Armijo_C, Dir_Deriv_Neg)
                  then
                     Accepted := True;
                     exit;
                  end if;
                  Alpha := Alpha * Cfg.Line_Search_Rho;
               end loop;
            end;
            if not Accepted or else Alpha <= 0.0 then
               return Copy_Result (X, F, Gn, Iter - 1, False);
            end if;
         else
            Alpha := Real (Cfg.Step);
         end if;

         declare
            X_New : constant Point := Add (X, Scale (Alpha, P));
         begin
            Step_Len := Norm2 (Sub (X_New, X));
            X := X_New;
         end;
         F  := Objective (X);
         G  := Eval_Grad (X);
         Gn := Norm2 (G);

         if Step_Len <= Cfg.Step_Tol then
            return Copy_Result (X, F, Gn, Iter, Gn <= Cfg.Grad_Tol);
         end if;
      end loop;

      return Copy_Result (X, F, Gn, Cfg.Max_Iterations, Gn <= Cfg.Grad_Tol);
   end Maximize;

   ---------------------------------------------------------------------------
   -- Minimize_Momentum (heavy-ball)
   ---------------------------------------------------------------------------

   function Minimize_Momentum
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Grad_Fn := null;
      Cfg       : Config := Default_Config) return Result
   is
      X        : Point (X0'Range) := X0;
      V        : Point (X0'Range) := [others => 0.0];
      G        : Point (X0'Range);
      F        : Real;
      Gn       : Non_Negative;
      Step_Len : Non_Negative;
      Beta     : constant Real := Real (Cfg.Momentum_Beta);
      Eta      : constant Real := Real (Cfg.Step);

      function Eval_Grad (Y : Point) return Point is
      begin
         if Grad /= null then
            return Grad (Y);
         else
            return Finite_Difference_Gradient (Objective, Y, Cfg.Fd_Eps);
         end if;
      end Eval_Grad;
   begin
      F  := Objective (X);
      G  := Eval_Grad (X);
      Gn := Norm2 (G);

      for Iter in 1 .. Cfg.Max_Iterations loop
         if Gn <= Cfg.Grad_Tol then
            return Copy_Result (X, F, Gn, Iter - 1, True);
         end if;

         declare
            X_New : constant Point :=
              Momentum_Step (X, V, G, Eta, Beta);
         begin
            Step_Len := Norm2 (Sub (X_New, X));
            X := X_New;
         end;
         F  := Objective (X);
         G  := Eval_Grad (X);
         Gn := Norm2 (G);

         if Step_Len <= Cfg.Step_Tol then
            return Copy_Result (X, F, Gn, Iter, Gn <= Cfg.Grad_Tol);
         end if;
      end loop;

      return Copy_Result (X, F, Gn, Cfg.Max_Iterations, Gn <= Cfg.Grad_Tol);
   end Minimize_Momentum;

end Gradient_Descent;
