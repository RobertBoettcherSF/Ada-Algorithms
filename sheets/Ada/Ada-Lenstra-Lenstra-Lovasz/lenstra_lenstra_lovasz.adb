--  Lenstra_Lenstra_Lovasz body — floating Gram–Schmidt LLL (educational).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Lenstra_Lenstra_Lovasz
  with SPARK_Mode => Off
is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Dot (U, V : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in U'Range loop
         S := S + Real (U (I)) * Real (V (I - U'First + V'First));
      end loop;
      return S;
   end Dot;

   function Dot (U, V : Real_Vector) return Real is
      S : Real := 0.0;
   begin
      for I in U'Range loop
         S := S + U (I) * V (I - U'First + V'First);
      end loop;
      return S;
   end Dot;

   function Norm2 (V : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in V'Range loop
         S := S + Real (V (I)) * Real (V (I));
      end loop;
      return S;
   end Norm2;

   function Norm2 (V : Real_Vector) return Real is
      S : Real := 0.0;
   begin
      for I in V'Range loop
         S := S + V (I) * V (I);
      end loop;
      return S;
   end Norm2;

   function Euclidean_Norm (V : Vector) return Real is
   begin
      return Sqrt (Norm2 (V));
   end Euclidean_Norm;

   function Euclidean_Norm (V : Real_Vector) return Real is
   begin
      return Sqrt (Norm2 (V));
   end Euclidean_Norm;

   function Nearest_Integer (X : Real) return Integer is
   begin
      return Integer (Real'Rounding (X));
   end Nearest_Integer;

   function Make_Vector (X : Vector) return Fixed_Vector is
      R : Fixed_Vector := [others => 0];
      K : Positive := 1;
   begin
      for I in X'Range loop
         R (K) := X (I);
         K := K + 1;
      end loop;
      return R;
   end Make_Vector;

   function Slice (V : Fixed_Vector; M : Dimension) return Vector is
      R : Vector (1 .. M);
   begin
      for J in 1 .. M loop
         R (J) := V (J);
      end loop;
      return R;
   end Slice;

   function Make_Basis (Rows : Matrix) return Basis_Bundle is
      N : constant Dimension := Rows'Length (1);
      M : constant Dimension := Rows'Length (2);
      R : Basis_Bundle (N, M);
      RI : Positive := 1;
   begin
      for I in Rows'Range (1) loop
         declare
            CJ : Positive := 1;
         begin
            for J in Rows'Range (2) loop
               R.B (RI) (CJ) := Rows (I, J);
               CJ := CJ + 1;
            end loop;
         end;
         RI := RI + 1;
      end loop;
      return R;
   end Make_Basis;

   function To_Matrix (Bundle : Basis_Bundle) return Matrix is
      R : Matrix (1 .. Bundle.N, 1 .. Bundle.M);
   begin
      for I in 1 .. Bundle.N loop
         for J in 1 .. Bundle.M loop
            R (I, J) := Bundle.B (I) (J);
         end loop;
      end loop;
      return R;
   end To_Matrix;

   function Copy_Basis (Bundle : Basis_Bundle) return Basis_Bundle is
      R : Basis_Bundle (Bundle.N, Bundle.M);
   begin
      for I in 1 .. Bundle.N loop
         R.B (I) := Bundle.B (I);
      end loop;
      return R;
   end Copy_Basis;

   -------------------------------------------------------------------------
   -- Gram–Schmidt
   -------------------------------------------------------------------------

   procedure Gram_Schmidt
     (Bundle      : Basis_Bundle;
      Bstar       : out Real_Matrix;
      Mu          : out Real_Matrix;
      Bstar_Norm2 : out Real_Vector)
   is
      N : constant Dimension := Bundle.N;
      M : constant Dimension := Bundle.M;
   begin
      for I in Bstar'Range (1) loop
         for J in Bstar'Range (2) loop
            Bstar (I, J) := 0.0;
         end loop;
      end loop;
      for I in Mu'Range (1) loop
         for J in Mu'Range (2) loop
            Mu (I, J) := 0.0;
         end loop;
      end loop;
      for I in Bstar_Norm2'Range loop
         Bstar_Norm2 (I) := 0.0;
      end loop;

      for I in 1 .. N loop
         --  b*_i ← b_i
         for J in 1 .. M loop
            Bstar (I, J) := Real (Bundle.B (I) (J));
         end loop;

         for J in 1 .. I - 1 loop
            declare
               Num : Real := 0.0;
               Den : constant Real := Bstar_Norm2 (J);
            begin
               for T in 1 .. M loop
                  Num := Num + Real (Bundle.B (I) (T)) * Bstar (J, T);
               end loop;
               if Den > 0.0 then
                  Mu (I, J) := Num / Den;
               else
                  Mu (I, J) := 0.0;
               end if;
               for T in 1 .. M loop
                  Bstar (I, T) :=
                    Bstar (I, T) - Mu (I, J) * Bstar (J, T);
               end loop;
            end;
         end loop;

         declare
            S : Real := 0.0;
         begin
            for T in 1 .. M loop
               S := S + Bstar (I, T) * Bstar (I, T);
            end loop;
            Bstar_Norm2 (I) := S;
         end;
      end loop;
   end Gram_Schmidt;

   -------------------------------------------------------------------------
   -- Predicates
   -------------------------------------------------------------------------

   function Is_Size_Reduced
     (Bundle : Basis_Bundle; Tol : Real := Mu_Tol) return Boolean
   is
      Bstar       : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Mu          : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Bstar_Norm2 : Real_Vector (1 .. Max_Dim);
   begin
      if Bundle.N = 0 or else Bundle.M = 0 then
         return False;
      end if;
      Gram_Schmidt (Bundle, Bstar, Mu, Bstar_Norm2);
      for I in 1 .. Bundle.N loop
         for J in 1 .. I - 1 loop
            if abs (Mu (I, J)) > 0.5 + Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Size_Reduced;

   function Satisfies_Lovasz
     (Bundle : Basis_Bundle;
      Reduction_Delta : Real := Default_Delta;
      Tol    : Real := Lovasz_Tol) return Boolean
   is
      Bstar       : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Mu          : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Bstar_Norm2 : Real_Vector (1 .. Max_Dim);
   begin
      if Bundle.N <= 1 then
         return Bundle.N = 1 and then Bundle.M >= 1;
      end if;
      if Bundle.M = 0 then
         return False;
      end if;
      Gram_Schmidt (Bundle, Bstar, Mu, Bstar_Norm2);
      for K in 2 .. Bundle.N loop
         declare
            Left  : constant Real := Reduction_Delta * Bstar_Norm2 (K - 1);
            Right : constant Real :=
              Bstar_Norm2 (K)
              + Mu (K, K - 1) * Mu (K, K - 1) * Bstar_Norm2 (K - 1);
         begin
            if Left > Right + Tol then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Satisfies_Lovasz;

   function Is_LLL_Reduced
     (Bundle : Basis_Bundle;
      Reduction_Delta : Real := Default_Delta;
      Tol    : Real := Mu_Tol) return Boolean
   is
   begin
      return Is_Size_Reduced (Bundle, Tol)
        and then Satisfies_Lovasz (Bundle, Reduction_Delta, Tol);
   end Is_LLL_Reduced;

   function Volume (Bundle : Basis_Bundle) return Real is
      Bstar       : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Mu          : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Bstar_Norm2 : Real_Vector (1 .. Max_Dim);
      Prod        : Real := 1.0;
   begin
      Gram_Schmidt (Bundle, Bstar, Mu, Bstar_Norm2);
      for I in 1 .. Bundle.N loop
         if Bstar_Norm2 (I) <= 0.0 then
            return 0.0;
         end if;
         Prod := Prod * Sqrt (Bstar_Norm2 (I));
      end loop;
      return Prod;
   end Volume;

   function Max_Euclidean_Norm (Bundle : Basis_Bundle) return Real is
      Best : Real := 0.0;
   begin
      for I in 1 .. Bundle.N loop
         declare
            N2 : constant Real := Norm2 (Slice (Bundle.B (I), Bundle.M));
         begin
            if N2 > Best then
               Best := N2;
            end if;
         end;
      end loop;
      return Sqrt (Best);
   end Max_Euclidean_Norm;

   function Sum_Squared_Norms (Bundle : Basis_Bundle) return Real is
      S : Real := 0.0;
   begin
      for I in 1 .. Bundle.N loop
         S := S + Norm2 (Slice (Bundle.B (I), Bundle.M));
      end loop;
      return S;
   end Sum_Squared_Norms;

   -------------------------------------------------------------------------
   -- Core LLL
   -------------------------------------------------------------------------

   function LLL_Reduce
     (Bundle : Basis_Bundle;
      Reduction_Delta : Real := Default_Delta) return Basis_Bundle
   is
      N : constant Dimension := Bundle.N;
      M : constant Dimension := Bundle.M;
      Work : Basis_Bundle (N, M);

      Bstar       : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Mu          : Real_Matrix (1 .. Max_Dim, 1 .. Max_Dim);
      Bstar_Norm2 : Real_Vector (1 .. Max_Dim);

      K : Positive := 2;

      procedure Recompute_GS is
      begin
         Gram_Schmidt (Work, Bstar, Mu, Bstar_Norm2);
      end Recompute_GS;

      procedure Size_Reduce_Against (Ki, J : Positive) is
         R : Integer;
      begin
         if abs (Mu (Ki, J)) > 0.5 then
            R := Nearest_Integer (Mu (Ki, J));
            for T in 1 .. M loop
               Work.B (Ki) (T) := Work.B (Ki) (T) - R * Work.B (J) (T);
            end loop;
            Recompute_GS;
         end if;
      end Size_Reduce_Against;

   begin
      if N = 0 or else M = 0 then
         raise Invalid_Argument with "empty lattice basis";
      end if;
      if Reduction_Delta <= 0.25 or else Reduction_Delta > 1.0 then
         raise Invalid_Argument
           with "Reduction_Delta must satisfy 1/4 < Reduction_Delta <= 1";
      end if;

      Work := Copy_Basis (Bundle);

      if N = 1 then
         return Work;
      end if;

      Recompute_GS;
      K := 2;

      while K <= N loop
         --  Size-reduce b_k against b_{k-1}, ..., b_1
         for J in reverse 1 .. K - 1 loop
            Size_Reduce_Against (K, J);
         end loop;

         --  Lovász condition
         if Bstar_Norm2 (K)
           >= (Reduction_Delta - Mu (K, K - 1) * Mu (K, K - 1)) * Bstar_Norm2 (K - 1)
         then
            K := K + 1;
         else
            declare
               Tmp : Fixed_Vector;
            begin
               Tmp := Work.B (K);
               Work.B (K) := Work.B (K - 1);
               Work.B (K - 1) := Tmp;
            end;
            Recompute_GS;
            if K > 2 then
               K := K - 1;
            else
               K := 2;
            end if;
         end if;
      end loop;

      return Work;
   end LLL_Reduce;

   function LLL_Reduce
     (B     : Matrix;
      Reduction_Delta : Real := Default_Delta) return Matrix
   is
      Bundle : constant Basis_Bundle := Make_Basis (B);
      Red    : constant Basis_Bundle := LLL_Reduce (Bundle, Reduction_Delta);
   begin
      return To_Matrix (Red);
   end LLL_Reduce;

   function LLL_Reduce
     (B       : Basis;
      Ambient : Dimension;
      Reduction_Delta   : Real := Default_Delta) return Basis
   is
      N : constant Dimension := B'Length;
      Bundle : Basis_Bundle (N, Ambient);
      Red    : Basis_Bundle (N, Ambient);
      Out_B  : Basis (B'Range);
      Src    : Positive := 1;
   begin
      for I in B'Range loop
         Bundle.B (Src) := B (I);
         Src := Src + 1;
      end loop;
      Red := LLL_Reduce (Bundle, Reduction_Delta);
      Src := 1;
      for I in Out_B'Range loop
         Out_B (I) := Red.B (Src);
         Src := Src + 1;
      end loop;
      return Out_B;
   end LLL_Reduce;

end Lenstra_Lenstra_Lovasz;
