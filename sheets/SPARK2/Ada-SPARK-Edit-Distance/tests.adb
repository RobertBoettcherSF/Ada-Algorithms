with Ada.Assertions; use Ada.Assertions;
with Edit_Distance; use Edit_Distance;

procedure Tests is
   A : Word := (others => 0);
   B : Word := (others => 0);
begin
   Assert (Distance (A, B, 0, 0) = 0);
   A (1) := 0; A (2) := 1; A (3) := 2;
   B (1) := 0; B (2) := 2; B (3) := 3;
   Assert (Distance (A, B, 3, 3) = 2);
   Assert (Distance (A, B, 3, 0) = 3);
end Tests;
