pragma SPARK_Mode (On);
pragma Ada_2022;
package body Peeking_Iterator_Stub is
   function Create (Data : Value_Array; Size : Count) return Iterator is
     (Data => Data, Size => Size, Position => 0);

   function Has_Next (It : Iterator) return Boolean is
     (It.Position < It.Size);

   function Peek (It : Iterator) return Value is
     (It.Data (It.Position + 1));

   procedure Next (It : in out Iterator; Result : out Value) is
   begin
      Result := It.Data (It.Position + 1);
      It.Position := It.Position + 1;
   end Next;

   procedure Reset (It : in out Iterator) is
   begin
      It.Position := 0;
   end Reset;
end Peeking_Iterator_Stub;
