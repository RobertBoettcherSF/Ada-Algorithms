pragma Ada_2022;

package Count_Smaller_After_Self with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -100 .. 100;
   subtype Count_Range is Natural range 0 .. Length;
   type Input_Array is array (Index) of Value;
   type Count_Array is array (Index) of Count_Range;

   function Count (Input : Input_Array) return Count_Array
     with Global => null;
end Count_Smaller_After_Self;
