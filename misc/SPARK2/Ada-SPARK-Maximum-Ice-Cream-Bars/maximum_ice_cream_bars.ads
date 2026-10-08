pragma SPARK_Mode (On);

package Maximum_Ice_Cream_Bars is
   subtype Price is Positive range 1 .. 1_000;
   subtype Coins is Natural range 0 .. 32_000;
   subtype Bar_Count is Natural range 0 .. 32;

   function Bars_Bought
     (Unit_Price : Price; Budget : Coins) return Bar_Count
     with Global => null,
          Post => Bars_Bought'Result <= Bar_Count'Last;
end Maximum_Ice_Cream_Bars;
