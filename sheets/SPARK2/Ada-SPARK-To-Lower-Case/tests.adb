with Ada.Assertions; use Ada.Assertions;
with To_Lower_Case; use To_Lower_Case;
procedure Tests is
   Input  : Text := [others => ' '];
   Output : Text;
begin
   Input (1 .. 12) := "Hello WORLD!";
   Lower_Case (Input, 12, Output);
   Assert (Output (1 .. 12) = "hello world!");
end Tests;
