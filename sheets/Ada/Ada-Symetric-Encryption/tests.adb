with Ada.Text_IO; use Ada.Text_IO;
with Symmetric_Ciphers; use Symmetric_Ciphers;

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

begin
   --  ========================================================================
   --  TEST 1: TEA Block Primitive Reversibility
   --  ========================================================================
   declare
      Block_1    : TEA_Block := [10, 20];
      Block_Orig : constant TEA_Block := Block_1;
      Key_1      : constant TEA_Key := [1, 2, 3, 4];
      Key_2      : constant TEA_Key := [5, 6, 7, 8];
   begin
      Put_Line ("TEST 1 — TEA Primitive Reversibility");
      TEA_Encrypt_Block (Block_1, Key_1);
      Check ("1.1 Encrypted block differs from original", Block_1 /= Block_Orig);
      
      TEA_Decrypt_Block (Block_1, Key_1);
      Check ("1.2 Decrypted block matches original", Block_1 = Block_Orig);
      
      TEA_Encrypt_Block (Block_1, Key_2);
      TEA_Decrypt_Block (Block_1, Key_1);
      Check ("1.3 Decrypting with wrong key yields garbage", Block_1 /= Block_Orig);
   end;

   --  ========================================================================
   --  TEST 2: TEA Block Extreme Values
   --  ========================================================================
   declare
      Zero_Block : TEA_Block := [0, 0];
      Max_Block  : TEA_Block := [Word32'Last, Word32'Last];
      Zero_Key   : constant TEA_Key := [0, 0, 0, 0];
   begin
      Put_Line ("TEST 2 — TEA Primitive Extreme Values");
      TEA_Encrypt_Block (Zero_Block, Zero_Key);
      TEA_Decrypt_Block (Zero_Block, Zero_Key);
      Check ("2.1 Zero block encrypts/decrypts correctly", Zero_Block = [0, 0]);
      
      TEA_Encrypt_Block (Max_Block, Zero_Key);
      TEA_Decrypt_Block (Max_Block, Zero_Key);
      Check ("2.2 Max word32 block encrypts/decrypts correctly", Max_Block = [Word32'Last, Word32'Last]);
      
      TEA_Encrypt_Block (Zero_Block, [Word32'Last, Word32'Last, Word32'Last, Word32'Last]);
      Check ("2.3 Max key does not cause failures", Zero_Block /= [0, 0]);
   end;

   --  ========================================================================
   --  TEST 3: TEA ECB Mode Basic
   --  ========================================================================
   declare
      PT  : constant TEA_Block_Array (1 .. 3) := [[1, 1], [2, 2], [1, 1]];
      CT  : TEA_Block_Array (1 .. 3);
      Key : constant TEA_Key := [10, 20, 30, 40];
   begin
      Put_Line ("TEST 3 — TEA ECB Mode Basic");
      CT := TEA_Encrypt_ECB (PT, Key);
      Check ("3.1 Output length matches input", CT'Length = PT'Length);
      
      Check ("3.2 ECB is perfectly reversible", TEA_Decrypt_ECB (CT, Key) = PT);
      
      --  ECB property: identical plaintext blocks map to identical ciphertext blocks
      Check ("3.3 Identical PT blocks map to identical CT blocks", CT (1) = CT (3));
   end;

   --  ========================================================================
   --  TEST 4: TEA ECB Empty Input Handling
   --  ========================================================================
   declare
      Empty_PT : constant TEA_Block_Array (1 .. 0) := [others => [0, 0]];
      Empty_CT : TEA_Block_Array (1 .. 0);
      Key      : constant TEA_Key := [1, 1, 1, 1];
   begin
      Put_Line ("TEST 4 — TEA ECB Empty Input");
      Empty_CT := TEA_Encrypt_ECB (Empty_PT, Key);
      Check ("4.1 Empty input to encrypt returns empty", Empty_CT'Length = 0);
      
      Empty_CT := TEA_Decrypt_ECB (Empty_PT, Key);
      Check ("4.2 Empty input to decrypt returns empty", Empty_CT'Length = 0);
      
      Check ("4.3 Processing empty array does not throw exceptions", Empty_CT = Empty_PT);
   end;

   --  ========================================================================
   --  TEST 5: TEA CBC Mode Basic
   --  ========================================================================
   declare
      PT   : constant TEA_Block_Array (1 .. 3) := [[1, 1], [2, 2], [1, 1]];
      CT1  : TEA_Block_Array (1 .. 3);
      CT2  : TEA_Block_Array (1 .. 3);
      Key  : constant TEA_Key := [15, 25, 35, 45];
      IV_1 : constant TEA_Block := [99, 99];
      IV_2 : constant TEA_Block := [88, 88];
   begin
      Put_Line ("TEST 5 — TEA CBC Mode Basic");
      CT1 := TEA_Encrypt_CBC (PT, Key, IV_1);
      Check ("5.1 CBC is perfectly reversible", TEA_Decrypt_CBC (CT1, Key, IV_1) = PT);
      
      --  CBC property: identical plaintext blocks do NOT map to identical ciphertext blocks
      Check ("5.2 Identical PT blocks map to DIFF CT blocks in CBC", CT1 (1) /= CT1 (3));
      
      CT2 := TEA_Encrypt_CBC (PT, Key, IV_2);
      Check ("5.3 Different IV changes entire ciphertext output", CT1 /= CT2);
   end;

   --  ========================================================================
   --  TEST 6: TEA CBC Avalanche Effect
   --  ========================================================================
   declare
      PT1 : constant TEA_Block_Array (1 .. 3) := [[0, 0], [0, 0], [0, 0]];
      PT2 : constant TEA_Block_Array (1 .. 3) := [[0, 1], [0, 0], [0, 0]]; -- 1 bit flipped
      CT1 : TEA_Block_Array (1 .. 3);
      CT2 : TEA_Block_Array (1 .. 3);
      Key : constant TEA_Key := [7, 7, 7, 7];
      IV  : constant TEA_Block := [5, 5];
   begin
      Put_Line ("TEST 6 — TEA CBC Avalanche Effect");
      CT1 := TEA_Encrypt_CBC (PT1, Key, IV);
      CT2 := TEA_Encrypt_CBC (PT2, Key, IV);
      
      Check ("6.1 Flipped bit changes Block 1", CT1 (1) /= CT2 (1));
      Check ("6.2 Flipped bit chains to Block 2", CT1 (2) /= CT2 (2));
      Check ("6.3 Flipped bit chains to Block 3", CT1 (3) /= CT2 (3));
   end;

   --  ========================================================================
   --  TEST 7: ARC4 Stream Reversibility
   --  ========================================================================
   declare
      Ctx    : ARC4_Context;
      K      : constant Byte_Array (1 .. 3) := [1, 2, 3];
      PT     : constant Byte_Array (1 .. 4) := [10, 20, 30, 40];
      CT     : Byte_Array (1 .. 4);
      PT_Out : Byte_Array (1 .. 4);
   begin
      Put_Line ("TEST 7 — ARC4 Stream Reversibility");
      ARC4_Init (Ctx, K);
      ARC4_Process (Ctx, PT, CT);
      Check ("7.1 Ciphertext differs from Plaintext", CT /= PT);
      
      ARC4_Init (Ctx, K);
      ARC4_Process (Ctx, CT, PT_Out);
      Check ("7.2 Decrypted text matches original Plaintext", PT_Out = PT);
      
      ARC4_Init (Ctx, [1, 2, 4]); -- wrong key
      ARC4_Process (Ctx, CT, PT_Out);
      Check ("7.3 Decrypting with wrong key yields garbage", PT_Out /= PT);
   end;

   --  ========================================================================
   --  TEST 8: ARC4 Continuous Stream State
   --  ========================================================================
   declare
      Ctx1, Ctx2 : ARC4_Context;
      K          : constant Byte_Array (1 .. 2) := [255, 128];
      PT_Full    : constant Byte_Array (1 .. 4) := [11, 22, 33, 44];
      CT_Full    : Byte_Array (1 .. 4);
      CT_Part1   : Byte_Array (1 .. 2);
      CT_Part2   : Byte_Array (3 .. 4);
   begin
      Put_Line ("TEST 8 — ARC4 Continuous Stream State");
      --  Encrypt in one pass
      ARC4_Init (Ctx1, K);
      ARC4_Process (Ctx1, PT_Full, CT_Full);
      
      --  Encrypt in two passes using same context
      ARC4_Init (Ctx2, K);
      ARC4_Process (Ctx2, PT_Full (1 .. 2), CT_Part1);
      ARC4_Process (Ctx2, PT_Full (3 .. 4), CT_Part2);
      
      Check ("8.1 Pass 1 matches full stream prefix", CT_Part1 (1) = CT_Full (1) and CT_Part1 (2) = CT_Full (2));
      Check ("8.2 Pass 2 matches full stream suffix", CT_Part2 (3) = CT_Full (3) and CT_Part2 (4) = CT_Full (4));
      Check ("8.3 Context indices advanced internally", Ctx2.I /= 0);
   end;

   --  ========================================================================
   --  TEST 9: ARC4 Invalid Key Constraints
   --  ========================================================================
   declare
      Ctx       : ARC4_Context;
      Empty_Key : constant Byte_Array (1 .. 0) := [others => 0];
      Long_Key  : constant Byte_Array (1 .. 257) := [others => 0];
      Thrown    : Boolean;
   begin
      Put_Line ("TEST 9 — ARC4 Invalid Key Constraints");
      Thrown := False;
      begin
         ARC4_Init (Ctx, Empty_Key);
      exception
         when Invalid_Key_Length => Thrown := True;
      end;
      Check ("9.1 Empty key raises exception", Thrown);
      
      Thrown := False;
      begin
         ARC4_Init (Ctx, Long_Key);
      exception
         when Invalid_Key_Length => Thrown := True;
      end;
      Check ("9.2 Oversized (>256) key raises exception", Thrown);
      
      --  Test valid key bound
      Thrown := False;
      begin
         ARC4_Init (Ctx, [1 .. 256 => 1]);
      exception
         when Invalid_Key_Length => Thrown := True;
      end;
      Check ("9.3 Max sized (256) key successfully initializes", not Thrown);
   end;

   --  ========================================================================
   --  TEST 10: ARC4 Input Size Validation
   --  ========================================================================
   declare
      Ctx         : ARC4_Context;
      In_B        : constant Byte_Array (1 .. 2) := [1, 2];
      Out_B_Short : Byte_Array (1 .. 1);
      Out_B_Long  : Byte_Array (1 .. 3);
      Out_B_Ok    : Byte_Array (1 .. 2);
      Thrown      : Boolean;
   begin
      Put_Line ("TEST 10 — ARC4 Input Size Validation");
      ARC4_Init (Ctx, [1 .. 1 => 42]); -- Valid key setup
      
      Thrown := False;
      begin
         ARC4_Process (Ctx, In_B, Out_B_Short);
      exception
         when Invalid_Input_Size => Thrown := True;
      end;
      Check ("10.1 Short output buffer raises exception", Thrown);

      Thrown := False;
      begin
         ARC4_Process (Ctx, In_B, Out_B_Long);
      exception
         when Invalid_Input_Size => Thrown := True;
      end;
      Check ("10.2 Long output buffer raises exception", Thrown);

      Thrown := False;
      begin
         ARC4_Process (Ctx, In_B, Out_B_Ok);
      exception
         when Invalid_Input_Size => Thrown := True;
      end;
      Check ("10.3 Exact matched bounds succeed", not Thrown);
   end;

   --  ========================================================================
   --  TEST 11: TEA Mode Interoperability Checks
   --  ========================================================================
   declare
      PT     : constant TEA_Block_Array (1 .. 2) := [[1, 2], [3, 4]];
      Key    : constant TEA_Key := [11, 22, 33, 44];
      IV     : constant TEA_Block := [99, 99];
      CT_ECB : constant TEA_Block_Array := TEA_Encrypt_ECB (PT, Key);
      CT_CBC : constant TEA_Block_Array := TEA_Encrypt_CBC (PT, Key, IV);
   begin
      Put_Line ("TEST 11 — TEA Mode Interoperability Checks");
      Check ("11.1 ECB and CBC produce vastly different ciphertexts", CT_ECB /= CT_CBC);
      
      Check ("11.2 Decrypting CBC ciphertext as ECB yields garbage", TEA_Decrypt_ECB (CT_CBC, Key) /= PT);
      
      Check ("11.3 Decrypting ECB ciphertext as CBC yields garbage", TEA_Decrypt_CBC (CT_ECB, Key, IV) /= PT);
   end;

   --  ========================================================================
   --  TEST 12: XOR Blocks Helper Validator
   --  ========================================================================
   declare
      B1 : constant TEA_Block := [16#AAAA_AAAA#, 16#5555_5555#];
      B2 : constant TEA_Block := [16#5555_5555#, 16#AAAA_AAAA#];
      B0 : constant TEA_Block := [0, 0];
   begin
      Put_Line ("TEST 12 — XOR Blocks Helper Validator");
      Check ("12.1 XOR with self equals 0", XOR_Blocks (B1, B1) = B0);
      
      Check ("12.2 XOR with 0 equals self", XOR_Blocks (B1, B0) = B1);
      
      Check ("12.3 XOR cross bits evaluates fully", XOR_Blocks (B1, B2) = [16#FFFF_FFFF#, 16#FFFF_FFFF#]);
   end;

   --  ========================================================================
   --  TEST 13: ARC4 Edge Case - Zero Input
   --  ========================================================================
   declare
      Ctx       : ARC4_Context;
      Empty_In  : constant Byte_Array (1 .. 0) := [others => 0];
      Empty_Out : Byte_Array (1 .. 0);
      I_Prev, J_Prev : Byte;
   begin
      Put_Line ("TEST 13 — ARC4 Edge Case - Zero Input");
      ARC4_Init (Ctx, [1 .. 1 => 50]);
      I_Prev := Ctx.I;
      J_Prev := Ctx.J;
      
      --  Should not crash
      ARC4_Process (Ctx, Empty_In, Empty_Out);
      
      Check ("13.1 Processing empty array succeeds", Empty_Out'Length = 0);
      Check ("13.2 Context I does not advance", Ctx.I = I_Prev);
      Check ("13.3 Context J does not advance", Ctx.J = J_Prev);
   end;

   --  ========================================================================
   --  TEST SUMMARY
   --  ========================================================================
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
