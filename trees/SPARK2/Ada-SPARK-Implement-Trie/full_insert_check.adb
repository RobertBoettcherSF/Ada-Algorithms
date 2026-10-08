--  Own check (silent no-op scan, tools/vv/silent_noop.csv): Insert of a new word when all
--  Max_Words slots are used has no room and must be rejected, not dropped silently.
with Ada.Assertions;
with Ada.Text_IO;
with Implement_Trie; use Implement_Trie;

procedure Full_Insert_Check is
   T : Trie;
   function W (N : Natural) return Word is   --  distinct three-letter words over a .. d
     (Len => 3, Chars => [1 => Character'Val (Character'Pos ('a') + N mod 4),
                          2 => Character'Val (Character'Pos ('a') + (N / 4) mod 4),
                          others => 'a']);
begin
   for I in 0 .. Max_Words - 1 loop
      Insert (T, W (I));
   end loop;
   begin
      Insert (T, W (Max_Words));
      Ada.Text_IO.Put_Line ("FAIL own check: Insert on a full trie accepted (word dropped)");
      raise Program_Error;
   exception
      when Ada.Assertions.Assertion_Error =>
         Ada.Text_IO.Put_Line ("PASS own check: Insert on a full trie rejected");
   end;
end Full_Insert_Check;
