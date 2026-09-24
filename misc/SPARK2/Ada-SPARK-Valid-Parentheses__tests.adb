with Ada.Assertions; use Ada.Assertions;
with Valid_Parentheses; use Valid_Parentheses;
procedure Tests is
   Good : constant Text_Array := "({[]})";
   Bad : constant Text_Array := "([)]{}";
   Emptyish : constant Text_Array := "()[]{}";
begin
   Assert (Is_Valid (Good));
   Assert (not Is_Valid (Bad));
   Assert (Is_Valid (Emptyish));
end Tests;
