-- chandra_toueg.adb
-- Implementation of the Chandra-Toueg Consensus Algorithm.
package body Chandra_Toueg is

   -- Determines the coordinator for the current round (rotating coordinator variant)
   function Get_Coordinator (R : Round_Number) return Process_ID is
   begin
      return Process_ID ((Natural(R) - 1) mod Max_Processes + 1);
   end Get_Coordinator;

   -- Phase 1: All alive processes send their current estimate and timestamp to the coordinator.
   procedure Phase_1 (Sim : in out Simulator) is
      Coordinator : constant Process_ID := Get_Coordinator (Sim.Current_Round);
   begin
      -- Reset Phase 1 mailboxes
      Sim.Phase_1_Messages := (others => (Valid => False, others => <>));
      
      for P in Process_ID loop
         if Sim.Processes(P).Status = Alive then
            Sim.Phase_1_Messages(P) := 
              (Valid        => True, 
               Sender       => P, 
               Has_Estimate => Sim.Processes(P).Has_Estimate,
               Estimate     => Sim.Processes(P).Estimate, 
               TS           => Sim.Processes(P).TS);
         end if;
      end loop;
   end Phase_1;

   -- Phase 2: Coordinator waits for majority of estimates, picks the one with highest TS,
   -- and broadcasts it as the new proposal.
   procedure Phase_2 (Sim : in out Simulator) is
      Msg_Count : Natural := 0;
      Max_TS    : Round_Number := 0;
      Best_Val  : Value_Type := 0;
      Has_Val   : Boolean := False;
   begin
      Sim.Phase_2_Valid := False;
      
      -- Gather messages
      for P in Process_ID loop
         if Sim.Phase_1_Messages(P).Valid then
            Msg_Count := Msg_Count + 1;
            
            -- Find the estimate with the most recent timestamp
            if Sim.Phase_1_Messages(P).Has_Estimate and then 
               (not Has_Val or else Sim.Phase_1_Messages(P).TS >= Max_TS) then
               Max_TS := Sim.Phase_1_Messages(P).TS;
               Best_Val := Sim.Phase_1_Messages(P).Estimate;
               Has_Val := True;
            end if;
         end if;
      end loop;

      -- If majority reached, propose the value
      if Msg_Count >= Majority then
         Sim.Phase_2_Valid := True;
         Sim.Phase_2_Proposal := Best_Val;
      end if;
   end Phase_2;

   -- Phase 3: Processes wait for proposal. If received, they ACK. 
   -- If they suspect the coordinator via Unreliable Failure Detector, they NACK.
   procedure Phase_3 (Sim : in out Simulator) is
      Coordinator : constant Process_ID := Get_Coordinator (Sim.Current_Round);
   begin
      Sim.Phase_3_Votes := (others => None);

      for P in Process_ID loop
         if Sim.Processes(P).Status = Alive then
            -- Check Unreliable Failure Detector
            if Sim.FD(P, Coordinator) then
               Sim.Phase_3_Votes(P) := Nack;
            elsif Sim.Phase_2_Valid then
               Sim.Processes(P).Has_Estimate := True;
               Sim.Processes(P).Estimate := Sim.Phase_2_Proposal;
               Sim.Processes(P).TS := Sim.Current_Round;
               Sim.Phase_3_Votes(P) := Ack;
            end if;
         end if;
      end loop;
   end Phase_3;

   -- Phase 4: Coordinator waits for majority of ACKs. If received, decides and broadcasts.
   procedure Phase_4 (Sim : in out Simulator) is
      Ack_Count : Natural := 0;
   begin
      -- Coordinator tallies votes
      for P in Process_ID loop
         if Sim.Phase_3_Votes(P) = Ack then
            Ack_Count := Ack_Count + 1;
         end if;
      end loop;

      -- On majority ACK, Reliable Broadcast (simulated) of decision
      if Ack_Count >= Majority then
         for P in Process_ID loop
            if Sim.Processes(P).Status = Alive then
               Sim.Processes(P).State := Decided;
               Sim.Processes(P).Decided_Value := Sim.Phase_2_Proposal;
            end if;
         end loop;
      end if;
   end Phase_4;

   -- Runs all 4 phases for the current round and increments round counter
   procedure Run_Round (Sim : in out Simulator) is
   begin
      Phase_1 (Sim);
      Phase_2 (Sim);
      Phase_3 (Sim);
      Phase_4 (Sim);
      Sim.Current_Round := Sim.Current_Round + 1;
   end Run_Round;

   procedure Initialize (Sim : out Simulator; Initial_Values : Value_Array) is
   begin
      Sim.Current_Round := 1;
      Sim.FD := (others => (others => False));
      for P in Process_ID loop
         Sim.Processes(P).Status := Alive;
         Sim.Processes(P).State := Undecided;
         Sim.Processes(P).Has_Estimate := True;
         Sim.Processes(P).Estimate := Initial_Values(P);
         Sim.Processes(P).TS := 0;
      end loop;
   end Initialize;

   procedure Crash_Process (Sim : in out Simulator; P : Process_ID) is
   begin
      Sim.Processes(P).Status := Crashed;
   end Crash_Process;

   procedure Suspect (Sim : in out Simulator; Suspector, Suspected : Process_ID) is
   begin
      Sim.FD(Suspector, Suspected) := True;
   end Suspect;

end Chandra_Toueg;
