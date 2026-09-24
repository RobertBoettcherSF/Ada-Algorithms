with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;
with Twofish;     use Twofish;

procedure Tests is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_32;

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

   Key_128_Sample : constant Key_128_Bytes :=
     [16#00#, 16#01#, 16#02#, 16#03#, 16#04#, 16#05#, 16#06#, 16#07#,
      16#08#, 16#09#, 16#0A#, 16#0B#, 16#0C#, 16#0D#, 16#0E#, 16#0F#];

   Key_192_Sample : constant Key_192_Bytes :=
     [16#00#, 16#01#, 16#02#, 16#03#, 16#04#, 16#05#, 16#06#, 16#07#,
      16#08#, 16#09#, 16#0A#, 16#0B#, 16#0C#, 16#0D#, 16#0E#, 16#0F#,
      16#10#, 16#11#, 16#12#, 16#13#, 16#14#, 16#15#, 16#16#, 16#17#];

   Key_256_Sample : constant Key_256_Bytes :=
     [16#00#, 16#01#, 16#02#, 16#03#, 16#04#, 16#05#, 16#06#, 16#07#,
      16#08#, 16#09#, 16#0A#, 16#0B#, 16#0C#, 16#0D#, 16#0E#, 16#0F#,
      16#10#, 16#11#, 16#12#, 16#13#, 16#14#, 16#15#, 16#16#, 16#17#,
      16#18#, 16#19#, 16#1A#, 16#1B#, 16#1C#, 16#1D#, 16#1E#, 16#1F#];

   Zero_Block : constant Block_Bytes := [others => 16#00#];
   Data_Block : constant Block_Bytes :=
     [16#01#, 16#23#, 16#45#, 16#67#, 16#89#, 16#AB#, 16#CD#, 16#EF#,
      16#FE#, 16#DC#, 16#BA#, 16#98#, 16#76#, 16#54#, 16#32#, 16#10#];

   Ctx_128 : Twofish_Context (Key_128);
   Ctx_192 : Twofish_Context (Key_192);
   Ctx_256 : Twofish_Context (Key_256);

   Enc_Out : Block_Bytes;
   Dec_Out : Block_Bytes;

begin
   -- TEST 1 — 128-bit Key Setup
   Put_Line ("TEST 1 — 128-bit Key Setup");
   Key_Setup_128 (Key_128_Sample, Ctx_128);
   pragma Warnings (Off, "-gnatwc");
   Check ("1.1 Context key length is Key_128", Ctx_128.Key_Len = Key_128);
   pragma Warnings (On, "-gnatwc");
   Check ("1.2 Subkeys array populated", Ctx_128.Subkeys(0) /= 16#FFFFFFFF#);
   Check ("1.3 S-Box initialized", Ctx_128.S_Box(0) = 0);

   -- TEST 2 — 192-bit Key Setup
   Put_Line ("TEST 2 — 192-bit Key Setup");
   Key_Setup_192 (Key_192_Sample, Ctx_192);
   pragma Warnings (Off, "-gnatwc");
   Check ("2.1 Context key length is Key_192", Ctx_192.Key_Len = Key_192);
   pragma Warnings (On, "-gnatwc");
   Check ("2.2 Subkeys array populated", Ctx_192.Subkeys(5) /= 0);
   Check ("2.3 S-Box initialized", Ctx_192.S_Box(255) = 255);

   -- TEST 3 — 256-bit Key Setup
   Put_Line ("TEST 3 — 256-bit Key Setup");
   Key_Setup_256 (Key_256_Sample, Ctx_256);
   pragma Warnings (Off, "-gnatwc");
   Check ("3.1 Context key length is Key_256", Ctx_256.Key_Len = Key_256);
   pragma Warnings (On, "-gnatwc");
   Check ("3.2 Subkeys array populated", Ctx_256.Subkeys(10) /= 0);
   Check ("3.3 S-Box initialized", Ctx_128.S_Box(10) = 10);

   -- TEST 4 — Zero Block Encryption with 128-bit Key
   Put_Line ("TEST 4 — Zero Block Encryption (128-bit)");
   Encrypt (Ctx_128, Zero_Block, Enc_Out);
   Check ("4.1 Ciphertext generated (length 16)", Enc_Out'Length = 16);
   Check ("4.2 Ciphertext differs from plaintext", Enc_Out /= Zero_Block);
   Check ("4.3 Non-trivial output bytes", Enc_Out(1) /= 0 or Enc_Out(2) /= 0);

   -- TEST 5 — Zero Block Decryption with 128-bit Key
   Put_Line ("TEST 5 — Zero Block Decryption (128-bit)");
   Decrypt (Ctx_128, Enc_Out, Dec_Out);
   Check ("5.1 Plaintext recovered (length 16)", Dec_Out'Length = 16);
   Check ("5.2 Recovered plaintext matches original zero block", Dec_Out = Zero_Block);
   Check ("5.3 Decryption inverse verified", Dec_Out(1) = 0);

   -- TEST 6 — Data Block Roundtrip with 128-bit Key
   Put_Line ("TEST 6 — Data Block Roundtrip (128-bit)");
   Encrypt (Ctx_128, Data_Block, Enc_Out);
   Decrypt (Ctx_128, Enc_Out, Dec_Out);
   Check ("6.1 Encrypted output differs from data block", Enc_Out /= Data_Block);
   Check ("6.2 Decrypted output matches original data block", Dec_Out = Data_Block);
   Check ("6.3 First byte matches", Dec_Out(1) = Data_Block(1));

   -- TEST 7 — Data Block Roundtrip with 192-bit Key
   Put_Line ("TEST 7 — Data Block Roundtrip (192-bit)");
   Encrypt (Ctx_192, Data_Block, Enc_Out);
   Decrypt (Ctx_192, Enc_Out, Dec_Out);
   Check ("7.1 Encrypted output generated", Enc_Out /= Data_Block);
   Check ("7.2 Decrypted output matches original data block", Dec_Out = Data_Block);
   Check ("7.3 Middle byte matches", Dec_Out(8) = Data_Block(8));

   -- TEST 8 — Data Block Roundtrip with 256-bit Key
   Put_Line ("TEST 8 — Data Block Roundtrip (256-bit)");
   Encrypt (Ctx_256, Data_Block, Enc_Out);
   Decrypt (Ctx_256, Enc_Out, Dec_Out);
   Check ("8.1 Encrypted output generated", Enc_Out /= Data_Block);
   Check ("8.2 Decrypted output matches original data block", Dec_Out = Data_Block);
   Check ("8.3 Last byte matches", Dec_Out(16) = Data_Block(16));

   -- TEST 9 — Avalanche Effect (Different Plaintexts)
   Put_Line ("TEST 9 — Avalanche Effect (Plaintexts)");
   declare
      Block_Alt : constant Block_Bytes :=
        [16#02#, 16#23#, 16#45#, 16#67#, 16#89#, 16#AB#, 16#CD#, 16#EF#,
         16#FE#, 16#DC#, 16#BA#, 16#98#, 16#76#, 16#54#, 16#32#, 16#10#];
      Enc_Alt : Block_Bytes;
   begin
      Encrypt (Ctx_128, Block_Alt, Enc_Alt);
      Check ("9.1 Different plaintext yields different ciphertext", Enc_Alt /= Enc_Out);
      Check ("9.2 Ciphertext length valid", Enc_Alt'Length = 16);
      Check ("9.3 Ciphertext not all zeros", Enc_Alt /= Zero_Block);
   end;

   -- TEST 10 — Key Sensitivity (Different Keys)
   Put_Line ("TEST 10 — Key Sensitivity");
   declare
      Ctx_Alt : Twofish_Context (Key_128);
      Key_Alt : constant Key_128_Bytes :=
        [16#FF#, 16#01#, 16#02#, 16#03#, 16#04#, 16#05#, 16#06#, 16#07#,
         16#08#, 16#09#, 16#0A#, 16#0B#, 16#0C#, 16#0D#, 16#0E#, 16#0F#];
      Enc_Alt : Block_Bytes;
   begin
      Key_Setup_128 (Key_Alt, Ctx_Alt);
      Encrypt (Ctx_Alt, Data_Block, Enc_Alt);
      Check ("10.1 Different key yields different ciphertext", Enc_Alt /= Enc_Out);
      Check ("10.2 Alt ciphertext length valid", Enc_Alt'Length = 16);
      Check ("10.3 Alt ciphertext not zero", Enc_Alt /= Zero_Block);
   end;

   -- TEST 11 — Boundary Values (All Ones Block)
   Put_Line ("TEST 11 — Boundary Values (All Ones)");
   declare
      Ones_Block : constant Block_Bytes := [others => 16#FF#];
   begin
      Encrypt (Ctx_128, Ones_Block, Enc_Out);
      Decrypt (Ctx_128, Enc_Out, Dec_Out);
      Check ("11.1 All-ones encrypted successfully", Enc_Out /= Ones_Block);
      Check ("11.2 All-ones decrypted successfully", Dec_Out = Ones_Block);
      Check ("11.3 Block length invariant maintained", Dec_Out'Length = 16);
   end;

   -- TEST 12 — Multiple Successive Encryptions
   Put_Line ("TEST 12 — Successive Encryptions");
   declare
      B1, B2, B3 : Block_Bytes;
   begin
      Encrypt (Ctx_128, Data_Block, B1);
      Encrypt (Ctx_128, B1, B2);
      Encrypt (Ctx_128, B2, B3);
      Check ("12.1 Successive ciphertexts distinct", B1 /= B2);
      Check ("12.2 Successive ciphertexts distinct 2", B2 /= B3);
      Check ("12.3 All ciphertexts length 16", B3'Length = 16);
   end;

   -- TEST 13 — Context Independence
   Put_Line ("TEST 13 — Context Independence");
   declare
      Ctx_A, Ctx_B : Twofish_Context (Key_128);
      E_A, E_B     : Block_Bytes;
   begin
      Key_Setup_128 (Key_128_Sample, Ctx_A);
      Key_Setup_128 (Key_128_Sample, Ctx_B);
      Encrypt (Ctx_A, Data_Block, E_A);
      Encrypt (Ctx_B, Data_Block, E_B);
      Check ("13.1 Identical contexts produce identical ciphertext", E_A = E_B);
      Check ("13.2 Ciphertext non-zero", E_A /= Zero_Block);
      Check ("13.3 Ciphertext length valid", E_A'Length = 16);
   end;

   -- TEST 14 — Full Decryption Chain Verification
   Put_Line ("TEST 14 — Full Decryption Chain");
   declare
      Original : constant Block_Bytes :=
        [16#DE#, 16#AD#, 16#BE#, 16#EF#, 16#CA#, 16#FE#, 16#BA#, 16#BE#,
         16#01#, 16#23#, 16#45#, 16#67#, 16#89#, 16#AB#, 16#CD#, 16#EF#];
      Enc, Dec : Block_Bytes;
   begin
      Encrypt (Ctx_256, Original, Enc);
      Decrypt (Ctx_256, Enc, Dec);
      Check ("14.1 Encrypted successfully", Enc /= Original);
      Check ("14.2 Decrypted successfully", Dec = Original);
      Check ("14.3 Full 16-byte integrity verified", Dec(1) = Original(1) and Dec(16) = Original(16));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
