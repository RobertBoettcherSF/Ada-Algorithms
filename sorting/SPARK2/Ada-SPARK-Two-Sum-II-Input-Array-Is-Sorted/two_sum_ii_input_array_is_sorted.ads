pragma SPARK_Mode (On);

package Two_Sum_II_Input_Array_Is_Sorted is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Value is Integer range -1_000 .. 1_000;
   subtype Target is Integer range -2_000 .. 2_000;
   type Values is array (Index) of Value;

   function Has_Pair (Data : Values; Length : Length_Type; Goal : Target)
     return Boolean with Global => null;
end Two_Sum_II_Input_Array_Is_Sorted;
