with Ada.Assertions; use Ada.Assertions;
with Defanging_IP; use Defanging_IP;
procedure Tests is
   Input : Text := [others => ' '];
   Output : Text;
   Length : Length_Type;
begin
   Input (1 .. 7) := "1.1.1.1";
   Defang (Input, 7, Output, Length);
   Assert (Length = 13 and then Output (1 .. 13) = "1[.]1[.]1[.]1");
end Tests;
