pragma SPARK_Mode (On);

package body Count_Odd_Numbers is
   function Count (Low, High : Endpoint) return Natural is
      Length : Natural := High - Low + 1;
      Result : Natural := Length / 2;
   begin
      if Length mod 2 = 1 and then Low mod 2 = 1 then
         Result := Result + 1;
      end if;
      return Result;
   end Count;
end Count_Odd_Numbers;
