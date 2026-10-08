pragma SPARK_Mode (On);

package body Hit_Counter_Stub is
   function Count_Recent
     (Hits : Hit_Array; Count : Hit_Count; Now : Timestamp) return Hit_Count is
      Result : Hit_Count := 0;
   begin
      for I in Hit_Index'First .. Count loop
         if Now >= Hits (I) and then Now - Hits (I) <= Window then
            if Result < Capacity then
               Result := Result + 1;
            end if;
         end if;
      end loop;
      return Result;
   end Count_Recent;
end Hit_Counter_Stub;
