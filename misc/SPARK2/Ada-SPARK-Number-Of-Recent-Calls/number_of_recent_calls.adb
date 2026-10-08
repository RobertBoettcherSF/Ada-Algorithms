pragma SPARK_Mode (On);

package body Number_Of_Recent_Calls is
   function Number_In_Window
     (Calls   : Call_Times;
      Length  : Call_Count;
      At_Time : Time) return Call_Count is
      Result : Integer := 0;
   begin
      for I in Calls'Range loop
         pragma Loop_Invariant (Result >= 0);
         pragma Loop_Invariant (Result <= I - Calls'First);
         if I <= Length and then Calls (I) >= At_Time - 3_000 then
            Result := Result + 1;
         end if;
      end loop;
      return Call_Count (Result);
   end Number_In_Window;
end Number_Of_Recent_Calls;
