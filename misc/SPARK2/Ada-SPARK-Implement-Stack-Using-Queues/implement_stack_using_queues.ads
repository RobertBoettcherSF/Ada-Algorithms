pragma Ada_2022;
package Implement_Stack_Using_Queues with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Index is Natural range 0 .. Capacity;
   subtype Slot is Positive range 1 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Stack is private;
   function Empty return Stack with Global => null;
   procedure Push (S : in out Stack; V : Value) with Global => null, Pre => Size (S) < Capacity;
   procedure Pop (S : in out Stack; V : out Value) with Global => null, Pre => Size (S) > 0;
   function Size (S : Stack) return Natural with Global => null;
private
   type Values is array (Slot) of Value;
   type Stack is record Data : Values; Count : Index; end record;
end Implement_Stack_Using_Queues;
