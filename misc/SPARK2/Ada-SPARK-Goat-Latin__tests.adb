with Ada.Assertions; use Ada.Assertions;
with Goat_Latin; use Goat_Latin;
procedure Tests is
   Input : Text := (others => ' ');
   Result : Score_Type;
begin
   Input (1 .. 12) := "I speak Goat";
   Goat_Length (Input, 12, Result);
   Assert (Result = 24);
   Goat_Length (Input, 0, Result);
   Assert (Result = 0);
end Tests;
