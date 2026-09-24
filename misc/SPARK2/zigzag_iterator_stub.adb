pragma SPARK_Mode (On);
package body Zigzag_Iterator_Stub is
   function Advance (P : Cursor) return Cursor is
   begin
      case P is
         when 1 => return 2; when 2 => return 3; when 3 => return 4; when 4 => return 5;
         when 5 => return 6; when 6 => return 7; when 7 => return 8; when 8 => return 9;
         when others => return Cursor'Last;
      end case;
   end Advance;

   function Create (A : Value_Array; A_Size : Count; B : Value_Array; B_Size : Count) return Iterator is
   begin return (A => A, B => B, A_Size => A_Size, B_Size => B_Size, A_Position => 1, B_Position => 1, Turn => False); end Create;
   function Has_Next (It : Iterator) return Boolean is
   begin return It.A_Position <= It.A_Size or else It.B_Position <= It.B_Size; end Has_Next;
   procedure Next (It : in out Iterator; Result : out Value) is
      Value_Result : Value;
      Take_A : Boolean;
   begin
      if It.A_Position <= It.A_Size and then It.B_Position <= It.B_Size then
         Take_A := not It.Turn; It.Turn := not It.Turn;
      elsif It.A_Position <= It.A_Size then Take_A := True;
      else Take_A := False;
      end if;
      if Take_A then Value_Result := It.A (It.A_Position); It.A_Position := Advance (It.A_Position);
      else Value_Result := It.B (It.B_Position); It.B_Position := Advance (It.B_Position); end if;
      Result := Value_Result;
   end Next;
end Zigzag_Iterator_Stub;
