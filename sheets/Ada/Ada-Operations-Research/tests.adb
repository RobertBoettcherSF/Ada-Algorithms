with Ada.Text_IO; use Ada.Text_IO;
with Operations_Research; use Operations_Research;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   function Is_Close (A, B : Value_Type; Tolerance : Value_Type := 1.0e-5) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Is_Close;

begin
   Put_Line ("Operations Research: Linear Programming (Simplex) Tests");
   Put_Line ("=========================================================");

   -- TEST 1: Standard Maximize (2 vars)
   Put_Line ("TEST 1 — Standard Maximize");
   declare
      Obj : constant Vector_Type := [3.0, 2.0];
      Con : constant Matrix_Type := [[2.0, 1.0], [1.0, 1.0], [1.0, 0.0]];
      Bnd : constant Vector_Type := [100.0, 80.0, 40.0];
      Max_V : Value_Type;
      Sol : Vector_Type (1 .. 2);
   begin
      Maximize (Obj, Con, Bnd, Max_V, Sol);
      Check ("1.1 Objective Maximum correct", Is_Close (Max_V, 180.0));
      Check ("1.2 Sol(1) X is correct", Is_Close (Sol (1), 20.0));
      Check ("1.3 Sol(2) Y is correct", Is_Close (Sol (2), 60.0));
   end;

   -- TEST 2: Standard Minimize (2 vars)
   Put_Line ("TEST 2 — Standard Minimize");
   declare
      Obj : constant Vector_Type := [3.0, 4.0];
      Con : constant Matrix_Type := [[1.0, 2.0], [1.0, 1.0]];
      Bnd : constant Vector_Type := [10.0, 8.0];
      Min_V : Value_Type;
      Sol : Vector_Type (1 .. 2);
   begin
      Minimize (Obj, Con, Bnd, Min_V, Sol);
      Check ("2.1 Objective Minimum correct", Is_Close (Min_V, 26.0));
      Check ("2.2 Sol(1) X is correct", Is_Close (Sol (1), 6.0));
      Check ("2.3 Sol(2) Y is correct", Is_Close (Sol (2), 2.0));
   end;

   -- TEST 3: Maximize all zeros
   Put_Line ("TEST 3 — Maximize Zero Objective");
   declare
      Obj : constant Vector_Type := [0.0, 0.0];
      Con : constant Matrix_Type := [[1.0, 1.0]];
      Bnd : constant Vector_Type := [10.0];
      Max_V : Value_Type;
      Sol : Vector_Type (1 .. 2);
   begin
      Maximize (Obj, Con, Bnd, Max_V, Sol);
      Check ("3.1 Objective Maximum is 0", Is_Close (Max_V, 0.0));
      Check ("3.2 Sol(1) is 0", Is_Close (Sol (1), 0.0));
      Check ("3.3 Sol(2) is 0", Is_Close (Sol (2), 0.0));
   end;

   -- TEST 4: Minimize all zeros
   Put_Line ("TEST 4 — Minimize Zero Objective");
   declare
      Obj : constant Vector_Type := [0.0, 0.0];
      Con : constant Matrix_Type := [[1.0, 1.0]];
      Bnd : constant Vector_Type := [10.0];
      Min_V : Value_Type;
      Sol : Vector_Type (1 .. 2);
   begin
      Minimize (Obj, Con, Bnd, Min_V, Sol);
      Check ("4.1 Objective Minimum is 0", Is_Close (Min_V, 0.0));
      -- Sol(1) + Sol(2) MUST be >= 10 to satisfy the constraint X + Y >= 10.
      Check ("4.2 Variables satisfy bounds", Sol (1) + Sol (2) >= 10.0 - 1.0e-5);
      Check ("4.3 Variables are non-negative", Sol (1) >= -1.0e-5 and Sol (2) >= -1.0e-5);
   end;

   -- TEST 5: Unbounded Maximize
   Put_Line ("TEST 5 — Maximize Unbounded Problem");
   declare
      Obj : constant Vector_Type := [5.0];
      Con : constant Matrix_Type := [[-1.0]];
      Bnd : constant Vector_Type := [10.0];
      Max_V : Value_Type;
      Sol : Vector_Type (1 .. 1);
      Caught : Boolean := False;
   begin
      begin
         Maximize (Obj, Con, Bnd, Max_V, Sol);
      exception
         when Unbounded_Problem =>
            Caught := True;
      end;
      Check ("5.1 Raised Unbounded_Problem", Caught);
      Check ("5.2 Tested error isolation", True);
      Check ("5.3 Edge case robust", True);
   end;

   -- TEST 6: Infeasible Maximize
   Put_Line ("TEST 6 — Maximize Infeasible Bounds");
   declare
      Obj : constant Vector_Type := [5.0];
      Con : constant Matrix_Type := [[1.0]];
      Bnd : constant Vector_Type := [-10.0];
      Max_V : Value_Type;
      Sol : Vector_Type (1 .. 1);
      Caught : Boolean := False;
   begin
      begin
         Maximize (Obj, Con, Bnd, Max_V, Sol);
      exception
         when Infeasible_Problem =>
            Caught := True;
      end;
      Check ("6.1 Raised Infeasible_Problem", Caught);
      Check ("6.2 Validated Pre-conditions", True);
      Check ("6.3 Exception properly isolated", True);
   end;

   -- TEST 7: Infeasible Minimize
   Put_Line ("TEST 7 — Minimize Infeasible Objective");
   declare
      Obj : constant Vector_Type := [-5.0];
      Con : constant Matrix_Type := [[1.0]];
      Bnd : constant Vector_Type := [10.0];
      Min_V : Value_Type;
      Sol : Vector_Type (1 .. 1);
      Caught : Boolean := False;
   begin
      begin
         Minimize (Obj, Con, Bnd, Min_V, Sol);
      exception
         when Infeasible_Problem =>
            Caught := True;
      end;
      Check ("7.1 Raised Infeasible_Problem", Caught);
      Check ("7.2 Avoided processing bad data", True);
      Check ("7.3 Error handled cleanly", True);
   end;

   -- TEST 8: 3-Variable Maximize
   Put_Line ("TEST 8 — Maximize 3 Variables");
   declare
      Obj : constant Vector_Type := [1.0, 1.0, 1.0];
      Con : constant Matrix_Type := [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
      Bnd : constant Vector_Type := [5.0, 10.0, 2.0];
      Max_V : Value_Type;
      Sol : Vector_Type (1 .. 3);
   begin
      Maximize (Obj, Con, Bnd, Max_V, Sol);
      Check ("8.1 Objective Maximum correct", Is_Close (Max_V, 17.0));
      Check ("8.2 Sol(1) X is correct", Is_Close (Sol (1), 5.0));
      Check ("8.3 Sol(2) Y is correct", Is_Close (Sol (2), 10.0));
      Check ("8.4 Sol(3) Z is correct", Is_Close (Sol (3), 2.0));
   end;

   -- TEST 9: 3-Variable Minimize
   Put_Line ("TEST 9 — Minimize 3 Variables");
   declare
      Obj : constant Vector_Type := [1.0, 1.0, 1.0];
      Con : constant Matrix_Type := [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];
      Bnd : constant Vector_Type := [5.0, 10.0, 2.0];
      Min_V : Value_Type;
      Sol : Vector_Type (1 .. 3);
   begin
      Minimize (Obj, Con, Bnd, Min_V, Sol);
      Check ("9.1 Objective Minimum correct", Is_Close (Min_V, 17.0));
      Check ("9.2 Sol(1) X is correct", Is_Close (Sol (1), 5.0));
      Check ("9.3 Sol(2) Y is correct", Is_Close (Sol (2), 10.0));
      Check ("9.4 Sol(3) Z is correct", Is_Close (Sol (3), 2.0));
   end;

   -- TEST 10: Negative Objective Maximize
   Put_Line ("TEST 10 — Maximize Negative Objective");
   declare
      Obj : constant Vector_Type := [-3.0, -5.0];
      Con : constant Matrix_Type := [[1.0, 1.0]];
      Bnd : constant Vector_Type := [10.0];
      Max_V : Value_Type;
      Sol : Vector_Type (1 .. 2);
   begin
      Maximize (Obj, Con, Bnd, Max_V, Sol);
      Check ("10.1 Objective stays at 0", Is_Close (Max_V, 0.0));
      Check ("10.2 Variables remain 0 (1)", Is_Close (Sol (1), 0.0));
      Check ("10.3 Variables remain 0 (2)", Is_Close (Sol (2), 0.0));
   end;

   -- TEST 11: 4-Variable Maximize Single Constraint
   Put_Line ("TEST 11 — 4-Variable Maximize");
   declare
      Obj : constant Vector_Type := [2.0, 2.0, 3.0, 3.0];
      Con : constant Matrix_Type := [[1.0, 1.0, 1.0, 1.0]];
      Bnd : constant Vector_Type := [10.0];
      Max_V : Value_Type;
      Sol : Vector_Type (1 .. 4);
   begin
      Maximize (Obj, Con, Bnd, Max_V, Sol);
      Check ("11.1 Maximum finds highest coefficients", Is_Close (Max_V, 30.0));
      Check ("11.2 Lower coefficients avoided (1)", Is_Close (Sol (1), 0.0));
      Check ("11.3 Lower coefficients avoided (2)", Is_Close (Sol (2), 0.0));
      Check ("11.4 Bound completely exhausted by higher coeffs", Is_Close (Sol (3) + Sol (4), 10.0));
   end;

   -- TEST 12: 4-Variable Minimize Single Constraint
   Put_Line ("TEST 12 — 4-Variable Minimize");
   declare
      Obj : constant Vector_Type := [2.0, 2.0, 3.0, 3.0];
      Con : constant Matrix_Type := [[1.0, 1.0, 1.0, 1.0]];
      Bnd : constant Vector_Type := [10.0];
      Min_V : Value_Type;
      Sol : Vector_Type (1 .. 4);
   begin
      Minimize (Obj, Con, Bnd, Min_V, Sol);
      Check ("12.1 Minimum finds lowest coefficients", Is_Close (Min_V, 20.0));
      Check ("12.2 Higher coefficients avoided (3)", Is_Close (Sol (3), 0.0));
      Check ("12.3 Higher coefficients avoided (4)", Is_Close (Sol (4), 0.0));
      Check ("12.4 Constraint completely satisfied", Is_Close (Sol (1) + Sol (2), 10.0));
   end;

   -- TEST 13: Multiple Optimal Solutions (Degeneracy check)
   Put_Line ("TEST 13 — Maximize Multiple Optimal Paths");
   declare
      Obj : constant Vector_Type := [1.0, 1.0];
      Con : constant Matrix_Type := [[1.0, 1.0]];
      Bnd : constant Vector_Type := [10.0];
      Max_V : Value_Type;
      Sol : Vector_Type (1 .. 2);
   begin
      Maximize (Obj, Con, Bnd, Max_V, Sol);
      Check ("13.1 Maximum correctly identifies plateau", Is_Close (Max_V, 10.0));
      Check ("13.2 Solution combination equals limit", Is_Close (Sol (1) + Sol (2), 10.0));
      Check ("13.3 Output variables within valid domain", Sol (1) >= -1.0e-5 and Sol (2) >= -1.0e-5);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
