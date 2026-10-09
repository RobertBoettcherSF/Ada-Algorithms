pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Subtree_Of_Another_Tree; use Subtree_Of_Another_Tree;
with Own_Checks;
procedure Tests is
   T : Tree := Empty; P : Tree := Empty; Q : Tree := Empty;
begin
   Set_Node (T, 1, 3, 2, 3); Set_Node (T, 2, 4, 0, 0); Set_Node (T, 3, 5, 0, 0);
   Set_Node (P, 1, 3, 2, 3); Set_Node (P, 2, 4, 0, 0); Set_Node (P, 3, 5, 0, 0);
   Set_Node (Q, 1, 6, 0, 0);
   if not Is_Subtree (T, 1, P, 1) or else Is_Subtree (T, 1, Q, 1) then raise Program_Error; end if;
   --  Only nodes under Root count (V&V sweep, agent A3): node 2 (value 7)
   --  is set but not linked from root 1, so a lone 7 is not a subtree of
   --  the tree at 1; it is a subtree of the tree at 2. Likewise node 3 of
   --  T is under root 1 but not under root 2.
   declare
      U : Tree := Empty;
      Seven : Tree := Empty;
   begin
      Set_Node (U, 1, 5, 0, 0);
      Set_Node (U, 2, 7, 0, 0);
      Set_Node (Seven, 1, 7, 0, 0);
      if Is_Subtree (U, 1, Seven, 1) then
         Put_Line ("FAIL Is_Subtree counts node 2, which is not under root 1");
         raise Program_Error with "unreachable candidate";
      end if;
      if not Is_Subtree (U, 2, Seven, 1) then
         raise Program_Error with "subtree at its own root";
      end if;
      Set_Node (Seven, 1, 5, 0, 0);
      if Is_Subtree (T, 2, Seven, 1) or else not Is_Subtree (T, 3, Seven, 1) then
         raise Program_Error with "subtree of a subtree";
      end if;
   end;
   Put_Line ("Subtree check: PASS");
   Own_Checks;
end Tests;
