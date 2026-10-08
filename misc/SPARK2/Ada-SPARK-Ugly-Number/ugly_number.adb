pragma SPARK_Mode (On);

package body Ugly_Number is
   function Is_Ugly (N : Number) return Boolean is
      Value : Natural := N;
   begin
      for Step in 1 .. 31 loop
         pragma Loop_Invariant (Value >= 1);
         if Value mod 2 = 0 then
            Value := Value / 2;
         end if;
         if Value mod 3 = 0 then
            Value := Value / 3;
         end if;
         if Value mod 5 = 0 then
            Value := Value / 5;
         end if;
      end loop;
      return Value = 1;
   end Is_Ugly;
end Ugly_Number;
