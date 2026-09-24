pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Accounts_Merge_Lite; use Accounts_Merge_Lite;
procedure Tests is
   O : Owner_Array := (1 => 1, 2 => 2, 3 => 1, 4 => 3, others => 4);
begin
   Assert (Merge_Count (4, O) = 3);
   Put_Line ("PASS Accounts Merge Lite");
end Tests;
