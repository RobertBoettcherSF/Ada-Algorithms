with Ada.Assertions; use Ada.Assertions;
with Generate_Parentheses; use Generate_Parentheses;
procedure Tests is
begin
   Assert (Generate_First = "((()))");
end Tests;
