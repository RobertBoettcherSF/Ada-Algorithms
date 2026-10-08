with Ada.Assertions; use Ada.Assertions;
with Reverse_Words_In_A_String_III; use Reverse_Words_In_A_String_III;
with Own_Checks;
procedure Tests is
   Input : Text := [others => ' '];
   Output : Text;
   Length : Length_Type;
begin
   Input (1 .. 11) := "hello world";
   Reverse_Words (Input, 11, Output, Length);
   Assert (Length = 11);
   Assert (Output (1 .. 11) = "olleh dlrow");
   Own_Checks;
end Tests;
