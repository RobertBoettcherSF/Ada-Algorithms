pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Naive_String_Search; use Naive_String_Search;
procedure Tests is
   Text : constant Text_Array := "THE QUICK BROWNX";
   Pattern : constant Pattern_Array := "BROW";
   Missing : constant Pattern_Array := "ZZZZ";
begin
   Assert (Search (Text, Pattern) = 11);
   Assert (Search (Text, Missing) = 0);
   Put_Line ("PASS Naive_String_Search");
end Tests;
