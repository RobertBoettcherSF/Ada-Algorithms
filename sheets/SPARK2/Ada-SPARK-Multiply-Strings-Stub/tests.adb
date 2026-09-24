with Ada.Assertions; use Ada.Assertions;
with Multiply_Strings; use Multiply_Strings;
procedure Tests is
begin
   Assert (Multiply (0, 9999) = 0);
   Assert (Multiply (12, 34) = 408);
   Assert (Multiply (9999, 9999) = 99_980_001);
end Tests;
