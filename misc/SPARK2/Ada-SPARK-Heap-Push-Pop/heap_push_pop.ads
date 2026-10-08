pragma Ada_2022;

package Heap_Push_Pop with SPARK_Mode => On is
   Capacity : constant := 32;
   subtype Index is Natural range 0 .. Capacity;
   subtype Slot is Positive range 1 .. Capacity;
   subtype Value is Integer range -1000 .. 1000;
   type Heap is private;
   function Empty return Heap with Global => null;
   procedure Push (H : in out Heap; V : Value) with Global => null, Pre => Size (H) < Capacity;
   procedure Pop_Min (H : in out Heap; V : out Value) with Global => null, Pre => Size (H) > 0;
   function Size (H : Heap) return Natural with Global => null;
private
   type Value_Array is array (Slot) of Value;
   type Heap is record Data : Value_Array; Count : Index; end record;
end Heap_Push_Pop;
