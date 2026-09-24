pragma Ada_2022;
with Damerau_Levenshtein_Distance;
use Damerau_Levenshtein_Distance;
procedure Tests is
   A : constant Char_Array := "CA";
   B : constant Char_Array := "AC";
   C : constant Char_Array := "book";
   D : constant Char_Array := "back";
begin
   pragma Assert (Distance (A, B) = 1);
   pragma Assert (Distance (C, D) = 2);
end Tests;
