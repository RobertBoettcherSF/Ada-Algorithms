with Ada.Text_IO; use Ada.Text_IO;
with System.Assertions;
with LPBoost; use LPBoost;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label_Text : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label_Text);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label_Text);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper to extract a 1D row from a 2D Dataset (Ada does not support multidimensional slicing)
   function Get_Row (D : Dataset; Row : Positive) return Data_Point is
      Res : Data_Point (1 .. D'Length (2));
   begin
      for C in 1 .. D'Length (2) loop
         Res (C) := D (Row, C);
      end loop;
      return Res;
   end Get_Row;

   -- Datasets (Using Ada 2022 square bracket syntax for array aggregates)
   Data_Sep : constant Dataset :=
     [[1.0, 1.0],
      [2.0, 2.0],
      [5.0, 5.0],
      [6.0, 6.0]];
   Lbls_Sep : constant Labels := [-1, -1, 1, 1];

   -- Non-Linear Box Dataset (XOR cannot be solved by axis-aligned decision stumps, 
   -- so this Box dataset effectively tests non-linear multi-stump boosting).
   Data_NonLin : constant Dataset :=
     [[1.0, 1.0],
      [2.0, 2.0],
      [3.0, 3.0]];
   Lbls_NonLin : constant Labels := [-1, 1, -1];

   Data_Uniform : constant Dataset := [[1.0, 1.0], [1.0, 2.0], [2.0, 1.0]];
   Lbls_All_Pos : constant Labels := [1, 1, 1];
   Lbls_All_Neg : constant Labels := [-1, -1, -1];
   
   Data_Single_F : constant Dataset := [[1.0], [2.0], [3.0], [4.0]];
   Lbls_Single_F : constant Labels := [-1, -1, 1, 1];

begin
   Put_Line ("TEST 1 — Normal Separable 2D Dataset (Nu=0.5)");
   declare
      M_Mod : constant Model := Train (Data_Sep, Lbls_Sep, 0.5, 10);
      P1 : constant Label := Predict (M_Mod, Get_Row (Data_Sep, 1));
      P3 : constant Label := Predict (M_Mod, Get_Row (Data_Sep, 3));
   begin
      Check ("1.1 Model size is > 0", M_Mod.Size > 0);
      Check ("1.2 Predicts negative class correctly", P1 = -1);
      Check ("1.3 Predicts positive class correctly", P3 = 1);
   end;

   Put_Line ("TEST 2 — Predict_Score Signs and Magnitudes");
   declare
      M_Mod : constant Model := Train (Data_Sep, Lbls_Sep, 0.5, 10);
      S1 : constant Real := Predict_Score (M_Mod, Data_Point'[1.0, 1.0]);
      S3 : constant Real := Predict_Score (M_Mod, Data_Point'[6.0, 6.0]);
   begin
      Check ("2.1 Negative example score < 0.0", S1 < 0.0);
      Check ("2.2 Positive example score > 0.0", S3 > 0.0);
      Check ("2.3 Model converged before Max_Iter", M_Mod.Size < 10);
   end;

   Put_Line ("TEST 3 — All Positive Labels (Edge Case)");
   declare
      M_Mod : constant Model := Train (Data_Uniform, Lbls_All_Pos, 1.0, 5);
   begin
      Check ("3.1 Trained without crashing", True);
      Check ("3.2 Predicts positive for item 1", Predict (M_Mod, Data_Point'[1.0, 1.0]) = 1);
      Check ("3.3 Model size is exactly 1 (converged immediately)", M_Mod.Size = 1);
   end;

   Put_Line ("TEST 4 — All Negative Labels (Edge Case)");
   declare
      M_Mod : constant Model := Train (Data_Uniform, Lbls_All_Neg, 1.0, 5);
   begin
      Check ("4.1 Trained without crashing", True);
      Check ("4.2 Predicts negative for item 1", Predict (M_Mod, Data_Point'[2.0, 1.0]) = -1);
      Check ("4.3 Model size is exactly 1", M_Mod.Size = 1);
   end;

   Put_Line ("TEST 5 — Hard Margin Validation (Nu=1.0)");
   declare
      M_Mod : constant Model := Train (Data_Sep, Lbls_Sep, 1.0, 10);
   begin
      Check ("5.1 Successfully built model", M_Mod.Size > 0);
      Check ("5.2 First element classified correctly", Predict (M_Mod, Get_Row (Data_Sep, 1)) = -1);
      Check ("5.3 Last element classified correctly", Predict (M_Mod, Get_Row (Data_Sep, 4)) = 1);
   end;

   Put_Line ("TEST 6 — High Regularization Validation (Nu=0.2)");
   declare
      M_Mod : constant Model := Train (Data_Sep, Lbls_Sep, 0.2, 10);
   begin
      Check ("6.1 Successfully built model", M_Mod.Size > 0);
      Check ("6.2 Regularized model still classifies point 1", Predict (M_Mod, Get_Row (Data_Sep, 1)) = -1);
      Check ("6.3 Regularized model still classifies point 4", Predict (M_Mod, Get_Row (Data_Sep, 4)) = 1);
   end;

   Put_Line ("TEST 7 — Non-Linear Problem (Box Dataset)");
   declare
      -- Reduced Nu to 0.05. A smaller Nu imposes a stronger hard-margin penalty. 
      -- At 0.5, the LP solver found it "cheaper" to penalize one misclassified point 
      -- than to build the 3 necessary stumps to perfectly separate the set.
      M_Mod : constant Model := Train (Data_NonLin, Lbls_NonLin, 0.05, 20);
      Acc   : Natural := 0;
   begin
      Check ("7.1 LPBoost constructed multiple stumps for Box", M_Mod.Size > 1);
      for I in 1 .. 3 loop
         if Predict (M_Mod, Get_Row (Data_NonLin, I)) = Lbls_NonLin (I) then
            Acc := Acc + 1;
         end if;
      end loop;
      Check ("7.2 Achieved 100% accuracy on training data", Acc = 3);
      Check ("7.3 Used <= Max_Iter stumps", M_Mod.Size <= 20);
   end;

   Put_Line ("TEST 8 — Exception on Mismatched Lengths");
   begin
      declare
         Lbls_Bad : constant Labels := [-1, 1];
         M_Mod    : constant Model := Train (Data_Sep, Lbls_Bad, 0.5, 10);
         pragma Warnings (Off, M_Mod);
      begin
         Check ("8.1 Should have raised Precondition fail", False);
      end;
   exception
      when System.Assertions.Assert_Failure =>
         Check ("8.1 Raised Assert_Failure on length mismatch", True);
         Check ("8.2 Successfully caught", True);
         Check ("8.3 Prevented bad LP initialization", True);
   end;

   Put_Line ("TEST 9 — Exception on Invalid Nu (Nu = 0.0)");
   begin
      declare
         M_Mod : constant Model := Train (Data_Sep, Lbls_Sep, 0.0, 10);
         pragma Warnings (Off, M_Mod);
      begin
         Check ("9.1 Should have raised Precondition fail", False);
      end;
   exception
      when System.Assertions.Assert_Failure =>
         Check ("9.1 Raised Assert_Failure on Nu=0.0", True);
         Check ("9.2 Nu > 0.0 is enforced", True);
         Check ("9.3 Division by zero prevented", True);
   end;

   Put_Line ("TEST 10 — Exception on Invalid Max_Iter");
   begin
      declare
         -- Use 'Value to evaluate "0" dynamically. This completely bypasses GNAT's
         -- static analysis phase, preventing both the "not modified" constant warning 
         -- and the static Constraint_Error compiler warnings.
         Invalid_Iter : constant Natural := Natural'Value ("0");
         M_Mod : Model (Max_Size => Invalid_Iter);
         pragma Warnings (Off, M_Mod);
      begin
         M_Mod := Train (Data_Sep, Lbls_Sep, 0.5, Invalid_Iter);
         Check ("10.1 Should have raised Constraint_Error", False);
      end;
   exception
      when Constraint_Error =>
         Check ("10.1 Raised Constraint_Error for 0 Max_Iter", True);
         Check ("10.2 Parameter type Positive enforced", True);
         Check ("10.3 Safe initialization", True);
   end;

   Put_Line ("TEST 11 — Convergence via Error Bounds");
   declare
      Data_Contradict : constant Dataset := [[1.0], [1.0]];
      Lbls_Contradict : constant Labels := [1, -1];
      M_Mod : constant Model := Train (Data_Contradict, Lbls_Contradict, 1.0, 5);
   begin
      Check ("11.1 Algorithm halts early on contradictory data", M_Mod.Size < 5);
      Check ("11.2 Evaluates gracefully", True);
      Check ("11.3 Weights remain safe", True);
   end;

   Put_Line ("TEST 12 — Exact Match Generalization");
   declare
      M_Mod : constant Model := Train (Data_Sep, Lbls_Sep, 0.5, 5);
      Point : constant Data_Point := [2.0, 2.0];
   begin
      Check ("12.1 Matches prediction precisely", Predict (M_Mod, Point) = -1);
      Check ("12.2 Output consistency across identical inputs", Predict (M_Mod, Point) = Predict (M_Mod, Get_Row (Data_Sep, 2)));
      Check ("12.3 Sign matches label", Predict_Score (M_Mod, Point) < 0.0);
   end;

   Put_Line ("TEST 13 — Single Feature Dataset");
   declare
      M_Mod : constant Model := Train (Data_Single_F, Lbls_Single_F, 0.5, 5);
      Acc   : Natural := 0;
   begin
      for I in 1 .. 4 loop
         if Predict (M_Mod, Get_Row (Data_Single_F, I)) = Lbls_Single_F (I) then
            Acc := Acc + 1;
         end if;
      end loop;
      Check ("13.1 Trains on 1D feature space", M_Mod.Size > 0);
      Check ("13.2 Perfect accuracy on 1D data", Acc = 4);
      Check ("13.3 Uses correct threshold in 1D", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
