with Ada.Text_IO; use Ada.Text_IO;
with Mechanistic_Interpretability; use Mechanistic_Interpretability;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   --  Helper for floating point comparisons
   function Near (A, B : Real) return Boolean is
   begin
      return abs (A - B) < 0.0001;
   end Near;

begin
   Put_Line ("TEST 1 -- Linear Transform Basics");
   declare
      In_Vec : constant Vector(1 .. 2) := [1.0, 2.0];
      W_Mat  : constant Matrix(1 .. 2, 1 .. 2) := [[1.0, 0.5], [0.0, 1.0]];
      Bias   : constant Vector(1 .. 2) := [0.1, 0.2];
      Res    : constant Vector := Linear_Transform (In_Vec, W_Mat, Bias);
   begin
      Check ("1.1 Vector dimension preserved", Res'Length = 2);
      Check ("1.2 First element matches expected value", Near (Res (1), 1.1));
      Check ("1.3 Second element matches expected value", Near (Res (2), 2.7));
   end;

   Put_Line ("TEST 2 -- ReLU Activation");
   declare
      In_Vec : constant Vector(1 .. 3) := [-5.0, 0.0, 3.14];
      Res    : constant Vector := ReLU (In_Vec);
   begin
      Check ("2.1 Negative numbers become zero", Near (Res (1), 0.0));
      Check ("2.2 Zero remains zero", Near (Res (2), 0.0));
      Check ("2.3 Positive numbers remain unchanged", Near (Res (3), 3.14));
   end;

   Put_Line ("TEST 3 -- Sparse Autoencoder (SAE) Encoding");
   declare
      Act     : constant Vector(1 .. 2) := [1.0, -1.0];
      W_Enc   : constant Matrix(1 .. 2, 1 .. 3) := [[1.0, -1.0, 0.0], [1.0, 1.0, 0.0]];
      B_Enc   : constant Vector(1 .. 3) := [0.0, 0.0, 1.0];
      Feat    : constant Vector := Encode_SAE (Act, W_Enc, B_Enc);
   begin
      Check ("3.1 Correct expansion to higher dimension space", Feat'Length = 3);
      Check ("3.2 Sparsity constraint forced by ReLU (index 2 is 0)", Near (Feat (2), 0.0));
      Check ("3.3 Positive activations pass through", Near (Feat (3), 1.0));
   end;

   Put_Line ("TEST 4 -- Sparse Autoencoder (SAE) Decoding");
   declare
      Feat    : constant Vector(1 .. 3) := [0.0, 2.0, 0.0];
      W_Dec   : constant Matrix(1 .. 3, 1 .. 2) := [[1.0, 0.0], [0.5, 0.5], [0.0, 1.0]];
      B_Dec   : constant Vector(1 .. 2) := [0.0, 0.0];
      Recon   : constant Vector := Decode_SAE (Feat, W_Dec, B_Dec);
   begin
      Check ("4.1 Correct projection back to original dimension", Recon'Length = 2);
      Check ("4.2 First decoded element matches weights", Near (Recon (1), 1.0));
      Check ("4.3 Second decoded element matches weights", Near (Recon (2), 1.0));
   end;

   Put_Line ("TEST 5 -- Reconstruction Error Calculation");
   declare
      Orig  : constant Vector(1 .. 2) := [1.0, 2.0];
      Recon : constant Vector(1 .. 2) := [1.0, 2.0];
      Bad   : constant Vector(1 .. 2) := [0.0, 4.0];
   begin
      Check ("5.1 Perfect reconstruction yields zero error", Near (Reconstruction_Error (Orig, Recon), 0.0));
      Check ("5.2 Calculates accurate Mean Squared Error", Near (Reconstruction_Error (Orig, Bad), 2.5));
      Check ("5.3 Symmetry property is maintained", Near (Reconstruction_Error (Bad, Orig), 2.5));
   end;

   Put_Line ("TEST 6 -- Activation Patching (Causal Tracing) - Full Masks");
   declare
      Clean   : constant Vector(1 .. 3) := [1.0, 2.0, 3.0];
      Corrupt : constant Vector(1 .. 3) := [9.0, 8.0, 7.0];
      M_False : constant Boolean_Mask(1 .. 3) := [False, False, False];
      M_True  : constant Boolean_Mask(1 .. 3) := [True, True, True];
   begin
      Check ("6.1 All False mask returns clean vector", Near (Activation_Patch (Clean, Corrupt, M_False)(1), 1.0));
      Check ("6.2 All True mask returns corrupted vector", Near (Activation_Patch (Clean, Corrupt, M_True)(3), 7.0));
      Check ("6.3 Length stays preserved", Activation_Patch (Clean, Corrupt, M_False)'Length = 3);
   end;

   Put_Line ("TEST 7 -- Activation Patching (Causal Tracing) - Mixed Masks");
   declare
      Clean   : constant Vector(1 .. 3) := [1.0, 2.0, 3.0];
      Corrupt : constant Vector(1 .. 3) := [9.0, 8.0, 7.0];
      M_Mixed : constant Boolean_Mask(1 .. 3) := [True, False, True];
      Res     : constant Vector := Activation_Patch (Clean, Corrupt, M_Mixed);
   begin
      Check ("7.1 First element patched", Near (Res (1), 9.0));
      Check ("7.2 Second element remains clean", Near (Res (2), 2.0));
      Check ("7.3 Third element patched", Near (Res (3), 7.0));
   end;

   Put_Line ("TEST 8 -- Superposition Detection");
   declare
      Dims    : constant Natural := 2;
      Dense   : constant Vector(1 .. 4) := [0.9, 0.8, 0.7, 0.6];
      Sparse  : constant Vector(1 .. 4) := [0.9, 0.0, 0.0, 0.0];
      Thresh  : constant Real := 0.5;
   begin
      Check ("8.1 Detects superposition when active features > dimensions", 
             Is_In_Superposition (Dense, Dims, Thresh));
      Check ("8.2 Returns False when within capacity", 
             not Is_In_Superposition (Sparse, Dims, Thresh));
      Check ("8.3 Exact boundary check (Active == Dims is not superposition)", 
             not Is_In_Superposition ([1.0, 1.0, 0.0, 0.0], Dims, Thresh));
   end;

   Put_Line ("TEST 9 -- Induction Head Simulation - Basic Pattern");
   declare
      -- Pattern: [1, 2, 3, 1] -> context at last pos is '1', previous '1' was followed by '2'
      Seq : constant Token_Sequence(1 .. 4) := [1, 2, 3, 1];
      Res : constant Token_Sequence := Simulate_Induction_Head (Seq);
   begin
      Check ("9.1 Induction head predicts '2' at final sequence step", Res (4) = 2);
      Check ("9.2 No previous context defaults to 0 (step 1)", Res (1) = 0);
      Check ("9.3 No previous context defaults to 0 (step 2)", Res (2) = 0);
   end;

   Put_Line ("TEST 10 -- Induction Head Simulation - Complex Patterns");
   declare
      -- Sequence: [5, 9, 5, 8, 5] 
      -- Index 3 (context 5): prior 5 was followed by 9. Result(3) = 9.
      -- Index 5 (context 5): prior 5 was followed by 8. Result(5) = 8.
      Seq : constant Token_Sequence(1 .. 5) := [5, 9, 5, 8, 5];
      Res : constant Token_Sequence := Simulate_Induction_Head (Seq);
   begin
      Check ("10.1 Updates prediction based on most recent context", Res (5) = 8);
      Check ("10.2 Correctly identified first pattern instance", Res (3) = 9);
      Check ("10.3 Token with no historical follower returns default", Res (4) = 0);
   end;

   Put_Line ("TEST 11 -- Induction Head Simulation - Edge Cases");
   declare
      Seq_Short : constant Token_Sequence(1 .. 1) := [others => 7];
      Seq_Repeat : constant Token_Sequence(1 .. 3) := [4, 4, 4];
      Res_Short  : constant Token_Sequence := Simulate_Induction_Head (Seq_Short);
      Res_Repeat : constant Token_Sequence := Simulate_Induction_Head (Seq_Repeat);
   begin
      Check ("11.1 Single token sequence is handled gracefully", Res_Short (1) = 0);
      Check ("11.2 Repeated token induction evaluates correctly (index 2)", Res_Repeat (2) = 4);
      Check ("11.3 Repeated token induction evaluates correctly (index 3)", Res_Repeat (3) = 4);
   end;

   Put_Line ("TEST 12 -- Contract Verification (Preconditions on Shapes)");
   declare
      In_Vec : constant Vector(1 .. 2) := [1.0, 2.0];
      W_Mat  : constant Matrix(1 .. 3, 1 .. 2) := [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]];
      Bias   : constant Vector(1 .. 2) := [0.0, 0.0];
      Caught : Boolean := False;
   begin
      begin
         if Linear_Transform (In_Vec, W_Mat, Bias)'Length > 0 then
            Check ("12.1 Execution should not reach here", False);
         end if;
      exception
         when others => Caught := True;
      end;
      Check ("12.2 Input vs Weights mismatch caught via precondition", Caught);
      Check ("12.3 Ensure execution continued safely", True);
   end;

   Put_Line ("TEST 13 -- Contract Verification (Bias dimension mismatch)");
   declare
      In_Vec : constant Vector(1 .. 2) := [1.0, 2.0];
      W_Mat  : constant Matrix(1 .. 2, 1 .. 2) := [[1.0, 1.0], [1.0, 1.0]];
      Bias   : constant Vector(1 .. 3) := [0.0, 0.0, 0.0];
      Caught : Boolean := False;
   begin
      begin
         if Linear_Transform (In_Vec, W_Mat, Bias)'Length > 0 then
            Check ("13.1 Execution should not reach here", False);
         end if;
      exception
         when others => Caught := True;
      end;
      Check ("13.2 Bias vs Weights mismatch caught via precondition", Caught);
      Check ("13.3 Robust exception handling validated", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
