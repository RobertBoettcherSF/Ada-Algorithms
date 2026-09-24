with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with First_Bad_Version; use First_Bad_Version;

procedure Tests is
   V : constant Version_Array := [Good, Good, Good, Bad, Bad, Bad, Bad, Bad];
begin
   Assert (First_Bad (V) = 4);
   Put_Line ("PASS First_Bad_Version");
end Tests;
