--  Own checks (see tests/SOURCES.txt): Decode_Digital accepts every Mu_Law_8_Bit value
--  and is non-decreasing in it (mu-law expansion is monotone).
with Ada.Text_IO;
with Mu_Law; use Mu_Law;

procedure Own_Checks is
   Prev : PCM_14_Bit := PCM_14_Bit'First;
   D : PCM_14_Bit;
begin
   for Y in Mu_Law_8_Bit loop
      begin
         D := Decode_Digital (Y);
      exception
         when Constraint_Error =>
            Ada.Text_IO.Put_Line ("FAIL own check: Decode_Digital raised Constraint_Error for Y ="
                                  & Mu_Law_8_Bit'Image (Y));
            raise;
      end;
      if D < Prev then
         Ada.Text_IO.Put_Line ("FAIL own check: Decode_Digital decreases at Y =" & Mu_Law_8_Bit'Image (Y));
         raise Program_Error;
      end if;
      Prev := D;
   end loop;
   Ada.Text_IO.Put_Line ("PASS own checks: Decode_Digital for all 256 codes (no exception, non-decreasing)");
end Own_Checks;
