pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Boyer_Moore; use Boyer_Moore;
procedure Tests is
   Text : constant Text_Array := "THE QUICK BROWNX";
   Pattern : constant Pattern_Array := "QUIC";
   Missing : constant Pattern_Array := "ZZZZ";
begin
   Assert (Search (Text, Pattern) = 5);
   Assert (Search (Text, Missing) = 0);
   Put_Line ("PASS Boyer_Moore");
end Tests;
