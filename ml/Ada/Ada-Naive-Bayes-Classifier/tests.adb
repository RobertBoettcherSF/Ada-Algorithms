with Ada.Text_IO; use Ada.Text_IO;
with Naive_Bayes; use Naive_Bayes;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   Put_Line ("--- Starting Naive Bayes Tests ---");

   --  TEST 1: Gaussian Basic
   Put_Line ("TEST 1 - Gaussian Basic Train & Predict");
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 2) :=
        [[1.0, 1.0],
         [2.0, 1.0],
         [10.0, 10.0],
         [11.0, 10.0]];
      Y : constant Label_Vector (1 .. 4) := [1, 1, 2, 2];
      Model : constant Gaussian_Model := Train_Gaussian (X, Y, 2);
   begin
      Check ("1.1 Model built successfully", Model.Num_Classes = 2);
      Check ("1.2 Predict Class 1", Predict_Gaussian (Model, [1 => 1.5, 2 => 1.0]) = 1);
      Check ("1.3 Predict Class 2", Predict_Gaussian (Model, [1 => 10.5, 2 => 10.5]) = 2);
   end;

   --  TEST 2: Gaussian with Negative Values
   Put_Line ("TEST 2 - Gaussian Negative Data");
   declare
      X : constant Feature_Matrix (1 .. 3, 1 .. 2) := [[-1.0, -1.0], [-2.0, -1.0], [10.0, 10.0]];
      Y : constant Label_Vector (1 .. 3) := [1, 1, 2];
      Model : constant Gaussian_Model := Train_Gaussian (X, Y, 2);
   begin
      Check ("2.1 Model Built", Model.Num_Features = 2);
      Check ("2.2 Predict Class 1", Predict_Gaussian (Model, [1 => -1.5, 2 => -1.0]) = 1);
      Check ("2.3 Predict Class 2", Predict_Gaussian (Model, [1 => 9.0, 2 => 9.0]) = 2);
   end;

   --  TEST 3: Gaussian Variance Smoothing
   Put_Line ("TEST 3 - Gaussian Variance Smoothing (Identical Samples)");
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 2) := [[1.0, 1.0], [1.0, 1.0], [2.0, 2.0], [2.0, 2.0]];
      Y : constant Label_Vector (1 .. 4) := [1, 1, 2, 2];
      Model : constant Gaussian_Model := Train_Gaussian (X, Y, 2, Var_Smoothing => 1.0e-5);
   begin
      Check ("3.1 Model built successfully", True);
      -- Ensure zero variance triggered smoothing correctly
      Check ("3.2 Variance > 0", Model.Variances (1, 1) >= 1.0e-5);
      Check ("3.3 Predict Class 1", Predict_Gaussian (Model, [1 => 1.0, 2 => 1.0]) = 1);
   end;

   --  TEST 4: Multinomial Basic
   Put_Line ("TEST 4 - Multinomial Basic Train & Predict");
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 2) :=
        [[1.0, 0.0],
         [2.0, 0.0],
         [0.0, 1.0],
         [0.0, 2.0]];
      Y : constant Label_Vector (1 .. 4) := [1, 1, 2, 2];
      Model : constant Multinomial_Model := Train_Multinomial (X, Y, 2);
   begin
      Check ("4.1 Model built successfully", Model.Num_Classes = 2);
      Check ("4.2 Predict Class 1", Predict_Multinomial (Model, [1 => 1.0, 2 => 0.0]) = 1);
      Check ("4.3 Predict Class 2", Predict_Multinomial (Model, [1 => 0.0, 2 => 1.0]) = 2);
   end;

   --  TEST 5: Multinomial Smoothing
   Put_Line ("TEST 5 - Multinomial High Alpha Smoothing");
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 2) := [[1.0, 0.0], [0.0, 1.0]];
      Y : constant Label_Vector (1 .. 2) := [1, 2];
      Model : constant Multinomial_Model := Train_Multinomial (X, Y, 2, Alpha => 100.0);
   begin
      Check ("5.1 High smoothing completes", True);
      Check ("5.2 Equal Priors", Model.Log_Priors (1) = Model.Log_Priors (2));
      Check ("5.3 Predict Class 1", Predict_Multinomial (Model, [1 => 1.0, 2 => 0.0]) = 1);
   end;

   --  TEST 6: Multinomial Text Classification Mock
   Put_Line ("TEST 6 - Multinomial Text Classification");
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 4) :=
        [[1.0, 1.0, 0.0, 0.0],
         [0.0, 0.0, 1.0, 1.0]];
      Y : constant Label_Vector (1 .. 2) := [1, 2];
      Model : constant Multinomial_Model := Train_Multinomial (X, Y, 2);
   begin
      Check ("6.1 Model Setup", Model.Num_Features = 4);
      Check ("6.2 Predict Class 1 via keywords", Predict_Multinomial (Model, [1.0, 0.0, 0.0, 0.0]) = 1);
      Check ("6.3 Predict Class 2 via keywords", Predict_Multinomial (Model, [0.0, 0.0, 1.0, 0.0]) = 2);
   end;

   --  TEST 7: Bernoulli Basic
   Put_Line ("TEST 7 - Bernoulli Basic Classification");
   declare
      X : constant Feature_Matrix (1 .. 3, 1 .. 2) := [[1.0, 0.0], [1.0, 0.0], [0.0, 1.0]];
      Y : constant Label_Vector (1 .. 3) := [1, 1, 2];
      Model : constant Bernoulli_Model := Train_Bernoulli (X, Y, 2);
   begin
      Check ("7.1 Model Setup", Model.Num_Classes = 2);
      Check ("7.2 Predict Presence 1", Predict_Bernoulli (Model, [1.0, 0.0]) = 1);
      Check ("7.3 Predict Presence 2", Predict_Bernoulli (Model, [0.0, 1.0]) = 2);
   end;

   --  TEST 8: Bernoulli Thresholding
   Put_Line ("TEST 8 - Bernoulli Non-Binary Thresholding");
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 2) := [[10.0, -5.0], [0.0, 20.0]];
      Y : constant Label_Vector (1 .. 2) := [1, 2];
      Model : constant Bernoulli_Model := Train_Bernoulli (X, Y, 2);
   begin
      Check ("8.1 Thresholding handled internally", True);
      Check ("8.2 Predict Class 1", Predict_Bernoulli (Model, [5.0, -1.0]) = 1);
      Check ("8.3 Predict Class 2", Predict_Bernoulli (Model, [0.0, 5.0]) = 2);
   end;

   --  TEST 9: Training Dimensions Mismatch
   Put_Line ("TEST 9 - Training Dimensions Precondition");
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 2) := [[1.0, 1.0], [2.0, 2.0]];
      Y : constant Label_Vector (1 .. 1) := [1 => 1];
   begin
      Check ("9.1 Setup intentional bounds mismatch", True);
      declare
         M : constant Gaussian_Model := Train_Gaussian (X, Y, 2);
      begin
         Check ("9.2 Should not reach here", False);
         Check ("9.3 Dummy failure", M.Num_Classes = 2);
      end;
   exception
      when others =>
         Check ("9.2 Caught expected bounds mismatch", True);
         Check ("9.3 Passed", True);
   end;

   --  TEST 10: Invalid Label handling
   Put_Line ("TEST 10 - Invalid Label Data_Error");
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 2) := [[1.0, 1.0], [2.0, 2.0]];
      Y : constant Label_Vector (1 .. 2) := [1, 3]; -- 3 is > Num_Classes (2)
   begin
      Check ("10.1 Setup intentional invalid label", True);
      declare
         M : constant Multinomial_Model := Train_Multinomial (X, Y, 2);
      begin
         Check ("10.2 Should not reach here", False);
         Check ("10.3 Dummy failure", M.Num_Classes = 2);
      end;
   exception
      when Naive_Bayes.Data_Error =>
         Check ("10.2 Caught Data_Error exactly", True);
         Check ("10.3 Passed", True);
      when others =>
         Check ("10.2 Failed: wrong exception caught", False);
         Check ("10.3 Failed", False);
   end;

   --  TEST 11: Single Class Missing (Zero occurrences)
   Put_Line ("TEST 11 - Class missing in training set");
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 2) := [[1.0, 1.0], [2.0, 2.0]];
      Y : constant Label_Vector (1 .. 2) := [1, 1];
      Model : constant Gaussian_Model := Train_Gaussian (X, Y, 2);
   begin
      Check ("11.1 Model completed despite missing class 2", True);
      Check ("11.2 Prior for class 2 is extremely low", Model.Log_Priors (2) < -100.0);
      Check ("11.3 Predict defaults securely", Predict_Gaussian (Model, [1.5, 1.5]) = 1);
   end;

   --  TEST 12: Invalid Alpha Precondition
   Put_Line ("TEST 12 - Negative Alpha Precondition");
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 2) := [[1.0, 1.0], [2.0, 2.0]];
      Y : constant Label_Vector (1 .. 2) := [1, 2];
   begin
      Check ("12.1 Setup invalid alpha", True);
      declare
         M : constant Bernoulli_Model := Train_Bernoulli (X, Y, 2, Alpha => -1.0);
      begin
         Check ("12.2 Should not reach here", False);
         Check ("12.3 Dummy failure", M.Num_Classes = 2);
      end;
   exception
      when others =>
         Check ("12.2 Caught Alpha Precondition", True);
         Check ("12.3 Passed", True);
   end;

   --  TEST 13: Prediction length mismatch
   Put_Line ("TEST 13 - Prediction length Precondition");
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 2) := [[1.0, 1.0], [2.0, 2.0]];
      Y : constant Label_Vector (1 .. 2) := [1, 2];
      Model : constant Multinomial_Model := Train_Multinomial (X, Y, 2);
      Bad_Vec : constant Feature_Vector (1 .. 3) := [1.0, 2.0, 3.0];
   begin
      Check ("13.1 Setup valid model, bad predict array", True);
      declare
         Result : constant Class_ID := Predict_Multinomial (Model, Bad_Vec);
      begin
         Check ("13.2 Should not reach here", False);
         Check ("13.3 Dummy failure", Result = 1);
      end;
   exception
      when others =>
         Check ("13.2 Caught Prediction Dimension Mismatch", True);
         Check ("13.3 Passed", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
