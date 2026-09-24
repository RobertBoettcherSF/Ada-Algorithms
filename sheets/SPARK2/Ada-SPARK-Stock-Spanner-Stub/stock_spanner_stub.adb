pragma SPARK_Mode (On);

package body Stock_Spanner_Stub is
   function Span (Prices : Price_Array; Day : Day_Index) return Day_Index is
      Result : Day_Index := 1;
   begin
      if Day > Day_Index'First then
         for I in reverse Day_Index'First .. Day - 1 loop
            exit when Prices (I) > Prices (Day);
            if Result < Day_Index'Last then
               Result := Result + 1;
            end if;
         end loop;
      end if;
      return Result;
   end Span;
end Stock_Spanner_Stub;
