pragma Ada_2022;

package Product_Of_Array_Except_Self with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Element is Integer range 0 .. 2;
   type Input_Array is array (Index) of Element;
   type Output_Array is array (Index) of Integer;

   function Products (Input : Input_Array) return Output_Array
     with Global => null;
end Product_Of_Array_Except_Self;
