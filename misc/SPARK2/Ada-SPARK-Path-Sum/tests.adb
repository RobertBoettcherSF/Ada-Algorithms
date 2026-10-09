pragma Ada_2022;
pragma SPARK_Mode (Off);
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
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
   --  Links that would not make a tree are rejected by Set_Node's
   --  precondition: a self-loop, a two-node cycle, a three-node cycle, a
   --  child shared by two parents, and the same child on both sides.
   declare
      procedure Rejects (Label : String; Setup : access procedure (X : in out Tree)) is
         X : Tree := Empty;
      begin
         Setup (X);
         Put_Line ("FAIL " & Label & ": Set_Node accepted a link that is not a tree");
         raise Program_Error with Label;
      exception
         when Ada.Assertions.Assertion_Error => null;
      end Rejects;
      procedure Self_Loop (X : in out Tree) is
      begin
         Set_Node (X, 4, 1, 4, 0);
      end Self_Loop;
      procedure Two_Cycle (X : in out Tree) is
      begin
         Set_Node (X, 1, 1, 2, 0);
         Set_Node (X, 2, 1, 0, 1);
      end Two_Cycle;
      procedure Three_Cycle (X : in out Tree) is
      begin
         Set_Node (X, 5, 1, 9, 0);
         Set_Node (X, 9, 1, 0, 2);
         Set_Node (X, 2, 1, 5, 0);
      end Three_Cycle;
      procedure Shared (X : in out Tree) is
      begin
         Set_Node (X, 1, 1, 3, 0);
         Set_Node (X, 2, 1, 0, 3);
      end Shared;
      procedure Both_Sides (X : in out Tree) is
      begin
         Set_Node (X, 1, 1, 3, 3);
      end Both_Sides;
      Y : Tree := Empty;
   begin
      Rejects ("self-loop", Self_Loop'Access);
      Rejects ("two-node cycle", Two_Cycle'Access);
      Rejects ("three-node cycle", Three_Cycle'Access);
      Rejects ("shared child", Shared'Access);
      Rejects ("same child twice", Both_Sides'Access);
      --  Re-setting a node may move its children; children may be set
      --  before their parent, and node numbers need not follow the shape.
      Set_Node (Y, 7, 3, 0, 0);
      Set_Node (Y, 2, 1, 7, 0);
      Set_Node (Y, 2, 1, 0, 7);
      Set_Node (Y, 5, 1, 2, 0);
      if not Has_Path_Sum (Y, 5, 5) or else Left_Child (Y, 2) /= 0
        or else Right_Child (Y, 2) /= 7
      then
         raise Program_Error with "re-set links";
      end if;
   end;

   Own_Checks;
   Put_Line ("Path Sum: PASS");
end Tests;
