pragma SPARK_Mode (On);

package body Coin_Change_II is
   type Ways is array (Amount) of Count;

   function Add (Left, Right : Count) return Count is
   begin
      if Left > Count'Last - Right then
         return Count'Last;
      else
         return Left + Right;
      end if;
   end Add;

   function Combinations
     (A : Amount; Denominations : Coins; N : Amount) return Count
   is
      W : Ways := (others => 0);
   begin
      W (0) := 1;
      for C in 1 .. N loop
         for V in Denominations (C) .. A loop
            W (V) := Add (W (V), W (V - Denominations (C)));
         end loop;
      end loop;
      return W (A);
   end Combinations;
end Coin_Change_II;
