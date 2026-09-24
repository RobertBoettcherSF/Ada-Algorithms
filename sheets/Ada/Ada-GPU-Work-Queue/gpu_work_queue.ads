pragma SPARK_Mode (On);

--  Vendor-neutral GPU-style host command queue (educational).
--  Bounded ring buffer; no access types, no heap.

package GPU_Work_Queue is

   Capacity : constant Positive := 8;

   subtype Occupancy_Count is Natural range 0 .. Capacity;
   subtype Slot_Index is Natural range 0 .. Capacity - 1;

   type Job_Kind is (Compute, Copy);

   type Queue is private;

   function Occupancy (Q : Queue) return Occupancy_Count
     with Global => null;

   function Is_Empty (Q : Queue) return Boolean
     with Global => null,
          Post   => Is_Empty'Result = (Occupancy (Q) = 0);

   function Is_Full (Q : Queue) return Boolean
     with Global => null,
          Post   => Is_Full'Result = (Occupancy (Q) = Capacity);

   function Create return Queue
     with Global => null,
          Post   => Occupancy (Create'Result) = 0;

   procedure Reset (Q : out Queue)
     with Global => null,
          Post   => Occupancy (Q) = 0;

   --  Enqueue a job. Rejects when full (Ok = False).
   procedure Submit
     (Q    : in out Queue;
      Kind : Job_Kind;
      Ok   : out Boolean)
     with Global => null,
          Post   =>
            (if Occupancy (Q'Old) = Capacity then
               not Ok and then Occupancy (Q) = Occupancy (Q'Old)
             else
               Ok and then Occupancy (Q) = Occupancy (Q'Old) + 1);

   --  Dequeue oldest job. Ok = False when empty.
   procedure Try_Pop
     (Q    : in out Queue;
      Kind : out Job_Kind;
      Ok   : out Boolean)
     with Global => null,
          Post   =>
            (if Occupancy (Q'Old) = 0 then
               not Ok and then Occupancy (Q) = 0
             else
               Ok and then Occupancy (Q) = Occupancy (Q'Old) - 1);

   --  Complete / retire oldest job (frees one slot). Same occupancy
   --  effect as Try_Pop; Kind is discarded.
   procedure Complete
     (Q  : in out Queue;
      Ok : out Boolean)
     with Global => null,
          Post   =>
            (if Occupancy (Q'Old) = 0 then
               not Ok and then Occupancy (Q) = 0
             else
               Ok and then Occupancy (Q) = Occupancy (Q'Old) - 1);

private

   type Job_Array is array (Slot_Index) of Job_Kind;

   type Queue is record
      Slots : Job_Array := [others => Compute];
      Head  : Slot_Index := 0;
      Tail  : Slot_Index := 0;
      Count : Occupancy_Count := 0;
   end record;

   function Occupancy (Q : Queue) return Occupancy_Count is (Q.Count);

   function Is_Empty (Q : Queue) return Boolean is (Q.Count = 0);

   function Is_Full (Q : Queue) return Boolean is (Q.Count = Capacity);

end GPU_Work_Queue;
