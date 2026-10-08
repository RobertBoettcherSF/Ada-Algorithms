pragma Ada_2022;

package Intersection_Of_Two_Arrays_II with SPARK_Mode => On is
   Length : constant := 4;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 10;
   type Input_Array is array (Index) of Value;

   function Has_Common (Left, Right : Input_Array) return Boolean
     with Global => null;
end Intersection_Of_Two_Arrays_II;
