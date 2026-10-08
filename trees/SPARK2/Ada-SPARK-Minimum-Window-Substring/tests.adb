pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Minimum_Window_Substring; use Minimum_Window_Substring;
with Own_Checks;
procedure Tests is
begin
   Assert (Minimum ("ADOBECOD") = 6);
   Assert (Minimum ("AAABBBCC") = 5);
   Assert (Minimum ("AAAAAAAA") = 0);
   Own_Checks;
end Tests;
