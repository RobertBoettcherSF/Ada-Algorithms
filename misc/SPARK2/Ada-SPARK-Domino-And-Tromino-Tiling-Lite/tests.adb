pragma Ada_2022;
with Ada.Text_IO;
with Domino_And_Tromino_Tiling_Lite; use Domino_And_Tromino_Tiling_Lite;

procedure Tests with SPARK_Mode => Off is
   --  Tilings of a 2 x n board with 2 x 1 dominoes (either way) and
   --  L-trominoes (any rotation).
   procedure Check (N : Column_Count; Want : Tiling_Count) is
   begin
      if Number_Of_Tilings (N) /= Want then
         raise Program_Error with "n =" & N'Image & ": got" & Number_Of_Tilings (N)'Image
           & ", expected" & Want'Image;
      end if;
   end Check;
begin
   --  By hand: n = 0: the empty tiling; 1: one vertical domino; 2: two
   --  vertical or two horizontal; 3: 3 domino tilings + 2 tromino pairs = 5.
   Check (0, 1);
   Check (1, 1);
   Check (2, 2);
   Check (3, 5);
   Check (4, 11);
   Check (16, 144_467);
   --  Beyond the old table (n <= 16), by T (n) = 2 T (n - 1) + T (n - 3):
   --  T (17) = 2 * 144_467 + 29_698 = 318_632.
   Check (17, 318_632);
   Check (20, 3_418_626);
   --  The top of the range: T (28) = 1_914_332_891 <= Natural'Last, while
   --  T (29) = 2 * T (28) + T (26) = 4_222_194_104 would not fit.
   Check (27, 867_954_037);
   Check (28, 1_914_332_891);
   Ada.Text_IO.Put_Line ("PASS Domino_And_Tromino_Tiling_Lite");
end Tests;
