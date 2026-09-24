pragma Ada_2022;

package Find_The_Duplicate_Number with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Element is Integer range 1 .. Length - 1;
   type Input_Array is array (Index) of Element;

   function Duplicate (Input : Input_Array) return Element
     with Global => null;
end Find_The_Duplicate_Number;
