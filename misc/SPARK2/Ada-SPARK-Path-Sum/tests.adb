pragma Ada_2022;
pragma SPARK_Mode (Off);
with Ada.Text_IO; use Ada.Text_IO;
with Path_Sum; use Path_Sum;
with Own_Checks;
procedure Tests is
   T : Tree := Empty;
   --  Hand-worked (agent A3): a right-only chain 1 -> 2 -> 3 with values
   --  10, -20, 30 has the single leaf sum 20; its prefixes 10 and -10 are
   --  not leaf sums. A lone unused node is not a tree.
   C : Tree := Empty;
begin
   Set_Node (T, 1, 5, 2, 3);
   Set_Node (T, 2, 4, 4, 5);
   Set_Node (T, 3, 8, 0, 6);
   Set_Node (T, 4, 11, 0, 0);
   Set_Node (T, 5, 2, 0, 0);
   Set_Node (T, 6, 1, 0, 0);
   if not Has_Path_Sum (T, 1, 20) or else
     Has_Path_Sum (T, 1, 99) then
      raise Program_Error;
   end if;
   --  Leaf sums of T: 5+4+11 = 20, 5+4+2 = 11, 5+8+1 = 14; 17 = 5+4+8 is
   --  not a path, and 9 = 5+4 stops at an inner node.
   if not Has_Path_Sum (T, 1, 11) or else not Has_Path_Sum (T, 1, 14)
     or else Has_Path_Sum (T, 1, 9) or else Has_Path_Sum (T, 1, 13)
     or else not Has_Path_Sum (T, 3, 9) or else not Has_Path_Sum (T, 6, 1)
   then
      raise Program_Error with "leaf sums of T";
   end if;
   Set_Node (C, 1, 10, 0, 2);
   Set_Node (C, 2, -20, 0, 3);
   Set_Node (C, 3, 30, 0, 0);
   if not Has_Path_Sum (C, 1, 20) or else Has_Path_Sum (C, 1, 10)
     or else Has_Path_Sum (C, 1, -10) or else Has_Path_Sum (C, 7, 0)
     or else Has_Path_Sum (C, 0, 0)
   then
      raise Program_Error with "right chain";
   end if;
   Own_Checks;
   Put_Line ("Path Sum: PASS");
end Tests;
