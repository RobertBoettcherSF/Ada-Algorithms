pragma SPARK_Mode (On);

package Coin_Change_II is
   subtype Amount is Natural range 0 .. 4;
   subtype Coin is Positive range 1 .. 4;
   subtype Count is Natural range 0 .. 100;
   type Coins is array (Positive range 1 .. 4) of Coin;

   function Combinations
     (A : Amount; Denominations : Coins; N : Amount) return Count
     with Global => null;
end Coin_Change_II;
