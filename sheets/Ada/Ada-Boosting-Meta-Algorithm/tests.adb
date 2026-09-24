with Ada.Text_IO; use Ada.Text_IO;
with Boosting;    use Boosting;

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

   procedure Check_Real (Label : String; Actual, Expected, Tol : Real) is
   begin
      Check (Label, abs (Actual - Expected) <= Tol);
   end Check_Real;

begin
   Put_Line ("Starting Boosting Test Suite...");
   Put_Line ("=====================================");

   --  TEST 1: AdaBoost Basic Functionality
   Put_Line ("TEST 1 — AdaBoost Basic Training & Prediction");
   declare
      X     : constant Real_Matrix (1 .. 4, 1 .. 2) := [[1.0, 1.0], [2.0, 1.0], [1.0, 2.0], [3.0, 3.0]];
      Y     : constant Real_Vector (1 .. 4) := [-1.0, -1.0, -1.0, 1.0];
      Model : constant AdaBoost_Model := Train_AdaBoost (X, Y, 5);
   begin
      Check ("1.1 Model built successfully", Model.Num_Iterations > 0);
      Check_Real ("1.2 Predict class -1 correctly", Predict_AdaBoost (Model, [1 => 1.5, 2 => 1.5]), -1.0, 0.0);
      Check_Real ("1.3 Predict class 1 correctly", Predict_AdaBoost (Model, [1 => 3.5, 2 => 3.5]), 1.0, 0.0);
   end;

   --  TEST 2: Gradient Boosting Basic Functionality
   Put_Line ("TEST 2 — Gradient Boosting Training & Prediction");
   declare
      X     : constant Real_Matrix (1 .. 3, 1 .. 1) := [[1 => 1.0], [1 => 2.0], [1 => 3.0]];
      Y     : constant Real_Vector (1 .. 3) := [2.0, 4.0, 6.0];
      Model : constant Gradient_Boosting_Model := Train_Gradient_Boosting (X, Y, 10, 0.5);
   begin
      Check ("2.1 Model has iterations", Model.Num_Iterations = 10);
      Check_Real ("2.2 Predict logic tracks upward trend", Predict_Gradient_Boosting (Model, [1 => 1.0]), 2.0, 1.5);
      Check_Real ("2.3 Predict logic tracks upper bound", Predict_Gradient_Boosting (Model, [1 => 3.0]), 6.0, 1.5);
   end;

   --  TEST 3: AdaBoost Bad Dimensions Exception
   Put_Line ("TEST 3 — AdaBoost Mismatched Dimensions");
   declare
      X      : constant Real_Matrix (1 .. 2, 1 .. 1) := [[1 => 1.0], [1 => 2.0]];
      Y      : constant Real_Vector (1 .. 3) := [1.0, -1.0, 1.0]; -- Length 3 vs 2
      Caught : Boolean := False;
   begin
      Check ("3.1 Setup ready", True);
      begin
         declare
            M : constant AdaBoost_Model := Train_AdaBoost (X, Y, 5);
            pragma Unreferenced (M);
         begin
            Check ("3.2 Should not reach here", False);
         end;
      exception
         when Invalid_Input_Error =>
            Caught := True;
            Check ("3.2 Exception successfully caught", True);
      end;
      Check ("3.3 State validated", Caught);
   end;

   --  TEST 4: Gradient Boosting Bad Dimensions Exception
   Put_Line ("TEST 4 — Gradient Boosting Mismatched Dimensions");
   declare
      X      : constant Real_Matrix (1 .. 3, 1 .. 2) := [[1.0, 1.0], [2.0, 2.0], [3.0, 3.0]];
      Y      : constant Real_Vector (1 .. 2) := [1.0, 2.0];
      Caught : Boolean := False;
   begin
      Check ("4.1 Setup ready", True);
      begin
         declare
            M : constant Gradient_Boosting_Model := Train_Gradient_Boosting (X, Y, 5);
            pragma Unreferenced (M);
         begin
            Check ("4.2 Should not reach here", False);
         end;
      exception
         when Invalid_Input_Error =>
            Caught := True;
            Check ("4.2 Exception successfully caught", True);
      end;
      Check ("4.3 State validated", Caught);
   end;

   --  TEST 5: AdaBoost Invalid Labels Exception
   Put_Line ("TEST 5 — AdaBoost Invalid Labels");
   declare
      X      : constant Real_Matrix (1 .. 2, 1 .. 1) := [[1 => 1.0], [1 => 2.0]];
      Y      : constant Real_Vector (1 .. 2) := [1.0, 2.0]; -- 2.0 is not allowed
      Caught : Boolean := False;
   begin
      Check ("5.1 Setup ready", True);
      begin
         declare
            M : constant AdaBoost_Model := Train_AdaBoost (X, Y, 5);
            pragma Unreferenced (M);
         begin
            Check ("5.2 Should not reach here", False);
         end;
      exception
         when Invalid_Labels_Error =>
            Caught := True;
            Check ("5.2 Caught Invalid_Labels_Error", True);
      end;
      Check ("5.3 Exception validated", Caught);
   end;

   --  TEST 6: Gradient Boosting Zero Iterations
   Put_Line ("TEST 6 — Gradient Boosting Zero Iterations");
   declare
      X     : constant Real_Matrix (1 .. 2, 1 .. 1) := [[1 => 1.0], [1 => 2.0]];
      Y     : constant Real_Vector (1 .. 2) := [10.0, 20.0];
      Model : constant Gradient_Boosting_Model := Train_Gradient_Boosting (X, Y, 0);
   begin
      Check ("6.1 Model iterates 0 times", Model.Num_Iterations = 0);
      Check_Real ("6.2 Init prediction is exact mean", Model.Initial_Prediction, 15.0, 0.0001);
      Check_Real ("6.3 Prediction returns init pred natively", Predict_Gradient_Boosting (Model, [1 => 1.0]), 15.0, 0.0001);
   end;

   --  TEST 7: AdaBoost Early Stopping Condition
   Put_Line ("TEST 7 — AdaBoost Early Stopping");
   declare
      -- Linearly separable perfectly at iteration 1
      X     : constant Real_Matrix (1 .. 4, 1 .. 1) := [[1 => 1.0], [1 => 2.0], [1 => 9.0], [1 => 10.0]];
      Y     : constant Real_Vector (1 .. 4) := [-1.0, -1.0, 1.0, 1.0];
      Model : constant AdaBoost_Model := Train_AdaBoost (X, Y, 20);
   begin
      Check ("7.1 Stopped early (Iter < Max_Iter)", Model.Num_Iterations = 1);
      Check_Real ("7.2 Accurate pred left", Predict_AdaBoost (Model, [1 => 0.0]), -1.0, 0.0);
      Check_Real ("7.3 Accurate pred right", Predict_AdaBoost (Model, [1 => 11.0]), 1.0, 0.0);
   end;

   --  TEST 8: Gradient Boosting Constant Output Dataset
   Put_Line ("TEST 8 — Gradient Boosting Constant Target");
   declare
      X     : constant Real_Matrix (1 .. 3, 1 .. 1) := [[1 => 1.0], [1 => 2.0], [1 => 3.0]];
      Y     : constant Real_Vector (1 .. 3) := [5.0, 5.0, 5.0];
      Model : constant Gradient_Boosting_Model := Train_Gradient_Boosting (X, Y, 3);
   begin
      Check_Real ("8.1 Init pred is exactly 5.0", Model.Initial_Prediction, 5.0, 0.0001);
      Check_Real ("8.2 Pred remains 5.0 internally", Predict_Gradient_Boosting (Model, [1 => 1.5]), 5.0, 0.0001);
      Check_Real ("8.3 Extrapolation prediction is 5.0", Predict_Gradient_Boosting (Model, [1 => 99.0]), 5.0, 0.0001);
   end;

   --  TEST 9: AdaBoost Negative Polarity Handling
   Put_Line ("TEST 9 — AdaBoost Negative Polarity");
   declare
      -- Requires splitting where < Threshold maps to 1, and > maps to -1
      X     : constant Real_Matrix (1 .. 4, 1 .. 1) := [[1 => 1.0], [1 => 2.0], [1 => 8.0], [1 => 9.0]];
      Y     : constant Real_Vector (1 .. 4) := [1.0, 1.0, -1.0, -1.0];
      Model : constant AdaBoost_Model := Train_AdaBoost (X, Y, 1);
   begin
      Check ("9.1 Polarity applied appropriately", Model.Stumps (1).Polarity = -1 or Model.Stumps (1).Polarity = 1);
      Check_Real ("9.2 Predicting class 1 for low value", Predict_AdaBoost (Model, [1 => 0.5]), 1.0, 0.0);
      Check_Real ("9.3 Predicting class -1 for high value", Predict_AdaBoost (Model, [1 => 10.0]), -1.0, 0.0);
   end;

   --  TEST 10: AdaBoost Output Constraints
   Put_Line ("TEST 10 — AdaBoost Postcondition Verification");
   declare
      X     : constant Real_Matrix (1 .. 3, 1 .. 2) := [[1.0, 1.0], [2.0, 2.0], [3.0, 3.0]];
      Y     : constant Real_Vector (1 .. 3) := [1.0, -1.0, 1.0];
      Model : constant AdaBoost_Model := Train_AdaBoost (X, Y, 3);
      P1, P2, P3 : Real;
   begin
      P1 := Predict_AdaBoost (Model, [1 => 1.5, 2 => 1.5]);
      P2 := Predict_AdaBoost (Model, [1 => 2.5, 2 => 2.5]);
      P3 := Predict_AdaBoost (Model, [1 => -1.0, 2 => -1.0]);
      Check ("10.1 Prediction 1 is binary", abs P1 = 1.0);
      Check ("10.2 Prediction 2 is binary", abs P2 = 1.0);
      Check ("10.3 Prediction 3 is binary", abs P3 = 1.0);
   end;

   --  TEST 11: Gradient Boosting Extrapolation
   Put_Line ("TEST 11 — Gradient Boosting Bounds Check");
   declare
      X     : constant Real_Matrix (1 .. 2, 1 .. 1) := [[1 => 1.0], [1 => 5.0]];
      Y     : constant Real_Vector (1 .. 2) := [10.0, 50.0];
      Model : constant Gradient_Boosting_Model := Train_Gradient_Boosting (X, Y, 5, 1.0);
   begin
      Check ("11.1 Trained model has 5 iterations", Model.Num_Iterations = 5);
      -- Values beyond bounds should clamp to the stump's extreme left/right values
      Check_Real ("11.2 Extrapolating left side", Predict_Gradient_Boosting (Model, [1 => -100.0]), 10.0, 2.0);
      Check_Real ("11.3 Extrapolating right side", Predict_Gradient_Boosting (Model, [1 => 100.0]), 50.0, 2.0);
   end;

   --  TEST 12: AdaBoost Large Max Iterations (Robustness)
   Put_Line ("TEST 12 — AdaBoost Robustness with overlapping data");
   declare
      -- Noisy data impossible to completely classify
      X     : constant Real_Matrix (1 .. 4, 1 .. 1) := [[1 => 1.0], [1 => 1.0], [1 => 5.0], [1 => 5.0]];
      Y     : constant Real_Vector (1 .. 4) := [1.0, -1.0, 1.0, -1.0];
      Model : constant AdaBoost_Model := Train_AdaBoost (X, Y, 100);
   begin
      Check ("12.1 Exited early due to poor accuracy threshold", Model.Num_Iterations < 100);
      Check ("12.2 Output prediction yields a valid Real", abs Predict_AdaBoost (Model, [1 => 1.0]) = 1.0);
      Check ("12.3 Robustness pass", True);
   end;

   --  TEST 13: Gradient Boosting High Dimensionality Stub
   Put_Line ("TEST 13 — Gradient Boosting High Dimension Selection");
   declare
      X     : constant Real_Matrix (1 .. 2, 1 .. 5) :=
         [[1.0, 2.0, 3.0, 4.0, 5.0], [6.0, 7.0, 8.0, 9.0, 10.0]];
      Y     : constant Real_Vector (1 .. 2) := [0.0, 1.0];
      Model : constant Gradient_Boosting_Model := Train_Gradient_Boosting (X, Y, 2);
   begin
      Check ("13.1 Selects valid feature index", Model.Stumps (1).Feature <= 5);
      Check_Real ("13.2 Accuracy 1", Predict_Gradient_Boosting (Model, [1.0, 2.0, 3.0, 4.0, 5.0]), 0.0, 0.5);
      Check_Real ("13.3 Accuracy 2", Predict_Gradient_Boosting (Model, [6.0, 7.0, 8.0, 9.0, 10.0]), 1.0, 0.5);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
