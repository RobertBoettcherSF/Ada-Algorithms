pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Insert_Into_A_Binary_Search_Tree; use Insert_Into_A_Binary_Search_Tree;

procedure Tests is
   T : Tree := Empty;
   Root : Index := 0;

   --  Search from Root by the BST rule (at most 16 steps).
   function Reachable (V : Value) return Boolean is
      Current : Index := Root;
   begin
      for Step in 1 .. 16 loop
         exit when Current = 0;
         if Value_Of (T, Current) = V then
            return True;
         elsif V < Value_Of (T, Current) then
            Current := Left_Of (T, Current);
         else
            Current := Right_Of (T, Current);
         end if;
      end loop;
      return False;
   end Reachable;

begin
   Insert (T, Root, 1, 8); Insert (T, Root, 2, 4); Insert (T, Root, 3, 12);
   if Root /= 1 then
      raise Program_Error;
   end if;
   --  Every inserted value must be found from the root, and the three
   --  nodes must form 8 (4, 12).
   if not (Reachable (8) and then Reachable (4) and then Reachable (12))
     or else Left_Of (T, 1) /= 2 or else Right_Of (T, 1) /= 3
     or else Left_Of (T, 2) /= 0 or else Right_Of (T, 2) /= 0
     or else Left_Of (T, 3) /= 0 or else Right_Of (T, 3) /= 0
   then
      Put_Line ("Insert_Into_A_Binary_Search_Tree: FAIL (tree after 8, 4, 12:"
                & " left (1) =" & Left_Of (T, 1)'Image
                & ", right (1) =" & Right_Of (T, 1)'Image & ")");
      raise Program_Error;
   end if;
   Put_Line ("Insert_Into_A_Binary_Search_Tree: PASS");
end Tests;
