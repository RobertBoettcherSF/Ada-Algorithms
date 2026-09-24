pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Wiggle_Subsequence; use Wiggle_Subsequence;
procedure Tests is
begin
   pragma Assert (Wiggle_Length (1, 3, 2) = 3);
   pragma Assert (Wiggle_Length (4, 4, 4) = 1);
   pragma Assert (Wiggle_Length (1, 2, 3) = 2);
   Put_Line ("PASS Ada-SPARK-Wiggle-Subsequence");
end Tests;
