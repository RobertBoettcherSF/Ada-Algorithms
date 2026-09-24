-- lemke_howson.adb
-- Implementation of the Lemke-Howson complementary pivoting algorithm.

package body Lemke_Howson is

   -- Helper to pivot a tableau
   procedure Pivot
     (Tab       : in out Matrix;
      Rows      : Positive;
      Cols      : Positive;
      Pivot_Row : Positive;
      Pivot_Col : Positive)
   is
      Divisor : constant Real := Tab (Pivot_Row, Pivot_Col);
      Factor  : Real;
   begin
      -- Scale the pivot row
      for J in 1 .. Cols loop
         Tab (Pivot_Row, J) := Tab (Pivot_Row, J) / Divisor;
      end loop;

      -- Eliminate the pivot column in all other rows
      for I in 1 .. Rows loop
         if I /= Pivot_Row then
            Factor := Tab (I, Pivot_Col);
            for J in 1 .. Cols loop
               Tab (I, J) := Tab (I, J) - Factor * Tab (Pivot_Row, J);
            end loop;
         end if;
      end loop;
   end Pivot;

   -- Helper to find the leaving variable (Minimum Ratio Test)
   function Find_Leaving_Variable
     (Tab          : Matrix;
      Rows         : Positive;
      Entering_Col : Positive;
      RHS_Col      : Positive) return Positive
   is
      Min_Ratio : Real := Real'Last;
      Best_Row  : Positive := 1;
      Ratio     : Real;
      Found     : Boolean := False;
      Epsilon   : constant Real := 1.0e-9;
   begin
      for I in 1 .. Rows loop
         if Tab (I, Entering_Col) > Epsilon then
            Ratio := Tab (I, RHS_Col) / Tab (I, Entering_Col);
            if Ratio < Min_Ratio then
               Min_Ratio := Ratio;
               Best_Row  := I;
               Found     := True;
            end if;
         end if;
      end loop;

      if not Found then
         raise Unbounded_Problem with "No valid pivot row found. Problem is unbounded.";
      end if;

      return Best_Row;
   end Find_Leaving_Variable;

   function Solve
     (A, B          : Matrix;
      Dropped_Label : Positive := 1) return Equilibrium
   is
      -- Ensure matrices are not empty
      M : constant Natural := A'Length (1);
      N : constant Natural := A'Length (2);
   begin
      if M = 0 or else N = 0 then
         raise Invalid_Input with "Matrices cannot be empty.";
      end if;

      if A'Length (1) /= B'Length (1) or else A'Length (2) /= B'Length (2) then
         raise Invalid_Input with "Payoff matrices A and B must have identical dimensions.";
      end if;

      if Dropped_Label > M + N then
         raise Invalid_Input with "Dropped_Label must be <= M + N.";
      end if;

      declare
         -- 1-based internal copies to simplify indexing mathematics
         Local_A : Matrix (1 .. M, 1 .. N);
         Local_B : Matrix (1 .. M, 1 .. N);

         Offset  : Real := 0.0;
         Min_Val : Real := 0.0;

         -- Tableaux: T1 (Player 2's mixed strategies / P1's payoffs)
         --           T2 (Player 1's mixed strategies / P2's payoffs)
         T1_Cols : constant Positive := M + N + 1;
         T1      : Matrix (1 .. M, 1 .. T1_Cols) := (others => (others => 0.0));
         Basic1  : array (1 .. M) of Positive;

         T2_Cols : constant Positive := M + N + 1;
         T2      : Matrix (1 .. N, 1 .. T2_Cols) := (others => (others => 0.0));
         Basic2  : array (1 .. N) of Positive;

         Curr_Tab     : Integer;
         Entering_Col : Positive;
         Leaving_Lbl  : Positive;
         Pivot_Row    : Positive;
         
         Result       : Equilibrium (M, N);
         Sum1, Sum2   : Real := 0.0;
      begin
         -- Copy elements and find min value to ensure strict positivity
         for I in 1 .. M loop
            for J in 1 .. N loop
               Local_A (I, J) := A (A'First (1) + I - 1, A'First (2) + J - 1);
               Local_B (I, J) := B (B'First (1) + I - 1, B'First (2) + J - 1);
               if Local_A (I, J) < Min_Val then Min_Val := Local_A (I, J); end if;
               if Local_B (I, J) < Min_Val then Min_Val := Local_B (I, J); end if;
            end loop;
         end loop;

         Offset := abs (Min_Val) + 1.0;

         -- Initialize Tableau 1 (Variables: s1..sm in 1..M, y1..yn in M+1..M+N)
         for I in 1 .. M loop
            Basic1 (I) := I; -- Initially basic variables are the slacks s1..sm
            T1 (I, I) := 1.0;
            for J in 1 .. N loop
               T1 (I, M + J) := Local_A (I, J) + Offset;
            end loop;
            T1 (I, T1_Cols) := 1.0; -- RHS
         end loop;

         -- Initialize Tableau 2 (Variables: x1..xm in 1..M, r1..rn in M+1..M+N)
         for J in 1 .. N loop
            Basic2 (J) := M + J; -- Initially basic variables are the slacks r1..rn
            T2 (J, M + J) := 1.0;
            for I in 1 .. M loop
               T2 (J, I) := Local_B (I, J) + Offset; -- Transposed access for B^T
            end loop;
            T2 (J, T2_Cols) := 1.0; -- RHS
         end loop;

         -- Setup Initial Drop Variant
         Entering_Col := Dropped_Label;
         if Dropped_Label <= M then
            Curr_Tab := 2; -- Dropping x_k/s_k means x_k enters T2
         else
            Curr_Tab := 1; -- Dropping y_k/r_k means y_k enters T1
         end if;

         -- Pivoting Loop
         loop
            if Curr_Tab = 1 then
               Pivot_Row := Find_Leaving_Variable (T1, M, Entering_Col, T1_Cols);
               Leaving_Lbl := Basic1 (Pivot_Row);
               Pivot (T1, M, T1_Cols, Pivot_Row, Entering_Col);
               Basic1 (Pivot_Row) := Entering_Col;
            else
               Pivot_Row := Find_Leaving_Variable (T2, N, Entering_Col, T2_Cols);
               Leaving_Lbl := Basic2 (Pivot_Row);
               Pivot (T2, N, T2_Cols, Pivot_Row, Entering_Col);
               Basic2 (Pivot_Row) := Entering_Col;
            end if;

            exit when Leaving_Lbl = Dropped_Label;

            -- The leaving variable becomes the entering variable in the other tableau
            Entering_Col := Leaving_Lbl;
            if Curr_Tab = 1 then
               Curr_Tab := 2;
            else
               Curr_Tab := 1;
            end if;
         end loop;

         -- Extract non-normalized probabilities
         for I in 1 .. M loop
            Result.P1 (I) := 0.0;
            for R in 1 .. N loop
               if Basic2 (R) = I then Result.P1 (I) := T2 (R, T2_Cols); end if;
            end loop;
            Sum1 := Sum1 + Result.P1 (I);
         end loop;

         for J in 1 .. N loop
            Result.P2 (J) := 0.0;
            for R in 1 .. M loop
               if Basic1 (R) = M + J then Result.P2 (J) := T1 (R, T1_Cols); end if;
            end loop;
            Sum2 := Sum2 + Result.P2 (J);
         end loop;

         -- Normalize probabilities
         for I in 1 .. M loop Result.P1 (I) := Result.P1 (I) / Sum1; end loop;
         for J in 1 .. N loop Result.P2 (J) := Result.P2 (J) / Sum2; end loop;

         return Result;
      end;
   end Solve;

end Lemke_Howson;
