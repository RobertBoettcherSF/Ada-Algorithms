pragma SPARK_Mode (On);

package Pascal_Triangle is
   subtype Row_Index is Natural range 0 .. 32;
   subtype Result is Natural range 0 .. 2_147_483_647;

   function Row_Total (Row : Row_Index) return Result;
end Pascal_Triangle;
