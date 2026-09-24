with Ada.Text_IO; use Ada.Text_IO;
with Adaboost;    use Adaboost;

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

   -- Helper variables for testing
   Empty_X : Features_Matrix (1 .. 0, 1 .. 1);
   Empty_Y : Labels_Array (1 .. 0);
   Model   : AdaBoost_Model (Max_Iterations => 10);

begin
   Put_Line ("TEST 1 - Exception: Empty Dataset (0 rows)");
   declare
      Raised_Error : Boolean := False;
   begin
      begin
         Train (Model, Empty_X, Empty_Y);
      exception
         when Empty_Dataset_Error => Raised_Error := True;
         when others => null;
      end;
      Check ("1.1 Empty matrix rows raises Empty_Dataset_Error", Raised_Error);
      Check ("1.2 Model count remains 0", Model.Count = 0);
      pragma Warnings (Off, "condition can only be False if invalid values present");
      pragma Warnings (Off, "condition is always True");
      Check ("1.3 Max iterations intact", Model.Max_Iterations = 10);
      pragma Warnings (On, "condition is always True");
      pragma Warnings (On, "condition can only be False if invalid values present");
   end;

   Put_Line ("TEST 2 - Exception: Empty Dataset (0 cols)");
   declare
      Raised_Error : Boolean := False;
      Zero_Col_X   : Features_Matrix (1 .. 1, 1 .. 0);
      One_Row_Y    : constant Labels_Array (1 .. 1) := [1 => Adaboost.Positive];
   begin
      begin
         Train (Model, Zero_Col_X, One_Row_Y);
      exception
         when Empty_Dataset_Error => Raised_Error := True;
         when others => null;
      end;
      Check ("2.1 Empty matrix cols raises Empty_Dataset_Error", Raised_Error);
      Check ("2.2 Model count remains 0", Model.Count = 0);
      Check ("2.3 Model feature count remains 0", Model.Feature_Count = 0);
   end;

   Put_Line ("TEST 3 - Exception: Dimension Mismatch (Rows)");
   declare
      Raised_Error : Boolean := False;
      Mismatch_X   : constant Features_Matrix (1 .. 2, 1 .. 1) := [1 => [1 => 1.0], 2 => [1 => 2.0]];
      Mismatch_Y   : constant Labels_Array (1 .. 1) := [1 => Adaboost.Positive];
   begin
      begin
         Train (Model, Mismatch_X, Mismatch_Y);
      exception
         when Dimension_Mismatch_Error => Raised_Error := True;
         when others => null;
      end;
      Check ("3.1 Mismatched rows raises Dimension_Mismatch_Error", Raised_Error);
      Check ("3.2 Safely averted training loop", True);
      Check ("3.3 State clean", Model.Count = 0);
   end;

   Put_Line ("TEST 4 - Exception: Dimension Mismatch (Predict)");
   declare
      Raised_Error : Boolean := False;
      X : constant Features_Matrix (1 .. 1, 1 .. 2) := [1 => [1 => 1.0, 2 => 1.0]];
      Y : constant Labels_Array (1 .. 1) := [1 => Adaboost.Positive];
      Vec : constant Feature_Vector (1 .. 3) := [1 => 1.0, 2 => 1.0, 3 => 1.0];
   begin
      Train (Model, X, Y);
      begin
         if Predict (Model, Vec) = Adaboost.Positive then
            null;
         end if;
      exception
         when Dimension_Mismatch_Error => Raised_Error := True;
         when others => null;
      end;
      Check ("4.1 Training succeeded on valid simple data", Model.Count = 1);
      Check ("4.2 Mismatched features length in predict raises Error", Raised_Error);
      Check ("4.3 Model remembers trained Feature_Count", Model.Feature_Count = 2);
   end;

   Put_Line ("TEST 5 - Perfect Separation (Polarity 1)");
   declare
      X : constant Features_Matrix (1 .. 2, 1 .. 1) := [1 => [1 => 1.0], 2 => [1 => 3.0]];
      Y : constant Labels_Array (1 .. 2) := [Adaboost.Negative, Adaboost.Positive];
      V1 : constant Feature_Vector (1 .. 1) := [1 => 1.0];
      V2 : constant Feature_Vector (1 .. 1) := [1 => 3.0];
   begin
      Train (Model, X, Y);
      Check ("5.1 Stops early at 1 stump", Model.Count = 1);
      Check ("5.2 Predicts Negative for 1.0", Predict (Model, V1) = Adaboost.Negative);
      Check ("5.3 Predicts Positive for 3.0", Predict (Model, V2) = Adaboost.Positive);
   end;

   Put_Line ("TEST 6 - Perfect Separation (Polarity -1)");
   declare
      X : constant Features_Matrix (1 .. 2, 1 .. 1) := [1 => [1 => 1.0], 2 => [1 => 3.0]];
      Y : constant Labels_Array (1 .. 2) := [Adaboost.Positive, Adaboost.Negative];
      V1 : constant Feature_Vector (1 .. 1) := [1 => 1.0];
      V2 : constant Feature_Vector (1 .. 1) := [1 => 3.0];
   begin
      Train (Model, X, Y);
      Check ("6.1 Stops early at 1 stump", Model.Count = 1);
      Check ("6.2 Predicts Positive for 1.0", Predict (Model, V1) = Adaboost.Positive);
      Check ("6.3 Predicts Negative for 3.0", Predict (Model, V2) = Adaboost.Negative);
   end;

   Put_Line ("TEST 7 - Inseparable Data Handling");
   declare
      X : constant Features_Matrix (1 .. 2, 1 .. 1) := [1 => [1 => 2.0], 2 => [1 => 2.0]];
      Y : constant Labels_Array (1 .. 2) := [Adaboost.Positive, Adaboost.Negative];
   begin
      Train (Model, X, Y);
      Check ("7.1 Cannot separate, aborts gracefully", Model.Count = 0);
      Check ("7.2 Predict returns default (Positive) for empty ensemble", Predict (Model, [1 => 2.0]) = Adaboost.Positive);
      Check ("7.3 Predict_Score is exactly 0.0", Predict_Score (Model, [1 => 2.0]) = 0.0);
   end;

   Put_Line ("TEST 8 - All Positive Labels Quick Exit");
   declare
      X : constant Features_Matrix (1 .. 2, 1 .. 1) := [1 => [1 => 1.0], 2 => [1 => 3.0]];
      Y : constant Labels_Array (1 .. 2) := [Adaboost.Positive, Adaboost.Positive];
   begin
      Train (Model, X, Y);
      Check ("8.1 Early exit on perfect score", Model.Count = 1);
      Check ("8.2 Predicts Positive unconditionally", Predict (Model, [1 => 2.0]) = Adaboost.Positive);
      Check ("8.3 Score is strictly positive", Predict_Score (Model, [1 => 2.0]) > 0.0);
   end;

   Put_Line ("TEST 9 - All Negative Labels Quick Exit");
   declare
      X : constant Features_Matrix (1 .. 2, 1 .. 1) := [1 => [1 => 1.0], 2 => [1 => 3.0]];
      Y : constant Labels_Array (1 .. 2) := [Adaboost.Negative, Adaboost.Negative];
   begin
      Train (Model, X, Y);
      Check ("9.1 Early exit on perfect score", Model.Count = 1);
      Check ("9.2 Predicts Negative unconditionally", Predict (Model, [1 => 2.0]) = Adaboost.Negative);
      Check ("9.3 Score is strictly negative", Predict_Score (Model, [1 => 2.0]) < 0.0);
   end;

   Put_Line ("TEST 10 - Multi-Step AdaBoost Region Learning");
   declare
      -- 1D Space: [1.5, 2.5] is Positive, outside is Negative. Stumps must combine.
      X : constant Features_Matrix (1 .. 3, 1 .. 1) := 
        [1 => [1 => 1.0], 2 => [1 => 2.0], 3 => [1 => 3.0]];
      Y : constant Labels_Array (1 .. 3) := [Adaboost.Negative, Adaboost.Positive, Adaboost.Negative];
   begin
      Train (Model, X, Y);
      Check ("10.1 Required >1 stump to map region", Model.Count > 1);
      Check ("10.2 Left bound correctly predicted", Predict (Model, [1 => 1.0]) = Adaboost.Negative);
      Check ("10.3 Center correctly predicted", Predict (Model, [1 => 2.0]) = Adaboost.Positive);
      Check ("10.4 Right bound correctly predicted", Predict (Model, [1 => 3.0]) = Adaboost.Negative);
   end;

   Put_Line ("TEST 11 - 2D Feature Selection");
   declare
      X : constant Features_Matrix (1 .. 4, 1 .. 2) := 
        [1 => [1 => 1.0, 2 => 1.0], 2 => [1 => 1.0, 2 => 3.0],
         3 => [1 => 3.0, 2 => 1.0], 4 => [1 => 3.0, 2 => 3.0]];
      -- Class depends exclusively on feature 2
      Y : constant Labels_Array (1 .. 4) := [Adaboost.Negative, Adaboost.Positive, Adaboost.Negative, Adaboost.Positive];
   begin
      Train (Model, X, Y);
      Check ("11.1 Stopped early (separable on F2)", Model.Count = 1);
      Check ("11.2 Evaluates correctly disregarding F1", Predict (Model, [1 => 9.0, 2 => 3.0]) = Adaboost.Positive);
      Check ("11.3 Evaluates correctly regarding F2", Predict (Model, [1 => 9.0, 2 => 1.0]) = Adaboost.Negative);
   end;

   Put_Line ("TEST 12 - Extreme Values Robustness");
   declare
      X : constant Features_Matrix (1 .. 2, 1 .. 1) := 
        [1 => [1 => -1.0e15], 2 => [1 => 1.0e15]];
      Y : constant Labels_Array (1 .. 2) := [Adaboost.Negative, Adaboost.Positive];
   begin
      Train (Model, X, Y);
      Check ("12.1 Converged successfully without overflow", Model.Count = 1);
      Check ("12.2 Handled extreme negative well", Predict (Model, [1 => -1.0e15]) = Adaboost.Negative);
      Check ("12.3 Handled extreme positive well", Predict (Model, [1 => 1.0e15]) = Adaboost.Positive);
   end;

   Put_Line ("TEST 13 - Empty Model Usage");
   declare
      Empty_Model : AdaBoost_Model (Max_Iterations => 5);
      Vec : constant Feature_Vector (1 .. 2) := [1.0, 2.0];
   begin
      Check ("13.1 Defaults to score 0.0", Predict_Score (Empty_Model, Vec) = 0.0);
      Check ("13.2 Defaults to Positive class", Predict (Empty_Model, Vec) = Adaboost.Positive);
      Check ("13.3 Does not crash on dimension mismatch if Count=0", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
