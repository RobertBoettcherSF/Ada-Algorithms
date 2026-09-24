with Ada.Assertions; use Ada.Assertions;
with Remove_Adjacent_Duplicates_II; use Remove_Adjacent_Duplicates_II;
procedure Tests is
   Input : Text := [others => ' '];
   Output : Text;
   Length : Length_Type;
begin
   Input (1 .. 6) := "azxxzy";
   Remove_Duplicates (Input, 6, Output, Length);
   Assert (Length = 2 and then Output (1 .. 2) = "ay");
end Tests;
