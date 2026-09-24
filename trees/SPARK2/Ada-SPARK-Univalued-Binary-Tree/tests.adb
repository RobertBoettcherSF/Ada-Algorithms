pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Univalued_Binary_Tree; use Univalued_Binary_Tree;
procedure Tests is
   Uniform : constant Tree := (others => 7);
   Mixed : Tree := Uniform;
begin
   Mixed (9) := 8;
   Assert (Is_Univalued (Uniform));
   Assert (not Is_Univalued (Mixed));
   Put_Line ("PASS Univalued_Binary_Tree");
end Tests;
