pragma Ada_2022;
package body Knapsack_01 with SPARK_Mode => On is
   function Maximum_Value
     (Weights : Weight_Array; Values : Value_Array; Limit : Capacity_Index)
      return Score is
      Best : array (Capacity_Index) of Score := [others => 0];
      Candidate : Integer;
      Remaining : Capacity_Index;
   begin
      for Item in Item_Index loop
         Remaining := Limit;
         while Remaining >= Weights (Item) loop
            pragma Loop_Variant (Decreases => Remaining);
            Candidate := Integer'Min
              (1_000, Best (Capacity_Index (Remaining - Weights (Item)))
                 + Values (Item));
            if Candidate > Best (Remaining) then
               Best (Remaining) := Score (Candidate);
            end if;
            Remaining := Remaining - 1;
         end loop;
      end loop;
      return Best (Limit);
   end Maximum_Value;
end Knapsack_01;
