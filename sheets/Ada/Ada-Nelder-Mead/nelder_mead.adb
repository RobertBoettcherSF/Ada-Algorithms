--  Nelder_Mead body — downhill simplex reflection / expansion /
--  contraction / shrink (Nelder & Mead 1965; Wikipedia algorithm).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Nelder_Mead
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

   --  Copy Dim leading coordinates of a Max_Dim-backed vertex vector
   --  into a tight Point (1 .. Dim).
   function Slice (V : Point; Dim : Dim_Count) return Point is
      R : Point (1 .. Dim);
   begin
      for I in 1 .. Dim loop
         R (I) := V (I);
      end loop;
      return R;
   end Slice;

   --  Embed a Dim-vector into a Max_Dim Point (trailing zeros).
   function Embed (X : Point) return Point is
      R : Point (1 .. Max_Dim) := [others => 0.0];
   begin
      for I in X'Range loop
         R (I - X'First + 1) := X (I);
      end loop;
      return R;
   end Embed;

   ---------------------------------------------------------------------------
   -- Geometry
   ---------------------------------------------------------------------------

   function Centroid_Excluding_Worst
     (S : Simplex; Dim : Dim_Count) return Point
   is
      C     : Point (1 .. Dim) := [others => 0.0];
      N     : constant Real := Real (Dim);
      First : constant Vertex_Index := S'First;
      Last  : constant Vertex_Index := S'Last;  -- worst
   begin
      for V in First .. Last - 1 loop
         for I in 1 .. Dim loop
            C (I) := C (I) + S (V).X (I);
         end loop;
      end loop;
      for I in 1 .. Dim loop
         C (I) := C (I) / N;
      end loop;
      return C;
   end Centroid_Excluding_Worst;

   function Reflect
     (Centroid, Worst : Point; Alpha : Positive_Real) return Point
   is
   begin
      --  x_r = x_o + α (x_o − x_w) = (1+α) x_o − α x_w
      return Add (Centroid, Scale (Real (Alpha), Sub (Centroid, Worst)));
   end Reflect;

   function Expand
     (Centroid, Reflected : Point; Gamma : Positive_Real) return Point
   is
   begin
      --  x_e = x_o + γ (x_r − x_o)
      return Add (Centroid, Scale (Real (Gamma), Sub (Reflected, Centroid)));
   end Expand;

   function Contract_Outside
     (Centroid, Reflected : Point; Rho : Positive_Real) return Point
   is
   begin
      --  x_c = x_o + ρ (x_r − x_o)
      return Add (Centroid, Scale (Real (Rho), Sub (Reflected, Centroid)));
   end Contract_Outside;

   function Contract_Inside
     (Centroid, Worst : Point; Rho : Positive_Real) return Point
   is
   begin
      --  x_c = x_o + ρ (x_w − x_o)
      return Add (Centroid, Scale (Real (Rho), Sub (Worst, Centroid)));
   end Contract_Inside;

   function Shrink_Toward_Best
     (Best, Other : Point; Sigma : Positive_Real) return Point
   is
   begin
      --  x' = x_1 + σ (x − x_1)
      return Add (Best, Scale (Real (Sigma), Sub (Other, Best)));
   end Shrink_Toward_Best;

   function Simplex_Size (S : Simplex; Dim : Dim_Count) return Non_Negative is
      Best  : constant Point := Slice (S (S'First).X, Dim);
      Max_D : Real := 0.0;
      D     : Real;
   begin
      for V in S'First + 1 .. S'Last loop
         D := Real (Norm2 (Sub (Slice (S (V).X, Dim), Best)));
         if D > Max_D then
            Max_D := D;
         end if;
      end loop;
      return Non_Negative (Max_D);
   end Simplex_Size;

   function F_Spread (S : Simplex) return Non_Negative is
      Diff : constant Real := S (S'Last).F - S (S'First).F;
   begin
      if Diff < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Diff);
   end F_Spread;

   procedure Order_Vertices (S : in out Simplex) is
      --  Insertion sort by ascending F (stable enough for n ≤ 9).
      Key : Vertex;
      J   : Integer;
   begin
      for I in S'First + 1 .. S'Last loop
         Key := S (I);
         J   := Integer (I) - 1;
         while J >= Integer (S'First) and then S (Vertex_Index (J)).F > Key.F
         loop
            S (Vertex_Index (J + 1)) := S (Vertex_Index (J));
            J := J - 1;
         end loop;
         S (Vertex_Index (J + 1)) := Key;
      end loop;
   end Order_Vertices;

   function Initial_Simplex
     (X0   : Point;
      Step : Positive_Real;
      Obj  : Objective_Fn) return Simplex
   is
      Dim : constant Dim_Count := X0'Length;
      S   : Simplex (1 .. Dim + 1);
      P   : Point (1 .. Dim);
   begin
      --  Vertex 1 = X0
      for I in 1 .. Dim loop
         S (1).X (I) := X0 (X0'First + I - 1);
         P (I) := S (1).X (I);
      end loop;
      for I in Dim + 1 .. Max_Dim loop
         S (1).X (I) := 0.0;
      end loop;
      S (1).F := Obj (P);

      --  Vertices 2 .. n+1 : offset by Step along each axis
      for K in 1 .. Dim loop
         for I in 1 .. Dim loop
            S (K + 1).X (I) := S (1).X (I);
            P (I) := S (1).X (I);
         end loop;
         S (K + 1).X (K) := S (K + 1).X (K) + Real (Step);
         P (K) := S (K + 1).X (K);
         for I in Dim + 1 .. Max_Dim loop
            S (K + 1).X (I) := 0.0;
         end loop;
         S (K + 1).F := Obj (P);
      end loop;

      Order_Vertices (S);
      return S;
   end Initial_Simplex;

   ---------------------------------------------------------------------------
   -- Objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere;

   function Rosenbrock (X : Point) return Real is
      A : constant Real := 1.0;
      B : constant Real := 100.0;
      Xx, Yy : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      Xx := X (X'First);
      Yy := X (X'First + 1);
      return (A - Xx) ** 2 + B * (Yy - Xx ** 2) ** 2;
   end Rosenbrock;

   function Himmelblau (X : Point) return Real is
      Xx, Yy : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      Xx := X (X'First);
      Yy := X (X'First + 1);
      return (Xx ** 2 + Yy - 11.0) ** 2 + (Xx + Yy ** 2 - 7.0) ** 2;
   end Himmelblau;

   function Quadratic_1D (X : Point) return Real is
   begin
      return (X (X'First) - 2.0) ** 2;
   end Quadratic_1D;

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

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      Cfg       : Config := (others => <>)) return Result
   is
      Dim : constant Dim_Count := X0'Length;
      S   : Simplex := Initial_Simplex (X0, Cfg.Step, Objective);
      R   : Result;
      Evals : Natural := Dim + 1;  -- initial simplex evaluations

      procedure Replace_Worst (X : Point; F : Real) is
      begin
         for I in 1 .. Dim loop
            S (S'Last).X (I) := X (I);
         end loop;
         for I in Dim + 1 .. Max_Dim loop
            S (S'Last).X (I) := 0.0;
         end loop;
         S (S'Last).F := F;
      end Replace_Worst;

      procedure Do_Shrink is
         Best_P : constant Point := Slice (S (S'First).X, Dim);
         New_P  : Point (1 .. Dim);
      begin
         for V in S'First + 1 .. S'Last loop
            New_P := Shrink_Toward_Best
              (Best_P, Slice (S (V).X, Dim), Cfg.Sigma);
            for I in 1 .. Dim loop
               S (V).X (I) := New_P (I);
            end loop;
            for I in Dim + 1 .. Max_Dim loop
               S (V).X (I) := 0.0;
            end loop;
            S (V).F := Objective (New_P);
            Evals := Evals + 1;
         end loop;
      end Do_Shrink;

      Centroid  : Point (1 .. Dim);
      Xr, Xe, Xc : Point (1 .. Dim);
      Fr, Fe, Fc : Real;
      Worst_P   : Point (1 .. Dim);
      Accepted  : Boolean;
   begin
      R.Dim := Dim;

      for Iter in 1 .. Cfg.Max_Iters loop
         Order_Vertices (S);

         R.Final_Size := Simplex_Size (S, Dim);
         --  Require BOTH size and f-spread (MATLAB fminsearch-style):
         --  equal f at symmetric wrong points must not stop early.
         if R.Final_Size <= Cfg.Size_Tol
           and then F_Spread (S) <= Cfg.F_Tol
         then
            R.Iters     := Iter - 1;
            R.Converged := True;
            exit;
         end if;

         Centroid := Centroid_Excluding_Worst (S, Dim);
         Worst_P  := Slice (S (S'Last).X, Dim);

         --  Reflection
         Xr := Reflect (Centroid, Worst_P, Cfg.Alpha);
         Fr := Objective (Xr);
         Evals := Evals + 1;
         Accepted := False;

         if Fr >= S (S'First).F and then Fr < S (S'Last - 1).F then
            --  Better than second-worst, not better than best → accept
            Replace_Worst (Xr, Fr);
            Accepted := True;

         elsif Fr < S (S'First).F then
            --  Best so far → try expansion
            Xe := Expand (Centroid, Xr, Cfg.Gamma);
            Fe := Objective (Xe);
            Evals := Evals + 1;
            if Fe < Fr then
               Replace_Worst (Xe, Fe);
            else
               Replace_Worst (Xr, Fr);
            end if;
            Accepted := True;

         else
            --  Fr >= f(x_n)  → contraction
            if Fr < S (S'Last).F then
               --  Outside contraction
               Xc := Contract_Outside (Centroid, Xr, Cfg.Rho);
               Fc := Objective (Xc);
               Evals := Evals + 1;
               if Fc < Fr then
                  Replace_Worst (Xc, Fc);
                  Accepted := True;
               end if;
            else
               --  Inside contraction
               Xc := Contract_Inside (Centroid, Worst_P, Cfg.Rho);
               Fc := Objective (Xc);
               Evals := Evals + 1;
               if Fc < S (S'Last).F then
                  Replace_Worst (Xc, Fc);
                  Accepted := True;
               end if;
            end if;

            if not Accepted then
               Do_Shrink;
            end if;
         end if;

         R.Iters := Iter;
      end loop;

      Order_Vertices (S);
      R.Best_X     := Embed (Slice (S (S'First).X, Dim));
      R.Best_F     := S (S'First).F;
      R.Evals      := Evals;
      R.Final_Size := Simplex_Size (S, Dim);
      if not R.Converged then
         --  Hit Max_Iters; still report best / mark converged if both tols met
         if R.Final_Size <= Cfg.Size_Tol
           and then F_Spread (S) <= Cfg.F_Tol
         then
            R.Converged := True;
         end if;
      end if;
      return R;
   end Minimize;

end Nelder_Mead;
