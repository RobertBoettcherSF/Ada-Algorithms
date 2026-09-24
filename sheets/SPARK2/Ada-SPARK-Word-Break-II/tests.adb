with Ada.Assertions; use Ada.Assertions;
with Word_Break_II; use Word_Break_II;

procedure Tests is
   A : Word := (1, 1, 2, 2);
   B : Word := (1, 2, 3, 4);
begin
   Assert (Segmentations (A, 4) = 4);
   Assert (Segmentations (B, 4) = 1);
   Assert (Segmentations (A, 0) = 1);
end Tests;
