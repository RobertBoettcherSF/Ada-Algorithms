--  Own check (silent no-op scan, tools/vv/silent_noop.csv): Append on a full list has no
--  room for the value and must be rejected, not dropped silently.
with Ada.Assertions;
with Ada.Text_IO;
with Middle_Of_The_Linked_List; use Middle_Of_The_Linked_List;

procedure Full_Append_Check is
   L : List;
begin
   for I in 1 .. Count'Last loop
      Append (L, 1);
   end loop;
   --  (no Length function before the fix)
   begin
      Append (L, 1);
      Ada.Text_IO.Put_Line ("FAIL own check: Append on a full list accepted (value dropped)");
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line ("PASS own check: Append on a full list rejected");
   end;
end Full_Append_Check;
