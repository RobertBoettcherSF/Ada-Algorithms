with Ada.Assertions; use Ada.Assertions;
with Make_The_String_Great; use Make_The_String_Great;
procedure Tests is
   Input : Text := [others => ' '];
   Output : Text;
   Length : Length_Type;
begin
   Input (1 .. 10) := "leEeetcode";
   Make_Great (Input, 10, Output, Length);
   Assert (Length = 8 and then Output (1 .. 8) = "leetcode");
end Tests;
