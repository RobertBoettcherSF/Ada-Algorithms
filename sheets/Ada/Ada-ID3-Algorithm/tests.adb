with Ada.Text_IO; use Ada.Text_IO;
with ID3; use ID3;

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

   -- Helper to populate dataset
   procedure Setup_Dataset (Data : out Dataset; Set : out Attribute_Set) is
   begin
      Data.Clear;
      Set.Clear;
      Set.Insert (1);
      Set.Insert (2);
      Data.Append (Instance'(Num_Attributes => 2, Attributes => [1 => 1, 2 => 1], Class => 0));
      Data.Append (Instance'(Num_Attributes => 2, Attributes => [1 => 1, 2 => 2], Class => 0));
      Data.Append (Instance'(Num_Attributes => 2, Attributes => [1 => 2, 2 => 1], Class => 1));
      Data.Append (Instance'(Num_Attributes => 2, Attributes => [1 => 2, 2 => 2], Class => 1));
   end Setup_Dataset;

   -- T1
   procedure Test_1_Empty_Dataset is
      Empty_Data : Dataset;
      Attrs      : Attribute_Set;
      E1, E2, E3 : Boolean := False;
   begin
      Put_Line ("TEST 1 — Empty Dataset Exceptions");
      begin
         declare E : constant Metric_Value := Entropy (Empty_Data); pragma Unreferenced (E); begin null; end;
      exception
         when Empty_Dataset_Error => E1 := True;
      end;
      Check ("1.1 Entropy raises exception on empty dataset", E1);

      begin
         declare IG : constant Metric_Value := Information_Gain (Empty_Data, 1); pragma Unreferenced (IG); begin null; end;
      exception
         when Empty_Dataset_Error => E2 := True;
      end;
      Check ("1.2 Information_Gain raises exception on empty dataset", E2);

      begin
         declare T : constant Tree := Build_Tree (Empty_Data, Attrs); pragma Unreferenced (T); begin null; end;
      exception
         when Empty_Dataset_Error => E3 := True;
      end;
      Check ("1.3 Build_Tree raises exception on empty dataset", E3);
   end Test_1_Empty_Dataset;

   -- T2
   procedure Test_2_Homogeneous_Dataset is
      Data  : Dataset;
      Attrs : Attribute_Set;
      T     : Tree;
   begin
      Put_Line ("TEST 2 — Homogeneous Dataset Handling");
      Attrs.Insert (1);
      Data.Append (Instance'(Num_Attributes => 1, Attributes => [1 => 1], Class => 3));
      Data.Append (Instance'(Num_Attributes => 1, Attributes => [1 => 2], Class => 3));
      
      Check ("2.1 Entropy of single-class dataset is 0", abs (Entropy (Data)) < 0.001);
      
      T := Build_Tree (Data, Attrs);
      Check ("2.2 Builds Leaf node immediately", T.Kind = Leaf);
      Check ("2.3 Predicted class matches", T.Predicted_Class = 3);
      Free_Tree (T);
   end Test_2_Homogeneous_Dataset;

   -- T3
   procedure Test_3_Perfect_Split is
      Data  : Dataset;
      Attrs : Attribute_Set;
      Gain, Ratio : Metric_Value;
   begin
      Put_Line ("TEST 3 — Information Gain & Ratio Calculations");
      Setup_Dataset (Data, Attrs);
      Gain := Information_Gain (Data, 1);
      Ratio := Gain_Ratio (Data, 1);
      
      Check ("3.1 Entropy calculation correctness (1.0 for 50/50 split)", abs (Entropy (Data) - 1.0) < 0.001);
      Check ("3.2 Gain on perfect split attribute", abs (Gain - 1.0) < 0.001);
      Check ("3.3 Gain Ratio on perfect split", abs (Ratio - 1.0) < 0.001);
   end Test_3_Perfect_Split;

   -- T4
   procedure Test_4_Prediction_Valid_Data is
      Data  : Dataset;
      Attrs : Attribute_Set;
      T     : Tree;
      Inst1 : constant Instance := (Num_Attributes => 2, Attributes => [1 => 1, 2 => 1], Class => 0);
      Inst2 : constant Instance := (Num_Attributes => 2, Attributes => [1 => 2, 2 => 2], Class => 1);
   begin
      Put_Line ("TEST 4 — Standard Prediction");
      Setup_Dataset (Data, Attrs);
      T := Build_Tree (Data, Attrs);
      
      Check ("4.1 Decision tree root is well-formed", T.Kind = Decision);
      Check ("4.2 Correct prediction for instance 1 (Class 0)", Predict (T, Inst1) = 0);
      Check ("4.3 Correct prediction for instance 2 (Class 1)", Predict (T, Inst2) = 1);
      Free_Tree (T);
   end Test_4_Prediction_Valid_Data;

   -- T5
   procedure Test_5_Unseen_Value_Fallback is
      Data  : Dataset;
      Attrs : Attribute_Set;
      T     : Tree;
      Inst_Unseen : constant Instance := (Num_Attributes => 2, Attributes => [1 => 99, 2 => 1], Class => 0);
   begin
      Put_Line ("TEST 5 — Unseen Value Inference");
      Setup_Dataset (Data, Attrs);
      T := Build_Tree (Data, Attrs);
      
      Check ("5.1 Model successfully builds despite small data", T /= null);
      
      -- Attribute 1 has values 1 and 2 in training. Value 99 is unseen. 
      -- Should fallback to default class (majority of root: Class 0)
      Check ("5.2 Graceful predict on unseen categorical value", Predict (T, Inst_Unseen) = 0);
      
      -- Even entirely weird combo doesn't crash
      declare
         Weird : constant Instance := (Num_Attributes => 2, Attributes => [1 => 99, 2 => 99], Class => 0);
      begin
         Check ("5.3 Safely handles multiple unseen dimensions", Predict (T, Weird) = 0);
      end;
      Free_Tree (T);
   end Test_5_Unseen_Value_Fallback;

   -- T6
   procedure Test_6_Missing_Attribute_Errors is
      Data : Dataset;
      Attrs : Attribute_Set;
      Bad_Inst : constant Instance := (Num_Attributes => 1, Attributes => [1 => 1], Class => 0);
      E1, E2, E3 : Boolean := False;
   begin
      Put_Line ("TEST 6 — Invalid Data Integrity Check");
      Data.Append (Bad_Inst);
      -- Add a second instance of a different class to prevent early `All_Same => True` Leaf return bypass
      Data.Append (Instance'(Num_Attributes => 1, Attributes => [1 => 2], Class => 1)); 
      
      begin
         declare IG : constant Metric_Value := Information_Gain (Data, 2); pragma Unreferenced (IG); begin null; end;
      exception
         when Invalid_Data_Error => E1 := True;
      end;
      Check ("6.1 Info Gain catches out of bounds attribute index", E1);
      
      begin
         declare GR : constant Metric_Value := Gain_Ratio (Data, 2); pragma Unreferenced (GR); begin null; end;
      exception
         when Invalid_Data_Error => E2 := True;
      end;
      Check ("6.2 Gain Ratio catches out of bounds attribute index", E2);
      
      begin
         Attrs.Insert (2);
         declare T : constant Tree := Build_Tree (Data, Attrs); pragma Unreferenced (T); begin null; end;
      exception
         when Invalid_Data_Error => E3 := True;
      end;
      Check ("6.3 Build_Tree catches missing required attributes", E3);
   end Test_6_Missing_Attribute_Errors;

   -- T7
   procedure Test_7_Gain_Ratio_Zero_Intrinsic is
      Data  : Dataset;
      Ratio, Gain : Metric_Value;
   begin
      Put_Line ("TEST 7 — Gain Ratio edge case (Div by zero avoidance)");
      -- Create a dataset where all instances have the same value for the attribute
      Data.Append (Instance'(Num_Attributes => 1, Attributes => [1 => 5], Class => 0));
      Data.Append (Instance'(Num_Attributes => 1, Attributes => [1 => 5], Class => 1));
      
      Gain := Information_Gain (Data, 1);
      Ratio := Gain_Ratio (Data, 1);
      
      Check ("7.1 Entropy calculates correctly (> 0)", Entropy (Data) > 0.0);
      Check ("7.2 Gain calculates correctly (0.0)", abs (Gain) < 0.001);
      Check ("7.3 Ratio falls back to Gain cleanly (0.0)", abs (Ratio - Gain) < 0.001);
   end Test_7_Gain_Ratio_Zero_Intrinsic;

   -- T8
   procedure Test_8_Empty_Attributes_Set is
      Data  : Dataset;
      Attrs : Attribute_Set; -- Empty!
      T     : Tree;
   begin
      Put_Line ("TEST 8 — Exhausted Attributes handling");
      Setup_Dataset (Data, Attrs);
      Attrs.Clear; -- Deliberately exhaust
      
      T := Build_Tree (Data, Attrs);
      Check ("8.1 Returns leaf when attributes exhausted", T.Kind = Leaf);
      Check ("8.2 Predicted class is data majority", T.Predicted_Class = 0);
      
      Free_Tree (T);
      Check ("8.3 Tree safely deallocated", T = null);
   end Test_8_Empty_Attributes_Set;

   -- T9
   procedure Test_9_Tree_Properties is
      Data  : Dataset;
      Attrs : Attribute_Set;
      T     : Tree;
   begin
      Put_Line ("TEST 9 — Core Tree Structure");
      Setup_Dataset (Data, Attrs);
      T := Build_Tree (Data, Attrs);
      
      Check ("9.1 Root node is a Decision node", T.Kind = Decision);
      Check ("9.2 Split on attribute 1 (highest gain)", T.Attribute = 1);
      Check ("9.3 Has correct number of branch subsets", not T.Branches.Is_Empty);
      Free_Tree (T);
   end Test_9_Tree_Properties;

   -- T10
   procedure Test_10_Memory is
      Data  : Dataset;
      Attrs : Attribute_Set;
      T_Mem : Tree := null;
      
      -- Helper functions obscure the null-checks from local static flow analysis
      function Is_Allocated (Node : Tree) return Boolean is (Node /= null);
      function Is_Null (Node : Tree) return Boolean is (Node = null);
   begin
      Put_Line ("TEST 10 — Memory Management");
      Check ("10.1 Pointer is initially null", Is_Null (T_Mem));
      Setup_Dataset (Data, Attrs);
      T_Mem := Build_Tree (Data, Attrs);
      
      Check ("10.2 Tree successfully allocated", Is_Allocated (T_Mem));
      
      Free_Tree (T_Mem);
      Check ("10.3 Tree fully deallocated and nullified", Is_Null (T_Mem));
   end Test_10_Memory;

   -- T11
   procedure Test_11_Variant_Gain_Ratio is
      Data  : Dataset;
      Attrs : Attribute_Set;
      T     : Tree;
      Inst  : constant Instance := (Num_Attributes => 2, Attributes => [1 => 2, 2 => 1], Class => 1);
   begin
      Put_Line ("TEST 11 — Split Criterion: Use_Gain_Ratio variant");
      Setup_Dataset (Data, Attrs);
      
      T := Build_Tree (Data, Attrs, Criterion => Use_Gain_Ratio);
      Check ("11.1 Build_Tree succeeds with Gain Ratio", T /= null);
      Check ("11.2 Root is valid decision", T.Kind = Decision);
      Check ("11.3 Correct classification remains", Predict (T, Inst) = 1);
      Free_Tree (T);
   end Test_11_Variant_Gain_Ratio;

   -- T12
   procedure Test_12_Invalid_Model is
      Null_T : constant Tree := null;
      E1     : Boolean := False;
      Dummy_Inst : constant Instance := (Num_Attributes => 1, Attributes => [1 => 1], Class => 0);
      Leaf_T : Tree := new Tree_Node'(Kind => Leaf, Predicted_Class => 5);
   begin
      Put_Line ("TEST 12 — Invalid Model Evaluation");
      begin
         declare C : constant Class_ID := Predict (Null_T, Dummy_Inst); pragma Unreferenced (C); begin null; end;
      exception
         when Prediction_Error => E1 := True;
      end;
      Check ("12.1 Predict on null tree raises Prediction_Error", E1);
      Check ("12.2 Predict on pure Leaf succeeds directly", Predict (Leaf_T, Dummy_Inst) = 5);
      
      Free_Tree (Leaf_T);
      Check ("12.3 Freeing standalone leaf resolves gracefully", Leaf_T = null);
   end Test_12_Invalid_Model;

   -- T13
   procedure Test_13_Predict_Constraint_Violations is
      Data  : Dataset;
      Attrs : Attribute_Set;
      T     : Tree;
      E1    : Boolean := False;
      Bad_Inst : constant Instance := (Num_Attributes => 0, Attributes => [], Class => 0);
   begin
      Put_Line ("TEST 13 — Prediction Data Constraint Violations");
      Setup_Dataset (Data, Attrs);
      T := Build_Tree (Data, Attrs);
      
      begin
         declare C : constant Class_ID := Predict (T, Bad_Inst); pragma Unreferenced (C); begin null; end;
      exception
         when Invalid_Data_Error => E1 := True;
      end;
      
      Check ("13.1 Predict raises Invalid_Data_Error when instance lacks attribute", E1);
      Check ("13.2 Dataset verification (valid instance passes)", Predict (T, Data.First_Element) = 0);
      Check ("13.3 Tree integrity remains uncorrupted", T.Kind = Decision);
      Free_Tree (T);
   end Test_13_Predict_Constraint_Violations;

   -- T14
   procedure Test_14_Majority_Logic is
      Data  : Dataset;
      Attrs : Attribute_Set;
      T     : Tree;
   begin
      Put_Line ("TEST 14 — Majority Class Bias Inference");
      Data.Append (Instance'(Num_Attributes => 1, Attributes => [1 => 1], Class => 2));
      Data.Append (Instance'(Num_Attributes => 1, Attributes => [1 => 2], Class => 2));
      Data.Append (Instance'(Num_Attributes => 1, Attributes => [1 => 3], Class => 5));
      -- Class 2 is majority
      
      T := Build_Tree (Data, Attrs); -- empty attrs
      
      Check ("14.1 Entropy reflects non-pure data (> 0.0)", Entropy (Data) > 0.0);
      Check ("14.2 Returns leaf on exhausted attributes", T.Kind = Leaf);
      Check ("14.3 Leaf class properly selects majority (2)", T.Predicted_Class = 2);
      Free_Tree (T);
   end Test_14_Majority_Logic;

begin
   Test_1_Empty_Dataset;
   Test_2_Homogeneous_Dataset;
   Test_3_Perfect_Split;
   Test_4_Prediction_Valid_Data;
   Test_5_Unseen_Value_Fallback;
   Test_6_Missing_Attribute_Errors;
   Test_7_Gain_Ratio_Zero_Intrinsic;
   Test_8_Empty_Attributes_Set;
   Test_9_Tree_Properties;
   Test_10_Memory;
   Test_11_Variant_Gain_Ratio;
   Test_12_Invalid_Model;
   Test_13_Predict_Constraint_Violations;
   Test_14_Majority_Logic;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
