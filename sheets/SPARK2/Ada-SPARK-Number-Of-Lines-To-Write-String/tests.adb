with Ada.Assertions; use Ada.Assertions;
with Write_String_Lines; use Write_String_Lines;
procedure Tests is
   Widths : Width_Table := (others => 10);
   Input  : Text := [others => ' '];
   Lines  : Line_Count_Type;
   Last   : Width_Type;
begin
   Input (1 .. 11) := "helloworldx";
   Lines_For (Widths, Input, 11, Lines, Last);
   Assert (Lines = 2 and then Last = 10);
end Tests;
