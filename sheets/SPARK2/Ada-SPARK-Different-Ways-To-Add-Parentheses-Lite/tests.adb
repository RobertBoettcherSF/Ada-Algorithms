with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Different_Ways_Parentheses; use Different_Ways_Parentheses;
procedure Tests is
begin
   Assert (Number_Of_Ways (1) = 1);
   Assert (Number_Of_Ways (4) = 5);
   Assert (Number_Of_Ways (8) = 429);
   Put_Line ("PASS Different_Ways_Parentheses");
end Tests;
