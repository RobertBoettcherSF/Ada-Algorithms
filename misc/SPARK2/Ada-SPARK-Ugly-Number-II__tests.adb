pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Ugly_Number_II; use Ugly_Number_II;
procedure Tests is
begin
   Assert (Nth_Ugly (1) = 1);
   Assert (Nth_Ugly (10) = 12);
   Assert (Nth_Ugly (20) = 36);
   Put_Line ("PASS Ugly_Number_II");
end Tests;
