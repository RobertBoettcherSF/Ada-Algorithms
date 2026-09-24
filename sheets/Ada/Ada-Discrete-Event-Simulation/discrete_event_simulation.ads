package Discrete_Event_Simulation is

   -- Strong domain types for simulator data
   type Sim_Time is new Long_Float range 0.0 .. Long_Float'Last;
   type Event_Id_Type is new Natural;
   type Capacity_Type is new Positive;
   type Count_Type is new Natural;

   Event_Error : exception;

   -- Abstract Event definition. Users extend this to create domain-specific events.
   type Event is abstract tagged record
      Time      : Sim_Time := 0.0;
      Id        : Event_Id_Type := 0;
      Cancelled : Boolean := False;
   end record;

   type Event_Access is access all Event'Class;

   -- Simulator type managing the clock and the event queue.
   type Simulator (Max_Capacity : Capacity_Type) is tagged private;

   -- Must be overridden to define the behavior of the event.
   procedure Execute (This : in out Event; Sim : in out Simulator'Class) is abstract;

   -- Accessors
   function Current_Time (Sim : Simulator) return Sim_Time;
   function Pending_Events (Sim : Simulator) return Count_Type;
   function Is_Empty (Sim : Simulator) return Boolean;

   -- Schedules a new event in the simulator. The simulator takes ownership of the memory.
   procedure Schedule (Sim : in out Simulator; E : Event_Access; Id : out Event_Id_Type)
     with Pre => E /= null
                 and then E.Time >= Current_Time (Sim)
                 and then Pending_Events (Sim) < Count_Type (Sim.Max_Capacity);

   -- Event-Scheduling approach: advances time to the next pending event and executes it.
   procedure Step_Next_Event (Sim : in out Simulator)
     with Pre => not Is_Empty (Sim);

   -- Advances time, executing all events scheduled up to End_Time.
   procedure Run_Until (Sim : in out Simulator; End_Time : Sim_Time)
     with Pre => End_Time >= Current_Time (Sim);

   -- Activity-Scanning approach: fixed-increment time advance executing all events in that window.
   procedure Step_Fixed_Increment (Sim : in out Simulator; Step : Sim_Time)
     with Pre => Step > 0.0;

   -- Marks an event for lazy deletion. Does nothing if the ID is not found.
   procedure Cancel_Event (Sim : in out Simulator; Id : Event_Id_Type);

   -- Empties the simulator queue and deallocates all pending events.
   procedure Clear (Sim : in out Simulator);

private
   type Event_Array is array (Capacity_Type range <>) of Event_Access;

   type Simulator (Max_Capacity : Capacity_Type) is tagged record
      Clock        : Sim_Time := 0.0;
      Queue        : Event_Array (1 .. Max_Capacity);
      Size         : Count_Type := 0;
      Active_Count : Count_Type := 0;
      Next_Id      : Event_Id_Type := 1;
   end record;

end Discrete_Event_Simulation;
