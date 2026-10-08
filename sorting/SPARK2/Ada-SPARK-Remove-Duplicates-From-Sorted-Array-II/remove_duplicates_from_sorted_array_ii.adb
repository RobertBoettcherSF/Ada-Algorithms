pragma SPARK_Mode (On);

package body Remove_Duplicates_From_Sorted_Array_II is
   procedure Keep_Two (Data : in out Values; Length : in out Length_Type) is
      Write_Pos : Index := Index'First;
      New_Length : Length_Type := 0;
      Previous : Value := Data (Index'First);
      Run : Natural range 0 .. 2 := 0;
      Have_Previous : Boolean := False;
   begin
      for I in Index loop
         pragma Loop_Invariant (New_Length <= I - 1);
         exit when I > Length;
         if not Have_Previous or else Data (I) /= Previous then
            Previous := Data (I);
            Run := 1;
            Have_Previous := True;
            Data (Write_Pos) := Data (I);
            New_Length := New_Length + 1;
            if Write_Pos < Index'Last then
               Write_Pos := Write_Pos + 1;
            end if;
         elsif Run < 2 then
            Run := Run + 1;
            Data (Write_Pos) := Data (I);
            New_Length := New_Length + 1;
            if Write_Pos < Index'Last then
               Write_Pos := Write_Pos + 1;
            end if;
         end if;
      end loop;
      Length := New_Length;
   end Keep_Two;
end Remove_Duplicates_From_Sorted_Array_II;
