pragma SPARK_Mode (On);

package body Missing_Ranges_Stub is
   function Count_Missing (Present : Presence) return Count is
      Result : Count := 0;
   begin
      for Position in Index loop
         pragma Loop_Invariant (Result <= Position - Index'First);
         if not Present (Position) then
            Result := Result + 1;
         end if;
      end loop;
      return Result;
   end Count_Missing;
end Missing_Ranges_Stub;
