pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Remove_All_Adjacent_Duplicates_In_String; use Remove_All_Adjacent_Duplicates_In_String;
procedure Tests is Input : constant Buffer := ['a', 'b', 'b', 'a', others => ' ']; Output : Buffer; N : Length; begin
   Reduce (Input, 4, Output, N); Assert (N = 0); Put_Line ("PASS Remove_All_Adjacent_Duplicates_In_String");
end Tests;
