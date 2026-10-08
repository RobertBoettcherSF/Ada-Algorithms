pragma SPARK_Mode (On);

package body Min_Cost_Climbing_Stairs is
   function Compute (Costs : Cost_Array) return Result is
      Next_1 : Result := 0;   --  cheapest from step I + 1 (0 past the top)
      Next_2 : Result := 0;   --  cheapest from step I + 2
      Here   : Result;
   begin
      for I in reverse Index loop
         pragma Loop_Invariant (Next_1 = From_Step (Costs, I + 1) and then Next_2 = From_Step (Costs, I + 2));
         Here := Costs (I) + Integer'Min (Next_1, Next_2);
         Next_2 := Next_1;
         Next_1 := Here;
      end loop;
      return Integer'Min (Next_1, Next_2);
   end Compute;
end Min_Cost_Climbing_Stairs;
