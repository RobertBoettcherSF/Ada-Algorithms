pragma Ada_2022;

package body Range_Sum_Query_2D_Immutable with SPARK_Mode => On is
   function Sum_All (G : Grid) return Sum is
      Total_Value : Sum := 0;
      Row_Value   : Sum := 0;
   begin
      for R in Index loop
         pragma Loop_Invariant (Total_Value <= Size * (R - Index'First));
         pragma Loop_Invariant (Row_Value = 0);
         for C in Index loop
            pragma Loop_Invariant (Row_Value <= C - Index'First);
            Row_Value := Row_Value + G (R, C);
         end loop;
         Total_Value := Total_Value + Row_Value;
         Row_Value := 0;
      end loop;
      return Total_Value;
   end Sum_All;
end Range_Sum_Query_2D_Immutable;
