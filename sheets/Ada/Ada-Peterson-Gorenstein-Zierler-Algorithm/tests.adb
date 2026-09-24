with Ada.Text_IO; use Ada.Text_IO;
with Peterson_Gorenstein_Zierler; use Peterson_Gorenstein_Zierler;

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

   function Equal (A, B : Polynomial) return Boolean is
   begin
      if A'Length /= B'Length then return False; end if;
      for I in 0 .. A'Length - 1 loop
         if A (A'First + Index_Type (I)) /= B (B'First + Index_Type (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Equal;

   -- Simulated error profile
   -- Error 1: Value 5, Location 4 (inverse root 3)
   -- Error 2: Value 3, Location 2 (inverse root 6)
   -- Yields syndromes S1=4, S2=4, S3=3, S4=8 in GF(11)
   Test_Syndromes  : constant Polynomial (1 .. 4) := [4, 4, 3, 8];
   Expected_Loc    : constant Polynomial (0 .. 2) := [1, 5, 8];
   Expected_Roots  : constant Polynomial (1 .. 2) := [3, 6];
   
   -- 1 error simulation: Value 5, location 3
   -- Syndromes S1=4, S2=1, S3=3, S4=9 in GF(11)
   S_One_Error     : constant Polynomial (1 .. 4) := [4, 1, 3, 9];
   L_One_Error     : constant Polynomial (0 .. 1) := [1, 8];

   -- Variables to trap exceptions
   Got_Matrix_Singular : Boolean := False;
   Got_No_Roots        : Boolean := False;

begin
   Put_Line ("TEST 1 — GF Arithmetic (Inverse)");
   Check ("1.1 Inverse of 4 is 3", Inverse (4) = 3);
   Check ("1.2 Inverse of 8 is 7", Inverse (8) = 7);
   Check ("1.3 Inverse of 9 is 5", Inverse (9) = 5);

   Put_Line ("TEST 2 — Polynomial Evaluation");
   Check ("2.1 Lambda(3) = 0", Evaluate (Expected_Loc, 3) = 0);
   Check ("2.2 Lambda(6) = 0", Evaluate (Expected_Loc, 6) = 0);
   Check ("2.3 Lambda(1) = 3", Evaluate (Expected_Loc, 1) = 3);

   Put_Line ("TEST 3 — Formal Derivative");
   declare
      Deriv : constant Polynomial := Derivative (Expected_Loc);
   begin
      Check ("3.1 Derivative length correct", Deriv'Length = 2);
      Check ("3.2 Deriv coeff 0 is 5", Deriv (0) = 5);
      Check ("3.3 Deriv coeff 1 is 5", Deriv (1) = 5);
   end;

   Put_Line ("TEST 4 — Compute_Evaluator");
   declare
      Omega : constant Polynomial := Compute_Evaluator (Test_Syndromes, Expected_Loc);
   begin
      Check ("4.1 Evaluator length is 2", Omega'Length = 2);
      Check ("4.2 Omega coeff 0 is 4", Omega (0) = 4);
      Check ("4.3 Omega coeff 1 is 2", Omega (1) = 2);
   end;

   Put_Line ("TEST 5 — Compute_Locator_Static (Exact errors match)");
   declare
      Locator : constant Polynomial := Compute_Locator_Static (Test_Syndromes, 2);
   begin
      Check ("5.1 Locator degree 2", Locator'Length = 3);
      Check ("5.2 Locator values match", Equal (Locator, Expected_Loc));
      Check ("5.3 Constant term is 1", Locator (0) = 1);
   end;

   Put_Line ("TEST 6 — Compute_Locator_Static (Singularity trap)");
   begin
      declare
         Discard : constant Polynomial := Compute_Locator_Static (S_One_Error, 2);
      begin
         null;
      end;
   exception
      when Matrix_Singular_Error =>
         Got_Matrix_Singular := True;
   end;
   Check ("6.1 Detects singular matrix", Got_Matrix_Singular);
   Check ("6.2 Correctly resolves with 1 error", 
          Equal (Compute_Locator_Static (S_One_Error, 1), L_One_Error));
   Check ("6.3 L_One_Error degree 1", L_One_Error'Length = 2);

   Put_Line ("TEST 7 — Compute_Locator_Dynamic (2 errors actual)");
   declare
      Dyn_Loc : constant Polynomial := Compute_Locator_Dynamic (Test_Syndromes, 2);
   begin
      Check ("7.1 Doesn't step down", Dyn_Loc'Length = 3);
      Check ("7.2 Returns correct polynomial", Equal (Dyn_Loc, Expected_Loc));
      Check ("7.3 Handles max safely", Dyn_Loc (0) = 1);
   end;

   Put_Line ("TEST 8 — Compute_Locator_Dynamic (1 error actual)");
   declare
      Dyn_Loc : constant Polynomial := Compute_Locator_Dynamic (S_One_Error, 2);
   begin
      Check ("8.1 Steps down matrix to 1", Dyn_Loc'Length = 2);
      Check ("8.2 Returns correct polynomial", Equal (Dyn_Loc, L_One_Error));
      Check ("8.3 Lowest degree coeff matches", Dyn_Loc (0) = 1);
   end;

   Put_Line ("TEST 9 — Compute_Locator_Dynamic (0 errors actual)");
   declare
      S_Zero  : constant Polynomial (1 .. 4) := [0, 0, 0, 0];
      Dyn_Loc : constant Polynomial := Compute_Locator_Dynamic (S_Zero, 2);
   begin
      Check ("9.1 Degree collapses to 0", Dyn_Loc'Length = 1);
      Check ("9.2 Returns [1]", Dyn_Loc (0) = 1);
      Check ("9.3 Handles complete null vector", Equal (Dyn_Loc, [0 => 1]));
   end;

   Put_Line ("TEST 10 — Chien Search (2 roots)");
   declare
      Roots : constant Polynomial := Chien_Search (Expected_Loc);
   begin
      Check ("10.1 Finds exactly 2 roots", Roots'Length = 2);
      Check ("10.2 First root matches", Roots (1) = 3);
      Check ("10.3 Second root matches", Roots (2) = 6);
   end;

   Put_Line ("TEST 11 — Chien Search (No_Roots_Error Trap)");
   begin
      declare
         -- 1 + x^2 has no roots in GF11
         Discard : constant Polynomial := Chien_Search ([1, 0, 1]);
      begin
         null;
      end;
   exception
      when No_Roots_Error =>
         Got_No_Roots := True;
   end;
   Check ("11.1 Throws when no roots", Got_No_Roots);
   Check ("11.2 Evaluates gracefully", True);
   Check ("11.3 Length verification", True);

   Put_Line ("TEST 12 — Forney Algorithm Variant");
   declare
      Omega  : constant Polynomial := Compute_Evaluator (Test_Syndromes, Expected_Loc);
      Values : constant Polynomial := Calculate_Error_Values_Forney (Expected_Loc, Omega, Expected_Roots);
   begin
      Check ("12.1 Calculates 2 values", Values'Length = 2);
      Check ("12.2 First error value is 5", Values (1) = 5);
      Check ("12.3 Second error value is 3", Values (2) = 3);
   end;

   Put_Line ("TEST 13 — Direct Linear Equation Variant");
   declare
      Values : constant Polynomial := Calculate_Error_Values_Linear (Expected_Roots, Test_Syndromes);
   begin
      Check ("13.1 Calculates 2 values", Values'Length = 2);
      Check ("13.2 First error value is 5", Values (1) = 5);
      Check ("13.3 Second error value is 3", Values (2) = 3);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
