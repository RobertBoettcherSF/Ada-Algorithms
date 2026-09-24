--  Main demonstration program for EDF Scheduling Algorithm
--  This program demonstrates the Earliest Deadline First scheduling algorithm
--  with various task configurations.

with Ada.Text_IO; use Ada.Text_IO;
with EDF_Scheduling; use EDF_Scheduling;

procedure Main is

   -- Example 1: Simple periodic task set
   procedure Demo_Basic_Periodic is
      Config1, Config2, Config3 : Task_Config;
   begin
      New_Line (2);
      Put_Line ("=== Demo 1: Basic Periodic Tasks ===");
      New_Line;
      
      Initialize (Standard_Preemptive);
      
      -- Task 1: Periodic, released at 0, computation 3, deadline 8, period 8
      Config1 := (ID => 1, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 3, Deadline => 8, Period => 8);
      
      -- Task 2: Periodic, released at 0, computation 2, deadline 5, period 5
      Config2 := (ID => 2, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 2, Deadline => 5, Period => 5);
      
      -- Task 3: Periodic, released at 2, computation 2, deadline 10, period 10
      Config3 := (ID => 3, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 2, Computation_Time => 2, Deadline => 10, Period => 10);
      
      Add_Task (Config1);
      Add_Task (Config2);
      Add_Task (Config3);
      
      Put_Line ("Schedulability: " & Boolean'Image (Is_Schedulable));
      Run_Simulation (20);
   end Demo_Basic_Periodic;

   -- Example 2: Mixed periodic and aperiodic tasks
   procedure Demo_Mixed_Tasks is
      Config1, Config2, Config3 : Task_Config;
   begin
      New_Line (2);
      Put_Line ("=== Demo 2: Mixed Periodic and Aperiodic Tasks ===");
      New_Line;
      
      Initialize (Standard_Preemptive);
      
      -- Periodic task
      Config1 := (ID => 1, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 2, Deadline => 5, Period => 5);
      
      -- Aperiodic task released at time 1
      Config2 := (ID => 2, Type_Of_Task => Aperiodic, Criticality => High,
                  Release_Time => 1, Computation_Time => 3, Deadline => 4, Period => 1);
      
      -- Another periodic task
      Config3 := (ID => 3, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 1, Deadline => 10, Period => 10);
      
      Add_Task (Config1);
      Add_Task (Config2);
      Add_Task (Config3);
      
      Put_Line ("Schedulability: " & Boolean'Image (Is_Schedulable));
      Run_Simulation (15);
   end Demo_Mixed_Tasks;

   -- Example 3: EDF-VD with mixed criticality
   procedure Demo_EDF_VD is
      Config1, Config2, Config3 : Task_Config;
   begin
      New_Line (2);
      Put_Line ("=== Demo 3: EDF-VD (Mixed Criticality) ===");
      New_Line;
      
      Initialize (EDF_VD);
      
      -- High criticality task
      Config1 := (ID => 1, Type_Of_Task => Periodic, Criticality => High,
                  Release_Time => 0, Computation_Time => 3, Deadline => 10, Period => 10);
      
      -- Low criticality task
      Config2 := (ID => 2, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 2, Deadline => 8, Period => 8);
      
      -- Another high criticality task
      Config3 := (ID => 3, Type_Of_Task => Periodic, Criticality => High,
                  Release_Time => 0, Computation_Time => 2, Deadline => 10, Period => 10);
      
      Add_Task (Config1);
      Add_Task (Config2);
      Add_Task (Config3);
      
      Put_Line ("Schedulability: " & Boolean'Image (Is_Schedulable));
      Run_Simulation (20);
   end Demo_EDF_VD;

   -- Example 4: Non-preemptive mode
   procedure Demo_Non_Preemptive is
      Config1, Config2 : Task_Config;
   begin
      New_Line (2);
      Put_Line ("=== Demo 4: Non-Preemptive EDF ===");
      New_Line;
      
      Initialize (Standard_Non_Preemptive);
      
      -- Long running periodic task
      Config1 := (ID => 1, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 5, Deadline => 10, Period => 10);
      
      -- Short periodic task with earlier deadline arriving later
      Config2 := (ID => 2, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 2, Computation_Time => 1, Deadline => 3, Period => 10);
      
      Add_Task (Config1);
      Add_Task (Config2);
      
      Put_Line ("Schedulability: " & Boolean'Image (Is_Schedulable));
      Run_Simulation (10);
   end Demo_Non_Preemptive;

   -- Example 5: Overloaded system (demonstrates deadline misses)
   procedure Demo_Overloaded is
      Config1, Config2, Config3 : Task_Config;
   begin
      New_Line (2);
      Put_Line ("=== Demo 5: Overloaded System (Deadline Misses) ===");
      New_Line;
      
      Initialize (Standard_Preemptive);
      
      -- Task 1: 50% utilization
      Config1 := (ID => 1, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 5, Deadline => 10, Period => 10);
      
      -- Task 2: 50% utilization
      Config2 := (ID => 2, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 5, Deadline => 10, Period => 10);
      
      -- Task 3: 20% utilization - total = 120%
      Config3 := (ID => 3, Type_Of_Task => Periodic, Criticality => Low,
                  Release_Time => 0, Computation_Time => 2, Deadline => 10, Period => 10);
      
      Add_Task (Config1);
      Add_Task (Config2);
      Add_Task (Config3);
      
      Put_Line ("Schedulability: " & Boolean'Image (Is_Schedulable));
      Run_Simulation (20);
   end Demo_Overloaded;

begin
   Put_Line ("==========================================");
   Put_Line ("EDF Scheduling Algorithm Demonstration");
   Put_Line ("==========================================");
   
   -- Run all demos
   Demo_Basic_Periodic;
   Demo_Mixed_Tasks;
   Demo_EDF_VD;
   Demo_Non_Preemptive;
   Demo_Overloaded;
   
   New_Line (2);
   Put_Line ("Demonstration complete.");
   Put_Line ("Run 'make test' to execute the test suite.");
end Main;
