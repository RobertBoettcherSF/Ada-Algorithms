pragma SPARK_Mode (On);

package body Bulb_Switcher_Stub is
   function On_Count (Value : Bulbs) return On_Bulbs is
      Result : On_Bulbs := 0;
   begin
      for Candidate in 0 .. 31_623 loop
         pragma Loop_Invariant (Result <= Candidate);
         exit when Long_Long_Integer (Candidate + 1) * Long_Long_Integer (Candidate + 1) > Long_Long_Integer (Value);
         Result := Candidate + 1;
      end loop;
      return Result;
   end On_Count;
end Bulb_Switcher_Stub;
