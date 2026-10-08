--  Own check (silent no-op scan, tools/vv/silent_noop.csv): Add_Word of a new word when all
--  Max_Words slots are used has no room and must be rejected, not dropped silently.
with Ada.Assertions;
with Ada.Text_IO;
with Design_Add_And_Search_Words; use Design_Add_And_Search_Words;

procedure Full_Insert_Check is
   D : Dictionary;
   function W (N : Natural) return Word is   --  distinct three-letter words over a .. d
     (Len => 3, Chars => [1 => Character'Val (Character'Pos ('a') + N mod 4),
                          2 => Character'Val (Character'Pos ('a') + (N / 4) mod 4),
                          others => 'a']);
begin
   for I in 0 .. Max_Words - 1 loop
      Add_Word (D, W (I));
   end loop;
   begin
      Add_Word (D, W (Max_Words));
      Ada.Text_IO.Put_Line ("FAIL own check: Add_Word on a full dictionary accepted (word dropped)");
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line ("PASS own check: Add_Word on a full dictionary rejected");
   end;
end Full_Insert_Check;
