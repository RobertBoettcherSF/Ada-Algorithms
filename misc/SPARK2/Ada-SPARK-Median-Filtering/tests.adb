pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Median_Filtering; use Median_Filtering;
procedure Tests is
   Uniform : constant Image := [others => [others => 42]];
   Out_I   : Image;
   Noisy   : Image := [others => [others => 10]];
   Spike   : Image := [others => [others => 0]];
begin
   Out_I := Filter_3x3 (Uniform);
   Assert (Out_I (1, 1) = 42);
   Assert (Out_I (4, 4) = 42);
   Assert (Out_I (8, 8) = 42);
   Put_Line ("PASS uniform image identity");

   --  Salt impulse at center of a flat field → median restores flat value.
   Noisy (4, 4) := 255;
   Out_I := Filter_3x3 (Noisy);
   Assert (Out_I (4, 4) = 10);
   Put_Line ("PASS center impulse removed");

   --  Corner spike with edge replication: majority of clamped window is 0.
   Spike (1, 1) := 200;
   Out_I := Filter_3x3 (Spike);
   Assert (Out_I (1, 1) = 0);
   Put_Line ("PASS corner edge-replication median");

   --  Known 3x3 neighborhood median at (2,2) of a patterned patch.
   declare
      Pat : Image := [others => [others => 0]];
   begin
      Pat (1, 1) := 1; Pat (1, 2) := 2; Pat (1, 3) := 3;
      Pat (2, 1) := 4; Pat (2, 2) := 5; Pat (2, 3) := 6;
      Pat (3, 1) := 7; Pat (3, 2) := 8; Pat (3, 3) := 9;
      Out_I := Filter_3x3 (Pat);
      --  Window at (2,2) is 1..9 → median 5.
      Assert (Out_I (2, 2) = 5);
   end;
   Put_Line ("PASS patterned 3x3 median");

   Put_Line ("All Median_Filtering tests passed.");
end Tests;
