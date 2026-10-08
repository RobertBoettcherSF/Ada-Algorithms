pragma SPARK_Mode (On);
package Combination_Iterator_Stub is
   Capacity : constant := 8;
   subtype Count is Natural range 0 .. Capacity;
   subtype Cursor is Positive range 1 .. Capacity + 10;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity + 20;
   type Value_Array is array (Index) of Value;
   type Combination is record Values : Value_Array := (others => 0); Size : Count := 0; end record;
   type Iterator is private;
   function Create (Items : Value_Array; Item_Count : Count; Choose : Positive) return Iterator
     with Global => null, Pre => Choose <= 2 and then Choose <= Item_Count;
   function Has_Next (It : Iterator) return Boolean with Global => null;
   procedure Next (It : in out Iterator; R : out Combination)
     with Global => null, Pre => Has_Next (It);
private
   type Iterator is record
      Items : Value_Array := (others => 0); Item_Count : Count := 0; Choose : Positive range 1 .. 2 := 1;
      A_Position, B_Position : Cursor := 1;
   end record;
end Combination_Iterator_Stub;
