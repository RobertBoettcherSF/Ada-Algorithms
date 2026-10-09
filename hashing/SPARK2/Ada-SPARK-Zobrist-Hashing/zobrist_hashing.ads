pragma Ada_2022;
package Zobrist_Hashing
  with SPARK_Mode => On
is
   Max_Len : constant := 16;
   type Hash_Value is mod 2 ** 32;
   type Char_Array is array (Positive range <>) of Character;

   function Hash (Text : Char_Array) return Hash_Value
     with
       Global => null,
       Pre => Text'Length <= Max_Len;
   --  Any Text'First: the key of a character depends on its position
   --  within Text (I - Text'First), not on the storage index.
end Zobrist_Hashing;
