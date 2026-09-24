with Ada.Text_IO; use Ada.Text_IO;
with Post_Quantum_Crypto; use Post_Quantum_Crypto;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   SK, SK2 : Secret_Key;
   PK, PK2 : Public_Key;
   CT, CT2 : Ciphertext;
   
   --  Test variables
   A_Mat : constant Matrix_M_N := [others => [others => 1]];
   S_Vec : constant Vector_N   := [others => 2];
   E_Vec : constant Vector_M   := [others => 0];
   
   Inner : Element;
begin
   Put_Line ("--- LWE Post-Quantum Cryptography Test Suite ---");

   -- TEST 1 — Static Keypair Validation
   Put_Line ("TEST 1 — Static Keypair Variant");
   Generate_Keypair_Static (A_Mat, S_Vec, E_Vec, SK, PK);
   Check ("1.1 PK.A is correctly assigned", PK.A (1, 1) = 1);
   Check ("1.2 SK.S is correctly assigned", SK.S (1) = 2);
   Check ("1.3 B vector mathematically sound (16 * 1 * 2 = 32)", PK.B (1) = 32);

   -- TEST 2 — Dynamic PRNG Keypair
   Put_Line ("TEST 2 — Dynamic PRNG Keypair Variant");
   Generate_Keypair (123, SK, PK);
   Generate_Keypair (456, SK2, PK2);
   Check ("2.1 Seed 123 differs from Seed 456 (S)", SK.S (1) /= SK2.S (1));
   Check ("2.2 Seed 123 differs from Seed 456 (A)", PK.A (1, 1) /= PK2.A (1, 1));
   Check ("2.3 Seed 123 differs from Seed 456 (B)", PK.B (1) /= PK2.B (1));

   -- TEST 3 — Encrypt/Decrypt Bit 0
   Put_Line ("TEST 3 — Preemptive Variant: Bit 0");
   CT := Encrypt_Bit (789, PK, 0);
   Check ("3.1 Decrypts identically to 0", Decrypt_Bit (SK, CT) = 0);
   Check ("3.2 CT is structurally valid", Is_Valid_Ciphertext (CT));
   Check ("3.3 V value is properly distributed (< 64 or > 192)", CT.V < 64 or CT.V > 192);

   -- TEST 4 — Encrypt/Decrypt Bit 1
   Put_Line ("TEST 4 — Preemptive Variant: Bit 1");
   CT := Encrypt_Bit (789, PK, 1);
   Check ("4.1 Decrypts identically to 1", Decrypt_Bit (SK, CT) = 1);
   Check ("4.2 CT is structurally valid", Is_Valid_Ciphertext (CT));
   Check ("4.3 V value shifted by q/2 (approx 128)", CT.V > 64 and CT.V < 192);

   -- TEST 5 — Non-Preemptive Batch Message (All Zeros)
   Put_Line ("TEST 5 — Batch Variant: All Zeros");
   declare
      Msg : constant Bit_Array (1 .. 10) := [others => 0];
      CTs : constant Ciphertext_Array := Encrypt_Message (101, PK, Msg);
      Dec : constant Bit_Array := Decrypt_Message (SK, CTs);
   begin
      Check ("5.1 Batch length maintained", CTs'Length = 10);
      Check ("5.2 First element matches 0", Dec (1) = 0);
      Check ("5.3 Last element matches 0", Dec (10) = 0);
   end;

   -- TEST 6 — Non-Preemptive Batch Message (All Ones)
   Put_Line ("TEST 6 — Batch Variant: All Ones");
   declare
      Msg : constant Bit_Array (1 .. 10) := [others => 1];
      CTs : constant Ciphertext_Array := Encrypt_Message (102, PK, Msg);
      Dec : constant Bit_Array := Decrypt_Message (SK, CTs);
   begin
      Check ("6.1 Batch length maintained", CTs'Length = 10);
      Check ("6.2 First element matches 1", Dec (1) = 1);
      Check ("6.3 Last element matches 1", Dec (10) = 1);
   end;

   -- TEST 7 — Batch Message (Alternating)
   Put_Line ("TEST 7 — Batch Variant: Alternating Bits");
   declare
      Msg : constant Bit_Array (1 .. 4) := [0, 1, 0, 1];
      CTs : constant Ciphertext_Array := Encrypt_Message (103, PK, Msg);
      Dec : constant Bit_Array := Decrypt_Message (SK, CTs);
   begin
      Check ("7.1 Index 1 matches 0", Dec (1) = 0);
      Check ("7.2 Index 2 matches 1", Dec (2) = 1);
      Check ("7.3 Index 4 matches 1", Dec (4) = 1);
   end;

   -- TEST 8 — Error Handling (Edge Cases)
   Put_Line ("TEST 8 — Edge Cases & Preconditions");
   Check ("8.1 Is_Valid_Ciphertext traps all-zero state", 
          Is_Valid_Ciphertext ((U => [others => 0], V => 0)) = False);
   begin
      declare
         Empty_Msg : constant Bit_Array (1 .. 0) := [others => 0];
         Dummy     : constant Ciphertext_Array := Encrypt_Message (1, PK, Empty_Msg);
      begin
         Check ("8.2 Encrypt_Message bypasses exception", False);
      end;
   exception
      when others => Check ("8.2 Empty plaintext raises exception properly", True);
   end;
   begin
      declare
         Empty_CTs : constant Ciphertext_Array (1 .. 0) := [others => CT];
         Dummy     : constant Bit_Array := Decrypt_Message (SK, Empty_CTs);
      begin
         Check ("8.3 Decrypt_Message bypasses exception", False);
      end;
   exception
      when others => Check ("8.3 Empty ciphertext raises exception properly", True);
   end;

   -- TEST 9 — Determinism
   Put_Line ("TEST 9 — Cryptographic Determinism via Seed");
   CT  := Encrypt_Bit (999, PK, 1);
   CT2 := Encrypt_Bit (999, PK, 1);
   Check ("9.1 Identical seed yields same V", CT.V = CT2.V);
   Check ("9.2 Identical seed yields same U(1)", CT.U (1) = CT2.U (1));
   Check ("9.3 Identical seed yields same U(16)", CT.U (16) = CT2.U (16));

   -- TEST 10 — Entropy Spread
   Put_Line ("TEST 10 — Cryptographic Entropy via Seeds");
   CT  := Encrypt_Bit (111, PK, 1);
   CT2 := Encrypt_Bit (222, PK, 1);
   Check ("10.1 Different seed diverges V", CT.V /= CT2.V);
   Check ("10.2 Different seed diverges U(1)", CT.U (1) /= CT2.U (1));
   Check ("10.3 Different seed diverges U(16)", CT.U (16) /= CT2.U (16));

   -- Pre-calculate inner product for mathematical threshold testing (Tests 11-14)
   CT.U := [others => 1];
   Inner := 0;
   for J in Index_N loop
      Inner := Inner + CT.U (J) * SK.S (J);
   end loop;

   -- TEST 11 — Decision Threshold: Upper Limit for Bit 0
   Put_Line ("TEST 11 — Decision Threshold (0 Upper Limit)");
   CT.V := Inner + 63;
   Check ("11.1 Distance 63 triggers 0 correctly", Decrypt_Bit (SK, CT) = 0);
   Check ("11.2 Not returning 1", Decrypt_Bit (SK, CT) /= 1);
   Check ("11.3 Structurally valid bypass check", Is_Valid_Ciphertext(CT));

   -- TEST 12 — Decision Threshold: Lower Limit for Bit 1
   Put_Line ("TEST 12 — Decision Threshold (1 Lower Limit)");
   CT.V := Inner + 64;
   Check ("12.1 Distance 64 triggers 1 correctly", Decrypt_Bit (SK, CT) = 1);
   Check ("12.2 Not returning 0", Decrypt_Bit (SK, CT) /= 0);
   Check ("12.3 Structurally valid bypass check", Is_Valid_Ciphertext(CT));

   -- TEST 13 — Decision Threshold: Upper Limit for Bit 1
   Put_Line ("TEST 13 — Decision Threshold (1 Upper Limit)");
   CT.V := Inner + 192;
   Check ("13.1 Distance 192 triggers 1 correctly", Decrypt_Bit (SK, CT) = 1);
   Check ("13.2 Not returning 0", Decrypt_Bit (SK, CT) /= 0);
   Check ("13.3 Structurally valid bypass check", Is_Valid_Ciphertext(CT));

   -- TEST 14 — Decision Threshold: Lower Limit for Wrap 0
   Put_Line ("TEST 14 — Decision Threshold (0 Wrap Bound)");
   CT.V := Inner + 193;
   Check ("14.1 Distance 193 triggers 0 correctly", Decrypt_Bit (SK, CT) = 0);
   Check ("14.2 Not returning 1", Decrypt_Bit (SK, CT) /= 1);
   Check ("14.3 Structurally valid bypass check", Is_Valid_Ciphertext(CT));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
             
   -- Verify test suite overall health using built-in assertions
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
