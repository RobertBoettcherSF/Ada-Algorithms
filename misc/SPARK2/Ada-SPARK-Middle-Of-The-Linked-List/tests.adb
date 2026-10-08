pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Middle_Of_The_Linked_List; use Middle_Of_The_Linked_List;
with Full_Append_Check;
with Own_Checks;

procedure Tests is
   L : List := Empty;
begin
   Append (L, 10); Append (L, 20); Append (L, 30); Append (L, 40); Append (L, 50);
   if Middle (L) /= 30 then raise Program_Error; end if;
   Put_Line ("Middle of linked list: PASS");
   Full_Append_Check;
   Own_Checks;
end Tests;
