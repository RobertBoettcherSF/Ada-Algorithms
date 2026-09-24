pragma Ada_2022;
package LZ77
  with SPARK_Mode => On
is
   Max_Len : constant := 16;
   Window_Size : constant := 4;
   subtype Length is Natural range 0 .. Max_Len;
   type Char_Array is array (Positive range <>) of Character;

   function Literal_Length (Input : Char_Array) return Length
     with
       Global => null,
       Pre => Input'First = 1 and then Input'Last <= Max_Len;
end LZ77;
