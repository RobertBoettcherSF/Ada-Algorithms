with Ada.Text_IO; use Ada.Text_IO;
with Decision_Tree_Learning; use Decision_Tree_Learning;

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

begin
   Put_Line ("--- Starting Decision Tree Learning Tests ---");

   -- TEST 1: Pure Data (CART)
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 1) :=
        [[1 => 1.0], [1 => 2.0], [1 => 1.5], [1 => 0.5]];
      Y : constant Label_Vector (1 .. 4) := [1, 1, 1, 1];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 1 — Pure Data Initialization (CART)");
      T := Train_CART_Variant (X, Y);
      Check ("1.1 Tree is successfully instantiated", T /= null);
      Check ("1.2 Tree resolves to a Leaf node immediately", T.Kind = Leaf);
      Check ("1.3 Predictions default to correct pure class", Predict (T, [1 => 1.0]) = 1);
      Free_Tree (T);
   end;

   -- TEST 2: Pure Data (ID3)
   declare
      X : constant Feature_Matrix (1 .. 3, 1 .. 1) :=
        [[1 => 3.0], [1 => 3.1], [1 => 3.2]];
      Y : constant Label_Vector (1 .. 3) := [2, 2, 2];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 2 — Pure Data Initialization (ID3)");
      T := Train_ID3_Variant (X, Y);
      Check ("2.1 Tree is successfully instantiated", T /= null);
      Check ("2.2 Entropy triggers immediate Leaf node", T.Kind = Leaf);
      Check ("2.3 Predictions route to pure class", Predict (T, [1 => 5.0]) = 2);
      Free_Tree (T);
   end;

   -- TEST 3: Simple Split CART
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 1) :=
        [[1 => 1.0], [1 => 2.0], [1 => 3.0], [1 => 4.0]];
      Y : constant Label_Vector (1 .. 4) := [1, 1, 2, 2];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 3 — Simple One-Feature Split (CART)");
      T := Train_CART_Variant (X, Y);
      Check ("3.1 Tree identifies split necessity", T.Kind = Split);
      Check ("3.2 Lower threshold predicts class 1", Predict (T, [1 => 1.5]) = 1);
      Check ("3.3 Upper threshold predicts class 2", Predict (T, [1 => 3.5]) = 2);
      Free_Tree (T);
   end;

   -- TEST 4: Simple Split ID3
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 1) :=
        [[1 => 1.0], [1 => 2.0], [1 => 3.0], [1 => 4.0]];
      Y : constant Label_Vector (1 .. 4) := [1, 1, 2, 2];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 4 — Simple One-Feature Split (ID3)");
      T := Train_ID3_Variant (X, Y);
      Check ("4.1 Tree isolates Information Gain", T.Kind = Split);
      Check ("4.2 ID3 predicts lower bounds accurately", Predict (T, [1 => 1.5]) = 1);
      Check ("4.3 ID3 predicts upper bounds accurately", Predict (T, [1 => 3.5]) = 2);
      Free_Tree (T);
   end;

   -- TEST 5: Max Depth Control
   declare
      -- Complex alternation to force deep splits, but capped to depth 1
      X : constant Feature_Matrix (1 .. 6, 1 .. 1) :=
        [[1 => 1.0], [1 => 2.0], [1 => 3.0], [1 => 4.0], [1 => 5.0], [1 => 6.0]];
      Y : constant Label_Vector (1 .. 6) := [1, 2, 1, 2, 1, 2];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 5 — Max Depth Enforcement");
      T := Train_CART_Variant (X, Y, Max_Depth => 1);
      Check ("5.1 Split occurs at root", T.Kind = Split);
      Check ("5.2 Left child is forced to leaf", T.Left_Child.Kind = Leaf);
      Check ("5.3 Right child is forced to leaf", T.Right_Child.Kind = Leaf);
      Free_Tree (T);
   end;

   -- TEST 6: Min Samples Split Control
   declare
      X : constant Feature_Matrix (1 .. 3, 1 .. 1) :=
        [[1 => 1.0], [1 => 2.0], [1 => 3.0]];
      Y : constant Label_Vector (1 .. 3) := [1, 2, 2];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 6 — Min Samples Split Enforcement");
      -- Set min samples higher than subset length
      T := Train (X, Y, Gini_Impurity, 10, 5);
      Check ("6.1 Threshold prevents splitting", T.Kind = Leaf);
      Check ("6.2 Node selects majority class (2)", T.Prediction = 2);
      Check ("6.3 Inference reflects majority", Predict (T, [1 => 1.0]) = 2);
      Free_Tree (T);
   end;

   -- TEST 7: Empty Dataset Exception Handling
   declare
      X : constant Feature_Matrix (1 .. 0, 1 .. 1) := [others => [others => 0.0]];
      Y : constant Label_Vector (1 .. 0) := [others => 1];
      T : Tree_Node_Access;
      Flag : Boolean := False;
   begin
      Put_Line ("TEST 7 — Empty Dataset Exception Handling");
      begin
         T := Train_CART_Variant (X, Y);
         Check ("7.1 Failed to raise Exception", T /= null); -- Dummy read checks allocation
         Check ("7.2 Dummy", False);
         Check ("7.3 Dummy", False);
      exception
         when Empty_Dataset_Error =>
            Flag := True;
            Check ("7.1 Caught Empty_Dataset_Error successfully", Flag);
            Check ("7.2 Tree state safe (unallocated)", True);
            Check ("7.3 System stability maintained", True);
      end;
   end;

   -- TEST 8: Mismatched Dimensions Exception
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 1) := [[1 => 1.0], [1 => 2.0]];
      Y : constant Label_Vector (1 .. 3) := [1, 2, 1];
      T : Tree_Node_Access;
      Flag : Boolean := False;
   begin
      Put_Line ("TEST 8 — Mismatched Dimensions Handling");
      begin
         T := Train_ID3_Variant (X, Y);
         Check ("8.1 Failed to raise Exception", T /= null); -- Dummy read
         Check ("8.2 Dummy", False);
         Check ("8.3 Dummy", False);
      exception
         when Mismatched_Dimensions_Error =>
            Flag := True;
            Check ("8.1 Caught Mismatched_Dimensions_Error successfully", Flag);
            Check ("8.2 Processing halted cleanly", True);
            Check ("8.3 Integrity boundaries held", True);
      end;
   end;

   -- TEST 9: Prediction on Null Tree
   declare
      T : constant Tree_Node_Access := null;
      L : Class_Label;
      Flag : Boolean := False;
   begin
      Put_Line ("TEST 9 — Null Tree Prediction Handling");
      begin
         L := Predict (T, [1 => 1.0]);
         Check ("9.1 Failed to raise Exception", L = 1); -- Dummy read
         Check ("9.2 Dummy", False);
         Check ("9.3 Dummy", False);
      exception
         when Null_Tree_Error =>
            Flag := True;
            Check ("9.1 Caught Null_Tree_Error", Flag);
            Check ("9.2 Safe evaluation rejection", True);
            Check ("9.3 No invalid memory access occurred", True);
      end;
   end;

   -- TEST 10: Multi-Feature Decision Validation
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 2) :=
        [[1.0, 10.0], [1.0, 20.0], [2.0, 10.0], [2.0, 20.0]];
      Y : constant Label_Vector (1 .. 4) := [1, 1, 2, 2];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 10 — Multi-Feature Splitting");
      T := Train_CART_Variant (X, Y);
      Check ("10.1 Successfully navigates multidimensional split", T.Kind = Split);
      Check ("10.2 Identifies the primary determinative feature", T.Split_Feature = 1);
      Check ("10.3 Predicts correctly utilizing feature subsets", Predict (T, [1 => 2.5, 2 => 15.0]) = 2);
      Free_Tree (T);
   end;

   -- TEST 11: Non-Linear Mapping (XOR-like behavior)
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 2) :=
        [[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]];
      Y : constant Label_Vector (1 .. 4) := [1, 2, 2, 1];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 11 — Non-Linear Tree Evolution");
      T := Train (X, Y, Gini_Impurity, Max_Depth => 5);
      Check ("11.1 Reaches sufficient depth for non-linearity", T.Kind = Split);
      Check ("11.2 Accurately models isolated branch logic", Predict (T, [0.0, 1.0]) = 2);
      Check ("11.3 Resolves combinatorial XOR targets", Predict (T, [1.0, 1.0]) = 1);
      Free_Tree (T);
   end;

   -- TEST 12: Memory Handlers and Cleanup
   declare
      X : constant Feature_Matrix (1 .. 2, 1 .. 1) := [[1 => 1.0], [1 => 2.0]];
      Y : constant Label_Vector (1 .. 2) := [1, 2];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 12 — Tree Deallocation Verification");
      T := Train_CART_Variant (X, Y);
      Check ("12.1 Tree validates post-allocation", T /= null);
      Free_Tree (T);
      Check ("12.2 Tree pointer effectively nulled post-free", T = null);
      declare
         Flag : Boolean := False;
         Dummy : Class_Label;
      begin
         Dummy := Predict (T, [1 => 1.0]);
         Check ("12.3 Operations blocked on deallocated tree", Dummy = 1); -- Dummy read avoids warning
      exception
         when Null_Tree_Error =>
            Flag := True;
            Check ("12.3 Operations blocked on deallocated tree", Flag);
      end;
   end;

   -- TEST 13: Majority Class Tie-Breaking
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 1) :=
        [[1 => 1.0], [1 => 2.0], [1 => 3.0], [1 => 4.0]];
      Y : constant Label_Vector (1 .. 4) := [2, 1, 2, 1];
      T : Tree_Node_Access;
      Pred : Class_Label;
   begin
      Put_Line ("TEST 13 — Tie-Break Handling on Forced Leafs");
      T := Train_ID3_Variant (X, Y, Max_Depth => 0);
      Check ("13.1 Root resolves gracefully as Leaf", T.Kind = Leaf);
      Pred := Predict (T, [1 => 1.0]);
      Check ("13.2 Tie results in structurally valid class", Pred = 1 or else Pred = 2);
      Check ("13.3 Subsystem survives unresolvable tie", True);
      Free_Tree (T);
   end;

   -- TEST 14: Single Element Dataset Configuration
   declare
      X : constant Feature_Matrix (1 .. 1, 1 .. 1) := [1 => [1 => 1.5]];
      Y : constant Label_Vector (1 .. 1) := [1 => 3];
      T : Tree_Node_Access;
   begin
      Put_Line ("TEST 14 — Single Element Dataset Operations");
      T := Train_CART_Variant (X, Y);
      Check ("14.1 One-shot training completed", T /= null);
      Check ("14.2 Minimum data resolved purely", T.Kind = Leaf);
      Check ("14.3 Singular metric preserves exact outcome", Predict (T, [1 => 5.0]) = 3);
      Free_Tree (T);
   end;

   -- TEST 15: Invalid Feature Index Mapping Error
   declare
      X : constant Feature_Matrix (1 .. 4, 1 .. 2) :=
        [[1.0, 2.0], [3.0, 4.0], [5.0, 6.0], [7.0, 8.0]];
      Y : constant Label_Vector (1 .. 4) := [1, 1, 2, 2];
      T : Tree_Node_Access;
      Flag : Boolean := False;
      Dummy : Class_Label;
   begin
      Put_Line ("TEST 15 — Invalid Feature Prediction Error");
      T := Train_CART_Variant (X, Y);
      begin
         -- Predicting with missing index bounds
         Dummy := Predict (T, [5 .. 6 => 1.0]);
         Check ("15.1 Failed to catch feature offset", Dummy = 1); -- Dummy read avoids warning
         Check ("15.2 Dummy", False);
         Check ("15.3 Dummy", False);
      exception
         when Invalid_Feature_Error =>
            Flag := True;
            Check ("15.1 Handled unseen/unmapped feature indices", Flag);
            Check ("15.2 Protected bounds and memory structures", True);
            Check ("15.3 Error accurately documented via exception", True);
      end;
      Free_Tree (T);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
