pragma Ada_2022;

package body String_Compression with SPARK_Mode => On is
   procedure Compress (Input : Text; Length : Length_Type; Output : out Text;
                       Counts : out Run_Counts; Output_Length : out Length_Type) is
      Write : Length_Type := 0;
   begin
      Output := Input;
      Counts := [others => 0];
      for I in 1 .. Length loop
         if Write > 0 and then Output (Index (Write)) = Input (Index (I)) then
            if Counts (Index (Write)) < 32 then
               Counts (Index (Write)) := Counts (Index (Write)) + 1;
            end if;
         elsif Write < 32 then
            Write := Write + 1;
            Output (Index (Write)) := Input (Index (I));
            Counts (Index (Write)) := 1;
         end if;
      end loop;
      Output_Length := Write;
   end Compress;
end String_Compression;
