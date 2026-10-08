pragma SPARK_Mode (On);

package body Tweet_Counts_Stub is
   function Count_In_Range
     (Tweets : Tweet_Times;
      Length : Tweet_Count;
      First  : Timestamp;
      Last   : Timestamp) return Tweet_Count is
      Result : Integer := 0;
   begin
      for I in Tweets'Range loop
         pragma Loop_Invariant (Result >= 0);
         pragma Loop_Invariant (Result <= I - Tweets'First);
         if I <= Length and then Tweets (I) >= First and then Tweets (I) <= Last then
            Result := Result + 1;
         end if;
      end loop;
      return Tweet_Count (Result);
   end Count_In_Range;
end Tweet_Counts_Stub;
