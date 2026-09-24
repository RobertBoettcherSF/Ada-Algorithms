with Ada.Assertions; use Ada.Assertions;
with Count_Binary_Substrings; use Count_Binary_Substrings;
procedure Tests is
   Input : Text := (others => ' ');
   Result : Count_Type;
begin
   Input (1 .. 6) := "001100";
   Count_Substrings (Input, 6, Result);
   Assert (Result = 4);
   Count_Substrings (Input, 0, Result);
   Assert (Result = 0);
end Tests;
