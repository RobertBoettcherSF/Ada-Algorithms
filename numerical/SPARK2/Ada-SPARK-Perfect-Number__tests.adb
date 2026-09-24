with Ada.Assertions; use Ada.Assertions;
with Perfect_Number; use Perfect_Number;

procedure Tests is
begin
   Assert (Is_Perfect (6));
   Assert (Is_Perfect (28));
   Assert (Is_Perfect (496));
   Assert (Is_Perfect (8_128));
   Assert (Is_Perfect (33_550_336));
   Assert (not Is_Perfect (1));
   Assert (not Is_Perfect (100));
end Tests;
