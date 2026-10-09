pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Sorted_Array_To_BST; use Sorted_Array_To_BST;

procedure Tests is
   procedure Check (Condition : Boolean; Name : String) is
   begin
      if not Condition then
         Put_Line ("FAIL " & Name);
         raise Program_Error with Name;
      end if;
   end Check;

   T : Tree := Empty;
begin
   --  1 .. 7: root is the middle element 4.
   Build (T, [1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5, 6 => 6, 7 => 7,
              others => 0], 7);
   Check (Root_Value (T) = 4, "1 .. 7 root");
   Check (Is_BST (T), "1 .. 7 is a BST");

   --  Unsorted input 1 2 5 4 6 7 8: the root is 4 and its left child 2 has
   --  right child 5. Every parent/child pair is ordered, but 5 sits in the
   --  left subtree of 4, so the result is not a binary search tree.
   Build (T, [1 => 1, 2 => 2, 3 => 5, 4 => 4, 5 => 6, 6 => 7, 7 => 8,
              others => 0], 7);
   Check (Root_Value (T) = 4, "1 2 5 4 6 7 8 root");
   Check (not Is_BST (T), "1 2 5 4 6 7 8 is not a BST");

   Put_Line ("sorted array to BST: PASS");
end Tests;
