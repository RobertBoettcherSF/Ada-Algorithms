pragma Ada_2022;
package Maximum_Product_Of_Word_Lengths with SPARK_Mode => On is
   subtype Word_Length is Natural range 0 .. 128;
   subtype Product is Natural range 0 .. 16_384;
   function Product_Of_Two (Left, Right : Word_Length) return Product
     with Global => null;
   function Maximum_Product
     (A, B, C, D : Word_Length) return Product
     with Global => null;
end Maximum_Product_Of_Word_Lengths;
