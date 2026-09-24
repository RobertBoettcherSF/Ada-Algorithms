with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;  use Interfaces;
with Chacha;      use Chacha;

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

   --  Helper to initialize byte arrays from strings for tests
   function To_Bytes (S : String) return Bytes is
      B : Bytes (0 .. S'Length - 1);
   begin
      for I in S'Range loop
         B (I - S'First) := Character'Pos (S (I));
      end loop;
      return B;
   end To_Bytes;

   --  Shared test variables
   Test_Key_IETF    : constant Key_256  := [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31];
   Test_Nonce_IETF  : constant Nonce_96 := [0,0,0,9, 0,0,0,16#4a#, 0,0,0,0];
   Test_Nonce_Orig  : constant Nonce_64 := [1,2,3,4, 5,6,7,8];
   
   A, B, C, D : Word;
   Block_Data : Block_Type;
   Msg_1      : Bytes := To_Bytes ("Short message");
   Msg_Empty  : Bytes (1 .. 0);
   Msg_1_Byte : Bytes (1 .. 1) := [1 => 16#AA#];
   Msg_Large  : Bytes (0 .. 129) := [others => 0];
begin
   --  TEST 1 — Quarter Round correctness (RFC 7539 Sec 2.1.1 vector)
   Put_Line ("TEST 1 — Quarter Round Functional Correctness");
   A := 16#11111111#; B := 16#01020304#; C := 16#9b8d6f43#; D := 16#01234567#;
   Quarter_Round (A, B, C, D);
   Check ("1.1 Word A matching RFC", A = 16#ea2a92f4#);
   Check ("1.2 Word B matching RFC", B = 16#cb1cf8ce#);
   Check ("1.3 Word C matching RFC", C = 16#4581472e#);
   Check ("1.4 Word D matching RFC", D = 16#5881c4bb#);

   --  TEST 2 — IETF Block Generation (RFC 7539 Sec 2.3.2 vector check on first bytes)
   Put_Line ("TEST 2 — IETF Block Generation");
   declare
      State : constant State_Array := [16#61707865#, 16#3320646e#, 16#79622d32#, 16#6b206574#,
                                       16#03020100#, 16#07060504#, 16#0b0a0908#, 16#0f0e0d0c#,
                                       16#13121110#, 16#17161514#, 16#1b1a1918#, 16#1f1e1d1c#,
                                       1, 16#09000000#, 16#4a000000#, 0];
   begin
      Generate_Block (State, ChaCha20, Block_Data);
      Check ("2.1 Keystream byte 0", Block_Data (0) = 16#10#);
      Check ("2.2 Keystream byte 1", Block_Data (1) = 16#f1#);
      Check ("2.3 Keystream byte 2", Block_Data (2) = 16#e7#);
      Check ("2.4 Keystream byte 63 exists", Block_Data'Last = 63);
   end;

   --  TEST 3 — IETF Encryption Identity (Single Block)
   Put_Line ("TEST 3 — IETF Single Block Identity");
   declare
      Orig : constant Bytes := Msg_1;
   begin
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Msg_1, ChaCha20);
      Check ("3.1 Ciphertext != Plaintext", Msg_1 (0) /= Orig (0));
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Msg_1, ChaCha20);
      Check ("3.2 Decryption restores byte 0", Msg_1 (0) = Orig (0));
      Check ("3.3 Decryption restores exact string", Msg_1 = Orig);
   end;

   --  TEST 4 — Edge Case: Empty Data Encryption
   Put_Line ("TEST 4 — Edge Case: Empty Data Array");
   Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Msg_Empty);
   Check ("4.1 Length invariant maintained", Msg_Empty'Length = 0);
   Check ("4.2 First bound invariant", Msg_Empty'First = 1);
   Check ("4.3 Last bound invariant", Msg_Empty'Last = 0);

   --  TEST 5 — Edge Case: Single Byte
   Put_Line ("TEST 5 — Edge Case: Single Byte");
   Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Msg_1_Byte);
   Check ("5.1 State altered successfully", Msg_1_Byte (1) /= 16#AA#);
   Check ("5.2 Length invariant maintained", Msg_1_Byte'Length = 1);
   Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Msg_1_Byte);
   Check ("5.3 Reversible", Msg_1_Byte (1) = 16#AA#);

   --  TEST 6 — ChaCha8 Variant Encryption
   Put_Line ("TEST 6 — ChaCha8 Variant (IETF)");
   declare
      Data : Bytes := To_Bytes ("ChaCha8");
      Orig : constant Bytes := Data;
   begin
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Data, Variant => ChaCha8);
      Check ("6.1 Encrypted successfully", Data /= Orig);
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Data, Variant => ChaCha8);
      Check ("6.2 Decrypted successfully", Data = Orig);
      Check ("6.3 Structure preserved", Data'Length = 7);
   end;

   --  TEST 7 — ChaCha12 Variant Encryption
   Put_Line ("TEST 7 — ChaCha12 Variant (IETF)");
   declare
      Data : Bytes := To_Bytes ("ChaCha12Test");
      Orig : constant Bytes := Data;
   begin
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Data, Variant => ChaCha12);
      Check ("7.1 Encrypted successfully", Data /= Orig);
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Data, Variant => ChaCha12);
      Check ("7.2 Decrypted successfully", Data = Orig);
      Check ("7.3 Valid index mapping", Data (Data'Last) = Orig (Orig'Last));
   end;

   --  TEST 8 — Original Bernstein Variant (64-bit Nonce, 64-bit Counter)
   Put_Line ("TEST 8 — Original Bernstein Variant");
   declare
      Data : Bytes := To_Bytes ("Testing Original 64-bit Nonce!");
      Orig : constant Bytes := Data;
   begin
      Encrypt_Original (Test_Key_IETF, Test_Nonce_Orig, 1000, Data, ChaCha20);
      Check ("8.1 Ciphertext mutated", Data /= Orig);
      Check ("8.2 Length maintained", Data'Length = Orig'Length);
      Encrypt_Original (Test_Key_IETF, Test_Nonce_Orig, 1000, Data, ChaCha20);
      Check ("8.3 Symmetry verified", Data = Orig);
   end;

   --  TEST 9 — Original Variant 64-bit Counter Wrapping Boundary
   Put_Line ("TEST 9 — Original Variant Counter Word Wrap");
   declare
      Data_Block : Bytes (0 .. 127) := [others => 0];
      -- Counter set to Max(Unsigned_32) to force overflow into Word 13 on block 2
   begin
      Encrypt_Original (Test_Key_IETF, Test_Nonce_Orig, 16#0000_0000_FFFF_FFFF#, Data_Block);
      Check ("9.1 Successfully processed multiple blocks without crash", True);
      Check ("9.2 Byte 0 modified", Data_Block (0) /= 0);
      Check ("9.3 Byte 127 modified", Data_Block (127) /= 0);
   end;

   --  TEST 10 — Large Data (Multi-Block) Non-Multiple IETF
   Put_Line ("TEST 10 — Large Data Cross-Block Integrity");
   declare
      Orig_Large : constant Bytes := Msg_Large;
   begin
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 0, Msg_Large);
      Check ("10.1 First byte altered", Msg_Large (0) /= 0);
      Check ("10.2 Block boundary altered", Msg_Large (64) /= 0);
      Check ("10.3 Final non-aligned byte altered", Msg_Large (129) /= 0);
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 0, Msg_Large);
      Check ("10.4 All blocks restored correctly", Msg_Large = Orig_Large);
   end;

   --  TEST 11 — Invariant Safety: Zero Quarter Round
   Put_Line ("TEST 11 — Quarter Round Zero Invariant");
   A := 0; B := 0; C := 0; D := 0;
   Quarter_Round (A, B, C, D);
   Check ("11.1 A remains 0", A = 0);
   Check ("11.2 B remains 0", B = 0);
   Check ("11.3 C remains 0", C = 0);
   Check ("11.4 D remains 0", D = 0);

   --  TEST 12 — Variant Cross-Pollination Assurance (ChaCha8 vs ChaCha20)
   Put_Line ("TEST 12 — Variant Cross-Pollination");
   declare
      Data1 : Bytes := To_Bytes ("Collision");
      Data2 : Bytes := To_Bytes ("Collision");
   begin
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Data1, ChaCha8);
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Data2, ChaCha20);
      Check ("12.1 ChaCha8 mutates", Data1 /= To_Bytes ("Collision"));
      Check ("12.2 ChaCha20 mutates", Data2 /= To_Bytes ("Collision"));
      Check ("12.3 Keystreams differ by variant", Data1 /= Data2);
   end;
   
   --  TEST 13 — Variant Cross-Pollination Assurance (Original vs IETF)
   Put_Line ("TEST 13 — Protocol Variant Cross-Pollination");
   declare
      -- IETF uses a 96 bit nonce, Original uses 64 bit nonce. 
      -- We'll use padded arrays just to prove they derive different initial states.
      Data1 : Bytes := To_Bytes ("Collision2");
      Data2 : Bytes := To_Bytes ("Collision2");
   begin
      Encrypt_IETF (Test_Key_IETF, Test_Nonce_IETF, 1, Data1, ChaCha20);
      Encrypt_Original (Test_Key_IETF, Test_Nonce_Orig, 1, Data2, ChaCha20);
      Check ("13.1 IETF mutates", Data1 /= To_Bytes ("Collision2"));
      Check ("13.2 Original mutates", Data2 /= To_Bytes ("Collision2"));
      Check ("13.3 Keystreams differ across formats", Data1 /= Data2);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
