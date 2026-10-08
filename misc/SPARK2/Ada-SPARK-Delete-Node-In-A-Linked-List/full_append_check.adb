--  Own check (silent no-op scan, tools/vv/silent_noop.csv): Append on a full list has no
--  room for the value and must be rejected, not dropped silently.
with Ada.Assertions;
with Ada.Text_IO;
with Delete_Node_In_A_Linked_List; use Delete_Node_In_A_Linked_List;

procedure Full_Append_Check is
   L : List;
begin
   for I in 1 .. Count'Last loop
      Append (L, 1);
   end loop;
   if Length (L) /= Count'Last then raise Program_Error with "list not full"; end if;
   begin
      Append (L, 1);
      Ada.Text_IO.Put_Line ("FAIL own check: Append on a full list accepted (value dropped)");
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line ("PASS own check: Append on a full list rejected");
   end;
end Full_Append_Check;
