with Ada.Text_IO; use Ada.Text_IO;
with HMAC;        use HMAC;

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

   -- A predictable mock hash function to allow deterministic testing
   -- of the HMAC structural requirements, padding, and XOR masks.
   function Fake_Hash (Data : Byte_Array) return Byte_Array is
      Output : Byte_Array (1 .. 4) := [0, 0, 0, 0];
      Sum    : Byte := 0;
      Xor_V  : Byte := 0;
   begin
      for B of Data loop
         Sum   := Sum + B;
         Xor_V := Xor_V xor B;
      end loop;
      Output (1) := Sum;
      Output (2) := Xor_V;
      Output (3) := Byte (Data'Length mod 256);
      if Data'Length > 0 then
         Output (4) := Data (Data'First);
      else
         Output (4) := 16#00#;
      end if;
      return Output;
   end Fake_Hash;

   -- Instantiate HMAC algorithm with the Fake_Hash
   package Test_HMAC is new HMAC.Core
     (Block_Size => 8,
      Hash_Size  => 4,
      Hash       => Fake_Hash);

begin
   Put_Line ("=== Testing HMAC Variants & Edge Cases ===");

   -- TEST 1: Normalize Short Key (Zero Padding)
   declare
      Key     : constant Byte_Array := [16#01#, 16#02#];
      K_Prime : constant Byte_Array := Test_HMAC.Normalize_Key (Key);
   begin
      Put_Line ("TEST 1 — Normalize Short Key");
      Check ("1.1 K' length is block size (8)", K_Prime'Length = 8);
      Check ("1.2 First bytes match key", K_Prime (1) = 16#01# and K_Prime (2) = 16#02#);
      Check ("1.3 Remaining bytes are padded zero", K_Prime (3) = 0 and K_Prime (8) = 0);
   end;

   -- TEST 2: Normalize Exact Length Key
   declare
      Key     : constant Byte_Array := [1, 2, 3, 4, 5, 6, 7, 8];
      K_Prime : constant Byte_Array := Test_HMAC.Normalize_Key (Key);
   begin
      Put_Line ("TEST 2 — Normalize Exact Block Size Key");
      Check ("2.1 K' length is exact", K_Prime'Length = 8);
      Check ("2.2 First byte matches", K_Prime (1) = 1);
      Check ("2.3 Last byte matches, no corruption", K_Prime (8) = 8);
   end;

   -- TEST 3: Normalize Long Key (Pre-Hashing required by RFC)
   declare
      Key     : constant Byte_Array (1 .. 10) := [others => 16#AA#];
      K_Prime : constant Byte_Array := Test_HMAC.Normalize_Key (Key);
   begin
      Put_Line ("TEST 3 — Normalize Long Key (Hashing)");
      Check ("3.1 K' length is padded to block size", K_Prime'Length = 8);
      Check ("3.2 First byte comes from Hash(Key)", K_Prime (1) = 16#A4#);
      Check ("3.3 Fifth byte is zero (padded after hash size)", K_Prime (5) = 0);
   end;

   -- TEST 4: Normalize Empty Key
   declare
      Key     : constant Byte_Array (1 .. 0) := [others => 0];
      K_Prime : constant Byte_Array := Test_HMAC.Normalize_Key (Key);
   begin
      Put_Line ("TEST 4 — Normalize Empty Key");
      Check ("4.1 K' length is block size", K_Prime'Length = 8);
      Check ("4.2 First byte is padded zero", K_Prime (1) = 0);
      Check ("4.3 Last byte is padded zero", K_Prime (8) = 0);
   end;

   -- TEST 5: Compute HMAC on Empty Data
   declare
      Key    : constant Byte_Array (1 .. 0) := [others => 0];
      Msg    : constant Byte_Array (1 .. 0) := [others => 0];
      Result : constant Byte_Array := Test_HMAC.Compute (Key, Msg);
   begin
      Put_Line ("TEST 5 — Compute Empty Key and Message");
      Check ("5.1 Result length is Hash_Size (4)", Result'Length = 4);
      Check ("5.2 Lower bound is properly formatted (1)", Result'First = 1);
      Check ("5.3 Deterministic result check", Result (1) = 16#CE#);
   end;

   -- TEST 6: Compute Normal Configuration
   declare
      Key    : constant Byte_Array := [16#01#, 16#02#];
      Msg    : constant Byte_Array := [16#10#, 16#20#];
      Result : constant Byte_Array := Test_HMAC.Compute (Key, Msg);
   begin
      Put_Line ("TEST 6 — Compute Normal Inputs");
      Check ("6.1 Valid array bounds generated", Result'Length = 4);
      Check ("6.2 Output is stable (idempotency)", Result = Test_HMAC.Compute (Key, Msg));
      Check ("6.3 Differs from empty evaluation", Result /= Test_HMAC.Compute ([1..0 => 0], [1..0 => 0]));
   end;

   -- TEST 7: String Interface Variant Verification
   declare
      Key_Str   : constant String := "AB";
      Msg_Str   : constant String := "CD";
      Key_Bytes : constant Byte_Array := [16#41#, 16#42#];
      Msg_Bytes : constant Byte_Array := [16#43#, 16#44#];
      Res_Str   : constant Byte_Array := Test_HMAC.Compute_String (Key_Str, Msg_Str);
      Res_Bytes : constant Byte_Array := Test_HMAC.Compute (Key_Bytes, Msg_Bytes);
   begin
      Put_Line ("TEST 7 — Compute_String Mapping");
      Check ("7.1 String variant equals Byte_Array variant", Res_Str = Res_Bytes);
      Check ("7.2 Length output conforms", Res_Str'Length = 4);
      Check ("7.3 Bounded properly", Res_Str'First = 1);
   end;

   -- TEST 8: Output Sensitivity to Key Perturbation
   declare
      Key1 : constant Byte_Array := [16#01#];
      Key2 : constant Byte_Array := [16#02#];
      Msg  : constant Byte_Array := [16#10#, 16#20#];
      Res1 : constant Byte_Array := Test_HMAC.Compute (Key1, Msg);
      Res2 : constant Byte_Array := Test_HMAC.Compute (Key2, Msg);
   begin
      Put_Line ("TEST 8 — Key Sensitivity");
      Check ("8.1 Results correctly diverge", Res1 /= Res2);
      Check ("8.2 Length maintains format", Res1'Length = 4);
      Check ("8.3 Hash maintains independent format", Res2'Length = 4);
   end;

   -- TEST 9: Output Sensitivity to Message Perturbation
   declare
      Key  : constant Byte_Array := [16#01#];
      Msg1 : constant Byte_Array := [16#10#, 16#20#];
      Msg2 : constant Byte_Array := [16#99#, 16#88#];
      Res1 : constant Byte_Array := Test_HMAC.Compute (Key, Msg1);
      Res2 : constant Byte_Array := Test_HMAC.Compute (Key, Msg2);
   begin
      Put_Line ("TEST 9 — Message Sensitivity");
      Check ("9.1 Results correctly diverge", Res1 /= Res2);
      Check ("9.2 Bounds correctly established", Res1'First = 1);
      Check ("9.3 Length maintained strictly", Res2'Length = 4);
   end;

   -- TEST 10: Structural Equivalence for Long Keys (RFC Core Requirement)
   declare
      Long_Key   : constant Byte_Array (1 .. 10) := [others => 16#AA#];
      Msg        : constant Byte_Array := [16#11#, 16#22#];
      Hashed_Key : constant Byte_Array := Fake_Hash (Long_Key);
      Res_Long   : constant Byte_Array := Test_HMAC.Compute (Long_Key, Msg);
      Res_Hashed : constant Byte_Array := Test_HMAC.Compute (Hashed_Key, Msg);
   begin
      Put_Line ("TEST 10 — Key Hashing Equivalence (RFC Compliance)");
      Check ("10.1 HMAC(K, M) equals HMAC(Hash(K), M) for large K", Res_Long = Res_Hashed);
      Check ("10.2 Final result format adheres to sizing", Res_Long'Length = 4);
      Check ("10.3 Hashed Key accurately sized", Hashed_Key'Length = 4);
   end;

   -- TEST 11: Extreme Message Length Processing
   declare
      Key : constant Byte_Array := [16#99#];
      Msg : constant Byte_Array (1 .. 1000) := [others => 16#55#];
      Res : constant Byte_Array := Test_HMAC.Compute (Key, Msg);
   begin
      Put_Line ("TEST 11 — Large Message Bounds Formatting");
      Check ("11.1 Computes seamlessly across concatenations", Res'Length = 4);
      Check ("11.2 Valid lower array bound preserved", Res'First = 1);
      Check ("11.3 Output is fully deterministic", Res = Test_HMAC.Compute (Key, Msg));
   end;

   -- TEST 12: Single Element Vectors
   declare
      Key : constant Byte_Array := [1 => 16#FF#];
      Msg : constant Byte_Array := [1 => 16#00#];
      Res : constant Byte_Array := Test_HMAC.Compute (Key, Msg);
   begin
      Put_Line ("TEST 12 — Single Element Vectors");
      Check ("12.1 Evaluation returns valid block", Res'Length = 4);
      Check ("12.2 Output indices adhere to spec", Res'First = 1);
      Check ("12.3 Stable function execution", Res = Test_HMAC.Compute (Key, Msg));
   end;

   -- TEST 13: String Interface Null Safety
   declare
      Res_Str   : constant Byte_Array := Test_HMAC.Compute_String ("", "");
      Res_Bytes : constant Byte_Array := Test_HMAC.Compute ([1..0 => 0], [1..0 => 0]);
   begin
      Put_Line ("TEST 13 — Empty String Handling");
      Check ("13.1 Empty string handles cleanly", Res_Str'Length = 4);
      Check ("13.2 Resolves symmetrically with byte variant", Res_Str = Res_Bytes);
      Check ("13.3 Known edge-case sum resolves correctly", Res_Str (1) = 16#CE#);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
             
   pragma Assert (Fail_Count = 0, "Some tests failed");
   
   -- Provide firm exit failure for automated environments not passing `-gnata`
   if Fail_Count > 0 then
      raise Program_Error with "Test suite failed with errors.";
   end if;

end Tests;
