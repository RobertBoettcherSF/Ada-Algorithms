with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Exceptions; use Ada.Exceptions;
with Proof_Of_Work; use Proof_Of_Work;

procedure Tests is
   Nonce  : Nonce_Type;
   Hash_R : String (1 .. 64);
   Idx    : Natural;
begin
   Put_Line ("=================================================");
   Put_Line ("Proof-of-Work V&V Testing Suite");
   Put_Line ("Philosophy: Assume code is broken; PASS disproves.");
   Put_Line ("=================================================");

   -- TEST 1 - Hashcash Generation
   Put_Line ("TEST 1 - Hashcash (CPU-Bound) Normal Generation");
   Put_Line ("  1.1 Assume Hashcash cannot produce 1 leading zero");
   begin
      Generate_Hashcash ("Block_1", 1, Nonce, Hash_R);
      Assert (Hash_R (1) = '0', "Hash does not start with 0");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 2 - Hashcash Verification Valid
   Put_Line ("TEST 2 - Hashcash Verification (Positive)");
   Put_Line ("  2.1 Assume valid nonce will be rejected");
   begin
      Assert (Verify_Hashcash ("Block_1", 1, Nonce) = True, "Rejected valid nonce");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 3 - Hashcash Verification Invalid
   Put_Line ("TEST 3 - Hashcash Verification (Negative)");
   Put_Line ("  3.1 Assume modified data allows verification bypass");
   begin
      Assert (Verify_Hashcash ("Block_2_Forged", 1, Nonce) = False, "Accepted forged data");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 4 - Hashcash Empty String Edge Case
   Put_Line ("TEST 4 - Hashcash Empty String Input");
   Put_Line ("  4.1 Assume empty string crashes generator");
   begin
      Generate_Hashcash ("", 1, Nonce, Hash_R);
      Assert (Verify_Hashcash ("", 1, Nonce), "Empty string verification failed");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 5 - Hashcash Zero Difficulty Edge Case
   Put_Line ("TEST 5 - Hashcash Zero Difficulty");
   Put_Line ("  5.1 Assume difficulty 0 causes infinite loop or crash");
   begin
      Generate_Hashcash ("Test", 0, Nonce, Hash_R);
      Assert (Nonce = 0, "Zero difficulty did not return immediately with Nonce=0");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 6 - Hash Chain Generation
   Put_Line ("TEST 6 - Hash Chain (Time-Bound) Execution");
   Put_Line ("  6.1 Assume Hash Chain fails on 10 iterations");
   begin
      Generate_Hash_Chain ("SeedValue", 10, Hash_R);
      Assert (Hash_R'Length = 64, "Resulting Hash is invalid length");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 7 - Hash Chain Verify Valid
   Put_Line ("TEST 7 - Hash Chain Verification (Positive)");
   Put_Line ("  7.1 Assume valid hash chain is rejected");
   begin
      Assert (Verify_Hash_Chain ("SeedValue", 10, Hash_R), "Valid hash chain rejected");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 8 - Hash Chain Verify Invalid
   Put_Line ("TEST 8 - Hash Chain Verification (Negative)");
   Put_Line ("  8.1 Assume verifying wrong iterations bypasses check");
   begin
      Assert (Verify_Hash_Chain ("SeedValue", 11, Hash_R) = False, "Bypassed with wrong iterations");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 9 - Hash Chain Edge Case Size 1
   Put_Line ("TEST 9 - Hash Chain 1 Iteration Edge Case");
   Put_Line ("  9.1 Assume single iteration crashes");
   begin
      Generate_Hash_Chain ("Single", 1, Hash_R);
      Assert (Verify_Hash_Chain ("Single", 1, Hash_R), "1 iteration failed");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 10 - Memory Puzzle Generation
   Put_Line ("TEST 10 - Memory Puzzle (Space-Bound)");
   Put_Line ("  10.1 Assume memory puzzle cannot find target 'a' in pool of 500");
   begin
      Solve_Memory_Puzzle ("MemSeed", 500, 'a', Idx);
      Assert (Idx > 0 and Idx <= 500, "Found index out of bounds");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 11 - Memory Puzzle Valid
   Put_Line ("TEST 11 - Memory Puzzle Verification (Positive)");
   Put_Line ("  11.1 Assume valid memory pointer rejected");
   begin
      Assert (Verify_Memory_Puzzle ("MemSeed", 'a', Idx), "Valid pointer rejected");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 12 - Memory Puzzle Invalid
   Put_Line ("TEST 12 - Memory Puzzle Verification (Negative)");
   Put_Line ("  12.1 Assume wrong pointer bypasses verification");
   begin
      -- Incrementing index invalidates the hash mapping
      Assert (Verify_Memory_Puzzle ("MemSeed", 'a', Idx + 1) = False, "Invalid pointer accepted");
      Put_Line ("     PASS (Assumption proven false)");
   exception
      when E : others => Put_Line ("     FAIL: " & Exception_Message (E));
   end;

   -- TEST 13 - Memory Puzzle Not Found Exception
   Put_Line ("TEST 13 - Memory Puzzle Missing Target");
   Put_Line ("  13.1 Assume impossible target 'z' in size 1 avoids raising PoW_Error");
   begin
      Solve_Memory_Puzzle ("MissingTarget", 1, 'z', Idx);
      Assert (False, "Expected PoW_Error was not raised");
   exception
      when PoW_Error => Put_Line ("     PASS (Assumption proven false)");
      when E : others => Put_Line ("     FAIL: Unexpected exception " & Exception_Message (E));
   end;
   
   -- TEST 14 - Invalid Difficulty Bound
   Put_Line ("TEST 14 - Type Constraints");
   Put_Line ("  14.1 Assume type system allows out-of-bounds difficulty (-1)");
   begin
      declare
         Invalid_Diff : Difficulty_Level;
      begin
         -- GNAT catches static constraint errors at compile time, so we bypass it with dynamic cast
         Invalid_Diff := Difficulty_Level (Integer'Value ("-1"));
         Assert (False, "Allowed negative difficulty");
      end;
   exception
      when Constraint_Error => Put_Line ("     PASS (Assumption proven false)");
      when E : others => Put_Line ("     FAIL: Unexpected exception " & Exception_Message (E));
   end;
end Tests;
