pragma Ada_2022;

package Find_All_Duplicates_In_An_Array with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Element is Integer range 1 .. Length;
   type Input_Array is array (Index) of Element;
   subtype Output_Element is Integer range 0 .. Length;
   type Output_Array is array (Index) of Output_Element;

   function Duplicates (Input : Input_Array) return Output_Array
     with Global => null;
end Find_All_Duplicates_In_An_Array;
