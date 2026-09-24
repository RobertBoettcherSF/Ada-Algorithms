--  Eigenvalue_Algorithms body — educational sketches (self-contained).

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Eigenvalue_Algorithms
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   function Abs_F (X : Float) return Float is
   begin
      if X < 0.0 then
         return -X;
      else
         return X;
      end if;
   end Abs_F;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean is
   begin
      return Abs_F (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if Abs_F (A (I) - B (B'First + (I - A'First))) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Dot (U, V : Vector) return Float is
      S : Float := 0.0;
   begin
      for I in U'Range loop
         S := S + U (I) * V (V'First + (I - U'First));
      end loop;
      return S;
   end Dot;

   function Norm2 (V : Vector) return Float is
   begin
      return Math.Sqrt (Dot (V, V));
   end Norm2;

   function Scale (V : Vector; S : Float) return Vector is
      R : Vector (V'Range);
   begin
      for I in V'Range loop
         R (I) := V (I) * S;
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

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      N : constant Dimension := X'Length;
      Y : Vector (1 .. N) := [others => 0.0];
      S : Float;
   begin
      for I in 1 .. N loop
         S := 0.0;
         for J in 1 .. N loop
            S := S
              + A (A'First (1) + (I - 1), A'First (2) + (J - 1))
              * X (X'First + (J - 1));
         end loop;
         Y (I) := S;
      end loop;
      return Y;
   end Mat_Vec;

   function Is_Square (A : Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square;

   function Is_Symmetric
     (A : Matrix; Tol : Float := Sym_Tol) return Boolean
   is
      N : constant Dimension := A'Length (1);
   begin
      for I in 0 .. N - 1 loop
         for J in I + 1 .. N - 1 loop
            if Abs_F
                 (A (A'First (1) + I, A'First (2) + J)
                  - A (A'First (1) + J, A'First (2) + I))
              > Tol
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

   function Is_Tridiagonal
     (A : Matrix; Tol : Float := Epsilon_Tol) return Boolean
   is
      N : constant Dimension := A'Length (1);
      Diff : Integer;
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            Diff := I - J;
            if Diff < 0 then
               Diff := -Diff;
            end if;
            if Diff > 1
              and then Abs_F
                         (A (A'First (1) + I, A'First (2) + J))
                       > Tol
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Tridiagonal;

   function Is_Diagonal
     (A : Matrix; Tol : Float := Epsilon_Tol) return Boolean
   is
      N : constant Dimension := A'Length (1);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            if I /= J
              and then Abs_F
                         (A (A'First (1) + I, A'First (2) + J))
                       > Tol
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Diagonal;

   function Normalize (V : Vector) return Vector is
      Nrm : constant Float := Norm2 (V);
      R   : Vector (V'Range);
   begin
      if Nrm <= Norm_Tol then
         raise Invalid_Argument;
      end if;
      for I in V'Range loop
         R (I) := V (I) / Nrm;
      end loop;
      return R;
   end Normalize;

   function Identity (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := 1.0;
      end loop;
      return A;
   end Identity;

   function Off_Diag_Norm (A : Matrix) return Float is
      N : constant Dimension := A'Length (1);
      S : Float := 0.0;
      V : Float;
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            if I /= J then
               V := A (A'First (1) + I, A'First (2) + J);
               S := S + V * V;
            end if;
         end loop;
      end loop;
      return Math.Sqrt (S);
   end Off_Diag_Norm;

   function Column (A : Matrix; J : Positive) return Vector is
      R : Vector (A'Range (1));
   begin
      for I in A'Range (1) loop
         R (I) := A (I, J);
      end loop;
      return R;
   end Column;

   procedure Set_Column
     (A : in out Matrix; J : Positive; V : Vector)
   is
   begin
      for I in V'Range loop
         A (A'First (1) + (I - V'First), J) := V (I);
      end loop;
   end Set_Column;

   -------------------------------------------------------------------------
   -- Rayleigh / residual
   -------------------------------------------------------------------------

   function Rayleigh_Quotient (A : Matrix; X : Vector) return Float is
      Den : constant Float := Dot (X, X);
   begin
      if Den <= Norm_Tol then
         raise Invalid_Argument;
      end if;
      return Dot (X, Mat_Vec (A, X)) / Den;
   end Rayleigh_Quotient;

   function Eigen_Residual
     (A : Matrix; X : Vector; Lambda : Float) return Vector
   is
   begin
      return Sub (Mat_Vec (A, X), Scale (X, Lambda));
   end Eigen_Residual;

   function Eigen_Residual_Norm
     (A : Matrix; X : Vector; Lambda : Float) return Float
   is
   begin
      return Norm2 (Eigen_Residual (A, X, Lambda));
   end Eigen_Residual_Norm;

   -------------------------------------------------------------------------
   -- Builders
   -------------------------------------------------------------------------

   function Make_Diagonal (Eigs : Vector) return Matrix is
      N : constant Dimension := Eigs'Length;
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := Eigs (Eigs'First + (I - 1));
      end loop;
      return A;
   end Make_Diagonal;

   function Make_Poisson_1D (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := 2.0;
         if I > 1 then
            A (I, I - 1) := -1.0;
         end if;
         if I < N then
            A (I, I + 1) := -1.0;
         end if;
      end loop;
      return A;
   end Make_Poisson_1D;

   function Make_Known_Spectrum_Symmetric
     (Eigs : Vector) return Matrix
   is
      N   : constant Dimension := Eigs'Length;
      Q   : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      A   : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Col : Vector (1 .. N);
      Proj, Nrm, S : Float;
   begin
      for J in 1 .. N loop
         for I in 1 .. N loop
            Q (I, J) :=
              Float ((I * 11 + J * 19 + I * J) mod 89) / 89.0
              + Float (I + J) * 0.01;
         end loop;
         Q (J, J) := Q (J, J) + Float (N);
      end loop;

      for J in 1 .. N loop
         for I in 1 .. N loop
            Col (I) := Q (I, J);
         end loop;
         for K in 1 .. J - 1 loop
            Proj := 0.0;
            for I in 1 .. N loop
               Proj := Proj + Q (I, K) * Col (I);
            end loop;
            for I in 1 .. N loop
               Col (I) := Col (I) - Proj * Q (I, K);
            end loop;
         end loop;
         Nrm := Norm2 (Col);
         if Nrm <= Norm_Tol then
            Col := [others => 0.0];
            Col (J) := 1.0;
            Nrm := 1.0;
         end if;
         for I in 1 .. N loop
            Q (I, J) := Col (I) / Nrm;
         end loop;
      end loop;

      for I in 1 .. N loop
         for J in 1 .. N loop
            S := 0.0;
            for K in 1 .. N loop
               S := S
                 + Q (I, K) * Eigs (Eigs'First + (K - 1)) * Q (J, K);
            end loop;
            A (I, J) := S;
         end loop;
      end loop;
      return A;
   end Make_Known_Spectrum_Symmetric;

   function Make_Nonsymmetric (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         A (I, I) := Float (N);
         for J in I + 1 .. N loop
            A (I, J) := 1.0;
         end loop;
         for J in 1 .. I - 1 loop
            A (I, J) := 0.25;
         end loop;
      end loop;
      return A;
   end Make_Nonsymmetric;

   function Make_Ones_Vector (N : Dimension) return Vector is
   begin
      return [1 .. N => 1.0];
   end Make_Ones_Vector;

   function Make_Unit_Vector
     (N : Dimension; K : Dim_Index) return Vector
   is
      V : Vector (1 .. N) := [others => 0.0];
   begin
      V (K) := 1.0;
      return V;
   end Make_Unit_Vector;

   function Make_Perturbed_Basis
     (N : Dimension; K : Dim_Index; Eps : Float := 0.1) return Vector
   is
      V : Vector (1 .. N) := [others => Eps];
   begin
      V (K) := V (K) + 1.0;
      return Normalize (V);
   end Make_Perturbed_Basis;

   function Poisson_Eigenvalue
     (N : Dimension; K : Dim_Index) return Float
   is
      Pi : constant Float := 3.14159_26535_89793;
      Ang : constant Float := Float (K) * Pi / Float (N + 1);
   begin
      return 2.0 - 2.0 * Math.Cos (Ang);
   end Poisson_Eigenvalue;

   -------------------------------------------------------------------------
   -- Taxonomy
   -------------------------------------------------------------------------

   function Classify_Matrix
     (A : Matrix; Tol : Float := Sym_Tol) return Matrix_Properties
   is
      P : Matrix_Properties;
   begin
      P.N := A'Length (1);
      P.Symmetric := Is_Symmetric (A, Tol);
      P.Tridiagonal := Is_Tridiagonal (A, Epsilon_Tol);
      P.Diagonal := Is_Diagonal (A, Epsilon_Tol);
      return P;
   end Classify_Matrix;

   function Recommend_Method
     (P         : Matrix_Properties;
      Goal      : Goal_Kind := Want_Dominant;
      Has_Shift : Boolean := False) return Method_Kind
   is
   begin
      case Goal is
         when Want_Near_Shift =>
            if Has_Shift then
               return Inverse;
            else
               return Rayleigh_Quotient;
            end if;

         when Want_Full_Spectrum =>
            if P.Symmetric then
               if P.N <= 8 then
                  return Jacobi_Symmetric;
               else
                  return QR_Iteration;
               end if;
            else
               return QR_Iteration;
            end if;

         when Want_Extremal_Few =>
            if P.Symmetric then
               return Lanczos;
            else
               return Arnoldi;
            end if;

         when Want_Dominant =>
            if Has_Shift then
               return Inverse;
            else
               return Power;
            end if;
      end case;
   end Recommend_Method;

   function Classify_Method (K : Method_Kind) return Method_Info is
      Info : Method_Info;
   begin
      Info.Kind := K;
      case K is
         when Power =>
            Info :=
              (Kind => Power, Needs_Symmetric => False,
               Uses_Shift => False, Full_Spectrum => False,
               Krylov => False, Runnable_Sketch => True);
         when Inverse =>
            Info :=
              (Kind => Inverse, Needs_Symmetric => False,
               Uses_Shift => True, Full_Spectrum => False,
               Krylov => False, Runnable_Sketch => True);
         when Rayleigh_Quotient =>
            Info :=
              (Kind => Rayleigh_Quotient, Needs_Symmetric => False,
               Uses_Shift => True, Full_Spectrum => False,
               Krylov => False, Runnable_Sketch => True);
         when QR_Iteration =>
            Info :=
              (Kind => QR_Iteration, Needs_Symmetric => False,
               Uses_Shift => False, Full_Spectrum => True,
               Krylov => False, Runnable_Sketch => True);
         when Jacobi_Symmetric =>
            Info :=
              (Kind => Jacobi_Symmetric, Needs_Symmetric => True,
               Uses_Shift => False, Full_Spectrum => True,
               Krylov => False, Runnable_Sketch => True);
         when Lanczos =>
            Info :=
              (Kind => Lanczos, Needs_Symmetric => True,
               Uses_Shift => False, Full_Spectrum => False,
               Krylov => True, Runnable_Sketch => True);
         when Arnoldi =>
            Info :=
              (Kind => Arnoldi, Needs_Symmetric => False,
               Uses_Shift => False, Full_Spectrum => False,
               Krylov => True, Runnable_Sketch => True);
         when Divide_And_Conquer =>
            Info :=
              (Kind => Divide_And_Conquer, Needs_Symmetric => True,
               Uses_Shift => False, Full_Spectrum => True,
               Krylov => False, Runnable_Sketch => False);
      end case;
      return Info;
   end Classify_Method;

   function Method_Name (K : Method_Kind) return String is
   begin
      case K is
         when Power              => return "Power";
         when Inverse            => return "Inverse";
         when Rayleigh_Quotient  => return "Rayleigh_Quotient";
         when QR_Iteration       => return "QR_Iteration";
         when Jacobi_Symmetric   => return "Jacobi_Symmetric";
         when Lanczos            => return "Lanczos";
         when Arnoldi            => return "Arnoldi";
         when Divide_And_Conquer => return "Divide_And_Conquer";
      end case;
   end Method_Name;

   function Method_Count return Positive is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
        - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

   -------------------------------------------------------------------------
   -- Dense GEPP for (A − μ I) y = x  (Inverse / RQI)
   -------------------------------------------------------------------------

   type Solve_Status is (Ok_Sol, Singular, Zero_Pivot);

   type Linear_Result is record
      Y       : Vector (1 .. Max_N) := [others => 0.0];
      N       : Dimension := 0;
      Stat    : Solve_Status := Singular;
      Success : Boolean := False;
   end record;

   function Solve_Shifted
     (A : Matrix; Mu : Float; X : Vector) return Linear_Result
   is
      N   : constant Dimension := X'Length;
      Aug : Matrix (1 .. N, 1 .. N + 1);
      Res : Linear_Result;
      Pivot, Factor, Max_Abs : Float;
      Pivot_Row : Dim_Index;
      Tmp : Float;
   begin
      Res.N := N;
      for I in 1 .. N loop
         for J in 1 .. N loop
            Aug (I, J) :=
              A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
         Aug (I, I) := Aug (I, I) - Mu;
         Aug (I, N + 1) := X (X'First + (I - 1));
      end loop;

      for K in 1 .. N loop
         Pivot_Row := K;
         Max_Abs := Abs_F (Aug (K, K));
         for I in K + 1 .. N loop
            if Abs_F (Aug (I, K)) > Max_Abs then
               Max_Abs := Abs_F (Aug (I, K));
               Pivot_Row := I;
            end if;
         end loop;

         if Max_Abs <= Pivot_Tol then
            Res.Stat := Zero_Pivot;
            return Res;
         end if;

         if Pivot_Row /= K then
            for J in K .. N + 1 loop
               Tmp := Aug (K, J);
               Aug (K, J) := Aug (Pivot_Row, J);
               Aug (Pivot_Row, J) := Tmp;
            end loop;
         end if;

         Pivot := Aug (K, K);
         for I in K + 1 .. N loop
            Factor := Aug (I, K) / Pivot;
            for J in K .. N + 1 loop
               Aug (I, J) := Aug (I, J) - Factor * Aug (K, J);
            end loop;
         end loop;
      end loop;

      for I in reverse 1 .. N loop
         Tmp := Aug (I, N + 1);
         for J in I + 1 .. N loop
            Tmp := Tmp - Aug (I, J) * Res.Y (J);
         end loop;
         if Abs_F (Aug (I, I)) <= Pivot_Tol then
            Res.Stat := Singular;
            return Res;
         end if;
         Res.Y (I) := Tmp / Aug (I, I);
      end loop;

      Res.Stat := Ok_Sol;
      Res.Success := True;
      return Res;
   end Solve_Shifted;

   function Acceptable_Res
     (R, Lam, Tol : Float) return Boolean
   is
   begin
      return R <= Tol or else R <= 1.0E-6 * (1.0 + Abs_F (Lam));
   end Acceptable_Res;

   -------------------------------------------------------------------------
   -- Power
   -------------------------------------------------------------------------

   function Power_Dominant
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
   is
      N      : constant Dimension := X0'Length;
      Res    : Eigenpair_Result;
      X, Y   : Vector (1 .. N);
      Lam, Nrm : Float;
      Max_It : Natural;
   begin
      Res.N := N;
      Res.Success := False;

      if N = 0
        or else A'Length (1) /= N
        or else A'Length (2) /= N
      then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      if Params.Tol < 0.0 then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      Nrm := Norm2 (X0);
      if Nrm <= Norm_Tol then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      for I in 1 .. N loop
         X (I) := X0 (X0'First + (I - 1)) / Nrm;
      end loop;

      Lam := Rayleigh_Quotient (A, X);
      Res.Residual := Eigen_Residual_Norm (A, X, Lam);
      if Acceptable_Res (Res.Residual, Lam, Params.Tol) then
         Res.Eigenvalue := Lam;
         for I in 1 .. N loop
            Res.Eigenvector (I) := X (I);
         end loop;
         Res.Stat := Converged;
         Res.Success := True;
         return Res;
      end if;

      if Params.Max_Iter = 0 then
         Max_It := 200;
      else
         Max_It := Params.Max_Iter;
      end if;

      for K in 1 .. Max_It loop
         Y := Mat_Vec (A, X);
         Nrm := Norm2 (Y);
         if Nrm <= Norm_Tol then
            Res.Eigenvalue := Lam;
            for I in 1 .. N loop
               Res.Eigenvector (I) := X (I);
            end loop;
            Res.Iterations := K;
            Res.Residual := Eigen_Residual_Norm (A, X, Lam);
            Res.Stat := Breakdown;
            return Res;
         end if;

         for I in 1 .. N loop
            X (I) := Y (I) / Nrm;
         end loop;

         Lam := Rayleigh_Quotient (A, X);
         Res.Residual := Eigen_Residual_Norm (A, X, Lam);
         Res.Iterations := K;
         Res.Eigenvalue := Lam;
         for I in 1 .. N loop
            Res.Eigenvector (I) := X (I);
         end loop;

         if Acceptable_Res (Res.Residual, Lam, Params.Tol) then
            Res.Stat := Converged;
            Res.Success := True;
            return Res;
         end if;
      end loop;

      Res.Stat := Iteration_Limit;
      return Res;
   end Power_Dominant;

   -------------------------------------------------------------------------
   -- Inverse (fixed shift)
   -------------------------------------------------------------------------

   function Inverse_Near
     (A      : Matrix;
      Mu     : Float;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
   is
      N      : constant Dimension := X0'Length;
      Res    : Eigenpair_Result;
      X, Y   : Vector (1 .. N);
      Lam, Nrm, Den : Float;
      Lin    : Linear_Result;
      Max_It : Natural;
   begin
      Res.N := N;
      Res.Mu := Mu;
      Res.Success := False;

      if N = 0
        or else A'Length (1) /= N
        or else A'Length (2) /= N
      then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      if Params.Tol < 0.0 then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      Nrm := Norm2 (X0);
      if Nrm <= Norm_Tol then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      for I in 1 .. N loop
         X (I) := X0 (X0'First + (I - 1)) / Nrm;
      end loop;

      if Params.Max_Iter = 0 then
         Max_It := 100;
      else
         Max_It := Params.Max_Iter;
      end if;

      for K in 1 .. Max_It loop
         Lin := Solve_Shifted (A, Mu, X);
         if not Lin.Success then
            Res.Eigenvalue := Rayleigh_Quotient (A, X);
            for I in 1 .. N loop
               Res.Eigenvector (I) := X (I);
            end loop;
            Res.Iterations := K;
            Res.Residual := Eigen_Residual_Norm (A, X, Res.Eigenvalue);
            Res.Stat := Singular_Shift;
            return Res;
         end if;

         for I in 1 .. N loop
            Y (I) := Lin.Y (I);
         end loop;

         Nrm := Norm2 (Y);
         if Nrm <= Norm_Tol then
            Res.Eigenvalue := Rayleigh_Quotient (A, X);
            for I in 1 .. N loop
               Res.Eigenvector (I) := X (I);
            end loop;
            Res.Iterations := K;
            Res.Residual := Eigen_Residual_Norm (A, X, Res.Eigenvalue);
            Res.Stat := Breakdown;
            return Res;
         end if;

         Den := Dot (X, Y);
         for I in 1 .. N loop
            X (I) := Y (I) / Nrm;
         end loop;

         if Abs_F (Den) > Norm_Tol then
            Lam := Mu + 1.0 / Den;
         else
            Lam := Rayleigh_Quotient (A, X);
         end if;

         Res.Residual := Eigen_Residual_Norm (A, X, Lam);
         Res.Iterations := K;
         Res.Eigenvalue := Lam;
         for I in 1 .. N loop
            Res.Eigenvector (I) := X (I);
         end loop;

         if Acceptable_Res (Res.Residual, Lam, Params.Tol) then
            Res.Stat := Converged;
            Res.Success := True;
            return Res;
         end if;
      end loop;

      Res.Stat := Iteration_Limit;
      return Res;
   end Inverse_Near;

   -------------------------------------------------------------------------
   -- Rayleigh quotient iteration
   -------------------------------------------------------------------------

   function Rayleigh_Quotient_Iterate
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
   is
      N      : constant Dimension := X0'Length;
      Res    : Eigenpair_Result;
      X, Y   : Vector (1 .. N);
      Mu, Lam, Nrm : Float;
      Lin    : Linear_Result;
      Max_It : Natural;
   begin
      Res.N := N;
      Res.Success := False;

      if N = 0
        or else A'Length (1) /= N
        or else A'Length (2) /= N
      then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      if Params.Tol < 0.0 then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      Nrm := Norm2 (X0);
      if Nrm <= Norm_Tol then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      for I in 1 .. N loop
         X (I) := X0 (X0'First + (I - 1)) / Nrm;
      end loop;

      if Params.Has_Shift then
         Mu := Params.Mu;
      else
         Mu := Rayleigh_Quotient (A, X);
      end if;
      Res.Mu := Mu;

      if Params.Max_Iter = 0 then
         Max_It := 50;
      else
         Max_It := Params.Max_Iter;
      end if;

      for K in 1 .. Max_It loop
         Lin := Solve_Shifted (A, Mu, X);
         if not Lin.Success then
            --  μ may already be an exact (or near-exact) eigenvalue.
            Lam := Rayleigh_Quotient (A, X);
            Res.Residual := Eigen_Residual_Norm (A, X, Lam);
            Res.Eigenvalue := Lam;
            for I in 1 .. N loop
               Res.Eigenvector (I) := X (I);
            end loop;
            Res.Iterations := K;
            Res.Mu := Mu;
            if Acceptable_Res (Res.Residual, Lam, Params.Tol)
              or else Res.Residual <= 1.0E-4 * (1.0 + Abs_F (Lam))
            then
               Res.Stat := Converged;
               Res.Success := True;
            else
               Res.Stat := Singular_Shift;
            end if;
            return Res;
         end if;

         for I in 1 .. N loop
            Y (I) := Lin.Y (I);
         end loop;
         Nrm := Norm2 (Y);
         if Nrm <= Norm_Tol then
            Res.Eigenvalue := Mu;
            for I in 1 .. N loop
               Res.Eigenvector (I) := X (I);
            end loop;
            Res.Iterations := K;
            Res.Residual := Eigen_Residual_Norm (A, X, Mu);
            Res.Mu := Mu;
            Res.Stat := Breakdown;
            return Res;
         end if;

         for I in 1 .. N loop
            X (I) := Y (I) / Nrm;
         end loop;

         Mu := Rayleigh_Quotient (A, X);
         Lam := Mu;
         Res.Residual := Eigen_Residual_Norm (A, X, Lam);
         Res.Iterations := K;
         Res.Eigenvalue := Lam;
         Res.Mu := Mu;
         for I in 1 .. N loop
            Res.Eigenvector (I) := X (I);
         end loop;

         if Acceptable_Res (Res.Residual, Lam, Params.Tol) then
            Res.Stat := Converged;
            Res.Success := True;
            return Res;
         end if;
      end loop;

      Res.Stat := Iteration_Limit;
      return Res;
   end Rayleigh_Quotient_Iterate;

   -------------------------------------------------------------------------
   -- Jacobi (cyclic)
   -------------------------------------------------------------------------

   function Apply_Jacobi_Rotation
     (S      : in out Matrix;
      V      : in out Matrix;
      P, Q   : Dim_Index;
      N      : Dimension) return Boolean
   is
      App : constant Float := S (P, P);
      Aqq : constant Float := S (Q, Q);
      Apq : constant Float := S (P, Q);
      Tau, T_Rot, C, Ss : Float;
   begin
      if Abs_F (Apq) <= Norm_Tol then
         return False;
      end if;

      Tau := (Aqq - App) / (2.0 * Apq);
      if Tau >= 0.0 then
         T_Rot := 1.0 / (Tau + Math.Sqrt (1.0 + Tau * Tau));
      else
         T_Rot := -1.0 / (-Tau + Math.Sqrt (1.0 + Tau * Tau));
      end if;
      C  := 1.0 / Math.Sqrt (1.0 + T_Rot * T_Rot);
      Ss := T_Rot * C;

      S (P, P) := App - T_Rot * Apq;
      S (Q, Q) := Aqq + T_Rot * Apq;
      S (P, Q) := 0.0;
      S (Q, P) := 0.0;

      for R in 1 .. N loop
         if R /= P and then R /= Q then
            declare
               Trp : constant Float := S (R, P);
               Trq : constant Float := S (R, Q);
            begin
               S (R, P) := C * Trp - Ss * Trq;
               S (P, R) := S (R, P);
               S (R, Q) := Ss * Trp + C * Trq;
               S (Q, R) := S (R, Q);
            end;
         end if;
      end loop;

      for R in 1 .. N loop
         declare
            Vrp : constant Float := V (R, P);
            Vrq : constant Float := V (R, Q);
         begin
            V (R, P) := C * Vrp - Ss * Vrq;
            V (R, Q) := Ss * Vrp + C * Vrq;
         end;
      end loop;

      return True;
   end Apply_Jacobi_Rotation;

   procedure Sort_Eigs_Asc
     (Eigs : in out Vector;
      V    : in out Matrix;
      N    : Dimension)
   is
   begin
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            if Eigs (J) < Eigs (I) then
               declare
                  Tmp : constant Float := Eigs (I);
               begin
                  Eigs (I) := Eigs (J);
                  Eigs (J) := Tmp;
               end;
               for R in 1 .. N loop
                  declare
                     U : constant Float := V (R, I);
                  begin
                     V (R, I) := V (R, J);
                     V (R, J) := U;
                  end;
               end loop;
            end if;
         end loop;
      end loop;
   end Sort_Eigs_Asc;

   function Jacobi_Diagonalize
     (S      : Matrix;
      Params : Parameters := Default_Parameters) return Spectrum_Result
   is
      N    : constant Dimension := S'Length (1);
      Res  : Spectrum_Result;
      Work : Matrix (1 .. N, 1 .. N);
      Vmat : Matrix (1 .. N, 1 .. N);
      Off  : Float;
      Max_Sw : Natural;
      E    : Vector (1 .. N);
   begin
      Res.N := N;
      Res.Success := False;

      for I in 1 .. N loop
         for J in 1 .. N loop
            Work (I, J) :=
              S (S'First (1) + (I - 1), S'First (2) + (J - 1));
         end loop;
      end loop;

      if not Is_Symmetric (Work, Sym_Tol) then
         Res.Stat := Not_Symmetric;
         Res.Off_Diag := Off_Diag_Norm (Work);
         return Res;
      end if;

      Vmat := Identity (N);

      if N = 1 then
         Res.Eigenvalues (1) := Work (1, 1);
         Res.Eigenvectors (1, 1) := 1.0;
         Res.Final_A (1, 1) := Work (1, 1);
         Res.Off_Diag := 0.0;
         Res.Has_Vectors := True;
         Res.Stat := Converged;
         Res.Success := True;
         return Res;
      end if;

      if Params.Max_Sweeps = 0 then
         Max_Sw := 50;
      else
         Max_Sw := Params.Max_Sweeps;
      end if;

      for Sweep in 1 .. Max_Sw loop
         Off := Off_Diag_Norm (Work);
         Res.Off_Diag := Off;
         Res.Iterations := Sweep;
         if Off <= Params.Tol then
            exit;
         end if;

         for P in 1 .. N - 1 loop
            for Q in P + 1 .. N loop
               if Apply_Jacobi_Rotation (Work, Vmat, P, Q, N) then
                  null;
               end if;
            end loop;
         end loop;
      end loop;

      Off := Off_Diag_Norm (Work);
      Res.Off_Diag := Off;
      for I in 1 .. N loop
         E (I) := Work (I, I);
      end loop;
      Sort_Eigs_Asc (E, Vmat, N);

      for I in 1 .. N loop
         Res.Eigenvalues (I) := E (I);
         for J in 1 .. N loop
            Res.Eigenvectors (I, J) := Vmat (I, J);
            Res.Final_A (I, J) := Work (I, J);
         end loop;
      end loop;
      Res.Has_Vectors := True;

      if Off <= Params.Tol * 10.0 or else Off <= 1.0E-4 then
         Res.Stat := Converged;
         Res.Success := True;
      else
         Res.Stat := Iteration_Limit;
      end if;
      return Res;
   end Jacobi_Diagonalize;

   -------------------------------------------------------------------------
   -- Unshifted QR (MGS)
   -------------------------------------------------------------------------

   type QR_Local is record
      Q, R    : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0.0]];
      Success : Boolean := False;
   end record;

   function QR_Factor_MGS (A : Matrix; N : Dimension) return QR_Local is
      Loc : QR_Local;
      Col : Vector (1 .. N);
      Proj, Nrm : Float;
   begin
      for J in 1 .. N loop
         for I in 1 .. N loop
            Col (I) := A (I, J);
         end loop;
         for K in 1 .. J - 1 loop
            Proj := 0.0;
            for I in 1 .. N loop
               Proj := Proj + Loc.Q (I, K) * Col (I);
            end loop;
            Loc.R (K, J) := Proj;
            for I in 1 .. N loop
               Col (I) := Col (I) - Proj * Loc.Q (I, K);
            end loop;
         end loop;
         Nrm := Norm2 (Col);
         Loc.R (J, J) := Nrm;
         if Nrm <= Norm_Tol then
            Loc.Success := False;
            return Loc;
         end if;
         for I in 1 .. N loop
            Loc.Q (I, J) := Col (I) / Nrm;
         end loop;
      end loop;
      Loc.Success := True;
      return Loc;
   end QR_Factor_MGS;

   function Mat_Mul_NN
     (A, B : Matrix; N : Dimension) return Matrix
   is
      C : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      S : Float;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            S := 0.0;
            for K in 1 .. N loop
               S := S + A (I, K) * B (K, J);
            end loop;
            C (I, J) := S;
         end loop;
      end loop;
      return C;
   end Mat_Mul_NN;

   function QR_Unshifted
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Spectrum_Result
   is
      N    : constant Dimension := A'Length (1);
      Res  : Spectrum_Result;
      Work : Matrix (1 .. N, 1 .. N);
      Loc  : QR_Local;
      Next : Matrix (1 .. N, 1 .. N);
      Max_It : Natural;
      Off  : Float;
      E    : Vector (1 .. N);
      Vdum : Matrix (1 .. N, 1 .. N) := Identity (N);
   begin
      Res.N := N;
      Res.Success := False;
      Res.Has_Vectors := False;

      for I in 1 .. N loop
         for J in 1 .. N loop
            Work (I, J) :=
              A (A'First (1) + (I - 1), A'First (2) + (J - 1));
         end loop;
      end loop;

      if Params.Tol < 0.0 then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      if Params.Max_Iter = 0 then
         Max_It := 200;
      else
         Max_It := Params.Max_Iter;
      end if;

      for K in 1 .. Max_It loop
         Off := Off_Diag_Norm (Work);
         Res.Off_Diag := Off;
         Res.Iterations := K;
         if Off <= Params.Tol then
            exit;
         end if;

         Loc := QR_Factor_MGS (Work, N);
         if not Loc.Success then
            Res.Stat := Breakdown;
            for I in 1 .. N loop
               Res.Eigenvalues (I) := Work (I, I);
               for J in 1 .. N loop
                  Res.Final_A (I, J) := Work (I, J);
               end loop;
            end loop;
            return Res;
         end if;

         --  A ← R Q  (unshifted)
         declare
            Qn : Matrix (1 .. N, 1 .. N);
            Rn : Matrix (1 .. N, 1 .. N);
         begin
            for I in 1 .. N loop
               for J in 1 .. N loop
                  Qn (I, J) := Loc.Q (I, J);
                  Rn (I, J) := Loc.R (I, J);
               end loop;
            end loop;
            Next := Mat_Mul_NN (Rn, Qn, N);
            Work := Next;
         end;
      end loop;

      Off := Off_Diag_Norm (Work);
      Res.Off_Diag := Off;
      for I in 1 .. N loop
         E (I) := Work (I, I);
         for J in 1 .. N loop
            Res.Final_A (I, J) := Work (I, J);
         end loop;
      end loop;
      Sort_Eigs_Asc (E, Vdum, N);
      for I in 1 .. N loop
         Res.Eigenvalues (I) := E (I);
      end loop;

      if Off <= Params.Tol * 100.0 or else Off <= 1.0E-3 then
         Res.Stat := Converged;
         Res.Success := True;
      else
         Res.Stat := Iteration_Limit;
      end if;
      return Res;
   end QR_Unshifted;

   -------------------------------------------------------------------------
   -- Lanczos build
   -------------------------------------------------------------------------

   function Lanczos_Build
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Krylov_Result
   is
      N      : constant Dimension := V0'Length;
      Res    : Krylov_Result;
      M_Want : Natural;
      Vj     : Vector (1 .. N);
      Vjm1   : Vector (1 .. N) := [others => 0.0];
      W      : Vector (1 .. N);
      Beta_J : Float := 0.0;
      Alpha, Nrm, Proj : Float;
      Basis  : Matrix (1 .. N, 1 .. Max_N) :=
                 [others => [others => 0.0]];
   begin
      Res.N := N;
      Res.Success := False;
      Res.Has_V := False;
      Res.Steps := 0;

      if N = 0
        or else A'Length (1) /= N
        or else A'Length (2) /= N
      then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      if Params.Tol < 0.0 then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      if not Is_Symmetric (A, Sym_Tol) then
         Res.Stat := Not_Symmetric;
         return Res;
      end if;

      Nrm := Norm2 (V0);
      if Nrm <= Norm_Tol then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      if Params.M = 0 then
         M_Want := Natural'Min (N, 4);
      else
         M_Want := Params.M;
      end if;
      if M_Want > N then
         M_Want := N;
      end if;
      Res.M_Requested := M_Want;

      for I in 1 .. N loop
         Vj (I) := V0 (V0'First + (I - 1)) / Nrm;
      end loop;
      Set_Column (Basis, 1, Vj);

      for J in 1 .. M_Want loop
         W := Mat_Vec (A, Vj);
         Alpha := Dot (Vj, W);
         Res.Alphas (J) := Alpha;

         W := Sub (W, Scale (Vj, Alpha));
         if J > 1 then
            W := Sub (W, Scale (Vjm1, Beta_J));
         end if;

         --  Light reorthogonalization
         for K in 1 .. J loop
            declare
               Vk : constant Vector := Column (Basis, K);
            begin
               Proj := Dot (W, Vk);
               W := Sub (W, Scale (Vk, Proj));
            end;
         end loop;

         Nrm := Norm2 (W);
         Res.Betas (J) := Nrm;
         Res.Beta_Next := Nrm;
         Res.Steps := J;

         if Nrm <= Params.Tol then
            Res.Stat := Breakdown;
            Res.Success := True;
            for Col in 1 .. J loop
               for Row in 1 .. N loop
                  Res.V (Row, Col) := Basis (Row, Col);
               end loop;
            end loop;
            Res.Has_V := True;
            return Res;
         end if;

         if J = M_Want then
            exit;
         end if;

         Vjm1 := Vj;
         Beta_J := Nrm;
         for I in 1 .. N loop
            Vj (I) := W (I) / Nrm;
         end loop;
         Set_Column (Basis, J + 1, Vj);
      end loop;

      for Col in 1 .. Res.Steps loop
         for Row in 1 .. N loop
            Res.V (Row, Col) := Basis (Row, Col);
         end loop;
      end loop;
      Res.Has_V := True;
      Res.Stat := Ok;
      Res.Success := True;
      return Res;
   end Lanczos_Build;

   -------------------------------------------------------------------------
   -- Arnoldi build
   -------------------------------------------------------------------------

   function Arnoldi_Build
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Krylov_Result
   is
      N      : constant Dimension := V0'Length;
      Res    : Krylov_Result;
      M_Want : Natural;
      Vj, W  : Vector (1 .. N);
      Hij, Nrm : Float;
      Basis  : Matrix (1 .. N, 1 .. Max_N) :=
                 [others => [others => 0.0]];
      Hloc   : Matrix (1 .. Max_N, 1 .. Max_N) :=
                 [others => [others => 0.0]];
   begin
      Res.N := N;
      Res.Success := False;
      Res.Has_V := False;
      Res.Steps := 0;

      if N = 0
        or else A'Length (1) /= N
        or else A'Length (2) /= N
      then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      if Params.Tol < 0.0 then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      Nrm := Norm2 (V0);
      if Nrm <= Norm_Tol then
         Res.Stat := Ill_Started;
         return Res;
      end if;

      if Params.M = 0 then
         M_Want := Natural'Min (N, 4);
      else
         M_Want := Params.M;
      end if;
      if M_Want > N then
         M_Want := N;
      end if;
      Res.M_Requested := M_Want;

      for I in 1 .. N loop
         Vj (I) := V0 (V0'First + (I - 1)) / Nrm;
      end loop;
      Set_Column (Basis, 1, Vj);

      for J in 1 .. M_Want loop
         W := Mat_Vec (A, Vj);

         for I in 1 .. J loop
            declare
               Vi : constant Vector := Column (Basis, I);
            begin
               Hij := Dot (Vi, W);
               Hloc (I, J) := Hij;
               W := Sub (W, Scale (Vi, Hij));
            end;
         end loop;

         Nrm := Norm2 (W);
         Res.H_Extra := Nrm;
         Res.Steps := J;

         if Nrm <= Params.Tol then
            Res.Stat := Breakdown;
            Res.Success := True;
            for Col in 1 .. J loop
               for Row in 1 .. N loop
                  Res.V (Row, Col) := Basis (Row, Col);
               end loop;
            end loop;
            for I in 1 .. J loop
               for JJ in 1 .. J loop
                  Res.H (I, JJ) := Hloc (I, JJ);
               end loop;
            end loop;
            Res.Has_V := True;
            return Res;
         end if;

         if J < M_Want then
            Hloc (J + 1, J) := Nrm;
            for I in 1 .. N loop
               Vj (I) := W (I) / Nrm;
            end loop;
            Set_Column (Basis, J + 1, Vj);
         else
            --  Last step: store h_{m+1,m} in H_Extra only
            null;
         end if;
      end loop;

      for Col in 1 .. Res.Steps loop
         for Row in 1 .. N loop
            Res.V (Row, Col) := Basis (Row, Col);
         end loop;
      end loop;
      for I in 1 .. Res.Steps loop
         for J in 1 .. Res.Steps loop
            Res.H (I, J) := Hloc (I, J);
         end loop;
      end loop;
      --  Keep subdiagonal of last completed advance if present
      if Res.Steps >= 2 then
         null;
      end if;
      Res.Has_V := True;
      Res.Stat := Ok;
      Res.Success := True;
      return Res;
   end Arnoldi_Build;

   -------------------------------------------------------------------------
   -- Dispatchers
   -------------------------------------------------------------------------

   function Run_Eigenpair
     (A      : Matrix;
      X0     : Vector;
      Kind   : Method_Kind;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
   is
      Res : Eigenpair_Result;
      P   : Parameters := Params;
   begin
      case Kind is
         when Power =>
            return Power_Dominant (A, X0, Params);

         when Inverse =>
            if not Params.Has_Shift then
               P.Has_Shift := True;
               P.Mu := Params.Mu;
            end if;
            return Inverse_Near (A, P.Mu, X0, P);

         when Rayleigh_Quotient =>
            return Rayleigh_Quotient_Iterate (A, X0, Params);

         when others =>
            Res.N := X0'Length;
            Res.Stat := Not_Implemented;
            Res.Success := False;
            return Res;
      end case;
   end Run_Eigenpair;

   function Run_Spectrum
     (A      : Matrix;
      Kind   : Method_Kind;
      Params : Parameters := Default_Parameters) return Spectrum_Result
   is
      Res : Spectrum_Result;
   begin
      case Kind is
         when Jacobi_Symmetric =>
            return Jacobi_Diagonalize (A, Params);

         when QR_Iteration =>
            return QR_Unshifted (A, Params);

         when others =>
            Res.N := A'Length (1);
            Res.Stat := Not_Implemented;
            Res.Success := False;
            return Res;
      end case;
   end Run_Spectrum;

   function Run_Auto_Eigenpair
     (A      : Matrix;
      X0     : Vector;
      Goal   : Goal_Kind := Want_Dominant;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
   is
      Prop : constant Matrix_Properties := Classify_Matrix (A);
      Kind : Method_Kind;
      G    : Goal_Kind := Goal;
   begin
      --  Spectrum / Krylov goals cannot return Eigenpair_Result; fall back.
      if G = Want_Full_Spectrum or else G = Want_Extremal_Few then
         G := Want_Dominant;
      end if;
      Kind := Recommend_Method (Prop, G, Params.Has_Shift);
      if Kind = Inverse
        or else Kind = Power
        or else Kind = Rayleigh_Quotient
      then
         return Run_Eigenpair (A, X0, Kind, Params);
      else
         return Power_Dominant (A, X0, Params);
      end if;
   end Run_Auto_Eigenpair;

end Eigenvalue_Algorithms;
