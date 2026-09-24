pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Permutation_In_String; use Permutation_In_String;
procedure Tests is
begin
   Assert (Contains_Permutation ("eidbaooo"));
   Assert (not Contains_Permutation ("eidboooo"));
end Tests;
