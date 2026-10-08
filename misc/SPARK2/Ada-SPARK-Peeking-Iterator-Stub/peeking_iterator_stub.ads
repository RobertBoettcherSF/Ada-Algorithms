pragma SPARK_Mode (On);
package Peeking_Iterator_Stub is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Cursor is Natural range 0 .. Capacity + 10;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity + 20;
   type Value_Array is array (Index) of Value;
   type Iterator is private;
   function Create (Data : Value_Array; Size : Count) return Iterator with Global => null;
   function Has_Next (It : Iterator) return Boolean with Global => null;
   function Peek (It : Iterator) return Value with Global => null, Pre => Has_Next (It);
   procedure Next (It : in out Iterator; Result : out Value) with Global => null, Pre => Has_Next (It);
   procedure Reset (It : in out Iterator) with Global => null;
private
   type Iterator is record Data : Value_Array := (others => 0); Size : Count := 0; Position : Cursor := 0; end record;
end Peeking_Iterator_Stub;
