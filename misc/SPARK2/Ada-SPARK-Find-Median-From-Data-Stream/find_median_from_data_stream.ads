pragma Ada_2022;

package Find_Median_From_Data_Stream with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Count_Index is Positive range 1 .. 8;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;

   function Median (Input : Input_Array; Count : Count_Index) return Value
     with Global => null;
end Find_Median_From_Data_Stream;
