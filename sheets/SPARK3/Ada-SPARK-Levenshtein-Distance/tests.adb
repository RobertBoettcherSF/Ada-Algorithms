pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Levenshtein_Distance; use Levenshtein_Distance;
procedure Tests is
   A : constant Char_Array := ('k', 'i', 't', 't', 'e', 'n');
   B : constant Char_Array := ('s', 'i', 't', 't', 'i', 'n', 'g');
   E : constant Char_Array (1 .. 0) := [];
begin
   Assert (Distance (E, E) = 0);
   Assert (Distance (A, A) = 0);
   Assert (Distance (A, B) = 3);
   Assert (Distance (['a'], ['b']) = 1);
   Put_Line ("PASS Levenshtein_Distance Distance");
   Put_Line ("All Levenshtein_Distance SPARK topic tests passed.");
end Tests;
