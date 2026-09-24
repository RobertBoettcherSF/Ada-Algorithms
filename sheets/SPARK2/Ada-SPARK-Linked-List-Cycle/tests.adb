pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Linked_List_Cycle; use Linked_List_Cycle;

procedure Tests is
   L : List := Empty; A : List := Empty;
begin
   Set_Next (L, 1, 2); Set_Next (L, 2, 3); Set_Next (L, 3, 2); Set_Next (A, 1, 2); Set_Next (A, 2, 0);
   if not Has_Cycle (L, 1) or else Has_Cycle (A, 1) then raise Program_Error; end if;
   Put_Line ("Linked list cycle: PASS");
end Tests;
