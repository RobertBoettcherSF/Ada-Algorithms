pragma SPARK_Mode (On);
package body BST_Iterator_Stub is
   function Empty return Tree is
   begin return (Data => (others => 0), Size => 0); end Empty;
   function Size (T : Tree) return Count is
   begin return T.Size; end Size;
   procedure Insert (T : in out Tree; V : Value) is
   begin
      case T.Size is
         when 0 => T.Data (1) := V;
         when 1 => T.Data (2) := V;
         when 2 => T.Data (3) := V;
         when 3 => T.Data (4) := V;
         when 4 => T.Data (5) := V;
         when 5 => T.Data (6) := V;
         when 6 => T.Data (7) := V;
         when 7 => T.Data (8) := V;
         when 8 => null;
      end case;
      if T.Size < Capacity then T.Size := T.Size + 1; end if;
   end Insert;
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

   function Create (T : Tree) return Iterator is
   begin return (Data => T.Data, Size => T.Size, Position => 0); end Create;
   function Has_Next (It : Iterator) return Boolean is
   begin return It.Position < It.Size; end Has_Next;
   procedure Next (It : in out Iterator; Result : out Value) is
   begin Result := It.Data (It.Position + 1); It.Position := Advance (It.Position); end Next;
end BST_Iterator_Stub;
