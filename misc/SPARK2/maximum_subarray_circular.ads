pragma Ada_2022;

package Maximum_Subarray_Circular with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Element is Integer range -20 .. 20;
   type Input_Array is array (Index) of Element;

   function Max_Subarray (Input : Input_Array) return Integer
     with Global => null;
end Maximum_Subarray_Circular;
