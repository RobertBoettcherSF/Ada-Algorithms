pragma Ada_2022;
package body Final_Prices_With_A_Special_Discount with SPARK_Mode => On is
   function Final_Price (P : Price; D : Discount_Percent) return Price is
   begin return P - (P * D / 100); end Final_Price;
   function Special (P : Price) return Price is
   begin return Final_Price (P, 20); end Special;
end Final_Prices_With_A_Special_Discount;
