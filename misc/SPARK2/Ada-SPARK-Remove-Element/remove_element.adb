pragma SPARK_Mode (On);

package body Remove_Element is
   procedure Remove (Data : in out Values; Length : in out Length_Type;
                     Target : Value) is
      Kept : Length_Type := 0;   --  elements kept so far, packed into Data (1 .. Kept)
   begin
      for I in 1 .. Length loop
         pragma Loop_Invariant (Kept < I);
         if Data (I) /= Target then
            Kept := Kept + 1;
            Data (Kept) := Data (I);
         end if;
      end loop;
      Length := Kept;
   end Remove;
end Remove_Element;
