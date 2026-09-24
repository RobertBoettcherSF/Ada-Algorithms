pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with KMP; use KMP;
procedure Tests is
   Pat : constant Char_Array := ('A', 'A', 'B');
   Pi  : Prefix_Table (1 .. 3);
begin
   Build_Prefix (Pat, Pi);
   Assert (Pi (1) = 0);
   Assert (Pi (2) = 1);
   Assert (Pi (3) = 0);
   Put_Line ("PASS KMP.Build_Prefix");
   Put_Line ("All KMP SPARK topic tests passed.");
end Tests;
