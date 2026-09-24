pragma Ada_2022;
package body Remove_All_Adjacent_Duplicates_In_String with SPARK_Mode => On is
   procedure Reduce (Input : Buffer; N : Length; Output : out Buffer; M : out Length) is Top : Length := 0;
   begin
      Output := [others => ' '];
      for I in 1 .. N loop
         if Top > 0 and then Output (Top) = Input (I) then Top := Top - 1;
         elsif Top < Capacity then Top := Top + 1; Output (Top) := Input (I); end if;
      end loop;
      M := Top;
   end Reduce;
end Remove_All_Adjacent_Duplicates_In_String;
