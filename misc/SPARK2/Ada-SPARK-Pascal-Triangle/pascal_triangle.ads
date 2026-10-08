pragma SPARK_Mode (On);

package Pascal_Triangle is
   --  Row R of Pascal's triangle sums to 2**R; rows up to 30 keep that within Result.
   subtype Row_Index is Natural range 0 .. 30;
   subtype Result is Natural range 0 .. 2_147_483_647;

   function Row_Total (Row : Row_Index) return Result
     with Post => Row_Total'Result = 2 ** Row;
end Pascal_Triangle;
