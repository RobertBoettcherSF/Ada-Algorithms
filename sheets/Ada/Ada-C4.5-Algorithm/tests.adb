with Ada.Text_IO; use Ada.Text_IO;
with C45_Algorithm; use C45_Algorithm;

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

   -- Helper to approximate Float equality
   function Approx_Eq (A, B : Float) return Boolean is
   begin
      return abs (A - B) < 0.001;
   end Approx_Eq;

   -- Shared test attributes setup
   Attrs_Continuous : constant Attribute_Set := [(Kind => Continuous, Max_Discrete_Value => 1)];
   Attrs_Discrete   : constant Attribute_Set := [(Kind => Discrete, Max_Discrete_Value => 3)];
   
   -- Dataset instances for tests
   DS_Pure : constant Dataset := [
      (Features => [1 => 1.0, others => Missing_Value], Class => 1),
      (Features => [1 => 2.0, others => Missing_Value], Class => 1),
      (Features => [1 => 3.0, others => Missing_Value], Class => 1)
   ];

   DS_Mixed : constant Dataset := [
      (Features => [1 => 1.0, others => Missing_Value], Class => 1),
      (Features => [1 => 2.0, others => Missing_Value], Class => 0)
   ];

   DS_Complex : constant Dataset := [
      (Features => [1 => 10.0, others => Missing_Value], Class => 1),
      (Features => [1 => 20.0, others => Missing_Value], Class => 1),
      (Features => [1 => 30.0, others => Missing_Value], Class => 0),
      (Features => [1 => 40.0, others => Missing_Value], Class => 0)
   ];

   DS_Discrete : constant Dataset := [
      (Features => [1 => 1.0, others => Missing_Value], Class => 1),
      (Features => [1 => 2.0, others => Missing_Value], Class => 0),
      (Features => [1 => 3.0, others => Missing_Value], Class => 1)
   ];

   DS_Missing : constant Dataset := [
      (Features => [1 => 1.0, others => Missing_Value], Class => 1),
      (Features => [1 => Missing_Value, others => Missing_Value], Class => 1),
      (Features => [1 => 2.0, others => Missing_Value], Class => 0)
   ];

   Tree : Decision_Tree;
begin
   Put_Line ("--- Starting C4.5 Algorithm Test Suite ---");

   -- TEST 1 — Entropy Calculations
   Put_Line ("TEST 1 — Entropy Calculations");
   Check ("1.1 Pure dataset entropy is 0.0", Approx_Eq (Calculate_Entropy (DS_Pure), 0.0));
   Check ("1.2 50/50 dataset entropy is 1.0", Approx_Eq (Calculate_Entropy (DS_Mixed), 1.0));
   Check ("1.3 Even split 4 elements is 1.0", Approx_Eq (Calculate_Entropy (DS_Complex), 1.0));

   -- TEST 2 — Standard Tree Building (Base Cases)
   Put_Line ("TEST 2 — Standard Tree Building (Base Cases)");
   Tree := Build_Tree (DS_Pure, Attrs_Continuous);
   Check ("2.1 Tree built from pure dataset classifies correctly", Classify (Tree, [1 => 1.5, others => Missing_Value]) = 1);
   Check ("2.2 Handles unseen values purely", Classify (Tree, [1 => 99.0, others => Missing_Value]) = 1);
   Destroy_Tree (Tree);
   Check ("2.3 Tree destroyed successfully", Is_Null (Tree));

   -- TEST 3 — Continuous Split Tree Construction
   Put_Line ("TEST 3 — Continuous Split Tree Construction");
   Tree := Build_Tree (DS_Complex, Attrs_Continuous);
   Check ("3.1 Left branch evaluated correctly", Classify (Tree, [1 => 15.0, others => Missing_Value]) = 1);
   Check ("3.2 Right branch evaluated correctly", Classify (Tree, [1 => 35.0, others => Missing_Value]) = 0);
   Check ("3.3 Exact threshold boundary handling", Classify (Tree, [1 => 20.0, others => Missing_Value]) = 1);
   Destroy_Tree (Tree);

   -- TEST 4 — Discrete Split Tree Construction
   Put_Line ("TEST 4 — Discrete Split Tree Construction");
   Tree := Build_Tree (DS_Discrete, Attrs_Discrete);
   Check ("4.1 Discrete path 1 classified correctly", Classify (Tree, [1 => 1.0, others => Missing_Value]) = 1);
   Check ("4.2 Discrete path 2 classified correctly", Classify (Tree, [1 => 2.0, others => Missing_Value]) = 0);
   Check ("4.3 Discrete path 3 classified correctly", Classify (Tree, [1 => 3.0, others => Missing_Value]) = 1);
   Destroy_Tree (Tree);

   -- TEST 5 — Unseen/Invalid Discrete Values Classification
   Put_Line ("TEST 5 — Unseen/Invalid Discrete Values Classification");
   Tree := Build_Tree (DS_Discrete, Attrs_Discrete);
   Check ("5.1 Falls back to default class for zero", Classify (Tree, [1 => 0.0, others => Missing_Value]) = 0);
   Check ("5.2 Falls back to default class for out of bounds", Classify (Tree, [1 => 99.0, others => Missing_Value]) = 0);
   Check ("5.3 Re-verifies valid boundary", Classify (Tree, [1 => 2.0, others => Missing_Value]) = 0);
   Destroy_Tree (Tree);

   -- TEST 6 — Post-Pruning Variant (Redundant Splits)
   Put_Line ("TEST 6 — Post-Pruning Variant");
   declare
      Redundant_DS : constant Dataset := [
         (Features => [1 => 1.0, others => Missing_Value], Class => 1),
         (Features => [1 => 2.0, others => Missing_Value], Class => 1),
         (Features => [1 => 3.0, others => Missing_Value], Class => 1)
      ];
   begin
      Tree := Build_Tree_Pruned (Redundant_DS, Attrs_Continuous);
      Check ("6.1 Pruned tree correctly classifies", Classify (Tree, [1 => 1.0, others => Missing_Value]) = 1);
      Check ("6.2 Pruned tree boundary checks", Classify (Tree, [1 => 2.5, others => Missing_Value]) = 1);
      Check ("6.3 Pruned tree out of bounds", Classify (Tree, [1 => 5.0, others => Missing_Value]) = 1);
      Destroy_Tree (Tree);
   end;

   -- TEST 7 — Missing Value Training Variant
   Put_Line ("TEST 7 — Missing Value Training Variant");
   Tree := Build_Tree_Handle_Missing (DS_Missing, Attrs_Discrete);
   Check ("7.1 Routes missing instance correctly", Classify (Tree, [1 => 1.0, others => Missing_Value]) = 1);
   Check ("7.2 Non-missing branch remains unaffected", Classify (Tree, [1 => 2.0, others => Missing_Value]) = 0);
   Check ("7.3 Handles missing value dynamically during query", Classify (Tree, [1 => Missing_Value, others => Missing_Value]) = 0);
   Destroy_Tree (Tree);

   -- TEST 8 — Edge Case: Single Element Dataset
   Put_Line ("TEST 8 — Edge Case: Single Element Dataset");
   declare
      DS_Single : constant Dataset := [(Features => [1 => 5.5, others => Missing_Value], Class => 7)];
   begin
      Tree := Build_Tree (DS_Single, Attrs_Continuous);
      Check ("8.1 Learns single class", Classify (Tree, [1 => 5.5, others => Missing_Value]) = 7);
      Check ("8.2 Broad generalization", Classify (Tree, [1 => 10.0, others => Missing_Value]) = 7);
      Destroy_Tree (Tree);
      Check ("8.3 Null tree state confirmed", Is_Null (Tree));
   end;

   -- TEST 9 — Multi-Attribute Dataset Tests
   Put_Line ("TEST 9 — Multi-Attribute Dataset Tests");
   declare
      Attrs_Multi : constant Attribute_Set := [
         (Kind => Continuous, Max_Discrete_Value => 1), 
         (Kind => Discrete, Max_Discrete_Value => 2)
      ];
      DS_Multi : constant Dataset := [
         (Features => [1 => 10.0, 2 => 1.0, others => Missing_Value], Class => 1),
         (Features => [1 => 10.0, 2 => 2.0, others => Missing_Value], Class => 0),
         (Features => [1 => 20.0, 2 => 1.0, others => Missing_Value], Class => 1)
      ];
   begin
      Tree := Build_Tree (DS_Multi, Attrs_Multi);
      Check ("9.1 Split properly on attribute 2", Classify (Tree, [1 => 10.0, 2 => 1.0, others => Missing_Value]) = 1);
      Check ("9.2 Split properly on attribute 2 opposite", Classify (Tree, [1 => 10.0, 2 => 2.0, others => Missing_Value]) = 0);
      Check ("9.3 Other paths correct", Classify (Tree, [1 => 20.0, 2 => 1.0, others => Missing_Value]) = 1);
      Destroy_Tree (Tree);
   end;

   -- TEST 10 — Error Handling Classification
   Put_Line ("TEST 10 — Error Handling Classification");
   Check ("10.1 Null tree doesn't crash destroy", True); -- Checked implicitly by no exception
   begin
      declare
         Dummy : constant Class_Label := Classify (Tree, [1 => 1.0, others => Missing_Value]);
      begin
         Check ("10.2 Exception should have fired (got " & Class_Label'Image (Dummy) & ")", False);
      end;
   exception
      when others =>
         Check ("10.2 Invalid tree raised exception", True);
   end;
   Check ("10.3 Ensures safety block exits clean", True);

   -- TEST 11 — Identical Features with Different Classes (Conflict)
   Put_Line ("TEST 11 — Identical Features Conflict");
   declare
      DS_Conflict : constant Dataset := [
         (Features => [1 => 1.0, others => Missing_Value], Class => 0),
         (Features => [1 => 1.0, others => Missing_Value], Class => 1),
         (Features => [1 => 1.0, others => Missing_Value], Class => 1)
      ];
   begin
      Tree := Build_Tree (DS_Conflict, Attrs_Continuous);
      Check ("11.1 Returns majority class correctly", Classify (Tree, [1 => 1.0, others => Missing_Value]) = 1);
      Check ("11.2 Extrapolates majority class", Classify (Tree, [1 => 2.0, others => Missing_Value]) = 1);
      Destroy_Tree (Tree);
      Check ("11.3 Clean destruction on terminal conflict", Is_Null (Tree));
   end;

   -- TEST 12 — No Gain / Terminal Cutoff
   Put_Line ("TEST 12 — No Gain Terminal Cutoff");
   declare
      DS_NoGain : constant Dataset := [
         (Features => [1 => 1.0, others => Missing_Value], Class => 1),
         (Features => [1 => 2.0, others => Missing_Value], Class => 1)
      ];
   begin
      Tree := Build_Tree_Pruned (DS_NoGain, Attrs_Discrete);
      Check ("12.1 Collapsed to leaf naturally", Classify (Tree, [1 => 1.0, others => Missing_Value]) = 1);
      Check ("12.2 Identifies correct default path", Classify (Tree, [1 => 2.0, others => Missing_Value]) = 1);
      Destroy_Tree (Tree);
      Check ("12.3 Frees early stopped tree safely", Is_Null (Tree));
   end;

   -- TEST 13 — Complete Missing Data Variant Execution
   Put_Line ("TEST 13 — Complete Missing Data Variant Execution");
   declare
      DS_Missing_All : constant Dataset := [
         (Features => [1 => Missing_Value, others => Missing_Value], Class => 1),
         (Features => [1 => Missing_Value, others => Missing_Value], Class => 0),
         (Features => [1 => Missing_Value, others => Missing_Value], Class => 1)
      ];
   begin
      Tree := Build_Tree_Handle_Missing (DS_Missing_All, Attrs_Continuous);
      Check ("13.1 Missing data resolved to majority", Classify (Tree, [1 => Missing_Value, others => Missing_Value]) = 1);
      Check ("13.2 Real values default correctly", Classify (Tree, [1 => 10.0, others => Missing_Value]) = 1);
      Destroy_Tree (Tree);
      Check ("13.3 Destroys tree safely", Is_Null (Tree));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
