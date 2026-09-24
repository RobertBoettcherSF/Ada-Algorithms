-- src/main.adb
with Ada.Text_IO; use Ada.Text_IO;
with Naimi_Trehel; use Naimi_Trehel;

procedure Main is
   Sys : Distributed_System (Num_Nodes => 3);
begin
   Put_Line ("=== Naimi-Trehel Log(n) Algorithm Simulation ===");
   
   Initialize (Sys, Initial_Token_Holder => 1);
   Put_Line ("System Initialized. Token holder: Node 1.");
   
   Put_Line ("Node 2 requests Critical Section (CS).");
   Request_Critical_Section (Sys, Node => 2);
   
   Put_Line ("Processing messages...");
   Process_All_Messages (Sys);
   
   if Has_Token (Sys, 2) then
      Put_Line ("Node 2 successfully acquired the token.");
   end if;
   
   Put_Line ("Node 2 releases CS.");
   Release_Critical_Section (Sys, Node => 2);
   
   Put_Line ("Simulation completed successfully.");
end Main;
