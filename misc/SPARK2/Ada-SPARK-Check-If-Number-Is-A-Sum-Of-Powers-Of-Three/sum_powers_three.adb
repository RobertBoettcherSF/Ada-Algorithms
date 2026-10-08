pragma SPARK_Mode (On);

package body Sum_Powers_Three is
   function Is_Sum_Of_Powers_Of_Three (Value : Number) return Boolean is
      Current : Number := Value;
      Digit   : Natural range 0 .. 2;
   begin
      for Power in 1 .. 20 loop
         pragma Loop_Invariant (Current <= Value);
         Digit := Current mod 3;
         if Digit = 2 then
            return False;
         end if;
         Current := Current / 3;
      end loop;
      return Current = 0;
   end Is_Sum_Of_Powers_Of_Three;
end Sum_Powers_Three;
