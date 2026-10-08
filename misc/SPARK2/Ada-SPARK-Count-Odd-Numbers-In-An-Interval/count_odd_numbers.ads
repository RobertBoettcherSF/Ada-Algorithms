pragma SPARK_Mode (On);

package Count_Odd_Numbers is
   subtype Endpoint is Natural range 0 .. 1_000_000_000;

   function Count (Low, High : Endpoint) return Natural
     with Pre => Low <= High, Global => null;
end Count_Odd_Numbers;
