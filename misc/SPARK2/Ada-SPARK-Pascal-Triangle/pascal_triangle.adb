pragma SPARK_Mode (On);

package body Pascal_Triangle is
   function Add_Bounded (Left, Right : Result) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Row_Total (Row : Row_Index) return Result is
      Total : Result := 1;
   begin
      for I in 1 .. Row loop
         pragma Loop_Invariant (Total in Result);
         Total := Add_Bounded (Total, Total);
      end loop;
      return Total;
   end Row_Total;
end Pascal_Triangle;
