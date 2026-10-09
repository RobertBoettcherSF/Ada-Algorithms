pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Sorted_Array_To_BST; use Sorted_Array_To_BST;
with Own_Checks;

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

   --  Empty tree.
   Build (T, [others => 5], 0);
   Check (Is_BST (T) and then Height (T) = 0 and then Root_Value (T) = 0
          and then not Contains (T, 5), "empty");

   --  One node; two nodes put the first at the root (1 + (2 - 1) / 2 = 1).
   Build (T, [1 => -7, others => 0], 1);
   Check (Height (T) = 1 and then Root_Value (T) = -7 and then Is_BST (T)
          and then Contains (T, -7) and then not Contains (T, 0), "one");
   Build (T, [1 => 3, 2 => 9, others => 0], 2);
   Check (Height (T) = 2 and then Root_Value (T) = 3 and then Is_BST (T)
          and then Contains (T, 9) and then not Contains (T, 4), "two");

   --  Equal values are not a BST.
   Build (T, [1 => 4, 2 => 4, others => 0], 2);
   Check (not Is_BST (T), "4 4 is not a BST");

   --  15 values fill four levels; 16 need a fifth; 31 fill five.
   declare
      A : Value_Array := [others => 0];
   begin
      for I in 1 .. 31 loop
         A (I) := 10 * I;
      end loop;
      Build (T, A, 15);
      Check (Height (T) = 4 and then Root_Value (T) = 80 and then Is_BST (T),
             "15 values");
      Build (T, A, 16);
      Check (Height (T) = 5 and then Root_Value (T) = 80 and then Is_BST (T),
             "16 values");
      Build (T, A, 31);
      Check (Height (T) = 5 and then Root_Value (T) = 160 and then Is_BST (T)
             and then Contains (T, 10) and then Contains (T, 310)
             and then not Contains (T, 155), "31 values");
      --  Swap the last two values: the in-order sequence ends 310, 300,
      --  so the tree is no longer a BST.
      A (31) := 300;
      A (30) := 310;
      Build (T, A, 31);
      Check (not Is_BST (T), "310 before 300 is not a BST");
   end;

   --  The extreme values -1000 and 1000 are ordinary keys.
   Build (T, [1 => -1000, 2 => 0, 3 => 1000, others => 0], 3);
   Check (Is_BST (T) and then Root_Value (T) = 0
          and then Contains (T, -1000) and then Contains (T, 1000), "-1000 0 1000");
   Build (T, [1 => 1000, others => 0], 1);
   Check (Is_BST (T), "1000 alone");
   Build (T, [1 => -1000, others => 0], 1);
   Check (Is_BST (T), "-1000 alone");

   Own_Checks;
   Put_Line ("sorted array to BST: PASS");
end Tests;
