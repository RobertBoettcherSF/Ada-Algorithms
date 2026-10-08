pragma Ada_2022;
package Implement_Queue_Using_Stacks with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Index is Natural range 0 .. Capacity;
   subtype Slot is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Queue is private;
   function Empty return Queue with Global => null;
   procedure Enqueue (Q : in out Queue; V : Value) with Global => null, Pre => Size (Q) < Capacity;
   procedure Dequeue (Q : in out Queue; V : out Value) with Global => null, Pre => Size (Q) > 0;
   function Size (Q : Queue) return Natural with Global => null;
private
   type Values is array (Slot) of Value;
   type Queue is record Data : Values; Head : Slot; Tail : Slot; Count : Index; end record;
end Implement_Queue_Using_Stacks;
