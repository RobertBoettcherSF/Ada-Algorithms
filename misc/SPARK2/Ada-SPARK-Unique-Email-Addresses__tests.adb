with Ada.Assertions; use Ada.Assertions;
with Unique_Emails; use Unique_Emails;
procedure Tests is
   Input  : Text := [others => ' '];
   Output : Text;
   Length : Length_Type;
begin
   Input (1 .. 21) := "test.email+tag@ex.com";
   Normalize (Input, 21, Output, Length);
   Assert (Length = 16 and then Output (1 .. 16) = "testemail@ex.com");
end Tests;
