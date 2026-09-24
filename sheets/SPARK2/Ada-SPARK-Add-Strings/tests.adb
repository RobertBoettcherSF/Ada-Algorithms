with Ada.Assertions; use Ada.Assertions;
with Add_Strings; use Add_Strings;
procedure Tests is
begin
   Assert (Add (0, 0) = 0);
   Assert (Add (123, 456) = 579);
   Assert (Add (100_000_000, 100_000_000) = 200_000_000);
end Tests;
