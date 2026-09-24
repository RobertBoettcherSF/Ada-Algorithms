pragma SPARK_Mode (On);

package body Self_Dividing_Numbers is
   function Is_Self_Dividing (Value : Input) return Boolean is
      Work : Natural := Value;
      Digit : Natural;
   begin
      while Work > 0 loop
         pragma Loop_Variant (Decreases => Work);
         pragma Loop_Invariant (Work <= Value);
         Digit := Work mod 10;
         if Digit = 0 or else Value mod Digit /= 0 then
            return False;
         end if;
         Work := Work / 10;
      end loop;
      return True;
   end Is_Self_Dividing;
end Self_Dividing_Numbers;
