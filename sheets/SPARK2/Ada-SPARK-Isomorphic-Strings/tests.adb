with Ada.Assertions; use Ada.Assertions;
with Isomorphic_Strings; use Isomorphic_Strings;
procedure Tests is
   Left : constant Text_Array := "paper ";
   Right : constant Text_Array := "title ";
   Bad : constant Text_Array := "tiger ";
begin
   Assert (Are_Isomorphic (Left, Right));
   Assert (not Are_Isomorphic (Left, Bad));
end Tests;
