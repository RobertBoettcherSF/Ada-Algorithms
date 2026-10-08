pragma Ada_2022;
package Divisor_Game with SPARK_Mode => On is
   subtype Number is Positive range 1 .. 16;
   function Alice_Wins (N : Number) return Boolean with Global => null;
end Divisor_Game;
