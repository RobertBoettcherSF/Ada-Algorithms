pragma Ada_2022;
package Longest_Common_Substring
  with SPARK_Mode => On
is
   Max_Len : constant := 4;
   subtype Len is Natural range 0 .. Max_Len;
   subtype Idx is Natural range 0 .. Max_Len;
   type Char_Array is array (Positive range <>) of Character;

   function Length (A, B : Char_Array) return Natural
     with
       Global => null,
       Pre => A'First = 1 and then B'First = 1
              and then A'Last <= Max_Len and then B'Last <= Max_Len;
end Longest_Common_Substring;
