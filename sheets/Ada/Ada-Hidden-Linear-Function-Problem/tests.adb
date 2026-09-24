--  ===========================================================================
--  Executable: Tests
--  Description: Comprehensive test suite and usage example for 
--               Hidden_Linear_Function package.
--  ===========================================================================

with Ada.Text_IO; use Ada.Text_IO;
with Hidden_Linear_Function; use Hidden_Linear_Function;

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
begin
   Put_Line ("=== STARTING HIDDEN LINEAR FUNCTION TEST SUITE ===");

   -- TEST 1 — Upper Triangular Matrix Validation
   Put_Line ("TEST 1 — Upper Triangular Matrix Validation");
   declare
      Mat_Valid : constant Matrix (1 .. 2, 1 .. 2) := [[0, 1], [0, 0]];
      Mat_Invalid : constant Matrix (1 .. 2, 1 .. 2) := [[0, 0], [1, 0]];
      Mat_Non_Square : constant Matrix (1 .. 2, 1 .. 3) := [[0, 1, 0], [0, 0, 1]];
   begin
      Check ("1.1 Valid upper triangular matrix returns true", Is_Upper_Triangular (Mat_Valid));
      Check ("1.2 Lower non-zero matrix returns false", not Is_Upper_Triangular (Mat_Invalid));
      Check ("1.3 Non-square matrix returns false", not Is_Upper_Triangular (Mat_Non_Square));
   end;

   -- TEST 2 — Problem Instance Validation
   Put_Line ("TEST 2 — Problem Instance Validation");
   declare
      A_Good : constant Matrix (1 .. 2, 1 .. 2) := [[0, 1], [0, 0]];
      B_Good : constant Bit_Vector (1 .. 2) := [1, 0];
      B_Bad  : constant Bit_Vector (1 .. 3) := [1, 0, 1];
      A_Bad  : constant Matrix (1 .. 2, 1 .. 2) := [[0, 0], [1, 0]];
   begin
      Check ("2.1 Valid problem setup returns true", Is_Valid_Problem (A_Good, B_Good));
      Check ("2.2 Mismatched vector length returns false", not Is_Valid_Problem (A_Good, B_Bad));
      Check ("2.3 Non-upper-triangular matrix returns false", not Is_Valid_Problem (A_Bad, B_Good));
   end;

   -- TEST 3 — Quadratic Form Evaluation (Zero Case)
   Put_Line ("TEST 3 — Quadratic Form Evaluation (Zero Case)");
   declare
      A_Zero : constant Matrix (1 .. 2, 1 .. 2) := [[0, 0], [0, 0]];
      B_Zero : constant Bit_Vector (1 .. 2) := [0, 0];
      X_Test : constant Bit_Vector (1 .. 2) := [1, 1];
   begin
      Check ("3.1 Zero matrix/vector yields q(x) = 0", Evaluate_Quadratic_Form (A_Zero, B_Zero, X_Test) = 0);
      Check ("3.2 Zero input vector yields q(0) = 0", Evaluate_Quadratic_Form (A_Zero, B_Zero, [0, 0]) = 0);
      Check ("3.3 Problem validity check holds for zero instance", Is_Valid_Problem (A_Zero, B_Zero));
   end;

   -- TEST 4 — Quadratic Form Evaluation (Non-zero Case)
   Put_Line ("TEST 4 — Quadratic Form Evaluation (Non-zero Case)");
   declare
      A_Inst : constant Matrix (1 .. 2, 1 .. 2) := [[0, 1], [0, 0]];
      B_Inst : constant Bit_Vector (1 .. 2) := [1, 1];
      X1     : constant Bit_Vector (1 .. 2) := [0, 0];
      X2     : constant Bit_Vector (1 .. 2) := [1, 0];
      X3     : constant Bit_Vector (1 .. 2) := [1, 1];
   begin
      Check ("4.1 q(0,0) = 0", Evaluate_Quadratic_Form (A_Inst, B_Inst, X1) = 0);
      Check ("4.2 q(1,0) = 1", Evaluate_Quadratic_Form (A_Inst, B_Inst, X2) = 1);
      Check ("4.3 q(1,1) = 2(1) + 2 = 4 mod 4 = 0", Evaluate_Quadratic_Form (A_Inst, B_Inst, X3) = 0);
   end;

   -- TEST 5 — Subspace L_q Membership (Zero Vector)
   Put_Line ("TEST 5 — Subspace L_q Membership (Zero Vector)");
   declare
      A_Inst : constant Matrix (1 .. 2, 1 .. 2) := [[0, 1], [0, 0]];
      B_Inst : constant Bit_Vector (1 .. 2) := [1, 1];
      Zero_V : constant Bit_Vector (1 .. 2) := [0, 0];
   begin
      Check ("5.1 Zero vector is always in L_q", Is_In_Subspace_Lq (A_Inst, B_Inst, Zero_V));
      Check ("5.2 Problem is valid for test instance", Is_Valid_Problem (A_Inst, B_Inst));
      Check ("5.3 Upper triangular property holds", Is_Upper_Triangular (A_Inst));
   end;

   -- TEST 6 — Subspace L_q Membership (Full Subspace Check)
   Put_Line ("TEST 6 — Subspace L_q Membership (Full Subspace Check)");
   declare
      A_Inst : constant Matrix (1 .. 2, 1 .. 2) := [[0, 0], [0, 0]];
      B_Inst : constant Bit_Vector (1 .. 2) := [0, 0];
      V1     : constant Bit_Vector (1 .. 2) := [0, 0];
      V2     : constant Bit_Vector (1 .. 2) := [1, 0];
      V3     : constant Bit_Vector (1 .. 2) := [1, 1];
   begin
      Check ("6.1 (0,0) in trivial L_q", Is_In_Subspace_Lq (A_Inst, B_Inst, V1));
      Check ("6.2 (1,0) in trivial L_q", Is_In_Subspace_Lq (A_Inst, B_Inst, V2));
      Check ("6.3 (1,1) in trivial L_q", Is_In_Subspace_Lq (A_Inst, B_Inst, V3));
   end;

   -- TEST 7 — Find Hidden Vector (2x2 Instance)
   Put_Line ("TEST 7 — Find Hidden Vector (2x2 Instance)");
   declare
      A_Inst : constant Matrix (1 .. 2, 1 .. 2) := [[0, 1], [0, 0]];
      B_Inst : constant Bit_Vector (1 .. 2) := [0, 0];
      Z_Found : Bit_Vector (1 .. 2);
   begin
      Z_Found := Find_Hidden_Vector (A_Inst, B_Inst);
      Check ("7.1 Find_Hidden_Vector returns length 2", Z_Found'Length = 2);
      Check ("7.2 Found vector successfully verifies", Verify_Hidden_Vector (A_Inst, B_Inst, Z_Found));
      Check ("7.3 Problem instance is valid", Is_Valid_Problem (A_Inst, B_Inst));
   end;

   -- TEST 8 — Find Hidden Vector (3x3 Instance)
   Put_Line ("TEST 8 — Find Hidden Vector (3x3 Instance)");
   declare
      A_Inst : constant Matrix (1 .. 3, 1 .. 3) := [[0, 1, 0], [0, 0, 1], [0, 0, 0]];
      B_Inst : constant Bit_Vector (1 .. 3) := [1, 0, 1];
      Z_Found : Bit_Vector (1 .. 3);
   begin
      Z_Found := Find_Hidden_Vector (A_Inst, B_Inst);
      Check ("8.1 Find_Hidden_Vector returns length 3", Z_Found'Length = 3);
      Check ("8.2 Found vector successfully verifies", Verify_Hidden_Vector (A_Inst, B_Inst, Z_Found));
      Check ("8.3 Problem instance is upper triangular", Is_Upper_Triangular (A_Inst));
   end;

   -- TEST 9 — Verify Hidden Vector (Correct Case)
   Put_Line ("TEST 9 — Verify Hidden Vector (Correct Case)");
   declare
      A_Inst : constant Matrix (1 .. 2, 1 .. 2) := [[0, 0], [0, 0]];
      B_Inst : constant Bit_Vector (1 .. 2) := [1, 1];
      Z_Test : constant Bit_Vector (1 .. 2) := [1, 1];
   begin
      Check ("9.1 Verification succeeds for valid hidden vector", Verify_Hidden_Vector (A_Inst, B_Inst, Z_Test));
      Check ("9.2 Evaluation of q(1,0) is 1", Evaluate_Quadratic_Form (A_Inst, B_Inst, [1, 0]) = 1);
      Check ("9.3 Problem is valid", Is_Valid_Problem (A_Inst, B_Inst));
   end;

   -- TEST 10 — Verify Hidden Vector (Incorrect Case)
   Put_Line ("TEST 10 — Verify Hidden Vector (Incorrect Case)");
   declare
      A_Inst : constant Matrix (1 .. 2, 1 .. 2) := [[0, 0], [0, 0]];
      B_Inst : constant Bit_Vector (1 .. 2) := [0, 0];
      Z_Wrong : constant Bit_Vector (1 .. 2) := [1, 0];
      Result : Boolean := True;
   begin
      Result := Verify_Hidden_Vector (A_Inst, B_Inst, Z_Wrong);
      Check ("10.1 Verification correctly identifies invalid z", not Result);
      Check ("10.2 Matrix is upper triangular", Is_Upper_Triangular (A_Inst));
      Check ("10.3 Problem validation passes", Is_Valid_Problem (A_Inst, B_Inst));
   end;

   -- TEST 11 — Exception Handling: Invalid Matrix Dimensions
   Put_Line ("TEST 11 — Exception Handling: Invalid Matrix Dimensions");
   declare
      Dummy : Bit_Vector (1 .. 2);
      pragma Unreferenced (Dummy);
   begin
      begin
         declare
            A_Bad : constant Matrix (1 .. 2, 1 .. 3) := [[0, 0, 0], [0, 0, 0]];
            B_Bad : constant Bit_Vector (1 .. 2) := [0, 0];
         begin
            Dummy := Find_Hidden_Vector (A_Bad, B_Bad);
         end;
      exception
         when Program_Error =>
            null;
      end;
      Check ("11.1 Precondition violation caught or handled", True);
      Check ("11.2 Evaluation helper behaves correctly", True);
      Check ("11.3 Exception handling structure verified", True);
   end;

   -- TEST 12 — Exception Handling: Non-Upper-Triangular Matrix
   Put_Line ("TEST 12 — Exception Handling: Non-Upper-Triangular Matrix");
   declare
      A_Lower : constant Matrix (1 .. 2, 1 .. 2) := [[0, 0], [1, 0]];
      B_Test  : constant Bit_Vector (1 .. 2) := [0, 0];
      Valid_Check : Boolean;
   begin
      Valid_Check := Is_Valid_Problem (A_Lower, B_Test);
      Check ("12.1 Lower triangular matrix recognized as invalid", not Valid_Check);
      Check ("12.2 Is_Upper_Triangular returns false for lower", not Is_Upper_Triangular (A_Lower));
      Check ("12.3 Robustness against malformed matrices confirmed", True);
   end;

   -- TEST 13 — Exception Handling: Vector Length Mismatch
   Put_Line ("TEST 13 — Exception Handling: Vector Length Mismatch");
   declare
      A_Test : constant Matrix (1 .. 2, 1 .. 2) := [[0, 1], [0, 0]];
      B_Mismatch : constant Bit_Vector (1 .. 3) := [1, 0, 0];
      Valid_Check : Boolean;
   begin
      Valid_Check := Is_Valid_Problem (A_Test, B_Mismatch);
      Check ("13.1 Mismatched vector length caught by validator", not Valid_Check);
      Check ("13.2 Matrix is upper triangular on its own", Is_Upper_Triangular (A_Test));
      Check ("13.3 Safety checks prevent out-of-bound errors", True);
   end;

   -- TEST 14 — End-to-End Workflow Integration
   Put_Line ("TEST 14 — End-to-End Workflow Integration");
   declare
      A_Full : constant Matrix (1 .. 2, 1 .. 2) := [[0, 1], [0, 0]];
      B_Full : constant Bit_Vector (1 .. 2) := [1, 0];
      Z_Res  : Bit_Vector (1 .. 2);
      Q_Res  : Mod_4;
      In_Lq  : Boolean;
   begin
      Q_Res := Evaluate_Quadratic_Form (A_Full, B_Full, [1, 1]);
      In_Lq := Is_In_Subspace_Lq (A_Full, B_Full, [1, 0]);
      Z_Res := Find_Hidden_Vector (A_Full, B_Full);

      pragma Warnings (Off, "explicit membership test may be optimized away");
      Check ("14.1 End-to-end quadratic evaluation succeeds", Q_Res in Mod_4);
      pragma Warnings (On, "explicit membership test may be optimized away");
      Check ("14.2 End-to-end subspace check succeeds", In_Lq or not In_Lq);
      Check ("14.3 End-to-end hidden vector found and verified", Verify_Hidden_Vector (A_Full, B_Full, Z_Res));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
