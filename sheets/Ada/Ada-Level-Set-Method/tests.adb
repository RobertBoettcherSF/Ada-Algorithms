-- tests.adb
-- Validates functional correctness and boundary cases of the Level Set implementation.
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Level_Set_Method; use Level_Set_Method;

procedure Tests is
   Grid : Grid_2D (1 .. 10, 1 .. 10);
   Small_Grid : Grid_2D (1 .. 2, 1 .. 2);
begin
   Put_Line ("=====================================");
   Put_Line ("Level Set Method Test Suite");
   Put_Line ("=====================================");

   -- TEST 1
   Put_Line ("TEST 1 - Initialization (Inside Circle)");
   Initialize_Circle (Grid, 5.0, 5.0, 3.0);
   Put_Line ("  1.1 Assert center (5,5) is highly negative");
   Assert (Grid (5, 5) = -3.0, "Center value incorrect");
   Put_Line ("      PASS");
   Put_Line ("  1.2 Assert point (6,5) is negative");
   Assert (Grid (6, 5) < 0.0, "Inside point incorrect");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Initialization (Outside Circle)");
   Put_Line ("  2.1 Assert point (1,1) is positive");
   Assert (Grid (1, 1) > 0.0, "Outside point should be positive");
   Put_Line ("      PASS");
   Put_Line ("  2.2 Assert point (10,10) is positive");
   Assert (Grid (10, 10) > 0.0, "Outside point should be positive");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Initialization (Boundary)");
   Initialize_Circle (Grid, 5.0, 5.0, 2.0);
   Put_Line ("  3.1 Assert point exactly on radius is 0");
   Assert (Grid (7, 5) = 0.0, "Boundary point incorrect");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Basic Update (Expansion)");
   Initialize_Circle (Grid, 5.0, 5.0, 2.0);
   Update_Basic (Grid, dt => 1.0, F => 1.0); -- Outward speed
   Put_Line ("  4.1 Assert point at (7,5) becomes negative (interface moved out)");
   Assert (Grid (7, 5) < 0.0, "Expansion failed");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Basic Update (Contraction)");
   Initialize_Circle (Grid, 5.0, 5.0, 3.0);
   Update_Basic (Grid, dt => 1.0, F => -1.0); -- Inward speed
   Put_Line ("  5.1 Assert point at (8,5) becomes more positive");
   Assert (Grid (8, 5) > 0.0, "Contraction failed");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Zero Time Step");
   Initialize_Circle (Grid, 5.0, 5.0, 3.0);
   declare
      Old_Val : constant Real := Grid (2, 2);
   begin
      Update_Basic (Grid, dt => 0.0, F => 5.0);
      Put_Line ("  6.1 Assert dt=0 produces no change");
      Assert (Grid (2, 2) = Old_Val, "dt=0 modified grid");
      Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Narrow Band (Outside Unchanged)");
   Initialize_Circle (Grid, 5.0, 5.0, 2.0);
   declare
      Old_Outside : constant Real := Grid (1, 1);
   begin
      Update_Narrow_Band (Grid, dt => 1.0, F => 1.0, Band_Width => 1.5);
      Put_Line ("  7.1 Assert outside point ignored");
      Assert (Grid (1, 1) = Old_Outside, "Narrow band altered distant point");
      Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Narrow Band (Inside Changed)");
   Initialize_Circle (Grid, 5.0, 5.0, 2.0);
   declare
      Old_Inside : constant Real := Grid (7, 5); -- Phi = 0.0
   begin
      Update_Narrow_Band (Grid, dt => 1.0, F => 1.0, Band_Width => 1.5);
      Put_Line ("  8.1 Assert inside band point altered");
      Assert (Grid (7, 5) /= Old_Inside, "Narrow band missed valid point");
      Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Reinitialization (Preserves Zero Level)");
   Initialize_Circle (Grid, 5.0, 5.0, 2.0);
   Grid (7, 5) := 0.0; -- Manually ensure zero
   Reinitialize (Grid, Iterations => 5, dt => 0.1);
   Put_Line ("  9.1 Assert zero interface does not shift");
   Assert (abs (Grid (7, 5)) < 0.05, "Reinitialization moved zero set wildly");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Exception Handling (Grid Too Small)");
   Put_Line ("  10.1 Assert Grid_Too_Small raised on 2x2 grid");
   begin
      Update_Basic (Small_Grid, dt => 0.1, F => 1.0);
      Assert (False, "Exception not raised for small grid");
   exception
      when Grid_Too_Small => Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Exception Handling (Invalid Time Step)");
   Put_Line ("  11.1 Assert negative time step is rejected");
   begin
      Update_Basic (Grid, dt => -0.5, F => 1.0);
      Assert (False, "Exception not raised for negative dt");
   exception
      when Invalid_Time_Step => Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Boundary Conditions (Stability)");
   Put_Line ("  12.1 Assert corners don't produce NaN during computation");
   Initialize_Circle (Grid, 5.0, 5.0, 5.0);
   Update_Basic (Grid, dt => 0.1, F => 1.0);
   Assert (Grid (1, 1) < 100.0, "Boundary condition unstable");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Zero Speed Function");
   Initialize_Circle (Grid, 5.0, 5.0, 2.0);
   declare
      Old_Val : constant Real := Grid (6, 5);
   begin
      Update_Basic (Grid, dt => 1.0, F => 0.0);
      Put_Line ("  13.1 Assert F=0 produces no movement");
      Assert (Grid (6, 5) = Old_Val, "Grid changed despite zero speed");
      Put_Line ("      PASS");
   end;

   -- TEST 14
   Put_Line ("TEST 14 - Reinitialization (Corrects Slope)");
   -- Distort the gradient
   Grid (5, 5) := -10.0; 
   Grid (6, 5) := -5.0;  
   Grid (7, 5) := 0.0;   
   Put_Line ("  14.1 Assert Reinit smooths steep gradients");
   Reinitialize (Grid, Iterations => 10, dt => 0.1);
   Assert (abs (Grid (6, 5)) < 4.0, "Gradient wasn't normalized towards 1.0");
   Put_Line ("      PASS");

   Put_Line ("=====================================");
   Put_Line ("ALL TESTS COMPLETED SUCCESSFULLY");
   Put_Line ("=====================================");
end Tests;
