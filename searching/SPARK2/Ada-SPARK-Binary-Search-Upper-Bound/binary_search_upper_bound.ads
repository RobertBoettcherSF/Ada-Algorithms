pragma Ada_2022;

package Binary_Search_Upper_Bound with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Result_Index is Positive range 1 .. Length + 1;
   subtype Value is Integer range -100 .. 100;
   subtype Target_Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;

   function Find (Input : Input_Array; Target : Target_Value) return Result_Index
     with Global => null;
end Binary_Search_Upper_Bound;
