pragma Ada_2022;

package body Path_Sum_III_Lite with SPARK_Mode => On is
   function Path_Total (A : Nodes) return Sum is
      Result : Sum := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant
           (Result <= Node_Value'Last * (I - Index'First));
         Result := Result + A (I);
      end loop;
      return Result;
   end Path_Total;
end Path_Sum_III_Lite;
