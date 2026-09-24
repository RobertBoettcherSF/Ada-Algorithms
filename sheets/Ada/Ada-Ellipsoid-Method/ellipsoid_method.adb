--  Ellipsoid_Method body — central / deep ellipsoid updates and
--  polytope feasibility loop (educational Float, n ≤ 8).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Ellipsoid_Method
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   function Active_Shape (E : Ellipsoid) return Matrix is
      M : Matrix (1 .. E.N, 1 .. E.N);
   begin
      for I in 1 .. E.N loop
         for J in 1 .. E.N loop
            M (I, J) := E.Shape (I, J);
         end loop;
      end loop;
      return M;
   end Active_Shape;

   function Active_Center (E : Ellipsoid) return Vector is
      C : Vector (1 .. E.N);
   begin
      for I in 1 .. E.N loop
         C (I) := E.Center (I);
      end loop;
      return C;
   end Active_Center;

   procedure Store_Shape (E : in out Ellipsoid; M : Matrix) is
   begin
      for I in 1 .. E.N loop
         for J in 1 .. E.N loop
            E.Shape (I, J) := M (I, J);
         end loop;
      end loop;
      --  Zero unused block for cleanliness
      for I in E.N + 1 .. Max_Dim loop
         for J in 1 .. Max_Dim loop
            E.Shape (I, J) := 0.0;
         end loop;
      end loop;
      for I in 1 .. E.N loop
         for J in E.N + 1 .. Max_Dim loop
            E.Shape (I, J) := 0.0;
         end loop;
      end loop;
   end Store_Shape;

   procedure Store_Center (E : in out Ellipsoid; C : Vector) is
   begin
      for I in 1 .. E.N loop
         E.Center (I) := C (I);
      end loop;
      for I in E.N + 1 .. Max_Dim loop
         E.Center (I) := 0.0;
      end loop;
   end Store_Center;

   --  Solve P y = rhs by Gaussian elimination with partial pivoting.
   --  Returns False if singular / ill-conditioned.
   function Solve_Linear
     (P   : Matrix;
      Rhs : Vector;
      Y   : out Vector) return Boolean
   is
      N : constant Positive := Rhs'Length;
      A : Matrix (1 .. N, 1 .. N);
      B : Vector (1 .. N);
      Pivot : Real;
      Best  : Positive;
      Tmp   : Real;
      Fac   : Real;
   begin
      Y := [for K in Rhs'Range => 0.0];
      if P'Length (1) /= N or else P'Length (2) /= N then
         return False;
      end if;
      for I in 1 .. N loop
         for J in 1 .. N loop
            A (I, J) := P (P'First (1) + I - 1, P'First (2) + J - 1);
         end loop;
         B (I) := Rhs (Rhs'First + I - 1);
      end loop;

      for K in 1 .. N loop
         Best := K;
         Pivot := abs (A (K, K));
         for I in K + 1 .. N loop
            if abs (A (I, K)) > Pivot then
               Pivot := abs (A (I, K));
               Best := I;
            end if;
         end loop;
         if Pivot < 1.0E-18 then
            return False;
         end if;
         if Best /= K then
            for J in K .. N loop
               Tmp := A (K, J);
               A (K, J) := A (Best, J);
               A (Best, J) := Tmp;
            end loop;
            Tmp := B (K);
            B (K) := B (Best);
            B (Best) := Tmp;
         end if;
         for I in K + 1 .. N loop
            Fac := A (I, K) / A (K, K);
            A (I, K) := 0.0;
            for J in K + 1 .. N loop
               A (I, J) := A (I, J) - Fac * A (K, J);
            end loop;
            B (I) := B (I) - Fac * B (K);
         end loop;
      end loop;

      for I in reverse 1 .. N loop
         Tmp := B (I);
         for J in I + 1 .. N loop
            Tmp := Tmp - A (I, J) * Y (Y'First + J - 1);
         end loop;
         if abs (A (I, I)) < 1.0E-18 then
            return False;
         end if;
         Y (Y'First + I - 1) := Tmp / A (I, I);
      end loop;
      return True;
   end Solve_Linear;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if abs (A (I) - B (B'First + (I - A'First))) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Dot (U, V : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in U'Range loop
         S := S + U (I) * V (V'First + (I - U'First));
      end loop;
      return S;
   end Dot;

   function Norm2 (V : Vector) return Real is
   begin
      return EF.Sqrt (Real'Max (0.0, Dot (V, V)));
   end Norm2;

   function Normalize (V : Vector) return Vector is
      Nrm : constant Real := Norm2 (V);
      R   : Vector (V'Range);
   begin
      if Nrm < 1.0E-18 then
         raise Invalid_Argument with "Normalize: zero vector";
      end if;
      for I in V'Range loop
         R (I) := V (I) / Nrm;
      end loop;
      return R;
   end Normalize;

   function Scale (V : Vector; S : Real) return Vector is
      R : Vector (V'Range);
   begin
      for I in V'Range loop
         R (I) := S * V (I);
      end loop;
      return R;
   end Scale;

   function Add (U, V : Vector) return Vector is
      R : Vector (U'Range);
   begin
      for I in U'Range loop
         R (I) := U (I) + V (V'First + (I - U'First));
      end loop;
      return R;
   end Add;

   function Sub (U, V : Vector) return Vector is
      R : Vector (U'Range);
   begin
      for I in U'Range loop
         R (I) := U (I) - V (V'First + (I - U'First));
      end loop;
      return R;
   end Sub;

   function Mat_Vec (M : Matrix; V : Vector) return Vector is
      N : constant Positive := V'Length;
      R : Vector (1 .. N);
      S : Real;
   begin
      for I in 1 .. N loop
         S := 0.0;
         for J in 1 .. N loop
            S := S + M (M'First (1) + I - 1, M'First (2) + J - 1)
              * V (V'First + J - 1);
         end loop;
         R (I) := S;
      end loop;
      return R;
   end Mat_Vec;

   function Mat_Mul (A, B : Matrix) return Matrix is
      N : constant Positive := A'Length (1);
      R : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      S : Real;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            S := 0.0;
            for K in 1 .. N loop
               S := S
                 + A (A'First (1) + I - 1, A'First (2) + K - 1)
                 * B (B'First (1) + K - 1, B'First (2) + J - 1);
            end loop;
            R (I, J) := S;
         end loop;
      end loop;
      return R;
   end Mat_Mul;

   function Transpose (M : Matrix) return Matrix is
      N : constant Positive := M'Length (1);
      R : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := M (M'First (1) + J - 1, M'First (2) + I - 1);
         end loop;
      end loop;
      return R;
   end Transpose;

   function Identity (N : Dimension) return Matrix is
      R : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         R (I, I) := 1.0;
      end loop;
      return R;
   end Identity;

   function Symmetric_Part (M : Matrix) return Matrix is
      N : constant Positive := M'Length (1);
      R : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := 0.5
              * (M (M'First (1) + I - 1, M'First (2) + J - 1)
                 + M (M'First (1) + J - 1, M'First (2) + I - 1));
         end loop;
      end loop;
      return R;
   end Symmetric_Part;

   function Determinant_2x2 (M : Matrix) return Real is
      A11 : constant Real := M (M'First (1), M'First (2));
      A12 : constant Real := M (M'First (1), M'First (2) + 1);
      A21 : constant Real := M (M'First (1) + 1, M'First (2));
      A22 : constant Real := M (M'First (1) + 1, M'First (2) + 1);
   begin
      return A11 * A22 - A12 * A21;
   end Determinant_2x2;

   function Determinant_3x3 (M : Matrix) return Real is
      A : constant Real := M (M'First (1), M'First (2));
      B : constant Real := M (M'First (1), M'First (2) + 1);
      C : constant Real := M (M'First (1), M'First (2) + 2);
      D : constant Real := M (M'First (1) + 1, M'First (2));
      E : constant Real := M (M'First (1) + 1, M'First (2) + 1);
      F : constant Real := M (M'First (1) + 1, M'First (2) + 2);
      G : constant Real := M (M'First (1) + 2, M'First (2));
      H : constant Real := M (M'First (1) + 2, M'First (2) + 1);
      I : constant Real := M (M'First (1) + 2, M'First (2) + 2);
   begin
      return A * (E * I - F * H)
        - B * (D * I - F * G)
        + C * (D * H - E * G);
   end Determinant_3x3;

   function Determinant (M : Matrix) return Real is
      N : constant Positive := M'Length (1);
      A : Matrix (1 .. N, 1 .. N);
      Det : Real := 1.0;
      Pivot : Real;
      Best  : Positive;
      Tmp   : Real;
      Fac   : Real;
      Sign  : Real := 1.0;
   begin
      if N = 1 then
         return M (M'First (1), M'First (2));
      elsif N = 2 then
         return Determinant_2x2 (M);
      elsif N = 3 then
         return Determinant_3x3 (M);
      end if;

      for I in 1 .. N loop
         for J in 1 .. N loop
            A (I, J) := M (M'First (1) + I - 1, M'First (2) + J - 1);
         end loop;
      end loop;

      for K in 1 .. N loop
         Best := K;
         Pivot := abs (A (K, K));
         for I in K + 1 .. N loop
            if abs (A (I, K)) > Pivot then
               Pivot := abs (A (I, K));
               Best := I;
            end if;
         end loop;
         if Pivot < 1.0E-30 then
            return 0.0;
         end if;
         if Best /= K then
            Sign := -Sign;
            for J in K .. N loop
               Tmp := A (K, J);
               A (K, J) := A (Best, J);
               A (Best, J) := Tmp;
            end loop;
         end if;
         Det := Det * A (K, K);
         for I in K + 1 .. N loop
            Fac := A (I, K) / A (K, K);
            for J in K + 1 .. N loop
               A (I, J) := A (I, J) - Fac * A (K, J);
            end loop;
         end loop;
      end loop;
      return Sign * Det;
   end Determinant;

   function Is_Symmetric
     (M : Matrix; Tol : Real := Epsilon_Tol) return Boolean
   is
      N : constant Positive := M'Length (1);
   begin
      for I in 1 .. N loop
         for J in I + 1 .. N loop
            if abs (M (M'First (1) + I - 1, M'First (2) + J - 1)
                    - M (M'First (1) + J - 1, M'First (2) + I - 1))
              > Tol
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

   ---------------------------------------------------------------------------
   -- Ellipsoid construction & volume
   ---------------------------------------------------------------------------

   function Init_Ball
     (Center : Vector;
      Radius : Positive_Real) return Ellipsoid
   is
      E : Ellipsoid;
      N : constant Dimension := Center'Length;
      R2 : constant Real := Radius * Radius;
   begin
      E.N := N;
      for I in 1 .. N loop
         E.Center (I) := Center (Center'First + I - 1);
         for J in 1 .. N loop
            if I = J then
               E.Shape (I, J) := R2;
            else
               E.Shape (I, J) := 0.0;
            end if;
         end loop;
      end loop;
      return E;
   end Init_Ball;

   function Volume_Proxy (E : Ellipsoid) return Real is
      P : constant Matrix := Active_Shape (E);
   begin
      return Determinant (P);
   end Volume_Proxy;

   function Log_Volume_Proxy (E : Ellipsoid) return Real is
      Det : constant Real := Volume_Proxy (E);
   begin
      if Det <= 0.0 then
         return Real'First / 4.0;
      end if;
      return 0.5 * EF.Log (Det);
   end Log_Volume_Proxy;

   function Quadratic_Form
     (E : Ellipsoid; X : Vector) return Real
   is
      N   : constant Positive := E.N;
      Diff : Vector (1 .. N);
      Y    : Vector (1 .. N);
      P    : constant Matrix := Active_Shape (E);
      Ok   : Boolean;
   begin
      for I in 1 .. N loop
         Diff (I) := X (X'First + I - 1) - E.Center (I);
      end loop;
      Ok := Solve_Linear (P, Diff, Y);
      if not Ok then
         raise Invalid_Argument with "Quadratic_Form: singular Shape";
      end if;
      return Dot (Diff, Y);
   end Quadratic_Form;

   function Contains_Point
     (E : Ellipsoid; X : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return Quadratic_Form (E, X) <= 1.0 + Tol;
   end Contains_Point;

   ---------------------------------------------------------------------------
   -- Cuts
   ---------------------------------------------------------------------------

   function Make_Cut
     (Grad : Vector; Depth : Real := 0.0) return Cut
   is
      C : Cut;
   begin
      C.N := Grad'Length;
      for I in 1 .. C.N loop
         C.Grad (I) := Grad (Grad'First + I - 1);
      end loop;
      C.Depth := Depth;
      C.Valid := Norm2 (Grad) > 1.0E-18;
      return C;
   end Make_Cut;

   function Halfspace_Violation
     (H : Halfspace; X : Vector) return Real
   is
      S : Real := 0.0;
   begin
      for I in 1 .. H.N loop
         S := S + H.Normal (I) * X (X'First + I - 1);
      end loop;
      return S - H.Offset;
   end Halfspace_Violation;

   function Cut_From_Halfspace
     (H      : Halfspace;
      E      : Ellipsoid;
      Deep   : Boolean := True;
      Tol    : Real := Epsilon_Tol) return Cut
   is
      N    : constant Positive := E.N;
      G    : Vector (1 .. N);
      C    : constant Vector := Active_Center (E);
      P    : constant Matrix := Active_Shape (E);
      Pg   : Vector (1 .. N);
      GPg  : Real;
      Alpha : Real := 0.0;
      Viol  : Real;
      Result_Cut : Cut;
   begin
      for I in 1 .. N loop
         G (I) := H.Normal (I);
      end loop;
      Viol := Halfspace_Violation (H, C);
      if Viol <= Tol then
         Result_Cut.Valid := False;
         Result_Cut.N := N;
         return Result_Cut;
      end if;

      Pg := Mat_Vec (P, G);
      GPg := Dot (G, Pg);
      if GPg <= 1.0E-30 then
         Result_Cut.Valid := False;
         Result_Cut.N := N;
         return Result_Cut;
      end if;

      if Deep then
         Alpha := Viol / EF.Sqrt (GPg);
         if Alpha < 0.0 then
            Alpha := 0.0;
         end if;
         --  Alpha >= 1: halfspace misses the ellipsoid entirely (empty).
         --  Encode as Valid cut with Depth >= 1 so the feasibility loop
         --  can return Infeasible without applying an invalid update.
         if Alpha >= 1.0 then
            Result_Cut.N := N;
            for I in 1 .. N loop
               Result_Cut.Grad (I) := G (I);
            end loop;
            Result_Cut.Depth := Alpha;
            Result_Cut.Valid := True;
            return Result_Cut;
         end if;
      else
         Alpha := 0.0;
      end if;

      Result_Cut := Make_Cut (G, Alpha);
      return Result_Cut;
   end Cut_From_Halfspace;

   procedure Apply_Deep_Cut
     (E     : in out Ellipsoid;
      G     : Vector;
      Alpha : Real)
   is
      N  : constant Positive := E.N;
      Rn : constant Real := Real (N);
      P  : constant Matrix (1 .. N, 1 .. N) := Active_Shape (E);
      C  : Vector (1 .. N) := Active_Center (E);
      Gv : Vector (1 .. N);
      Pg : Vector (1 .. N);
      GPg : Real;
      Gtilde : Vector (1 .. N);
      Tau, Sigma, Delta_F : Real;
      Outer : Matrix (1 .. N, 1 .. N);
      P_New : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         Gv (I) := G (G'First + I - 1);
      end loop;

      Pg := Mat_Vec (P, Gv);
      GPg := Dot (Gv, Pg);
      if GPg <= 1.0E-30 then
         raise Invalid_Argument with "Apply_Deep_Cut: g^T P g ≈ 0";
      end if;

      --  g̃ = g / sqrt(g^T P g)   (Wikipedia / GLS convention)
      declare
         Inv : constant Real := 1.0 / EF.Sqrt (GPg);
      begin
         for I in 1 .. N loop
            Gtilde (I) := Inv * Gv (I);
         end loop;
      end;

      --  τ = (1 + n α) / (n + 1)
      --  σ = 2 (1 + n α) / ((n + 1) (1 + α))
      --  δ = n² (1 − α²) / (n² − 1)
      declare
         Pg_Tilde : Vector (1 .. N);
      begin
         for I in 1 .. N loop
            Pg_Tilde (I) := 0.0;
            for J in 1 .. N loop
               Pg_Tilde (I) := Pg_Tilde (I) + P (I, J) * Gtilde (J);
            end loop;
         end loop;

         if N = 1 then
            --  1-D half-interval: τ=(1+α)/2, P ← ((1−α)/2)² P
            Tau := (1.0 + Alpha) / 2.0;
            C := Sub (C, Scale (Pg_Tilde, Tau));
            declare
               Factor : constant Real :=
                 ((1.0 - Alpha) / 2.0) * ((1.0 - Alpha) / 2.0);
            begin
               P_New (1, 1) := Factor * P (1, 1);
            end;
         else
            --  τ = (1 + n α)/(n+1)
            --  σ = 2(1 + n α)/((n+1)(1+α))
            --  δ = n²(1 − α²)/(n² − 1)
            Tau   := (1.0 + Rn * Alpha) / (Rn + 1.0);
            Sigma := (2.0 * (1.0 + Rn * Alpha))
              / ((Rn + 1.0) * (1.0 + Alpha));
            Delta_F := (Rn * Rn * (1.0 - Alpha * Alpha))
              / (Rn * Rn - 1.0);
            C := Sub (C, Scale (Pg_Tilde, Tau));
            for I in 1 .. N loop
               for J in 1 .. N loop
                  Outer (I, J) := Pg_Tilde (I) * Pg_Tilde (J);
               end loop;
            end loop;
            for I in 1 .. N loop
               for J in 1 .. N loop
                  P_New (I, J) :=
                    Delta_F * (P (I, J) - Sigma * Outer (I, J));
               end loop;
            end loop;
         end if;
      end;

      P_New := Symmetric_Part (P_New);
      Store_Center (E, C);
      Store_Shape (E, P_New);
   end Apply_Deep_Cut;

   procedure Apply_Central_Cut
     (E : in out Ellipsoid;
      G : Vector)
   is
   begin
      Apply_Deep_Cut (E, G, 0.0);
   end Apply_Central_Cut;

   procedure Apply_Cut
     (E : in out Ellipsoid;
      C : Cut)
   is
      G : Vector (1 .. C.N);
   begin
      for I in 1 .. C.N loop
         G (I) := C.Grad (I);
      end loop;
      Apply_Deep_Cut (E, G, C.Depth);
   end Apply_Cut;

   ---------------------------------------------------------------------------
   -- Feasibility
   ---------------------------------------------------------------------------

   function First_Violated
     (Hs  : Halfspace_List;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Natural
   is
   begin
      for I in Hs'Range loop
         if Hs (I).N /= X'Length then
            return 0;
         end if;
         if Halfspace_Violation (Hs (I), X) > Tol then
            return I;
         end if;
      end loop;
      return 0;
   end First_Violated;

   function Is_Feasible
     (Hs  : Halfspace_List;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return First_Violated (Hs, X, Tol) = 0;
   end Is_Feasible;

   function Feasibility_Ellipsoid
     (Hs      : Halfspace_List;
      Initial : Ellipsoid;
      Cfg     : Config := (others => <>)) return Result
   is
      E   : Ellipsoid := Initial;
      R   : Result;
      Idx : Natural;
      C   : Vector (1 .. Initial.N);
      Cut_V : Cut;
      Vol : Real;
   begin
      R.N := Initial.N;
      R.Final_Ell := Initial;

      if Initial.N < 1 then
         R.Stat := Ill_Started;
         return R;
      end if;

      Vol := Volume_Proxy (E);
      if Vol <= 0.0 then
         R.Stat := Ill_Started;
         return R;
      end if;

      for Iter in 1 .. Cfg.Max_Iters loop
         R.Iterations := Iter;
         for I in 1 .. E.N loop
            C (I) := E.Center (I);
         end loop;

         Idx := First_Violated (Hs, C, Cfg.Tol);
         if Idx = 0 then
            R.Stat := Feasible;
            R.Success := True;
            for I in 1 .. E.N loop
               R.Point (I) := C (I);
            end loop;
            R.Final_Ell := E;
            return R;
         end if;

         Cut_V := Cut_From_Halfspace
           (Hs (Idx), E, Deep => Cfg.Use_Deep_Cuts, Tol => Cfg.Tol);
         if not Cut_V.Valid then
            R.Stat := Ill_Started;
            R.Final_Ell := E;
            return R;
         end if;

         --  Deep cut with α ≥ 1 ⇒ ellipsoid ∩ halfspace = ∅
         if Cut_V.Depth >= 1.0 then
            R.Stat := Infeasible;
            R.Final_Ell := E;
            return R;
         end if;

         begin
            Apply_Cut (E, Cut_V);
         exception
            when Invalid_Argument =>
               R.Stat := Ill_Started;
               R.Final_Ell := E;
               return R;
         end;

         if Log_Volume_Proxy (E) <= Cfg.Min_Log_Vol
           or else Volume_Proxy (E) <= 0.0
         then
            R.Stat := Volume_Too_Small;
            --  Educational empty-set proxy when volume collapses
            R.Final_Ell := E;
            return R;
         end if;
      end loop;

      R.Stat := Iteration_Limit;
      R.Final_Ell := E;
      for I in 1 .. E.N loop
         R.Point (I) := E.Center (I);
      end loop;
      return R;
   end Feasibility_Ellipsoid;

   function Feasibility_Box
     (Lo, Hi  : Vector;
      Radius  : Positive_Real := 10.0;
      Cfg     : Config := (others => <>)) return Result
   is
      N : constant Dimension := Lo'Length;
      Mid : Vector (1 .. N);
      Hs  : Halfspace_List (1 .. 2 * N);
      E0  : Ellipsoid;
      K   : Positive := 1;
   begin
      for I in 1 .. N loop
         Mid (I) := 0.5
           * (Lo (Lo'First + I - 1) + Hi (Hi'First + I - 1));
      end loop;
      E0 := Init_Ball (Mid, Radius);

      --  Box:  x_i ≤ Hi_i  and  −x_i ≤ −Lo_i
      for I in 1 .. N loop
         Hs (K).N := N;
         Hs (K).Normal := [others => 0.0];
         Hs (K).Normal (I) := 1.0;
         Hs (K).Offset := Hi (Hi'First + I - 1);
         K := K + 1;
         Hs (K).N := N;
         Hs (K).Normal := [others => 0.0];
         Hs (K).Normal (I) := -1.0;
         Hs (K).Offset := -Lo (Lo'First + I - 1);
         K := K + 1;
      end loop;

      return Feasibility_Ellipsoid (Hs, E0, Cfg);
   end Feasibility_Box;

   function Maximize_Linear_Feasibility
     (Hs      : Halfspace_List;
      Obj     : Vector;
      Lo, Hi  : Real;
      Initial : Ellipsoid;
      Cfg     : Config := (others => <>);
      Binary_Steps : Positive := 20) return Result
   is
      N : constant Dimension := Initial.N;
      Low  : Real := Lo;
      High : Real := Hi;
      Mid  : Real;
      Best : Result;
      Trial : Result;
      Aug  : Halfspace_List (1 .. Hs'Length + 1);
      Obj_Hs : Halfspace;
      Have_Best : Boolean := False;
   begin
      Best.N := N;
      Best.Stat := Infeasible;

      for I in Hs'Range loop
         Aug (1 + (I - Hs'First)) := Hs (I);
      end loop;

      Obj_Hs.N := N;
      Obj_Hs.Normal := [others => 0.0];
      for I in 1 .. N loop
         --  c · x ≥ γ  ⇔  −c · x ≤ −γ
         Obj_Hs.Normal (I) := -Obj (Obj'First + I - 1);
      end loop;

      for Step in 1 .. Binary_Steps loop
         Mid := 0.5 * (Low + High);
         Obj_Hs.Offset := -Mid;
         Aug (Aug'Last) := Obj_Hs;
         Trial := Feasibility_Ellipsoid (Aug, Initial, Cfg);
         if Trial.Success then
            Have_Best := True;
            Best := Trial;
            Low := Mid;
         else
            High := Mid;
         end if;
      end loop;

      if Have_Best then
         Best.Stat := Feasible;
         Best.Success := True;
      else
         --  Fall back to plain feasibility without objective cut
         Best := Feasibility_Ellipsoid (Hs, Initial, Cfg);
      end if;
      return Best;
   end Maximize_Linear_Feasibility;

end Ellipsoid_Method;
