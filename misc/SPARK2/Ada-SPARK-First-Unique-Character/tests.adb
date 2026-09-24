with Ada.Assertions; use Ada.Assertions;
with First_Unique_Character; use First_Unique_Character;
procedure Tests is
begin
   Assert (First_Unique ("swissabc") = 2);
   Assert (First_Unique ("aabbccdd") = 0);
end Tests;
