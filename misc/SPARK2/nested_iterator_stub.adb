pragma SPARK_Mode (On);
package body Nested_Iterator_Stub is
   function Empty return Nested_Data is
   begin return (Data => (others => 0), Size => 0); end Empty;
   function Length (N : Nested_Data) return Count is
   begin return N.Size; end Length;
   procedure Add (N : in out Nested_Data; V : Value) is
   begin
      case N.Size is
         when 0 => N.Data (1) := V; when 1 => N.Data (2) := V; when 2 => N.Data (3) := V;
         when 3 => N.Data (4) := V; when 4 => N.Data (5) := V; when 5 => N.Data (6) := V;
         when 6 => N.Data (7) := V; when 7 => N.Data (8) := V; when 8 => null;
      end case;
      if N.Size < Capacity then N.Size := N.Size + 1; end if;
   end Add;
   function Advance (P : Cursor_Position) return Cursor_Position is
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
         when others => return Cursor_Position'Last;
      end case;
   end Advance;

   function Create (N : Nested_Data) return Iterator is
   begin return (Data => N.Data, Size => N.Size, Position => 0); end Create;
   function Has_Next (It : Iterator) return Boolean is
   begin return It.Position < It.Size; end Has_Next;
   procedure Next (It : in out Iterator; Result : out Value) is
   begin Result := It.Data (It.Position + 1); It.Position := Advance (It.Position); end Next;
end Nested_Iterator_Stub;
