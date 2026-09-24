with Ada.Text_IO; use Ada.Text_IO;
with Least_Common_Multiple; use Least_Common_Multiple;

procedure Tests is
begin
   pragma Assert (LCM (12, 18) = 36);
   pragma Assert (LCM (21, 6) = 42);
   Put_Line ("LCM checks passed");
end Tests;
