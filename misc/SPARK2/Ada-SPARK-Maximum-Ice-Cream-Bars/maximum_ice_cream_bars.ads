pragma SPARK_Mode (On);

package Maximum_Ice_Cream_Bars is
   subtype Price is Positive range 1 .. 1_000;
   subtype Coins is Natural range 0 .. 32_000;
   --  the shop has Bar_Count'Last = 32 bars, all at Unit_Price; as in the standard problem
   --  (at most n bars can be bought) the answer is min (32, Budget / Unit_Price)
   subtype Bar_Count is Natural range 0 .. 32;

   function Bars_Bought
     (Unit_Price : Price; Budget : Coins) return Bar_Count
     with Global => null,
          Post => Bars_Bought'Result = Natural'Min (Bar_Count'Last, Budget / Unit_Price);
end Maximum_Ice_Cream_Bars;
