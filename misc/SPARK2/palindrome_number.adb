pragma SPARK_Mode (On);

package body Palindrome_Number is
   function Is_Palindrome (Value : Input) return Boolean is
      Work : Long_Long_Integer := Long_Long_Integer (Value);
      Reversed : Long_Long_Integer := 0;
      Digit : Long_Long_Integer;
   begin
      if Value = 0 then
         return True;
      end if;
      while Work > 0 loop
         pragma Loop_Variant (Decreases => Work);
         pragma Loop_Invariant (Work >= 0);
         pragma Loop_Invariant (Work <= Long_Long_Integer (Value));
         pragma Loop_Invariant (Reversed >= 0);
         Digit := Work mod 10;
         if Reversed > 1_000_000_000 then
            return False;
         end if;
         Reversed := Reversed * 10 + Digit;
         Work := Work / 10;
      end loop;
      return Reversed = Long_Long_Integer (Value);
   end Is_Palindrome;
end Palindrome_Number;
