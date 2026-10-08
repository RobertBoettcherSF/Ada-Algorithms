pragma Ada_2022;
package Pearson_Hashing
  with SPARK_Mode => On
is
   Max_Len : constant := 16;
   Table_Size : constant := 16;
   subtype Hash_Value is Natural range 0 .. Table_Size - 1;
   type Char_Array is array (Positive range <>) of Character;

   function Hash (Text : Char_Array) return Hash_Value
     with
       Global => null,
       Pre => Text'First = 1 and then Text'Last <= Max_Len;
end Pearson_Hashing;
