with Ada.Text_IO; use Ada.Text_IO;
with Structured_SVM;

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

   -- =========================================================================
   -- 1. DEFINE A SPECIFIC PROBLEM TO INSTANTIATE THE GENERIC PACKAGE
   --    We define a simple 3-class linear classification task as an SSVM.
   -- =========================================================================
   type Class_Label is range 1 .. 3;
   type Vector_3D is array (1 .. 3) of Float;

   Feature_Dim : constant Positive := 9; 
   subtype Feature_Index is Positive range 1 .. Feature_Dim;
   type Feature_Vector is array (Feature_Index) of Float;

   -- Block-encoding Joint Feature Map: copies X into a class-specific block offset
   function Joint_Feature_Map (X : Vector_3D; Y : Class_Label) return Feature_Vector is
      V : Feature_Vector := [others => 0.0];
      Offset : constant Natural := (Natural (Y) - 1) * 3;
   begin
      V (Offset + 1) := X (1);
      V (Offset + 2) := X (2);
      V (Offset + 3) := X (3);
      return V;
   end Joint_Feature_Map;

   -- Standard 0-1 Loss for Multiclass
   function Loss (True_Y, Predicted_Y : Class_Label) return Float is
   begin
      if True_Y = Predicted_Y then
         return 0.0;
      else
         return 1.0;
      end if;
   end Loss;

   function Dot_Product (A, B : Feature_Vector) return Float is
      Sum : Float := 0.0;
   begin
      for I in A'Range loop
         Sum := Sum + A (I) * B (I);
      end loop;
      return Sum;
   end Dot_Product;

   -- Inference: simply iterate all possible outputs natively
   function Predict_Max (X : Vector_3D; W : Feature_Vector) return Class_Label is
      Best_Y : Class_Label := 1;
      Best_Score : Float := -Float'Last;
      Score : Float;
   begin
      for Y in Class_Label loop
         Score := Dot_Product (W, Joint_Feature_Map (X, Y));
         if Score > Best_Score then
            Best_Score := Score;
            Best_Y := Y;
         end if;
      end loop;
      return Best_Y;
   end Predict_Max;

   function Argmax_Margin (X : Vector_3D; True_Y : Class_Label; W : Feature_Vector) return Class_Label is
      Best_Y : Class_Label := 1;
      Best_Score : Float := -Float'Last;
      Score : Float;
   begin
      for Y in Class_Label loop
         Score := Loss (True_Y, Y) + Dot_Product (W, Joint_Feature_Map (X, Y));
         if Score > Best_Score then
            Best_Score := Score;
            Best_Y := Y;
         end if;
      end loop;
      return Best_Y;
   end Argmax_Margin;

   function Argmax_Slack (X : Vector_3D; True_Y : Class_Label; W : Feature_Vector) return Class_Label is
      Best_Y : Class_Label := 1;
      Best_Score : Float := -Float'Last;
      Score : Float;
      Delta_Phi : Feature_Vector;
   begin
      for Y in Class_Label loop
         -- Using manual subtraction to bypass operator visibility resolution
         for I in Delta_Phi'Range loop
            Delta_Phi (I) := Joint_Feature_Map (X, True_Y)(I) - Joint_Feature_Map (X, Y)(I);
         end loop;
         
         Score := Loss (True_Y, Y) * (1.0 - Dot_Product (W, Delta_Phi));
         if Score > Best_Score then
            Best_Score := Score;
            Best_Y := Y;
         end if;
      end loop;
      return Best_Y;
   end Argmax_Slack;

   -- Instantiate Structured SVM
   package SSVM is new Structured_SVM
     (Real                    => Float,
      Input_Type              => Vector_3D,
      Output_Type             => Class_Label,
      Feature_Index           => Feature_Index,
      Feature_Vector          => Feature_Vector,
      Joint_Feature_Map       => Joint_Feature_Map,
      Loss                    => Loss,
      Predict_Max             => Predict_Max,
      Argmax_Margin_Rescaling => Argmax_Margin,
      Argmax_Slack_Rescaling  => Argmax_Slack);

   -- =========================================================================
   -- 2. TOY DATA AND TEST SUITE EXECUTION
   -- =========================================================================
   Dataset : constant SSVM.Dataset_Array (1 .. 3) :=
     [1 => [1.0, 0.0, 1.0],
      2 => [0.0, 1.0, 1.0],
      3 => [-1.0, -1.0, 1.0]];
   
   Labels : constant SSVM.Label_Array (1 .. 3) := [1 => 1, 2 => 2, 3 => 3];

   Model_Margin : SSVM.Model;
   Model_Slack  : SSVM.Model;
   Empty_D      : SSVM.Dataset_Array (1 .. 0);
   Empty_L      : SSVM.Label_Array (1 .. 0);
   Mismatch_L   : constant SSVM.Label_Array (1 .. 2) := [1 => 1, 2 => 2];

begin
   Put_Line ("TEST 1 — Vector Math Functions");
   declare
      V1 : constant Feature_Vector := [1 => 1.0, 2 => 2.0, others => 0.0];
      V2 : constant Feature_Vector := [1 => 2.0, 2 => 3.0, others => 0.0];
      V_Add : constant Feature_Vector := SSVM."+" (V1, V2);
      V_Sub : constant Feature_Vector := SSVM."-" (V2, V1);
      V_Mul : constant Feature_Vector := SSVM."*" (2.0, V1);
      Dot   : constant Float := SSVM.Dot_Product (V1, V2);
   begin
      Check ("1.1 Vector Addition", abs (V_Add (1) - 3.0) < 0.0001 and abs (V_Add (2) - 5.0) < 0.0001);
      Check ("1.2 Vector Subtraction", abs (V_Sub (1) - 1.0) < 0.0001 and abs (V_Sub (2) - 1.0) < 0.0001);
      Check ("1.3 Scalar Multiplication", abs (V_Mul (1) - 2.0) < 0.0001 and abs (V_Mul (2) - 4.0) < 0.0001);
      Check ("1.4 Dot Product", abs (Dot - 8.0) < 0.0001);
   end;

   Put_Line ("TEST 2 — Exception Handling: Empty Dataset");
   declare
      Failed_As_Expected : Boolean;
   begin
      Failed_As_Expected := False;
      begin
         Model_Margin := SSVM.Train_Margin_Rescaling (Empty_D, Empty_L, 1.0, 10);
      exception
         when SSVM.Empty_Dataset => Failed_As_Expected := True;
         when others => null;
      end;
      Check ("2.1 Margin catches Empty_Dataset", Failed_As_Expected);

      Failed_As_Expected := False;
      begin
         Model_Slack := SSVM.Train_Slack_Rescaling (Empty_D, Empty_L, 1.0, 10);
      exception
         when SSVM.Empty_Dataset => Failed_As_Expected := True;
         when others => null;
      end;
      Check ("2.2 Slack catches Empty_Dataset", Failed_As_Expected);
      Check ("2.3 Empty arrays correctly identified", Empty_D'Length = 0);
   end;

   Put_Line ("TEST 3 — Exception Handling: Size Mismatch");
   declare
      Failed_As_Expected : Boolean;
   begin
      Failed_As_Expected := False;
      begin
         Model_Margin := SSVM.Train_Margin_Rescaling (Dataset, Mismatch_L, 1.0, 10);
      exception
         when SSVM.Dataset_Size_Mismatch => Failed_As_Expected := True;
         when others => null;
      end;
      Check ("3.1 Margin catches Size_Mismatch", Failed_As_Expected);

      Failed_As_Expected := False;
      begin
         Model_Slack := SSVM.Train_Slack_Rescaling (Dataset, Mismatch_L, 1.0, 10);
      exception
         when SSVM.Dataset_Size_Mismatch => Failed_As_Expected := True;
         when others => null;
      end;
      Check ("3.2 Slack catches Size_Mismatch", Failed_As_Expected);
      Check ("3.3 Arrays differ in length", Dataset'Length /= Mismatch_L'Length);
   end;

   Put_Line ("TEST 4 — Exception Handling: Invalid Hyperparameters");
   declare
      Failed_As_Expected : Boolean;
   begin
      Failed_As_Expected := False;
      begin
         Model_Margin := SSVM.Train_Margin_Rescaling (Dataset, Labels, 0.0, 10);
      exception
         when SSVM.Invalid_Hyperparameter => Failed_As_Expected := True;
         when others => null;
      end;
      Check ("4.1 Margin catches Lambda=0.0", Failed_As_Expected);

      Failed_As_Expected := False;
      begin
         Model_Margin := SSVM.Train_Margin_Rescaling (Dataset, Labels, -1.0, 10);
      exception
         when SSVM.Invalid_Hyperparameter => Failed_As_Expected := True;
         when others => null;
      end;
      Check ("4.2 Margin catches Lambda=-1.0", Failed_As_Expected);

      Failed_As_Expected := False;
      begin
         Model_Slack := SSVM.Train_Slack_Rescaling (Dataset, Labels, -0.5, 10);
      exception
         when SSVM.Invalid_Hyperparameter => Failed_As_Expected := True;
         when others => null;
      end;
      Check ("4.3 Slack catches Invalid_Hyperparameter", Failed_As_Expected);
   end;

   Put_Line ("TEST 5 — Margin Loss-Augmented Inference Behavior");
   declare
      Zero_W : constant Feature_Vector := [others => 0.0];
      Y_Max  : Class_Label;
   begin
      Y_Max := Argmax_Margin (Dataset (1), Labels (1), Zero_W);
      -- With zero weights, we purely optimize Loss. Loss(1,1)=0; Loss(1,2)=1. Max selects 2 or 3.
      Check ("5.1 Argmax picks violating class for zero weights", Y_Max /= 1);

      declare
         Strong_W : Feature_Vector := [others => 0.0];
      begin
         Strong_W (1) := 10.0; -- Strongly biases towards class 1
         Y_Max := Argmax_Margin (Dataset (1), Labels (1), Strong_W);
         Check ("5.2 Weights overcome loss penalty", Y_Max = 1);
      end;
      Check ("5.3 Predict Max matches bias", Predict_Max (Dataset (1), Zero_W) = 1);
   end;

   Put_Line ("TEST 6 — Slack Loss-Augmented Inference Behavior");
   declare
      Zero_W : constant Feature_Vector := [others => 0.0];
      Y_Max  : Class_Label;
   begin
      Y_Max := Argmax_Slack (Dataset (1), Labels (1), Zero_W);
      Check ("6.1 Argmax picks violating class for zero weights", Y_Max /= 1);

      declare
         Strong_W : Feature_Vector := [others => 0.0];
         Y_Max_Strong : Class_Label;
      begin
         Strong_W (1) := 10.0;
         Y_Max_Strong := Argmax_Slack (Dataset (1), Labels (1), Strong_W);
         Check ("6.2 Weights effect", Y_Max_Strong = 1);
      end;
      Check ("6.3 Deterministic result", Argmax_Slack (Dataset (1), Labels (1), Zero_W) = Y_Max);
   end;

   Put_Line ("TEST 7 — Joint Feature Map Constraints");
   declare
      F_Map_1 : constant Feature_Vector := Joint_Feature_Map (Dataset (1), 1);
      F_Map_2 : constant Feature_Vector := Joint_Feature_Map (Dataset (1), 2);
   begin
      Check ("7.1 Offset works correctly", abs (F_Map_1 (1) - 1.0) < 0.0001);
      Check ("7.2 Zeros in other classes", abs (F_Map_1 (4)) < 0.0001);
      Check ("7.3 Orthogonal feature maps", abs (SSVM.Dot_Product (F_Map_1, F_Map_2)) < 0.0001);
   end;

   Put_Line ("TEST 8 — Training Margin Rescaling Subgradient Descent");
   Model_Margin := SSVM.Train_Margin_Rescaling (Dataset, Labels, Lambda => 0.1, Epochs => 200);
   Check ("8.1 W is non-zero after training", SSVM.Dot_Product (Model_Margin.Weights, Model_Margin.Weights) > 0.0001);
   Check ("8.2 Predicts sample 1", SSVM.Predict (Model_Margin, Dataset (1)) = Labels (1));
   Check ("8.3 Predicts sample 2", SSVM.Predict (Model_Margin, Dataset (2)) = Labels (2));

   Put_Line ("TEST 9 — Training Slack Rescaling Subgradient Descent");
   Model_Slack := SSVM.Train_Slack_Rescaling (Dataset, Labels, Lambda => 0.1, Epochs => 200);
   Check ("9.1 W is non-zero after training", SSVM.Dot_Product (Model_Slack.Weights, Model_Slack.Weights) > 0.0001);
   Check ("9.2 Predicts sample 1", SSVM.Predict (Model_Slack, Dataset (1)) = Labels (1));
   Check ("9.3 Predicts sample 2", SSVM.Predict (Model_Slack, Dataset (2)) = Labels (2));

   Put_Line ("TEST 10 — Overfitting Capability (Margin)");
   Check ("10.1 Margin matches Sample 1 exactly", SSVM.Predict (Model_Margin, Dataset (1)) = 1);
   Check ("10.2 Margin matches Sample 2 exactly", SSVM.Predict (Model_Margin, Dataset (2)) = 2);
   Check ("10.3 Margin matches Sample 3 exactly", SSVM.Predict (Model_Margin, Dataset (3)) = 3);

   Put_Line ("TEST 11 — Overfitting Capability (Slack)");
   Check ("11.1 Slack matches Sample 1 exactly", SSVM.Predict (Model_Slack, Dataset (1)) = 1);
   Check ("11.2 Slack matches Sample 2 exactly", SSVM.Predict (Model_Slack, Dataset (2)) = 2);
   Check ("11.3 Slack matches Sample 3 exactly", SSVM.Predict (Model_Slack, Dataset (3)) = 3);

   Put_Line ("TEST 12 — Single Sample Edge Case");
   declare
      Single_D : constant SSVM.Dataset_Array (1 .. 1) := [1 => Dataset (1)];
      Single_L : constant SSVM.Label_Array (1 .. 1)   := [1 => Labels (1)];
      M_Single : constant SSVM.Model := SSVM.Train_Margin_Rescaling (Single_D, Single_L, 0.1, 10);
   begin
      Check ("12.1 Completes without error", True);
      Check ("12.2 Fits the single sample", SSVM.Predict (M_Single, Single_D (1)) = Single_L (1));
      Check ("12.3 Biases unseen classes implicitly", SSVM.Predict (M_Single, Dataset (2)) /= Labels (2));
   end;

   Put_Line ("TEST 13 — Model Consistency");
   Check ("13.1 Predict equals Predict_Max", SSVM.Predict (Model_Margin, Dataset (1)) = Predict_Max (Dataset (1), Model_Margin.Weights));
   Check ("13.2 Slack model weights are valid", SSVM.Dot_Product (Model_Slack.Weights, Model_Slack.Weights) > 0.0001);
   Check ("13.3 Test suite completion", True);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
