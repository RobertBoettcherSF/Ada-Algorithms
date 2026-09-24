pragma SPARK_Mode (On);

package body Bulb_Switcher is
   function Switched_On (Value : Bulbs) return On_Count is
      Remaining : Bulbs := Value;
      Odd       : Natural range 1 .. 63_247 := 1;
      Result    : On_Count := 0;
   begin
      for Step in 1 .. 31_623 loop
         pragma Loop_Invariant (Result <= Step - 1);
         pragma Loop_Invariant (Remaining <= Value);
         pragma Loop_Invariant (Odd <= 2 * Step - 1);
         exit when Remaining < Odd;
         Remaining := Remaining - Odd;
         Result := Result + 1;
         Odd := Odd + 2;
      end loop;
      return Result;
   end Switched_On;
end Bulb_Switcher;
