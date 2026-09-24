pragma Ada_2022;
package body Maximum_Product_Of_Word_Lengths with SPARK_Mode => On is
   function Product_Of_Two (Left, Right : Word_Length) return Product is
   begin
      return Left * Right;
   end Product_Of_Two;
   function Maximum_Product
     (A, B, C, D : Word_Length) return Product is
      First : constant Product := Product_Of_Two (A, B);
      Second : constant Product := Product_Of_Two (C, D);
   begin
      if First >= Second then
         return First;
      else
         return Second;
      end if;
   end Maximum_Product;
end Maximum_Product_Of_Word_Lengths;
