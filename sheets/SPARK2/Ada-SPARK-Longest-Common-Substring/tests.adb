pragma Ada_2022;
with Longest_Common_Substring;
use Longest_Common_Substring;
procedure Tests is
   A : constant Char_Array := "abca";
   B : constant Char_Array := "bc";
begin
   pragma Assert (Length (A, B) = 2);
   pragma Assert (Length ("ab", "xy") = 0);
end Tests;
