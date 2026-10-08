pragma SPARK_Mode (On);
package body Combination_Iterator_Stub is
   function Advance (P : Cursor) return Cursor is
   begin
      case P is
         when 1 => return 2; when 2 => return 3; when 3 => return 4; when 4 => return 5;
         when 5 => return 6; when 6 => return 7; when 7 => return 8; when 8 => return 9;
         when others => return Cursor'Last;
      end case;
   end Advance;

   function Create (Items : Value_Array; Item_Count : Count; Choose : Positive) return Iterator is
      B : Cursor := 1;
   begin
      if Choose = 2 then B := 2; end if;
      return (Items => Items, Item_Count => Item_Count, Choose => Choose, A_Position => 1, B_Position => B);
   end Create;
   function Has_Next (It : Iterator) return Boolean is
   begin
      if It.Choose = 1 then return It.A_Position <= It.Item_Count;
      else return It.A_Position < It.Item_Count and then It.B_Position <= It.Item_Count; end if;
   end Has_Next;
   procedure Next (It : in out Iterator; R : out Combination) is
      Temp : Combination := (Values => (others => 0), Size => It.Choose);
   begin
      Temp.Values (1) := It.Items (It.A_Position);
      if It.Choose = 1 then
         It.A_Position := Advance (It.A_Position);
      else
         Temp.Values (2) := It.Items (It.B_Position);
         if It.B_Position < It.Item_Count then It.B_Position := Advance (It.B_Position);
         else It.A_Position := Advance (It.A_Position); It.B_Position := Advance (It.A_Position); end if;
      end if;
      R := Temp;
   end Next;
end Combination_Iterator_Stub;
