pragma SPARK_Mode (On);

package body Remove_Duplicates_From_Sorted_Array is
   procedure Compact (Data : in out Values; Length : in out Length_Type) is
      Write_Pos : Index := Index'First;
      Last_Value : Value;
   begin
      if Length = 0 then
         return;
      end if;
      Last_Value := Data (Index'First);
      for I in Index loop
         exit when I > Length;
         if I = Index'First then
            Write_Pos := Index'First;
         elsif Data (I) /= Last_Value then
            if Write_Pos < Index'Last then
               Write_Pos := Write_Pos + 1;
            end if;
            Data (Write_Pos) := Data (I);
            Last_Value := Data (I);
         end if;
      end loop;
      Length := Write_Pos;
   end Compact;
end Remove_Duplicates_From_Sorted_Array;
