pragma SPARK_Mode (Off);
with Ada.Text_IO; use Ada.Text_IO;
with Fibonacci_DP; use Fibonacci_DP;
with Own_Checks;

procedure Tests is
begin
   if Compute (0) /= 0 or else Compute (1) /= 1 or else Compute (10) /= 55 then
      raise Program_Error;
   end if;
   Put_Line ("Fibonacci DP: PASS");
   Own_Checks;
end Tests;
