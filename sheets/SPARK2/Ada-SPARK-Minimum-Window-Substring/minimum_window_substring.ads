pragma Ada_2022;

package Minimum_Window_Substring with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Result is Natural range 0 .. Length;
   type Text_Array is array (Index) of Character;
   function Minimum (Input : Text_Array) return Result with Global => null;
end Minimum_Window_Substring;
