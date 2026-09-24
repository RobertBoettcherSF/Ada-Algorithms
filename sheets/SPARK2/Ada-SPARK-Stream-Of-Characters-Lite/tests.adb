with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Stream_Of_Characters_Lite; use Stream_Of_Characters_Lite;
procedure Tests is
   Words : constant Word_Array :=
     (1 => (Len => 2, Chars => ['a','b','a','a']),
      others => (Len => 0, Chars => (others => 'a')));
   S : Stream := (others => <>);
begin
   Push (S, 'a');
   Push (S, 'b');
   Assert (Query (S, Words));
   Push (S, 'c');
   Assert (not Query (S, Words));
   Put_Line ("PASS Stream_Of_Characters_Lite");
end Tests;
