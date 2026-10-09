pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Validate_Binary_Search_Tree; use Validate_Binary_Search_Tree;
with Own_Checks;
procedure Tests is
   T : Tree := Empty; U : Tree := Empty;
begin
   Set_Node (T, 1, 5, 2, 3); Set_Node (T, 2, 3, 0, 0); Set_Node (T, 3, 7, 0, 0);
   Set_Node (U, 1, 5, 2, 3); Set_Node (U, 2, 8, 0, 0); Set_Node (U, 3, 7, 0, 0);
   if not Is_Valid_BST (T, 1) or else Is_Valid_BST (U, 1) then raise Program_Error; end if;
   --  Links that are not a tree are not a valid BST (V&V sweep, agent A3):
   --  a self-loop, a cycle back to the root, a child shared by two
   --  parents, the same child on both sides.
   declare
      X : Tree;
   begin
      X := Empty;
      Set_Node (X, 1, 5, 1, 0);
      if Is_Valid_BST (X, 1) then raise Program_Error with "self-loop"; end if;
      X := Empty;
      Set_Node (X, 1, 50, 0, 2); Set_Node (X, 2, 60, 0, 3); Set_Node (X, 3, 70, 1, 0);
      if Is_Valid_BST (X, 1) then raise Program_Error with "cycle"; end if;
      X := Empty;
      Set_Node (X, 1, 50, 2, 3); Set_Node (X, 2, 20, 0, 4); Set_Node (X, 3, 80, 4, 0);
      Set_Node (X, 4, 40, 0, 0);
      if Is_Valid_BST (X, 1) then raise Program_Error with "shared child"; end if;
      X := Empty;
      Set_Node (X, 1, 50, 2, 2); Set_Node (X, 2, 40, 0, 0);
      if Is_Valid_BST (X, 1) then raise Program_Error with "same child twice"; end if;
      --  A 15-node right chain -98, -84, .., 98 is valid; it fails when the
      --  last value drops below the first.
      X := Empty;
      for I in 1 .. 15 loop
         Set_Node (X, I, -112 + 14 * I, 0, (if I < 15 then I + 1 else 0));
      end loop;
      if not Is_Valid_BST (X, 1) then raise Program_Error with "15-node chain"; end if;
      Set_Node (X, 15, -99, 0, 0);
      if Is_Valid_BST (X, 1) then raise Program_Error with "15-node chain, bad last"; end if;
   end;

   Put_Line ("Validate BST: PASS");
   Own_Checks;
end Tests;
