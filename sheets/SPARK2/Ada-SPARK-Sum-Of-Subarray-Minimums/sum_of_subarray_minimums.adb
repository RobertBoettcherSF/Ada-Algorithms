pragma Ada_2022;

package body Sum_Of_Subarray_Minimums with SPARK_Mode => On is
   function Sum_Minimums (A : Values; Length : Length_Type) return Sum_Value is
      Total : Sum_Value := 0;
      Current_Min : Value;
   begin
      for Left in 1 .. Length loop
         Current_Min := Value'Last;
         for Right in Left .. Length loop
            if A (Right) < Current_Min then
               Current_Min := A (Right);
            end if;
            if Total <= Sum_Value'Last - Sum_Value (Current_Min) then
               Total := Total + Sum_Value (Current_Min);
            end if;
         end loop;
      end loop;
      return Total;
   end Sum_Minimums;
end Sum_Of_Subarray_Minimums;
