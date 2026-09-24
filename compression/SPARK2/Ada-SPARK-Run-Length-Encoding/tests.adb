pragma Ada_2022;
with Run_Length_Encoding;
procedure Tests is
   use Run_Length_Encoding;
   A : constant Char_Array := "aaabbc";
   B : constant Char_Array := "zzzz";
   C : constant Char_Array := "abcd";
begin
   pragma Assert (Number_Of_Runs (A) = 3);
   pragma Assert (Number_Of_Runs (B) = 1);
   pragma Assert (Number_Of_Runs (C) = 4);
end Tests;
