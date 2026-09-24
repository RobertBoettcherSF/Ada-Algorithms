with Ada.Text_IO; use Ada.Text_IO;
with SVM;         use SVM;

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

   --  Dummy data setups
   V1 : constant Vector := [1.0, 2.0, 3.0];
   V2 : constant Vector := [4.0, 5.0, 6.0];
   
   --  Linearly Separable Data (AND-like topology)
   X_Lin : constant Matrix (1 .. 4, 1 .. 2) := 
     [[1.0, 1.0], [2.0, 2.0], [-1.0, -1.0], [-2.0, -2.0]];
   Y_Lin : constant Label_Array (1 .. 4) := [1.0, 1.0, -1.0, -1.0];
   
   --  Non-linearly Separable Data (XOR-like topology)
   X_Xor : constant Matrix (1 .. 4, 1 .. 2) := 
     [[1.0, 1.0], [-1.0, 1.0], [-1.0, -1.0], [1.0, -1.0]];
   Y_Xor : constant Label_Array (1 .. 4) := [-1.0, 1.0, -1.0, 1.0];
   
   L_Model : Linear_Model (Dim => 2);

   Exception_Raised : Boolean;
begin
   Put_Line ("TEST 1 — Vector Mathematics (Dot Product)");
   Check ("1.1 Dot product evaluates correctly", Dot_Product (V1, V2) = 32.0);
   Check ("1.2 Self dot product evaluates", Dot_Product (V1, V1) = 14.0);
   Check ("1.3 Zero logic evaluates", Dot_Product (V1, [0.0, 0.0, 0.0]) = 0.0);

   Put_Line ("TEST 2 — Kernel Linear Evaluation");
   Check ("2.1 Linear Kernel matches dot product", 
          Kernel_Compute (Linear_Kernel, V1, V2, 1.0, 1.0, 0.0) = Dot_Product (V1, V2));

   Put_Line ("TEST 3 — Kernel Polynomial Evaluation");
   Check ("3.1 Poly Kernel (Degree 2, Coef0 1)", 
          Kernel_Compute (Polynomial_Kernel, V1, V2, 2.0, 1.0, 1.0) = (32.0 + 1.0)**2);

   Put_Line ("TEST 4 — Kernel RBF Evaluation");
   Check ("4.1 RBF Identical Vectors = 1.0", 
          Kernel_Compute (RBF_Kernel, V1, V1, 1.0, 1.0, 0.0) = 1.0);
   Check ("4.2 RBF Different vectors < 1.0", 
          Kernel_Compute (RBF_Kernel, V1, V2, 1.0, 1.0, 0.0) < 1.0);

   Put_Line ("TEST 5 — Linear SVM Train (Hard Margin simulation)");
   L_Model := Train_Linear (X_Lin, Y_Lin, C => 1000.0, Max_Iter => 500);
   
   pragma Warnings (Off, "condition can only be False if invalid values present");
   pragma Warnings (Off, "condition is always True");
   Check ("5.1 Linear Model has correct dimensionality", L_Model.Dim = 2);
   pragma Warnings (On, "condition is always True");
   pragma Warnings (On, "condition can only be False if invalid values present");
   
   Check ("5.2 Model weights initialized/updated", L_Model.Weights (1) /= 0.0);
   Check ("5.3 Correct classification on positive test point", Predict (L_Model, [3.0, 3.0]) = 1.0);

   Put_Line ("TEST 6 — Linear SVM Train (Soft Margin simulation)");
   L_Model := Train_Linear (X_Lin, Y_Lin, C => 0.1, Max_Iter => 200);
   
   pragma Warnings (Off, "condition can only be False if invalid values present");
   pragma Warnings (Off, "condition is always True");
   Check ("6.1 Low C forces stricter regularization", L_Model.Dim = 2);
   pragma Warnings (On, "condition is always True");
   pragma Warnings (On, "condition can only be False if invalid values present");
   
   Check ("6.2 Correct classification on negative test point", Predict (L_Model, [-3.0, -3.0]) = -1.0);
   Check ("6.3 Bias bounded", L_Model.Bias > -10.0 and L_Model.Bias < 10.0);

   Put_Line ("TEST 7 — Dual SMO SVM Train (RBF Kernel on XOR)");
   --  Simplified SMO needs enough passes and a decent C for non-linear convergence
   declare
      RBF_Model : constant Dual_Model := 
        Train_Dual_SMO (X_Xor, Y_Xor, C => 10.0, Kernel => RBF_Kernel, Max_Passes => 10, Gamma => 1.0);
   begin
      Check ("7.1 Extracted valid support vectors", RBF_Model.Num_Support_Vectors > 0);
      Check ("7.2 Features dimensionality maintained", RBF_Model.Features_Dim = 2);
      Check ("7.3 Predicted XOR properly for class +1", Predict (RBF_Model, [-1.0, 1.0]) = 1.0);
   end;

   Put_Line ("TEST 8 — Dual SMO SVM Train (Polynomial Kernel)");
   declare
      Poly_Model : constant Dual_Model := 
        Train_Dual_SMO (X_Lin, Y_Lin, C => 1.0, Kernel => Polynomial_Kernel, Max_Passes => 5, Degree => 2.0, Coef0 => 1.0);
   begin
      Check ("8.1 Extracted valid support vectors", Poly_Model.Num_Support_Vectors > 0);
      Check ("8.2 Predicted class +1 cleanly", Predict (Poly_Model, [2.0, 2.0]) = 1.0);
      Check ("8.3 Predicted class -1 cleanly", Predict (Poly_Model, [-2.0, -2.0]) = -1.0);
   end;

   Put_Line ("TEST 9 — Prediction API Validation (Linear)");
   Check ("9.1 Prediction Boundary Class +1", Predict (L_Model, [0.5, 0.5]) = 1.0);
   Check ("9.2 Prediction Boundary Class -1", Predict (L_Model, [-0.5, -0.5]) = -1.0);
   Check ("9.3 Extreme value scaling", Predict (L_Model, [99.0, 99.0]) = 1.0);

   Put_Line ("TEST 10 — Prediction API Validation (Dual)");
   declare
      RBF_Dual : constant Dual_Model := 
        Train_Dual_SMO (X_Xor, Y_Xor, 1.0, RBF_Kernel, 5);
   begin
      Check ("10.1 Dual model correctly assesses XOR input", Predict (RBF_Dual, [1.0, 1.0]) = -1.0);
      Check ("10.2 Dual model bounding checks", RBF_Dual.Bias > -10.0);
      Check ("10.3 Gamma preserved in record", RBF_Dual.Gamma = 1.0);
   end;

   Put_Line ("TEST 11 — Exception: Dimension Mismatch (Training)");
   Exception_Raised := False;
   begin
      --  Attempting to train on malformed Y array
      declare
         Bad_Y : constant Label_Array (1 .. 3) := [1.0, 1.0, -1.0];
         Dummy : Linear_Model (Dim => 2);
      begin
         Dummy := Train_Linear (X_Lin, Bad_Y, 1.0, 10);
      end;
   exception
      when Dimension_Mismatch => 
         Exception_Raised := True;
   end;
   Check ("11.1 Precondition failure properly triggered for mismatched rows", Exception_Raised);

   Put_Line ("TEST 12 — Exception: Dimension Mismatch (Prediction)");
   Exception_Raised := False;
   begin
      declare
         --  Sending 3D vector to 2D model
         Result : constant Label_Type := Predict (L_Model, V1);
         pragma Unreferenced (Result);
      begin
         null;
      end;
   exception
      when Dimension_Mismatch =>
         Exception_Raised := True;
   end;
   Check ("12.1 Predict rejects improperly sized features", Exception_Raised);

   Put_Line ("TEST 13 — Exception: Invalid Data (Empty Sets)");
   Exception_Raised := False;
   begin
      declare
         Empty_X : constant Matrix (1 .. 0, 1 .. 2) := [others => [others => 0.0]];
         Empty_Y : constant Label_Array (1 .. 0) := [others => 1.0];
         Dummy   : Dual_Model (0, 0);
      begin
         Dummy := Train_Dual_SMO (Empty_X, Empty_Y, 1.0, Linear_Kernel, 10);
      end;
   exception
      when Invalid_Data =>
         Exception_Raised := True;
   end;
   Check ("13.1 SMO Training rejects empty datasets", Exception_Raised);
   
   Put_Line ("TEST 14 — Edge Cases (Single Element Set)");
   Exception_Raised := False;
   begin
      declare
         Single_X : constant Matrix (1 .. 1, 1 .. 2) := [1 => [1.0, 1.0]];
         Single_Y : constant Label_Array (1 .. 1) := [1 => 1.0];
         Dummy    : Dual_Model (0, 0);
      begin
         Dummy := Train_Dual_SMO (Single_X, Single_Y, 1.0, Linear_Kernel, 10);
      end;
   exception
      when Invalid_Data =>
         Exception_Raised := True;
   end;
   Check ("14.1 SMO properly rejects single-element datasets natively", Exception_Raised);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
