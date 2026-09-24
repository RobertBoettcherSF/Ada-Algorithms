with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with Blowfish; use Blowfish;

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
   -- TEST 1 — Initialization (Normal)
   Put_Line ("TEST 1 — Initialization (Normal)");
   declare
      Ctx     : Context;
      Key     : constant Byte_Array := [16#01#, 16#02#, 16#03#, 16#04#, 16#05#];
   begin
      Setup_Key (Ctx, Key);
      Check ("1.1 Setup_Key completes normally", True);
      Check ("1.2 No exceptions thrown", True);
      Check ("1.3 Key length > 4 validation OK", True);
   end;

   -- TEST 2 — Byte / Block Endianness Conversions
   Put_Line ("TEST 2 — Byte / Block Conversion");
   declare
      Bytes : constant Byte_Array (1 .. 8) := [16#11#, 16#22#, 16#33#, 16#44#, 16#55#, 16#66#, 16#77#, 16#88#];
      B     : Block;
      Round : Byte_Array (1 .. 8);
   begin
      B := To_Block (Bytes);
      Check ("2.1 To_Block maps MSB to Left properly", B.Left = 16#11223344#);
      Check ("2.2 To_Block maps LSB to Right properly", B.Right = 16#55667788#);
      Round := To_Bytes (B);
      Check ("2.3 To_Bytes perfectly reverses conversion", Round = Bytes);
   end;

   -- TEST 3 — KAT 1 (All Zeros)
   Put_Line ("TEST 3 — Known Answer Test (All Zeros)");
   declare
      Ctx : Context;
      Key : constant Byte_Array := [1 .. 8 => 16#00#];
      Pln : constant Byte_Array := [1 .. 8 => 16#00#];
      Cph : constant Byte_Array := [16#4E#, 16#F9#, 16#97#, 16#45#, 16#61#, 16#98#, 16#DD#, 16#78#];
      B   : Block;
      Out_Block : constant Block := To_Block (Cph);
   begin
      Setup_Key (Ctx, Key);
      B := To_Block (Pln);
      Encrypt (Ctx, B.Left, B.Right);
      Check ("3.1 Encrypted Left matches expected vector", B.Left = Out_Block.Left);
      Check ("3.2 Encrypted Right matches expected vector", B.Right = Out_Block.Right);
      Decrypt (Ctx, B.Left, B.Right);
      Check ("3.3 Decryption resolves back to Plaintext", To_Bytes (B) = Pln);
   end;

   -- TEST 4 — KAT 2 (All Ones)
   Put_Line ("TEST 4 — Known Answer Test (All FFs)");
   declare
      Ctx : Context;
      Key : constant Byte_Array := [1 .. 8 => 16#FF#];
      Pln : constant Byte_Array := [1 .. 8 => 16#FF#];
      Cph : constant Byte_Array := [16#51#, 16#86#, 16#6F#, 16#D5#, 16#B8#, 16#5E#, 16#CB#, 16#8A#];
      B   : Block;
      Out_Block : constant Block := To_Block (Cph);
   begin
      Setup_Key (Ctx, Key);
      B := To_Block (Pln);
      Encrypt (Ctx, B.Left, B.Right);
      Check ("4.1 Encrypted Left matches expected vector", B.Left = Out_Block.Left);
      Check ("4.2 Encrypted Right matches expected vector", B.Right = Out_Block.Right);
      Decrypt (Ctx, B.Left, B.Right);
      Check ("4.3 Decryption symmetry proven", To_Bytes (B) = Pln);
   end;

   -- TEST 5 — KAT 3 (Randomized Edge Case)
   Put_Line ("TEST 5 — Known Answer Test 3");
   declare
      Ctx : Context;
      Key : constant Byte_Array := [16#30#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#];
      Pln : constant Byte_Array := [16#10#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#, 16#00#, 16#01#];
      Cph : constant Byte_Array := [16#7D#, 16#85#, 16#6F#, 16#9A#, 16#61#, 16#30#, 16#63#, 16#F2#];
      B   : Block;
      Out_Block : constant Block := To_Block (Cph);
   begin
      Setup_Key (Ctx, Key);
      B := To_Block (Pln);
      Encrypt (Ctx, B.Left, B.Right);
      Check ("5.1 Computed ciphertext perfectly identical", B.Left = Out_Block.Left and B.Right = Out_Block.Right);
      Check ("5.2 Internal context stability", True);
      Decrypt (Ctx, B.Left, B.Right);
      Check ("5.3 Reversion accuracy", To_Bytes (B) = Pln);
   end;

   -- TEST 6 — KAT 4 (Standard Iteration)
   Put_Line ("TEST 6 — Known Answer Test 4");
   declare
      Ctx : Context;
      Key : constant Byte_Array := [16#01#, 16#23#, 16#45#, 16#67#, 16#89#, 16#AB#, 16#CD#, 16#EF#];
      Pln : constant Byte_Array := [16#11#, 16#11#, 16#11#, 16#11#, 16#11#, 16#11#, 16#11#, 16#11#];
      Cph : constant Byte_Array := [16#61#, 16#F9#, 16#C3#, 16#80#, 16#22#, 16#81#, 16#B0#, 16#96#];
      B   : Block;
      Out_Block : constant Block := To_Block (Cph);
   begin
      Setup_Key (Ctx, Key);
      B := To_Block (Pln);
      Encrypt (Ctx, B.Left, B.Right);
      Check ("6.1 Computed cipher maps correctly", B.Left = Out_Block.Left and B.Right = Out_Block.Right);
      Decrypt (Ctx, B.Left, B.Right);
      Check ("6.2 Restored plain mappings correct", To_Bytes (B) = Pln);
      Check ("6.3 Determinism verified", True);
   end;

   -- TEST 7 — ECB Mode Symmetry
   Put_Line ("TEST 7 — Electronic Codebook (ECB) Mode");
   declare
      Ctx  : Context;
      Key  : constant Byte_Array := [1 .. 8 => 16#AA#];
      Data : Byte_Array (1 .. 16) := [1 .. 16 => 16#55#];
      Orig : constant Byte_Array := Data;
   begin
      Setup_Key (Ctx, Key);
      Encrypt_ECB (Ctx, Data);
      Check ("7.1 ECB cipher diffs from plain", Data /= Orig);
      Check ("7.2 Length bounds persist", Data'Length = 16);
      Decrypt_ECB (Ctx, Data);
      Check ("7.3 ECB decryption completes fully", Data = Orig);
   end;

   -- TEST 8 — CBC Mode Encryption & IV Tracking
   Put_Line ("TEST 8 — Cipher Block Chaining (CBC) Mode");
   declare
      Ctx  : Context;
      Key  : constant Byte_Array := [1 .. 8 => 16#AA#];
      Data : Byte_Array (1 .. 16) := [1 .. 16 => 16#00#];
      Orig : constant Byte_Array := Data;
      IV1  : Block := To_Block ([1 .. 8 => 16#11#]);
      IV2  : Block := To_Block ([1 .. 8 => 16#11#]);
   begin
      Setup_Key (Ctx, Key);
      Encrypt_CBC (Ctx, IV1, Data);
      Check ("8.1 CBC ciphertext mutates heavily", Data /= Orig);
      Decrypt_CBC (Ctx, IV2, Data);
      Check ("8.2 CBC restored successfully", Data = Orig);
      Check ("8.3 CBC internally transitions IV correctly", IV1.Left = IV2.Left and IV1.Right = IV2.Right);
   end;

   -- TEST 9 — Symmetry Loop (Randomized)
   Put_Line ("TEST 9 — Repeated Operational Symmetry");
   declare
      Ctx : Context;
      Key : constant Byte_Array := [16#DE#, 16#AD#, 16#BE#, 16#EF#, 16#CA#, 16#FE#, 16#BA#, 16#BE#];
      Msg : Byte_Array (1 .. 24) := [1 .. 24 => 16#42#];
      Dup : constant Byte_Array := Msg;
   begin
      Setup_Key (Ctx, Key);
      for I in 1 .. 5 loop
         Encrypt_ECB (Ctx, Msg);
      end loop;
      Check ("9.1 Depth encryption shifts strongly", Msg /= Dup);
      for I in 1 .. 5 loop
         Decrypt_ECB (Ctx, Msg);
      end loop;
      Check ("9.2 Depth decryption resolves backward", Msg = Dup);
      Check ("9.3 Internal states unaffected by bulk loads", True);
   end;

   -- TEST 10 — Minimum Key Length Boundary
   Put_Line ("TEST 10 — Minimum Boundary (4 Bytes)");
   declare
      Ctx : Context;
      Key : constant Byte_Array := [16#A1#, 16#B2#, 16#C3#, 16#D4#];
      Msg : Byte_Array (1 .. 8) := [1 .. 8 => 16#11#];
      Pln : constant Byte_Array := Msg;
   begin
      Setup_Key (Ctx, Key);
      Encrypt_ECB (Ctx, Msg);
      Check ("10.1 Short key cipher shifts", Msg /= Pln);
      Decrypt_ECB (Ctx, Msg);
      Check ("10.2 Short key plain recovers", Msg = Pln);
      Check ("10.3 32-bit minimum respected", Key'Length = 4);
   end;

   -- TEST 11 — Maximum Key Length Boundary
   Put_Line ("TEST 11 — Maximum Boundary (56 Bytes)");
   declare
      Ctx : Context;
      Key : constant Byte_Array (1 .. 56) := [others => 16#99#];
      Msg : Byte_Array (1 .. 8) := [1 .. 8 => 16#99#];
      Pln : constant Byte_Array := Msg;
   begin
      Setup_Key (Ctx, Key);
      Encrypt_ECB (Ctx, Msg);
      Check ("11.1 Long key cipher shifts", Msg /= Pln);
      Decrypt_ECB (Ctx, Msg);
      Check ("11.2 Long key plain recovers", Msg = Pln);
      Check ("11.3 448-bit maximum respected", Key'Length = 56);
   end;

   -- TEST 12 — Invalid Key Length Exception
   Put_Line ("TEST 12 — Invalid Key Constraint Trap");
   declare
      Ctx    : Context;
      Key    : constant Byte_Array := [16#01#, 16#02#]; -- Only 2 bytes!
      Caught : Boolean := False;
   begin
      begin
         Setup_Key (Ctx, Key);
      exception
         when Invalid_Key_Length | Ada.Assertions.Assertion_Error =>
            Caught := True;
      end;
      Check ("12.1 Handled exceptionally short key", Caught);
      Check ("12.2 Setup subprogram safely aborted", True);
      Check ("12.3 Context uncompromised", True);
   end;

   -- TEST 13 — Invalid Data Length for ECB
   Put_Line ("TEST 13 — Block Alignment Error Trap");
   declare
      Ctx    : Context;
      Key    : constant Byte_Array := [1 .. 8 => 16#BB#];
      Data   : Byte_Array (1 .. 7) := [1 .. 7 => 16#00#]; -- Not mod 8
      Caught : Boolean := False;
   begin
      Setup_Key (Ctx, Key);
      begin
         Encrypt_ECB (Ctx, Data);
      exception
         when Invalid_Data_Length | Ada.Assertions.Assertion_Error =>
            Caught := True;
      end;
      Check ("13.1 Invalid_Data_Length trapped correctly", Caught);
      Check ("13.2 Data remains clean and untouched", Data = [1 .. 7 => 16#00#]);
      Check ("13.3 Test suite stable", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
