pragma SPARK_Mode (On);
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Logger_Rate_Limiter_Stub; use Logger_Rate_Limiter_Stub;

procedure Tests is
begin
   Assert (Allowed (10, 15, 5));
   Assert (not Allowed (10, 14, 5));
   Assert (Allowed (100, 100, 0));
   Put_Line ("Logger Rate Limiter: PASS");
end Tests;
