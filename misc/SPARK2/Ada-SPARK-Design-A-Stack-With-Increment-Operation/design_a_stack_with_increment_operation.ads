pragma Ada_2022;
package Design_A_Stack_With_Increment_Operation with SPARK_Mode => On is
   Capacity : constant := 8;
   subtype Index is Natural range 0 .. Capacity;
   subtype Slot is Positive range 1 .. Capacity;
   subtype Value is Integer range 0 .. 1000;
   subtype Amount is Integer range 0 .. 10;
   type Stack is private;
   function Empty return Stack with Global => null;
   procedure Push (S : in out Stack; V : Value) with Global => null, Pre => Size (S) < Capacity;
   --  True when adding By to the bottom Bottom elements (all of them if
   --  fewer are stored) keeps every value within Value.
   function Fits (S : Stack; Bottom : Index; By : Amount) return Boolean with Global => null;
   --  Adds By to the bottom Bottom elements; an increment that would leave
   --  Value is refused by the precondition instead of being skipped.
   procedure Increment (S : in out Stack; Bottom : Index; By : Amount)
     with Global => null, Pre => Fits (S, Bottom, By);
   procedure Pop (S : in out Stack; V : out Value) with Global => null, Pre => Size (S) > 0;
   function Size (S : Stack) return Natural with Global => null;
private
   type Values is array (Slot) of Value;
   type Stack is record Data : Values; Count : Index; end record;
   function Fits (S : Stack; Bottom : Index; By : Amount) return Boolean is
     (for all I in 1 .. Integer'Min (Bottom, S.Count) => S.Data (I) <= Value'Last - By);
end Design_A_Stack_With_Increment_Operation;
