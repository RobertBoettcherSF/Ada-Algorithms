pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Fibonacci_DP; use Fibonacci_DP;

procedure Tests is
begin
   if Compute (0) /= 0 or else Compute (1) /= 1 or else Compute (10) /= 55 then
      raise Program_Error;
   end if;
   Put_Line ("Fibonacci DP: PASS");
end Tests;
