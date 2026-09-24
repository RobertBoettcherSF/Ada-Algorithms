with Ada.Text_IO; use Ada.Text_IO;
with One_Attribute_Rule; use One_Attribute_Rule;

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
   -- TEST 1 - Basic Model Training and Prediction
   Put_Line ("TEST 1 - Basic Model Perfect Predictor");
   declare
      D : constant Dataset :=
        (Num_Instances => 4, Num_Attributes => 2,
         Grid => [1 => [1 => 1, 2 => 0],
                  2 => [1 => 1, 2 => 1],
                  3 => [1 => 0, 2 => 0],
                  4 => [1 => 0, 2 => 1]],
         Classes => [1 => 1, 2 => 1, 3 => 0, 4 => 0]);
      M : constant Basic_Model := Train_Basic (D);
      P1 : constant Class_Label := Predict_Basic (M, Attribute_Array'[1 => 1, 2 => 0]);
      P2 : constant Class_Label := Predict_Basic (M, Attribute_Array'[1 => 0, 2 => 1]);
   begin
      Check ("1.1 Best attribute chosen correctly", M.Best_Attribute = 1);
      Check ("1.2 Optimal total error evaluates to 0", M.Total_Error = 0);
      Check ("1.3 Correct prediction mapping for value 1", P1 = 1);
      Check ("1.4 Correct prediction mapping for value 0", P2 = 0);
   end;

   -- TEST 2 - Robust Model Default Class Selection
   Put_Line ("TEST 2 - Robust Model Default Class Selection");
   declare
      D : constant Dataset :=
        (Num_Instances => 5, Num_Attributes => 1,
         Grid => [1 => [1 => 1],
                  2 => [1 => 1],
                  3 => [1 => 2],
                  4 => [1 => 3],
                  5 => [1 => 3]],
         Classes => [1 => 7, 2 => 7, 3 => 8, 4 => 7, 5 => 9]);
      M : constant Robust_Model := Train_Robust (D);
   begin
      Check ("2.1 Valid attribute isolated", M.Best_Attribute = 1);
      Check ("2.2 Global majority identifies correctly as 7", M.Default_Class = 7);
      Check ("2.3 Matches standard rule set", Predict_Robust(M, Attribute_Array'[1 => 2]) = 8);
   end;

   -- TEST 3 - Unseen Value Handling: Basic Model Exception
   Put_Line ("TEST 3 - Unseen Value Handling: Basic Model Exception");
   declare
      D : constant Dataset :=
        (Num_Instances => 2, Num_Attributes => 1,
         Grid => [1 => [1 => 1], 2 => [1 => 2]],
         Classes => [1 => 10, 2 => 20]);
      M : constant Basic_Model := Train_Basic (D);
      Caught : Boolean := False;
   begin
      begin
         if Predict_Basic (M, Attribute_Array'[1 => 3]) = 10 then
            null;
         end if;
      exception
         when Unseen_Value_Error => Caught := True;
      end;
      Check ("3.1 Model successfully builds internal rules", M.Num_Rules = 2);
      Check ("3.2 Safe usage preserves existing values", Predict_Basic(M, Attribute_Array'[1 => 1]) = 10);
      Check ("3.3 Out of domain attributes enforce strong typing limit", Caught);
   end;

   -- TEST 4 - Unseen Value Handling: Robust Model Fallback
   Put_Line ("TEST 4 - Unseen Value Handling: Robust Model Fallback");
   declare
      D : constant Dataset :=
        (Num_Instances => 3, Num_Attributes => 1,
         Grid => [1 => [1 => 1], 2 => [1 => 1], 3 => [1 => 2]],
         Classes => [1 => 5, 2 => 5, 3 => 6]);
      M : constant Robust_Model := Train_Robust (D);
   begin
      Check ("4.1 Default class falls back to 5", M.Default_Class = 5);
      Check ("4.2 Fallback behaves functionally for value 3", Predict_Robust (M, Attribute_Array'[1 => 3]) = 5);
      Check ("4.3 Fallback guarantees no exceptions out of bounds", Predict_Robust (M, Attribute_Array'[1 => 99]) = 5);
   end;

   -- TEST 5 - Tie Breaking Attributes Index Resolution
   Put_Line ("TEST 5 - Tie Breaking Attributes Index Resolution");
   declare
      D : constant Dataset :=
        (Num_Instances => 4, Num_Attributes => 3,
         Grid => [1 => [1 => 1, 2 => 2, 3 => 0],
                  2 => [1 => 1, 2 => 2, 3 => 0],
                  3 => [1 => 0, 2 => 1, 3 => 0],
                  4 => [1 => 0, 2 => 1, 3 => 0]],
         Classes => [1 => 1, 2 => 1, 3 => 0, 4 => 0]);
      M : constant Basic_Model := Train_Basic (D);
   begin
      Check ("5.1 Earlier attribute indexed on conflict", M.Best_Attribute = 1);
      Check ("5.2 Zero error derived mathematically", M.Total_Error = 0);
      Check ("5.3 Prediction logic executes safely", Predict_Basic (M, Attribute_Array'[1=>1, 2=>2, 3=>0]) = 1);
   end;

   -- TEST 6 - Tie Breaking Inner Classification Rules
   Put_Line ("TEST 6 - Tie Breaking Inner Classification Rules");
   declare
      D : constant Dataset :=
        (Num_Instances => 4, Num_Attributes => 1,
         Grid => [1 => [1 => 1], 2 => [1 => 1], 3 => [1 => 1], 4 => [1 => 1]],
         Classes => [1 => 3, 2 => 3, 3 => 2, 4 => 2]);
      M : constant Basic_Model := Train_Basic (D);
   begin
      Check ("6.1 Unified subset rule reduction", M.Num_Rules = 1);
      Check ("6.2 Max conflict equals total instances minus resolved", M.Total_Error = 2);
      Check ("6.3 Identifies logically smaller class constraint", Predict_Basic (M, Attribute_Array'[1 => 1]) = 2);
   end;

   -- TEST 7 - Single Instance Dataset Geometry
   Put_Line ("TEST 7 - Single Instance Dataset Geometry");
   declare
      D : constant Dataset :=
        (Num_Instances => 1, Num_Attributes => 5,
         Grid => [1 => [1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5]],
         Classes => [1 => 42]);
      M : constant Robust_Model := Train_Robust (D);
   begin
      Check ("7.1 Minimum array evaluation anchors 1", M.Best_Attribute = 1);
      Check ("7.2 Impossible internal conflicts evaluate 0 error", M.Total_Error = 0);
      Check ("7.3 Trivial majority calculation evaluates securely", M.Default_Class = 42);
      Check ("7.4 Data validation maps output seamlessly", Predict_Robust (M, Attribute_Array'[1=>1, 2=>2, 3=>3, 4=>4, 5=>5]) = 42);
   end;

   -- TEST 8 - Constant Attribute Bypass Handling
   Put_Line ("TEST 8 - Constant Attribute Bypass Handling");
   declare
      D : constant Dataset :=
        (Num_Instances => 3, Num_Attributes => 2,
         Grid => [1 => [1 => 1, 2 => 0],
                  2 => [1 => 1, 2 => 1],
                  3 => [1 => 1, 2 => 2]],
         Classes => [1 => 9, 2 => 9, 3 => 9]);
      M : constant Basic_Model := Train_Basic (D);
   begin
      Check ("8.1 Bypass forces priority index 1", M.Best_Attribute = 1);
      Check ("8.2 Error calculation retains integrity globally", M.Total_Error = 0);
      Check ("8.3 Accurate class return mapping", Predict_Basic (M, Attribute_Array'[1 => 1, 2 => 0]) = 9);
   end;

   -- TEST 9 - Worst Case (High Error Classification)
   Put_Line ("TEST 9 - Worst Case (High Error Classification)");
   declare
      D : constant Dataset :=
        (Num_Instances => 4, Num_Attributes => 1,
         Grid => [1 => [1 => 0], 2 => [1 => 0], 3 => [1 => 0], 4 => [1 => 0]],
         Classes => [1 => 1, 2 => 2, 3 => 3, 4 => 4]);
      M : constant Robust_Model := Train_Robust (D);
   begin
      Check ("9.1 Default limits itself algorithmically", M.Default_Class = 1);
      Check ("9.2 Maximum permutation bounds error evaluates to 3", M.Total_Error = 3);
      Check ("9.3 Target fallback maintains consistent minimum label", Predict_Robust (M, Attribute_Array'[1 => 0]) = 1);
   end;

   -- TEST 10 - Diverse Multi-Value Complexity
   Put_Line ("TEST 10 - Diverse Multi-Value Complexity");
   declare
      D : constant Dataset :=
        (Num_Instances => 6, Num_Attributes => 2,
         Grid => [1 => [1 => 0, 2 => 1],
                  2 => [1 => 0, 2 => 1],
                  3 => [1 => 1, 2 => 2],
                  4 => [1 => 1, 2 => 2],
                  5 => [1 => 2, 2 => 3],
                  6 => [1 => 2, 2 => 3]],
         Classes => [1 => 10, 2 => 10, 3 => 20, 4 => 20, 5 => 30, 6 => 20]);
      M : constant Basic_Model := Train_Basic (D);
   begin
      Check ("10.1 Uniform distribution prioritizes sequentially", M.Best_Attribute = 1);
      Check ("10.2 Discovered isolated anomaly (Error 1)", M.Total_Error = 1);
      Check ("10.3 Resolves subset tiebreaker strictly correctly", Predict_Basic (M, Attribute_Array'[1 => 2, 2 => 3]) = 20);
   end;

   -- TEST 11 - Robust Model Complete Branch Traversals
   Put_Line ("TEST 11 - Robust Model Complete Branch Traversals");
   declare
      D : constant Dataset :=
        (Num_Instances => 3, Num_Attributes => 1,
         Grid => [1 => [1 => 1], 2 => [1 => 2], 3 => [1 => 3]],
         Classes => [1 => 5, 2 => 5, 3 => 6]);
      M : constant Robust_Model := Train_Robust (D);
   begin
      Check ("11.1 Isolates valid macro default label", M.Default_Class = 5);
      Check ("11.2 Evaluates mapped instance target", Predict_Robust (M, Attribute_Array'[1 => 1]) = 5);
      Check ("11.3 Distinguishes separate inner rule cleanly", Predict_Robust (M, Attribute_Array'[1 => 3]) = 6);
      Check ("11.4 Bypasses array completely for missing domains", Predict_Robust (M, Attribute_Array'[1 => 4]) = 5);
   end;
   
   -- TEST 12 - Large Loop Performance / Data Verification
   Put_Line ("TEST 12 - Large Loop Performance / Data Verification");
   declare
      D : Dataset (Num_Instances => 100, Num_Attributes => 2);
   begin
      for I in 1 .. 100 loop
         D.Grid (I, 1) := Attribute_Value (I mod 2); 
         D.Grid (I, 2) := 0;      
         D.Classes (I) := Class_Label (I mod 2);
      end loop;
      
      declare
         M : constant Basic_Model := Train_Basic (D);
      begin
         Check ("12.1 Safely processes heavy grid volume correctly", M.Best_Attribute = 1);
         Check ("12.2 Maintains math structure mapping linearly", M.Total_Error = 0);
         Check ("12.3 Resolves modulo label 0 optimally", Predict_Basic (M, Attribute_Array'[1 => 0, 2 => 0]) = 0);
         Check ("12.4 Resolves modulo label 1 optimally", Predict_Basic (M, Attribute_Array'[1 => 1, 2 => 0]) = 1);
      end;
   end;

   -- TEST 13 - Independent Cross-Overriding
   Put_Line ("TEST 13 - Independent Cross-Overriding");
   declare
      D : constant Dataset :=
        (Num_Instances => 7, Num_Attributes => 1,
         Grid => [1 => [1 => 1], 2 => [1 => 1], 3 => [1 => 2],
                  4 => [1 => 2], 5 => [1 => 2], 6 => [1 => 3], 7 => [1 => 3]],
         Classes => [1 => 9, 2 => 9, 3 => 8, 4 => 8, 5 => 8, 6 => 7, 7 => 7]);
      M : constant Robust_Model := Train_Robust (D);
   begin
      Check ("13.1 Selects independent subset majority globally", M.Default_Class = 8);
      Check ("13.2 Restricts internal rule precedence accurately", Predict_Robust (M, Attribute_Array'[1 => 1]) = 9);
      Check ("13.3 Matches tertiary subset dynamically", Predict_Robust (M, Attribute_Array'[1 => 3]) = 7);
      Check ("13.4 Identifies absence and overrides accurately", Predict_Robust (M, Attribute_Array'[1 => 4]) = 8);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
