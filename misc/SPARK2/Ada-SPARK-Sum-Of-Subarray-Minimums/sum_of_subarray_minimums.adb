pragma Ada_2022;

package body Sum_Of_Subarray_Minimums with SPARK_Mode => On is
   function Sum_Minimums (A : Values; Length : Length_Type) return Sum_Value is
      Total : Sum_Value := 0;
      Current_Min : Value;
   begin
      --  No saturation: each of the at most 32 * 32 (Left, Right) pairs adds a minimum <= 32, so
      --  Total <= 32 * 32 * 32 = 32_768 <= Sum_Value'Last; the loop invariants carry that bound.
      for Left in 1 .. Length loop
         pragma Loop_Invariant (Total <= 1_024 * (Left - 1));
         Current_Min := Value'Last;
         for Right in Left .. Length loop
            pragma Loop_Invariant (Total <= 1_024 * (Left - 1) + 32 * (Right - Left));
            if A (Right) < Current_Min then
               Current_Min := A (Right);
            end if;
            Total := Total + Sum_Value (Current_Min);
         end loop;
      end loop;
      return Total;
   end Sum_Minimums;
end Sum_Of_Subarray_Minimums;
