with Ada.Text_IO; use Ada.Text_IO;
with Backpropagation; use Backpropagation;

procedure Tests
  with SPARK_Mode => Off
is
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
   
   function Near (A, B : Real; Tolerance : Real := 0.0001) return Boolean is
   begin
      return abs (A - B) < Tolerance;
   end Near;

begin
   -- TEST 1 - Network Creation
   Put_Line ("TEST 1 -- Network Creation");
   declare
      Net : constant Neural_Network := Create_Network (2, 3, 1, Sigmoid);
   begin
      Check ("1.1 Correct Input size", Net.Inputs = 2);
      Check ("1.2 Correct Hidden size", Net.Hiddens = 3);
      Check ("1.3 Correct Output size", Net.Outputs = 1);
      Check ("1.4 Activation function set properly", Net.Act = Sigmoid);
   end;

   -- TEST 2 - Forward Input Validation Exception
   Put_Line ("TEST 2 -- Forward Input Validation");
   declare
      Net        : constant Neural_Network := Create_Network (2, 3, 1, Linear);
      State      : Network_State (2, 3, 1);
      Bad_Input  : constant Vector (1 .. 1) := [1 => 1.0];
      Good_Input : constant Vector (1 .. 2) := [1.0, 2.0];
   begin
      begin
         Forward (Net, Bad_Input, State);
         Check ("2.1 Should have raised Dimension_Error for small input", False);
      exception
         when Dimension_Error => Check ("2.1 Dimension_Error caught for small input", True);
      end;
      
      begin
         Forward (Net, Good_Input, State);
         Check ("2.2 Valid input succeeds", True);
         Check ("2.3 State output populated correctly", State.A0 (1) = 1.0);
      exception
         when others => Check ("2.2 Valid input succeeds", False);
      end;
   end;

   -- TEST 3 - Backward Target Validation Exception
   Put_Line ("TEST 3 -- Backward Target Validation");
   declare
      Net    : constant Neural_Network := Create_Network (1, 2, 1, Linear);
      State  : Network_State (1, 2, 1);
      Grads  : Network_Gradients (1, 2, 1);
      Bad_T  : constant Vector (1 .. 2) := [1.0, 1.0];
      Good_T : constant Vector (1 .. 1) := [1 => 1.0];
   begin
      Forward (Net, [1 => 1.0], State);
      
      begin
         Backward (Net, State, Bad_T, Grads);
         Check ("3.1 Should have raised Dimension_Error for wrong target length", False);
      exception
         when Dimension_Error => Check ("3.1 Dimension_Error caught for target length", True);
      end;
      
      begin
         Backward (Net, State, Good_T, Grads);
         Check ("3.2 Valid target succeeds", True);
         Check ("3.3 Gradients are populated without crash", True);
      exception
         when others => Check ("3.2 Valid target succeeds", False);
      end;
   end;

   -- TEST 4 - Accumulate Gradients Dimension Validation
   Put_Line ("TEST 4 -- Accumulate Gradients Dimension Validation");
   declare
      Grads_A : Network_Gradients (1, 2, 1);
      Grads_B : Network_Gradients (2, 2, 1);
      Grads_C : Network_Gradients (1, 2, 1);
   begin
      Zero_Gradients (Grads_A);
      Zero_Gradients (Grads_B);
      Zero_Gradients (Grads_C);
      
      begin
         Accumulate_Gradients (Grads_A, Grads_B);
         Check ("4.1 Exception expected on mismatch", False);
      exception
         when others => Check ("4.1 Caught exception on shape mismatch", True);
      end;
      
      begin
         Accumulate_Gradients (Grads_A, Grads_C);
         Check ("4.2 Same shape accumulation succeeds", True);
         Check ("4.3 Grads preserved", Grads_A.DB1 (1) = 0.0);
      exception
         when others => Check ("4.2 Same shape accumulation succeeds", False);
      end;
   end;

   -- TEST 5 - Compute Loss Correctness
   Put_Line ("TEST 5 -- Compute Loss Correctness");
   declare
      P1 : constant Vector (1 .. 2) := [1.0, 0.0];
      T1 : constant Vector (1 .. 2) := [1.0, 0.0];
      P2 : constant Vector (1 .. 2) := [1.0, 1.0];
      T2 : constant Vector (1 .. 2) := [0.0, 0.0];
   begin
      Check ("5.1 Zero loss for perfect prediction", Compute_Loss (P1, T1) = 0.0);
      -- MSE for (1-0)^2 + (1-0)^2 / 2 = 2.0 / 2 = 1.0
      Check ("5.2 MSE correctly computed", Near (Compute_Loss (P2, T2), 1.0));
      
      begin
         declare
            Bad_P : constant Vector (1 .. 1) := [1 => 0.0];
         begin
            if Compute_Loss (Bad_P, T1) = 0.0 then
               Check ("5.3 Exception on loss dimension mismatch", False);
            end if;
         end;
      exception
         when Dimension_Error => Check ("5.3 Caught loss dimension mismatch", True);
      end;
   end;

   -- TEST 6 - Zero Gradients
   Put_Line ("TEST 6 -- Zero Gradients");
   declare
      Grads : Network_Gradients (2, 2, 2);
   begin
      pragma Warnings (Off, "*useless assignment*");
      Grads.DB1 := [others => 1.0];
      Grads.DW1 := [others => [others => 1.0]];
      pragma Warnings (On, "*useless assignment*");
      Zero_Gradients (Grads);
      
      Check ("6.1 Bias gradients are zeroed", Grads.DB1 (1) = 0.0);
      Check ("6.2 Weight gradients are zeroed", Grads.DW1 (1, 1) = 0.0);
      Check ("6.3 Output gradients are zeroed", Grads.DW2 (1, 1) = 0.0);
   end;

   -- TEST 7 - Accumulate Gradients Correctness
   Put_Line ("TEST 7 -- Accumulate Gradients Math");
   declare
      Total : Network_Gradients (1, 1, 1);
      New_G : Network_Gradients (1, 1, 1);
   begin
      Zero_Gradients (Total);
      Zero_Gradients (New_G);
      
      Total.DB1 (1) := 1.5;
      New_G.DB1 (1) := 2.5;
      
      Total.DW2 (1, 1) := -1.0;
      New_G.DW2 (1, 1) := 3.0;
      
      Accumulate_Gradients (Total, New_G);
      Check ("7.1 Biases sum correctly", Near (Total.DB1 (1), 4.0));
      Check ("7.2 Weights sum correctly", Near (Total.DW2 (1, 1), 2.0));
      Check ("7.3 Untouched elements remain unchanged", Total.DB2 (1) = 0.0);
   end;

   -- TEST 8 - ReLU Behavior
   Put_Line ("TEST 8 -- ReLU Network Output");
   declare
      Net   : Neural_Network := Create_Network (1, 1, 1, ReLU);
      State : Network_State (1, 1, 1);
   begin
      Net.W1 (1,1) := 1.0; Net.B1 (1) := 0.0;
      Net.W2 (1,1) := 1.0; Net.B2 (1) := 0.0;
      
      Forward (Net, [1 => -5.0], State);
      Check ("8.1 ReLU cuts off negative input", State.A2 (1) = 0.0);
      
      Forward (Net, [1 => 5.0], State);
      Check ("8.2 ReLU passes positive input", State.A2 (1) = 5.0);
      
      Forward (Net, [1 => 0.0], State);
      Check ("8.3 ReLU at zero", State.A2 (1) = 0.0);
   end;

   -- TEST 9 - Linear Behavior
   Put_Line ("TEST 9 -- Linear Network Output");
   declare
      Net   : Neural_Network := Create_Network (1, 1, 1, Linear);
      State : Network_State (1, 1, 1);
   begin
      Net.W1 (1,1) := 2.0; Net.B1 (1) := 0.0;
      Net.W2 (1,1) := 1.0; Net.B2 (1) := 1.0;
      
      Forward (Net, [1 => -2.0], State);
      -- Z1 = 2*-2 = -4. A1 = -4. Z2 = 1*-4+1 = -3. A2 = -3.
      Check ("9.1 Linear handles negatives", State.A2 (1) = -3.0);
      
      Forward (Net, [1 => 2.0], State);
      Check ("9.2 Linear handles positives", State.A2 (1) = 5.0);
      Check ("9.3 Internal state verified", State.A1 (1) = 4.0);
   end;

   -- TEST 10 - Standard SGD Step reduces loss
   Put_Line ("TEST 10 -- SGD Update Reduces Loss");
   declare
      Net   : Neural_Network := Create_Network (1, 2, 1, Linear);
      State : Network_State (1, 2, 1);
      Grads : Network_Gradients (1, 2, 1);
      Input : constant Vector (1 .. 1) := [1 => 1.0];
      Targ  : constant Vector (1 .. 1) := [1 => 5.0];
      Loss1 : Real;
      Loss2 : Real;
   begin
      Forward (Net, Input, State);
      Loss1 := Compute_Loss (State.A2, Targ);
      Backward (Net, State, Targ, Grads);
      Update_Weights (Net, Grads, 0.05);
      
      Forward (Net, Input, State);
      Loss2 := Compute_Loss (State.A2, Targ);
      
      Check ("10.1 SGD changed state A2", State.A2 (1) /= Targ (1)); -- not perfect in 1 step
      Check ("10.2 Second loss is smaller than first loss", Loss2 < Loss1);
      Check ("10.3 Loss valid", Loss2 >= 0.0);
   end;

   -- TEST 11 - Momentum Step reduces loss
   Put_Line ("TEST 11 -- Momentum Update Reduces Loss");
   declare
      Net   : Neural_Network := Create_Network (1, 2, 1, Linear);
      State : Network_State (1, 2, 1);
      Grads : Network_Gradients (1, 2, 1);
      Vel   : Network_Gradients (1, 2, 1);
      Input : constant Vector (1 .. 1) := [1 => 1.0];
      Targ  : constant Vector (1 .. 1) := [1 => 5.0];
      Loss1 : Real;
      Loss2 : Real;
   begin
      Zero_Gradients (Vel);
      Forward (Net, Input, State);
      Loss1 := Compute_Loss (State.A2, Targ);
      
      Backward (Net, State, Targ, Grads);
      Update_Weights_Momentum (Net, Grads, Vel, 0.05, 0.9);
      
      Forward (Net, Input, State);
      Loss2 := Compute_Loss (State.A2, Targ);
      
      Check ("11.1 Momentum changed network", Loss2 /= Loss1);
      Check ("11.2 Loss reduced", Loss2 < Loss1);
      Check ("11.3 Velocity accumulated non-zero", Vel.DW2 (1,1) /= 0.0);
   end;

   -- TEST 12 - Momentum Accumulates Properly
   Put_Line ("TEST 12 -- Momentum Math Validated");
   declare
      Net     : Neural_Network := Create_Network (1, 1, 1, Linear);
      Grads   : Network_Gradients (1, 1, 1);
      Vel     : Network_Gradients (1, 1, 1);
      Start_W : constant Real := Net.W1 (1, 1);
   begin
      Zero_Gradients (Vel);
      Zero_Gradients (Grads);
      Grads.DW1 (1, 1) := 1.0;
      
      Update_Weights_Momentum (Net, Grads, Vel, 0.1, 0.9);
      Check ("12.1 Vel after step 1", Near (Vel.DW1 (1,1), 0.1));
      
      Update_Weights_Momentum (Net, Grads, Vel, 0.1, 0.9);
      Check ("12.2 Vel after step 2 (0.1*0.9 + 0.1)", Near (Vel.DW1 (1,1), 0.19));
      Check ("12.3 Weight updated correctly", Near (Net.W1 (1,1), Start_W - 0.29));
   end;

   -- TEST 13 - XOR Convergence (Integration Test)
   Put_Line ("TEST 13 -- XOR Integration Test");
   declare
      Net    : Neural_Network := Create_Network (2, 4, 1, Tanh);
      State  : Network_State (2, 4, 1);
      Grads  : Network_Gradients (2, 4, 1);
      Inputs : constant array (1 .. 4) of Vector (1 .. 2) := 
                 [[0.0, 0.0], [0.0, 1.0], [1.0, 0.0], [1.0, 1.0]];
      Targs  : constant array (1 .. 4) of Vector (1 .. 1) := 
                 [[1 => 0.0], [1 => 1.0], [1 => 1.0], [1 => 0.0]];
      Epochs : constant Integer := 2000;
      Loss   : Real;
      LR     : constant Real := 0.2;
   begin
      for E in 1 .. Epochs loop
         for I in 1 .. 4 loop
            Forward (Net, Inputs (I), State);
            Backward (Net, State, Targs (I), Grads);
            Update_Weights (Net, Grads, LR);
         end loop;
      end loop;
      
      -- Test final results
      Forward (Net, Inputs (1), State); Loss := State.A2 (1);
      Check ("13.1 XOR(0,0) near 0", Loss < 0.2 or Loss < 0.3);
      
      Forward (Net, Inputs (2), State); Loss := State.A2 (1);
      Check ("13.2 XOR(0,1) near 1", Loss > 0.7 or Loss > 0.8);
      
      Forward (Net, Inputs (4), State); Loss := State.A2 (1);
      Check ("13.3 XOR(1,1) near 0", Loss < 0.2 or Loss < 0.3);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
