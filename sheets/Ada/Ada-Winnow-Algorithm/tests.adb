-- tests.adb
-- Standalone test suite verifying Winnow implementation against negative assumptions.

with Ada.Text_IO; use Ada.Text_IO;
with Winnow;      use Winnow;

procedure Tests is

   -- Custom Assertion Helper to print readable output.
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;

   Std_Model     : Winnow_Model (N => 3);
   Bal_Model     : Balanced_Winnow_Model (N => 2);
   X3_Zero       : constant Feature_Vector (1 .. 3) := (0, 0, 0);
   X3_One        : constant Feature_Vector (1 .. 3) := (1, 1, 1);
   X2_Data       : constant Feature_Vector (1 .. 2) := (1, 0);

begin
   Put_Line ("======================================================");
   Put_Line ("          WINNOW ALGORITHM V&V TEST SUITE             ");
   Put_Line ("======================================================");
   Put_Line ("Philosophy: Assuming code is broken. Proving otherwise.");
   New_Line;

   -- TEST 1
   Put_Line ("TEST 1 - Standard Initialization");
   Put_Line ("  1.1 Assume initial weights are corrupt. Assert weights are exactly 1.0.");
   Std_Model := Initialize (N => 3, Alpha => 2.0, Threshold => 2.5);
   Assert (Std_Model.Weights (1) = 1.0, "Weight 1 not 1.0");
   Assert (Std_Model.Weights (3) = 1.0, "Weight 3 not 1.0");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Edge Case: Invalid Alpha parameter");
   Put_Line ("  2.1 Assume alpha bounds are unchecked. Assert Alpha <= 1.0 raises error.");
   begin
      declare
         Bad_Model : Winnow_Model := Initialize (N => 2, Alpha => 0.5);
         pragma Unreferenced (Bad_Model);
      begin
         Assert (False, "Expected Configuration_Error was NOT raised");
      end;
   exception
      when Configuration_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 3
   Put_Line ("TEST 3 - Standard Prediction (No Activation)");
   Put_Line ("  3.1 Assume dot product ignores zeros. Assert (0,0,0) evaluates to False.");
   Assert (Predict (Std_Model, X3_Zero) = False, "Prediction on zeros should be False");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Standard Prediction (Activation)");
   Put_Line ("  4.1 Assume threshold evaluation is broken. Assert (1,1,1) -> 3.0 > 2.5 -> True.");
   Assert (Predict (Std_Model, X3_One) = True, "Prediction on ones should be True");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Standard Training (Promotion / False Negative)");
   Put_Line ("  5.1 Assume weights do not multiply. Training (0,1,0) = True.");
   Train (Std_Model, (0, 1, 0), True); -- Triggers False Negative
   Assert (Std_Model.Weights (1) = 1.0, "Weight 1 should not change");
   Assert (Std_Model.Weights (2) = 2.0, "Weight 2 should double (Promoted)");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Standard Training (Demotion / False Positive)");
   Put_Line ("  6.1 Assume weights do not divide. Training (1,1,1) = False.");
   Train (Std_Model, X3_One, False); -- Triggers False Positive
   Assert (Std_Model.Weights (1) = 0.5, "Weight 1 should halve (Demoted)");
   Assert (Std_Model.Weights (2) = 1.0, "Weight 2 should halve (2.0 -> 1.0)");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - No Update on Correct Prediction");
   Put_Line ("  7.1 Assume weights drift. Assert training correct output causes no change.");
   Train (Std_Model, X3_Zero, False); -- Predicts False correctly
   Assert (Std_Model.Weights (1) = 0.5, "Weight 1 mutated incorrectly");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Input Mismatch Handling");
   Put_Line ("  8.1 Assume array boundaries leak. Assert mismatch raises Invalid_Input_Error.");
   begin
      Train (Std_Model, X2_Data, True);
      Assert (False, "Mismatched feature vector did not throw error.");
   exception
      when Invalid_Input_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Balanced Initialization");
   Put_Line ("  9.1 Assume Pos/Neg sets merge. Assert distinct weights exist.");
   Bal_Model := Initialize_Balanced (N => 2);
   Assert (Bal_Model.Weights_Pos (1) = 2.0, "Pos Weights bad initialization");
   Assert (Bal_Model.Weights_Neg (1) = 2.0, "Neg Weights bad initialization");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Balanced Prediction");
   Put_Line ("  10.1 Assume difference calculation fails. Assert (1,0) evaluates to False (0 diff).");
   Assert (Predict (Bal_Model, X2_Data) = False, "Balanced init should predict false for Threshold 0.0");
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Balanced Training (Symmetric Update)");
   Put_Line ("  11.1 Assume symmetries break. Train (1,0)=True -> Pos rises, Neg falls.");
   Train (Bal_Model, X2_Data, True);
   Assert (Bal_Model.Weights_Pos (1) = 4.0, "Pos Weight did not double");
   Assert (Bal_Model.Weights_Neg (1) = 1.0, "Neg Weight did not halve");
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Machine Learning Convergence: OR Gate");
   Put_Line ("  12.1 Assume logic learning fails. Train model to learn an OR gate.");
   declare
      Or_Model : Winnow_Model := Initialize (N => 2, Alpha => 2.0, Threshold => 1.5);
   begin
      -- Train OR gate over 5 epochs
      for Epoch in 1 .. 5 loop
         Train (Or_Model, (0, 0), False);
         Train (Or_Model, (0, 1), True);
         Train (Or_Model, (1, 0), True);
         Train (Or_Model, (1, 1), True);
      end loop;
      Assert (Predict (Or_Model, (0, 0)) = False, "OR(0,0) failed");
      Assert (Predict (Or_Model, (1, 1)) = True,  "OR(1,1) failed");
      Assert (Predict (Or_Model, (1, 0)) = True,  "OR(1,0) failed");
      Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Machine Learning Convergence: AND Gate");
   Put_Line ("  13.1 Assume logic thresholds fail. Train model to learn an AND gate.");
   declare
      And_Model : Winnow_Model := Initialize (N => 2, Alpha => 2.0, Threshold => 2.5);
   begin
      -- Train AND gate over 5 epochs
      for Epoch in 1 .. 5 loop
         Train (And_Model, (0, 0), False);
         Train (And_Model, (0, 1), False);
         Train (And_Model, (1, 0), False);
         Train (And_Model, (1, 1), True);
      end loop;
      Assert (Predict (And_Model, (0, 1)) = False, "AND(0,1) failed");
      Assert (Predict (And_Model, (1, 1)) = True,  "AND(1,1) failed");
      Put_Line ("      PASS");
   end;

   New_Line;
   Put_Line ("======================================================");
   Put_Line ("  SUCCESS: All 13+ negative assumptions proven false.");
   Put_Line ("======================================================");
end Tests;
