with Ada.Assertions; use Ada.Assertions;
with Keyboard_Row; use Keyboard_Row;
procedure Tests is
   Word : Text := [others => ' '];
begin
   Word (1 .. 5) := "asdfg";
   Assert (In_One_Row (Word, 5));
   Word (1 .. 5) := "hello";
   Word (5) := 'q';
   Assert (not In_One_Row (Word, 5));
end Tests;
