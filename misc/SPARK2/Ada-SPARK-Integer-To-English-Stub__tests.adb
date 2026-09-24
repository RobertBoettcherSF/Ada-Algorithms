with Ada.Assertions; use Ada.Assertions;
with Integer_To_English; use Integer_To_English;
procedure Tests is
begin
   Assert (To_English (0) = Zero);
   Assert (To_English (7) = Seven);
   Assert (To_English (13) = Thirteen);
   Assert (To_English (19) = Nineteen);
end Tests;
