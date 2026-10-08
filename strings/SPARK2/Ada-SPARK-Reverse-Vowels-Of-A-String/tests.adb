with Reverse_Vowels_Of_A_String;
with Own_Checks;
use type Reverse_Vowels_Of_A_String.Text_Array;
procedure Tests is
   Input : constant Reverse_Vowels_Of_A_String.Text_Array := "xebcid";
   Expected : constant Reverse_Vowels_Of_A_String.Text_Array := "xibced";
begin
   pragma Assert (Reverse_Vowels_Of_A_String.Reverse_Vowels (Input) = Expected);
   Own_Checks;
end Tests;
