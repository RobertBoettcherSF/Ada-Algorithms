pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with LCS;
procedure Tests is
   A : constant LCS.Char_Array := ('A', 'G', 'G', 'T', 'A', 'B');
   B : constant LCS.Char_Array := ('G', 'X', 'T', 'X', 'A', 'Y', 'B');
begin
   Assert (LCS.Length (A, B) = 4);
   Assert (LCS.Length (A, A) = A'Length);
   Put_Line ("PASS LCS.Length");
   Put_Line ("All LCS SPARK topic tests passed.");
end Tests;
