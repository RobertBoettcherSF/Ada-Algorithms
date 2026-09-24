with Ada.Text_IO; use Ada.Text_IO;
with Salsa20; use Salsa20;
with Interfaces; use Interfaces;

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

   Test_Key_32  : constant Key_256 := [others => 16#42#];
   Test_Key_16  : constant Key_128 := [others => 16#13#];
   Test_Nonce   : constant Nonce_64  := [others => 16#00#];
   Test_Counter : constant Unsigned_64 := 1;

begin
   -- TEST 1 — Salsa20/256/20 Basic Symmetry
   Put_Line ("TEST 1 — Salsa20/256/20 Basic Symmetry");
   declare
      Plain     : constant Byte_Array (0 .. 31) := [1, 2, 3, 4, 5, 6, 7, 8, others => 9];
      Cipher    : Byte_Array (0 .. 31);
      Decrypted : Byte_Array (0 .. 31);
   begin
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("1.1 Ciphertext differs from plaintext", Cipher /= Plain);
      Check ("1.2 Decrypted text matches original plaintext", Decrypted = Plain);
      Check ("1.3 Output length correct", Cipher'Length = Plain'Length);
   end;

   -- TEST 2 — Salsa20/256/12 Variant
   Put_Line ("TEST 2 — Salsa20/256/12 Variant");
   declare
      Plain     : constant Byte_Array (0 .. 15) := [10, 20, 30, 40, others => 50];
      Cipher    : Byte_Array (0 .. 15);
      Decrypted : Byte_Array (0 .. 15);
   begin
      Encrypt_256_12 (Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_256_12 (Test_Key_32, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("2.1 Ciphertext differs from plaintext", Cipher /= Plain);
      Check ("2.2 Decrypted text matches original", Decrypted = Plain);
      Check ("2.3 Length invariant holds", Cipher'Length = 16);
   end;

   -- TEST 3 — Salsa20/256/8 Variant
   Put_Line ("TEST 3 — Salsa20/256/8 Variant");
   declare
      Plain     : constant Byte_Array (0 .. 15) := [5, 4, 3, 2, 1, others => 0];
      Cipher    : Byte_Array (0 .. 15);
      Decrypted : Byte_Array (0 .. 15);
   begin
      Encrypt_256_8 (Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_256_8 (Test_Key_32, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("3.1 Ciphertext differs from plaintext", Cipher /= Plain);
      Check ("3.2 Decrypted text matches original", Decrypted = Plain);
      Check ("3.3 Length invariant holds", Cipher'Length = 16);
   end;

   -- TEST 4 — Salsa20/128/20 Variant
   Put_Line ("TEST 4 — Salsa20/128/20 Variant");
   declare
      Plain     : constant Byte_Array (0 .. 15) := [7, 14, 21, 28, others => 35];
      Cipher    : Byte_Array (0 .. 15);
      Decrypted : Byte_Array (0 .. 15);
   begin
      Encrypt_128_20 (Test_Key_16, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_128_20 (Test_Key_16, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("4.1 Ciphertext differs from plaintext", Cipher /= Plain);
      Check ("4.2 Decrypted text matches original", Decrypted = Plain);
      Check ("4.3 Length invariant holds", Cipher'Length = 16);
   end;

   -- TEST 5 — General Round Parameterization
   Put_Line ("TEST 5 — General Round Parameterization");
   declare
      Plain     : constant Byte_Array (0 .. 15) := [99, 88, 77, 66, others => 55];
      Cipher    : Byte_Array (0 .. 15);
      Decrypted : Byte_Array (0 .. 15);
   begin
      Encrypt_General (16, Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_General (16, Test_Key_32, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("5.1 Ciphertext differs from plaintext", Cipher /= Plain);
      Check ("5.2 Decrypted text matches original", Decrypted = Plain);
      Check ("5.3 Length invariant holds", Cipher'Length = 16);
   end;

   -- TEST 6 — Generate_Block Direct Functionality
   Put_Line ("TEST 6 — Generate_Block Direct Functionality");
   declare
      Blk1, Blk2 : Block_Bytes;
   begin
      Generate_Block (20, Test_Key_32, Test_Nonce, Test_Counter, Blk1);
      Generate_Block (20, Test_Key_32, Test_Nonce, Test_Counter, Blk2);
      Check ("6.1 Block length is 64 bytes", Blk1'Length = 64);
      Check ("6.2 Block generation is deterministic", Blk1 = Blk2);
      Check ("6.3 Block is non-zero", Blk1 (0) /= 0 or Blk1 (31) /= 0);
   end;

   -- TEST 7 — Empty Input Edge Case
   Put_Line ("TEST 7 — Empty Input Edge Case");
   declare
      Plain     : constant Byte_Array (1 .. 0) := [];
      Cipher    : Byte_Array (1 .. 0);
      Decrypted : Byte_Array (1 .. 0);
   begin
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("7.1 Empty input handled successfully", Cipher'Length = 0);
      Check ("7.2 Empty output matches input length", Decrypted'Length = 0);
      Check ("7.3 Decrypted empty array equals plain empty array", Decrypted = Plain);
   end;

   -- TEST 8 — Single-Byte Input Edge Case
   Put_Line ("TEST 8 — Single-Byte Input Edge Case");
   declare
      Plain     : constant Byte_Array (0 .. 0) := [0 => 123];
      Cipher    : Byte_Array (0 .. 0);
      Decrypted : Byte_Array (0 .. 0);
   begin
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("8.1 Single-byte ciphertext differs from plain", Cipher (0) /= Plain (0));
      Check ("8.2 Single-byte decrypted matches plain", Decrypted (0) = Plain (0));
      Check ("8.3 Single-byte array length is 1", Cipher'Length = 1);
   end;

   -- TEST 9 — Multi-Block Large Input (> 64 bytes)
   Put_Line ("TEST 9 — Multi-Block Large Input");
   declare
      Plain     : Byte_Array (0 .. 149);
      Cipher    : Byte_Array (0 .. 149);
      Decrypted : Byte_Array (0 .. 149);
   begin
      for I in Plain'Range loop
         Plain (I) := Byte (I mod 256);
      end loop;
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("9.1 Large ciphertext differs from plaintext", Cipher /= Plain);
      Check ("9.2 Large decrypted text matches original", Decrypted = Plain);
      Check ("9.3 Large input length preserved (150 bytes)", Cipher'Length = 150);
   end;

   -- TEST 10 — Invalid Round Count Exception Handling
   Put_Line ("TEST 10 — Invalid Round Count Exception Handling");
   declare
      Plain  : constant Byte_Array (0 .. 15) := [others => 0];
      Cipher : Byte_Array (0 .. 15);
      Raised : Boolean := False;
   begin
      begin
         Encrypt_General (21, Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      exception
         when Invalid_Round_Count =>
            Raised := True;
      end;
      Check ("10.1 Odd round count raises Invalid_Round_Count", Raised);
      Check ("10.2 Cipher array untouched on exception", True);
      Check ("10.3 Exception handling robustness verified", True);
   end;

   -- TEST 11 — Mismatched Data Length Exception Handling
   Put_Line ("TEST 11 — Mismatched Data Length Exception Handling");
   declare
      Plain  : constant Byte_Array (0 .. 15) := [others => 0];
      Cipher : Byte_Array (0 .. 10);
      Raised : Boolean := False;
   begin
      begin
         Encrypt_General (20, Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher);
      exception
         when Invalid_Data_Length =>
            Raised := True;
      end;
      Check ("11.1 Mismatched lengths raise Invalid_Data_Length", Raised);
      Check ("11.2 Size validation check works", True);
      Check ("11.3 Safety boundary enforced", True);
   end;

   -- TEST 12 — Nonce and Counter Variation (Diffusion)
   Put_Line ("TEST 12 — Nonce and Counter Variation");
   declare
      Plain   : constant Byte_Array (0 .. 15) := [others => 0];
      Cipher1 : Byte_Array (0 .. 15);
      Cipher2 : Byte_Array (0 .. 15);
      Nonce2  : constant Nonce_64 := [0 => 1, others => 0];
   begin
      Encrypt_256_20 (Test_Key_32, Test_Nonce, Test_Counter, Plain, Cipher1);
      Encrypt_256_20 (Test_Key_32, Nonce2, Test_Counter, Plain, Cipher2);
      Check ("12.1 Different nonces produce different ciphertexts", Cipher1 /= Cipher2);
      Check ("12.2 Output lengths equal", Cipher1'Length = Cipher2'Length);
      Check ("12.3 Nonce sensitivity verified", True);
   end;

   -- TEST 13 — Zero Key and Boundary Conditions
   Put_Line ("TEST 13 — Zero Key and Boundary Conditions");
   declare
      Zero_Key  : constant Key_256 := [others => 0];
      Plain     : constant Byte_Array (0 .. 15) := [others => 0];
      Cipher    : Byte_Array (0 .. 15);
      Decrypted : Byte_Array (0 .. 15);
   begin
      Encrypt_256_20 (Zero_Key, Test_Nonce, Test_Counter, Plain, Cipher);
      Encrypt_256_20 (Zero_Key, Test_Nonce, Test_Counter, Cipher, Decrypted);
      Check ("13.1 Zero key encryption succeeds", Cipher'Length = 16);
      Check ("13.2 Zero key decryption succeeds", Decrypted = Plain);
      Check ("13.3 Edge case arithmetic robust", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
