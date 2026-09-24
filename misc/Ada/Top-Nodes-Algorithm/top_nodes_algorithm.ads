package Top_Nodes_Algorithm is

   type Resource_Amount is new Natural;
   type Time_Point is new Natural;
   type Reservation_ID is new Positive;

   -- A bounded, deterministic Calendar.
   -- Capacity is the number of elementary periods 'n' in the sliding window.
   -- Max_Reservations defines the upper bound of concurrent active reservations.
   type Calendar (Capacity : Positive; Max_Reservations : Positive) is tagged private;

   -- Initializes or resets the calendar to an empty state.
   procedure Initialize (Cal : in out Calendar);

   -- 1. Check if an amount of resource is available during a specific period of time.
   -- Returns True if the requested Amount does not cause the interval to exceed Max_Capacity.
   function Check_Availability
     (Cal          : Calendar;
      Start_Time   : Time_Point;
      End_Time     : Time_Point;
      Amount       : Resource_Amount;
      Max_Capacity : Resource_Amount) return Boolean;

   -- 2. Reserve an amount of resource for a specific period of time.
   -- The user is responsible for ensuring availability (via Check_Availability) prior to reserving.
   procedure Reserve
     (Cal        : in out Calendar;
      Start_Time : Time_Point;
      End_Time   : Time_Point;
      Amount     : Resource_Amount;
      ID         : out Reservation_ID;
      Success    : out Boolean);

   -- 3. Delete a previous reservation.
   procedure Delete_Reservation
     (Cal : in out Calendar;
      ID  : Reservation_ID);

   -- 4. Move the calendar forward.
   -- The calendar covers a defined duration [Current_Start, Current_Start + Capacity - 1].
   -- Moving it forward logically advances time. It dynamically trims or drops expired
   -- reservations taking $O(log n + M log n)$ where M is active reservations spanning the boundary.
   procedure Move_Forward
     (Cal   : in out Calendar;
      Shift : Natural := 1);

   -- Get the current start time of the calendar window
   function Get_Current_Start (Cal : Calendar) return Time_Point;

   -- Query the current resource usage in a time range (for testing)
   function Query_Ranges
     (Cal        : Calendar;
      Start_Time : Time_Point;
      End_Time   : Time_Point) return Resource_Amount;

private

   type Tree_Node is record
      Max_Child_Q  : Resource_Amount := 0;
      Top_Node_Res : Resource_Amount := 0;
   end record;

   -- Segment trees bounded natively require max 4 * N nodes to guarantee space.
   -- Use a large enough constant for the node array
   Max_Capacity_Constant : constant Positive := 1000;
   Max_Reservations_Constant : constant Positive := 1000;
   
   type Node_Array is array (1 .. 4 * Max_Capacity_Constant) of Tree_Node;
   type Optional_ID is new Natural; -- 0 represents Null

   type Reservation_Record is record
      Is_Active  : Boolean := False;
      Start_Time : Time_Point := 0;
      End_Time   : Time_Point := 0;
      Amount     : Resource_Amount := 0;
      Prev       : Optional_ID := 0;
      Next       : Optional_ID := 0;
   end record;

   type Reservation_Array is array (1 .. Max_Reservations_Constant) of Reservation_Record;

   type Calendar (Capacity : Positive; Max_Reservations : Positive) is tagged record
      Current_Start : Time_Point := 0;
      
      -- Perfect binary tree representation
      Nodes         : Node_Array := (others => (Max_Child_Q => 0, Top_Node_Res => 0));
      
      -- Doubly linked list tracking in contiguous memory for fast boundary iteration
      Reservations  : Reservation_Array;
      Active_Head   : Optional_ID := 0;
      Last_ID       : Reservation_ID := 1;
   end record;

end Top_Nodes_Algorithm;
