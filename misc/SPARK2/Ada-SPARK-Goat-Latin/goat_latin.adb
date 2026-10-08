pragma Ada_2022;
package body Goat_Latin with SPARK_Mode => On is
   procedure Goat_Length (Input : Text; Length : Length_Type; Result : out Score_Type) is
      Words : Natural range 0 .. 32 := 0;
      In_Word : Boolean := False;
      Score : Natural range 0 .. 2048;
   begin
      for I in Index loop
         exit when I > Length;
         if Input (I) = ' ' then
            In_Word := False;
         elsif not In_Word then
            Words := Words + 1;
            In_Word := True;
         end if;
         pragma Loop_Invariant (Words <= I);
      end loop;
      Score := Length + 2 * Words + Words * (Words + 1) / 2;
      Result := Score_Type (Score);
   end Goat_Length;
end Goat_Latin;
