with Ada.Text_IO; use Ada.Text_IO;
with Relevance_Vector_Machine; use Relevance_Vector_Machine;
with System.Assertions; use System.Assertions;

procedure Tests is
   -- 1. Use clauses for visibility
   use Relevance_Vector_Machine.Real_Arrays;

   -- 2. Variables and Constants
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   Model : RVM_Model;

   -- Datasets using Ada 2022 square bracket aggregate syntax
   X_Reg1D : constant Real_Matrix (1 .. 4, 1 .. 1) := [[1 => -1.0], [1 => 0.0], [1 => 1.0], [1 => 2.0]];
   Y_Reg1D : constant Real_Vector (1 .. 4)         := [-2.0, 0.0, 2.0, 4.0]; -- y = 2x

   -- Balanced, perfectly separable dataset (Class determined by X1 > 0)
   X_Class : constant Real_Matrix (1 .. 4, 1 .. 2) := [[-1.0, -1.0], [-1.0, 1.0], [1.0, -1.0], [1.0, 1.0]];
   Y_Class : constant Real_Vector (1 .. 4)         := [0.0, 0.0, 1.0, 1.0];

   -- 3. Local Subprograms
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
   Put_Line ("--- Relevance Vector Machine Test Suite ---");

   -- TEST 1 — Initialization State
   Put_Line ("TEST 1 — Model Initialization State");
   Check ("1.1 Model is not trained initially", not Model.Is_Trained_Successfully);
   Check ("1.2 Feature count is zero", Model.Features_Count = 0);
   Check ("1.3 SV count is zero", Model.Support_Vectors_Count = 0);

   -- TEST 2 — Exceptions on Premature Prediction
   Put_Line ("TEST 2 — Exceptions on Predict before Train");
   begin
      declare
         Val : constant Target_Value := Predict (Model, [1 => 1.0]);
         pragma Unreferenced (Val);
      begin
         Check ("2.1 Predict did not raise exception", False);
      end;
   exception
      when Model_Not_Trained => Check ("2.1 Predict raised Model_Not_Trained", True);
      when Assert_Failure => Check ("2.1 Precondition blocked Predict", True);
      when others => Check ("2.1 Unexpected exception", False);
   end;

   -- TEST 3 — Exceptions on Premature Probability Prediction
   Put_Line ("TEST 3 — Exceptions on Predict_Prob before Train");
   begin
      declare
         Prob : constant Probability := Predict_Prob (Model, [1 => 1.0]);
         pragma Unreferenced (Prob);
      begin
         Check ("3.1 Predict_Prob did not raise exception", False);
      end;
   exception
      when Model_Not_Trained => Check ("3.1 Predict_Prob raised Model_Not_Trained", True);
      when Assert_Failure => Check ("3.1 Precondition blocked Predict_Prob", True);
      when others => Check ("3.1 Unexpected exception", False);
   end;

   -- TEST 4 — Dimension Mismatch on Train
   Put_Line ("TEST 4 — Dimension Mismatch on Train (Precondition)");
   begin
      Train (Model, X_Reg1D, Y_Class, Regression); -- Y length is 4, X is 4, this is OK physically
      -- Wait, Precondition is X'Length(1) = Y'Length. Let's force a mismatch.
      declare
         Y_Bad : constant Real_Vector (1 .. 3) := [1.0, 2.0, 3.0];
      begin
         Train (Model, X_Reg1D, Y_Bad, Regression);
         Check ("4.1 Dimension mismatch allowed", False);
      end;
   exception
      when Assert_Failure => Check ("4.1 Precondition blocked dimension mismatch", True);
      when others => Check ("4.1 Unexpected exception", False);
   end;

   -- TEST 5 — Train Regression (Linear)
   Put_Line ("TEST 5 — Train Regression (Linear Kernel)");
   Train (Model, X_Reg1D, Y_Reg1D, Regression, Linear);
   Check ("5.1 Model successfully trained", Model.Is_Trained_Successfully);
   Check ("5.2 Feature count correctly set to 1", Model.Features_Count = 1);
   Check ("5.3 Extracted support vectors", Model.Support_Vectors_Count > 0);

   -- TEST 6 — Predict Regression (Linear)
   Put_Line ("TEST 6 — Predict Regression Accuracy (y = 2x)");
   declare
      Val1 : constant Target_Value := Predict (Model, [1 => 0.5]);
      Val2 : constant Target_Value := Predict (Model, [1 => -0.5]);
   begin
      Check ("6.1 Interpolation valid (f(0.5) ~ 1.0)", abs (Val1 - 1.0) < 0.1);
      Check ("6.2 Extrapolation valid (f(-0.5) ~ -1.0)", abs (Val2 - (-1.0)) < 0.1);
      Check ("6.3 Exact fit valid (f(2.0) ~ 4.0)", abs (Predict(Model, [1 => 2.0]) - 4.0) < 0.1);
   end;

   -- TEST 7 — Sparsity Check (Regression)
   Put_Line ("TEST 7 — Sparsity Assurance (Linear Regression)");
   Check ("7.1 Pruned SV count is minimal (< N)", Model.Support_Vectors_Count < 4);
   Check ("7.2 Active support vectors exists", Model.Support_Vectors_Count >= 1);
   Check ("7.3 Features count consistent", Model.Features_Count = 1);

   -- TEST 8 — Dimension Mismatch on Predict
   Put_Line ("TEST 8 — Dimension Mismatch on Predict");
   begin
      declare
         Val : constant Target_Value := Predict (Model, [1.0, 2.0]); -- expects 1 feature
         pragma Unreferenced (Val);
      begin
         Check ("8.1 Predict allowed wrong feature count", False);
      end;
   exception
      when Assert_Failure => Check ("8.1 Precondition caught wrong feature count", True);
      when others => Check ("8.1 Unexpected exception", False);
   end;

   -- TEST 9 — Train Regression (RBF)
   Put_Line ("TEST 9 — Train Regression (RBF Kernel)");
   Train (Model, X_Reg1D, Y_Reg1D, Regression, RBF, Gamma => 0.5);
   Check ("9.1 RBF Model trained correctly", Model.Is_Trained_Successfully);
   Check ("9.2 Model feature count maintained", Model.Features_Count = 1);
   Check ("9.3 SV count populated", Model.Support_Vectors_Count > 0);

   -- TEST 10 — Predict Regression (RBF)
   Put_Line ("TEST 10 — Predict Regression Accuracy (RBF Kernel)");
   declare
      Val1 : constant Target_Value := Predict (Model, [1 => 1.0]);
   begin
      Check ("10.1 Predict handles RBF correctly", abs (Val1 - 2.0) < 0.5);
      Check ("10.2 Bias and weights apply safely", Model.Support_Vectors_Count <= 4);
      Check ("10.3 Training set points bounded", abs (Predict(Model, [1 => 0.0]) - 0.0) < 0.5);
   end;

   -- TEST 11 — Train Classification (Linear)
   Put_Line ("TEST 11 — Train Classification (Linear Kernel)");
   Train (Model, X_Class, Y_Class, Classification, Linear);
   Check ("11.1 Model trained successfully for classification", Model.Is_Trained_Successfully);
   Check ("11.2 Feature count correctly set to 2", Model.Features_Count = 2);
   Check ("11.3 Support vectors retained for hyperplane", Model.Support_Vectors_Count > 0);

   -- TEST 12 — Predict_Prob Classification
   Put_Line ("TEST 12 — Predict_Prob Output Ranges");
   declare
      Prob_Neg : constant Probability := Predict_Prob (Model, [-1.0, -1.0]);
      Prob_Pos : constant Probability := Predict_Prob (Model, [1.0, 1.0]);
   begin
      Check ("12.1 Negative class probability < 0.5", Prob_Neg < 0.5);
      Check ("12.2 Positive class probability > 0.5", Prob_Pos > 0.5);
      Check ("12.3 Probability is strongly bounded [0, 1]", Prob_Neg >= 0.0 and Prob_Pos <= 1.0);
   end;

   -- TEST 13 — Train & Predict Classification (RBF)
   Put_Line ("TEST 13 — Classification (RBF Kernel)");
   Train (Model, X_Class, Y_Class, Classification, RBF, Gamma => 1.0);
   Check ("13.1 Non-linear Model trained successfully", Model.Is_Trained_Successfully);
   declare
      P1 : constant Probability := Predict_Prob (Model, [1.0, 1.0]);
      P0 : constant Probability := Predict_Prob (Model, [-1.0, -1.0]);
   begin
      Check ("13.2 RBF Positive class identified", P1 > 0.5);
      Check ("13.3 RBF Negative class identified", P0 < 0.5);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
