pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Manacher; use Manacher;
procedure Tests is
   Text : constant Text_Array := "RACECARX";
   Even : constant Text_Array := "ABCDDCBA";
begin
   Assert (Longest_Palindrome_Length (Text) = 7);
   Assert (Longest_Palindrome_Length (Even) = 8);
   Put_Line ("PASS Manacher");
end Tests;
