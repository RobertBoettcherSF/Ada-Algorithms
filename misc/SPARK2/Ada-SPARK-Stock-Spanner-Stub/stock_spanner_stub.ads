pragma SPARK_Mode (On);

package Stock_Spanner_Stub is
   Capacity : constant := 8;
   subtype Price is Integer range 0 .. 1000;
   subtype Day_Index is Positive range 1 .. Capacity;
   type Price_Array is array (Day_Index) of Price;

   function Span (Prices : Price_Array; Day : Day_Index) return Day_Index
     with Global => null;
end Stock_Spanner_Stub;
