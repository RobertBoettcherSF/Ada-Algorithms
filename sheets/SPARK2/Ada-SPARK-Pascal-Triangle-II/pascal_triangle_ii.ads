pragma SPARK_Mode (On);

package Pascal_Triangle_II is
   subtype Row_Index is Natural range 0 .. 32;
   subtype Result is Natural range 0 .. 1_000_000_000;
   type Row is array (Row_Index) of Result;

   function Get (Row_Number : Row_Index; Column : Row_Index) return Result;
end Pascal_Triangle_II;
