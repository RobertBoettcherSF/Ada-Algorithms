pragma SPARK_Mode (On);
package body Peeking_Iterator_Stub is
   function Advance (P : Cursor) return Cursor is
   begin
      case P is
         when 0 => return 1;
         when 1 => return 2;
         when 2 => return 3;
         when 3 => return 4;
         when 4 => return 5;
         when 5 => return 6;
         when 6 => return 7;
         when 7 => return 8;
         when 8 => return 9;
         when others => return Cursor'Last;
      end case;
   end Advance;

   function Create (Data : Value_Array; Size : Count) return Iterator is
   begin return (Data => Data, Size => Size, Position => 0); end Create;
   function Has_Next (It : Iterator) return Boolean is
   begin return It.Position < It.Size; end Has_Next;
   function Peek (It : Iterator) return Value is
   begin return It.Data (It.Position + 1); end Peek;
   procedure Next (It : in out Iterator; Result : out Value) is
   begin Result := It.Data (It.Position + 1); It.Position := Advance (It.Position); end Next;
   procedure Reset (It : in out Iterator) is
   begin It.Position := 0; end Reset;
end Peeking_Iterator_Stub;
