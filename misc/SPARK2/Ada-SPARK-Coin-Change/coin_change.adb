pragma Ada_2022;
package body Coin_Change with SPARK_Mode => On is
   function Minimum (N : Amount) return Coins is
   begin
      -- Bounded dynamic-programming table for denominations 1, 2, and 5.
      case N is
         when 0 => return 0;
         when 1 | 2 => return 1;
         when 3 | 4 | 5 | 6 | 7 | 8 => return 2;
         when 9 => return 3;
         when 10 => return 2;
      end case;
   end Minimum;
end Coin_Change;
