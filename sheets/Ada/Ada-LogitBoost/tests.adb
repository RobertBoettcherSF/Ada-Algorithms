with Ada.Text_IO; use Ada.Text_IO;
with Logit_Boost; use Logit_Boost;

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

   procedure Check_Float (Label : String; Actual, Expected, Tol : Real := 0.001) is
   begin
      if abs (Actual - Expected) <= Tol then
         Check (Label, True);
      else
         Put_Line ("    Expected:" & Real'Image(Expected) & " Actual:" & Real'Image(Actual));
         Check (Label, False);
      end if;
   end Check_Float;

begin
   Put_Line ("TEST 1 - Calculate_Working_Data Basic Logic (P=0.5)");
   declare
      Z1, W1, Z2, W2, Z3, W3 : Real;
   begin
      Calculate_Working_Data (0.5, 1, Z1, W1);
      Calculate_Working_Data (0.5, 0, Z2, W2);
      Calculate_Working_Data (0.2, 1, Z3, W3);

      Check_Float ("1.1 Z for Y=1, P=0.5 is 2.0", Z1, 2.0);
      Check_Float ("1.2 W for P=0.5 is 0.25", W1, 0.25);
      Check_Float ("1.3 Z for Y=0, P=0.5 is -2.0", Z2, -2.0);
      Check_Float ("1.4 W for Y=0, P=0.5 is 0.25", W2, 0.25);
      Check_Float ("1.5 Z for Y=1, P=0.2 is 4.0 (bounded from 5)", Z3, 4.0);
      Check_Float ("1.6 W for P=0.2 is 0.16", W3, 0.16);
   end;

   Put_Line ("TEST 2 - Calculate_Working_Data Extreme Bounds");
   declare
      Z1, W1, Z2, W2, Z3, W3 : Real;
   begin
      Calculate_Working_Data (0.0, 1, Z1, W1);
      Calculate_Working_Data (1.0, 0, Z2, W2);
      Calculate_Working_Data (-1.0, 1, Z3, W3);

      Check_Float ("2.1 Z bounded to 4.0 for P=0", Z1, 4.0);
      Check ("2.2 W non-zero despite P=0", W1 > 0.0);
      Check_Float ("2.3 Z bounded to -4.0 for P=1", Z2, -4.0);
      Check ("2.4 W non-zero despite P=1", W2 > 0.0);
      Check_Float ("2.5 Handled negative probability P=-1 (bounded to 4)", Z3, 4.0);
      Check ("2.6 W valid for P=-1", W3 > 0.0);
   end;

   Put_Line ("TEST 3 - Fit_Stump Perfect Split");
   declare
      X : Feature_Matrix (1 .. 3, 1 .. 1) := ((1 => 1.0), (1 => 2.0), (1 => 3.0));
      Z : Real_Vector (1 .. 3) := (-2.0, -2.0, 2.0);
      W : Real_Vector (1 .. 3) := (0.25, 0.25, 0.25);
      Stump : Decision_Stump;
   begin
      Stump := Fit_Stump (X, Z, W);
      Check ("3.1 Correct feature index", Stump.Feature_Index = 1);
      Check_Float ("3.2 Correct threshold (2.0)", Stump.Threshold, 2.0);
      Check_Float ("3.3 Correct left value", Stump.Left_Value, -2.0);
      Check_Float ("3.4 Correct right value", Stump.Right_Value, 2.0);
   end;

   Put_Line ("TEST 4 - Fit_Stump No Split Needed");
   declare
      X : Feature_Matrix (1 .. 3, 1 .. 1) := ((1 => 1.0), (1 => 2.0), (1 => 3.0));
      Z : Real_Vector (1 .. 3) := (1.0, 1.0, 1.0);
      W : Real_Vector (1 .. 3) := (1.0, 1.0, 1.0);
      Stump : Decision_Stump;
   begin
      Stump := Fit_Stump (X, Z, W);
      Check_Float ("4.1 Left value fits constant Z", Stump.Left_Value, 1.0);
      Check_Float ("4.2 Right value fits constant Z", Stump.Right_Value, 1.0);
      Check ("4.3 Feature selected successfully", Stump.Feature_Index = 1);
   end;

   Put_Line ("TEST 5 - Fit_Stump Zero Weights");
   declare
      X : Feature_Matrix (1 .. 3, 1 .. 1) := ((1 => 1.0), (1 => 2.0), (1 => 3.0));
      Z : Real_Vector (1 .. 3) := (1.0, -1.0, 1.0);
      W : Real_Vector (1 .. 3) := (0.0, 0.0, 0.0);
      Stump : Decision_Stump;
   begin
      Stump := Fit_Stump (X, Z, W);
      Check_Float ("5.1 Left value defaults to 0.0 gracefully", Stump.Left_Value, 0.0);
      Check_Float ("5.2 Right value defaults to 0.0 gracefully", Stump.Right_Value, 0.0);
      Check ("5.3 Executed cleanly without division by zero", True);
   end;

   Put_Line ("TEST 6 - Train Basic Linearly Separable Dataset");
   declare
      X : Feature_Matrix (1 .. 4, 1 .. 1) := ((1 => 1.0), (1 => 2.0), (1 => 8.0), (1 => 9.0));
      Y : Label_Vector (1 .. 4) := (0, 0, 1, 1);
      M : Model := Train (X, Y, 5);
   begin
      Check ("6.1 Model generated exactly 5 stumps", M.Number_Of_Stumps = 5);
      Check ("6.2 Correctly predicts class 0 for x=1.5", Predict (M, (1 => 1.5)) = 0);
      Check ("6.3 Correctly predicts class 1 for x=8.5", Predict (M, (1 => 8.5)) = 1);
   end;

   Put_Line ("TEST 7 - Train Zero Iterations");
   declare
      X : Feature_Matrix (1 .. 2, 1 .. 1) := ((1 => 1.0), (1 => 2.0));
      Y : Label_Vector (1 .. 2) := (0, 1);
      M : Model := Train (X, Y, 0);
   begin
      Check ("7.1 Model has 0 stumps", M.Number_Of_Stumps = 0);
      Check_Float ("7.2 Base F(x) is exactly 0.0", Predict_F (M, (1 => 1.5)), 0.0);
      Check_Float ("7.3 Base probability is exactly 0.5", Predict_Probability (M, (1 => 1.5)), 0.5);
   end;

   Put_Line ("TEST 8 - Train Exceptions (Dimension Mismatches)");
   begin
      declare
         X : Feature_Matrix (1 .. 2, 1 .. 1) := ((1 => 1.0), (1 => 2.0));
         Y : Label_Vector (1 .. 3) := (0, 1, 0);
         M : Model := Train (X, Y, 1);
      begin
         Check ("8.1 Should raise exception on length mismatch", False);
      end;
   exception
      when others => Check ("8.1 Exception properly raised on length mismatch", True);
   end;

   begin
      declare
         X : Feature_Matrix (1 .. 0, 1 .. 1);
         Y : Label_Vector (1 .. 0);
         M : Model := Train (X, Y, 1);
      begin
         Check ("8.2 Should raise exception on empty rows", False);
      end;
   exception
      when others => Check ("8.2 Exception properly raised on empty rows", True);
   end;

   begin
      declare
         X : Feature_Matrix (1 .. 2, 1 .. 0);
         Y : Label_Vector (1 .. 2) := (0, 1);
         M : Model := Train (X, Y, 1);
      begin
         Check ("8.3 Should raise exception on empty columns", False);
      end;
   exception
      when others => Check ("8.3 Exception properly raised on empty columns", True);
   end;

   Put_Line ("TEST 9 - Predict Exceptions on Empty Vector");
   declare
      X : Feature_Matrix (1 .. 2, 1 .. 1) := ((1 => 1.0), (1 => 2.0));
      Y : Label_Vector (1 .. 2) := (0, 1);
      M : Model := Train (X, Y, 1);
      Empty_X : Feature_Vector (1 .. 0);
      L : Class_Label;
      P : Real;
      F : Real;
   begin
      begin
         L := Predict (M, Empty_X);
         Check ("9.1 Should raise exception (Predict)", False);
      exception
         when others => Check ("9.1 Exception raised gracefully (Predict)", True);
      end;

      begin
         P := Predict_Probability (M, Empty_X);
         Check ("9.2 Should raise exception (Predict_Probability)", False);
      exception
         when others => Check ("9.2 Exception raised gracefully (Predict_Probability)", True);
      end;

      begin
         F := Predict_F (M, Empty_X);
         Check ("9.3 Should raise exception (Predict_F)", False);
      exception
         when others => Check ("9.3 Exception raised gracefully (Predict_F)", True);
      end;
   end;

   Put_Line ("TEST 10 - Predict_Probability Bound Validation");
   declare
      X : Feature_Matrix (1 .. 4, 1 .. 1) := ((1 => 1.0), (1 => 2.0), (1 => 8.0), (1 => 9.0));
      Y : Label_Vector (1 .. 4) := (0, 0, 1, 1);
      M : Model := Train (X, Y, 3);
      P1 : Real := Predict_Probability (M, (1 => 1.5));
      P2 : Real := Predict_Probability (M, (1 => 8.5));
   begin
      Check ("10.1 P1 lower bounded >= 0", P1 >= 0.0);
      Check ("10.2 P2 upper bounded <= 1", P2 <= 1.0);
      Check ("10.3 P2 > P1 properly separates classes probabilistically", P2 > P1);
   end;

   Put_Line ("TEST 11 - Predict_F Mathematical Consistency");
   declare
      X : Feature_Matrix (1 .. 4, 1 .. 1) := ((1 => 1.0), (1 => 2.0), (1 => 8.0), (1 => 9.0));
      Y : Label_Vector (1 .. 4) := (0, 0, 1, 1);
      M : Model := Train (X, Y, 2);
      F1 : Real := Predict_F (M, (1 => 1.5));
      F2 : Real := Predict_F (M, (1 => 8.5));
   begin
      Check ("11.1 F1 is negative (indicates class 0)", F1 < 0.0);
      Check ("11.2 F2 is positive (indicates class 1)", F2 > 0.0);
      Check ("11.3 F threshold matches Predict subprogram mapping",
             (if F1 < 0.0 then Predict(M, (1 => 1.5)) = 0 else False));
   end;

   Put_Line ("TEST 12 - Fit_Stump Multidimensional Feature Selection");
   declare
      -- Feature 1 is identical, Feature 2 separates the classes perfectly
      X : Feature_Matrix (1 .. 3, 1 .. 2) :=
        ((1.0, 1.0),
         (1.0, 2.0),
         (1.0, 3.0));
      Z : Real_Vector (1 .. 3) := (-1.0, -1.0, 1.0);
      W : Real_Vector (1 .. 3) := (1.0, 1.0, 1.0);
      Stump : Decision_Stump;
   begin
      Stump := Fit_Stump (X, Z, W);
      Check ("12.1 Selects informative feature (index 2)", Stump.Feature_Index = 2);
      Check_Float ("12.2 Threshold sits on boundary", Stump.Threshold, 2.0);
      Check_Float ("12.3 Left region prediction", Stump.Left_Value, -1.0);
      Check_Float ("12.4 Right region prediction", Stump.Right_Value, 1.0);
   end;

   Put_Line ("TEST 13 - Train Handles Constant Labels Robustly");
   declare
      X : Feature_Matrix (1 .. 3, 1 .. 1) := ((1 => 1.0), (1 => 2.0), (1 => 3.0));
      Y : Label_Vector (1 .. 3) := (1, 1, 1);
      M : Model := Train (X, Y, 3);
   begin
      Check ("13.1 Predicts class 1 uniformly for x=1.0", Predict(M, (1 => 1.0)) = 1);
      Check ("13.2 Predicts class 1 uniformly for x=2.0", Predict(M, (1 => 2.0)) = 1);
      Check ("13.3 Predicts class 1 uniformly for x=3.0", Predict(M, (1 => 3.0)) = 1);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
