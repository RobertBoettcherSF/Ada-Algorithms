pragma SPARK_Mode (On);

package body Minimum_Cost_To_Move_Chips is
   function Cost_To_Target
     (From, Target : Position) return Move_Cost is
   begin
      if From mod 2 = Target mod 2 then
         return 0;
      else
         return 1;
      end if;
   end Cost_To_Target;
end Minimum_Cost_To_Move_Chips;
