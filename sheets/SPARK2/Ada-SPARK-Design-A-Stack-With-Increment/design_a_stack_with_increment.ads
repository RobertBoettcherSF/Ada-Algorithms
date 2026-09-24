pragma Ada_2022;
package Design_A_Stack_With_Increment with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Change is Integer range 0 .. 1;
   type Stack is private;
   function Empty return Stack with Global => null;
   function Size (S : Stack) return Count with Global => null;
   procedure Push (S : in out Stack; V : Value) with Global => null, Pre => Size (S) < Capacity;
   procedure Pop (S : in out Stack; V : out Value) with Global => null, Pre => Size (S) > 0;
   procedure Increment_Bottom (S : in out Stack; K : Count; D : Change) with Global => null;
private
   subtype Slot is Positive range 1 .. Capacity;
   type Value_Array is array (Slot) of Value;
   type Stack is record Data : Value_Array := (others => 0); Count_Stored : Count := 0; end record;
end Design_A_Stack_With_Increment;
