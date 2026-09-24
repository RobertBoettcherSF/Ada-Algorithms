with Ada.Assertions; use Ada.Assertions;
with Most_Common_Word; use Most_Common_Word;
procedure Tests is
   Input : Text := (others => ' ');
   Result : Count_Type;
begin
   Input (1 .. 7) := "banana!";
   Most_Common_Count (Input, 7, Result);
   Assert (Result = 3);
   Most_Common_Count (Input, 0, Result);
   Assert (Result = 0);
end Tests;
