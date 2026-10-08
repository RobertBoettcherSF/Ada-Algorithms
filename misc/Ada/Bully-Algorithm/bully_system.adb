package body Bully_System is

   function Get_Coordinator (Network : Process_Array) return Process_ID is
   begin
      for P of Network loop
         if P.Status = Coordinator and P.Is_Alive then
            return P.ID;
         end if;
      end loop;
      return 0; -- 0 indicates no coordinator
   end Get_Coordinator;

   procedure Fail_Process (Network : in out Process_Array; ID : Process_ID) is
   begin
      for P of Network loop
         if P.ID = ID then
            P.Is_Alive := False;
            P.Status   := Idle;
            return;
         end if;
      end loop;
   end Fail_Process;

   procedure Recover_Process (Network : in out Process_Array; ID : Process_ID) is
   begin
      for P of Network loop
         if P.ID = ID then
            P.Is_Alive := True;
            return;
         end if;
      end loop;
   end Recover_Process;

   procedure Start_Election (Network : in out Process_Array; Initiator_ID : Process_ID) is
      Higher_Exists : Boolean := False;
   begin
      -- 1. Check if initiator is alive
      for P of Network loop
         if P.ID = Initiator_ID and not P.Is_Alive then
            return;
         end if;
      end loop;

      -- 2. Send ELECTION to all processes with higher ID
      for P of Network loop
         if P.ID > Initiator_ID and P.Is_Alive then
            Higher_Exists := True;
            -- In this simulation, if a higher process exists, it takes over
            Start_Election (Network, P.ID);
         end if;
      end loop;

      -- 3. If no higher process responded, this one becomes coordinator
      if not Higher_Exists then
         for P of Network loop
            if P.ID = Initiator_ID then
               P.Status := Coordinator;
            else
               P.Status := Idle;
            end if;
         end loop;
      end if;
   end Start_Election;
end Bully_System;
