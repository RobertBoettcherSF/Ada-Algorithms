pragma Ada_2022;
pragma SPARK_Mode (On);
--  Bounded FIFO queue (Capacity items) in a ring buffer. Items 1 .. Length
--  are the queue from the front (oldest) to the back (newest).
package Design_Circular_Queue is
   Capacity : constant := 4;
   subtype Value is Integer range -100 .. 100;
   subtype Count is Natural range 0 .. Capacity;
   type Queue is private;

   function Length (Q : Queue) return Count with Global => null;
   function Element (Q : Queue; I : Positive) return Value
     with Global => null, Pre => I <= Length (Q);
   --  The I-th item from the front (1 = front, the oldest item).

   function Empty return Queue
     with Global => null, Post => Length (Empty'Result) = 0;

   procedure Enqueue (Q : in out Queue; V : Value) with Global => null,
     Pre  => Length (Q) < Capacity,
     Post => Length (Q) = Length (Q'Old) + 1
             and then Element (Q, Length (Q)) = V
             and then (for all I in 1 .. Length (Q'Old) =>
                         Element (Q, I) = Element (Q'Old, I));
   --  V joins at the back; the items already queued keep their order.

   procedure Dequeue (Q : in out Queue) with Global => null,
     Pre  => Length (Q) > 0,
     Post => Length (Q) = Length (Q'Old) - 1
             and then (for all I in 1 .. Length (Q) =>
                         Element (Q, I) = Element (Q'Old, I + 1));
   --  The front item leaves; the others move up one place.

   function Front (Q : Queue) return Value with Global => null,
     Pre  => Length (Q) > 0,
     Post => Front'Result = Element (Q, 1);
private
   subtype Index is Positive range 1 .. Capacity;
   type Value_Array is array (Index) of Value;

   function Slot (Head : Index; K : Natural) return Index is
     ((Head - 1 + K) mod Capacity + 1)
     with Pre => K <= Capacity;
   --  The ring slot K places after Head.

   type Queue is record
      Values : Value_Array := [others => 0];
      Head   : Index := 1;
      Tail   : Index := 1;
      Size   : Count := 0;
   end record
     with Type_Invariant => Queue.Tail = Slot (Queue.Head, Queue.Size);
   --  Tail is the free slot just after the newest item.

   function Length (Q : Queue) return Count is (Q.Size);
   function Element (Q : Queue; I : Positive) return Value is
     (Q.Values (Slot (Q.Head, I - 1)));
end Design_Circular_Queue;
