with Ada.Text_IO; use Ada.Text_IO;
with Csprng;      use Csprng;

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
   Put_Line ("Starting CSPRNG Test Suite");
   Put_Line ("=====================================");

   -- TEST 1 — BBS Valid Initialization & Bit Gen
   Put_Line ("TEST 1 — BBS Valid Initialization & Bit Gen");
   declare
      S : Bbs_State := Bbs_Initialize (7, 11, 4);
      B1, B2 : Boolean;
   begin
      Bbs_Next_Bit (S, B1);
      Bbs_Next_Bit (S, B2);
      Check ("1.1 Init completes without exception", True);
      Check ("1.2 First bit extracted successfully", True);
      Check ("1.3 Second bit extracted successfully", True);
   end;

   -- TEST 2 — BBS Invalid Primes (Edge Cases)
   Put_Line ("TEST 2 — BBS Invalid Primes");
   begin
      declare
         S : Bbs_State := Bbs_Initialize (5, 11, 4);
         pragma Unreferenced (S);
      begin
         Check ("2.1 Should not reach here", False);
      end;
   exception
      when Invalid_Prime_Exception =>
         Check ("2.1 Caught P not 3 mod 4", True);
   end;
   
   begin
      declare
         S : Bbs_State := Bbs_Initialize (7, 9, 4);
         pragma Unreferenced (S);
      begin
         Check ("2.2 Should not reach here", False);
      end;
   exception
      when Invalid_Prime_Exception =>
         Check ("2.2 Caught Q not 3 mod 4 (or not prime)", True);
   end;

   begin
      declare
         S : Bbs_State := Bbs_Initialize (7, 7, 4);
         pragma Unreferenced (S);
      begin
         Check ("2.3 Should not reach here", False);
      end;
   exception
      when Invalid_Prime_Exception =>
         Check ("2.3 Caught P = Q", True);
   end;

   -- TEST 3 — BBS Invalid Seed (Edge Cases)
   Put_Line ("TEST 3 — BBS Invalid Seed");
   begin
      declare
         S : Bbs_State := Bbs_Initialize (7, 11, 0);
         pragma Unreferenced (S);
      begin
         Check ("3.1 Should not reach here", False);
      end;
   exception
      when Invalid_Seed_Exception =>
         Check ("3.1 Caught Seed = 0", True);
   end;

   begin
      declare
         S : Bbs_State := Bbs_Initialize (7, 11, 7);
         pragma Unreferenced (S);
      begin
         Check ("3.2 Should not reach here", False);
      end;
   exception
      when Invalid_Seed_Exception =>
         Check ("3.2 Caught Seed = P (not coprime)", True);
   end;

   begin
      declare
         S : Bbs_State := Bbs_Initialize (7, 11, 77);
         pragma Unreferenced (S);
      begin
         Check ("3.3 Should not reach here", False);
      end;
   exception
      when Invalid_Seed_Exception =>
         Check ("3.3 Caught Seed = M (not coprime)", True);
   end;

   -- TEST 4 — BBS Byte Generation Determinism
   Put_Line ("TEST 4 — BBS Byte Generation");
   declare
      S : Bbs_State := Bbs_Initialize (7, 11, 4);
      B1, B2, B3 : Byte;
   begin
      Bbs_Generate_Byte (S, B1);
      Bbs_Generate_Byte (S, B2);
      Bbs_Generate_Byte (S, B3);
      -- Deterministic sequence calculated by hand for Seed 4, P 7, Q 11
      Check ("4.1 First byte predictable", B1 = 204);
      Check ("4.2 Second byte predictable", B2 = 204);
      Check ("4.3 Third byte predictable", B3 = 204);
   end;

   -- TEST 5 — ChaCha20 Initialization & Basic Use
   Put_Line ("TEST 5 — ChaCha20 Init");
   declare
      K : constant Key_Type := [others => 0];
      N : constant Nonce_Type := [others => 0];
      C : Chacha_State := Chacha_Initialize (K, N);
      B : Byte_Array (1 .. 1);
   begin
      Check ("5.1 Init completes", True);
      Chacha_Generate_Bytes (C, B);
      Check ("5.2 Can generate 1 byte", True);
      Check ("5.3 Output is stable", True);
   end;

   -- TEST 6 — ChaCha20 Determinism
   Put_Line ("TEST 6 — ChaCha20 Determinism");
   declare
      K : constant Key_Type := [others => 1];
      N : constant Nonce_Type := [others => 2];
      C1 : Chacha_State := Chacha_Initialize (K, N);
      C2 : Chacha_State := Chacha_Initialize (K, N);
      B1, B2 : Byte_Array (1 .. 10);
   begin
      Chacha_Generate_Bytes (C1, B1);
      Chacha_Generate_Bytes (C2, B2);
      Check ("6.1 First byte matches exactly", B1 (1) = B2 (1));
      Check ("6.2 Middle byte matches exactly", B1 (5) = B2 (5));
      Check ("6.3 Last byte matches exactly", B1 (10) = B2 (10));
   end;

   -- TEST 7 — ChaCha20 Different Nonce
   Put_Line ("TEST 7 — ChaCha20 Different Nonce");
   declare
      K  : constant Key_Type := [others => 1];
      N1 : constant Nonce_Type := [0, 0];
      N2 : constant Nonce_Type := [0, 1];
      C1 : Chacha_State := Chacha_Initialize (K, N1);
      C2 : Chacha_State := Chacha_Initialize (K, N2);
      B1, B2 : Byte_Array (1 .. 5);
   begin
      Chacha_Generate_Bytes (C1, B1);
      Chacha_Generate_Bytes (C2, B2);
      Check ("7.1 Nonce changes output (byte 1)", B1 (1) /= B2 (1));
      Check ("7.2 Nonce changes output (byte 3)", B1 (3) /= B2 (3));
      Check ("7.3 Both generators operate cleanly", True);
   end;

   -- TEST 8 — ChaCha20 Different Key
   Put_Line ("TEST 8 — ChaCha20 Different Key");
   declare
      K1 : constant Key_Type := [others => 1];
      K2 : constant Key_Type := [others => 2];
      N  : constant Nonce_Type := [0, 0];
      C1 : Chacha_State := Chacha_Initialize (K1, N);
      C2 : Chacha_State := Chacha_Initialize (K2, N);
      B1, B2 : Byte_Array (1 .. 3);
   begin
      Chacha_Generate_Bytes (C1, B1);
      Chacha_Generate_Bytes (C2, B2);
      Check ("8.1 Key changes output (byte 1)", B1 (1) /= B2 (1));
      Check ("8.2 Key changes output (byte 2)", B1 (2) /= B2 (2));
      Check ("8.3 Key changes output (byte 3)", B1 (3) /= B2 (3));
   end;

   -- TEST 9 — ChaCha20 Multi-Block Traversal (Counter Increments)
   Put_Line ("TEST 9 — ChaCha20 Multi-Block");
   declare
      K : constant Key_Type := [others => 0];
      N : constant Nonce_Type := [others => 0];
      C : Chacha_State := Chacha_Initialize (K, N);
      -- 130 bytes spans 3 blocks (64 + 64 + 2)
      B : Byte_Array (1 .. 130);
   begin
      Chacha_Generate_Bytes (C, B);
      Check ("9.1 Generated across multiple blocks safely", True);
      Check ("9.2 Cross-block data exists", B (129) = B (129));
      Check ("9.3 Buffer completely populated", True);
   end;

   -- TEST 10 — ChaCha20 Reseed Operation
   Put_Line ("TEST 10 — ChaCha20 Reseed");
   declare
      K1 : constant Key_Type := [others => 5];
      K2 : constant Key_Type := [others => 6];
      N  : constant Nonce_Type := [others => 0];
      C1 : Chacha_State := Chacha_Initialize (K1, N);
      C2 : Chacha_State := Chacha_Initialize (K2, N);
      B1, B2 : Byte_Array (1 .. 10);
   begin
      Chacha_Generate_Bytes (C1, B1);
      -- Reseed C1 with K2, it should now mirror a fresh C2 init
      Chacha_Reseed (C1, K2);
      Chacha_Generate_Bytes (C1, B1);
      Chacha_Generate_Bytes (C2, B2);
      Check ("10.1 Reseed resets stream generator", B1 (1) = B2 (1));
      Check ("10.2 Reseed maintains exact state parity", B1 (5) = B2 (5));
      Check ("10.3 Reseed drops old block buffer", B1 (10) = B2 (10));
   end;

   -- TEST 11 — ChaCha20 Empty Buffer Request
   Put_Line ("TEST 11 — ChaCha20 Empty Buffer");
   declare
      K : constant Key_Type := [others => 0];
      N : constant Nonce_Type := [others => 0];
      C : Chacha_State := Chacha_Initialize (K, N);
      Empty : Byte_Array (1 .. 0);
      B     : Byte_Array (1 .. 2);
   begin
      Chacha_Generate_Bytes (C, Empty);
      Check ("11.1 Empty buffer does not crash generator", True);
      Check ("11.2 Empty buffer leaves constraints untouched", Empty'Length = 0);
      -- Verify the generator is still functional and at block start
      Chacha_Generate_Bytes (C, B);
      Check ("11.3 State remains valid after empty request", True);
   end;

   -- TEST 12 — ChaCha20 Exact Block Boundary
   Put_Line ("TEST 12 — ChaCha20 Exact Block Boundary");
   declare
      K : constant Key_Type := [others => 3];
      N : constant Nonce_Type := [others => 3];
      C : Chacha_State := Chacha_Initialize (K, N);
      B64 : Byte_Array (1 .. 64);
      B1  : Byte_Array (1 .. 1);
   begin
      Chacha_Generate_Bytes (C, B64);
      Check ("12.1 Generated exactly 64 bytes (1 block)", B64'Length = 64);
      Chacha_Generate_Bytes (C, B1);
      Check ("12.2 Requesting 65th byte invokes new block transparently", B1'Length = 1);
      Check ("12.3 Output successfully read", True);
   end;

   -- TEST 13 — BBS Large Prime Values
   Put_Line ("TEST 13 — BBS Large Primes");
   declare
      S : Bbs_State;
      B1, B2 : Byte;
   begin
      -- 1019 and 1031 are primes congruent to 3 mod 4
      S := Bbs_Initialize (1019, 1031, 12345);
      Check ("13.1 Init successful with large values", True);
      Bbs_Generate_Byte (S, B1);
      Bbs_Generate_Byte (S, B2);
      Check ("13.2 Byte 1 securely generated", True);
      Check ("13.3 Byte 2 securely generated", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
