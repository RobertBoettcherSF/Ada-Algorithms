with Ada.Text_IO; use Ada.Text_IO;
with Supervised_Learning; use Supervised_Learning;

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

   function Approx_Equal (A, B : Real) return Boolean is
   begin
      return abs (A - B) < 0.001;
   end Approx_Equal;

   -- Shared variables
   LR_Model : Linear_Model;
   P_Model  : Perceptron_Model (Dimension => 2);

   -- KNN Data
   KNN_Train_X : constant Matrix (1 .. 4, 1 .. 2) :=
     [1 => [0.0, 0.0], 2 => [0.1, 0.1], 3 => [10.0, 10.0], 4 => [10.1, 10.1]];
   KNN_Train_Y : constant Label_Array (1 .. 4) := [0, 0, 1, 1];
   KNN_Test_X1 : constant Vector (1 .. 2) := [0.0, 0.1];
   KNN_Test_X2 : constant Vector (1 .. 2) := [9.9, 10.0];

   -- Perceptron Data (Gates)
   P_Train_X : constant Matrix (1 .. 4, 1 .. 2) :=
     [1 => [-1.0, -1.0], 2 => [-1.0, 1.0], 3 => [1.0, -1.0], 4 => [1.0, 1.0]];
   P_Train_Y_AND : constant Label_Array (1 .. 4) := [-1, -1, -1, 1];
   P_Train_Y_OR  : constant Label_Array (1 .. 4) := [-1, 1, 1, 1];

begin
   Put_Line ("--- Starting Supervised Learning Tests ---");

   -- TEST 1
   Put_Line ("TEST 1 — Linear Regression Positive Trend");
   declare
      X : constant Vector (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
      Y : constant Vector (1 .. 4) := [3.0, 5.0, 7.0, 9.0]; -- y = 2x + 1
   begin
      LR_Model := Train_Linear_Regression (X, Y);
      Check ("1.1 Slope is approx 2.0", Approx_Equal (LR_Model.Slope, 2.0));
      Check ("1.2 Intercept is approx 1.0", Approx_Equal (LR_Model.Intercept, 1.0));
      Check ("1.3 Predict 5.0 is 11.0", Approx_Equal (Predict_Linear_Regression (LR_Model, 5.0), 11.0));
   end;

   -- TEST 2
   Put_Line ("TEST 2 — Linear Regression Negative Trend");
   declare
      X : constant Vector (1 .. 4) := [0.0, 1.0, 2.0, 3.0];
      Y : constant Vector (1 .. 4) := [10.0, 9.0, 8.0, 7.0]; -- y = -1x + 10
   begin
      LR_Model := Train_Linear_Regression (X, Y);
      Check ("2.1 Slope is approx -1.0", Approx_Equal (LR_Model.Slope, -1.0));
      Check ("2.2 Intercept is approx 10.0", Approx_Equal (LR_Model.Intercept, 10.0));
      Check ("2.3 Predict 5.0 is 5.0", Approx_Equal (Predict_Linear_Regression (LR_Model, 5.0), 5.0));
   end;

   -- TEST 3
   Put_Line ("TEST 3 — Linear Regression Flat Line");
   declare
      X : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      Y : constant Vector (1 .. 3) := [5.0, 5.0, 5.0];
   begin
      LR_Model := Train_Linear_Regression (X, Y);
      Check ("3.1 Slope is 0.0", Approx_Equal (LR_Model.Slope, 0.0));
      Check ("3.2 Intercept is 5.0", Approx_Equal (LR_Model.Intercept, 5.0));
      Check ("3.3 Predict is 5.0 everywhere", Approx_Equal (Predict_Linear_Regression (LR_Model, 99.0), 5.0));
   end;

   -- TEST 4
   Put_Line ("TEST 4 — Linear Regression Errors");
   declare
      Bad_X  : constant Vector (1 .. 1) := [1 => 1.0];
      Bad_Y  : constant Vector (1 .. 1) := [1 => 2.0];
      Mis_Y  : constant Vector (1 .. 2) := [1.0, 2.0];
      Flat_X : constant Vector (1 .. 3) := [2.0, 2.0, 2.0];
      Flat_Y : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      Raised : Boolean;
   begin
      Raised := False;
      begin
         LR_Model := Train_Linear_Regression (Bad_X, Bad_Y);
      exception
         when Insufficient_Data_Error => Raised := True;
      end;
      Check ("4.1 Insufficient data raised", Raised);

      Raised := False;
      begin
         LR_Model := Train_Linear_Regression (Flat_X, Mis_Y);
      exception
         when Dimension_Mismatch_Error => Raised := True;
      end;
      Check ("4.2 Dimension mismatch raised", Raised);

      Raised := False;
      begin
         LR_Model := Train_Linear_Regression (Flat_X, Flat_Y);
      exception
         when Zero_Variance_Error => Raised := True;
      end;
      Check ("4.3 Zero variance raised", Raised);
   end;

   -- TEST 5
   Put_Line ("TEST 5 — KNN 1D K=1");
   declare
      Train_X : constant Matrix (1 .. 4, 1 .. 1) := [1=>[1=>1.0], 2=>[1=>2.0], 3=>[1=>8.0], 4=>[1=>9.0]];
      Train_Y : constant Label_Array (1 .. 4) := [0, 0, 1, 1];
   begin
      Check ("5.1 Closest to 0s", Predict_KNN (Train_X, Train_Y, Vector'[1 => 1.5], 1) = 0);
      Check ("5.2 Closest to 1s", Predict_KNN (Train_X, Train_Y, Vector'[1 => 8.5], 1) = 1);
      Check ("5.3 Exact match 1s", Predict_KNN (Train_X, Train_Y, Vector'[1 => 9.0], 1) = 1);
   end;

   -- TEST 6
   Put_Line ("TEST 6 — KNN 1D K=3");
   declare
      Train_X : constant Matrix (1 .. 5, 1 .. 1) :=
        [1=>[1=>1.0], 2=>[1=>1.1], 3=>[1=>1.2], 4=>[1=>5.0], 5=>[1=>5.1]];
      Train_Y : constant Label_Array (1 .. 5) := [0, 0, 0, 1, 1];
   begin
      Check ("6.1 Majority class 0", Predict_KNN (Train_X, Train_Y, Vector'[1 => 2.0], 3) = 0);
      Check ("6.2 Majority class 1", Predict_KNN (Train_X, Train_Y, Vector'[1 => 4.5], 3) = 1);
      Check ("6.3 Exact match votes 0", Predict_KNN (Train_X, Train_Y, Vector'[1 => 1.0], 3) = 0);
   end;

   -- TEST 7
   Put_Line ("TEST 7 — KNN 2D Exact Matches");
   Check ("7.1 Predict (0.0, 0.1)", Predict_KNN (KNN_Train_X, KNN_Train_Y, KNN_Test_X1, 1) = 0);
   Check ("7.2 Predict (9.9, 10.0)", Predict_KNN (KNN_Train_X, KNN_Train_Y, KNN_Test_X2, 1) = 1);
   Check ("7.3 Predict (10.0, 10.0)", Predict_KNN (KNN_Train_X, KNN_Train_Y, Vector'[10.0, 10.0], 1) = 1);

   -- TEST 8
   Put_Line ("TEST 8 — KNN Errors");
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            L : constant Class_Label := Predict_KNN (KNN_Train_X, KNN_Train_Y, KNN_Test_X1, 5);
            pragma Unreferenced (L);
         begin null; end;
      exception
         when Invalid_Hyperparameter_Error => Raised := True;
      end;
      Check ("8.1 Invalid K", Raised);

      Raised := False;
      begin
         declare
            Bad_Y : constant Label_Array (1 .. 3) := [0, 0, 1];
            L : constant Class_Label := Predict_KNN (KNN_Train_X, Bad_Y, KNN_Test_X1, 1);
            pragma Unreferenced (L);
         begin null; end;
      exception
         when Dimension_Mismatch_Error => Raised := True;
      end;
      Check ("8.2 Mismatched Train lengths", Raised);

      Raised := False;
      begin
         declare
            Bad_Test : constant Vector (1 .. 3) := [0.0, 0.0, 0.0];
            L : constant Class_Label := Predict_KNN (KNN_Train_X, KNN_Train_Y, Bad_Test, 1);
            pragma Unreferenced (L);
         begin null; end;
      exception
         when Dimension_Mismatch_Error => Raised := True;
      end;
      Check ("8.3 Mismatched Test dimension", Raised);
   end;

   -- TEST 9
   Put_Line ("TEST 9 — Perceptron AND Gate");
   P_Model := Train_Perceptron (P_Train_X, P_Train_Y_AND, 0.1, 10);
   Check ("9.1 (-1, -1) -> -1", Predict_Perceptron (P_Model, Vector'[-1.0, -1.0]) = -1);
   Check ("9.2 (1, -1)  -> -1", Predict_Perceptron (P_Model, Vector'[1.0, -1.0]) = -1);
   Check ("9.3 (1, 1)   ->  1", Predict_Perceptron (P_Model, Vector'[1.0, 1.0]) = 1);

   -- TEST 10
   Put_Line ("TEST 10 — Perceptron OR Gate");
   P_Model := Train_Perceptron (P_Train_X, P_Train_Y_OR, 0.1, 10);
   Check ("10.1 (-1, -1) -> -1", Predict_Perceptron (P_Model, Vector'[-1.0, -1.0]) = -1);
   Check ("10.2 (1, -1)  ->  1", Predict_Perceptron (P_Model, Vector'[1.0, -1.0]) = 1);
   Check ("10.3 (-1, 1)  ->  1", Predict_Perceptron (P_Model, Vector'[-1.0, 1.0]) = 1);

   -- TEST 11
   Put_Line ("TEST 11 — Perceptron Errors");
   declare
      Raised : Boolean := False;
   begin
      begin
         P_Model := Train_Perceptron (P_Train_X, P_Train_Y_OR, -0.1, 10);
      exception
         when Invalid_Hyperparameter_Error => Raised := True;
      end;
      Check ("11.1 Negative learning rate", Raised);

      Raised := False;
      begin
         declare
            Bad_Labels : constant Label_Array (1 .. 4) := [0, 1, 1, 1];
         begin
            P_Model := Train_Perceptron (P_Train_X, Bad_Labels, 0.1, 10);
         end;
      exception
         when Invalid_Label_Error => Raised := True;
      end;
      Check ("11.2 Invalid labels (not +1/-1)", Raised);

      Raised := False;
      begin
         declare
            Bad_Test : constant Vector (1 .. 3) := [1.0, 1.0, 1.0];
            L : constant Class_Label := Predict_Perceptron (P_Model, Bad_Test);
            pragma Unreferenced (L);
         begin null; end;
      exception
         when Dimension_Mismatch_Error => Raised := True;
      end;
      Check ("11.3 Mismatched test dimension", Raised);
   end;

   -- TEST 12
   Put_Line ("TEST 12 — KNN Edge Cases");
   declare
      Train_X : constant Matrix (1 .. 2, 1 .. 1) := [1 => [1 => -1.0], 2 => [1 => 1.0]];
      Train_Y : constant Label_Array (1 .. 2) := [0, 1];
      Test_X  : constant Vector (1 .. 1) := [1 => 0.0];
      L       : Class_Label;
      Train_X2 : constant Matrix (1 .. 3, 1 .. 1) := [1=>[1=>0.0], 2=>[1=>10.0], 3=>[1=>10.0]];
      Train_Y2 : constant Label_Array (1 .. 3) := [0, 1, 1];
   begin
      L := Predict_KNN (Train_X, Train_Y, Test_X, 1);
      Check ("12.1 Tie break resolves safely", L = 0 or L = 1);
      L := Predict_KNN (Train_X, Train_Y, Test_X, 2);
      Check ("12.2 Tie break with K=2", L = 0 or L = 1);
      Check ("12.3 Global majority fallback", Predict_KNN (Train_X2, Train_Y2, Vector'[1 => -100.0], 3) = 1);
   end;

   -- TEST 13
   Put_Line ("TEST 13 — Linear Regression Real World Approximation");
   declare
      X : constant Vector (1 .. 5) := [1.0, 2.0, 3.0, 4.0, 5.0];
      Y : constant Vector (1 .. 5) := [2.2, 4.1, 5.9, 8.1, 10.0];
      M : Linear_Model;
   begin
      M := Train_Linear_Regression (X, Y);
      Check ("13.1 Slope approx 1.96", M.Slope > 1.9 and M.Slope < 2.0);
      Check ("13.2 Intercept approx 0.18", M.Intercept > 0.1 and M.Intercept < 0.3);
      Check ("13.3 Prediction reasonably extrapolates", 
             Predict_Linear_Regression (M, 6.0) > 11.8 and Predict_Linear_Regression (M, 6.0) < 12.1);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
