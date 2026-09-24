pragma SPARK_Mode (On);

package Arranging_Coins is
   subtype Coins is Natural range 0 .. 1_000_000_000;
   subtype Rows is Natural range 0 .. 44_721;

   function Full_Rows (Value : Coins) return Rows
     with Global => null;
end Arranging_Coins;
