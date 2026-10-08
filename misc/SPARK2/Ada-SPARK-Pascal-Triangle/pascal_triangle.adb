pragma SPARK_Mode (On);

package body Pascal_Triangle is
   --  each row sums to twice the row above it (every entry is added to the two entries below it)
   function Row_Total (Row : Row_Index) return Result is
      Total : Result := 1;
   begin
      for I in 1 .. Row loop
         Total := Total + Total;
         pragma Loop_Invariant (Total = 2 ** I);
      end loop;
      return Total;
   end Row_Total;
end Pascal_Triangle;
