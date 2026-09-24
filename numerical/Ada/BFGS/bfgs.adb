--  BFGS body — inverse-Hessian quasi-Newton update with Armijo
--  backtracking line search (Broyden, Fletcher, Goldfarb, Shanno;
--  Wikipedia algorithm).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body BFGS
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
      R : Point (X'Range) := [others => 0.0];
      N : constant Dim_Count := X'Length;
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

   function Outer (U, V : Point) return Matrix is
      N  : constant Dim_Count := U'Length;
      M  : Matrix (1 .. N, 1 .. N);
      UI : Dim_Index := U'First;
      VJ : Dim_Index;
   begin
      for I in 1 .. N loop
         VJ := V'First;
         for J in 1 .. N loop
            M (I, J) := U (UI) * V (VJ);
            if VJ < V'Last then
               VJ := VJ + 1;
            end if;
         end loop;
         if UI < U'Last then
            UI := UI + 1;
         end if;
      end loop;
      return M;
   end Outer;

   function Mat_Add (A, B : Matrix) return Matrix is
      N : constant Dim_Count := A'Length (1);
      R : Matrix (1 .. N, 1 .. N);
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
      N : constant Dim_Count := A'Length (1);
      R : Matrix (1 .. N, 1 .. N);
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

   --  Dense matrix product C = A B for square matrices of equal size.
   function Mat_Mul (A, B : Matrix) return Matrix is
      N : constant Dim_Count := A'Length (1);
      C : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      AR : constant Dim_Index := A'First (1);
      AC : constant Dim_Index := A'First (2);
      BR : constant Dim_Index := B'First (1);
      BC : constant Dim_Index := B'First (2);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            declare
               Acc : Real := 0.0;
            begin
               for K in 0 .. N - 1 loop
                  Acc := Acc + A (AR + I, AC + K) * B (BR + K, BC + J);
               end loop;
               C (1 + I, 1 + J) := Acc;
            end;
         end loop;
      end loop;
      return C;
   end Mat_Mul;

   ---------------------------------------------------------------------------
   -- BFGS update / FD gradient / line search
   ---------------------------------------------------------------------------

   function BFGS_Update
     (H : Matrix; S, Y : Point) return Matrix
   is
      N     : constant Dim_Count := S'Length;
      Ys    : constant Real := Dot (Y, S);
      Rho   : Real;
      I_Mat : Matrix (1 .. N, 1 .. N);
      A_L   : Matrix (1 .. N, 1 .. N);
      A_R   : Matrix (1 .. N, 1 .. N);
      Tmp   : Matrix (1 .. N, 1 .. N);
      H_New : Matrix (1 .. N, 1 .. N);
      H_Work : Matrix (1 .. N, 1 .. N);
      AR : constant Dim_Index := H'First (1);
      AC : constant Dim_Index := H'First (2);
   begin
      --  Curvature safeguard: skip update when yᵀs ≤ 0.
      if Ys <= 0.0 then
         H_Work := [others => [others => 0.0]];
         for I in 0 .. N - 1 loop
            for J in 0 .. N - 1 loop
               H_Work (1 + I, 1 + J) := H (AR + I, AC + J);
            end loop;
         end loop;
         return H_Work;
      end if;

      Rho := 1.0 / Ys;

      --  Copy H into 1 .. N indexing.
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            H_Work (1 + I, 1 + J) := H (AR + I, AC + J);
         end loop;
      end loop;

      I_Mat := Identity (N);
      --  (I − ρ s yᵀ)
      A_L := Mat_Add (I_Mat, Mat_Scale (-Rho, Outer (S, Y)));
      --  (I − ρ y sᵀ)
      A_R := Mat_Add (I_Mat, Mat_Scale (-Rho, Outer (Y, S)));
      --  (I − ρ s yᵀ) H (I − ρ y sᵀ)
      Tmp   := Mat_Mul (H_Work, A_R);
      H_New := Mat_Mul (A_L, Tmp);
      --  + ρ s sᵀ
      H_New := Mat_Add (H_New, Mat_Scale (Rho, Outer (S, S)));
      return H_New;
   end BFGS_Update;

   function Finite_Difference_Gradient
     (Obj : Objective_Fn;
      X   : Point;
      Eps : Positive_Real := 1.0E-7) return Point
   is
      G   : Point (X'Range);
      Xp  : Point (X'Range);
      Xm  : Point (X'Range);
      H   : Real;
      Fp  : Real;
      Fm  : Real;
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
     (Obj     : Objective_Fn;
      X       : Point;
      F       : Real;
      G       : Point;
      P       : Point;
      C1      : Positive_Real;
      Rho     : Positive_Real;
      Max_LS  : Positive) return Positive_Real
   is
      Alpha      : Real := 1.0;
      Dir_Deriv  : constant Real := Dot (G, P);
      X_Trial    : Point (X'Range);
      F_Trial    : Real;
   begin
      --  p should be a descent direction; if not, still try α shrinks.
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
      --  df/dx = -2(a-x) - 4 b x (y-x^2)
      --  df/dy = 2 b (y-x^2)
      G (X'First)     := -2.0 * (A - XV) - 4.0 * B * XV * (YV - XV ** 2);
      G (X'First + 1) := 2.0 * B * (YV - XV ** 2);
      return G;
   end Rosenbrock_Grad;

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

   function Shifted_Sphere (X : Point) return Real is
      S : Real := 0.0;
      D : Real;
   begin
      for I in X'Range loop
         D := X (I) - 1.0;
         S := S + D * D;
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

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      Grad      : Gradient_Fn := null;
      Cfg       : Config := (others => <>)) return Result
   is
      N : constant Dim_Count := X0'Length;

      function Eval_Grad (X : Point) return Point is
      begin
         if Grad /= null then
            return Grad (X);
         else
            return Finite_Difference_Gradient (Objective, X, Cfg.Fd_Eps);
         end if;
      end Eval_Grad;

      X      : Point (1 .. N);
      G      : Point (1 .. N);
      G_New  : Point (1 .. N);
      P      : Point (1 .. N);
      S      : Point (1 .. N);
      Y      : Point (1 .. N);
      H      : Matrix (1 .. N, 1 .. N);
      F      : Real;
      F_New  : Real;
      Alpha  : Positive_Real;
      G_Norm : Non_Negative;
      Step_N : Non_Negative;
      Ys     : Real;
      Yy     : Real;
      First_Update : Boolean := True;
      R      : Result;
      XI     : Dim_Index := X0'First;
   begin
      for I in 1 .. N loop
         X (I) := X0 (XI);
         if XI < X0'Last then
            XI := XI + 1;
         end if;
      end loop;

      H := Identity (N);
      F := Objective (X);
      G := Eval_Grad (X);
      G_Norm := Norm2 (G);

      R.Dim := N;
      R.Final_Value := F;
      R.Final_Grad_Norm := G_Norm;
      for I in 1 .. N loop
         R.Final_Point (I) := X (I);
      end loop;

      if G_Norm <= Cfg.Grad_Tol then
         R.Success := True;
         R.Iterations := 0;
         return R;
      end if;

      for Iter in 1 .. Cfg.Max_Iterations loop
         --  Search direction p = −H g
         P := Scale (-1.0, Mat_Vec (H, G));

         --  Ensure descent: if gᵀp ≥ 0, reset H = I and use −g
         if Dot (G, P) >= 0.0 then
            H := Identity (N);
            P := Scale (-1.0, G);
            First_Update := True;
         end if;

         begin
            Alpha := Line_Search
              (Objective, X, F, G, P,
               Cfg.Armijo_C, Cfg.Line_Search_Rho, Cfg.Max_Line_Search);
         exception
            when Line_Search_Failed =>
               R.Iterations := Iter - 1;
               R.Final_Value := F;
               R.Final_Grad_Norm := Norm2 (G);
               for I in 1 .. N loop
                  R.Final_Point (I) := X (I);
               end loop;
               R.Success := R.Final_Grad_Norm <= Cfg.Grad_Tol;
               return R;
         end;

         S := Scale (Alpha, P);
         Step_N := Norm2 (S);
         X := Add (X, S);
         F_New := Objective (X);
         G_New := Eval_Grad (X);
         Y := Sub (G_New, G);
         Ys := Dot (Y, S);

         --  Optional initial scaling of H before first BFGS update
         if First_Update and then Cfg.Scale_Initial_H and then Ys > 0.0 then
            Yy := Dot (Y, Y);
            if Yy > 0.0 then
               H := Mat_Scale (Ys / Yy, Identity (N));
            end if;
         end if;

         H := BFGS_Update (H, S, Y);
         First_Update := False;

         F := F_New;
         G := G_New;
         G_Norm := Norm2 (G);

         R.Iterations := Iter;
         R.Final_Value := F;
         R.Final_Grad_Norm := G_Norm;
         for I in 1 .. N loop
            R.Final_Point (I) := X (I);
         end loop;

         if G_Norm <= Cfg.Grad_Tol or else Step_N <= Cfg.Step_Tol then
            R.Success := True;
            return R;
         end if;
      end loop;

      R.Success := G_Norm <= Cfg.Grad_Tol;
      return R;
   end Minimize;

end BFGS;
