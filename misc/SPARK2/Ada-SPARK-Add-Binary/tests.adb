with Ada.Assertions; use Ada.Assertions;
with Add_Binary; use Add_Binary;
with Own_Checks;
procedure Tests is
begin
   Assert (Add ("00001011", "00000101") = "00010000");
   Assert (Add ("00000000", "00000000") = "00000000");
   Assert (Add ("11111111", "00000001") = "00000000");
   Own_Checks;
end Tests;
