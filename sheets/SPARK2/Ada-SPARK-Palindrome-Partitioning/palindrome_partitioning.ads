pragma SPARK_Mode (On);

package Palindrome_Partitioning is
   subtype Length is Natural range 0 .. 4;
   subtype Symbol is Natural range 0 .. 25;
   type Word is array (Positive range 1 .. 4) of Symbol;

   function Minimum_Cuts (A : Word; N : Length) return Length
     with Global => null;
end Palindrome_Partitioning;
