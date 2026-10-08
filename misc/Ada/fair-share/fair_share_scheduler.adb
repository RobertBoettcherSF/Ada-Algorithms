package body Fair_Share_Scheduler is

   procedure Initialize (Self : in out Scheduler) is
   begin
      Ada.Numerics.Float_Random.Reset (Self.RNG);
      for I in Self.Processes'Range loop
         Self.Processes(I).Is_Active := False;
      end loop;
      for I in Self.Users'Range loop
         Self.Users(I).Is_Active := False;
      end loop;
      Self.Current_Process := Null_Process;
   end Initialize;

   procedure Add_User (Self   : in out Scheduler;
                       ID     : User_ID;
                       Shares : Float) is
   begin
      for I in Self.Users'Range loop
         if not Self.Users(I).Is_Active then
            Self.Users(I).ID := ID;
            Self.Users(I).Shares := Shares;
            Self.Users(I).CPU_Usage := 0.0;
            Self.Users(I).Is_Active := True;
            return;
         end if;
      end loop;
   end Add_User;

   procedure Add_Process (Self          : in out Scheduler;
                          ID            : Process_ID;
                          Owner         : User_ID;
                          Base_Priority : Float := 10.0;
                          Tickets       : Natural := 0) is
   begin
      for I in Self.Processes'Range loop
         if not Self.Processes(I).Is_Active then
            Self.Processes(I).ID := ID;
            Self.Processes(I).Owner := Owner;
            Self.Processes(I).Base_Priority := Base_Priority;
            Self.Processes(I).Tickets := Tickets;
            Self.Processes(I).CPU_Usage := 0.0;
            Self.Processes(I).Virtual_Runtime := 0.0;
            Self.Processes(I).Is_Active := True;
            return;
         end if;
      end loop;
   end Add_Process;

   procedure Remove_Process (Self : in out Scheduler; ID : Process_ID) is
   begin
      for I in Self.Processes'Range loop
         if Self.Processes(I).Is_Active and then Self.Processes(I).ID = ID then
            Self.Processes(I).Is_Active := False;
            if Self.Current_Process = ID then
               Self.Current_Process := Null_Process;
            end if;
            return;
         end if;
      end loop;
   end Remove_Process;

   function Get_User_Index (Self : Scheduler; ID : User_ID) return Integer is
   begin
      for I in Self.Users'Range loop
         if Self.Users(I).Is_Active and then Self.Users(I).ID = ID then
            return I;
         end if;
      end loop;
      return -1;
   end Get_User_Index;

   function Count_User_Processes (Self : Scheduler; ID : User_ID) return Float is
      Count : Float := 0.0;
   begin
      for I in Self.Processes'Range loop
         if Self.Processes(I).Is_Active and then Self.Processes(I).Owner = ID then
            Count := Count + 1.0;
         end if;
      end loop;
      return Count;
   end Count_User_Processes;

   function Select_Next_Process (Self : in out Scheduler) return Process_ID is
      Selected_ID : Process_ID := Null_Process;
   begin
      case Self.Algorithm is
         
         when Traditional_Unix_FSS =>
            declare
               Min_Priority : Float := Float'Last;
            begin
               -- Lower number implies higher priority. Priority = Base + CPU_Use/2 + User_CPU_Use/2
               for I in Self.Processes'Range loop
                  if Self.Processes(I).Is_Active then
                     declare
                        U_Idx : constant Integer := Get_User_Index (Self, Self.Processes(I).Owner);
                        U_CPU : constant Float := (if U_Idx > 0 then Self.Users(U_Idx).CPU_Usage else 0.0);
                     begin
                        Self.Processes(I).Dynamic_Priority := 
                          Self.Processes(I).Base_Priority + 
                          (Self.Processes(I).CPU_Usage / 2.0) + 
                          (U_CPU / 2.0);

                        if Self.Processes(I).Dynamic_Priority < Min_Priority then
                           Min_Priority := Self.Processes(I).Dynamic_Priority;
                           Selected_ID  := Self.Processes(I).ID;
                        end if;
                     end;
                  end if;
               end loop;
            end;

         when Completely_Fair_Scheduler_CFS =>
            declare
               Min_VRuntime : Float := Float'Last;
            begin
               -- CFS strictly runs the task with the lowest Virtual Runtime
               for I in Self.Processes'Range loop
                  if Self.Processes(I).Is_Active then
                     if Self.Processes(I).Virtual_Runtime < Min_VRuntime then
                        Min_VRuntime := Self.Processes(I).Virtual_Runtime;
                        Selected_ID  := Self.Processes(I).ID;
                     end if;
                  end if;
               end loop;
            end;

         when Lottery_Scheduling =>
            declare
               Total_User_Shares : Float := 0.0;
               Total_System_Tickets : constant Float := 10000.0;
               Current_Ticket_Count : Float := 0.0;
               Random_Val : Float;
               Proc_Tickets : Float;
            begin
               for I in Self.Users'Range loop
                  if Self.Users(I).Is_Active then
                     Total_User_Shares := Total_User_Shares + Self.Users(I).Shares;
                  end if;
               end loop;

               if Total_User_Shares > 0.0 then
                  Random_Val := Ada.Numerics.Float_Random.Random (Self.RNG) * Total_System_Tickets;
                  
                  for I in Self.Processes'Range loop
                     if Self.Processes(I).Is_Active then
                        declare
                           U_Idx : constant Integer := Get_User_Index (Self, Self.Processes(I).Owner);
                           Active_Procs : constant Float := Count_User_Processes (Self, Self.Processes(I).Owner);
                        begin
                           Proc_Tickets := 0.0;
                           
                           -- Process tickets = (User Share % of Total) divided equally among the user's active processes
                           if U_Idx > 0 and then Active_Procs > 0.0 then
                              Proc_Tickets := (Self.Users(U_Idx).Shares / Total_User_Shares) * Total_System_Tickets / Active_Procs;
                           end if;

                           Current_Ticket_Count := Current_Ticket_Count + Proc_Tickets;
                           if Random_Val <= Current_Ticket_Count then
                              Selected_ID := Self.Processes(I).ID;
                              exit;
                           end if;
                        end;
                     end if;
                  end loop;
               end if;
               
               -- Fallback to the first active if floating point precision drops the ticket count early
               if Selected_ID = Null_Process then
                  for I in Self.Processes'Range loop
                     if Self.Processes(I).Is_Active then
                        Selected_ID := Self.Processes(I).ID;
                        exit;
                     end if;
                  end loop;
               end if;
            end;
      end case;

      Self.Current_Process := Selected_ID;
      return Selected_ID;
   end Select_Next_Process;

   procedure Tick (Self : in out Scheduler; Time_Slice : Float) is
      P_Idx : Integer := -1;
   begin
      if Self.Current_Process = Null_Process then
         return;
      end if;

      for I in Self.Processes'Range loop
         if Self.Processes(I).Is_Active and then Self.Processes(I).ID = Self.Current_Process then
            P_Idx := I;
            exit;
         end if;
      end loop;

      if P_Idx = -1 then 
         return; 
      end if;

      declare
         U_Idx : constant Integer := Get_User_Index (Self, Self.Processes(P_Idx).Owner);
      begin
         case Self.Algorithm is
            
            when Traditional_Unix_FSS =>
               Self.Processes(P_Idx).CPU_Usage := Self.Processes(P_Idx).CPU_Usage + Time_Slice;
               if U_Idx > 0 then
                  Self.Users(U_Idx).CPU_Usage := Self.Users(U_Idx).CPU_Usage + Time_Slice;
               end if;

            when Completely_Fair_Scheduler_CFS =>
               declare
                  Active_Procs : constant Float := Count_User_Processes (Self, Self.Processes(P_Idx).Owner);
                  Weight : Float := 1.0;
               begin
                  -- Virtual runtime penalty is mitigated by the User's share weight.
                  -- Heavier weight = slower virtual runtime increase = gets scheduled more.
                  if U_Idx > 0 and then Active_Procs > 0.0 then
                     Weight := Self.Users(U_Idx).Shares / Active_Procs;
                  end if;
                  
                  Self.Processes(P_Idx).Virtual_Runtime := 
                    Self.Processes(P_Idx).Virtual_Runtime + (Time_Slice / Weight);
               end;

            when Lottery_Scheduling =>
               -- Lottery handles fairness entirely in Select_Next_Process based on RNG
               null;
         end case;
      end;
   end Tick;

   procedure Decay_Usage (Self : in out Scheduler) is
   begin
      -- FSS prevents starvation by halves the memory of past CPU consumption 
      if Self.Algorithm = Traditional_Unix_FSS then
         for I in Self.Processes'Range loop
            if Self.Processes(I).Is_Active then
               Self.Processes(I).CPU_Usage := Self.Processes(I).CPU_Usage / 2.0;
            end if;
         end loop;
         for I in Self.Users'Range loop
            if Self.Users(I).Is_Active then
               Self.Users(I).CPU_Usage := Self.Users(I).CPU_Usage / 2.0;
            end if;
         end loop;
      end if;
   end Decay_Usage;

end Fair_Share_Scheduler;
