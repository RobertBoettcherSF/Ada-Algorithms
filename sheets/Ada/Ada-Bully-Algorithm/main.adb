-- main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Bully_System; use Bully_System;

procedure Main is
   -- Initialize a network with 5 processes
   Network : Process_Array (1 .. 5) := (
      (1, True, Idle),
      (2, True, Idle),
      (3, True, Idle),
      (4, True, Idle),
      (5, True, Idle)
   );
begin
   Put_Line ("--- Bully Algorithm Simulation ---");
   
   Put_Line ("1. Process 2 detects no coordinator and starts an election.");
   Start_Election (Network, 2);
   Put_Line ("   -> Coordinator is now Process:" & Process_ID'Image(Get_Coordinator(Network)));
   Put_Line ("");

   Put_Line ("2. Process 5 (the coordinator) fails.");
   Fail_Process (Network, 5);
   Put_Line ("");

   Put_Line ("3. Process 3 detects the failure and starts an election.");
   Start_Election (Network, 3);
   Put_Line ("   -> Coordinator is now Process:" & Process_ID'Image(Get_Coordinator(Network)));
   Put_Line ("");
   
   Put_Line ("4. Process 5 recovers and starts an election to reclaim coordinator status.");
   Recover_Process (Network, 5);
   Start_Election (Network, 5);
   Put_Line ("   -> Coordinator is now Process:" & Process_ID'Image(Get_Coordinator(Network)));

end Main;
