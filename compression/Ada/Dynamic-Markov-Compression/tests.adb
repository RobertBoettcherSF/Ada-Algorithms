with Ada.Text_IO; use Ada.Text_IO;
with Dynamic_Markov_Compression; use Dynamic_Markov_Compression;

procedure Tests is
   Passed_All : Boolean := True;
   M : DMC_Model;

   procedure Assert (Condition : Boolean; Desc : String) is
   begin
      if Condition then
         Put_Line ("      PASS: " & Desc);
      else
         Put_Line ("      FAIL: " & Desc);
         Passed_All := False;
      end if;
   end Assert;

begin
   Put_Line ("TEST 1 - Model Initialization (Single Variant)");
   M.Initialize (Init_Type => Single_State);
   Assert (M.Get_State_Count = 1, "1.1 Single State mode creates exactly 1 node");
   Assert (M.Predict_Zero = 0.5, "1.2 Initial probability is balanced (0.5)");

   Put_Line ("TEST 2 - Model Initialization (Order Zero Variant)");
   M.Initialize (Init_Type => Order_Zero);
   Assert (M.Get_State_Count = 255, "2.1 Order Zero creates 255 nodes");
   Assert (M.Current_State = 0, "2.2 Starts at root node (0)");

   Put_Line ("TEST 3 - Probability Integrity");
   M.Initialize (Single_State);
   M.Update (0);
   Assert (M.Predict_Zero > 0.5, "3.1 Feeding '0' correctly increases P(0)");
   Assert (M.Predict_One < 0.5, "3.2 Feeding '0' correctly decreases P(1)");
   Assert (abs((M.Predict_Zero + M.Predict_One) - 1.0) < 0.0001, "3.3 Probabilities sum strictly to 1.0");

   Put_Line ("TEST 4 - Dynamic Update Mechanics");
   Assert (M.Current_State = 0, "4.1 State loopback works as expected on 1-node model");
   M.Update (1);
   Assert (M.Predict_Zero = 0.5, "4.2 Counter-balancing pattern normalizes probabilities");

   Put_Line ("TEST 5 - State Transition Accuracy");
   M.Initialize (Order_Zero);
   M.Update (0);
   Assert (M.Current_State = 1, "5.1 '0' transition moves to left child (Node 1)");
   M.Initialize (Order_Zero);
   M.Update (1);
   Assert (M.Current_State = 2, "5.2 '1' transition moves to right child (Node 2)");

   Put_Line ("TEST 6 - State Cloning Triggering");
   -- Force clone condition: Min=0, Max=0
   M.Initialize (Single_State, Min_Cnt => 0, Max_Cnt => 0);
   M.Update (0);
   Assert (M.Get_State_Count = 2, "6.1 State cloning triggers when threshold breached");
   
   Put_Line ("TEST 7 - Cloning Ratio Integrity");
   -- Checking if clone logic prevents 0 probabilities internally
   Assert (M.Predict_Zero > 0.0 and M.Predict_One > 0.0, "7.1 Cloned states retain valid non-zero probabilities");
   
   Put_Line ("TEST 8 - Minimum Count Boundary");
   M.Initialize (Single_State, Min_Cnt => 10, Max_Cnt => 10);
   for I in 1 .. 9 loop M.Update (0); end loop;
   Assert (M.Get_State_Count = 1, "8.1 Prevents cloning if MIN_CNT/MAX_CNT boundaries unmet");

   Put_Line ("TEST 9 - Memory Bound Limit");
   M.Initialize (Single_State, Min_Cnt => 0, Max_Cnt => 0, Max_Memory => 3);
   M.Update (0); -- Clones (Count 2)
   M.Update (0); -- Clones (Count 3)
   M.Update (0); -- Blocked by limit
   Assert (M.Get_State_Count = 3, "9.1 Respects Max_Memory ceiling limits strictly");
   
   Put_Line ("TEST 10 - Reset Functionality");
   M.Reset_To_Start;
   Assert (M.Current_State = 0, "10.1 Reset successfully rewinds to root state");

   Put_Line ("TEST 11 - Deterministic Execution");
   declare
      M1, M2 : DMC_Model;
   begin
      M1.Initialize; M2.Initialize;
      M1.Update (1); M1.Update (0);
      M2.Update (1); M2.Update (0);
      Assert (M1.Predict_Zero = M2.Predict_Zero, "11.1 Identical models process identically");
   end;

   Put_Line ("TEST 12 - Overflow Protection");
   M.Initialize (Single_State, Min_Cnt => 100000, Max_Cnt => 100000);
   for I in 1 .. 500 loop
      M.Update (1);
   end loop;
   Assert (M.Get_State_Count = 1, "12.1 Survives large continuous identical ingestion without Constraint_Error");
   
   Put_Line ("TEST 13 - Probability Reversal (Learning)");
   M.Initialize (Single_State);
   for I in 1 .. 10 loop M.Update (0); end loop;
   declare
      High_P_Zero : constant Float := M.Predict_Zero;
   begin
      for I in 1 .. 30 loop M.Update (1); end loop;
      Assert (M.Predict_Zero < High_P_Zero, "13.1 Model successfully adapts/forgets old biases");
   end;

   if not Passed_All then
      Put_Line ("SOME TESTS FAILED.");
      -- Return non-zero conceptually for makefile
   else
      Put_Line ("ALL TESTS PASSED.");
   end if;
end Tests;
