pragma Ada_2022;

package body Remove_Adjacent_Duplicates with SPARK_Mode => On is
   procedure Remove_Duplicates (Input : Text; Length : Length_Type;
                                Output : out Text; Output_Length : out Length_Type) is
      Write : Length_Type := 0;
   begin
      Output := Input;
      for I in 1 .. Length loop
         if Write > 0 and then Output (Index (Write)) = Input (Index (I)) then
            Write := Write - 1;
         elsif Write < 32 then
            Write := Write + 1;
            Output (Index (Write)) := Input (Index (I));
         end if;
      end loop;
      Output_Length := Write;
   end Remove_Duplicates;
end Remove_Adjacent_Duplicates;
