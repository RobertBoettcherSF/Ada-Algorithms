pragma Ada_2022;
package body Defanging_IP with SPARK_Mode => On is
   procedure Defang (Input : Text; Length : Length_Type;
                     Output : out Out_Text; Output_Length : out Out_Length_Type) is
      Write : Out_Length_Type := 0;
   begin
      Output := [others => ' '];
      for I in 1 .. Length loop
         pragma Loop_Invariant (Write in I - 1 .. 3 * (I - 1));
         if Input (Index (I)) = '.' then
            Output (Write + 1) := '[';
            Output (Write + 2) := '.';
            Output (Write + 3) := ']';
            Write := Write + 3;
         else
            Output (Write + 1) := Input (Index (I));
            Write := Write + 1;
         end if;
      end loop;
      Output_Length := Write;
   end Defang;
end Defanging_IP;
