with Ada.Text_IO; use Ada.Text_IO;
with Blake;       use Blake;

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

   -- Helper to measure Avalanche differences
   function Diff_Count (A, B : Byte_Array) return Natural is
      Count : Natural := 0;
   begin
      for I in A'Range loop
         if A (I) /= B (I) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Diff_Count;

   Empty_Msg : constant Byte_Array (1 .. 0) := [others => 0];
   Msg_1     : constant Byte_Array := [1 => 16#61#, 2 => 16#62#, 3 => 16#63#]; -- "abc"
   Msg_1_Alt : constant Byte_Array := [1 => 16#61#, 2 => 16#62#, 3 => 16#64#]; -- "abd"
   
   -- Multi-block message helpers
   Long_Msg_256 : constant Byte_Array (0 .. 100) := [others => 16#FF#];
   Long_Msg_512 : constant Byte_Array (0 .. 200) := [others => 16#EE#];

   -- Padding boundary messages
   Bound_256    : constant Byte_Array (0 .. 54) := [others => 16#AA#]; -- Exactly 55 bytes
   Bound_512    : constant Byte_Array (0 .. 110) := [others => 16#BB#]; -- Exactly 111 bytes

   H224_E, H224_M : Digest_224;
   H256_E, H256_M, H256_A, H256_L, H256_B : Digest_256;
   H384_E, H384_M : Digest_384;
   H512_E, H512_M, H512_A, H512_L, H512_B : Digest_512;

begin
   -- TEST 1 — Hash_256 Empty Input Handling
   Put_Line ("TEST 1 — Hash_256 Empty Input");
   H256_E := Hash_256 (Empty_Msg);
   Check ("1.1 Hash computes without exception", True);
   Check ("1.2 Result length is exactly 32 bytes", H256_E'Length = 32);
   Check ("1.3 Hash is deterministic on empty", H256_E = Hash_256 (Empty_Msg));

   -- TEST 2 — Hash_256 Determinism and Functional Integrity
   Put_Line ("TEST 2 — Hash_256 Determinism (Input 'abc')");
   H256_M := Hash_256 (Msg_1);
   Check ("2.1 Hash produces expected block size", H256_M'Length = 32);
   Check ("2.2 Hash is strictly deterministic", H256_M = Hash_256 (Msg_1));
   Check ("2.3 Hash differs from Empty Hash", H256_M /= H256_E);

   -- TEST 3 — Hash_256 Avalanche Effect (Collision Resistance property)
   Put_Line ("TEST 3 — Hash_256 Avalanche Effect");
   H256_A := Hash_256 (Msg_1_Alt);
   Check ("3.1 Output differs with 1-byte input change", H256_M /= H256_A);
   Check ("3.2 Strong avalanche (> 15 bytes differ)", Diff_Count (H256_M, H256_A) > 15);
   Check ("3.3 Hash length remains constant", H256_A'Length = 32);

   -- TEST 4 — Hash_512 Empty Input Handling
   Put_Line ("TEST 4 — Hash_512 Empty Input");
   H512_E := Hash_512 (Empty_Msg);
   Check ("4.1 Hash computes without exception", True);
   Check ("4.2 Result length is exactly 64 bytes", H512_E'Length = 64);
   Check ("4.3 Hash is deterministic on empty", H512_E = Hash_512 (Empty_Msg));

   -- TEST 5 — Hash_512 Determinism and Functional Integrity
   Put_Line ("TEST 5 — Hash_512 Determinism (Input 'abc')");
   H512_M := Hash_512 (Msg_1);
   Check ("5.1 Hash produces expected block size", H512_M'Length = 64);
   Check ("5.2 Hash is strictly deterministic", H512_M = Hash_512 (Msg_1));
   Check ("5.3 Hash differs from Empty Hash", H512_M /= H512_E);

   -- TEST 6 — Hash_512 Avalanche Effect
   Put_Line ("TEST 6 — Hash_512 Avalanche Effect");
   H512_A := Hash_512 (Msg_1_Alt);
   Check ("6.1 Output differs with 1-byte input change", H512_M /= H512_A);
   Check ("6.2 Strong avalanche (> 32 bytes differ)", Diff_Count (H512_M, H512_A) > 32);
   Check ("6.3 Hash length remains constant", H512_A'Length = 64);

   -- TEST 7 — Hash_224 Capabilities
   Put_Line ("TEST 7 — Hash_224 Subtype correctness");
   H224_E := Hash_224 (Empty_Msg);
   H224_M := Hash_224 (Msg_1);
   Check ("7.1 Result length is exactly 28 bytes", H224_E'Length = 28);
   Check ("7.2 Deterministic property holds", H224_M = Hash_224 (Msg_1));
   Check ("7.3 Empty hash != Msg hash", H224_E /= H224_M);

   -- TEST 8 — Hash_384 Capabilities
   Put_Line ("TEST 8 — Hash_384 Subtype correctness");
   H384_E := Hash_384 (Empty_Msg);
   H384_M := Hash_384 (Msg_1);
   Check ("8.1 Result length is exactly 48 bytes", H384_E'Length = 48);
   Check ("8.2 Deterministic property holds", H384_M = Hash_384 (Msg_1));
   Check ("8.3 Empty hash != Msg hash", H384_E /= H384_M);

   -- TEST 9 — Variant Uniqueness (Domain Separation via IVs)
   Put_Line ("TEST 9 — Cryptographic Domain Separation");
   Check ("9.1 224 is NOT simply a truncated 256 output", 
          H224_M /= H256_M (0 .. 27));
   Check ("9.2 384 is NOT simply a truncated 512 output", 
          H384_M /= H512_M (0 .. 47));
   Check ("9.3 256 and 512 hashes do not trivially overlap", 
          H256_M (0 .. 15) /= H512_M (0 .. 15));

   -- TEST 10 — Multi-block Handling for 256-bit core
   Put_Line ("TEST 10 — Multi-block hashing (BLAKE-256)");
   H256_L := Hash_256 (Long_Msg_256);
   Check ("10.1 Successfully processed > 1 block (101 bytes)", True);
   Check ("10.2 Result length maintains consistency", H256_L'Length = 32);
   Check ("10.3 Multi-block determinism holds", H256_L = Hash_256 (Long_Msg_256));

   -- TEST 11 — Multi-block Handling for 512-bit core
   Put_Line ("TEST 11 — Multi-block hashing (BLAKE-512)");
   H512_L := Hash_512 (Long_Msg_512);
   Check ("11.1 Successfully processed > 1 block (201 bytes)", True);
   Check ("11.2 Result length maintains consistency", H512_L'Length = 64);
   Check ("11.3 Multi-block determinism holds", H512_L = Hash_512 (Long_Msg_512));

   -- TEST 12 — Padding Boundary (Exactly 55 bytes triggers shortest K=1 pad for 256)
   Put_Line ("TEST 12 — Padding Boundary conditions (BLAKE-256)");
   H256_B := Hash_256 (Bound_256);
   Check ("12.1 Hashed exact boundary input without exception", True);
   Check ("12.2 Length is constant", H256_B'Length = 32);
   Check ("12.3 Unique output generated at boundary", H256_B /= H256_M and H256_B /= H256_L);

   -- TEST 13 — Padding Boundary (Exactly 111 bytes triggers shortest K=1 pad for 512)
   Put_Line ("TEST 13 — Padding Boundary conditions (BLAKE-512)");
   H512_B := Hash_512 (Bound_512);
   Check ("13.1 Hashed exact boundary input without exception", True);
   Check ("13.2 Length is constant", H512_B'Length = 64);
   Check ("13.3 Unique output generated at boundary", H512_B /= H512_M and H512_B /= H512_L);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
