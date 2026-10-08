pragma SPARK_Mode (On);

package body Maximum_Ice_Cream_Bars is
   function Bars_Bought
     (Unit_Price : Price; Budget : Coins) return Bar_Count is
      Affordable : constant Natural := Budget / Unit_Price;
   begin
      if Affordable >= Bar_Count'Last then
         return Bar_Count'Last;
      else
         return Bar_Count (Affordable);
      end if;
   end Bars_Bought;
end Maximum_Ice_Cream_Bars;
