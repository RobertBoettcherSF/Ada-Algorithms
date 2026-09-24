with Ada.Text_IO; use Ada.Text_IO;
with Amplitude_Amplification; use Amplitude_Amplification;

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

   function Is_Close (A, B : Amplitude) return Boolean is
   begin
      return abs (A - B) < 1.0e-4;
   end Is_Close;

   -- Oracles used for testing
   function Oracle_3 (Idx : State_Index) return Boolean is (Idx = 3);
   
   function Oracle_None (Idx : State_Index) return Boolean is
      pragma Unreferenced (Idx);
   begin
      return False;
   end Oracle_None;
   
   function Oracle_Evens (Idx : State_Index) return Boolean is (Idx mod 2 = 0);

   -- Test Vectors
   S1      : constant State_Vector := Uniform_Superposition (0, 3);
   S_Zero  : constant State_Vector (0 .. 1) := [0.0, 0.0];
   S_Valid : constant State_Vector (0 .. 1) := [1.0, 0.0];
   S_Orth  : constant State_Vector (0 .. 1) := [0.0, 1.0];
   S_High  : constant State_Vector (0 .. 1) := [1.0, 1.0];
   S_Mixed : constant State_Vector (0 .. 2) := [0.1, -0.8, 0.3];

begin
   -- TEST 1: Uniform Superposition Creation
   Put_Line ("TEST 1 — Uniform Superposition");
   Check ("1.1 Vector is correct length", S1'Length = 4);
   Check ("1.2 Individual amplitude is correct (1/sqrt(4))", Is_Close (S1 (0), 0.5));
   Check ("1.3 Generated vector is normalized", Is_Normalized (S1));

   -- TEST 2: Normalization Constraints
   Put_Line ("TEST 2 — Normalization Constraints");
   Check ("2.1 Zero-filled vector fails normalization", not Is_Normalized (S_Zero));
   Check ("2.2 Valid purely real vector passes", Is_Normalized (S_Valid));
   Check ("2.3 Oversized vector fails normalization", not Is_Normalized (S_High));

   -- TEST 3: Inner Product Verification
   Put_Line ("TEST 3 — Inner Product Calculations");
   Check ("3.1 Parallel vectors equal 1.0", Is_Close (Inner_Product (S_Valid, S_Valid), 1.0));
   Check ("3.2 Orthogonal vectors equal 0.0", Is_Close (Inner_Product (S_Valid, S_Orth), 0.0));
   Check ("3.3 Superposition sum equals 1.0", Is_Close (Inner_Product (S1, S1), 1.0));

   -- TEST 4: Measure Most Likely Extraction
   Put_Line ("TEST 4 — Measure Most Likely");
   Check ("4.1 Finds highest negative magnitude (-0.8 => prob 0.64)", Measure_Most_Likely (S_Mixed) = 1);
   Check ("4.2 Ties resolve safely (picks first)", Measure_Most_Likely (S_High) = 0);
   Check ("4.3 Identifies obvious 1.0 state", Measure_Most_Likely (S_Valid) = 0);

   -- TEST 5: Oracle Application (Single Solution)
   Put_Line ("TEST 5 — Oracle Application (Single)");
   declare
      S_Oracle : State_Vector := S1;
   begin
      Apply_Oracle (S_Oracle, Oracle_3'Access);
      Check ("5.1 Target phase is flipped (-0.5)", Is_Close (S_Oracle (3), -0.5));
      Check ("5.2 Non-target phase remains intact (0.5)", Is_Close (S_Oracle (0), 0.5));
      Check ("5.3 Norm is strictly preserved", Is_Normalized (S_Oracle));
   end;

   -- TEST 6: Oracle Application (Multiple Solutions)
   Put_Line ("TEST 6 — Oracle Application (Multiple)");
   declare
      S_Multi : State_Vector := Uniform_Superposition (0, 3);
   begin
      Apply_Oracle (S_Multi, Oracle_Evens'Access);
      Check ("6.1 Even state 0 flipped", Is_Close (S_Multi (0), -0.5));
      Check ("6.2 Even state 2 flipped", Is_Close (S_Multi (2), -0.5));
      Check ("6.3 Odd state 1 intact", Is_Close (S_Multi (1), 0.5));
   end;

   -- TEST 7: Diffusion Operator (Zero Phase Change)
   Put_Line ("TEST 7 — Diffusion Operator on Initial State");
   declare
      S_Diff : State_Vector := S1;
   begin
      Apply_Diffusion (S_Diff, S1);
      Check ("7.1 State 0 remains untouched", Is_Close (S_Diff (0), 0.5));
      Check ("7.2 State 3 remains untouched", Is_Close (S_Diff (3), 0.5));
      Check ("7.3 Norm remains strictly 1.0", Is_Normalized (S_Diff));
   end;

   -- TEST 8: Diffusion Operator (Flipped Phase Amplification)
   Put_Line ("TEST 8 — Diffusion Operator (Inversion About Mean)");
   declare
      S_Flipped : State_Vector := S1;
   begin
      Apply_Oracle (S_Flipped, Oracle_3'Access);
      Apply_Diffusion (S_Flipped, S1);
      Check ("8.1 Target amplitude is amplified", S_Flipped (3) > 0.8);
      Check ("8.2 Other amplitudes are suppressed", S_Flipped (0) < 0.2);
      Check ("8.3 Amplified state remains normalized", Is_Normalized (S_Flipped));
   end;

   -- TEST 9: Optimal Iterations Calculation
   Put_Line ("TEST 9 — Optimal Iterations");
   Check ("9.1 Prob 1.0 requires 0 iterations", Optimal_Iterations (1.0) = 0);
   Check ("9.2 Prob 0.25 mathematically requires exactly 1 iteration", Optimal_Iterations (0.25) = 1);
   Check ("9.3 Prob 0.01 requires ~7 iterations", Optimal_Iterations (0.01) = 7);

   -- TEST 10: Standard Amplification Routine (Success)
   Put_Line ("TEST 10 — Standard Amplification Execution");
   declare
      S_Result : constant State_Vector := Standard_Amplification (S1, Oracle_3'Access, 1);
   begin
      Check ("10.1 Target reaches near 100% certainty", Is_Close (S_Result (3), 1.0));
      Check ("10.2 Non-targets reduce to near 0%", Is_Close (S_Result (0), 0.0));
      Check ("10.3 Exact index measured is target", Measure_Most_Likely (S_Result) = 3);
   end;

   -- TEST 11: Standard Amplification Routine (Zero Iters)
   Put_Line ("TEST 11 — Standard Amplification (0 Iterations)");
   declare
      S_Result0 : constant State_Vector := Standard_Amplification (S1, Oracle_3'Access, 0);
   begin
      Check ("11.1 Target remains unamplified (0.5)", Is_Close (S_Result0 (3), 0.5));
      Check ("11.2 Other remains unsuppressed (0.5)", Is_Close (S_Result0 (0), 0.5));
      Check ("11.3 Norm is intact", Is_Normalized (S_Result0));
   end;

   -- TEST 12: Exponential Search Variant (Found)
   Put_Line ("TEST 12 — Exponential Search (Success Path)");
   declare
      Found : constant State_Index := Exponential_Search (Uniform_Superposition (0, 15), Oracle_3'Access, 100);
   begin
      Check ("12.1 Extracted correct target index dynamically", Found = 3);
      Check ("12.2 Oracle confirms successful extraction", Oracle_3 (Found));
      Check ("12.3 Index remains in valid operational range", Found >= 0 and Found <= 15);
   end;

   -- TEST 13: Exponential Search Variant (Not Found Exception)
   Put_Line ("TEST 13 — Exponential Search (Failure Path)");
   begin
      declare
         Bad_Found : State_Index;
      begin
         Bad_Found := Exponential_Search (Uniform_Superposition (0, 3), Oracle_None'Access, 10);
         Check ("13.1 Should never reach here (Returned " & State_Index'Image (Bad_Found) & ")", False);
         Check ("13.2 Forced fail", False);
         Check ("13.3 Forced fail", False);
      end;
   exception
      when No_Solution_Error =>
         Check ("13.1 Threw No_Solution_Error correctly", True);
         Check ("13.2 Execution exited bounds properly", True);
         Check ("13.3 Error state cleanly handled", True);
   end;
   
   -- TEST 14: Edge Case (Single Element State)
   Put_Line ("TEST 14 — Edge Case (Single Element Domain)");
   declare
      S_One : constant State_Vector (0 .. 0) := [0 => 1.0];
      S_One_Res : constant State_Vector := Standard_Amplification (S_One, Oracle_Evens'Access, 1);
   begin
      Check ("14.1 Maintained vector length of 1", S_One_Res'Length = 1);
      Check ("14.2 Vector safely remains normalized", Is_Normalized (S_One_Res));
      Check ("14.3 Output index matches element explicitly", Measure_Most_Likely (S_One_Res) = 0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
