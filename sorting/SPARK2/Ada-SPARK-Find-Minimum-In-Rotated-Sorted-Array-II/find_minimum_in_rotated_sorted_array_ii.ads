pragma Ada_2022;

package Find_Minimum_In_Rotated_Sorted_Array_II with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -1_000 .. 1_000;
   type Value_Array is array (Index) of Value;

   function Minimum (Values : Value_Array) return Value
     with Global => null;
end Find_Minimum_In_Rotated_Sorted_Array_II;
