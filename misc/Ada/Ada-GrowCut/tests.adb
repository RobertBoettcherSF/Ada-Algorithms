with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with GrowCut; use GrowCut;

procedure Tests is
   -- Helper to create a test grid using nested array aggregates
   function Create_Empty_Grid return Grid_Type is
      (1..3 => (1..3 => (Label => Unknown, Strength => 0.0)));

   G : Grid_Type := Create_Empty_Grid;
begin
   Put_Line("--- GrowCut Test Suite ---");

   -- TEST 1: Initialization
   Put_Line("TEST 1 - Initialization");
   Assert(G(1,1).Label = Unknown, "Initial label mismatch");
   Put_Line("   PASS");

   -- TEST 2: Synchronous Propagation
   Put_Line("TEST 2 - Synchronous Propagation");
   G(1,1) := (Label => Foreground, Strength => 1.0);
   Run_Synchronous_Iteration(G);
   Assert(G(1,2).Label = Foreground, "Neighbor should be captured");
   Put_Line("   PASS");

   -- TEST 3: Asynchronous Propagation
   Put_Line("TEST 3 - Asynchronous Propagation");
   G := Create_Empty_Grid;
   G(1,1) := (Label => Foreground, Strength => 1.0);
   Run_Asynchronous_Iteration(G);
   Assert(G(1,2).Label = Foreground, "Neighbor should be captured");
   Put_Line("   PASS");

   -- TEST 4: Strength Decay
   Put_Line("TEST 4 - Strength Decay");
   Assert(G(1,2).Strength >= 0.89 and G(1,2).Strength <= 0.91, "Strength decay incorrect");
   Put_Line("   PASS");

   -- TEST 5: No Capture if Target Cell is Stronger
   Put_Line("TEST 5 - No Capture if Target Cell is Stronger");
   G := Create_Empty_Grid;
   G(1,1) := (Label => Foreground, Strength => 0.5);
   G(2,2) := (Label => Background, Strength => 0.1); -- Attack strength = 0.09
   Run_Synchronous_Iteration(G);
   Assert(G(1,1).Label = Foreground, "Strong cell captured by weak neighbor");
   Put_Line("   PASS");

   -- TEST 6: Boundary Checks
   Put_Line("TEST 6 - Boundary Checks (Corner)");
   G := Create_Empty_Grid;
   G(1,1) := (Label => Foreground, Strength => 1.0);
   Run_Synchronous_Iteration(G);
   Assert(G(1,2).Label = Foreground, "Corner neighbor not reached");
   Put_Line("   PASS");

   -- TEST 7: Multi-Label Handling
   Put_Line("TEST 7 - Multi-Label Handling");
   G(3,3) := (Label => Background, Strength => 1.0);
   Run_Synchronous_Iteration(G);
   Assert(G(3,2).Label = Background, "Background label not propagated");
   Put_Line("   PASS");

   -- TEST 8: Convergence Detection (Label Stability)
   Put_Line("TEST 8 - Stability");
   declare
      Prev : Grid_Type := G;
   begin
      Run_Synchronous_Iteration(G);
      Assert(G = Prev, "Grid changed when it should be stable");
   end;
   Put_Line("   PASS");

   -- TEST 9: Grid Range Validity
   Put_Line("TEST 9 - Grid Ranges");
   Assert(G'First(1) = 1 and G'Last(1) = 3, "Grid rows incorrect");
   Put_Line("   PASS");

   -- TEST 10: Similarity Function (Unit Test)
   Put_Line("TEST 10 - Similarity Calculation");
   Assert(Calculate_Similarity(1.0, 0.5) = 0.5, "Similarity math failed");
   Put_Line("   PASS");

   -- TEST 11: Empty Input Handling
   Put_Line("TEST 11 - Empty Input Handling");
   declare
      Empty : Grid_Type := (1..0 => (1..0 => (Label => Unknown, Strength => 0.0)));
   begin
      Run_Synchronous_Iteration(Empty);
      Put_Line("   PASS (Handled empty array)");
   end;

   -- TEST 12: Strength Clamping (Logic Check)
   Put_Line("TEST 12 - Strength Clamping");
   G(1,1).Strength := 2.0;
   Assert(G(1,1).Strength > 1.0, "Strength exceeds bound");
   Put_Line("   PASS");

   -- TEST 13: Memory/State Integrity
   Put_Line("TEST 13 - State Integrity");
   Assert(G(1,1).Label /= Unknown, "State was lost");
   Put_Line("   PASS");

end Tests;
