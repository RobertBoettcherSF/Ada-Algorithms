pragma Ada_2022;

package Longest_Palindromic_Substring with SPARK_Mode => On is
   Length : constant := 7;
   subtype Index is Positive range 1 .. Length;
   subtype Start_2 is Positive range 1 .. 6;
   subtype Start_3 is Positive range 1 .. 5;
   subtype Start_4 is Positive range 1 .. 4;
   subtype Start_5 is Positive range 1 .. 3;
   subtype Start_6 is Positive range 1 .. 2;
   subtype Answer_Length is Positive range 1 .. Length;
   type Text_Array is array (Index) of Character;

   function Longest_Length (Input : Text_Array) return Answer_Length
     with Global => null;
end Longest_Palindromic_Substring;
