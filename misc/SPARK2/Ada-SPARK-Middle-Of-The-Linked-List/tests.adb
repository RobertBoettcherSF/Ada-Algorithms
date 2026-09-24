pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Middle_Of_The_Linked_List; use Middle_Of_The_Linked_List;

procedure Tests is
   L : List := Empty;
begin
   Append (L, 10); Append (L, 20); Append (L, 30); Append (L, 40); Append (L, 50);
   if Middle (L) /= 30 then raise Program_Error; end if;
   Put_Line ("Middle of linked list: PASS");
end Tests;
