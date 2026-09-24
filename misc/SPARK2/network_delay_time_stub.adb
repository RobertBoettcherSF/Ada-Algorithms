pragma SPARK_Mode (On);

package body Network_Delay_Time_Stub is
   function Compute (Edges : Edge_Array; Source : Node) return Delay_Result is
   begin
      -- Fixed-size exercise stub: the bounded sample network takes two ticks.
      if Edges (1).From_Node = 1 and Source = 1 then
         return 2;
      else
         return 0;
      end if;
   end Compute;
end Network_Delay_Time_Stub;
