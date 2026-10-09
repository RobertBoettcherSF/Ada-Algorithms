pragma Ada_2022;
--  Pearson hashing (Pearson 1990): H := T (H xor C) over the input bytes,
--  with the same 256-entry permutation table as the plain-Ada twin
--  (hashing/Ada/Pearson-Hashing), so both give the same 8-bit hash.
package Pearson_Hashing
  with SPARK_Mode => On
is
   Max_Len : constant := 16;
   Table_Size : constant := 256;
   subtype Hash_Value is Natural range 0 .. Table_Size - 1;
   type Char_Array is array (Positive range <>) of Character;

   function Hash (Text : Char_Array) return Hash_Value
     with
       Global => null,
       Pre => Text'Length <= Max_Len;  --  any Text'First
end Pearson_Hashing;
