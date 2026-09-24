-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with FNV_Hash; use FNV_Hash;
with Interfaces; use Interfaces;

procedure Tests is
   procedure Pass (Msg : String) is begin Put_Line("    PASS - " & Msg); end Pass;
begin
   Put_Line("Starting FNV Implementation Tests...");

   -- TEST 1: FNV-1 32bit Consistency
   Put_Line("TEST 1 - FNV-1 32bit Consistency");
   Assert (Hash_FNV1_32("a") /= Hash_FNV1_32("b"), "Same input produces different hash");
   Assert (Hash_FNV1_32("test") = Hash_FNV1_32("test"), "Identical inputs produced different results");
   Pass("Consistency verified");

   -- TEST 2: FNV-1a 32bit Consistency
   Put_Line("TEST 2 - FNV-1a 32bit Consistency");
   Assert (Hash_FNV1a_32("a") /= Hash_FNV1a_32("b"), "Same input produces different hash");
   Assert (Hash_FNV1a_32("test") = Hash_FNV1a_32("test"), "Identical inputs produced different results");
   Pass("Consistency verified");

   -- TEST 3: Empty Input Handling
   Put_Line("TEST 3 - Empty Input Handling");
   Assert (Hash_FNV1_32("") = FNV_Offset_Basis_32, "FNV-1 32 empty should equal basis");
   Assert (Hash_FNV1_64("") = FNV_Offset_Basis_64, "FNV-1 64 empty should equal basis");
   Pass("Empty input returns basis correctly");

   -- TEST 4: FNV-1 vs FNV-1a Divergence
   Put_Line("TEST 4 - Algorithm Variant Divergence");
   Assert (Hash_FNV1_32("abc") /= Hash_FNV1a_32("abc"), "FNV-1 and FNV-1a should produce different hashes");
   Pass("Variants produce unique hashes");

   -- TEST 5: 64-bit FNV-1 Integrity
   Put_Line("TEST 5 - FNV-1 64bit Integrity");
   declare
      H1 : constant Unsigned_64 := Hash_FNV1_64("Ada");
      H2 : constant Unsigned_64 := Hash_FNV1_64("Ada");
   begin
      Assert (H1 = H2, "64bit FNV-1 non-deterministic");
   end;
   Pass("Deterministic 64-bit FNV-1");

   -- TEST 6: 64-bit FNV-1a Integrity
   Put_Line("TEST 6 - FNV-1a 64bit Integrity");
   declare
      H1 : constant Unsigned_64 := Hash_FNV1a_64("Ada");
      H2 : constant Unsigned_64 := Hash_FNV1a_64("Ada");
   begin
      Assert (H1 = H2, "64bit FNV-1a non-deterministic");
   end;
   Pass("Deterministic 64-bit FNV-1a");

   -- TEST 7: Single Character Input
   Put_Line("TEST 7 - Single Character Input");
   Assert (Hash_FNV1_32("A") /= Hash_FNV1_32("B"), "Single char hashing fails");
   Pass("Single character differentiation verified");

   -- TEST 8: Long String Input
   Put_Line("TEST 8 - Long String Input");
   declare
      Long_Str : String(1..1000) := (others => 'x');
   begin
      Assert (Hash_FNV1_32(Long_Str) /= 0, "Hash result is zero (failure)");
   end;
   Pass("Long input processed successfully");

   -- TEST 9: Byte Order Consistency (Mathematical verification)
   Put_Line("TEST 9 - Mathematical ordering FNV-1");
   -- FNV-1: (Base * Prime) XOR Byte
   declare
      Basis : constant Unsigned_32 := FNV_Offset_Basis_32;
      Expected : Unsigned_32 := (Basis * FNV_Prime_32) xor 65; -- 'A' is 65
   begin
      Assert (Hash_FNV1_32("A") = Expected, "FNV-1 calculation order incorrect");
   end;
   Pass("FNV-1 algorithm order verified");

   -- TEST 10: Mathematical ordering FNV-1a
   Put_Line("TEST 10 - Mathematical ordering FNV-1a");
   -- FNV-1a: (Base XOR Byte) * Prime
   declare
      Basis : constant Unsigned_32 := FNV_Offset_Basis_32;
      Expected : Unsigned_32 := (Basis xor 65) * FNV_Prime_32;
   begin
      Assert (Hash_FNV1a_32("A") = Expected, "FNV-1a calculation order incorrect");
   end;
   Pass("FNV-1a algorithm order verified");

   -- TEST 11: Null Character Handling
   Put_Line("TEST 11 - Null Character Input");
   Assert (Hash_FNV1_32(Character'Val(0) & "") /= FNV_Offset_Basis_32, "Hash did not change after null byte");
   Pass("Null character handled");

   -- TEST 12: High ASCII Character Handling
   Put_Line("TEST 12 - High ASCII Character Input");
   Assert (Hash_FNV1_32(Character'Val(255) & "") /= FNV_Offset_Basis_32, "High ASCII ignored");
   Pass("High ASCII processed");

   -- TEST 13: Immutability Verification
   Put_Line("TEST 13 - Input Immutability");
   declare
      Input : String := "Hello";
      H1    : constant Unsigned_32 := Hash_FNV1_32(Input);
      H2    : constant Unsigned_32 := Hash_FNV1_32(Input);
   begin
      Assert (H1 = H2, "Input modified during hashing");
      Assert (Input = "Hello", "Input string was modified");
   end;
   Pass("Input immutability verified");

   Put_Line("All 13 tests passed successfully.");
end Tests;
