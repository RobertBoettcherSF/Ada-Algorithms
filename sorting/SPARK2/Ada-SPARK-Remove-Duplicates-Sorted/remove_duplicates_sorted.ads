pragma Ada_2022;

package Remove_Duplicates_Sorted with SPARK_Mode => On is
   Length : constant := 5;
   Fill_Value : constant := -11;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -10 .. 10;
   subtype Result_Value is Integer range Fill_Value .. 10;
   type Input_Array is array (Index) of Value;
   type Result_Array is array (Index) of Result_Value;

   function Remove_Duplicates (Input : Input_Array) return Result_Array
     with Global => null;
end Remove_Duplicates_Sorted;
