-- tests.adb
with Ada.Text_IO;       use Ada.Text_IO;
with Block_Nested_Loop; use Block_Nested_Loop;

procedure Tests is
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      end if;
      Put_Line ("      PASS: " & Message);
   end Assert;

   -- Test Data Setup
   Empty_R : constant Table_R (1 .. 0) := (others => (Key => 0, Data => 0));
   Empty_S : constant Table_S (1 .. 0) := (others => (Key => 0, Data => 0));

   Basic_R : constant Table_R := (1 => (1, 10), 2 => (2, 20), 3 => (3, 30));
   Basic_S : constant Table_S := (1 => (2, 200), 2 => (3, 300), 3 => (4, 400));
   
   Disjoint_R : constant Table_R := (1 => (1, 10));
   Disjoint_S : constant Table_S := (1 => (2, 20));

   -- Data for testing duplicate behaviors
   Dup_R          : constant Table_R := (1 => (1, 10), 2 => (1, 11));
   Dup_S          : constant Table_S := (1 => (1, 100), 2 => (1, 101));
   Single_Match_R : constant Table_R := (1 => (1, 10));
   Single_Match_S : constant Table_S := (1 => (1, 100));

begin
   Put_Line ("========================================");
   Put_Line ("Running Block Nested Loop Join Tests...");
   Put_Line ("========================================");

   Put_Line ("TEST 1 - Naive Nested Loop Correctness");
   declare
      Res : constant Joined_Table := Nested_Loop_Join (Basic_R, Basic_S);
   begin
      Assert (Res'Length = 2, "1.1 Length is exactly 2 matches");
      Assert (Res(1).Key = 2 and Res(2).Key = 3, "1.2 Keys matched correctly");
   end;

   Put_Line ("TEST 2 - Block Nested Loop Correctness (Block=2)");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Basic_R, Basic_S, 2);
   begin
      Assert (Res'Length = 2, "2.1 Length is exactly 2 matches");
      Assert (Res(1).Key = 2, "2.2 First match is correct");
   end;

   Put_Line ("TEST 3 - Empty Outer Relation (R)");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Empty_R, Basic_S, 2);
   begin
      Assert (Res'Length = 0, "3.1 Length is 0");
   end;

   Put_Line ("TEST 4 - Empty Inner Relation (S)");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Basic_R, Empty_S, 2);
   begin
      Assert (Res'Length = 0, "4.1 Length is 0");
   end;

   Put_Line ("TEST 5 - Both Relations Empty");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Empty_R, Empty_S, 2);
   begin
      Assert (Res'Length = 0, "5.1 Length is 0");
   end;

   Put_Line ("TEST 6 - Block Size = Outer Relation Length");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Basic_R, Basic_S, 3);
   begin
      Assert (Res'Length = 2, "6.1 Length is exactly 2 matches");
   end;

   Put_Line ("TEST 7 - Block Size > Outer Relation Length");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Basic_R, Basic_S, 999);
   begin
      Assert (Res'Length = 2, "7.1 Safely handles large block sizes");
   end;

   Put_Line ("TEST 8 - Block Size = 1 (Behaves like NLJ)");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Basic_R, Basic_S, 1);
   begin
      Assert (Res'Length = 2, "8.1 Equivalent logic to single-tuple traversal");
   end;

   Put_Line ("TEST 9 - Disjoint Sets (No matches)");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Disjoint_R, Disjoint_S, 2);
   begin
      Assert (Res'Length = 0, "9.1 Correctly finds 0 matches");
   end;

   Put_Line ("TEST 10 - Cross Join / Identical Keys");
   declare
      Cross_R : constant Table_R := (1 => (1, 10), 2 => (1, 20));
      Cross_S : constant Table_S := (1 => (1, 30), 2 => (1, 40));
      Res : constant Joined_Table := Block_Nested_Loop_Join (Cross_R, Cross_S, 2);
   begin
      Assert (Res'Length = 4, "10.1 Creates full cartesian product (4 rows)");
   end;

   Put_Line ("TEST 11 - Outer Relation Duplicates");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Dup_R, Single_Match_S, 2);
   begin
      Assert (Res'Length = 2, "11.1 Duplicates in outer block successfully map to inner row");
   end;

   Put_Line ("TEST 12 - Inner Relation Duplicates");
   declare
      Res : constant Joined_Table := Block_Nested_Loop_Join (Single_Match_R, Dup_S, 2);
   begin
      Assert (Res'Length = 2, "12.1 Outer row successfully maps to duplicates in inner row");
   end;

   Put_Line ("TEST 13 - Invalid Block Size (0)");
   begin
      declare
         Res : constant Joined_Table := Block_Nested_Loop_Join (Basic_R, Basic_S, 0);
      begin
         Assert (False, "13.1 Exception not raised for size 0");
      end;
   exception
      when Invalid_Block_Size =>
         Assert (True, "13.1 Block size 0 triggers Invalid_Block_Size");
   end;

   Put_Line ("TEST 14 - Negative Block Size");
   begin
      declare
         Res : constant Joined_Table := Block_Nested_Loop_Join (Basic_R, Basic_S, -5);
      begin
         Assert (False, "14.1 Exception not raised for size -5");
      end;
   exception
      when Invalid_Block_Size =>
         Assert (True, "14.1 Negative block size triggers Invalid_Block_Size");
   end;
   
   Put_Line ("========================================");
   Put_Line ("ALL TESTS PASSED SUCCESSFULLY");
end Tests;
