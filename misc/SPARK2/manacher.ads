pragma Ada_2022;
package Manacher with SPARK_Mode => On is
   Text_Length : constant := 8;
   subtype Index is Positive range 1 .. Text_Length;
   subtype Length is Natural range 0 .. Text_Length;
   type Text_Array is array (Index) of Character;

   function Longest_Palindrome_Length (Text : Text_Array) return Length;
end Manacher;
