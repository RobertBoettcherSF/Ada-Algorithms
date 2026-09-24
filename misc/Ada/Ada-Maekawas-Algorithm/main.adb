-- src/main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Maekawa; use Maekawa;

procedure Main is
   Sys : Maekawa_System;
begin
   Put_Line ("Initializing Maekawa's Algorithm Simulation...");
   Initialize (Sys);
   Generate_Grid_Quorums (Sys);
   
   Put_Line ("Node 1 Requesting CS (Timestamp 10)...");
   Request_CS (Sys, 1, 10);
   Process_All_Events (Sys);
   
   if Sys.Nodes(1).State = Holding then
      Put_Line ("Success: Node 1 acquired Critical Section.");
   end if;

   Put_Line ("Node 1 Releasing CS...");
   Release_CS (Sys, 1);
   Process_All_Events (Sys);
   
   Put_Line ("Simulation finished.");
end Main;
