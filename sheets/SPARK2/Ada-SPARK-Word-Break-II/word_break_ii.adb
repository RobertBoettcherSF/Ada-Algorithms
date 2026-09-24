pragma SPARK_Mode (On);

package body Word_Break_II is
   type Ways is array (Length) of Count;

   function Add (Left, Right : Count) return Count is
   begin
      if Left > Count'Last - Right then
         return Count'Last;
      else
         return Left + Right;
      end if;
   end Add;

   function Segmentations (A : Word; N : Length) return Count is
      W : Ways := (others => 0);
   begin
      W (0) := 1;
      for I in 1 .. N loop
         W (I) := W (I - 1);
         if I >= 2 and then A (I) = A (I - 1) then
            W (I) := Add (W (I), W (I - 2));
         end if;
      end loop;
      return W (N);
   end Segmentations;
end Word_Break_II;
