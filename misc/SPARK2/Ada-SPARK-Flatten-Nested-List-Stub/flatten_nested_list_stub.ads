pragma SPARK_Mode (On);
package Flatten_Nested_List_Stub is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   type Values is private;
   function Empty return Values with Global => null;
   procedure Add (N : in out Values; V : Value) with Global => null, Pre => Length (N) < Capacity;
   function Flatten (N : Values) return Values with Global => null;
   function Length (N : Values) return Count with Global => null;
   function Element_At (N : Values; Position : Positive) return Value
     with Global => null, Pre => Position <= Length (N);
private
   subtype Index is Positive range 1 .. Capacity;
   type Value_Array is array (Index) of Value;
   type Values is record Data : Value_Array := (others => 0); Size : Count := 0; end record;
end Flatten_Nested_List_Stub;
