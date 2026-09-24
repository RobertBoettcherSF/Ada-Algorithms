with Ada.Assertions; use Ada.Assertions;
with Reverse_Vowels; use Reverse_Vowels;
procedure Tests is
   Input : Text := [others => ' '];
   Output : Text;
   Length : Length_Type;
begin
   Input (1 .. 7) := "hello!" & "x";
   Reverse_Vowels.Reverse_Vowels (Input, 7, Output, Length);
   Assert (Length = 7);
   Assert (Output (1 .. 7) = "holle!x");
end Tests;
