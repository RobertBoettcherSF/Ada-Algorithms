with Ada.Unchecked_Deallocation;

package body Discrete_Event_Simulation is

   procedure Free_Event is new Ada.Unchecked_Deallocation (Event'Class, Event_Access);

   function Current_Time (Sim : Simulator) return Sim_Time is
   begin
      return Sim.Clock;
   end Current_Time;

   function Pending_Events (Sim : Simulator) return Count_Type is
   begin
      return Sim.Active_Count;
   end Pending_Events;

   function Is_Empty (Sim : Simulator) return Boolean is
   begin
      return Sim.Active_Count = 0;
   end Is_Empty;

   -- Min-Heap internal operation
   procedure Sift_Up (Sim : in out Simulator; Index : Capacity_Type) is
      Child  : Natural := Natural (Index);
      Parent : Natural;
      Temp   : Event_Access;
   begin
      while Child > 1 loop
         Parent := Child / 2;
         if Sim.Queue (Capacity_Type (Child)).Time < Sim.Queue (Capacity_Type (Parent)).Time then
            Temp := Sim.Queue (Capacity_Type (Child));
            Sim.Queue (Capacity_Type (Child)) := Sim.Queue (Capacity_Type (Parent));
            Sim.Queue (Capacity_Type (Parent)) := Temp;
            Child := Parent;
         else
            exit;
         end if;
      end loop;
   end Sift_Up;

   -- Min-Heap internal operation
   procedure Sift_Down (Sim : in out Simulator; Index : Capacity_Type) is
      Parent : Natural := Natural (Index);
      Child  : Natural;
      Temp   : Event_Access;
   begin
      loop
         Child := 2 * Parent;
         exit when Child > Natural (Sim.Size);
         
         -- Find the smaller of the two children
         if Child < Natural (Sim.Size) 
            and then Sim.Queue (Capacity_Type (Child + 1)).Time < Sim.Queue (Capacity_Type (Child)).Time 
         then
            Child := Child + 1;
         end if;
         
         -- Swap if child is smaller than parent
         if Sim.Queue (Capacity_Type (Child)).Time < Sim.Queue (Capacity_Type (Parent)).Time then
            Temp := Sim.Queue (Capacity_Type (Parent));
            Sim.Queue (Capacity_Type (Parent)) := Sim.Queue (Capacity_Type (Child));
            Sim.Queue (Capacity_Type (Child)) := Temp;
            Parent := Child;
         else
            exit;
         end if;
      end loop;
   end Sift_Down;

   -- Extracts the root of the Min-Heap
   function Pop (Sim : in out Simulator) return Event_Access is
      Result : Event_Access;
   begin
      if Sim.Size = 0 then
         raise Event_Error with "Queue empty";
      end if;
      Result := Sim.Queue (1);
      Sim.Queue (1) := Sim.Queue (Capacity_Type (Sim.Size));
      Sim.Size := Sim.Size - 1;
      if Sim.Size > 0 then
         Sift_Down (Sim, 1);
      end if;
      return Result;
   end Pop;

   procedure Schedule (Sim : in out Simulator; E : Event_Access; Id : out Event_Id_Type) is
   begin
      if E = null then
         raise Event_Error with "Cannot schedule a null event";
      end if;
      if E.Time < Sim.Clock then
         raise Event_Error with "Cannot schedule event in the past";
      end if;
      if Sim.Size >= Count_Type (Sim.Max_Capacity) then
         raise Event_Error with "Simulator capacity exceeded";
      end if;

      E.Id := Sim.Next_Id;
      Id := E.Id;
      Sim.Next_Id := Sim.Next_Id + 1;

      Sim.Size := Sim.Size + 1;
      Sim.Queue (Capacity_Type (Sim.Size)) := E;
      Sim.Active_Count := Sim.Active_Count + 1;
      Sift_Up (Sim, Capacity_Type (Sim.Size));
   end Schedule;

   procedure Step_Next_Event (Sim : in out Simulator) is
      E : Event_Access;
      Found : Boolean := False;
   begin
      if Sim.Active_Count = 0 then
         raise Event_Error with "No active events to execute";
      end if;

      while Sim.Size > 0 and not Found loop
         E := Pop (Sim);
         if not E.Cancelled then
            Sim.Clock := E.Time;
            Execute (E.all, Sim);
            Found := True;
            Sim.Active_Count := Sim.Active_Count - 1;
         end if;
         Free_Event (E);
      end loop;
   end Step_Next_Event;

   procedure Run_Until (Sim : in out Simulator; End_Time : Sim_Time) is
      E : Event_Access;
   begin
      if End_Time < Sim.Clock then
         raise Event_Error with "End_Time is in the past";
      end if;

      while Sim.Size > 0 loop
         -- Peek root event time to see if we should stop.
         -- If it is cancelled, we will eventually pop and discard it during a Step,
         -- but for Run_Until, stopping early safely leaves it in the heap for lazy deletion later.
         if Sim.Queue (1).Time > End_Time then
            exit;
         end if;

         E := Pop (Sim);
         if not E.Cancelled then
            Sim.Clock := E.Time;
            Execute (E.all, Sim);
            Sim.Active_Count := Sim.Active_Count - 1;
         end if;
         Free_Event (E);
      end loop;
      
      Sim.Clock := End_Time;
   end Run_Until;

   procedure Step_Fixed_Increment (Sim : in out Simulator; Step : Sim_Time) is
   begin
      if Step <= 0.0 then
         raise Event_Error with "Step increment must be strictly positive";
      end if;
      Run_Until (Sim, Sim.Clock + Step);
   end Step_Fixed_Increment;

   procedure Cancel_Event (Sim : in out Simulator; Id : Event_Id_Type) is
   begin
      -- Iterate and mark as cancelled (lazy deletion). 
      for I in 1 .. Sim.Size loop
         if Sim.Queue (Capacity_Type (I)).Id = Id and then not Sim.Queue (Capacity_Type (I)).Cancelled then
            Sim.Queue (Capacity_Type (I)).Cancelled := True;
            Sim.Active_Count := Sim.Active_Count - 1;
            return;
         end if;
      end loop;
   end Cancel_Event;

   procedure Clear (Sim : in out Simulator) is
   begin
      for I in 1 .. Sim.Size loop
         Free_Event (Sim.Queue (Capacity_Type (I)));
      end loop;
      Sim.Size := 0;
      Sim.Active_Count := 0;
      Sim.Clock := 0.0;
      Sim.Next_Id := 1;
   end Clear;

end Discrete_Event_Simulation;
