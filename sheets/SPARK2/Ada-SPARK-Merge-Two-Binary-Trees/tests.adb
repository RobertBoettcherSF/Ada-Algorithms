pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Merge_Two_Binary_Trees; use Merge_Two_Binary_Trees;
procedure Tests is
   A : Tree := Empty; B : Tree := Empty; C : Tree;
begin
   Set_Node (A, 1, 1, 2, 0); Set_Node (A, 2, 2, 0, 0);
   Set_Node (B, 1, 3, 0, 3); Set_Node (B, 3, 4, 0, 0);
   C := Merge (A, B);
   if Value_At (C, 1) /= 4 or else Left_Child (C, 1) /= 2
     or else Right_Child (C, 1) /= 3 then raise Program_Error; end if;
   Put_Line ("Merge binary trees: PASS");
end Tests;
