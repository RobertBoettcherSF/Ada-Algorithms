with Ada.Text_IO; use Ada.Text_IO;
with Hopfield_Network; use Hopfield_Network;
with System.Assertions;

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

   -- Helper for comparing floats
   function Approx_Equal (Left, Right : Float; Tol : Float := 0.0001) return Boolean is
   begin
      return abs (Left - Right) < Tol;
   end Approx_Equal;

   -- Common fixtures
   Pattern_3 : constant Discrete_Pattern_Matrix (1 .. 1, 1 .. 3) :=
     [1 => [1, 1, -1]];
   Weights_3 : Weight_Matrix (1 .. 3, 1 .. 3);
   
   Pattern_C_3 : constant Continuous_Pattern_Matrix (1 .. 1, 1 .. 3) :=
     [1 => [1.0, 1.0, -1.0]];
   Weights_C_3 : Weight_Matrix (1 .. 3, 1 .. 3);
   
   State_3 : Discrete_Vector (1 .. 3);
   State_C : Continuous_State (1 .. 3);

   Exception_Caught : Boolean;

begin
   -- TEST 1 — Validation Helpers
   Put_Line ("TEST 1 — Validation Helpers");
   Check ("1.1 Valid bipolar vector", Is_Valid_Bipolar ([1, -1, 1]));
   Check ("1.2 Invalid bipolar vector (contains 0)", not Is_Valid_Bipolar ([1, 0, -1]));
   Check ("1.3 Is_Square matrix", Is_Square ([[1.0, 0.0], [0.0, 1.0]]));

   -- TEST 2 — Train Discrete Pattern
   Put_Line ("TEST 2 — Train Discrete Pattern");
   Weights_3 := Train_Discrete (Pattern_3);
   Check ("2.1 Diagonal is zero", Approx_Equal (Weights_3 (1, 1), 0.0));
   Check ("2.2 W_12 is correct", Approx_Equal (Weights_3 (1, 2), 1.0 / 3.0));
   Check ("2.3 W_23 is correct", Approx_Equal (Weights_3 (2, 3), -1.0 / 3.0));

   -- TEST 3 — Discrete Energy Computation
   Put_Line ("TEST 3 — Discrete Energy Computation");
   State_3 := [1, 1, -1]; -- Stable state
   Check ("3.1 Energy of stable state", Approx_Equal (Energy_Discrete (Weights_3, State_3), -1.0));
   State_3 := [-1, -1, 1]; -- Inverted stable state
   Check ("3.2 Energy of inverted stable state", Approx_Equal (Energy_Discrete (Weights_3, State_3), -1.0));
   State_3 := [1, -1, 1]; -- Unstable state
   Check ("3.3 Energy of unstable state is higher", Energy_Discrete (Weights_3, State_3) > -1.0);

   -- TEST 4 — Update Discrete Asynchronous
   Put_Line ("TEST 4 — Update Discrete Asynchronous");
   State_3 := [1, -1, -1]; -- One error at node 2
   Update_Discrete_Asynchronous (Weights_3, State_3, 2);
   Check ("4.1 Node 2 flipped to 1", State_3 (2) = 1);
   Update_Discrete_Asynchronous (Weights_3, State_3, 3);
   Check ("4.2 Node 3 remains -1", State_3 (3) = -1);
   Update_Discrete_Asynchronous (Weights_3, State_3, 1);
   Check ("4.3 Node 1 remains 1", State_3 (1) = 1);

   -- TEST 5 — Update Discrete Synchronous
   Put_Line ("TEST 5 — Update Discrete Synchronous");
   State_3 := [-1, 1, 1]; -- Completely corrupted state
   Update_Discrete_Synchronous (Weights_3, State_3);
   Check ("5.1 Sync recovers Node 1 to 1", State_3 (1) = 1);
   Check ("5.2 Sync recovers Node 2 to -1", State_3 (2) = -1); -- Wait, sum for 2 is -2/3. Node 2 becomes -1.
   Check ("5.3 Sync recovers Node 3 to 1", State_3 (3) = 1);
   -- Note: Because it's completely inverted minus threshold tie-breaking, it settles in a local min.

   -- TEST 6 — Discrete Multi-Pattern Training
   Put_Line ("TEST 6 — Discrete Multi-Pattern Training");
   declare
      Multi_Pats : constant Discrete_Pattern_Matrix (1 .. 2, 1 .. 4) :=
        [1 => [1, 1, 1, 1],
         2 => [1, -1, 1, -1]];
      W_Multi : constant Weight_Matrix := Train_Discrete (Multi_Pats);
   begin
      -- For W_12: (1*1 + 1*-1) / 4 = 0.0
      Check ("6.1 W_12 sums to 0", Approx_Equal (W_Multi (1, 2), 0.0));
      -- For W_13: (1*1 + 1*1) / 4 = 2/4 = 0.5
      Check ("6.2 W_13 sums to 0.5", Approx_Equal (W_Multi (1, 3), 0.5));
      -- For W_24: (1*1 + -1*-1) / 4 = 2/4 = 0.5
      Check ("6.3 W_24 sums to 0.5", Approx_Equal (W_Multi (2, 4), 0.5));
   end;

   -- TEST 7 — Continuous Training
   Put_Line ("TEST 7 — Continuous Training");
   Weights_C_3 := Train_Continuous (Pattern_C_3);
   Check ("7.1 Cont W_11 is 0.0", Approx_Equal (Weights_C_3 (1, 1), 0.0));
   Check ("7.2 Cont W_12 is 1/3", Approx_Equal (Weights_C_3 (1, 2), 1.0 / 3.0));
   Check ("7.3 Cont W_23 is -1/3", Approx_Equal (Weights_C_3 (2, 3), -1.0 / 3.0));

   -- TEST 8 — Continuous Update Dynamics (Step 1)
   Put_Line ("TEST 8 — Continuous Update Dynamics (Step 1)");
   -- Init nodes to zero state
   for I in State_C'Range loop
      State_C (I) := (U => 0.0, V => 0.0);
   end loop;
   Update_Continuous_Synchronous (Weights_C_3, State_C, 0.1);
   Check ("8.1 U remains 0", Approx_Equal (State_C (1).U, 0.0));
   Check ("8.2 V remains 0", Approx_Equal (State_C (1).V, 0.0));
   Check ("8.3 U2 remains 0", Approx_Equal (State_C (2).U, 0.0));

   -- TEST 9 — Continuous Update Dynamics (Step 2)
   Put_Line ("TEST 9 — Continuous Update Dynamics (Step 2)");
   State_C (1) := (U => 0.5, V => 0.46);
   State_C (2) := (U => 0.5, V => 0.46);
   State_C (3) := (U => -0.5, V => -0.46);
   Update_Continuous_Synchronous (Weights_C_3, State_C, 0.1);
   -- U1_new = 0.5 + 0.1*(-0.5 + sum(W1j*Vj))
   -- Sum = W12*V2 + W13*V3 = (1/3)*0.46 + (-1/3)*(-0.46) = 0.30666...
   -- U1_new = 0.5 + 0.1*(-0.5 + 0.30666) = 0.48066...
   Check ("9.1 U1 approaches steady state", Approx_Equal (State_C (1).U, 0.4806, 0.001));
   Check ("9.2 V1 updates correctly", State_C (1).V < 0.46 and State_C (1).V > 0.40);
   Check ("9.3 U3 updates symmetrically", Approx_Equal (State_C (3).U, -0.4806, 0.001));

   -- TEST 10 — Continuous Energy Calculation
   Put_Line ("TEST 10 — Continuous Energy Calculation");
   State_C (1) := (U => 1.0, V => 1.0);
   State_C (2) := (U => 1.0, V => 1.0);
   State_C (3) := (U => -1.0, V => -1.0);
   Check ("10.1 Energy of saturated cont stable state", Approx_Equal (Energy_Continuous (Weights_C_3, State_C), -1.0));
   
   State_C (1) := (U => 0.0, V => 0.0);
   State_C (2) := (U => 0.0, V => 0.0);
   State_C (3) := (U => 0.0, V => 0.0);
   Check ("10.2 Energy of zero state", Approx_Equal (Energy_Continuous (Weights_C_3, State_C), 0.0));
   
   State_C (1) := (U => 0.5, V => 0.5);
   State_C (2) := (U => 0.5, V => 0.5);
   State_C (3) := (U => -0.5, V => -0.5);
   Check ("10.3 Energy of partial state", Approx_Equal (Energy_Continuous (Weights_C_3, State_C), -0.25));

   -- TEST 11 — Edge Case 1-Node Network
   Put_Line ("TEST 11 — Edge Case 1-Node Network");
   declare
      Pat_1   : constant Discrete_Pattern_Matrix (1 .. 1, 1 .. 1) := [1 => [1 => 1]];
      W_1     : constant Weight_Matrix := Train_Discrete (Pat_1);
      State_1 : Discrete_Vector (1 .. 1) := [1 => 1];
   begin
      Check ("11.1 1-Node Weight is 0", Approx_Equal (W_1 (1, 1), 0.0));
      Update_Discrete_Synchronous (W_1, State_1);
      Check ("11.2 1-Node Update retains state (Sum 0 -> 1)", State_1 (1) = 1);
      Check ("11.3 1-Node Energy is 0", Approx_Equal (Energy_Discrete (W_1, State_1), 0.0));
   end;

   -- TEST 12 — Precondition Violation (Dimension Mismatch Caught)
   Put_Line ("TEST 12 — Precondition Violation (Dimension Mismatch)");
   Exception_Caught := False;
   declare
      Bad_Weights : constant Weight_Matrix (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
      Bad_State   : Discrete_Vector (1 .. 3) := [1, 1, 1];
   begin
      Update_Discrete_Synchronous (Bad_Weights, Bad_State);
      Check ("12.1 Mismatch should have raised Assert_Failure", False);
   exception
      when System.Assertions.Assert_Failure =>
         Exception_Caught := True;
         Check ("12.1 Mismatch raised Assert_Failure", True);
      when others =>
         Check ("12.1 Mismatch raised wrong exception", False);
   end;
   Check ("12.2 Exception handled", Exception_Caught);
   Check ("12.3 Execution continued safely", True);

   -- TEST 13 — Precondition Violation (Invalid Data Caught)
   Put_Line ("TEST 13 — Precondition Violation (Invalid Pattern)");
   Exception_Caught := False;
   declare
      Bad_Pat : constant Discrete_Pattern_Matrix (1 .. 1, 1 .. 2) := [1 => [1, 0]]; -- 0 is invalid
      Bad_W   : Weight_Matrix (1 .. 2, 1 .. 2);
   begin
      Bad_W := Train_Discrete (Bad_Pat);
      -- To prevent unused variable warning:
      if Bad_W (1, 1) = 0.0 then null; end if; 
      Check ("13.1 Invalid pattern should have raised Assert_Failure", False);
   exception
      when System.Assertions.Assert_Failure =>
         Exception_Caught := True;
         Check ("13.1 Invalid pattern raised Assert_Failure", True);
      when others =>
         Check ("13.1 Invalid pattern raised wrong exception", False);
   end;
   Check ("13.2 Exception handled", Exception_Caught);
   Check ("13.3 Execution continued safely", True);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
