pragma Ada_2022;
package Circular_Queue with SPARK_Mode => On is
   Capacity : constant := 8; type Queue is private;
   procedure Initialize (Q : out Queue); function Is_Empty (Q : Queue) return Boolean;
   function Is_Full (Q : Queue) return Boolean; function Length (Q : Queue) return Natural;
   procedure Enqueue (Q : in out Queue; Value : Integer) with Pre => Length (Q) < Capacity;
   procedure Dequeue (Q : in out Queue; Value : out Integer) with Pre => Length (Q) > 0;
   function Peek (Q : Queue) return Integer with Pre => Length (Q) > 0;
private
   subtype Index is Positive range 1 .. Capacity; subtype Count_Range is Natural range 0 .. Capacity;
   type Data_Array is array (Index) of Integer;
   type Queue is record Data : Data_Array; Head, Tail : Index; Count : Count_Range; end record;
end Circular_Queue;
