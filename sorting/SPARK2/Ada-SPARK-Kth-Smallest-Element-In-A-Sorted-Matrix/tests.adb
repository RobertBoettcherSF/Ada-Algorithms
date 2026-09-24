pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Kth_Smallest_Matrix; use Kth_Smallest_Matrix;
procedure Tests is
   M : Matrix := (1 => (1, 5, 9, 10, 0, 0, 0, 0), 2 => (2, 6, 10, 11, 0, 0, 0, 0),
      3 => (3, 7, 11, 12, 0, 0, 0, 0), 4 => (4, 8, 12, 13, 0, 0, 0, 0), others => (others => 0));
begin
   Assert (Kth (M, 4, 8) = 8);
   Put_Line ("PASS Kth Smallest Matrix");
end Tests;
