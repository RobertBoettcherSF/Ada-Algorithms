pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Interleaving_String; use Interleaving_String;
with Own_Checks;

procedure Tests is
   A : constant Word := [1, 2, 0, 0];
   B : constant Word := [3, 4, 0, 0];
   C : constant Word := [1, 3, 2, 4];
   D : constant Word := [1, 4, 2, 3];
begin
   Assert (Is_Interleaving (A, B, C, 2, 2, 4));
   Assert (not Is_Interleaving (A, B, D, 2, 2, 4));
   Assert (Is_Interleaving (A, B, C, 0, 0, 0));
   Own_Checks;
end Tests;
