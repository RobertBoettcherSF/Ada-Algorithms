pragma Ada_2022;

package How_Many_Numbers_Are_Smaller with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 10;
   subtype Count is Natural range 0 .. Length;
   type Input_Array is array (Index) of Value;

   function Count_Smaller (Input : Input_Array; Pivot : Value) return Count
     with Global => null;
end How_Many_Numbers_Are_Smaller;
