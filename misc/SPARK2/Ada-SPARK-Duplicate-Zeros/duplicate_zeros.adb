pragma Ada_2022;
package body Duplicate_Zeros with SPARK_Mode => On is
   procedure Duplicate (Input : in Int_Array; Output : out Int_Array) is
      Position : Integer range 1 .. 9 := 1;
   begin
      Output := (others => 0);
      for I in Input'Range loop
         if Position <= Output'Last then
            Output (Position) := Input (I);
            if Input (I) = 0 and then Position < Output'Last then
               Output (Position + 1) := 0;
               Position := Position + 2;
            else
               Position := Position + 1;
            end if;
         end if;
      end loop;
   end Duplicate;
end Duplicate_Zeros;
