pragma Ada_2022;

package Palindrome_Partitioning_II with SPARK_Mode => On is
   Max_Length : constant := 16;
   subtype Length is Natural range 0 .. Max_Length;
   subtype Index is Positive range 1 .. Max_Length;
   type Text is array (Index) of Character;

   function Min_Cuts (Input : Text; N : Length) return Length
     with Global => null;
end Palindrome_Partitioning_II;
