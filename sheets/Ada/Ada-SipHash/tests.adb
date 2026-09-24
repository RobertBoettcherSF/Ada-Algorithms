with Ada.Text_IO; use Ada.Text_IO;
with SipHash;     use SipHash;

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

   -- Standardized test keys
   K0 : constant Key_Type := [others => 0];
   K1 : constant Key_Type := [0 => 1, others => 0];
   K2 : constant Key_Type := [15 => 1, others => 0];

   -- Standardized test messages of various sizes
   M0 : constant Byte_Array (1 .. 0) := [others => 0];
   M1 : constant Byte_Array (0 .. 0) := [0 => 16#42#];
   M7 : constant Byte_Array (0 .. 6) := [others => 16#AB#];
   M8 : constant Byte_Array (0 .. 7) := [others => 16#AB#];
   M9 : constant Byte_Array (0 .. 8) := [others => 16#AB#];

begin
   -- TEST 1 — Hash_64 Determinism
   Put_Line ("TEST 1 — Hash_64 Determinism");
   Check ("1.1 Empty message is deterministic", Hash_64 (K0, M0) = Hash_64 (K0, M0));
   Check ("1.2 1-byte message is deterministic", Hash_64 (K0, M1) = Hash_64 (K0, M1));
   Check ("1.3 7-byte message is deterministic", Hash_64 (K1, M7) = Hash_64 (K1, M7));

   -- TEST 2 — Hash_128 Determinism
   Put_Line ("TEST 2 — Hash_128 Determinism");
   Check ("2.1 Empty message 128 is deterministic", Hash_128 (K0, M0) = Hash_128 (K0, M0));
   Check ("2.2 1-byte message Low half deterministic", Hash_128 (K1, M1).Low = Hash_128 (K1, M1).Low);
   Check ("2.3 8-byte message High half deterministic", Hash_128 (K2, M8).High = Hash_128 (K2, M8).High);

   -- TEST 3 — Avalanche Effect on Keys (64-bit)
   Put_Line ("TEST 3 — Avalanche on Keys (64-bit)");
   Check ("3.1 Output differs on K0 vs K1 (byte 0 changed)", Hash_64 (K0, M1) /= Hash_64 (K1, M1));
   Check ("3.2 Output differs on K0 vs K2 (byte 15 changed)", Hash_64 (K0, M1) /= Hash_64 (K2, M1));
   Check ("3.3 Output differs on K1 vs K2", Hash_64 (K1, M1) /= Hash_64 (K2, M1));

   -- TEST 4 — Avalanche Effect on Messages (64-bit)
   Put_Line ("TEST 4 — Avalanche on Messages (64-bit)");
   Check ("4.1 Output differs on length 7 vs 8", Hash_64 (K0, M7) /= Hash_64 (K0, M8));
   Check ("4.2 Output differs on length 8 vs 9", Hash_64 (K0, M8) /= Hash_64 (K0, M9));
   Check ("4.3 Output differs on length 7 vs 9", Hash_64 (K0, M7) /= Hash_64 (K0, M9));

   -- TEST 5 — Avalanche Effect on Keys (128-bit)
   Put_Line ("TEST 5 — Avalanche on Keys (128-bit)");
   Check ("5.1 Low differs on K0 vs K1", Hash_128 (K0, M1).Low /= Hash_128 (K1, M1).Low);
   Check ("5.2 High differs on K0 vs K2", Hash_128 (K0, M1).High /= Hash_128 (K2, M1).High);
   Check ("5.3 Low differs on K1 vs K2", Hash_128 (K1, M1).Low /= Hash_128 (K2, M1).Low);

   -- TEST 6 — Avalanche Effect on Messages (128-bit)
   Put_Line ("TEST 6 — Avalanche on Messages (128-bit)");
   Check ("6.1 Low differs on msg length 7 vs 8", Hash_128 (K0, M7).Low /= Hash_128 (K0, M8).Low);
   Check ("6.2 High differs on msg length 8 vs 9", Hash_128 (K0, M8).High /= Hash_128 (K0, M9).High);
   Check ("6.3 High differs on msg length 7 vs 9", Hash_128 (K0, M7).High /= Hash_128 (K0, M9).High);

   -- TEST 7 — Algorithm Variants by Round (64-bit)
   Put_Line ("TEST 7 — Round Configuration Variants (64-bit)");
   Check ("7.1 C=2,D=4 differs from C=4,D=8", Hash_64 (K0, M8, 2, 4) /= Hash_64 (K0, M8, 4, 8));
   Check ("7.2 C=2,D=4 differs from C=2,D=8", Hash_64 (K0, M8, 2, 4) /= Hash_64 (K0, M8, 2, 8));
   Check ("7.3 C=4,D=8 differs from C=2,D=8", Hash_64 (K0, M8, 4, 8) /= Hash_64 (K0, M8, 2, 8));

   -- TEST 8 — Algorithm Variants by Round (128-bit)
   Put_Line ("TEST 8 — Round Configuration Variants (128-bit)");
   Check ("8.1 Low C=2,D=4 differs from C=4,D=8", Hash_128 (K0, M8, 2, 4).Low /= Hash_128 (K0, M8, 4, 8).Low);
   Check ("8.2 High C=2,D=4 differs from C=2,D=8", Hash_128 (K0, M8, 2, 4).High /= Hash_128 (K0, M8, 2, 8).High);
   Check ("8.3 Low C=4,D=8 differs from C=2,D=8", Hash_128 (K0, M8, 4, 8).Low /= Hash_128 (K0, M8, 2, 8).Low);

   -- TEST 9 — Divergence between 64-bit and 128-bit modes
   Put_Line ("TEST 9 — Output Space Divergence");
   Check ("9.1 Hash_64 output is not Hash_128 Low", Hash_64 (K0, M8) /= Hash_128 (K0, M8).Low);
   Check ("9.2 Hash_64 output is not Hash_128 High", Hash_64 (K0, M8) /= Hash_128 (K0, M8).High);
   Check ("9.3 Hash_128 Low is not High", Hash_128 (K0, M8).Low /= Hash_128 (K0, M8).High);

   -- TEST 10 — Large Message Integrity
   Put_Line ("TEST 10 — Large Message Handling");
   declare
      M_Large : constant Byte_Array (1 .. 100) := [others => 5];
      M_Large_End_Mod : constant Byte_Array (1 .. 100) := [100 => 6, others => 5];
      M_Large_Start_Mod : constant Byte_Array (1 .. 100) := [1 => 6, others => 5];
   begin
      Check ("10.1 Large message deterministic", Hash_64 (K0, M_Large) = Hash_64 (K0, M_Large));
      Check ("10.2 Avalanche on last byte of large msg", Hash_64 (K0, M_Large) /= Hash_64 (K0, M_Large_End_Mod));
      Check ("10.3 Avalanche on first byte of large msg", Hash_64 (K0, M_Large) /= Hash_64 (K0, M_Large_Start_Mod));
   end;

   -- TEST 11 — Error Handling and Invariants
   Put_Line ("TEST 11 — Constraint Checks on Invalid Usage");
   declare
      Dummy_Key : constant Byte_Array (0 .. 10) := [others => 0];
      function Make_Bad_Key return Key_Type is
      begin
         pragma Warnings (Off);
         return Key_Type (Dummy_Key);
         pragma Warnings (On);
      end Make_Bad_Key;
   begin
      begin
         pragma Warnings (Off);
         if Hash_64 (K0, M0, C => 0) = 0 then
            null;
         end if;
         pragma Warnings (On);
         Check ("11.1 Zero compression rounds should raise Constraint_Error", False);
      exception
         when Constraint_Error =>
            Check ("11.1 Zero compression rounds should raise Constraint_Error", True);
      end;

      begin
         pragma Warnings (Off);
         if Hash_64 (K0, M0, D => 0) = 0 then
            null;
         end if;
         pragma Warnings (On);
         Check ("11.2 Zero finalization rounds should raise Constraint_Error", False);
      exception
         when Constraint_Error =>
            Check ("11.2 Zero finalization rounds should raise Constraint_Error", True);
      end;

      begin
         pragma Warnings (Off);
         if Hash_64 (Make_Bad_Key, M0) = 0 then
            null;
         end if;
         pragma Warnings (On);
         Check ("11.3 Invalid key length should raise Constraint_Error", False);
      exception
         when Constraint_Error =>
            Check ("11.3 Invalid key length should raise Constraint_Error", True);
      end;
   end;

   -- TEST 12 — Array Slices and Arbitrary Indexing
   Put_Line ("TEST 12 — Array Slices & Unaligned Indexing");
   declare
      Large_Buffer : constant Byte_Array (0 .. 31) := [others => 16#AB#];
      Slice_Msg    : constant Byte_Array := Large_Buffer (5 .. 12); -- 8 bytes long, non-zero indexed
   begin
      Check ("12.1 Sliced array equals statically defined bounds", Hash_64 (K0, M8) = Hash_64 (K0, Slice_Msg));
      Check ("12.2 Sliced 128-bit Low handles unaligned bounds", Hash_128 (K0, M8).Low = Hash_128 (K0, Slice_Msg).Low);
      Check ("12.3 Sliced 128-bit High handles unaligned bounds", Hash_128 (K0, M8).High = Hash_128 (K0, Slice_Msg).High);
   end;

   -- TEST 13 — Extreme Length Module 256 Edge Case
   Put_Line ("TEST 13 — High Bit Length Padding (256 bytes)");
   declare
      Msg_256 : constant Byte_Array (1 .. 256) := [others => 0];
   begin
      -- A 256-byte message length evaluates to 0 mod 256. Validates the padding byte doesn't overflow or fault.
      Check ("13.1 Hash 256-byte msg determinism", Hash_64 (K0, Msg_256) = Hash_64 (K0, Msg_256));
      Check ("13.2 Hash 256-byte 128-bit determinism", Hash_128 (K0, Msg_256).Low = Hash_128 (K0, Msg_256).Low);
      Check ("13.3 Output differs from 0-byte msg despite modulo", Hash_64 (K0, Msg_256) /= Hash_64 (K0, M0));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
