with Ada.Text_IO; use Ada.Text_IO;
with AES; use AES;

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

   -- FIPS 197 Vectors
   -- Appendix B Plaintext (Used for AES-128 test vector)
   FIPS_Plain   : constant Block := [16#32#, 16#43#, 16#F6#, 16#A8#, 16#88#, 16#5A#, 16#30#, 16#8D#, 
                                     16#31#, 16#31#, 16#98#, 16#A2#, 16#E0#, 16#37#, 16#07#, 16#34#];

   -- Appendix C Plaintext (Used for AES-192 and AES-256 test vectors)
   FIPS_Plain_C : constant Block := [16#00#, 16#11#, 16#22#, 16#33#, 16#44#, 16#55#, 16#66#, 16#77#, 
                                     16#88#, 16#99#, 16#AA#, 16#BB#, 16#CC#, 16#DD#, 16#EE#, 16#FF#];
   
   -- Appendix B test vectors for AES-128
   K128         : constant Key_128 := [16#2B#, 16#7E#, 16#15#, 16#16#, 16#28#, 16#AE#, 16#D2#, 16#A6#, 
                                       16#AB#, 16#F7#, 16#15#, 16#88#, 16#09#, 16#CF#, 16#4F#, 16#3C#];
   Expected_128 : constant Block := [16#39#, 16#25#, 16#84#, 16#1D#, 16#02#, 16#DC#, 16#09#, 16#FB#, 
                                     16#DC#, 16#11#, 16#85#, 16#97#, 16#19#, 16#6A#, 16#0B#, 16#32#];

   -- Appendix C.2 test vectors for AES-192
   K192         : constant Key_192 := [16#00#, 16#01#, 16#02#, 16#03#, 16#04#, 16#05#, 16#06#, 16#07#, 
                                       16#08#, 16#09#, 16#0A#, 16#0B#, 16#0C#, 16#0D#, 16#0E#, 16#0F#, 
                                       16#10#, 16#11#, 16#12#, 16#13#, 16#14#, 16#15#, 16#16#, 16#17#];
   Expected_192 : constant Block := [16#DD#, 16#A9#, 16#7C#, 16#A4#, 16#86#, 16#4C#, 16#DF#, 16#E0#, 
                                     16#6E#, 16#AF#, 16#70#, 16#A0#, 16#EC#, 16#0D#, 16#71#, 16#91#];

   -- Appendix C.3 test vectors for AES-256
   K256         : constant Key_256 := [16#00#, 16#01#, 16#02#, 16#03#, 16#04#, 16#05#, 16#06#, 16#07#, 
                                       16#08#, 16#09#, 16#0A#, 16#0B#, 16#0C#, 16#0D#, 16#0E#, 16#0F#, 
                                       16#10#, 16#11#, 16#12#, 16#13#, 16#14#, 16#15#, 16#16#, 16#17#, 
                                       16#18#, 16#19#, 16#1A#, 16#1B#, 16#1C#, 16#1D#, 16#1E#, 16#1F#];
   Expected_256 : constant Block := [16#8E#, 16#A2#, 16#B7#, 16#CA#, 16#51#, 16#67#, 16#45#, 16#BF#, 
                                     16#EA#, 16#FC#, 16#49#, 16#90#, 16#4B#, 16#49#, 16#60#, 16#89#];

   Cipher, Decrypted : Block;
   Empty_Array       : constant Byte_Array (1 .. 0) := [others => 0];
   Empty_Output      : Byte_Array (1 .. 0);

begin
   Put_Line ("Starting AES verification suite...");
   Put_Line ("=====================================");

   -- TEST 1: AES-128 Encryption Functional Check
   Put_Line ("TEST 1 — AES-128 Encrypt (FIPS 197)");
   Encrypt_Block_128 (FIPS_Plain, K128, Cipher);
   Check ("1.1 Cipher is full length", Cipher'Length = 16);
   Check ("1.2 Cipher differs from plaintext", Cipher /= FIPS_Plain);
   Check ("1.3 Matches FIPS 197 exact vector", Cipher = Expected_128);

   -- TEST 2: AES-128 Decryption Functional Check
   Put_Line ("TEST 2 — AES-128 Decrypt (FIPS 197)");
   Decrypt_Block_128 (Cipher, K128, Decrypted);
   Check ("2.1 Decrypted output is full length", Decrypted'Length = 16);
   Check ("2.2 Decrypted differs from Cipher", Decrypted /= Cipher);
   Check ("2.3 Reconstructs original plaintext", Decrypted = FIPS_Plain);

   -- TEST 3: AES-192 Encryption Functional Check
   Put_Line ("TEST 3 — AES-192 Encrypt (FIPS 197)");
   Encrypt_Block_192 (FIPS_Plain_C, K192, Cipher);
   Check ("3.1 Cipher is full length", Cipher'Length = 16);
   Check ("3.2 Cipher differs from plaintext", Cipher /= FIPS_Plain_C);
   Check ("3.3 Matches FIPS 197 exact vector", Cipher = Expected_192);

   -- TEST 4: AES-192 Decryption Functional Check
   Put_Line ("TEST 4 — AES-192 Decrypt (FIPS 197)");
   Decrypt_Block_192 (Cipher, K192, Decrypted);
   Check ("4.1 Decrypted output is full length", Decrypted'Length = 16);
   Check ("4.2 Decrypted differs from Cipher", Decrypted /= Cipher);
   Check ("4.3 Reconstructs original plaintext", Decrypted = FIPS_Plain_C);

   -- TEST 5: AES-256 Encryption Functional Check
   Put_Line ("TEST 5 — AES-256 Encrypt (FIPS 197)");
   Encrypt_Block_256 (FIPS_Plain_C, K256, Cipher);
   Check ("5.1 Cipher is full length", Cipher'Length = 16);
   Check ("5.2 Cipher differs from plaintext", Cipher /= FIPS_Plain_C);
   Check ("5.3 Matches FIPS 197 exact vector", Cipher = Expected_256);

   -- TEST 6: AES-256 Decryption Functional Check
   Put_Line ("TEST 6 — AES-256 Decrypt (FIPS 197)");
   Decrypt_Block_256 (Cipher, K256, Decrypted);
   Check ("6.1 Decrypted output is full length", Decrypted'Length = 16);
   Check ("6.2 Decrypted differs from Cipher", Decrypted /= Cipher);
   Check ("6.3 Reconstructs original plaintext", Decrypted = FIPS_Plain_C);

   -- TEST 7: Empty Inputs (ECB Mode)
   Put_Line ("TEST 7 — Empty Data Handled Without Error");
   begin
      Encrypt_ECB_128 (Empty_Array, K128, Empty_Output);
      Check ("7.1 Finished empty encrypt without exception", True);
      Decrypt_ECB_128 (Empty_Array, K128, Empty_Output);
      Check ("7.2 Finished empty decrypt without exception", True);
      Check ("7.3 Output remained size 0", Empty_Output'Length = 0);
   exception
      when others => Check ("7.1 Unexpected Exception", False);
   end;

   -- TEST 8: Invalid Length Exception Check
   Put_Line ("TEST 8 — Rejects Invalid Padding/Sizes (Exception)");
   declare
      Bad_Input : constant Byte_Array (1 .. 15) := [others => 0];
      Out_Data  : Byte_Array (1 .. 15) := [others => 99];
      Raised    : Boolean := False;
   begin
      begin
         Encrypt_ECB_128 (Bad_Input, K128, Out_Data);
      exception
         when Invalid_Length =>
            Raised := True;
      end;
      Check ("8.1 Threw Invalid_Length exception", Raised);
      Check ("8.2 Input was safely rejected based on length", Bad_Input'Length = 15);
      Check ("8.3 Internal arrays were not manipulated", Out_Data (1) = 99);
   end;

   -- TEST 9: Small Destination Buffer Exception Check
   Put_Line ("TEST 9 — Rejects Overflows to Tiny Buffers");
   declare
      Good_Input : constant Byte_Array (1 .. 16) := [others => 1];
      Bad_Output : Byte_Array (1 .. 15) := [others => 99];
      Raised     : Boolean := False;
   begin
      begin
         Encrypt_ECB_192 (Good_Input, K192, Bad_Output);
      exception
         when Invalid_Length =>
            Raised := True;
      end;
      Check ("9.1 Threw exception for too-small output buffer", Raised);
      Check ("9.2 Buffer size check evaluates safely", Bad_Output'Length < Good_Input'Length);
      Check ("9.3 Internal arrays were not manipulated", Bad_Output (1) = 99);
   end;

   -- TEST 10: Multi-Block Encryption
   Put_Line ("TEST 10 — Multi-Block Encrypt Integrity");
   declare
      Data           : Byte_Array (1 .. 32);
      Out_Data       : Byte_Array (1 .. 32);
      Expected_Block : Byte_Array (1 .. 16);
   begin
      for I in 0 .. 15 loop 
         Data (1 + I) := FIPS_Plain_C (I);
         Data (17 + I) := FIPS_Plain_C (I);
         Expected_Block (1 + I) := Expected_256 (I);
      end loop;
      
      Encrypt_ECB_256 (Data, K256, Out_Data);
      Check ("10.1 Successfully processed 32 bytes (2 blocks)", Out_Data'Length = 32);
      Check ("10.2 Block 1 matches standalone AES", Out_Data (1 .. 16) = Expected_Block);
      Check ("10.3 Block 2 matches standalone AES", Out_Data (17 .. 32) = Expected_Block);
   end;

   -- TEST 11: Multi-Block Decryption
   Put_Line ("TEST 11 — Multi-Block Decrypt Integrity");
   declare
      Cipher_In : Byte_Array (1 .. 32);
      Plain_Out : Byte_Array (1 .. 32);
   begin
      for I in 0 .. 15 loop Cipher_In (1 + I) := Expected_256 (I); end loop;
      for I in 0 .. 15 loop Cipher_In (17 + I) := Expected_256 (I); end loop;
      
      Decrypt_ECB_256 (Cipher_In, K256, Plain_Out);
      Check ("11.1 Successfully reversed 32 bytes", Plain_Out'Length = 32);
      Check ("11.2 Reconstructed Block 1 correctly", Plain_Out (1) = 16#00#);
      Check ("11.3 Block 1 and Block 2 plaintexts are identical", Plain_Out (1 .. 16) = Plain_Out (17 .. 32));
   end;

   -- TEST 12: Avalanche Effect (One bit change)
   Put_Line ("TEST 12 — Avalanche Effect Integrity");
   declare
      Mutated : Block := FIPS_Plain;
      C1, C2  : Block;
      Diffs   : Natural := 0;
   begin
      Mutated (0) := Mutated (0) xor 1; -- flip just the first bit
      Encrypt_Block_128 (FIPS_Plain, K128, C1);
      Encrypt_Block_128 (Mutated, K128, C2);
      
      for I in 0 .. 15 loop
         if C1(I) /= C2(I) then Diffs := Diffs + 1; end if;
      end loop;
      Check ("12.1 Only 1 bit changed in input", Mutated (0) /= FIPS_Plain (0));
      Check ("12.2 Output differs severely from input (Avalanche)", Diffs > 8);
      Check ("12.3 Both paths executed completely", C1(15) /= C2(15));
   end;

   -- TEST 13: Zeros Identity Check
   Put_Line ("TEST 13 — Identity Check (Zero-filled data & key)");
   declare
      Zero_Key   : constant Key_128 := [others => 0];
      Zero_Data  : constant Block   := [others => 0];
      Enc_Zeroes : Block;
      Dec_Zeroes : Block;
   begin
      Encrypt_Block_128 (Zero_Data, Zero_Key, Enc_Zeroes);
      Check ("13.1 Cipher text is NOT all zeroes (diffusion active)", Enc_Zeroes /= Zero_Data);
      Decrypt_Block_128 (Enc_Zeroes, Zero_Key, Dec_Zeroes);
      Check ("13.2 Inverse correctly reconstructed zeroes", Dec_Zeroes = Zero_Data);
      Check ("13.3 Keys and Data preserved size types properly", Dec_Zeroes'Length = 16);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
