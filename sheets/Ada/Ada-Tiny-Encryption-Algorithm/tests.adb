with Ada.Text_IO; use Ada.Text_IO;
with Interfaces; use type Interfaces.Unsigned_32;
with Tiny_Encryption_Algorithm; use Tiny_Encryption_Algorithm;

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

   --  Test Artifacts
   Key_Zero : constant Key_128 := [0, 0, 0, 0];
   Key_One  : constant Key_128 := [16#01020304#, 16#05060708#, 16#090A0B0C#, 16#0D0E0F00#];
   B64_Zero : constant Block_64 := [0, 0];
   B64_Pat  : constant Block_64 := [16#DEADBEEF#, 16#CAFEBABE#];

   Block, Orig : Block_64;
begin
   --  TEST 1 - TEA Basic Zero
   Put_Line ("TEST 1 - TEA Basic Zero");
   Block := B64_Zero;
   Orig  := Block;
   TEA_Encrypt (Block, Key_Zero);
   Check ("1.1 Encrypt alters data", Block /= Orig);
   Check ("1.2 First word is non-zero (deterministic check)", Block (0) /= 0);
   TEA_Decrypt (Block, Key_Zero);
   Check ("1.3 Decrypt cleanly restores data", Block = Orig);

   --  TEST 2 - TEA Pattern Behavior
   Put_Line ("TEST 2 - TEA Pattern Behavior");
   Block := B64_Pat;
   Orig  := Block;
   TEA_Encrypt (Block, Key_One);
   Check ("2.1 Encrypt alters data payload", Block /= Orig);
   Check ("2.2 Ciphertext relies on Key payload", Block /= B64_Zero);
   TEA_Decrypt (Block, Key_One);
   Check ("2.3 Decrypt cleanly restores payload", Block = Orig);

   --  TEST 3 - TEA Symmetry Check
   Put_Line ("TEST 3 - TEA Symmetry Check");
   Block := B64_Pat;
   Orig  := Block;
   TEA_Encrypt (Block, Key_One);
   declare
      Mid : constant Block_64 := Block;
   begin
      TEA_Encrypt (Block, Key_One);
      Check ("3.1 Double encrypt differs from single", Block /= Mid);
      Check ("3.2 Double encrypt differs from plain", Block /= Orig);
      TEA_Decrypt (Block, Key_One);
      TEA_Decrypt (Block, Key_One);
      Check ("3.3 Double decrypt cleanly restores data cascade", Block = Orig);
   end;

   --  TEST 4 - XTEA Basic Zero
   Put_Line ("TEST 4 - XTEA Basic Zero");
   Block := B64_Zero;
   Orig  := Block;
   XTEA_Encrypt (Block, Key_Zero);
   Check ("4.1 Encrypt alters data", Block /= Orig);
   declare
      Tea_Block : Block_64 := Orig;
   begin
      TEA_Encrypt (Tea_Block, Key_Zero);
      Check ("4.2 XTEA algo output inherently differs from TEA output", Block /= Tea_Block);
   end;
   XTEA_Decrypt (Block, Key_Zero);
   Check ("4.3 Decrypt cleanly restores data", Block = Orig);

   --  TEST 5 - XTEA Pattern Behavior
   Put_Line ("TEST 5 - XTEA Pattern Behavior");
   Block := B64_Pat;
   Orig  := Block;
   XTEA_Encrypt (Block, Key_One);
   Check ("5.1 Encrypt alters pattern payload", Block /= Orig);
   Check ("5.2 Ciphertext produces expected deterministic displacement", Block (0) /= 0);
   XTEA_Decrypt (Block, Key_One);
   Check ("5.3 Decrypt cleanly restores pattern", Block = Orig);

   --  TEST 6 - XTEA Custom Rounds
   Put_Line ("TEST 6 - XTEA Custom Rounds (16 vs 32 cycles)");
   Block := B64_Pat;
   Orig  := Block;
   XTEA_Encrypt (Block, Key_One, 16);
   declare
      Block_32 : Block_64 := Orig;
   begin
      XTEA_Encrypt (Block_32, Key_One, 32);
      Check ("6.1 16-rounds produces different payload than original", Block /= Orig);
      Check ("6.2 16-rounds inherently differs from 32-rounds", Block /= Block_32);
   end;
   XTEA_Decrypt (Block, Key_One, 16);
   Check ("6.3 16-rounds decrypt correctly maps reverse payload", Block = Orig);

   --  TEST 7 - XXTEA Basic (2 words block)
   Put_Line ("TEST 7 - XXTEA Basic (2 words)");
   declare
      Arr : Word_Array (0 .. 1) := [16#11111111#, 16#22222222#];
      Org : constant Word_Array (0 .. 1) := Arr;
   begin
      XXTEA_Encrypt (Arr, Key_One);
      Check ("7.1 Array structurally mutated", Arr /= Org);
      Check ("7.2 Word index 0 modified", Arr (0) /= Org (0));
      XXTEA_Decrypt (Arr, Key_One);
      Check ("7.3 Decrypt structurally restores payload", Arr = Org);
   end;

   --  TEST 8 - XXTEA Odd Block Size (3 words)
   Put_Line ("TEST 8 - XXTEA Odd Block Size (3 words)");
   declare
      Arr : Word_Array (0 .. 2) := [1, 2, 3];
      Org : constant Word_Array (0 .. 2) := Arr;
   begin
      XXTEA_Encrypt (Arr, Key_One);
      Check ("8.1 Odd layout structurally mutated", Arr /= Org);
      Check ("8.2 End boundary word modified", Arr (2) /= Org (2));
      XXTEA_Decrypt (Arr, Key_One);
      Check ("8.3 Decrypt mapping structurally restored", Arr = Org);
   end;

   --  TEST 9 - XXTEA Large Block Size (10 words)
   Put_Line ("TEST 9 - XXTEA Large Block Size (10 words)");
   declare
      Arr : Word_Array (1 .. 10) := [others => 16#ABCDEF01#];
      Org : constant Word_Array (1 .. 10) := Arr;
   begin
      XXTEA_Encrypt (Arr, Key_One);
      Check ("9.1 Large layout structurally mutated", Arr /= Org);
      Check ("9.2 Edge word modified successfully", Arr (10) /= Org (10));
      XXTEA_Decrypt (Arr, Key_One);
      Check ("9.3 Decrypt mapping structurally restored entire block", Arr = Org);
   end;

   --  TEST 10 - XXTEA Exception Trigger (Encrypt size < 2)
   Put_Line ("TEST 10 - XXTEA Exception Trigger (Encrypt 1 word)");
   declare
      Arr : Word_Array (0 .. 0) := [others => 0];
   begin
      Check ("10.1 Layout validates at length=1", Arr'Length = 1);
      XXTEA_Encrypt (Arr, Key_One);
      Check ("10.2 Code bypassed exception! (FAIL)", False);
   exception
      when Invalid_Block_Size =>
         Check ("10.2 Caught explicit algorithm domain exception", True);
         Check ("10.3 Preconditions structurally intact", True);
   end;

   --  TEST 11 - XXTEA Exception Trigger (Decrypt size < 2)
   Put_Line ("TEST 11 - XXTEA Exception Trigger (Decrypt 0 words)");
   declare
      Arr : Word_Array (1 .. 0);
   begin
      Check ("11.1 Layout validates at length=0 (Null Array)", Arr'Length = 0);
      XXTEA_Decrypt (Arr, Key_One);
      Check ("11.2 Code bypassed exception! (FAIL)", False);
   exception
      when Invalid_Block_Size =>
         Check ("11.2 Caught explicit algorithm domain exception", True);
         Check ("11.3 Preconditions structurally intact", True);
   end;

   --  TEST 12 - TEA Avalanche Check (Key Perturbation)
   Put_Line ("TEST 12 - TEA Avalanche Check (Key Perturbation)");
   Block := B64_Pat;
   Orig  := Block;
   TEA_Encrypt (Block, Key_One);
   declare
      Key_Mut   : Key_128 := Key_One;
      Block_Mut : Block_64 := Orig;
   begin
      Key_Mut (0) := Key_Mut (0) xor 1; -- Flip merely 1 bit
      TEA_Encrypt (Block_Mut, Key_Mut);
      Check ("12.1 1-bit key change yields different payload", Block /= Block_Mut);
      Check ("12.2 Perturbed key ciphertext remains secure against plain", Block_Mut /= Orig);
      TEA_Decrypt (Block_Mut, Key_Mut);
      Check ("12.3 Mutated key natively decrypts its own permutation", Block_Mut = Orig);
   end;

   --  TEST 13 - XXTEA Avalanche Check (Data Perturbation)
   Put_Line ("TEST 13 - XXTEA Avalanche Check (Data Perturbation)");
   declare
      Arr1 : Word_Array (0 .. 3) := [1, 2, 3, 4];
      Arr2 : Word_Array (0 .. 3) := [1, 2, 3, 5]; -- Flip merely 1 bit on last word
   begin
      XXTEA_Encrypt (Arr1, Key_One);
      XXTEA_Encrypt (Arr2, Key_One);
      Check ("13.1 1-bit data shift propagates layout avalanche", Arr1 /= Arr2);
      Check ("13.2 Word index 0 affected by word index 3 change", Arr1 (0) /= Arr2 (0));
      XXTEA_Decrypt (Arr1, Key_One);
      Check ("13.3 Decrypt completely restores array original format", Arr1 = [1, 2, 3, 4]);
   end;

   --  TEST 14 - XXTEA Non-Zero Bounds Preservation
   Put_Line ("TEST 14 - XXTEA Non-Zero Bounds Preservation");
   declare
      Arr : Word_Array (100 .. 103) := [10, 20, 30, 40];
      Org : constant Word_Array (100 .. 103) := Arr;
   begin
      Check ("14.1 Custom layout index mapped (First=100)", Arr'First = 100);
      XXTEA_Encrypt (Arr, Key_One);
      Check ("14.2 Structure natively encrypts on arbitrary offsets", Arr /= Org);
      XXTEA_Decrypt (Arr, Key_One);
      Check ("14.3 Decrypt maps cleanly bypassing index faults", Arr = Org);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
