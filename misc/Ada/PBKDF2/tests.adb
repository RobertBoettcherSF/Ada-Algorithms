with Ada.Text_IO; use Ada.Text_IO;
with PBKDF2;      use PBKDF2;

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

   -- Helper: Easily format strings to byte arrays for concise testing
   function S2B (Str : String) return Byte_Array is
      Res : Byte_Array (1 .. Str'Length);
   begin
      for I in Str'Range loop
         Res (I - Str'First + 1) := Byte (Character'Pos (Str (I)));
      end loop;
      return Res;
   end S2B;

   -- =========================================================================
   -- Cryptographic Primitives (Mocks)
   -- For test isolation, we utilize trivial, deterministic mock functions
   -- rather than linking heavy external crypto modules like GNAT.SHA256.
   -- =========================================================================

   -- Mock Hash (simulating a 4-byte hash function)
   function Mock_Hash (Data : Byte_Array) return Byte_Array is
      Res : Byte_Array (1 .. 4) := [1, 2, 3, 4];
   begin
      for I in Data'Range loop
         Res (1 + (I mod 4)) := Res (1 + (I mod 4)) xor Data (I);
      end loop;
      return Res;
   end Mock_Hash;

   -- Mock PRF (simulating a 4-byte HMAC)
   function Mock_PRF (Key, Data : Byte_Array) return Byte_Array is
      Res   : Byte_Array (1 .. 4) := [16#AA#, 16#BB#, 16#CC#, 16#DD#];
      K_Sum : Byte := 0;
   begin
      for I in Key'Range loop
         K_Sum := K_Sum + Key (I);
      end loop;
      for I in Data'Range loop
         Res (1 + (I mod 4)) := Res (1 + (I mod 4)) xor (Data (I) + K_Sum);
      end loop;
      return Res;
   end Mock_PRF;

   -- Instantiating our algorithms
   package T_PBKDF1 is new PBKDF1_Algorithm (Hash_Length => 4, Hash => Mock_Hash);
   package T_PBKDF2 is new PBKDF2_Algorithm (Hash_Length => 4, PRF  => Mock_PRF);

   Empty_Data : constant Byte_Array (1 .. 0) := [];
begin
   Put_Line ("Starting PBKDF1 and PBKDF2 test suite...");
   Put_Line ("========================================");

   -- TEST 1 - PBKDF2 Length Correctness
   Put_Line ("TEST 1 - PBKDF2 Length Correctness");
   declare
      R1  : constant Byte_Array := T_PBKDF2.Derive (S2B("pass"), S2B("salt"), 1, 1);
      R4  : constant Byte_Array := T_PBKDF2.Derive (S2B("pass"), S2B("salt"), 1, 4);
      R10 : constant Byte_Array := T_PBKDF2.Derive (S2B("pass"), S2B("salt"), 1, 10);
   begin
      Check ("1.1 Partial block (1 byte) returned correctly", R1'Length = 1);
      Check ("1.2 Exact block size (4 bytes) returned correctly", R4'Length = 4);
      Check ("1.3 Spanning blocks (10 bytes) returned correctly", R10'Length = 10);
   end;

   -- TEST 2 - PBKDF2 Determinism
   Put_Line ("TEST 2 - PBKDF2 Determinism");
   declare
      R1 : constant Byte_Array := T_PBKDF2.Derive (S2B("pwd"), S2B("slt"), 10, 8);
      R2 : constant Byte_Array := T_PBKDF2.Derive (S2B("pwd"), S2B("slt"), 10, 8);
      R3 : constant Byte_Array := T_PBKDF2.Derive (S2B("pwd"), S2B("slt"), 10, 8);
   begin
      Check ("2.1 Deterministic output: Run 1 = Run 2", R1 = R2);
      Check ("2.2 Deterministic output: Run 2 = Run 3", R2 = R3);
      Check ("2.3 Deterministic output: Run 1 = Run 3", R1 = R3);
   end;

   -- TEST 3 - PBKDF2 Prefix Property
   Put_Line ("TEST 3 - PBKDF2 Prefix Property");
   declare
      R4  : constant Byte_Array := T_PBKDF2.Derive (S2B("key"), S2B("s"), 5, 4);
      R8  : constant Byte_Array := T_PBKDF2.Derive (S2B("key"), S2B("s"), 5, 8);
      R12 : constant Byte_Array := T_PBKDF2.Derive (S2B("key"), S2B("s"), 5, 12);
   begin
      Check ("3.1 Output R4 forms the prefix of output R8", R4 = R8 (1 .. 4));
      Check ("3.2 Output R8 forms the prefix of output R12", R8 = R12 (1 .. 8));
      Check ("3.3 Output R4 forms the prefix of output R12", R4 = R12 (1 .. 4));
   end;

   -- TEST 4 - PBKDF2 Password Sensitivity
   Put_Line ("TEST 4 - PBKDF2 Password Sensitivity");
   declare
      R1 : constant Byte_Array := T_PBKDF2.Derive (S2B("A"), S2B("s"), 2, 8);
      R2 : constant Byte_Array := T_PBKDF2.Derive (S2B("B"), S2B("s"), 2, 8);
      R3 : constant Byte_Array := T_PBKDF2.Derive (S2B("C"), S2B("s"), 2, 8);
   begin
      Check ("4.1 Variant password outputs diverge (A /= B)", R1 /= R2);
      Check ("4.2 Variant password outputs diverge (B /= C)", R2 /= R3);
      Check ("4.3 Variant password outputs diverge (A /= C)", R1 /= R3);
   end;

   -- TEST 5 - PBKDF2 Salt Sensitivity
   Put_Line ("TEST 5 - PBKDF2 Salt Sensitivity");
   declare
      R1 : constant Byte_Array := T_PBKDF2.Derive (S2B("p"), S2B("X"), 2, 8);
      R2 : constant Byte_Array := T_PBKDF2.Derive (S2B("p"), S2B("Y"), 2, 8);
      R3 : constant Byte_Array := T_PBKDF2.Derive (S2B("p"), S2B("Z"), 2, 8);
   begin
      Check ("5.1 Variant salt outputs diverge (X /= Y)", R1 /= R2);
      Check ("5.2 Variant salt outputs diverge (Y /= Z)", R2 /= R3);
      Check ("5.3 Variant salt outputs diverge (X /= Z)", R1 /= R3);
   end;

   -- TEST 6 - PBKDF2 Iteration Sensitivity
   Put_Line ("TEST 6 - PBKDF2 Iteration Sensitivity");
   declare
      R1 : constant Byte_Array := T_PBKDF2.Derive (S2B("p"), S2B("s"), 1, 8);
      R2 : constant Byte_Array := T_PBKDF2.Derive (S2B("p"), S2B("s"), 2, 8);
      R3 : constant Byte_Array := T_PBKDF2.Derive (S2B("p"), S2B("s"), 3, 8);
   begin
      Check ("6.1 Iteration depth modifies entropy (1 /= 2)", R1 /= R2);
      Check ("6.2 Iteration depth modifies entropy (2 /= 3)", R2 /= R3);
      Check ("6.3 Iteration depth modifies entropy (1 /= 3)", R1 /= R3);
   end;

   -- TEST 7 - PBKDF1 Length Correctness
   Put_Line ("TEST 7 - PBKDF1 Length Correctness");
   declare
      R1 : constant Byte_Array := T_PBKDF1.Derive (S2B("pass"), S2B("salt"), 1, 1);
      R2 : constant Byte_Array := T_PBKDF1.Derive (S2B("pass"), S2B("salt"), 1, 2);
      R4 : constant Byte_Array := T_PBKDF1.Derive (S2B("pass"), S2B("salt"), 1, 4);
   begin
      Check ("7.1 Request exactly 1 byte returns 1 byte", R1'Length = 1);
      Check ("7.2 Request exactly 2 bytes returns 2 bytes", R2'Length = 2);
      Check ("7.3 Request maximal hash length (4 bytes) works", R4'Length = 4);
   end;

   -- TEST 8 - PBKDF1 Determinism and Properties
   Put_Line ("TEST 8 - PBKDF1 Determinism and Properties");
   declare
      R4_A : constant Byte_Array := T_PBKDF1.Derive (S2B("k"), S2B("s"), 3, 4);
      R4_B : constant Byte_Array := T_PBKDF1.Derive (S2B("k"), S2B("s"), 3, 4);
      R2   : constant Byte_Array := T_PBKDF1.Derive (S2B("k"), S2B("s"), 3, 2);
   begin
      Check ("8.1 Run outputs identically configured requests", R4_A = R4_B);
      Check ("8.2 Output R2 correctly acts as prefix for R4", R2 = R4_A (1 .. 2));
      Check ("8.3 Iteration count significantly alters outcome", R4_A /= T_PBKDF1.Derive (S2B("k"), S2B("s"), 2, 4));
   end;

   -- TEST 9 - PBKDF1 Maximum Length Exception Validation
   Put_Line ("TEST 9 - PBKDF1 Maximum Length Exception Validation");
   declare
      Raised_1 : Boolean := False;
      Raised_2 : Boolean := False;
      Raised_3 : Boolean := False;
   begin
      begin
         declare
            Discard : Byte_Array := T_PBKDF1.Derive (S2B("k"), S2B("s"), 1, 5);
            pragma Unreferenced (Discard);
         begin
            null;
         end;
      exception
         when Derived_Key_Too_Long => Raised_1 := True;
      end;

      begin
         declare
            Discard : Byte_Array := T_PBKDF1.Derive (S2B("k"), S2B("s"), 1, 10);
            pragma Unreferenced (Discard);
         begin
            null;
         end;
      exception
         when Derived_Key_Too_Long => Raised_2 := True;
      end;

      begin
         declare
            Discard : Byte_Array := T_PBKDF1.Derive (S2B("k"), S2B("s"), 1, 100);
            pragma Unreferenced (Discard);
         begin
            null;
         end;
      exception
         when Derived_Key_Too_Long => Raised_3 := True;
      end;

      Check ("9.1 Requesting 5 > Hash_Length(4) raises exception", Raised_1);
      Check ("9.2 Requesting 10 > Hash_Length(4) raises exception", Raised_2);
      Check ("9.3 Requesting 100 > Hash_Length(4) raises exception", Raised_3);
   end;

   -- TEST 10 - PBKDF2 Empty Inputs Handling
   Put_Line ("TEST 10 - PBKDF2 Empty Inputs Handling");
   declare
      R1 : constant Byte_Array := T_PBKDF2.Derive (Empty_Data, S2B("salt"), 1, 4);
      R2 : constant Byte_Array := T_PBKDF2.Derive (S2B("pass"), Empty_Data, 1, 4);
      R3 : constant Byte_Array := T_PBKDF2.Derive (Empty_Data, Empty_Data, 1, 4);
   begin
      Check ("10.1 Empty password gracefully executes", R1'Length = 4);
      Check ("10.2 Empty salt gracefully executes", R2'Length = 4);
      Check ("10.3 Empty password & salt gracefully execute", R3'Length = 4);
   end;

   -- TEST 11 - PBKDF1 Empty Inputs Handling
   Put_Line ("TEST 11 - PBKDF1 Empty Inputs Handling");
   declare
      R1 : constant Byte_Array := T_PBKDF1.Derive (Empty_Data, S2B("salt"), 1, 4);
      R2 : constant Byte_Array := T_PBKDF1.Derive (S2B("pass"), Empty_Data, 1, 4);
      R3 : constant Byte_Array := T_PBKDF1.Derive (Empty_Data, Empty_Data, 1, 4);
   begin
      Check ("11.1 Empty password gracefully executes", R1'Length = 4);
      Check ("11.2 Empty salt gracefully executes", R2'Length = 4);
      Check ("11.3 Empty password & salt gracefully execute", R3'Length = 4);
   end;

   -- TEST 12 - Internal Mechanics: To_Big_Endian
   Put_Line ("TEST 12 - Helper To_Big_Endian");
   declare
      B1     : constant Byte_Array := To_Big_Endian (1);
      B256   : constant Byte_Array := To_Big_Endian (256);
      B65537 : constant Byte_Array := To_Big_Endian (65537);
   begin
      Check ("12.1 Scalar value 1 encodes perfectly", B1 = [0, 0, 0, 1]);
      Check ("12.2 Scalar value 256 pushes correctly", B256 = [0, 0, 1, 0]);
      Check ("12.3 Scalar value 65537 encodes correctly", B65537 = [0, 1, 0, 1]);
   end;

   -- TEST 13 - Internal Mechanics: XOR Function
   Put_Line ("TEST 13 - Helper XOR");
   declare
      Zeros : constant Byte_Array (1 .. 4) := [0, 0, 0, 0];
      Ones  : constant Byte_Array (1 .. 4) := [255, 255, 255, 255];
      Mix1  : constant Byte_Array (1 .. 4) := [1, 2, 4, 8];
      Mix2  : constant Byte_Array (1 .. 4) := [254, 253, 251, 247];
   begin
      Check ("13.1 Zeros XOR Mix1 preserves identity", (Zeros xor Mix1) = Mix1);
      Check ("13.2 Ones XOR Mix1 yields bitwise complement", (Ones xor Mix1) = Mix2);
      Check ("13.3 Self XOR zeroes the entire vector", (Mix1 xor Mix1) = Zeros);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
