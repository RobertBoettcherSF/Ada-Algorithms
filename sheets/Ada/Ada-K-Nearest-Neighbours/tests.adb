with Ada.Text_IO; use Ada.Text_IO;
with Knn; use Knn;

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

   -- Standard Test Dataset
   Train_X : constant Feature_Matrix(1..5, 1..2) :=
     [[1.0, 1.0],
      [1.1, 1.1],
      [5.0, 5.0],
      [5.1, 5.1],
      [5.2, 5.2]];

   Train_Y_Class : constant Label_Vector(1..5) := [0, 0, 1, 1, 1];
   Train_Y_Reg   : constant Target_Vector(1..5) := [10.0, 11.0, 50.0, 51.0, 52.0];

   -- Distinct query scenarios
   Query_1 : constant Query_Vector(1..2) := [1.0, 1.0];
   Query_2 : constant Query_Vector(1..2) := [5.1, 5.1];
   Query_3 : constant Query_Vector(1..2) := [2.0, 2.0]; -- Point nearer to cluster 0 
   Query_4 : constant Query_Vector(1..2) := [4.0, 4.0]; -- Point nearer to cluster 1

   -- High dimensional dataset
   Train_X_High : constant Feature_Matrix(1..2, 1..4) :=
     [[0.0, 0.0, 0.0, 0.0],
      [1.0, 1.0, 1.0, 1.0]];
   Train_Y_High_Class : constant Label_Vector(1..2) := [0, 1];
   Train_Y_High_Reg   : constant Target_Vector(1..2) := [0.0, 100.0];
   Query_High : constant Query_Vector(1..4) := [0.1, 0.1, 0.1, 0.1];

   -- Exception testing datasets
   M_Empty     : constant Feature_Matrix (1 .. 0, 1 .. 2) := [others => [others => 0.0]];
   Y_Empty     : constant Label_Vector (1 .. 0) := [others => 0];
   Y_R_Empty   : constant Target_Vector (1 .. 0) := [others => 0.0];
   Q_Bad_Dim   : constant Query_Vector (1 .. 3) := [1.0, 2.0, 3.0];
   Y_Bad_Len   : constant Label_Vector (1 .. 4) := [0, 0, 1, 1];
   Y_R_Bad_Len : constant Target_Vector (1 .. 4) := [1.0, 2.0, 3.0, 4.0];
   Raised      : Boolean;

begin
   Put_Line ("TEST 1 - Basic Classification (K=1)");
   Check ("1.1 Direct match picks class 0", Predict_Classification(Train_X, Train_Y_Class, Query_1, 1) = 0);
   Check ("1.2 Direct match picks class 1", Predict_Classification(Train_X, Train_Y_Class, Query_2, 1) = 1);
   Check ("1.3 Proximity picks class 0", Predict_Classification(Train_X, Train_Y_Class, Query_3, 1) = 0);

   Put_Line ("TEST 2 - Basic Classification (K=3 Majority Vote)");
   Check ("2.1 Query matches cluster 0", Predict_Classification(Train_X, Train_Y_Class, Query_1, 3) = 0);
   Check ("2.2 Query matches cluster 1", Predict_Classification(Train_X, Train_Y_Class, Query_2, 3) = 1);
   Check ("2.3 Midpoint nearest cluster 1 votes class 1", Predict_Classification(Train_X, Train_Y_Class, Query_4, 3) = 1);

   Put_Line ("TEST 3 - Basic Regression (K=1 Uniform)");
   Check ("3.1 Exact match yields target 10.0", Predict_Regression(Train_X, Train_Y_Reg, Query_1, 1) = 10.0);
   Check ("3.2 Exact match yields target 51.0", Predict_Regression(Train_X, Train_Y_Reg, Query_2, 1) = 51.0);
   Check ("3.3 Exact match 5.2 yields 52.0", Predict_Regression(Train_X, Train_Y_Reg, [1..2 => 5.2], 1) = 52.0);

   Put_Line ("TEST 4 - Basic Regression (K=2 Average)");
   Check ("4.1 Average top 2 at cluster 0", Predict_Regression(Train_X, Train_Y_Reg, Query_3, 2) = 10.5);
   Check ("4.2 Average top 2 at cluster 1", Predict_Regression(Train_X, Train_Y_Reg, Query_2, 2) = 50.5);
   Check ("4.3 Average top 2 at point 5.0", Predict_Regression(Train_X, Train_Y_Reg, [1..2 => 5.0], 2) = 50.5);

   Put_Line ("TEST 5 - Weighted Classification (K=1)");
   Check ("5.1 Weighted exact match class 0", Predict_Weighted_Classification(Train_X, Train_Y_Class, Query_1, 1) = 0);
   Check ("5.2 Weighted exact match class 1", Predict_Weighted_Classification(Train_X, Train_Y_Class, Query_2, 1) = 1);
   Check ("5.3 Weighted midpoint class 1", Predict_Weighted_Classification(Train_X, Train_Y_Class, Query_4, 1) = 1);

   Put_Line ("TEST 6 - Weighted Classification (K=5 Voting Bias)");
   Check ("6.1 Extreme weight ensures class 0", Predict_Weighted_Classification(Train_X, Train_Y_Class, Query_1, 5) = 0);
   Check ("6.2 Extreme weight ensures class 1", Predict_Weighted_Classification(Train_X, Train_Y_Class, Query_2, 5) = 1);
   Check ("6.3 Weighted midpoint favors cluster 1", Predict_Weighted_Classification(Train_X, Train_Y_Class, Query_4, 5) = 1);

   Put_Line ("TEST 7 - Weighted Regression (Proximity dominance)");
   declare
      Val1 : constant Feature_Value := Predict_Weighted_Regression(Train_X, Train_Y_Reg, Query_1, 2);
      Val2 : constant Feature_Value := Predict_Weighted_Regression(Train_X, Train_Y_Reg, Query_2, 2);
      Val3 : constant Feature_Value := Predict_Weighted_Regression(Train_X, Train_Y_Reg, [1..2 => 5.2], 2);
   begin
      -- Exact matches cause extreme weights, drawing the average effectively to the target value
      Check ("7.1 Exact match query 1 dominates to ~10", abs(Val1 - 10.0) < 0.001);
      Check ("7.2 Exact match query 2 dominates to ~51", abs(Val2 - 51.0) < 0.001);
      Check ("7.3 Exact match query 3 dominates to ~52", abs(Val3 - 52.0) < 0.001);
   end;

   Put_Line ("TEST 8 - High Dimensional Data Classification");
   Check ("8.1 H-dim exact match K=1", Predict_Classification(Train_X_High, Train_Y_High_Class, Query_High, 1) = 0);
   Check ("8.2 H-dim resolves deterministic ties K=2", Predict_Classification(Train_X_High, Train_Y_High_Class, Query_High, 2) = 0);
   Check ("8.3 H-dim weighted classification resolves via closer point K=2", Predict_Weighted_Classification(Train_X_High, Train_Y_High_Class, Query_High, 2) = 0);

   Put_Line ("TEST 9 - High Dimensional Data Regression");
   Check ("9.1 H-dim strict match K=1", Predict_Regression(Train_X_High, Train_Y_High_Reg, Query_High, 1) = 0.0);
   Check ("9.2 H-dim naive average K=2", abs(Predict_Regression(Train_X_High, Train_Y_High_Reg, Query_High, 2) - 50.0) < 0.01);
   declare
      Weighted_Avg : constant Feature_Value := Predict_Weighted_Regression(Train_X_High, Train_Y_High_Reg, Query_High, 2);
   begin
      -- Point is closer to 0, so average should be heavily skewed away from 50 and towards 0
      Check ("9.3 H-dim weighted avg pulls closer to zero", Weighted_Avg < 11.0);
   end;

   Put_Line ("TEST 10 - Empty Dataset Exception Validation");
   Raised := False;
   begin
      if Predict_Classification (M_Empty, Y_Empty, Query_1, 1) = 0 then null; end if;
   exception
      when Empty_Dataset_Error => Raised := True;
      when others => null;
   end;
   Check ("10.1 Predict_Classification raises on empty", Raised);

   Raised := False;
   begin
      if Predict_Regression (M_Empty, Y_R_Empty, Query_1, 1) = 0.0 then null; end if;
   exception
      when Empty_Dataset_Error => Raised := True;
      when others => null;
   end;
   Check ("10.2 Predict_Regression raises on empty", Raised);

   Raised := False;
   begin
      if Predict_Weighted_Classification (M_Empty, Y_Empty, Query_1, 1) = 0 then null; end if;
   exception
      when Empty_Dataset_Error => Raised := True;
      when others => null;
   end;
   Check ("10.3 Predict_Weighted_Classification raises on empty", Raised);

   Put_Line ("TEST 11 - Invalid K Exception (K > Dataset Size)");
   Raised := False;
   begin
      if Predict_Classification (Train_X, Train_Y_Class, Query_1, 6) = 0 then null; end if;
   exception
      when Invalid_K_Error => Raised := True;
      when others => null;
   end;
   Check ("11.1 Predict_Classification catches excessive K", Raised);

   Raised := False;
   begin
      if Predict_Regression (Train_X, Train_Y_Reg, Query_1, 6) = 0.0 then null; end if;
   exception
      when Invalid_K_Error => Raised := True;
      when others => null;
   end;
   Check ("11.2 Predict_Regression catches excessive K", Raised);

   Raised := False;
   begin
      if Predict_Weighted_Regression (Train_X, Train_Y_Reg, Query_1, 6) = 0.0 then null; end if;
   exception
      when Invalid_K_Error => Raised := True;
      when others => null;
   end;
   Check ("11.3 Predict_Weighted_Regression catches excessive K", Raised);

   Put_Line ("TEST 12 - Dimension Mismatch Validation");
   Raised := False;
   begin
      if Predict_Classification (Train_X, Train_Y_Class, Q_Bad_Dim, 1) = 0 then null; end if;
   exception
      when Dimension_Mismatch_Error => Raised := True;
      when others => null;
   end;
   Check ("12.1 Classify identifies feature count mismatch", Raised);

   Raised := False;
   begin
      if Predict_Regression (Train_X, Train_Y_Reg, Q_Bad_Dim, 1) = 0.0 then null; end if;
   exception
      when Dimension_Mismatch_Error => Raised := True;
      when others => null;
   end;
   Check ("12.2 Regression identifies feature count mismatch", Raised);

   Raised := False;
   begin
      if Predict_Weighted_Classification (Train_X, Train_Y_Class, Q_Bad_Dim, 1) = 0 then null; end if;
   exception
      when Dimension_Mismatch_Error => Raised := True;
      when others => null;
   end;
   Check ("12.3 Weighted Classify identifies feature count mismatch", Raised);

   Put_Line ("TEST 13 - Row Count Mismatch Validation");
   Raised := False;
   begin
      if Predict_Classification (Train_X, Y_Bad_Len, Query_1, 1) = 0 then null; end if;
   exception
      when Length_Mismatch_Error => Raised := True;
      when others => null;
   end;
   Check ("13.1 Classify identifies differing lengths", Raised);

   Raised := False;
   begin
      if Predict_Regression (Train_X, Y_R_Bad_Len, Query_1, 1) = 0.0 then null; end if;
   exception
      when Length_Mismatch_Error => Raised := True;
      when others => null;
   end;
   Check ("13.2 Regression identifies differing lengths", Raised);

   Raised := False;
   begin
      if Predict_Weighted_Regression (Train_X, Y_R_Bad_Len, Query_1, 1) = 0.0 then null; end if;
   exception
      when Length_Mismatch_Error => Raised := True;
      when others => null;
   end;
   Check ("13.3 Weighted Regression identifies differing lengths", Raised);


   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
