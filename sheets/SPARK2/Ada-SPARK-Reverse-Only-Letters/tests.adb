with Ada.Assertions; use Ada.Assertions;
with Reverse_Only_Letters; use Reverse_Only_Letters;
procedure Tests is
   Input  : Text := [others => ' '];
   Output : Text;
begin
   Input (1 .. 6) := "a-bC-d";
   Reverse_Letters (Input, 6, Output);
   Assert (Output (1 .. 6) = "d-Cb-a");
   Input (1 .. 4) := "-abc";
   Reverse_Letters (Input, 4, Output);
   Assert (Output (1 .. 4) = "-cba");
end Tests;
