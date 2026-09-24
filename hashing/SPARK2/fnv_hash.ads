pragma Ada_2022;
package FNV_Hash
  with SPARK_Mode => On
is
   Max_Len : constant := 32;
   type Hash_Value is mod 2 ** 32;
   type Char_Array is array (Positive range <>) of Character;

   function Hash (Text : Char_Array) return Hash_Value
     with
       Global => null,
       Pre => Text'First = 1 and then Text'Last <= Max_Len;
end FNV_Hash;
