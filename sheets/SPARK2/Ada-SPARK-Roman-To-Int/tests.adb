with Ada.Assertions; use Ada.Assertions;
with Roman_To_Int; use Roman_To_Int;
procedure Tests is
   Example : constant Roman_Text := "MCMXCIV";
   Simple : constant Roman_Text := "VIII   ";
begin
   Assert (To_Integer (Example) = 1994);
   Assert (To_Integer (Simple) = 8);
end Tests;
