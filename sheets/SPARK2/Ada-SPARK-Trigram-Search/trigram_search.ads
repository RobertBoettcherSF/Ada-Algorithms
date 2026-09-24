pragma Ada_2022;
package Trigram_Search
  with SPARK_Mode => On
is
   Max_Len : constant := 16;
   type Char_Array is array (Positive range <>) of Character;

   function Contains (Text : Char_Array; A, B, C : Character) return Boolean
     with
       Global => null,
       Pre => Text'First = 1 and then Text'Last <= Max_Len;
end Trigram_Search;
