pragma Ada_2022;
pragma SPARK_Mode (On);

package body Unique_Paths_II is
   function Count (Rows : Dimension; Cols : Dimension; Blocked : Grid) return Result is
      subtype Coordinate is Dimension;
      type Counts is array (Coordinate, Coordinate) of Result;
      Ways : Counts := [others => [others => 0]];
      --  No saturation: a cell (I, J) is reached by at most 2 ** (I + J - 2) monotone paths, so every
      --  count stays <= 2 ** 14 = 16_384, far inside Result; the loop invariants carry that bound.
      type Pow_Table is array (0 .. 14) of Result;
      Pow2 : constant Pow_Table :=
        [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1_024, 2_048, 4_096, 8_192, 16_384];
   begin
      for R in 1 .. Rows loop
         pragma Loop_Invariant (for all I in Coordinate =>
                                  (for all J in Coordinate => Ways (I, J) <= Pow2 (I + J - 2)));
         for C in 1 .. Cols loop
            pragma Loop_Invariant (for all I in Coordinate =>
                                     (for all J in Coordinate => Ways (I, J) <= Pow2 (I + J - 2)));
            if Blocked (R, C) then
               Ways (R, C) := 0;
            elsif R = 1 and then C = 1 then
               Ways (R, C) := 1;
            elsif R = 1 then
               Ways (R, C) := Ways (R, C - 1);
            elsif C = 1 then
               Ways (R, C) := Ways (R - 1, C);
            else
               Ways (R, C) := Ways (R - 1, C) + Ways (R, C - 1);
            end if;
         end loop;
      end loop;
      return Ways (Rows, Cols);
   end Count;
end Unique_Paths_II;
