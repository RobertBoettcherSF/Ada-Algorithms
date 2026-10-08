pragma Ada_2022;
package Final_Prices_With_A_Special_Discount with SPARK_Mode => On is
   subtype Price is Natural range 0 .. 1000;
   subtype Discount_Percent is Natural range 0 .. 100;
   function Final_Price (P : Price; D : Discount_Percent) return Price
     with Global => null, Post => Final_Price'Result <= P;
   function Special (P : Price) return Price with Global => null;
end Final_Prices_With_A_Special_Discount;
