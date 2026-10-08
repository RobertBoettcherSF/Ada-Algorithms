pragma SPARK_Mode (On);

package body Remove_Element is
   procedure Remove (Data : in out Values; Length : in out Length_Type;
                     Target : Value) is
      Write_Pos : Index := Index'First;
   begin
      for I in Index loop
         exit when I > Length;
         if Data (I) /= Target then
            Data (Write_Pos) := Data (I);
            if Write_Pos < Index'Last then
               Write_Pos := Write_Pos + 1;
            end if;
         end if;
      end loop;
      if Write_Pos = Index'First and then Length > 0 and then Data (Index'First) = Target then
         Length := 0;
      elsif Length > 0 then
         Length := Write_Pos - Index'First;
      end if;
   end Remove;
end Remove_Element;
