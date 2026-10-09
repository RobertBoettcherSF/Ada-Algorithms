with Ada.Assertions; use Ada.Assertions;
with First_Unique_Character; use First_Unique_Character;
with Own_Checks;
procedure Tests is
begin
   Assert (First_Unique ("swissabc") = 2);
   Assert (First_Unique ("aabbccdd") = 0);
   --  Hand-worked (agent A3): the unique character is the last one, the
   --  first one, or there is none although every character but one repeats.
   Assert (First_Unique ("abababaz") = 8);
   Assert (First_Unique ("xaabbccd") = 1);
   Assert (First_Unique ("abababab") = 0);
   Assert (First_Unique ("aaaaaaab") = 8);
   Own_Checks;
end Tests;
