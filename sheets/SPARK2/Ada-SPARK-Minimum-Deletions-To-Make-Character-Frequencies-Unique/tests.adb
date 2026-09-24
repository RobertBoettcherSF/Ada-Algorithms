pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Minimum_Deletions_To_Make_Character_Frequencies_Unique; use Minimum_Deletions_To_Make_Character_Frequencies_Unique;
procedure Tests is
begin
   pragma Assert (Minimum_Deletions (9, 5) = 4);
   pragma Assert (Minimum_Deletions (3, 5) = 0);
   Put_Line ("PASS Ada-SPARK-Minimum-Deletions-To-Make-Character-Frequencies-Unique");
end Tests;
