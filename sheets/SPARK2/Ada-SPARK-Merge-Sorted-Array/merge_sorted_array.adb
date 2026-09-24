pragma SPARK_Mode (On);

package body Merge_Sorted_Array is
   function Merge_Sum (Left : Values; Right : Values; Length : Length_Type)
     return Integer is
      I : Index := Index'First;
      J : Index := Index'First;
      Total : Integer := 0;
   begin
      for K in Index loop
         pragma Loop_Invariant (Total in -1_000 * (K - 1) .. 1_000 * (K - 1));
         exit when K > Length;
         if Left (I) <= Right (J) then
            Total := Total + Left (I);
            if I < Index'Last then
               I := I + 1;
            end if;
         else
            Total := Total + Right (J);
            if J < Index'Last then
               J := J + 1;
            end if;
         end if;
      end loop;
      return Total;
   end Merge_Sum;
end Merge_Sorted_Array;
