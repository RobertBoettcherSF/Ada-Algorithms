pragma Ada_2022;
with Ada.Text_IO;
with Sqrt_Integer; use Sqrt_Integer;
procedure Tests with SPARK_Mode => Off is
   --  Bit-by-bit (digit-by-digit) square root over 32-bit values: one
   --  trial bit per step, from 2 ** 15 down to 2 ** 0, so exactly 16 steps
   --  for every input. A table lookup or a linear count cannot match it.
   procedure Check (N : Number; Want : Natural) is
      R : constant Sqrt_Result := Sqrt (N);
   begin
      if R.Root /= Want or else R.Steps /= 16 then
         raise Program_Error with "N =" & N'Image & ": root" & R.Root'Image
           & ", steps" & R.Steps'Image & " (expected root" & Want'Image & ", 16 steps)";
      end if;
   end Check;
begin
   Check (0, 0);
   Check (8, 2);
   Check (99, 9);
   Check (100, 10);
   Ada.Text_IO.Put_Line ("PASS Sqrt_Integer");
end Tests;
