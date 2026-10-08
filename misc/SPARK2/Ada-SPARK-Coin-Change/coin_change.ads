pragma Ada_2022;
package Coin_Change with SPARK_Mode => On is
   subtype Amount is Natural range 0 .. 10;
   subtype Coins is Natural range 0 .. 10;
   function Minimum (N : Amount) return Coins with Global => null;
end Coin_Change;
