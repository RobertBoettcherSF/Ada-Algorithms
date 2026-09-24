with Ada.Assertions; use Ada.Assertions;
with Pangram; use Pangram;
procedure Tests is
   Input : Text := [others => ' '];
begin
   Input (1 .. 26) := "abcdefghijklmnopqrstuvwxyz";
   Assert (Is_Pangram (Input, 26));
   Input (26) := 'x';
   Input (1) := 'a';
   Assert (not Is_Pangram (Input, 25));
end Tests;
