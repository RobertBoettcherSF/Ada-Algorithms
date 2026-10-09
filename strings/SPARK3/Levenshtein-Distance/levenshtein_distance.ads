pragma Ada_2022;
package Levenshtein_Distance
  with SPARK_Mode => On
is
   Max_Len : constant := 8;
   subtype Len is Natural range 0 .. Max_Len;
   subtype Idx is Natural range 0 .. Max_Len;
   type Char_Array is array (Positive range <>) of Character;

   function Distance (A, B : Char_Array) return Natural
     with
       Global => null,
       --  Any origin: character K of A is A (A'First + (K - 1)).
       Pre    => A'Length <= Max_Len and then B'Length <= Max_Len,
       Post   => Distance'Result <= A'Length + B'Length;
end Levenshtein_Distance;
