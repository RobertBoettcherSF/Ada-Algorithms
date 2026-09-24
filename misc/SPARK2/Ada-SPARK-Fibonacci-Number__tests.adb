pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Fibonacci_Number; use Fibonacci_Number;

procedure Tests is
begin
   if Compute (0) /= 0 or else Compute (10) /= 55 or else Compute (32) /= 2_178_309 then
      raise Program_Error;
   end if;
   Put_Line ("Fibonacci Number: PASS");
end Tests;
