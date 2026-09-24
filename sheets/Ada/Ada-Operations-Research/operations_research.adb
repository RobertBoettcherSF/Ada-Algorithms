package body Operations_Research is

   type Index_Array is array (Positive range <>) of Positive;

   -- Core simplex tableau solver used by both Maximize and Minimize.
   -- Implements standard tableau pivot logic and maintains the Basis array.
   procedure Solve_Tableau
     (Tableau  : in out Matrix_Type;
      Num_Vars : in Positive;
      Num_Cons : in Positive;
      Basis    : out Index_Array)
   is
      Pivot_Row : Positive := 1;
      Pivot_Col : Positive := 1;
      Found : Boolean;
      Rows : constant Positive := Num_Cons + 1;
      Cols : constant Positive := Num_Vars + Num_Cons + 1;
      Tolerance : constant Value_Type := 1.0e-9;
   begin
      -- Initialize basis to the slack variables
      for I in 1 .. Num_Cons loop
         Basis (I) := Num_Vars + I;
      end loop;

      loop
         -- 1. Find pivot column: most negative element in the objective row
         declare
            Min_Val : Value_Type := -Tolerance;
         begin
            Found := False;
            for J in 1 .. Cols - 1 loop
               if Tableau (Rows, J) < Min_Val then
                  Min_Val := Tableau (Rows, J);
                  Pivot_Col := J;
                  Found := True;
               end if;
            end loop;
         end;

         -- If no negative elements remain in the objective row, the solution is optimal.
         exit when not Found;

         -- 2. Find pivot row: minimum positive ratio of RHS to Pivot Column element
         declare
            Min_Ratio_Val : Value_Type := Value_Type'Last;
            Ratio         : Value_Type;
         begin
            Found := False;
            for I in 1 .. Num_Cons loop
               if Tableau (I, Pivot_Col) > Tolerance then
                  Ratio := Tableau (I, Cols) / Tableau (I, Pivot_Col);
                  if not Found or else Ratio < Min_Ratio_Val then
                     Min_Ratio_Val := Ratio;
                     Pivot_Row := I;
                     Found := True;
                  end if;
               end if;
            end loop;
         end;

         -- If no positive elements in the pivot column, the problem is unbounded.
         if not Found then
            raise Unbounded_Problem;
         end if;

         -- 3. Pivot Operation
         Basis (Pivot_Row) := Pivot_Col;

         declare
            Pivot_Val : constant Value_Type := Tableau (Pivot_Row, Pivot_Col);
         begin
            -- Divide the pivot row by the pivot element to make it 1
            for J in 1 .. Cols loop
               Tableau (Pivot_Row, J) := Tableau (Pivot_Row, J) / Pivot_Val;
            end loop;

            -- Subtract multiples of the pivot row from all other rows to zero out the pivot column
            for I in 1 .. Rows loop
               if I /= Pivot_Row then
                  declare
                     Factor : constant Value_Type := Tableau (I, Pivot_Col);
                  begin
                     for J in 1 .. Cols loop
                        Tableau (I, J) := Tableau (I, J) - Factor * Tableau (Pivot_Row, J);
                     end loop;
                  end;
               end if;
            end loop;
         end;
      end loop;
   end Solve_Tableau;

   procedure Maximize
     (Objective   : in Vector_Type;
      Constraints : in Matrix_Type;
      Bounds      : in Vector_Type;
      Max_Value   : out Value_Type;
      Solution    : out Vector_Type)
   is
      Num_Vars  : constant Positive := Objective'Length;
      Num_Cons  : constant Positive := Bounds'Length;
      Rows      : constant Positive := Num_Cons + 1;
      Cols      : constant Positive := Num_Vars + Num_Cons + 1;
      Tableau   : Matrix_Type (1 .. Rows, 1 .. Cols) := [others => [others => 0.0]];
      Basis     : Index_Array (1 .. Num_Cons);
   begin
      -- Standard form restricts bounds to non-negative (origin is feasible)
      for B of Bounds loop
         if B < 0.0 then
            raise Infeasible_Problem;
         end if;
      end loop;

      -- Initialize standard Tableau
      for I in 1 .. Num_Cons loop
         for J in 1 .. Num_Vars loop
            Tableau (I, J) := Constraints (Constraints'First (1) + I - 1, Constraints'First (2) + J - 1);
         end loop;
         Tableau (I, Num_Vars + I) := 1.0; -- Add slack variables to make equations
         Tableau (I, Cols) := Bounds (Bounds'First + I - 1);
      end loop;

      -- Setup objective row
      for J in 1 .. Num_Vars loop
         Tableau (Rows, J) := -Objective (Objective'First + J - 1);
      end loop;

      Solve_Tableau (Tableau, Num_Vars, Num_Cons, Basis);

      Max_Value := Tableau (Rows, Cols);

      -- Extract solution for Primal variables from the established Basis
      for J in 1 .. Num_Vars loop
         Solution (Solution'First + J - 1) := 0.0;
      end loop;
      
      for I in 1 .. Num_Cons loop
         if Basis (I) <= Num_Vars then
            declare
               Val : constant Value_Type := Tableau (I, Cols);
            begin
               -- Clamp to 0.0 to discard trivial floating-point drift (e.g., -1.0e-15)
               Solution (Solution'First + Basis (I) - 1) := (if Val < 0.0 then 0.0 else Val);
            end;
         end if;
      end loop;
   end Maximize;

   procedure Minimize
     (Objective   : in Vector_Type;
      Constraints : in Matrix_Type;
      Bounds      : in Vector_Type;
      Min_Value   : out Value_Type;
      Solution    : out Vector_Type)
   is
      Num_Vars : constant Positive := Objective'Length;
      Num_Cons : constant Positive := Bounds'Length;

      -- Create sizes mapping to the Dual problem (Maximize)
      Dual_Vars : constant Positive := Num_Cons;
      Dual_Cons : constant Positive := Num_Vars;
      Rows      : constant Positive := Dual_Cons + 1;
      Cols      : constant Positive := Dual_Vars + Dual_Cons + 1;
      Tableau   : Matrix_Type (1 .. Rows, 1 .. Cols) := [others => [others => 0.0]];
      Basis     : Index_Array (1 .. Dual_Cons);
      pragma Warnings (Off, Basis);
   begin
      -- Standard form minimization implies strictly non-negative objective coefficients.
      for C of Objective loop
         if C < 0.0 then
            raise Infeasible_Problem;
         end if;
      end loop;

      -- Initialize Tableau for the Dual (Transpose of the Primal)
      for I in 1 .. Dual_Cons loop
         for J in 1 .. Dual_Vars loop
            Tableau (I, J) := Constraints (Constraints'First (1) + J - 1, Constraints'First (2) + I - 1);
         end loop;
         Tableau (I, Dual_Vars + I) := 1.0; -- Dual slack variables
         Tableau (I, Cols) := Objective (Objective'First + I - 1);
      end loop;

      -- Setup Dual objective row
      for J in 1 .. Dual_Vars loop
         Tableau (Rows, J) := -Bounds (Bounds'First + J - 1);
      end loop;

      Solve_Tableau (Tableau, Dual_Vars, Dual_Cons, Basis);

      -- Max of Dual is Min of Primal
      Min_Value := Tableau (Rows, Cols);

      -- Extract solution for Primal from the Dual's slack variables in the objective row.
      for J in 1 .. Num_Vars loop
         declare
            Val : constant Value_Type := Tableau (Rows, Dual_Vars + J);
         begin
            Solution (Solution'First + J - 1) := (if Val < 0.0 then 0.0 else Val);
         end;
      end loop;
   end Minimize;

end Operations_Research;
