pragma Ada_2022;

package Minimum_ASCII_Delete_Sum with SPARK_Mode => On is
   Max_Length : constant := 16;
   subtype Length is Natural range 0 .. Max_Length;
   subtype Index is Positive range 1 .. Max_Length;
   subtype Cost is Natural range 0 .. 4_095;
   type Text is array (Index) of Character;

   function Delete_Sum
     (Left, Right : Text; NL, NR : Length) return Cost
     with Global => null;
end Minimum_ASCII_Delete_Sum;
