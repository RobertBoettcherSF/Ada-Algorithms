pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Super_Ugly_Number_Stub; use Super_Ugly_Number_Stub;
procedure Tests is
begin
   Assert (Nth_Super_Ugly (1) = 1);
   Assert (Nth_Super_Ugly (6) = 13);
   Assert (Nth_Super_Ugly (12) = 32);
   Put_Line ("PASS Super_Ugly_Number_Stub");
end Tests;
