pragma Ada_2022;
package body Divisor_Game with SPARK_Mode => On is
   function Alice_Wins (N : Number) return Boolean is
   begin
      -- The bounded game has the standard parity solution.
      return N mod 2 = 0;
   end Alice_Wins;
end Divisor_Game;
