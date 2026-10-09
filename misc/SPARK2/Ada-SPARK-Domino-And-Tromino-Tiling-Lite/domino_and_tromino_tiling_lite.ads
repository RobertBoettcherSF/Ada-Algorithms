pragma Ada_2022;

--  Domino and tromino tiling: the number of ways to tile a 2 x N board
--  with 2 x 1 dominoes (either orientation) and L-trominoes (any rotation).
--
--  Why 28: T (28) = 1_914_332_891 fits Natural, T (29) = 4_222_194_104
--  does not.
package Domino_And_Tromino_Tiling_Lite with SPARK_Mode => On is
   subtype Column_Count is Natural range 0 .. 28;
   subtype Tiling_Count is Natural;

   --  Ghost proof aids for the overflow bound: the values of the two
   --  counts below for N <= 28. The proof checks every entry against the
   --  recurrence (Post of Tiles); the tests regenerate them by brute-force
   --  tiling and by T (n) = 2 T (n - 1) + T (n - 3). The code does not use
   --  them.
   function Full_Table (N : Column_Count) return Natural is
     (case N is
        when 0 => 1, when 1 => 1, when 2 => 2, when 3 => 5, when 4 => 11,
        when 5 => 24, when 6 => 53, when 7 => 117, when 8 => 258,
        when 9 => 569, when 10 => 1_255, when 11 => 2_768, when 12 => 6_105,
        when 13 => 13_465, when 14 => 29_698, when 15 => 65_501,
        when 16 => 144_467, when 17 => 318_632, when 18 => 702_765,
        when 19 => 1_549_997, when 20 => 3_418_626, when 21 => 7_540_017,
        when 22 => 16_630_031, when 23 => 36_678_688, when 24 => 80_897_393,
        when 25 => 178_424_817, when 26 => 393_528_322,
        when 27 => 867_954_037, when 28 => 1_914_332_891)
   with Ghost;

   function Part_Table (N : Column_Count) return Natural is
     (case N is
        when 0 => 0, when 1 => 0, when 2 => 1, when 3 => 2, when 4 => 4,
        when 5 => 9, when 6 => 20, when 7 => 44, when 8 => 97, when 9 => 214,
        when 10 => 472, when 11 => 1_041, when 12 => 2_296, when 13 => 5_064,
        when 14 => 11_169, when 15 => 24_634, when 16 => 54_332,
        when 17 => 119_833, when 18 => 264_300, when 19 => 582_932,
        when 20 => 1_285_697, when 21 => 2_835_694, when 22 => 6_254_320,
        when 23 => 13_794_337, when 24 => 30_424_368, when 25 => 67_103_056,
        when 26 => 148_000_449, when 27 => 326_425_266,
        when 28 => 719_953_588)
   with Ghost;

   --  Full (n): tilings of the 2 x n board. Part (n): tilings of the
   --  2 x (n - 1) board plus one cell of column n (one row; the other row
   --  is the mirror image, hence the factor 2 below). The last column of a full tiling is closed by a
   --  vertical domino (Full (n - 1)), two horizontal dominoes
   --  (Full (n - 2)) or a tromino over a partial board (2 * Part (n - 1));
   --  a partial board ends in a tromino (Full (n - 2)) or a horizontal
   --  domino (Part (n - 1)).
   type State is record
      Full, Prev_Full, Part : Natural;   --  Full (n), Full (n - 1), Part (n)
   end record;

   function Step (S : State) return State is
     ((Full      => S.Full + S.Prev_Full + 2 * S.Part,
       Prev_Full => S.Full,
       Part      => S.Part + S.Prev_Full))
   with
     Ghost,
     Pre => Long_Long_Integer (S.Full) + Long_Long_Integer (S.Prev_Full)
              + 2 * Long_Long_Integer (S.Part) <= Long_Long_Integer (Natural'Last);

   --  Full (-1) = 0 and Part (0) = 0 start the recurrence.
   function Tiles (N : Column_Count) return State
   with
     Ghost,
     Post               =>
       Tiles'Result.Full = Full_Table (N) and then Tiles'Result.Part = Part_Table (N)
       and then Tiles'Result.Prev_Full = (if N = 0 then 0 else Full_Table (N - 1)),
     Subprogram_Variant => (Decreases => N);

   function Number_Of_Tilings (Columns : Column_Count) return Tiling_Count
   with
     Global => null,
     Post   => Number_Of_Tilings'Result = Tiles (Columns).Full;

private
   function Tiles (N : Column_Count) return State is
     (if N = 0 then (Full => 1, Prev_Full => 0, Part => 0) else Step (Tiles (N - 1)));
end Domino_And_Tromino_Tiling_Lite;
