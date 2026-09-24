-- tests.adb
-- Verification & Validation Test Suite for Push-Relabel Algorithm
with Ada.Text_IO; use Ada.Text_IO;
with Push_Relabel; use Push_Relabel;

procedure Tests is

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      [FAIL]: " & Message);
         raise Program_Error with Message;
      else
         Put_Line ("      [PASS]: Assumption proven false. " & Message);
      end if;
   end Assert;
   
   -- Reusable test graphs
   Simple_G  : Adjacency_Matrix(1 .. 2, 1 .. 2) := (others => (others => 0));
   Diamond_G : Adjacency_Matrix(1 .. 4, 1 .. 4) := (others => (others => 0));
   Bottle_G  : Adjacency_Matrix(1 .. 3, 1 .. 3) := (others => (others => 0));
   Disconn_G : Adjacency_Matrix(1 .. 3, 1 .. 3) := (others => (others => 0));

begin
   -- Initialize Graphs
   Simple_G(1, 2) := 10;
   
   Diamond_G(1, 2) := 10; Diamond_G(1, 3) := 10;
   Diamond_G(2, 4) := 10; Diamond_G(3, 4) := 10;
   Diamond_G(2, 3) := 5;  -- Total Max Flow should be 20
   
   Bottle_G(1, 2) := 100;
   Bottle_G(2, 3) := 1;   -- Max flow bottlenecked to 1
   
   Disconn_G(1, 2) := 10; -- Node 3 (Sink) unreachable from 1 (Source)
   
   Put_Line ("--------------------------------------------------");
   Put_Line ("TEST 1 - Generic Push-Relabel Validation");
   Put_Line ("  Assumption: Generic variant fails to calculate basic/complex flows.");
   Assert (Generic_Max_Flow(Simple_G, 1, 2) = 10, "1.1 Simple 2-Node Graph yields correct capacity.");
   Assert (Generic_Max_Flow(Diamond_G, 1, 4) = 20, "1.2 Diamond 4-Node Graph merges flows correctly.");
   Assert (Generic_Max_Flow(Disconn_G, 1, 3) = 0, "1.3 Disconnected Sink yields 0 flow.");

   Put_Line ("--------------------------------------------------");
   Put_Line ("TEST 2 - FIFO Push-Relabel Validation");
   Put_Line ("  Assumption: FIFO Queue mismanages active nodes.");
   Assert (FIFO_Max_Flow(Simple_G, 1, 2) = 10, "2.1 Simple 2-Node Graph yields correct capacity.");
   Assert (FIFO_Max_Flow(Diamond_G, 1, 4) = 20, "2.2 Diamond Graph paths resolve correctly via Queue.");
   Assert (FIFO_Max_Flow(Bottle_G, 1, 3) = 1, "2.3 Bottleneck graph properly queues back-flows.");

   Put_Line ("--------------------------------------------------");
   Put_Line ("TEST 3 - Highest-Label Push-Relabel Validation");
   Put_Line ("  Assumption: Height heuristics break standard capacity calculations.");
   Assert (Highest_Label_Max_Flow(Simple_G, 1, 2) = 10, "3.1 Simple 2-Node Graph yields correct capacity.");
   Assert (Highest_Label_Max_Flow(Diamond_G, 1, 4) = 20, "3.2 Diamond Graph resolves without looping.");
   Assert (Highest_Label_Max_Flow(Bottle_G, 1, 3) = 1, "3.3 Backward flows strictly follow height gradient.");

   Put_Line ("--------------------------------------------------");
   Put_Line ("TEST 4 - Edge Cases, Invalid Inputs & Side Effects");
   Put_Line ("  Assumption: The code lacks robust error handling and will crash unexpectedly.");
   
   begin
      declare Result : Flow_Type := Generic_Max_Flow(Simple_G, 1, 1); begin null; end;
      Assert(False, "Failed to catch Source=Sink error");
   exception
      when Source_Sink_Error => Assert(True, "4.1 Raised Source_Sink_Error when Source = Sink.");
   end;

   begin
      declare Result : Flow_Type := FIFO_Max_Flow(Simple_G, 5, 2); begin null; end;
      Assert(False, "Failed to catch Source out of bounds");
   exception
      when Source_Sink_Error => Assert(True, "4.2 Raised Source_Sink_Error when Source is outside matrix bounds.");
   end;

   begin
      declare Result : Flow_Type := Highest_Label_Max_Flow(Simple_G, 1, 99); begin null; end;
      Assert(False, "Failed to catch Sink out of bounds");
   exception
      when Source_Sink_Error => Assert(True, "4.3 Raised Source_Sink_Error when Sink is outside matrix bounds.");
   end;

   begin
      declare
         Empty_G : Adjacency_Matrix(1 .. 0, 1 .. 0);
         Result  : Flow_Type := Generic_Max_Flow(Empty_G, 1, 2);
      begin null; end;
      Assert(False, "Failed to catch Empty Graph error");
   exception
      when Empty_Graph_Error => Assert(True, "4.4 Raised Empty_Graph_Error on length-0 graph definition.");
   end;

   Put_Line ("--------------------------------------------------");
   Put_Line ("All tests completed successfully. Initial pessimistic assumptions disproved.");
end Tests;
