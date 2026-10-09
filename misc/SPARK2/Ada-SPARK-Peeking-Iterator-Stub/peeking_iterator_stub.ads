pragma SPARK_Mode (On);
pragma Ada_2022;
package Peeking_Iterator_Stub is
   Capacity : constant := 1_000;
   subtype Count is Natural range 0 .. Capacity;
   subtype Cursor is Natural range 0 .. Capacity;
   subtype Value is Integer range -100 .. 100;
   subtype Index is Positive range 1 .. Capacity;
   type Value_Array is array (Index) of Value;
   type Iterator is private;

   --  Model: the values Element (It, 1 .. Size (It)); Position (It) of them
   --  have been consumed.
   function Size (It : Iterator) return Count with Global => null;
   function Position (It : Iterator) return Cursor with Global => null;
   function Element (It : Iterator; I : Index) return Value with Global => null;

   function Create (Data : Value_Array; Size : Count) return Iterator
     with Global => null,
          Post   => Peeking_Iterator_Stub.Size (Create'Result) = Size
                    and then Position (Create'Result) = 0
                    and then (for all I in Index => Element (Create'Result, I) = Data (I));
   function Has_Next (It : Iterator) return Boolean
     with Global => null,
          Post   => Has_Next'Result = (Position (It) < Size (It));
   --  The next value, not consumed.
   function Peek (It : Iterator) return Value
     with Global => null, Pre => Has_Next (It),
          Post   => Peek'Result = Element (It, Position (It) + 1);
   --  The next value, consumed.
   procedure Next (It : in out Iterator; Result : out Value)
     with Global => null, Pre => Has_Next (It),
          Post   => Result = Element (It'Old, Position (It'Old) + 1)
                    and then Position (It) = Position (It'Old) + 1
                    and then Size (It) = Size (It'Old)
                    and then (for all I in Index => Element (It, I) = Element (It'Old, I));
   --  Back to the first value.
   procedure Reset (It : in out Iterator)
     with Global => null,
          Post   => Position (It) = 0
                    and then Size (It) = Size (It'Old)
                    and then (for all I in Index => Element (It, I) = Element (It'Old, I));
private
   type Iterator is record
      Data     : Value_Array := [others => 0];
      Size     : Count := 0;
      Position : Cursor := 0;
   end record
     with Type_Invariant => Position <= Size;
   function Size (It : Iterator) return Count is (It.Size);
   function Position (It : Iterator) return Cursor is (It.Position);
   function Element (It : Iterator; I : Index) return Value is (It.Data (I));
end Peeking_Iterator_Stub;
