package Bully_System is
   type Process_ID is range 0 .. 100;
   type Election_Status is (Idle, Participant, Coordinator);
   
   type Process is record
      ID          : Process_ID;
      Is_Alive    : Boolean := True;
      Status      : Election_Status := Idle;
   end record;

   type Process_Array is array (Process_ID range <>) of Process;

   -- Exception for invalid operations
   Invalid_Process : exception;

   -- Core Algorithm Procedures
   procedure Start_Election (Network : in out Process_Array; Initiator_ID : Process_ID);
   procedure Fail_Process   (Network : in out Process_Array; ID : Process_ID);
   procedure Recover_Process(Network : in out Process_Array; ID : Process_ID);
   
   -- Helper to find current coordinator
   function Get_Coordinator (Network : Process_Array) return Process_ID;
end Bully_System;
