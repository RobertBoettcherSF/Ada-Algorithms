pragma Ada_2022;

package body Defanging_IP with SPARK_Mode => On is
   procedure Defang (Input : Text; Length : Length_Type;
                     Output : out Text; Output_Length : out Length_Type) is
      Write : Length_Type := 0;
   begin
      Output := [others => ' '];
      for I in 1 .. Length loop
         if Input (Index (I)) = '.' and then Write <= 29 then
            Write := Write + 1; Output (Index (Write)) := '[';
            Write := Write + 1; Output (Index (Write)) := '.';
            Write := Write + 1; Output (Index (Write)) := ']';
         elsif Write < 32 then
            Write := Write + 1; Output (Index (Write)) := Input (Index (I));
         end if;
      end loop;
      Output_Length := Write;
   end Defang;
end Defanging_IP;
