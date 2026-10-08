pragma SPARK_Mode (On);

package body Unique_Paths_II is
   function Add_Bounded (Left, Right : Result) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Count (Rows : Dimension; Cols : Dimension; Blocked : Grid) return Result is
      subtype Coordinate is Dimension;
      type Counts is array (Coordinate, Coordinate) of Result;
      Ways : Counts := (others => (others => 0));
   begin
      for R in 1 .. Rows loop
         for C in 1 .. Cols loop
            if Blocked (R, C) then
               Ways (R, C) := 0;
            elsif R = 1 and then C = 1 then
               Ways (R, C) := 1;
            elsif R = 1 then
               Ways (R, C) := Ways (R, C - 1);
            elsif C = 1 then
               Ways (R, C) := Ways (R - 1, C);
            else
               Ways (R, C) := Add_Bounded (Ways (R - 1, C), Ways (R, C - 1));
            end if;
         end loop;
      end loop;
      return Ways (Rows, Cols);
   end Count;
end Unique_Paths_II;
