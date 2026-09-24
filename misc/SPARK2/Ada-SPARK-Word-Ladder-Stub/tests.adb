pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Word_Ladder_Stub; use Word_Ladder_Stub;

procedure Tests is
   Start_Word : constant Word := ('c', 'o', 'g');
   End_Word   : constant Word := ('d', 'o', 'g');
   Dictionary : constant Word_Array :=
     (1 => ('c', 'o', 'g'),
      2 => ('c', 'o', 't'),
      3 => ('c', 'o', 't'),
      4 => ('d', 'o', 't'),
      5 => ('d', 'o', 'g'));
begin
   if Distance (Start_Word, End_Word, Dictionary) /= 5 then raise Program_Error; end if;
   Put_Line ("Word ladder stub: PASS");
end Tests;
