pragma SPARK_Mode (On);

package body Recent_Counter is
   function Count_Recent
     (Requests : Timestamp_Array;
      Length   : Request_Count;
      Current  : Timestamp) return Request_Count is
      Result : Integer := 0;
   begin
      for I in Requests'Range loop
         pragma Loop_Invariant (Result >= 0);
         pragma Loop_Invariant (Result <= I - Requests'First);
         if I <= Length and then Requests (I) >= Current - 3_000 then
            Result := Result + 1;
         end if;
      end loop;
      return Request_Count (Result);
   end Count_Recent;
end Recent_Counter;
