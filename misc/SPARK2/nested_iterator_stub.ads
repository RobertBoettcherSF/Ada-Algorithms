pragma SPARK_Mode (On);
package Nested_Iterator_Stub is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity + 20;
   type Value_Array is array (Index) of Value;
   type Nested_Data is private;
   type Iterator is private;
   function Empty return Nested_Data with Global => null;
   procedure Add (N : in out Nested_Data; V : Value) with Global => null, Pre => Length (N) < Capacity;
   function Length (N : Nested_Data) return Count with Global => null;
   function Create (N : Nested_Data) return Iterator with Global => null;
   function Has_Next (It : Iterator) return Boolean with Global => null;
   procedure Next (It : in out Iterator; Result : out Value) with Global => null, Pre => Has_Next (It);
private
   subtype Cursor_Position is Natural range 0 .. Capacity + 10;
   type Nested_Data is record Data : Value_Array := (others => 0); Size : Count := 0; end record;
   type Iterator is record Data : Value_Array := (others => 0); Size : Count := 0; Position : Cursor_Position := 0; end record;
end Nested_Iterator_Stub;
