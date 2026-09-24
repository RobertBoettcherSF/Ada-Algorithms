--  Birkhoff_Von_Neumann body — Birkhoff peeling + support DFS matching.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Birkhoff_Von_Neumann is

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   function Abs_R (X : Real) return Real is
   begin
      if X < 0.0 then
         return -X;
      else
         return X;
      end if;
   end Abs_R;

   function Min_R (X, Y : Real) return Real is
   begin
      if X < Y then
         return X;
      else
         return Y;
      end if;
   end Min_R;

   function Perm_Slice_OK (P : Permutation; N : Dimension) return Boolean is
      Used : array (1 .. Max_N) of Boolean := [others => False];
      J    : Natural;
   begin
      if N = 0 then
         return True;
      end if;
      if P'Length < N then
         return False;
      end if;
      for K in 0 .. N - 1 loop
         J := P (P'First + K);
         if J < 1 or else J > Natural (N) then
            return False;
         end if;
         if Used (J) then
            return False;
         end if;
         Used (J) := True;
      end loop;
      return True;
   end Perm_Slice_OK;

   ---------------------------------------------------------------------------
   -- Predicates / numeric helpers
   ---------------------------------------------------------------------------

   function Is_Square (A : Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square;

   function Near (X, Y : Real; Tol : Real := Zero_Tol) return Boolean is
   begin
      return Abs_R (X - Y) <= Tol;
   end Near;

   function Entry_Near_Zero (X : Real; Tol : Real := Zero_Tol) return Boolean is
   begin
      return Abs_R (X) <= Tol;
   end Entry_Near_Zero;

   function Row_Sum (A : Matrix; I : Positive) return Real is
      S : Real := 0.0;
   begin
      for J in A'Range (2) loop
         S := S + A (I, J);
      end loop;
      return S;
   end Row_Sum;

   function Col_Sum (A : Matrix; J : Positive) return Real is
      S : Real := 0.0;
   begin
      for I in A'Range (1) loop
         S := S + A (I, J);
      end loop;
      return S;
   end Col_Sum;

   function Is_Nonnegative (A : Matrix; Tol : Real := Zero_Tol) return Boolean is
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if A (I, J) < -Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Nonnegative;

   function Is_Doubly_Stochastic
     (A : Matrix; Tol : Real := Sum_Tol) return Boolean
   is
   begin
      if not Is_Square (A) then
         return False;
      end if;
      if A'Length (1) = 0 then
         return True;
      end if;
      if not Is_Nonnegative (A, Tol) then
         return False;
      end if;
      for I in A'Range (1) loop
         if not Near (Row_Sum (A, I), 1.0, Tol) then
            return False;
         end if;
      end loop;
      for J in A'Range (2) loop
         if not Near (Col_Sum (A, J), 1.0, Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Doubly_Stochastic;

   function Matrices_Near
     (A, B : Matrix; Tol : Real := Recon_Tol) return Boolean
   is
   begin
      if A'Length (1) /= B'Length (1) or else A'Length (2) /= B'Length (2) then
         return False;
      end if;
      declare
         AI : Positive := A'First (1);
         BI : Positive := B'First (1);
      begin
         while AI <= A'Last (1) loop
            declare
               AJ : Positive := A'First (2);
               BJ : Positive := B'First (2);
            begin
               while AJ <= A'Last (2) loop
                  if Abs_R (A (AI, AJ) - B (BI, BJ)) > Tol then
                     return False;
                  end if;
                  AJ := AJ + 1;
                  BJ := BJ + 1;
               end loop;
            end;
            AI := AI + 1;
            BI := BI + 1;
         end loop;
      end;
      return True;
   end Matrices_Near;

   function Frobenius_Distance (A, B : Matrix) return Real is
      S  : Real := 0.0;
      AI : Positive := A'First (1);
      BI : Positive := B'First (1);
      D  : Real;
   begin
      while AI <= A'Last (1) loop
         declare
            AJ : Positive := A'First (2);
            BJ : Positive := B'First (2);
         begin
            while AJ <= A'Last (2) loop
               D := A (AI, AJ) - B (BI, BJ);
               S := S + D * D;
               AJ := AJ + 1;
               BJ := BJ + 1;
            end loop;
         end;
         AI := AI + 1;
         BI := BI + 1;
      end loop;
      return Real (Ada.Numerics.Long_Elementary_Functions.Sqrt (Long_Float (S)));
   end Frobenius_Distance;

   function Is_Permutation (P : Permutation; N : Dimension) return Boolean is
   begin
      return Perm_Slice_OK (P, N);
   end Is_Permutation;

   function Lambda_Sum (D : Decomposition) return Real is
      S : Real := 0.0;
   begin
      for K in 1 .. D.Count loop
         S := S + D.Terms (K).Lambda;
      end loop;
      return S;
   end Lambda_Sum;

   ---------------------------------------------------------------------------
   -- Constructors
   ---------------------------------------------------------------------------

   function Zero_Matrix (N : Dimension) return Matrix is
      Z : constant Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      return Z;
   end Zero_Matrix;

   function Identity (N : Dimension) return Matrix is
      I : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for K in 1 .. N loop
         I (K, K) := 1.0;
      end loop;
      return I;
   end Identity;

   function Uniform (N : Dimension) return Matrix is
      U : Matrix (1 .. N, 1 .. N);
      V : constant Real := 1.0 / Real (N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            U (I, J) := V;
         end loop;
      end loop;
      return U;
   end Uniform;

   function Identity_Permutation (N : Dimension) return Permutation is
      P : Permutation (1 .. N);
   begin
      for I in 1 .. N loop
         P (I) := I;
      end loop;
      return P;
   end Identity_Permutation;

   function Reverse_Permutation (N : Dimension) return Permutation is
      P : Permutation (1 .. N);
   begin
      for I in 1 .. N loop
         P (I) := N - I + 1;
      end loop;
      return P;
   end Reverse_Permutation;

   function Cycle_Permutation (N : Dimension; Shift : Natural := 1)
     return Permutation
   is
      P : Permutation (1 .. N);
      S : constant Natural := Shift mod Natural (N);
   begin
      for I in 1 .. N loop
         P (I) := ((I - 1 + S) mod N) + 1;
      end loop;
      return P;
   end Cycle_Permutation;

   function Permutation_Matrix (P : Permutation; N : Dimension) return Matrix is
      M : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      if not Perm_Slice_OK (P, N) then
         raise Invalid_Argument with "Permutation_Matrix: not a permutation";
      end if;
      for I in 1 .. N loop
         M (I, P (P'First + (I - 1))) := 1.0;
      end loop;
      return M;
   end Permutation_Matrix;

   function Scale (A : Matrix; S : Real) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J) * S;
         end loop;
      end loop;
      return R;
   end Scale;

   function Add (A, B : Matrix) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
      BI : Positive := B'First (1);
   begin
      for AI in A'Range (1) loop
         declare
            BJ : Positive := B'First (2);
         begin
            for AJ in A'Range (2) loop
               R (AI, AJ) := A (AI, AJ) + B (BI, BJ);
               BJ := BJ + 1;
            end loop;
         end;
         BI := BI + 1;
      end loop;
      return R;
   end Add;

   function Sub (A, B : Matrix) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
      BI : Positive := B'First (1);
   begin
      for AI in A'Range (1) loop
         declare
            BJ : Positive := B'First (2);
         begin
            for AJ in A'Range (2) loop
               R (AI, AJ) := A (AI, AJ) - B (BI, BJ);
               BJ := BJ + 1;
            end loop;
         end;
         BI := BI + 1;
      end loop;
      return R;
   end Sub;

   function Convex_Combination
     (Lambdas : Term_List; Count : Natural; N : Dimension) return Matrix
   is
      Acc : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      S   : Real := 0.0;
      T   : Term;
      PM  : Matrix (1 .. N, 1 .. N);
   begin
      if Count < 1 or else Count > Lambdas'Length then
         raise Invalid_Argument with "Convex_Combination: bad Count";
      end if;
      for K in 0 .. Count - 1 loop
         T := Lambdas (Lambdas'First + K);
         if T.Lambda < -Zero_Tol then
            raise Invalid_Argument with "Convex_Combination: negative lambda";
         end if;
         if T.N /= 0 and then T.N /= N then
            raise Invalid_Argument with "Convex_Combination: N mismatch";
         end if;
         if not Perm_Slice_OK (T.Perm, N) then
            raise Invalid_Argument with "Convex_Combination: bad perm";
         end if;
         S := S + T.Lambda;
         PM := Permutation_Matrix (T.Perm, N);
         for I in 1 .. N loop
            for J in 1 .. N loop
               Acc (I, J) := Acc (I, J) + T.Lambda * PM (I, J);
            end loop;
         end loop;
      end loop;
      if not Near (S, 1.0, Sum_Tol) then
         raise Invalid_Argument with "Convex_Combination: lambdas must sum to 1";
      end if;
      return Acc;
   end Convex_Combination;

   function Make_Toy_DS (N : Dimension) return Matrix is
      Terms : Term_List (1 .. 3);
      C     : Natural := 0;
      P1    : constant Permutation := Identity_Permutation (N);
      P2    : constant Permutation := Reverse_Permutation (N);
      P3    : constant Permutation := Cycle_Permutation (N, 1);
   begin
      --  For N = 1 reverse = identity = cycle; use a single term.
      if N = 1 then
         Terms (1) := (Lambda => 1.0, Perm => [1 => 1, others => 0], N => 1);
         return Convex_Combination (Terms, 1, 1);
      end if;
      --  Distinct perms when possible: id, reverse, cycle.
      C := 1;
      Terms (1).Lambda := 0.5;
      Terms (1).N := N;
      for I in 1 .. N loop
         Terms (1).Perm (I) := P1 (I);
      end loop;
      if N = 2 then
         --  id and reverse (swap) only; cycle(1) = reverse for n=2.
         Terms (1).Lambda := 0.4;
         Terms (2).Lambda := 0.6;
         Terms (2).N := N;
         for I in 1 .. N loop
            Terms (2).Perm (I) := P2 (I);
         end loop;
         C := 2;
      else
         Terms (1).Lambda := 0.4;
         Terms (2).Lambda := 0.35;
         Terms (2).N := N;
         for I in 1 .. N loop
            Terms (2).Perm (I) := P2 (I);
         end loop;
         Terms (3).Lambda := 0.25;
         Terms (3).N := N;
         for I in 1 .. N loop
            Terms (3).Perm (I) := P3 (I);
         end loop;
         C := 3;
      end if;
      return Convex_Combination (Terms, C, N);
   end Make_Toy_DS;

   function Wikipedia_Example_3x3 return Matrix is
      M : Matrix (1 .. 3, 1 .. 3);
   begin
      --  (1/12) * [[7,0,5],[2,6,4],[3,6,3]]
      M := [[7.0, 0.0, 5.0],
            [2.0, 6.0, 4.0],
            [3.0, 6.0, 3.0]];
      return Scale (M, 1.0 / 12.0);
   end Wikipedia_Example_3x3;

   ---------------------------------------------------------------------------
   -- Support perfect matching (DFS / backtracking)
   ---------------------------------------------------------------------------

   function Find_Support_Permutation
     (A : Matrix; Tol : Real := Zero_Tol) return Permutation
   is
      N : constant Dimension := A'Length (1);
   begin
      if not Is_Square (A) then
         raise Invalid_Argument with "Find_Support_Permutation: not square";
      end if;
      if N = 0 then
         raise Invalid_Argument with "Find_Support_Permutation: empty matrix";
      end if;

      declare
         --  Work on 1 .. N indices mapped from A'First.
         R0 : constant Positive := A'First (1);
         C0 : constant Positive := A'First (2);
         Col_Used : array (1 .. Max_N) of Boolean := [others => False];
         Assign   : array (1 .. Max_N) of Natural := [others => 0];
         Found    : Boolean := False;

         function Positive_Edge (Row, Col : Positive) return Boolean is
            AI : constant Positive := R0 + (Row - 1);
            AJ : constant Positive := C0 + (Col - 1);
         begin
            return A (AI, AJ) > Tol;
         end Positive_Edge;

         procedure Search (Row : Positive) is
         begin
            if Found then
               return;
            end if;
            if Row > N then
               Found := True;
               return;
            end if;
            for Col in 1 .. N loop
               if not Col_Used (Col) and then Positive_Edge (Row, Col) then
                  Col_Used (Col) := True;
                  Assign (Row) := Col;
                  Search (Row + 1);
                  if Found then
                     return;
                  end if;
                  Col_Used (Col) := False;
                  Assign (Row) := 0;
               end if;
            end loop;
         end Search;

         Result : Permutation (1 .. N);
      begin
         Search (1);
         if not Found then
            raise Invalid_Argument with
              "Find_Support_Permutation: no perfect matching in support";
         end if;
         for I in 1 .. N loop
            Result (I) := Assign (I);
         end loop;
         return Result;
      end;
   end Find_Support_Permutation;

   ---------------------------------------------------------------------------
   -- Birkhoff algorithm
   ---------------------------------------------------------------------------

   function Residual_Is_Zero (R : Matrix; Tol : Real) return Boolean is
   begin
      for I in R'Range (1) loop
         for J in R'Range (2) loop
            if Abs_R (R (I, J)) > Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Residual_Is_Zero;

   function Decompose
     (A : Matrix; Tol : Real := Zero_Tol) return Decomposition
   is
      N : constant Dimension := A'Length (1);
      D : Decomposition;
   begin
      D.N := N;
      D.Count := 0;
      D.Success := False;

      if not Is_Square (A) then
         raise Invalid_Argument with "Decompose: matrix not square";
      end if;
      --  N is Dimension (0 .. Max_N); oversized inputs are rejected by
      --  the subtype conversion of A'Length (1) above / caller Pre.
      if N = 0 then
         D.Success := True;
         return D;
      end if;
      if not Is_Doubly_Stochastic (A, Sum_Tol) then
         raise Invalid_Argument with
           "Decompose: matrix is not doubly stochastic";
      end if;

      declare
         R   : Matrix (1 .. N, 1 .. N);
         R0  : constant Positive := A'First (1);
         C0  : constant Positive := A'First (2);
         Pi  : Permutation (1 .. N);
         Theta : Real;
         Step  : Natural := 0;
      begin
         --  Copy into 1-based working residual.
         for I in 1 .. N loop
            for J in 1 .. N loop
               R (I, J) := A (R0 + (I - 1), C0 + (J - 1));
            end loop;
         end loop;

         while not Residual_Is_Zero (R, Tol) loop
            Step := Step + 1;
            if Step > Max_Terms then
               raise Invalid_Argument with
                 "Decompose: exceeded Max_Terms (numerical stall?)";
            end if;

            Pi := Find_Support_Permutation (R, Tol);
            Theta := R (1, Pi (1));
            for I in 2 .. N loop
               Theta := Min_R (Theta, R (I, Pi (I)));
            end loop;

            if Theta <= Tol then
               --  Should not happen if matching used edges > Tol.
               raise Invalid_Argument with
                 "Decompose: non-positive theta on support matching";
            end if;

            D.Count := D.Count + 1;
            D.Terms (D.Count).Lambda := Theta;
            D.Terms (D.Count).N := N;
            for I in 1 .. N loop
               D.Terms (D.Count).Perm (I) := Pi (I);
               R (I, Pi (I)) := R (I, Pi (I)) - Theta;
            end loop;
         end loop;

         --  Clamp tiny negative residuals from float noise (already zeroed).
         D.Success := True;
         return D;
      end;
   end Decompose;

   function Birkhoff_Decomposition
     (A : Matrix; Tol : Real := Zero_Tol) return Decomposition
   is
   begin
      return Decompose (A, Tol);
   end Birkhoff_Decomposition;

   function Reconstruct (D : Decomposition) return Matrix is
      N : constant Dimension := D.N;
      Acc : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      T   : Term;
      J   : Natural;
   begin
      if not D.Success then
         raise Invalid_Argument with "Reconstruct: decomposition not Success";
      end if;
      if N = 0 then
         return Zero_Matrix (0);
      end if;
      for K in 1 .. D.Count loop
         T := D.Terms (K);
         if not Perm_Slice_OK (T.Perm, N) then
            raise Invalid_Argument with "Reconstruct: bad permutation term";
         end if;
         for I in 1 .. N loop
            J := T.Perm (I);
            Acc (I, J) := Acc (I, J) + T.Lambda;
         end loop;
      end loop;
      return Acc;
   end Reconstruct;

   function Reconstruct_Near
     (A : Matrix; Tol : Real := Recon_Tol) return Boolean
   is
   begin
      if not Is_Square (A) or else A'Length (1) > Max_N then
         return False;
      end if;
      if not Is_Doubly_Stochastic (A, Sum_Tol) then
         return False;
      end if;
      declare
         D : constant Decomposition := Decompose (A);
         B : constant Matrix := Reconstruct (D);
      begin
         return Matrices_Near (A, B, Tol);
      end;
   exception
      when Invalid_Argument =>
         return False;
   end Reconstruct_Near;

end Birkhoff_Von_Neumann;
