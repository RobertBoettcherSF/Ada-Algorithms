--  Newtons_Method_Optimization body — educational Newton / damped Newton
--  with optional Hessian τ I regularization (Wikipedia optimization form).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Newtons_Method_Optimization
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

   function Mat_Add (A, B : Matrix) return Matrix is
      N  : constant Dim_Count := A'Length (1);
      R  : Matrix (1 .. N, 1 .. N);
      AR : constant Dim_Index := A'First (1);
      AC : constant Dim_Index := A'First (2);
      BR : constant Dim_Index := B'First (1);
      BC : constant Dim_Index := B'First (2);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            R (1 + I, 1 + J) :=
              A (AR + I, AC + J) + B (BR + I, BC + J);
         end loop;
      end loop;
      return R;
   end Mat_Add;

   function Mat_Scale (C : Real; A : Matrix) return Matrix is
      N  : constant Dim_Count := A'Length (1);
      R  : Matrix (1 .. N, 1 .. N);
      AR : constant Dim_Index := A'First (1);
      AC : constant Dim_Index := A'First (2);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            R (1 + I, 1 + J) := C * A (AR + I, AC + J);
         end loop;
      end loop;
      return R;
   end Mat_Scale;

   function Quadratic_Form (H : Matrix; X : Point) return Real is
   begin
      return Dot (X, Mat_Vec (H, X));
   end Quadratic_Form;

   ---------------------------------------------------------------------------
   -- Solve_Linear (Gaussian elimination with partial pivoting)
   ---------------------------------------------------------------------------

   function Solve_Linear
     (A : Matrix; B : Point) return Point
   is
      N       : constant Dim_Count := B'Length;
      M       : array (1 .. N, 1 .. N) of Real;
      Rhs     : array (1 .. N) of Real;
      X       : Point (1 .. N) := [others => 0.0];
      Pivot   : Dim_Index;
      Max_Abs : Real;
      Tmp     : Real;
      Factor  : Real;
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
   end Solve_Linear;

   ---------------------------------------------------------------------------
   -- Symmetry / Sylvester PD-ish / regularization
   ---------------------------------------------------------------------------

   function Is_Symmetric
     (H : Matrix; Tol : Real := 1.0E-10) return Boolean
   is
      N  : constant Dim_Count := H'Length (1);
      AR : constant Dim_Index := H'First (1);
      AC : constant Dim_Index := H'First (2);
   begin
      for I in 0 .. N - 1 loop
         for J in I + 1 .. N - 1 loop
            if abs (H (AR + I, AC + J) - H (AR + J, AC + I)) > Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

   --  Determinant of leading K×K principal minor via GE (no pivoting
   --  on sign tracking beyond product of pivots after row swaps).
   function Leading_Minor_Det
     (H : Matrix; K : Dim_Count) return Real
   is
      AR : constant Dim_Index := H'First (1);
      AC : constant Dim_Index := H'First (2);
      M  : array (1 .. K, 1 .. K) of Real;
      Det : Real := 1.0;
      Pivot : Dim_Index;
      Max_Abs : Real;
      Tmp : Real;
      Factor : Real;
      Sign : Real := 1.0;
   begin
      for I in 1 .. K loop
         for J in 1 .. K loop
            M (I, J) := H (AR + (I - 1), AC + (J - 1));
         end loop;
      end loop;

      for Col in 1 .. K loop
         Pivot := Col;
         Max_Abs := abs (M (Col, Col));
         for I in Col + 1 .. K loop
            if abs (M (I, Col)) > Max_Abs then
               Max_Abs := abs (M (I, Col));
               Pivot := I;
            end if;
         end loop;

         if Max_Abs < 1.0E-30 then
            return 0.0;
         end if;

         if Pivot /= Col then
            Sign := -Sign;
            for J in Col .. K loop
               Tmp := M (Col, J);
               M (Col, J) := M (Pivot, J);
               M (Pivot, J) := Tmp;
            end loop;
         end if;

         Det := Det * M (Col, Col);

         for I in Col + 1 .. K loop
            Factor := M (I, Col) / M (Col, Col);
            for J in Col + 1 .. K loop
               M (I, J) := M (I, J) - Factor * M (Col, J);
            end loop;
         end loop;
      end loop;

      return Sign * Det;
   end Leading_Minor_Det;

   function Is_Positive_Definite_Ish
     (H : Matrix; Tol : Real := 1.0E-12) return Boolean
   is
      N : constant Dim_Count := H'Length (1);
      D : Real;
   begin
      if not Is_Symmetric (H, 1.0E-8) then
         return False;
      end if;
      for K in 1 .. N loop
         D := Leading_Minor_Det (H, K);
         if D <= Tol then
            return False;
         end if;
      end loop;
      return True;
   end Is_Positive_Definite_Ish;

   function Regularize_Hessian
     (H : Matrix; Tau : Non_Negative) return Matrix
   is
      N  : constant Dim_Count := H'Length (1);
      R  : Matrix (1 .. N, 1 .. N);
      AR : constant Dim_Index := H'First (1);
      AC : constant Dim_Index := H'First (2);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            R (1 + I, 1 + J) := H (AR + I, AC + J);
         end loop;
         R (1 + I, 1 + I) := R (1 + I, 1 + I) + Tau;
      end loop;
      return R;
   end Regularize_Hessian;

   function Make_PD_Hessian
     (H        : Matrix;
      Tau0     : Positive_Real := 1.0E-6;
      Grow     : Positive_Real := 10.0;
      Tau_Max  : Positive_Real := 1.0E8;
      Used_Reg : access Boolean := null) return Matrix
   is
      Tau  : Real := 0.0;
      Work : Matrix := H;
      Did  : Boolean := False;
   begin
      if Is_Positive_Definite_Ish (H) then
         if Used_Reg /= null then
            Used_Reg.all := False;
         end if;
         return H;
      end if;

      Tau := Real (Tau0);
      loop
         Work := Regularize_Hessian (H, Non_Negative (Tau));
         Did := True;
         exit when Is_Positive_Definite_Ish (Work);
         exit when Tau >= Real (Tau_Max);
         Tau := Tau * Real (Grow);
         if Tau > Real (Tau_Max) then
            Tau := Real (Tau_Max);
            Work := Regularize_Hessian (H, Non_Negative (Tau));
            exit;
         end if;
      end loop;

      if Used_Reg /= null then
         Used_Reg.all := Did;
      end if;
      return Work;
   end Make_PD_Hessian;

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
   -- Newton direction
   ---------------------------------------------------------------------------

   function Newton_Direction
     (H : Matrix; G : Point) return Point
   is
   begin
      return Scale (-1.0, Solve_Linear (H, G));
   end Newton_Direction;

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
      H (1, 1) := 2.0 + 12.0 * B * XV * XV - 4.0 * B * YV;
      H (1, 2) := -4.0 * B * XV;
      H (2, 1) := H (1, 2);
      H (2, 2) := 2.0 * B;
      return H;
   end Rosenbrock_Hess;

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

   function Himmelblau_Hess (X : Point) return Matrix is
      XV, YV : Real;
      T1, T2 : Real;
      N : constant Dim_Count := X'Length;
      H : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      XV := X (X'First);
      YV := X (X'First + 1);
      T1 := XV * XV + YV - 11.0;
      T2 := XV + YV * YV - 7.0;
      H (1, 1) := 4.0 * T1 + 8.0 * XV * XV + 2.0;
      H (1, 2) := 4.0 * XV + 4.0 * YV;
      H (2, 1) := H (1, 2);
      H (2, 2) := 2.0 + 4.0 * T2 + 8.0 * YV * YV;
      return H;
   end Himmelblau_Hess;

   function Quartic_1D (X : Point) return Real is
      T : Real;
   begin
      T := X (X'First) - 3.0;
      return T ** 4;
   end Quartic_1D;

   function Quartic_1D_Grad (X : Point) return Point is
      T : Real;
      G : Point (X'Range) := [others => 0.0];
   begin
      T := X (X'First) - 3.0;
      G (X'First) := 4.0 * T ** 3;
      return G;
   end Quartic_1D_Grad;

   function Quartic_1D_Hess (X : Point) return Matrix is
      T : Real;
      N : constant Dim_Count := X'Length;
      H : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      T := X (X'First) - 3.0;
      H (1, 1) := 12.0 * T * T;
      return H;
   end Quartic_1D_Hess;

   function Shifted_Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + (X (I) - 1.0) ** 2;
      end loop;
      return S;
   end Shifted_Sphere;

   function Shifted_Sphere_Grad (X : Point) return Point is
      G : Point (X'Range);
   begin
      for I in X'Range loop
         G (I) := 2.0 * (X (I) - 1.0);
      end loop;
      return G;
   end Shifted_Sphere_Grad;

   function Shifted_Sphere_Hess (X : Point) return Matrix is
      N : constant Dim_Count := X'Length;
      H : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         H (I, I) := 2.0;
      end loop;
      return H;
   end Shifted_Sphere_Hess;

   ---------------------------------------------------------------------------
   -- Driver helpers
   ---------------------------------------------------------------------------

   function Copy_Result
     (X : Point; F : Real; Gn : Non_Negative;
      Iters : Natural; Ok : Boolean; Reg : Boolean) return Result
   is
      R : Result;
      N : constant Dim_Count := X'Length;
   begin
      R.Dim := N;
      R.Final_Value := F;
      R.Final_Grad_Norm := Gn;
      R.Iterations := Iters;
      R.Success := Ok;
      R.Regularized := Reg;
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
      Any_Reg : Boolean := False;
      Used : aliased Boolean := False;

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
            return Finite_Difference_Hessian
              (Objective, Y, Cfg.Fd_Hess_Eps);
         end if;
      end Eval_Hess;
   begin
      F := Objective (X);
      G := Eval_Grad (X);
      Gn := Norm2 (G);

      for Iter in 1 .. Cfg.Max_Iterations loop
         if Gn <= Cfg.Grad_Tol then
            return Copy_Result (X, F, Gn, Iter - 1, True, Any_Reg);
         end if;

         begin
            H := Eval_Hess (X);
            if Cfg.Hessian_Regularization then
               Used := False;
               H := Make_PD_Hessian
                 (H, Cfg.Reg_Tau0, Cfg.Reg_Tau_Grow, Cfg.Reg_Tau_Max,
                  Used'Access);
               if Used then
                  Any_Reg := True;
               end if;
            end if;
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

         if Cfg.Use_Line_Search then
            begin
               Alpha := Real (Line_Search
                 (Objective, X, F, G, P,
                  Cfg.Armijo_C, Cfg.Line_Search_Rho, Cfg.Max_Line_Search));
            exception
               when Line_Search_Failed =>
                  return Copy_Result (X, F, Gn, Iter - 1, False, Any_Reg);
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
         Gn := Norm2 (G);

         if Step_Len <= Cfg.Step_Tol then
            return Copy_Result
              (X, F, Gn, Iter, Gn <= Cfg.Grad_Tol, Any_Reg);
         end if;
      end loop;

      return Copy_Result
        (X, F, Gn, Cfg.Max_Iterations, Gn <= Cfg.Grad_Tol, Any_Reg);
   end Minimize;

end Newtons_Method_Optimization;
