pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Decode_Ways;

procedure Tests is
   One : constant Decode_Ways.Digit_Sequence := (1 => 1, 2 => 2, 3 => 6, others => 0);
   Zero : constant Decode_Ways.Digit_Sequence := (1 => 1, 2 => 0, others => 0);
begin
   if Decode_Ways.Count (One, 3) /= 3 or else Decode_Ways.Count (Zero, 2) /= 1 then
      raise Program_Error;
   end if;
   Put_Line ("Decode Ways: PASS");
end Tests;
