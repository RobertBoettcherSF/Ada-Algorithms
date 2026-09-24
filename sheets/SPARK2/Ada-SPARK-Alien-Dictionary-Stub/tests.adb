pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Alien_Dictionary_Stub; use Alien_Dictionary_Stub;

procedure Tests is
   Words : constant Word_Array :=
     (1 => ('w', 'r', 't'),
      2 => ('w', 'r', 'f'),
      3 => ('e', 'r', 'f'));
begin
   if not Is_Valid (Words) then raise Program_Error; end if;
   Put_Line ("Alien dictionary stub: PASS");
end Tests;
