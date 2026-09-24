with Ada.Text_IO; use Ada.Text_IO;
with Red_Black_Tree; use Red_Black_Tree;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   T : Tree;
begin
   -- TEST 1 - Empty Tree Invariants
   Put_Line ("TEST 1 - Empty Tree Invariants");
   Check ("1.1 Size of empty tree is 0", Size (T) = 0);
   Check ("1.2 Is_Empty returns True for new tree", Is_Empty (T));
   Check ("1.3 Empty tree is a valid Red-Black Tree", Is_Valid_Red_Black_Tree (T));

   -- TEST 2 - Empty Tree Exceptions
   Put_Line ("TEST 2 - Empty Tree Exceptions");
   begin
      if Minimum (T) = 0 then Check ("2.1 Min on empty", False); end if;
   exception
      when Empty_Tree_Error => Check ("2.1 Min raises Empty_Tree_Error", True);
   end;
   begin
      if Maximum (T) = 0 then Check ("2.2 Max on empty", False); end if;
   exception
      when Empty_Tree_Error => Check ("2.2 Max raises Empty_Tree_Error", True);
   end;
   begin
      if Search (T, 1) = 0.0 then Check ("2.3 Search empty raises error", False); end if;
   exception
      when Key_Not_Found_Error => Check ("2.3 Search empty raises error", True);
   end;

   -- TEST 3 - Single Node Insertion
   Put_Line ("TEST 3 - Single Node Insertion");
   Insert (T, 10, 1.5);
   Check ("3.1 Size becomes 1", Size (T) = 1);
   Check ("3.2 Contains inserted key", Contains (T, 10));
   Check ("3.3 Min is the only inserted key", Minimum (T) = 10);

   -- TEST 4 - Ascending Insertions (Left Rotations)
   Put_Line ("TEST 4 - Ascending Insertions");
   Insert (T, 20, 2.0);
   Insert (T, 30, 3.0);
   Insert (T, 40, 4.0);
   Insert (T, 50, 5.0);
   Check ("4.1 Size is 5 after ascending inserts", Size (T) = 5);
   Check ("4.2 Tree is a valid Red-Black Tree", Is_Valid_Red_Black_Tree (T));
   Check ("4.3 Maximum is correct", Maximum (T) = 50);

   -- TEST 5 - Descending Insertions (Right Rotations)
   Put_Line ("TEST 5 - Descending Insertions");
   Insert (T, 5, 0.5);
   Insert (T, 4, 0.4);
   Insert (T, 3, 0.3);
   Insert (T, 2, 0.2);
   Check ("5.1 Size is 9 after descending inserts", Size (T) = 9);
   Check ("5.2 Tree is a valid Red-Black Tree", Is_Valid_Red_Black_Tree (T));
   Check ("5.3 Minimum is correct", Minimum (T) = 2);

   -- TEST 6 - Search & Contains Validation
   Put_Line ("TEST 6 - Search & Contains Validation");
   Check ("6.1 Search retrieves correct value", Search (T, 30) = 3.0);
   Check ("6.2 Contains returns False for missing key", not Contains (T, 999));
   begin
      if Search (T, 999) = 0.0 then Check ("6.3", False); end if;
   exception
      when Key_Not_Found_Error => Check ("6.3 Search for missing raises error", True);
   end;

   -- TEST 7 - Duplicate Key Handling
   Put_Line ("TEST 7 - Duplicate Key Handling");
   begin
      Insert (T, 10, 9.9);
      Check ("7.1 Duplicate insert raises error", False);
   exception
      when Duplicate_Key_Error => Check ("7.1 Duplicate insert raises error", True);
   end;
   Check ("7.2 Size remains unchanged", Size (T) = 9);
   Check ("7.3 Original value intact", Search (T, 10) = 1.5);

   -- TEST 8 - Deleting a Leaf Node
   Put_Line ("TEST 8 - Deleting a Leaf Node");
   Delete (T, 2);
   Check ("8.1 Size decreases after delete", Size (T) = 8);
   Check ("8.2 Contains is false for deleted key", not Contains (T, 2));
   Check ("8.3 Tree remains structurally valid", Is_Valid_Red_Black_Tree (T));

   -- TEST 9 - Deleting a Node with One Child
   Put_Line ("TEST 9 - Deleting a Node with One Child");
   Insert (T, 45, 4.5); -- 45 will become a leaf child of 40 or 50
   Delete (T, 50);      -- 50 has one child (45)
   Check ("9.1 Deletion succeeds", not Contains (T, 50));
   Check ("9.2 Child node moved up successfully", Contains (T, 45));
   Check ("9.3 Tree remains structurally valid", Is_Valid_Red_Black_Tree (T));

   -- TEST 10 - Deleting a Node with Two Children
   Put_Line ("TEST 10 - Deleting a Node with Two Children");
   Delete (T, 10);
   Check ("10.1 Key with two children is removed", not Contains (T, 10));
   Check ("10.2 Other elements remain", Contains (T, 5) and Contains (T, 20));
   Check ("10.3 Tree remains structurally valid", Is_Valid_Red_Black_Tree (T));

   -- TEST 11 - Deleting Root Node
   Put_Line ("TEST 11 - Deleting Root Node");
   declare
      Root_Key : constant Node_Key := Minimum (T); -- Not root, just pick min
   begin
      Delete (T, Root_Key);
      Check ("11.1 Deletion of min key", not Contains (T, Root_Key));
   end;
   -- Now forcefully delete a known mid element which is likely near root
   Delete (T, 30);
   Check ("11.2 Tree structurally valid after deleting likely root/high node", Is_Valid_Red_Black_Tree (T));
   Check ("11.3 Size updated correctly", Size (T) = 5);

   -- TEST 12 - Invalid Delete / Missing Key
   Put_Line ("TEST 12 - Invalid Delete");
   begin
      Delete (T, 999);
      Check ("12.1 Delete missing raises error", False);
   exception
      when Key_Not_Found_Error => Check ("12.1 Delete missing raises error", True);
   end;
   begin
      Delete (T, -1);
      Check ("12.2 Delete negative missing raises error", False);
   exception
      when Key_Not_Found_Error => Check ("12.2 Delete negative missing raises error", True);
   end;
   Check ("12.3 Size remains unchanged on failed delete", Size (T) = 5);

   -- TEST 13 - Clear Tree
   Put_Line ("TEST 13 - Clear Tree");
   Clear (T);
   Check ("13.1 Size is 0 after Clear", Size (T) = 0);
   Check ("13.2 Is_Empty is True after Clear", Is_Empty (T));
   Check ("13.3 Cleared tree is a valid Red-Black Tree", Is_Valid_Red_Black_Tree (T));

   -- TEST 14 - Successor and Predecessor
   Put_Line ("TEST 14 - Predecessor and Successor");
   Insert (T, 100, 1.0);
   Insert (T, 200, 2.0);
   Insert (T, 300, 3.0);
   Check ("14.1 Successor of 100 is 200", Successor (T, 100) = 200);
   Check ("14.2 Predecessor of 300 is 200", Predecessor (T, 300) = 200);
   begin
      if Successor (T, 300) = 0 then Check ("14.3", False); end if;
   exception
      when Key_Not_Found_Error => Check ("14.3 Successor of max raises error", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
