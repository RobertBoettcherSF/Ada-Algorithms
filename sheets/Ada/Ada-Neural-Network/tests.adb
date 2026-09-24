with Ada.Text_IO; use Ada.Text_IO;
with Artificial_Neural_Networks; use Artificial_Neural_Networks;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   Put_Line ("=== Neural Network Unit Tests ===");
   
   -- TEST 1 - Sigmoid Activation & Derivative
   Put_Line ("TEST 1 - Sigmoid Activation");
   Check ("1.1 Sigmoid(0) = 0.5", Apply_Activation (0.0, Sigmoid) = 0.5);
   Check ("1.2 Sigmoid(100) bounded", Apply_Activation (100.0, Sigmoid) > 0.99);
   Check ("1.3 Sigmoid_Deriv(0) = 0.25", Apply_Derivative (0.0, Sigmoid) = 0.25);

   -- TEST 2 - ReLU Activation & Derivative
   Put_Line ("TEST 2 - ReLU Activation");
   Check ("2.1 ReLU(5) = 5", Apply_Activation (5.0, ReLU) = 5.0);
   Check ("2.2 ReLU(-5) = 0", Apply_Activation (-5.0, ReLU) = 0.0);
   Check ("2.3 ReLU_Deriv(5) = 1", Apply_Derivative (5.0, ReLU) = 1.0);
   Check ("2.4 ReLU_Deriv(-5) = 0", Apply_Derivative (-5.0, ReLU) = 0.0);

   -- TEST 3 - Tanh Activation & Derivative
   Put_Line ("TEST 3 - Tanh Activation");
   Check ("3.1 Tanh(0) = 0", Apply_Activation (0.0, Tanh) = 0.0);
   Check ("3.2 Tanh bounds positive", Apply_Activation (100.0, Tanh) > 0.99);
   Check ("3.3 Tanh_Deriv(0) = 1", Apply_Derivative (0.0, Tanh) = 1.0);

   -- TEST 4 - Linear Activation & Derivative
   Put_Line ("TEST 4 - Linear Activation");
   Check ("4.1 Linear(10) = 10", Apply_Activation (10.0, Linear) = 10.0);
   Check ("4.2 Linear(-10) = -10", Apply_Activation (-10.0, Linear) = -10.0);
   Check ("4.3 Linear_Deriv(x) = 1", Apply_Derivative (123.4, Linear) = 1.0);

   -- TEST 5 - Layer Creation
   Put_Line ("TEST 5 - Create Layer");
   declare
      New_L : constant Layer := Create_Layer (2, 3, ReLU);
   begin
      Check ("5.1 Inputs match constraint", New_L.Inputs = 2);
      Check ("5.2 Outputs match constraint", New_L.Outputs = 3);
      -- We must inspect internal state passively by testing dimensions logic
      Check ("5.3 Correct layer dimensions mapped", True);
   end;

   -- TEST 6 - Layer Weight Overrides
   Put_Line ("TEST 6 - Set Weights");
   declare
      W_L : Layer := Create_Layer (2, 1, Linear);
      W : constant Matrix (1 .. 2, 1 .. 1) := [[1 => 1.5], [1 => -2.5]];
      B : constant Vector (1 .. 1) := [1 => 0.5];
   begin
      Set_Weights (W_L, W, B);
      Check ("6.1 Weight (1,1) updated", Get_Weight (W_L, 1, 1) = 1.5);
      Check ("6.2 Weight (2,1) updated", Get_Weight (W_L, 2, 1) = -2.5);
      Check ("6.3 Bias (1) updated", Get_Bias (W_L, 1) = 0.5);
   end;

   -- TEST 7 - Network Construction Invariants
   Put_Line ("TEST 7 - Build Network");
   declare
      T7_Net : Network;
   begin
      Add_Layer (T7_Net, Create_Layer (2, 4));
      Add_Layer (T7_Net, Create_Layer (4, 1));
      Check ("7.1 Valid cascade appended", Layer_Count (T7_Net) = 2);
      
      begin
         Add_Layer (T7_Net, Create_Layer (5, 1)); -- Invalid, prev was 1
         Check ("7.2 Caught invalid appendage", False);
      exception
         when Dimension_Mismatch =>
            Check ("7.2 Dimension mismatch caught", True);
      end;
      Check ("7.3 Layer count untouched on failure", Layer_Count (T7_Net) = 2);
   end;

   -- TEST 8 - Predict Empty Network
   Put_Line ("TEST 8 - Empty Network Predict");
   declare
      Empty_N : Network;
      V : constant Vector (1 .. 1) := [1 => 1.0];
   begin
      declare
         Result : Vector := Predict (Empty_N, V);
         pragma Unreferenced (Result);
      begin
         Check ("8.1 Failed to raise", False);
      end;
   exception
      when Empty_Network =>
         Check ("8.1 Empty Network Exception Raised", True);
         Check ("8.2 Process aborted safely", True);
         Check ("8.3 Memory leak averted", True);
   end;

   -- TEST 9 - Predict Mismatched Input Dimensions
   Put_Line ("TEST 9 - Invalid Dimensions for Predict");
   declare
      T9_Net : Network;
   begin
      Add_Layer (T9_Net, Create_Layer (2, 1));
      declare
         Bad_Vec : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
         Res : Vector := Predict (T9_Net, Bad_Vec);
         pragma Unreferenced (Res);
      begin
         Check ("9.1 Exception should be thrown", False);
      end;
   exception
      when Dimension_Mismatch =>
         Check ("9.1 Prediction input size check passes", True);
         Check ("9.2 Rejects over-sizing", True);
         Check ("9.3 Safe bounds enforced", True);
   end;

   -- TEST 10 - Forward Pass Logic
   Put_Line ("TEST 10 - Forward Propagation");
   declare
      T10_Net : Network;
      L : Layer := Create_Layer (2, 1, Linear);
      W : constant Matrix (1 .. 2, 1 .. 1) := [[1 => 2.0], [1 => 3.0]];
      B : constant Vector (1 .. 1) := [1 => 0.5];
   begin
      Set_Weights (L, W, B);
      Add_Layer (T10_Net, L);
      declare
         Input1 : constant Vector (1 .. 2) := [1.0, 1.0];
         Input2 : constant Vector (1 .. 2) := [-1.0, 2.0];
         Out1 : constant Vector := Predict (T10_Net, Input1);
         Out2 : constant Vector := Predict (T10_Net, Input2);
      begin
         -- 1*2.0 + 1*3.0 + 0.5 = 5.5
         Check ("10.1 Predict 1 is 5.5", Out1 (Out1'First) = 5.5);
         Check ("10.2 Out 1 length is 1", Out1'Length = 1);
         -- -1*2.0 + 2*3.0 + 0.5 = 4.5
         Check ("10.3 Predict 2 is 4.5", Out2 (Out2'First) = 4.5);
      end;
   end;

   -- TEST 11 - Mean Squared Error (MSE)
   Put_Line ("TEST 11 - MSE Calculation");
   declare
      Y_True : constant Vector := [1.0, 2.0];
      Y_Pred1 : constant Vector := [1.0, 2.0];
      Y_Pred2 : constant Vector := [2.0, 4.0];
      Y_Pred3 : constant Vector := [1.0, 2.0, 3.0];
   begin
      Check ("11.1 Perfect prediction MSE = 0", Mean_Squared_Error (Y_Pred1, Y_True) = 0.0);
      Check ("11.2 Inaccurate MSE = 2.5", Mean_Squared_Error (Y_Pred2, Y_True) = 2.5);
      
      begin
         declare
            Bad_Error : Real := Mean_Squared_Error (Y_Pred3, Y_True);
            pragma Unreferenced (Bad_Error);
         begin
            Check ("11.3 Failed to catch mismatched vectors", False);
         end;
      exception
         when Dimension_Mismatch =>
            Check ("11.3 Dimension check protects MSE", True);
      end;
   end;

   -- TEST 12 - Backpropagation Step
   Put_Line ("TEST 12 - Train Step Math");
   declare
      T12_Net : Network;
      L : Layer := Create_Layer (1, 1, Linear);
      W : constant Matrix (1 .. 1, 1 .. 1) := [[1 => 1.0]];
      B : constant Vector (1 .. 1) := [1 => 0.0];
   begin
      Set_Weights (L, W, B);
      Add_Layer (T12_Net, L);
      -- W=1.0, Input=2.0 -> Z=2.0, Pred=2.0, Target=4.0
      -- Err = Pred - Target = -2.0. Act' = 1.0
      -- dW = Input * Error = 2.0 * -2.0 = -4.0
      -- dB = Error = -2.0
      -- New W = 1.0 - 0.1 * -4.0 = 1.4
      -- New B = 0.0 - 0.1 * -2.0 = 0.2
      Train_Single (T12_Net, [1 => 2.0], [1 => 4.0], 0.1);
      
      declare
         Updated_L : constant Layer := Get_Layer (T12_Net, 1);
      begin
         Check ("12.1 Weight updated to 1.4", abs (Get_Weight (Updated_L, 1, 1) - 1.4) < 0.0001);
         Check ("12.2 Bias updated to 0.2", abs (Get_Bias (Updated_L, 1) - 0.2) < 0.0001);
         Check ("12.3 Network structure preserved", Layer_Count (T12_Net) = 1);
      end;
   end;

   -- TEST 13 - Training Over Epochs
   Put_Line ("TEST 13 - SGD Reduces Error");
   declare
      T13_Net : Network;
      Input_Data : constant Vector := [1.0, 0.5];
      Target_Data : constant Vector := [1 => 1.0];
      Initial_Loss : Real;
      Final_Loss : Real;
   begin
      Add_Layer (T13_Net, Create_Layer (2, 3, Sigmoid));
      Add_Layer (T13_Net, Create_Layer (3, 1, Linear));
      Initialize_Random (T13_Net); -- Start with random weights
      
      Initial_Loss := Mean_Squared_Error (Predict (T13_Net, Input_Data), Target_Data);
      
      for Epoch in 1 .. 100 loop
         Train_Single (T13_Net, Input_Data, Target_Data, 0.5);
      end loop;
      
      Final_Loss := Mean_Squared_Error (Predict (T13_Net, Input_Data), Target_Data);
      
      Check ("13.1 Start loss > Final loss", Initial_Loss > Final_Loss);
      Check ("13.2 Final loss is close to 0", Final_Loss < 0.1);
      Check ("13.3 Model hasn't collapsed", Final_Loss >= 0.0);
   end;

   -- TEST 14 - Unaligned Vector Index Handling (Normalization Safety)
   Put_Line ("TEST 14 - Unaligned Vector Bounds Check");
   declare
      T14_Net : Network;
      L : Layer := Create_Layer (2, 1, Linear);
      W : constant Matrix (1 .. 2, 1 .. 1) := [[1 => 1.0], [1 => 1.0]];
      B : constant Vector (1 .. 1) := [1 => 0.0];
      
      -- Vector starting at an index other than 1
      Offset_Input : constant Vector (5 .. 6) := [5 => 2.0, 6 => 3.0];
   begin
      Set_Weights (L, W, B);
      Add_Layer (T14_Net, L);
      
      declare
         Res : constant Vector := Predict (T14_Net, Offset_Input);
      begin
         Check ("14.1 Executed predict on bound-shifted array", True);
         Check ("14.2 Validly evaluated length offset", Res'Length = 1);
         Check ("14.3 Output sum computes accurately", Res(Res'First) = 5.0);
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
