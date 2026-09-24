pragma Ada_2022;

package Longest_Substring_Without_Repeat with SPARK_Mode => On is
   Length : constant := 6;
   subtype Index is Positive range 1 .. Length;
   subtype Result is Natural range 0 .. Length;
   type Text_Array is array (Index) of Character;

   function Longest (Input : Text_Array) return Result
     with Global => null;
end Longest_Substring_Without_Repeat;
