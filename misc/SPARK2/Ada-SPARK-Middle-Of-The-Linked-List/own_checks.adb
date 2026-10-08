--  Own checks (see tests/SOURCES.txt): Middle returns the middle node, the second of
--  the two middle nodes for an even length; an empty list has no middle and must be
--  rejected, not answered with 0.
with Ada.Assertions;
with Ada.Text_IO;
with Middle_Of_The_Linked_List; use Middle_Of_The_Linked_List;

procedure Own_Checks is
   L : List;
   V : Value;
begin
   for N in 1 .. Count'Last loop
      L := Empty;
      for I in 1 .. N loop
         Append (L, Value (I));   --  node I holds I
      end loop;
      if Middle (L) /= Value (N / 2 + 1) then
         Ada.Text_IO.Put_Line ("FAIL own check: Middle of" & Integer'Image (N)
                               & " nodes gave node" & Integer'Image (Middle (L))
                               & ", expected node" & Integer'Image (N / 2 + 1));
         raise Program_Error;
      end if;
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks: Middle for every length 1 .. 16");
   L := Empty;
   begin
      V := Middle (L);
      Ada.Text_IO.Put_Line ("FAIL own check: Middle of an empty list answered" & Integer'Image (V));
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line ("PASS own check: Middle of an empty list rejected");
   end;
end Own_Checks;
