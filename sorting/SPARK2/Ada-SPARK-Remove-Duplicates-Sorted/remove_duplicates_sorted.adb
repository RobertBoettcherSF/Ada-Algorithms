pragma Ada_2022;

package body Remove_Duplicates_Sorted with SPARK_Mode => On is
   function Remove_Duplicates (Input : Input_Array) return Result_Array is
      Result : Result_Array := [others => Fill_Value];
      Last : Index := Index'First;
   begin
      Result (Last) := Input (Input'First);
      for I in Index range 2 .. Length loop
         if Input (I) /= Result (Last) then
            if Last < Index'Last then
               Last := Last + 1;
               Result (Last) := Input (I);
            end if;
         end if;
      end loop;
      return Result;
   end Remove_Duplicates;
end Remove_Duplicates_Sorted;
