pragma Ada_2022;
package Damerau_Levenshtein_Distance
  with SPARK_Mode => On
is
   Max_Len : constant := 4;
   subtype Len is Natural range 0 .. Max_Len;
   subtype Idx is Natural range 0 .. Max_Len;
   type Char_Array is array (Positive range <>) of Character;

   function Distance (A, B : Char_Array) return Natural
     with
       Global => null,
       Pre => A'Length <= Max_Len and then B'Length <= Max_Len;
   --  A and B may start at any index (First-relative); row I of the DP
   --  table reads A (A'First + (I - 1)), column J reads B (B'First + (J - 1)).
end Damerau_Levenshtein_Distance;
