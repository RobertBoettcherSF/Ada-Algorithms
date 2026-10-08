package body Task_Scheduling is

   Max_Events : constant := 10_000;

   type Task_State is record
      Id        : Task_Id;
      Arrival   : Time_Unit;
      Burst     : Time_Unit;
      Deadline  : Time_Unit;
      Remaining : Time_Unit;
      Done      : Boolean;
   end record;

   type State_Array is array (Positive range <>) of Task_State;

   type Schedule_Buffer is record
      Events : Schedule_Array (1 .. Max_Events);
      Count  : Natural := 0;
   end record;

   -----------------------------------------------------------------------------
   -- Helpers
   -----------------------------------------------------------------------------

   function Is_Valid (Tasks : Task_Array) return Boolean is
   begin
      for T of Tasks loop
         if T.Burst = 0 then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid;

   procedure Init_State (Tasks : Task_Array; States : out State_Array) is
   begin
      for I in Tasks'Range loop
         States (I) := (Id        => Tasks (I).Id,
                        Arrival   => Tasks (I).Arrival,
                        Burst     => Tasks (I).Burst,
                        Deadline  => Tasks (I).Deadline,
                        Remaining => Tasks (I).Burst,
                        Done      => False);
      end loop;
   end Init_State;

   procedure Add_Event (Buffer : in out Schedule_Buffer; Ev : Schedule_Event) is
   begin
      -- Merge contiguous executions of the same task in preemptive schedules
      if Buffer.Count > 0 and then Buffer.Events (Buffer.Count).Id = Ev.Id
         and then Buffer.Events (Buffer.Count).End_Time = Ev.Start_Time
      then
         Buffer.Events (Buffer.Count).End_Time := Ev.End_Time;
      else
         Buffer.Count := Buffer.Count + 1;
         Buffer.Events (Buffer.Count) := Ev;
      end if;
   end Add_Event;

   -----------------------------------------------------------------------------
   -- FCFS Scheduling
   -----------------------------------------------------------------------------
   function Schedule_FCFS (Tasks : Task_Array) return Schedule_Array is
      States       : State_Array (Tasks'Range);
      Buffer       : Schedule_Buffer;
      Current_Time : Time_Unit := 0;
      Selected_Idx : Integer;
   begin
      if Tasks'Length = 0 then raise Empty_Task_List; end if;
      if not Is_Valid (Tasks) then raise Invalid_Tasks; end if;

      Init_State (Tasks, States);

      for Step in 1 .. Tasks'Length loop
         Selected_Idx := 0;
         
         for I in States'Range loop
            if not States (I).Done then
               if Selected_Idx = 0 then
                  Selected_Idx := I;
               elsif States (I).Arrival < States (Selected_Idx).Arrival then
                  Selected_Idx := I;
               elsif States (I).Arrival = States (Selected_Idx).Arrival
                     and then States (I).Id < States (Selected_Idx).Id then
                  Selected_Idx := I;
               end if;
            end if;
         end loop;

         if Current_Time < States (Selected_Idx).Arrival then
            Current_Time := States (Selected_Idx).Arrival;
         end if;

         Add_Event (Buffer, (Id         => States (Selected_Idx).Id,
                             Start_Time => Current_Time,
                             End_Time   => Current_Time + States (Selected_Idx).Burst));
                             
         Current_Time := Current_Time + States (Selected_Idx).Burst;
         States (Selected_Idx).Done := True;
      end loop;

      return Buffer.Events (1 .. Buffer.Count);
   end Schedule_FCFS;

   -----------------------------------------------------------------------------
   -- SJN Scheduling
   -----------------------------------------------------------------------------
   function Schedule_SJN (Tasks : Task_Array) return Schedule_Array is
      States       : State_Array (Tasks'Range);
      Buffer       : Schedule_Buffer;
      Current_Time : Time_Unit := 0;
      Selected_Idx : Integer;
      Min_Arrival  : Time_Unit;
   begin
      if Tasks'Length = 0 then raise Empty_Task_List; end if;
      if not Is_Valid (Tasks) then raise Invalid_Tasks; end if;

      Init_State (Tasks, States);

      for Step in 1 .. Tasks'Length loop
         Selected_Idx := 0;
         Min_Arrival := Time_Unit'Last;

         for I in States'Range loop
            if not States (I).Done then
               if States (I).Arrival < Min_Arrival then
                  Min_Arrival := States (I).Arrival;
               end if;
            end if;
         end loop;

         if Current_Time < Min_Arrival then
            Current_Time := Min_Arrival;
         end if;

         for I in States'Range loop
            if not States (I).Done and then States (I).Arrival <= Current_Time then
               if Selected_Idx = 0 then
                  Selected_Idx := I;
               elsif States (I).Burst < States (Selected_Idx).Burst then
                  Selected_Idx := I;
               elsif States (I).Burst = States (Selected_Idx).Burst then
                  if States (I).Arrival < States (Selected_Idx).Arrival then
                     Selected_Idx := I;
                  elsif States (I).Arrival = States (Selected_Idx).Arrival
                        and then States (I).Id < States (Selected_Idx).Id then
                     Selected_Idx := I;
                  end if;
               end if;
            end if;
         end loop;

         Add_Event (Buffer, (Id         => States (Selected_Idx).Id,
                             Start_Time => Current_Time,
                             End_Time   => Current_Time + States (Selected_Idx).Burst));
                             
         Current_Time := Current_Time + States (Selected_Idx).Burst;
         States (Selected_Idx).Done := True;
      end loop;

      return Buffer.Events (1 .. Buffer.Count);
   end Schedule_SJN;

   -----------------------------------------------------------------------------
   -- SRTF Scheduling
   -----------------------------------------------------------------------------
   function Schedule_SRTF (Tasks : Task_Array) return Schedule_Array is
      States       : State_Array (Tasks'Range);
      Buffer       : Schedule_Buffer;
      Current_Time : Time_Unit := 0;
      Selected_Idx : Integer;
      Min_Arrival  : Time_Unit;
      Next_Arr     : Time_Unit;
      Time_To_Run  : Time_Unit;
      All_Done     : Boolean;
   begin
      if Tasks'Length = 0 then raise Empty_Task_List; end if;
      if not Is_Valid (Tasks) then raise Invalid_Tasks; end if;

      Init_State (Tasks, States);

      loop
         All_Done := True;
         Selected_Idx := 0;
         Min_Arrival := Time_Unit'Last;
         Next_Arr := Time_Unit'Last;

         for I in States'Range loop
            if not States (I).Done then
               All_Done := False;
               if States (I).Arrival < Min_Arrival then
                  Min_Arrival := States (I).Arrival;
               end if;
            end if;
         end loop;

         exit when All_Done;

         if Current_Time < Min_Arrival then
            Current_Time := Min_Arrival;
         end if;

         for I in States'Range loop
            if not States (I).Done and then States (I).Arrival <= Current_Time then
               if Selected_Idx = 0 then
                  Selected_Idx := I;
               elsif States (I).Remaining < States (Selected_Idx).Remaining then
                  Selected_Idx := I;
               elsif States (I).Remaining = States (Selected_Idx).Remaining then
                  if States (I).Arrival < States (Selected_Idx).Arrival then
                     Selected_Idx := I;
                  elsif States (I).Arrival = States (Selected_Idx).Arrival
                        and then States (I).Id < States (Selected_Idx).Id then
                     Selected_Idx := I;
                  end if;
               end if;
            end if;
         end loop;

         for I in States'Range loop
            if not States (I).Done and then States (I).Arrival > Current_Time then
               if States (I).Arrival < Next_Arr then
                  Next_Arr := States (I).Arrival;
               end if;
            end if;
         end loop;

         if Next_Arr < Time_Unit'Last and then (Next_Arr - Current_Time) < States (Selected_Idx).Remaining then
            Time_To_Run := Next_Arr - Current_Time;
         else
            Time_To_Run := States (Selected_Idx).Remaining;
         end if;

         Add_Event (Buffer, (Id         => States (Selected_Idx).Id,
                             Start_Time => Current_Time,
                             End_Time   => Current_Time + Time_To_Run));
                             
         Current_Time := Current_Time + Time_To_Run;
         States (Selected_Idx).Remaining := States (Selected_Idx).Remaining - Time_To_Run;

         if States (Selected_Idx).Remaining = 0 then
            States (Selected_Idx).Done := True;
         end if;
      end loop;

      return Buffer.Events (1 .. Buffer.Count);
   end Schedule_SRTF;

   -----------------------------------------------------------------------------
   -- EDF Scheduling
   -----------------------------------------------------------------------------
   function Schedule_EDF (Tasks : Task_Array) return Schedule_Array is
      States       : State_Array (Tasks'Range);
      Buffer       : Schedule_Buffer;
      Current_Time : Time_Unit := 0;
      Selected_Idx : Integer;
      Min_Arrival  : Time_Unit;
      Next_Arr     : Time_Unit;
      Time_To_Run  : Time_Unit;
      All_Done     : Boolean;
   begin
      if Tasks'Length = 0 then raise Empty_Task_List; end if;
      if not Is_Valid (Tasks) then raise Invalid_Tasks; end if;

      Init_State (Tasks, States);

      loop
         All_Done := True;
         Selected_Idx := 0;
         Min_Arrival := Time_Unit'Last;
         Next_Arr := Time_Unit'Last;

         for I in States'Range loop
            if not States (I).Done then
               All_Done := False;
               if States (I).Arrival < Min_Arrival then
                  Min_Arrival := States (I).Arrival;
               end if;
            end if;
         end loop;

         exit when All_Done;

         if Current_Time < Min_Arrival then
            Current_Time := Min_Arrival;
         end if;

         for I in States'Range loop
            if not States (I).Done and then States (I).Arrival <= Current_Time then
               if Selected_Idx = 0 then
                  Selected_Idx := I;
               elsif States (I).Deadline < States (Selected_Idx).Deadline then
                  Selected_Idx := I;
               elsif States (I).Deadline = States (Selected_Idx).Deadline then
                  if States (I).Arrival < States (Selected_Idx).Arrival then
                     Selected_Idx := I;
                  elsif States (I).Arrival = States (Selected_Idx).Arrival
                        and then States (I).Id < States (Selected_Idx).Id then
                     Selected_Idx := I;
                  end if;
               end if;
            end if;
         end loop;

         for I in States'Range loop
            if not States (I).Done and then States (I).Arrival > Current_Time then
               if States (I).Arrival < Next_Arr then
                  Next_Arr := States (I).Arrival;
               end if;
            end if;
         end loop;

         if Next_Arr < Time_Unit'Last and then (Next_Arr - Current_Time) < States (Selected_Idx).Remaining then
            Time_To_Run := Next_Arr - Current_Time;
         else
            Time_To_Run := States (Selected_Idx).Remaining;
         end if;

         Add_Event (Buffer, (Id         => States (Selected_Idx).Id,
                             Start_Time => Current_Time,
                             End_Time   => Current_Time + Time_To_Run));
                             
         Current_Time := Current_Time + Time_To_Run;
         States (Selected_Idx).Remaining := States (Selected_Idx).Remaining - Time_To_Run;

         if States (Selected_Idx).Remaining = 0 then
            States (Selected_Idx).Done := True;
         end if;
      end loop;

      return Buffer.Events (1 .. Buffer.Count);
   end Schedule_EDF;

end Task_Scheduling;
