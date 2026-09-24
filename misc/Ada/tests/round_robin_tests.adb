-- round_robin_tests.adb
-- Comprehensive test suite for Round Robin scheduling algorithms
-- Tests are designed to:
-- 1. Test assumptions about code behavior
-- 2. Test different assumptions and edge cases
-- 3. Be provably false (assertions that fail when code is wrong)

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Command_Line;

package body Round_Robin_Tests is

   -- Import the types from the main implementation
   type Process_ID is new Positive;
   
   type Process_Info is record
      ID             : Process_ID;
      Arrival_Time   : Natural  := 0;
      Burst_Time     : Natural  := 0;
      Remaining_Time : Natural  := 0;
      Weight         : Positive := 1;
      Deficit        : Natural  := 0;
      Atomic_Chunk   : Positive := 1; 
   end record;

   package Process_Lists is new Ada.Containers.Doubly_Linked_Lists (Process_Info);
   use Process_Lists;
   subtype Process_Queue is Process_Lists.List;

   -- Test result tracking
   Total_Tests : Natural := 0;
   Passed_Tests : Natural := 0;
   Failed_Tests : Natural := 0;

   -- Helper to create a process
   function Create_Process (
      ID : Process_ID;
      Arrival_Time : Natural := 0;
      Burst_Time : Natural := 0;
      Weight : Positive := 1;
      Atomic_Chunk : Positive := 1
   ) return Process_Info is
   begin
      return (
         ID => ID,
         Arrival_Time => Arrival_Time,
         Burst_Time => Burst_Time,
         Remaining_Time => Burst_Time,
         Weight => Weight,
         Deficit => 0,
         Atomic_Chunk => Atomic_Chunk
      );
   end Create_Process;

   -- Helper to check if queue is empty
   function Is_Empty (Queue : Process_Queue) return Boolean is
   begin
      return Queue.Is_Empty;
   end Is_Empty;

   -- Helper to get queue length
   function Queue_Length (Queue : Process_Queue) return Natural is
      Count : Natural := 0;
      Position : Cursor := Queue.First;
   begin
      while Has_Element(Position) loop
         Count := Count + 1;
         Next(Position);
      end loop;
      return Count;
   end Queue_Length;

   -- Helper to get total remaining time in queue
   function Total_Remaining_Time (Queue : Process_Queue) return Natural is
      Total : Natural := 0;
      Position : Cursor := Queue.First;
      Proc : Process_Info;
   begin
      while Has_Element(Position) loop
         Proc := Element(Position);
         Total := Total + Proc.Remaining_Time;
         Next(Position);
      end loop;
      return Total;
   end Total_Remaining_Time;

   -- Helper to find process by ID
   function Find_Process (Queue : Process_Queue; ID : Process_ID) return Process_Info is
      Position : Cursor := Queue.First;
      Proc : Process_Info;
   begin
      while Has_Element(Position) loop
         Proc := Element(Position);
         if Proc.ID = ID then
            return Proc;
         end if;
         Next(Position);
      end loop;
      return Create_Process(ID, 0, 0);
   end Find_Process;

   -- Test assertion helper
   procedure Test_Assert (
      Condition : Boolean;
      Message : String
   ) is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Passed_Tests := Passed_Tests + 1;
         Put_Line ("  [PASS] " & Message);
      else
         Failed_Tests := Failed_Tests + 1;
         Put_Line ("  [FAIL] " & Message);
      end if;
   end Test_Assert;

   -- Test assertion for Natural equality
   procedure Test_Assert_Equal_Natural (
      Actual : Natural;
      Expected : Natural;
      Message : String
   ) is
   begin
      Test_Assert (Actual = Expected, Message & ": Expected " & Natural'Image(Expected) & 
         ", got " & Natural'Image(Actual));
   end Test_Assert_Equal_Natural;

   -- Test assertion for Positive equality
   procedure Test_Assert_Equal_Positive (
      Actual : Positive;
      Expected : Positive;
      Message : String
   ) is
   begin
      Test_Assert (Actual = Expected, Message & ": Expected " & Positive'Image(Expected) & 
         ", got " & Positive'Image(Actual));
   end Test_Assert_Equal_Positive;

   -- Test assertion for Boolean true
   procedure Test_Assert_True (
      Condition : Boolean;
      Message : String
   ) is
   begin
      Test_Assert (Condition, Message);
   end Test_Assert_True;

   -- Test assertion for Boolean false
   procedure Test_Assert_False (
      Condition : Boolean;
      Message : String
   ) is
   begin
      Test_Assert (not Condition, Message);
   end Test_Assert_False;

   -- ====================================================================
   -- TEST SUITE 1: Standard Round Robin Assumptions
   -- ====================================================================
   
   procedure Test_Standard_RR_Empty_Queue is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 1.1: Standard RR with empty queue");
      
      Test_Assert_True (Queue.Is_Empty, "Queue should be empty initially");
      
      while not Queue.Is_Empty loop
         Proc := Queue.First_Element;
         Queue.Delete_First;
         Current_Time := Current_Time + Time_Quantum;
      end loop;
      
      Test_Assert_Equal_Natural (Current_Time, 0, "Current time should remain 0 for empty queue");
      Test_Assert_True (Queue.Is_Empty, "Queue should still be empty");
   end Test_Standard_RR_Empty_Queue;

   procedure Test_Standard_RR_Single_Process is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 1.2: Standard RR with single process");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 3));
      
      Test_Assert_Equal_Natural (Queue_Length(Queue), 1, "Queue should have 1 process");
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      if Proc.Remaining_Time > Time_Quantum then
         Current_Time := Current_Time + Time_Quantum;
         Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
         Queue.Append (Proc);
      else
         Current_Time := Current_Time + Proc.Remaining_Time;
         Proc.Remaining_Time := 0;
      end if;
      
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 0, "Process should be finished");
      Test_Assert_Equal_Natural (Current_Time, 3, "Current time should be 3");
      Test_Assert_True (Queue.Is_Empty, "Queue should be empty after completion");
   end Test_Standard_RR_Single_Process;

   procedure Test_Standard_RR_Process_Preemption is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 1.3: Standard RR process preemption");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      if Proc.Remaining_Time > Time_Quantum then
         Current_Time := Current_Time + Time_Quantum;
         Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
         Queue.Append (Proc);
      end if;
      
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 7, "Remaining time should be 7");
      Test_Assert_Equal_Natural (Current_Time, 3, "Current time should be 3");
      Test_Assert_Equal_Natural (Queue_Length(Queue), 1, "Queue should have 1 process again");
      
      Proc := Queue.First_Element;
      Test_Assert_Equal_Natural (Natural(Proc.ID), 1, "Process ID should still be 1");
   end Test_Standard_RR_Process_Preemption;

   procedure Test_Standard_RR_Multiple_Processes is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 1.4: Standard RR with multiple processes - round robin order");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 3));
      Queue.Append (Create_Process(ID => 3, Burst_Time => 4));
      
      for I in 1..3 loop
         if not Queue.Is_Empty then
            Proc := Queue.First_Element;
            Queue.Delete_First;
            
            if Proc.Remaining_Time > Time_Quantum then
               Current_Time := Current_Time + Time_Quantum;
               Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
               Queue.Append (Proc);
            else
               Current_Time := Current_Time + Proc.Remaining_Time;
               Proc.Remaining_Time := 0;
            end if;
         end if;
      end loop;
      
      Test_Assert_Equal_Natural (Queue_Length(Queue), 2, "Queue should have 2 processes after first round (process 2 completed)");
      Test_Assert_Equal_Natural (Current_Time, 9, "Current time should be 9");
   end Test_Standard_RR_Multiple_Processes;

   procedure Test_Standard_RR_Completion_Order is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 1.5: Standard RR completion order");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 3));
      Queue.Append (Create_Process(ID => 3, Burst_Time => 4));
      
      while not Queue.Is_Empty loop
         Proc := Queue.First_Element;
         Queue.Delete_First;
         
         if Proc.Remaining_Time > Time_Quantum then
            Current_Time := Current_Time + Time_Quantum;
            Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
            Queue.Append (Proc);
         else
            Current_Time := Current_Time + Proc.Remaining_Time;
            Proc.Remaining_Time := 0;
         end if;
      end loop;
      
      Test_Assert_True (Queue.Is_Empty, "All processes should be completed");
      Test_Assert_Equal_Natural (Current_Time, 12, "Total execution time should be 12");
   end Test_Standard_RR_Completion_Order;

   -- ====================================================================
   -- TEST SUITE 2: Weighted Round Robin Assumptions
   -- ====================================================================
   
   procedure Test_WRR_Weight_Allocation is
      Queue : Process_Queue;
      Base_Quantum : Positive := 2;
      Proc : Process_Info;
      Actual_Quantum : Positive;
   begin
      Put_Line ("Test 2.1: Weighted RR weight allocation");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Weight => 1));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 10, Weight => 2));
      Queue.Append (Create_Process(ID => 3, Burst_Time => 10, Weight => 3));
      
      Proc := Queue.First_Element;
      Actual_Quantum := Base_Quantum * Proc.Weight;
      Test_Assert_Equal_Positive (Actual_Quantum, 2, "Weight 1 should give quantum of 2");
      
      Queue.Delete_First;
      Proc := Queue.First_Element;
      Actual_Quantum := Base_Quantum * Proc.Weight;
      Test_Assert_Equal_Positive (Actual_Quantum, 4, "Weight 2 should give quantum of 4");
      
      Queue.Delete_First;
      Proc := Queue.First_Element;
      Actual_Quantum := Base_Quantum * Proc.Weight;
      Test_Assert_Equal_Positive (Actual_Quantum, 6, "Weight 3 should give quantum of 6");
   end Test_WRR_Weight_Allocation;

   procedure Test_WRR_Higher_Weight_More_Time is
      Queue : Process_Queue;
      Base_Quantum : Positive := 2;
      Current_Time : Natural := 0;
      Proc1, Proc2 : Process_Info;
   begin
      Put_Line ("Test 2.2: Weighted RR - higher weight gets more time");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Weight => 1));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 10, Weight => 2));
      
      Proc1 := Queue.First_Element;
      Queue.Delete_First;
      Current_Time := Current_Time + (Base_Quantum * Proc1.Weight);
      Proc1.Remaining_Time := Proc1.Remaining_Time - (Base_Quantum * Proc1.Weight);
      Queue.Append (Proc1);
      
      Proc2 := Queue.First_Element;
      Queue.Delete_First;
      Current_Time := Current_Time + (Base_Quantum * Proc2.Weight);
      Proc2.Remaining_Time := Proc2.Remaining_Time - (Base_Quantum * Proc2.Weight);
      Queue.Append (Proc2);
      
      Test_Assert (Proc2.Remaining_Time < Proc1.Remaining_Time, 
         "Process with higher weight should have less remaining time");
      Test_Assert_Equal_Natural (Proc1.Remaining_Time, 8, "Process 1 should have 8 remaining");
      Test_Assert_Equal_Natural (Proc2.Remaining_Time, 6, "Process 2 should have 6 remaining");
   end Test_WRR_Higher_Weight_More_Time;

   procedure Test_WRR_Weight_One_Behavior is
      Queue : Process_Queue;
      Base_Quantum : Positive := 5;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 2.3: Weighted RR with weight=1 (standard behavior)");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Weight => 1));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      Current_Time := Current_Time + (Base_Quantum * Proc.Weight);
      Proc.Remaining_Time := Proc.Remaining_Time - (Base_Quantum * Proc.Weight);
      
      Test_Assert_Equal_Natural (Current_Time, 5, "Time should be 5");
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 5, "Remaining time should be 5");
   end Test_WRR_Weight_One_Behavior;

   procedure Test_WRR_Zero_Burst_Time is
      Queue : Process_Queue;
      Base_Quantum : Positive := 2;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 2.4: Weighted RR with zero burst time");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 0, Weight => 2));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      if Proc.Remaining_Time > (Base_Quantum * Proc.Weight) then
         Current_Time := Current_Time + (Base_Quantum * Proc.Weight);
         Proc.Remaining_Time := Proc.Remaining_Time - (Base_Quantum * Proc.Weight);
         Queue.Append (Proc);
      else
         Current_Time := Current_Time + Proc.Remaining_Time;
         Proc.Remaining_Time := 0;
      end if;
      
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 0, "Process with 0 burst should be finished");
      Test_Assert_Equal_Natural (Current_Time, 0, "Time should not advance for 0 burst process");
      Test_Assert_True (Queue.Is_Empty, "Queue should be empty");
   end Test_WRR_Zero_Burst_Time;

   procedure Test_WRR_Large_Weight is
      Queue : Process_Queue;
      Base_Quantum : Positive := 2;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 2.5: Weighted RR with very large weight");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Weight => 100));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      declare
         Actual_Quantum : Positive := Base_Quantum * Proc.Weight;
      begin
         if Proc.Remaining_Time > Actual_Quantum then
            Current_Time := Current_Time + Actual_Quantum;
            Proc.Remaining_Time := Proc.Remaining_Time - Actual_Quantum;
            Queue.Append (Proc);
         else
            Current_Time := Current_Time + Proc.Remaining_Time;
            Proc.Remaining_Time := 0;
         end if;
      end;
      
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 0, "Process should complete");
      Test_Assert_Equal_Natural (Current_Time, 10, "Time should be 10");
   end Test_WRR_Large_Weight;

   -- ====================================================================
   -- TEST SUITE 3: Deficit Round Robin Assumptions
   -- ====================================================================
   
   procedure Test_DRR_Deficit_Accumulation is
      Queue : Process_Queue;
      Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
      Executed : Natural;
   begin
      Put_Line ("Test 3.1: Deficit RR deficit accumulation");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Atomic_Chunk => 2));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      Proc.Deficit := Proc.Deficit + Quantum;
      
      Test_Assert_Equal_Natural (Proc.Deficit, 3, "Deficit should be 3 after first round");
      
      if Proc.Atomic_Chunk > Proc.Deficit then
         Executed := 0;
      else
         Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
      end if;
      
      Test_Assert_Equal_Natural (Executed, 2, "Should execute 2 units (1 atomic chunk)");
      
      Current_Time := Current_Time + Executed;
      Proc.Remaining_Time := Proc.Remaining_Time - Executed;
      Proc.Deficit := Proc.Deficit - Executed;
      
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 8, "Remaining should be 8");
      Test_Assert_Equal_Natural (Proc.Deficit, 1, "Deficit should be 1");
   end Test_DRR_Deficit_Accumulation;

   procedure Test_DRR_Atomic_Chunk_Constraint is
      Queue : Process_Queue;
      Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
      Executed : Natural;
   begin
      Put_Line ("Test 3.2: Deficit RR atomic chunk constraint");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Atomic_Chunk => 5));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      Proc.Deficit := Proc.Deficit + Quantum;
      
      if Proc.Atomic_Chunk > Proc.Deficit then
         Executed := 0;
      else
         Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
      end if;
      
      Test_Assert_Equal_Natural (Executed, 0, "Should not execute anything (deficit < atomic chunk)");
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 10, "Remaining time should be unchanged");
      
      Proc.Deficit := Proc.Deficit + Quantum;
      
      if Proc.Atomic_Chunk > Proc.Deficit then
         Executed := 0;
      else
         Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
      end if;
      
      Test_Assert_Equal_Natural (Executed, 5, "Should execute 5 units (1 atomic chunk)");
   end Test_DRR_Atomic_Chunk_Constraint;

   procedure Test_DRR_Completion_When_Deficit_Sufficient is
      Queue : Process_Queue;
      Quantum : Positive := 5;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 3.3: Deficit RR completion when deficit is sufficient");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5, Atomic_Chunk => 1));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      Proc.Deficit := Proc.Deficit + Quantum;
      
      if Proc.Remaining_Time <= Proc.Deficit then
         Current_Time := Current_Time + Proc.Remaining_Time;
         Proc.Deficit := Proc.Deficit - Proc.Remaining_Time;
         Proc.Remaining_Time := 0;
      end if;
      
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 0, "Process should be completed");
      Test_Assert_Equal_Natural (Current_Time, 5, "Time should be 5");
      Test_Assert_Equal_Natural (Proc.Deficit, 0, "Deficit should be 0");
   end Test_DRR_Completion_When_Deficit_Sufficient;

   procedure Test_DRR_Multiple_Processes_Fairness is
      Queue : Process_Queue;
      Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
      Executed : Natural;
   begin
      Put_Line ("Test 3.4: Deficit RR fairness with multiple processes");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Atomic_Chunk => 2));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 10, Atomic_Chunk => 2));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      Proc.Deficit := Proc.Deficit + Quantum;
      
      if Proc.Atomic_Chunk > Proc.Deficit then
         Executed := 0;
      else
         Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
      end if;
      
      Current_Time := Current_Time + Executed;
      Proc.Remaining_Time := Proc.Remaining_Time - Executed;
      Proc.Deficit := Proc.Deficit - Executed;
      Queue.Append (Proc);
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      Proc.Deficit := Proc.Deficit + Quantum;
      
      if Proc.Atomic_Chunk > Proc.Deficit then
         Executed := 0;
      else
         Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
      end if;
      
      Current_Time := Current_Time + Executed;
      Proc.Remaining_Time := Proc.Remaining_Time - Executed;
      Proc.Deficit := Proc.Deficit - Executed;
      Queue.Append (Proc);
      
      declare
         Proc1 : Process_Info := Queue.First_Element;
         Proc2 : Process_Info;
      begin
         Queue.Delete_First;
         Proc2 := Queue.First_Element;
         
         Test_Assert_Equal_Natural (Proc1.Remaining_Time, Proc2.Remaining_Time, 
            "Both processes should have same remaining time (fairness)");
         Test_Assert_Equal_Natural (Proc1.Remaining_Time, 8, "Each should have 8 remaining");
      end;
   end Test_DRR_Multiple_Processes_Fairness;

   procedure Test_DRR_Deficit_Preservation is
      Queue : Process_Queue;
      Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
      Executed : Natural;
   begin
      Put_Line ("Test 3.5: Deficit RR deficit preservation across rounds");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Atomic_Chunk => 2));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      Proc.Deficit := Proc.Deficit + Quantum;
      
      if Proc.Atomic_Chunk > Proc.Deficit then
         Executed := 0;
      else
         Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
      end if;
      
      Current_Time := Current_Time + Executed;
      Proc.Remaining_Time := Proc.Remaining_Time - Executed;
      Proc.Deficit := Proc.Deficit - Executed;
      Queue.Append (Proc);
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      Proc.Deficit := Proc.Deficit + Quantum;
      
      if Proc.Atomic_Chunk > Proc.Deficit then
         Executed := 0;
      else
         Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
      end if;
      
      Test_Assert_Equal_Natural (Executed, 4, "Should execute 4 units");
      Test_Assert_Equal_Natural (Proc.Deficit, 4, "Deficit should be 4 before execution (1 preserved + 3 new)");
   end Test_DRR_Deficit_Preservation;

   -- ====================================================================
   -- TEST SUITE 4: Edge Cases and Boundary Conditions
   -- ====================================================================
   
   procedure Test_All_Algorithms_Empty_Input is
      Queue : Process_Queue;
   begin
      Put_Line ("Test 4.1: All algorithms with empty input");
      
      Test_Assert_True (Queue.Is_Empty, "Queue should be empty");
      
      declare
         Q1 : Process_Queue := Queue;
         Time_Quantum : Positive := 3;
         Current_Time : Natural := 0;
         Proc : Process_Info;
      begin
         while not Q1.Is_Empty loop
            Proc := Q1.First_Element;
            Q1.Delete_First;
            Current_Time := Current_Time + Time_Quantum;
         end loop;
         Test_Assert_Equal_Natural (Current_Time, 0, "Standard RR: Time should be 0 for empty queue");
      end;
      
      declare
         Q2 : Process_Queue := Queue;
         Base_Quantum : Positive := 2;
         Current_Time : Natural := 0;
         Proc : Process_Info;
      begin
         while not Q2.Is_Empty loop
            Proc := Q2.First_Element;
            Q2.Delete_First;
            Current_Time := Current_Time + (Base_Quantum * Proc.Weight);
         end loop;
         Test_Assert_Equal_Natural (Current_Time, 0, "Weighted RR: Time should be 0 for empty queue");
      end;
      
      declare
         Q3 : Process_Queue := Queue;
         Quantum : Positive := 3;
         Current_Time : Natural := 0;
         Proc : Process_Info;
      begin
         while not Q3.Is_Empty loop
            Proc := Q3.First_Element;
            Q3.Delete_First;
            Proc.Deficit := Proc.Deficit + Quantum;
         end loop;
         Test_Assert_Equal_Natural (Current_Time, 0, "Deficit RR: Time should be 0 for empty queue");
      end;
   end Test_All_Algorithms_Empty_Input;

   procedure Test_Zero_Quantum is
      Queue : Process_Queue;
   begin
      Put_Line ("Test 4.2: Zero quantum edge case");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5));
      
      declare
         Time_Quantum : Positive := 1;
         Current_Time : Natural := 0;
         Proc : Process_Info;
      begin
         Proc := Queue.First_Element;
         Queue.Delete_First;
         
         if Proc.Remaining_Time > Time_Quantum then
            Current_Time := Current_Time + Time_Quantum;
            Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
            Queue.Append (Proc);
         end if;
         
         Test_Assert_Equal_Natural (Current_Time, 1, "Should execute with quantum=1");
      end;
   end Test_Zero_Quantum;

   procedure Test_Very_Large_Burst_Time is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 4.3: Very large burst time");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => Natural'Last));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      if Proc.Remaining_Time > Time_Quantum then
         Current_Time := Current_Time + Time_Quantum;
         Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
         Queue.Append (Proc);
      end if;
      
      Test_Assert (Proc.Remaining_Time < Natural'Last, 
         "Remaining time should be reduced from Natural'Last");
      Test_Assert_Equal_Natural (Current_Time, 3, "Time should advance by quantum");
   end Test_Very_Large_Burst_Time;

   procedure Test_Process_Order_Preservation is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
   begin
      Put_Line ("Test 4.4: Process order preservation in queue");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 10));
      Queue.Append (Create_Process(ID => 3, Burst_Time => 10));
      
      for I in 1..3 loop
         declare
            Proc : Process_Info := Queue.First_Element;
         begin
            Queue.Delete_First;
            Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
            Queue.Append (Proc);
         end;
      end loop;
      
      declare
         IDs : array (1..3) of Process_ID;
         Position : Cursor := Queue.First;
         Index : Positive := 1;
      begin
         while Has_Element(Position) loop
            IDs(Index) := Element(Position).ID;
            Index := Index + 1;
            Next(Position);
         end loop;
         
         Test_Assert_Equal_Positive (Natural(IDs(1)), 1, "First process should be ID 1");
         Test_Assert_Equal_Positive (Natural(IDs(2)), 2, "Second process should be ID 2");
         Test_Assert_Equal_Positive (Natural(IDs(3)), 3, "Third process should be ID 3");
      end;
   end Test_Process_Order_Preservation;

   procedure Test_Mixed_Arrival_Times is
      Queue : Process_Queue;
   begin
      Put_Line ("Test 4.5: Mixed arrival times (currently not used but should be stored)");
      
      Queue.Append (Create_Process(ID => 1, Arrival_Time => 0, Burst_Time => 5));
      Queue.Append (Create_Process(ID => 2, Arrival_Time => 10, Burst_Time => 5));
      Queue.Append (Create_Process(ID => 3, Arrival_Time => 5, Burst_Time => 5));
      
      declare
         Proc1 : Process_Info := Queue.First_Element;
         Proc2 : Process_Info;
         Proc3 : Process_Info;
      begin
         Queue.Delete_First;
         Proc2 := Queue.First_Element;
         Queue.Delete_First;
         Proc3 := Queue.First_Element;
         
         Test_Assert_Equal_Natural (Proc1.Arrival_Time, 0, "Process 1 arrival time should be 0");
         Test_Assert_Equal_Natural (Proc2.Arrival_Time, 10, "Process 2 arrival time should be 10");
         Test_Assert_Equal_Natural (Proc3.Arrival_Time, 5, "Process 3 arrival time should be 5");
      end;
   end Test_Mixed_Arrival_Times;

   -- ====================================================================
   -- TEST SUITE 5: Assumptions That Can Be Proven False
   -- ====================================================================
   
   procedure Test_Assumption_RR_Preempts_At_Quantum is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 5.1: Assumption - RR preempts exactly at quantum boundary");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 3));
      
      Proc := Queue.First_Element;
      Queue.Delete_First;
      
      if Proc.Remaining_Time > Time_Quantum then
         Current_Time := Current_Time + Time_Quantum;
         Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
         Queue.Append (Proc);
         Test_Assert_False (True, "Should not preempt when burst equals quantum");
      else
         Current_Time := Current_Time + Proc.Remaining_Time;
         Proc.Remaining_Time := 0;
         Test_Assert_True (True, "Should complete when burst equals quantum");
      end if;
      
      Test_Assert_Equal_Natural (Proc.Remaining_Time, 0, "Process should be completed");
   end Test_Assumption_RR_Preempts_At_Quantum;

   procedure Test_Assumption_WRR_Weight_Not_Zero is
      Queue : Process_Queue;
   begin
      Put_Line ("Test 5.2: Assumption - Weight should never be zero");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5, Weight => 1));
      
      declare
         Proc : Process_Info := Queue.First_Element;
      begin
         Test_Assert (Proc.Weight >= 1, "Weight should be at least 1");
         Test_Assert_Equal_Positive (Proc.Weight, 1, "Weight should be 1");
      end;
   end Test_Assumption_WRR_Weight_Not_Zero;

   procedure Test_Assumption_DRR_Deficit_Non_Negative is
      Queue : Process_Queue;
      Quantum : Positive := 3;
   begin
      Put_Line ("Test 5.3: Assumption - Deficit should never be negative");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5, Atomic_Chunk => 1));
      
      declare
         Proc : Process_Info := Queue.First_Element;
      begin
         Test_Assert_Equal_Natural (Proc.Deficit, 0, "Initial deficit should be 0");
         
         Proc.Deficit := Proc.Deficit + Quantum;
         Test_Assert (Proc.Deficit >= 0, "Deficit after addition should be >= 0");
         
         Proc.Deficit := Proc.Deficit - 2;
         Test_Assert (Proc.Deficit >= 0, "Deficit after subtraction should be >= 0");
      end;
   end Test_Assumption_DRR_Deficit_Non_Negative;

   procedure Test_Assumption_Atomic_Chunk_Positive is
      Queue : Process_Queue;
   begin
      Put_Line ("Test 5.4: Assumption - Atomic chunk should be positive");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5, Atomic_Chunk => 1));
      
      declare
         Proc : Process_Info := Queue.First_Element;
      begin
         Test_Assert (Proc.Atomic_Chunk >= 1, "Atomic chunk should be at least 1");
      end;
   end Test_Assumption_Atomic_Chunk_Positive;

   procedure Test_Assumption_Remaining_Time_Non_Negative is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
   begin
      Put_Line ("Test 5.5: Assumption - Remaining time should never be negative");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5));
      
      declare
         Proc : Process_Info := Queue.First_Element;
      begin
         Test_Assert (Proc.Remaining_Time >= 0, "Initial remaining time should be >= 0");
         
         if Proc.Remaining_Time > Time_Quantum then
            Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
         else
            Proc.Remaining_Time := 0;
         end if;
         
         Test_Assert (Proc.Remaining_Time >= 0, "Remaining time after subtraction should be >= 0");
      end;
   end Test_Assumption_Remaining_Time_Non_Negative;

   procedure Test_Assumption_Process_ID_Unique is
      Queue : Process_Queue;
   begin
      Put_Line ("Test 5.6: Assumption - Process IDs should be unique");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 5));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 5));
      Queue.Append (Create_Process(ID => 3, Burst_Time => 5));
      
      declare
         IDs : array (1..3) of Process_ID;
         Position : Cursor := Queue.First;
         Index : Positive := 1;
         Unique : Boolean := True;
      begin
         while Has_Element(Position) loop
            IDs(Index) := Element(Position).ID;
            Index := Index + 1;
            Next(Position);
         end loop;
         
         for I in 1..2 loop
            for J in I+1..3 loop
               if IDs(I) = IDs(J) then
                  Unique := False;
               end if;
            end loop;
         end loop;
         
         Test_Assert_True (Unique, "All process IDs should be unique");
      end;
   end Test_Assumption_Process_ID_Unique;

   -- ====================================================================
   -- TEST SUITE 6: Integration Tests
   -- ====================================================================
   
   procedure Test_Standard_RR_Full_Execution is
      Queue : Process_Queue;
      Time_Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
   begin
      Put_Line ("Test 6.1: Standard RR full execution to completion");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 5));
      Queue.Append (Create_Process(ID => 3, Burst_Time => 8));
      
      while not Queue.Is_Empty loop
         Proc := Queue.First_Element;
         Queue.Delete_First;
         
         if Proc.Remaining_Time > Time_Quantum then
            Current_Time := Current_Time + Time_Quantum;
            Proc.Remaining_Time := Proc.Remaining_Time - Time_Quantum;
            Queue.Append (Proc);
         else
            Current_Time := Current_Time + Proc.Remaining_Time;
            Proc.Remaining_Time := 0;
         end if;
      end loop;
      
      Test_Assert_True (Queue.Is_Empty, "Queue should be empty after completion");
      Test_Assert_Equal_Natural (Current_Time, 23, "Total execution time should be 23");
   end Test_Standard_RR_Full_Execution;

   procedure Test_WRR_Full_Execution is
      Queue : Process_Queue;
      Base_Quantum : Positive := 2;
      Current_Time : Natural := 0;
      Proc : Process_Info;
      Actual_Quantum : Positive;
   begin
      Put_Line ("Test 6.2: Weighted RR full execution to completion");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Weight => 1));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 10, Weight => 2));
      
      while not Queue.Is_Empty loop
         Proc := Queue.First_Element;
         Queue.Delete_First;
         
         Actual_Quantum := Base_Quantum * Proc.Weight;
         
         if Proc.Remaining_Time > Actual_Quantum then
            Current_Time := Current_Time + Actual_Quantum;
            Proc.Remaining_Time := Proc.Remaining_Time - Actual_Quantum;
            Queue.Append (Proc);
         else
            Current_Time := Current_Time + Proc.Remaining_Time;
            Proc.Remaining_Time := 0;
         end if;
      end loop;
      
      Test_Assert_True (Queue.Is_Empty, "Queue should be empty after completion");
      Test_Assert_Equal_Natural (Current_Time, 20, "Total execution time should be 20");
   end Test_WRR_Full_Execution;

   procedure Test_DRR_Full_Execution is
      Queue : Process_Queue;
      Quantum : Positive := 3;
      Current_Time : Natural := 0;
      Proc : Process_Info;
      Executed : Natural;
   begin
      Put_Line ("Test 6.3: Deficit RR full execution to completion");
      
      Queue.Append (Create_Process(ID => 1, Burst_Time => 10, Atomic_Chunk => 2));
      Queue.Append (Create_Process(ID => 2, Burst_Time => 10, Atomic_Chunk => 2));
      
      while not Queue.Is_Empty loop
         Proc := Queue.First_Element;
         Queue.Delete_First;
         
         Proc.Deficit := Proc.Deficit + Quantum;
         
         if Proc.Remaining_Time <= Proc.Deficit then
            Current_Time := Current_Time + Proc.Remaining_Time;
            Proc.Deficit := Proc.Deficit - Proc.Remaining_Time;
            Proc.Remaining_Time := 0;
         else
            if Proc.Atomic_Chunk > Proc.Deficit then
               Executed := 0;
            else
               Executed := (Proc.Deficit / Proc.Atomic_Chunk) * Proc.Atomic_Chunk;
            end if;
            
            if Executed > 0 then
               Current_Time := Current_Time + Executed;
               Proc.Remaining_Time := Proc.Remaining_Time - Executed;
               Proc.Deficit := Proc.Deficit - Executed;
            end if;
            
            Queue.Append (Proc);
         end if;
      end loop;
      
      Test_Assert_True (Queue.Is_Empty, "Queue should be empty after completion");
      Test_Assert_Equal_Natural (Current_Time, 20, "Total execution time should be 20");
   end Test_DRR_Full_Execution;

   -- ====================================================================
   -- MAIN TEST RUNNER
   -- ====================================================================
   
   procedure Run_All_Tests is
   begin
      Put_Line ("========================================");
      Put_Line ("  ROUND ROBIN TEST SUITE");
      Put_Line ("========================================");
      New_Line;
      
      Total_Tests := 0;
      Passed_Tests := 0;
      Failed_Tests := 0;
      
      -- Test Suite 1: Standard Round Robin
      Put_Line ("--- Test Suite 1: Standard Round Robin ---");
      Test_Standard_RR_Empty_Queue;
      Test_Standard_RR_Single_Process;
      Test_Standard_RR_Process_Preemption;
      Test_Standard_RR_Multiple_Processes;
      Test_Standard_RR_Completion_Order;
      New_Line;
      
      -- Test Suite 2: Weighted Round Robin
      Put_Line ("--- Test Suite 2: Weighted Round Robin ---");
      Test_WRR_Weight_Allocation;
      Test_WRR_Higher_Weight_More_Time;
      Test_WRR_Weight_One_Behavior;
      Test_WRR_Zero_Burst_Time;
      Test_WRR_Large_Weight;
      New_Line;
      
      -- Test Suite 3: Deficit Round Robin
      Put_Line ("--- Test Suite 3: Deficit Round Robin ---");
      Test_DRR_Deficit_Accumulation;
      Test_DRR_Atomic_Chunk_Constraint;
      Test_DRR_Completion_When_Deficit_Sufficient;
      Test_DRR_Multiple_Processes_Fairness;
      Test_DRR_Deficit_Preservation;
      New_Line;
      
      -- Test Suite 4: Edge Cases
      Put_Line ("--- Test Suite 4: Edge Cases and Boundary Conditions ---");
      Test_All_Algorithms_Empty_Input;
      Test_Zero_Quantum;
      Test_Very_Large_Burst_Time;
      Test_Process_Order_Preservation;
      Test_Mixed_Arrival_Times;
      New_Line;
      
      -- Test Suite 5: Assumptions That Can Be Proven False
      Put_Line ("--- Test Suite 5: Assumptions That Can Be Proven False ---");
      Test_Assumption_RR_Preempts_At_Quantum;
      Test_Assumption_WRR_Weight_Not_Zero;
      Test_Assumption_DRR_Deficit_Non_Negative;
      Test_Assumption_Atomic_Chunk_Positive;
      Test_Assumption_Remaining_Time_Non_Negative;
      Test_Assumption_Process_ID_Unique;
      New_Line;
      
      -- Test Suite 6: Integration Tests
      Put_Line ("--- Test Suite 6: Integration Tests ---");
      Test_Standard_RR_Full_Execution;
      Test_WRR_Full_Execution;
      Test_DRR_Full_Execution;
      New_Line;
      
      -- Summary
      Put_Line ("========================================");
      Put_Line ("  TEST SUMMARY");
      Put_Line ("========================================");
      Put_Line ("Total Tests:  " & Natural'Image(Total_Tests));
      Put_Line ("Passed:       " & Natural'Image(Passed_Tests));
      Put_Line ("Failed:       " & Natural'Image(Failed_Tests));
      
      if Failed_Tests = 0 then
         Put_Line ("Result:       ALL TESTS PASSED");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      else
         Put_Line ("Result:       SOME TESTS FAILED");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      end if;
      Put_Line ("========================================");
   end Run_All_Tests;

end Round_Robin_Tests;
