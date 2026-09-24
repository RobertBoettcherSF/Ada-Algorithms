with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Hash_Join; use Hash_Join;

procedure Tests is
   R_Table, S_Table : Relation_R.Vector; 
   S_Table_Rght     : Relation_S.Vector;
   Result           : Relation_Joined.Vector;

   procedure Reset_Tables is
   begin
      R_Table.Clear;
      S_Table_Rght.Clear;
      Result.Clear;
   end Reset_Tables;

begin
   Put_Line ("Starting Verification & Validation Tests for Hash Join...");
   Put_Line ("===========================================================");

   -- TEST 1 - Classic Hash Join (Normal)
   Put_Line ("TEST 1 - Classic Hash Join (1-to-1 Matches)");
   Reset_Tables;
   R_Table.Append ((Key => 1, Data => To_Unbounded_String("Alice")));
   S_Table_Rght.Append ((Key => 1, Data => To_Unbounded_String("HR")));
   Put_Line ("  1.1 Assert join output length is 1");
   Result := Classic_Hash_Join (R_Table, S_Table_Rght);
   Assert (Natural(Result.Length) = 1, "Length mismatch");
   Put_Line ("  1.2 Assert Key matches");
   Assert (Result.First_Element.Key = 1, "Key mismatch");
   Put_Line ("      PASS");

   -- TEST 2 - Classic Hash Join (Empty R)
   Put_Line ("TEST 2 - Classic Hash Join (Empty Build Relation)");
   Reset_Tables;
   S_Table_Rght.Append ((Key => 1, Data => To_Unbounded_String("HR")));
   Put_Line ("  2.1 Assert Result is empty when R is empty");
   Result := Classic_Hash_Join (R_Table, S_Table_Rght);
   Assert (Result.Is_Empty, "Result should be empty");
   Put_Line ("      PASS");

   -- TEST 3 - Classic Hash Join (Empty S)
   Put_Line ("TEST 3 - Classic Hash Join (Empty Probe Relation)");
   Reset_Tables;
   R_Table.Append ((Key => 1, Data => To_Unbounded_String("Alice")));
   Put_Line ("  3.1 Assert Result is empty when S is empty");
   Result := Classic_Hash_Join (R_Table, S_Table_Rght);
   Assert (Result.Is_Empty, "Result should be empty");
   Put_Line ("      PASS");

   -- TEST 4 - Classic Hash Join (No matches)
   Put_Line ("TEST 4 - Classic Hash Join (Disjoint Keys)");
   Reset_Tables;
   R_Table.Append ((Key => 2, Data => To_Unbounded_String("Bob")));
   S_Table_Rght.Append ((Key => 3, Data => To_Unbounded_String("IT")));
   Put_Line ("  4.1 Assert zero matches found");
   Result := Classic_Hash_Join (R_Table, S_Table_Rght);
   Assert (Result.Is_Empty, "Expected no matches");
   Put_Line ("      PASS");

   -- TEST 5 - Classic Hash Join (1-to-N Matches)
   Put_Line ("TEST 5 - Classic Hash Join (1-to-N Matches)");
   Reset_Tables;
   R_Table.Append ((Key => 5, Data => To_Unbounded_String("Manager")));
   S_Table_Rght.Append ((Key => 5, Data => To_Unbounded_String("ProjA")));
   S_Table_Rght.Append ((Key => 5, Data => To_Unbounded_String("ProjB")));
   Put_Line ("  5.1 Assert two rows generated for single key in R");
   Result := Classic_Hash_Join (R_Table, S_Table_Rght);
   Assert (Natural(Result.Length) = 2, "Length mismatch in 1:N");
   Put_Line ("      PASS");

   -- TEST 6 - Grace Hash Join (Normal)
   Put_Line ("TEST 6 - Grace Hash Join (Standard execution, 3 Partitions)");
   Reset_Tables;
   R_Table.Append ((Key => 10, Data => To_Unbounded_String("R1")));
   R_Table.Append ((Key => 11, Data => To_Unbounded_String("R2")));
   S_Table_Rght.Append ((Key => 10, Data => To_Unbounded_String("S1")));
   S_Table_Rght.Append ((Key => 11, Data => To_Unbounded_String("S2")));
   Put_Line ("  6.1 Assert joins succeed across partitioned space");
   Result := Grace_Hash_Join (R_Table, S_Table_Rght, 3);
   Assert (Natural(Result.Length) = 2, "Grace failed normal join");
   Put_Line ("      PASS");

   -- TEST 7 - Grace Hash Join (Empty Inputs)
   Put_Line ("TEST 7 - Grace Hash Join (Empty inputs)");
   Reset_Tables;
   Put_Line ("  7.1 Assert graceful handling of empty inputs in partitions");
   Result := Grace_Hash_Join (R_Table, S_Table_Rght, 4);
   Assert (Result.Is_Empty, "Expected empty output for Grace");
   Put_Line ("      PASS");

   -- TEST 8 - Grace Hash Join (Invalid Partitions Exception)
   Put_Line ("TEST 8 - Grace Hash Join (Invalid Partition Boundaries)");
   Put_Line ("  8.1 Assert 0 partitions raises Invalid_Partition_Count");
   begin
      Result := Grace_Hash_Join (R_Table, S_Table_Rght, 0);
      Assert (False, "Should have raised exception");
   exception
      when Invalid_Partition_Count =>
         Put_Line ("      PASS");
   end;

   -- TEST 9 - Hybrid Hash Join (Normal)
   Put_Line ("TEST 9 - Hybrid Hash Join (Standard execution)");
   Reset_Tables;
   R_Table.Append ((Key => 4, Data => To_Unbounded_String("Hyb_R1")));
   S_Table_Rght.Append ((Key => 4, Data => To_Unbounded_String("Hyb_S1")));
   Put_Line ("  9.1 Assert Hybrid returns valid tuples");
   Result := Hybrid_Hash_Join (R_Table, S_Table_Rght, 2);
   Assert (Natural(Result.Length) = 1, "Hybrid failed normal join");
   Put_Line ("      PASS");

   -- TEST 10 - Hybrid Hash Join (Partition 0 Match Only)
   Put_Line ("TEST 10 - Hybrid Hash Join (Memory optimization path check)");
   Reset_Tables;
   -- Key 10 mod 5 = 0 (Lands strictly in partition 0)
   R_Table.Append ((Key => 10, Data => To_Unbounded_String("Part0_R")));
   S_Table_Rght.Append ((Key => 10, Data => To_Unbounded_String("Part0_S")));
   Put_Line ("  10.1 Assert Hybrid immediate probe mechanism succeeds");
   Result := Hybrid_Hash_Join (R_Table, S_Table_Rght, 5);
   Assert (Natural(Result.Length) = 1, "Hybrid failed P0 probe");
   Put_Line ("      PASS");

   -- TEST 11 - Hybrid Hash Join (Empty Inputs)
   Put_Line ("TEST 11 - Hybrid Hash Join (Empty Inputs)");
   Reset_Tables;
   Put_Line ("  11.1 Assert Hybrid handles empty safely");
   Result := Hybrid_Hash_Join (R_Table, S_Table_Rght, 3);
   Assert (Result.Is_Empty, "Hybrid empty failed");
   Put_Line ("      PASS");

   -- TEST 12 - Hybrid Hash Join (Invalid Partitions)
   Put_Line ("TEST 12 - Hybrid Hash Join (Invalid Partitions Exception)");
   Put_Line ("  12.1 Assert 0 partitions raises exception in Hybrid");
   begin
      Result := Hybrid_Hash_Join (R_Table, S_Table_Rght, 0);
      Assert (False, "Should have raised exception");
   exception
      when Invalid_Partition_Count =>
         Put_Line ("      PASS");
   end;

   -- TEST 13 - Edge Case: Negative Keys Robustness
   Put_Line ("TEST 13 - Edge Case: Negative Keys");
   Reset_Tables;
   R_Table.Append ((Key => -5, Data => To_Unbounded_String("NegR")));
   S_Table_Rght.Append ((Key => -5, Data => To_Unbounded_String("NegS")));
   Put_Line ("  13.1 Assert Hash Functions and Modulo Operators handle negative integers safely");
   Result := Grace_Hash_Join (R_Table, S_Table_Rght, 3);
   Assert (Natural(Result.Length) = 1, "Failed on negative key");
   Put_Line ("      PASS");

   -- TEST 14 - Edge Case: Large Number of Partitions
   Put_Line ("TEST 14 - Edge Case: Extremely Large Partition Matrix");
   Reset_Tables;
   R_Table.Append ((Key => 1, Data => To_Unbounded_String("A")));
   S_Table_Rght.Append ((Key => 1, Data => To_Unbounded_String("B")));
   Put_Line ("  14.1 Assert Grace allocation handles large N seamlessly");
   Result := Grace_Hash_Join (R_Table, S_Table_Rght, 500);
   Assert (Natural(Result.Length) = 1, "Failed on high partition count");
   Put_Line ("      PASS");

   Put_Line ("===========================================================");
   Put_Line ("ALL VERIFICATION AND VALIDATION TESTS PASSED SUCCESSFULLY.");
end Tests;
