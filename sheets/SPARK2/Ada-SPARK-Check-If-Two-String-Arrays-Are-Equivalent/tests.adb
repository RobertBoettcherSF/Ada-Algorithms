with Ada.Assertions; use Ada.Assertions;
with Equivalent_String_Arrays; use Equivalent_String_Arrays;
procedure Tests is
   Left : Text := [others => ' '];
   Right : Text := [others => ' '];
   Other : Text := [others => ' '];
begin
   Left (1 .. 6) := "foobar";
   Right (1 .. 6) := "foobar";
   Other (1 .. 6) := "foobaz";
   Assert (Are_Equivalent (Left, 6, Right, 6));
   Assert (not Are_Equivalent (Left, 6, Other, 6));
end Tests;
