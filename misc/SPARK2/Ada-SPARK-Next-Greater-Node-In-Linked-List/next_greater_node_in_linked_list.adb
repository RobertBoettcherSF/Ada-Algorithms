pragma Ada_2022;

package body Next_Greater_Node_In_Linked_List with SPARK_Mode => On is
   function Next_Greater (A : Values; Length : Length_Type) return Results is
      Result : Results := [others => -1];
   begin
      for I in 1 .. Length loop
         for J in I + 1 .. Length loop
            if A (J) > A (I) then
               Result (I) := Result_Value (A (J));
               exit;
            end if;
         end loop;
      end loop;
      return Result;
   end Next_Greater;
end Next_Greater_Node_In_Linked_List;
