pragma Ada_2022;
package LCS
  with SPARK_Mode => On
is
   Max_Len : constant := 12;
   subtype Len is Natural range 0 .. Max_Len;
   type Char_Array is array (Positive range <>) of Character;

   function Length (A, B : Char_Array) return Natural
     with
       Global => null,
       Pre    => A'Length <= Max_Len and then B'Length <= Max_Len,
       --  any A'First / B'First: row I reads A (A'First + (I - 1)),
       --  column J reads B (B'First + (J - 1))
       Post   => Length'Result <= A'Length
                 and then Length'Result <= B'Length;
end LCS;
