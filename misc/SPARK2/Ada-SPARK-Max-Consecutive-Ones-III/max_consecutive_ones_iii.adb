pragma Ada_2022;

package body Max_Consecutive_Ones_III with SPARK_Mode => On is
   --  Sliding window with at most two zeroes. The longest valid window that
   --  ends at Right starts just after the third most recent zero, so it is
   --  enough to remember the positions of the last three zeroes (0 = none):
   --  Z3 <= Z2 <= Z1 <= Right, and the window is Input (Z3 + 1 .. Right).
   function Longest (Input : Input_Array) return Result is
      Z1, Z2, Z3 : Natural := 0;
      Best       : Result := 0;
   begin
      for Right in Index loop
         pragma Loop_Invariant (Z3 <= Z2 and then Z2 <= Z1 and then Z1 < Right);
         pragma Loop_Invariant (Best < Right);
         if Input (Right) = 0 then
            Z3 := Z2;
            Z2 := Z1;
            Z1 := Right;
         end if;
         Best := Result'Max (Best, Right - Z3);
      end loop;
      return Best;
   end Longest;
end Max_Consecutive_Ones_III;
