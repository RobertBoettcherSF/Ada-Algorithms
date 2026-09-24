pragma Ada_2022;

package Product_Except_Self with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 5;
   subtype Product is Integer range 0 .. 625;
   type Input_Array is array (Index) of Value;
   type Result_Array is array (Index) of Product;

   function Compute (Input : Input_Array) return Result_Array
     with Global => null;
end Product_Except_Self;
