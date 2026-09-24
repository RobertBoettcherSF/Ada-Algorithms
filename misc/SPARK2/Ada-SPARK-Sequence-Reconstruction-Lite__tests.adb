with Ada.Assertions; use Ada.Assertions;
with Sequence_Reconstruction; use Sequence_Reconstruction;
procedure Tests is
   A : constant Sequence := [1, 2, 3, others => 0];
   B : constant Sequence := [1, 2, 3, others => 0];
   C : constant Sequence := [1, 3, 2, others => 0];
begin
   Assert (Matches (A, B, 3));
   Assert (not Matches (A, C, 3));
end Tests;
