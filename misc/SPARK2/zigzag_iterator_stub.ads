pragma SPARK_Mode (On);
package Zigzag_Iterator_Stub is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Cursor is Positive range 1 .. Capacity + 10;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity + 20;
   type Value_Array is array (Index) of Value;
   type Iterator is private;
   function Create (A : Value_Array; A_Size : Count; B : Value_Array; B_Size : Count) return Iterator
     with Global => null;
   function Has_Next (It : Iterator) return Boolean with Global => null;
   procedure Next (It : in out Iterator; Result : out Value) with Global => null, Pre => Has_Next (It);
private
   type Iterator is record
      A, B : Value_Array := (others => 0); A_Size, B_Size : Count := 0;
      A_Position, B_Position : Cursor := 1; Turn : Boolean := False;
   end record;
end Zigzag_Iterator_Stub;
