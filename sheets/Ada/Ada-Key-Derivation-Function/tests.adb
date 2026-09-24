with Ada.Text_IO; use Ada.Text_IO;
with Key_Derivation; use Key_Derivation;

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
   -- TEST 1 - Utilities correctness
   Put_Line ("TEST 1 — Utilities");
   Check ("1.1 To_Bytes non-empty", To_Bytes ("abc")'Length = 3);
   Check ("1.2 To_String roundtrip", To_String (To_Bytes ("test")) = "test");
   Check ("1.3 To_Bytes empty input", To_Bytes ("")'Length = 0);

   -- TEST 2 - Underlying Hash Primitive (Simulated PRF)
   Put_Line ("TEST 2 — Hash primitive");
   Check ("2.1 Hash produces fixed length", Hash (To_Bytes ("msg"))'Length = 32);
   Check ("2.2 Hash is deterministic", Hash (To_Bytes ("alpha")) = Hash (To_Bytes ("alpha")));
   Check ("2.3 Hash avoids basic collision", Hash (To_Bytes ("a")) /= Hash (To_Bytes ("b")));

   -- TEST 3 - Underlying HMAC Primitive
   Put_Line ("TEST 3 — HMAC primitive");
   Check ("3.1 HMAC outputs fixed length", HMAC (To_Bytes ("key"), To_Bytes ("msg"))'Length = 32);
   Check ("3.2 HMAC deterministic", HMAC (To_Bytes ("k"), To_Bytes ("m")) = HMAC (To_Bytes ("k"), To_Bytes ("m")));
   Check ("3.3 HMAC changes with key", HMAC (To_Bytes ("k1"), To_Bytes ("m")) /= HMAC (To_Bytes ("k2"), To_Bytes ("m")));

   -- TEST 4 - HMAC Padding & Lengths (Edge Cases)
   Put_Line ("TEST 4 — HMAC padding edge cases");
   Check ("4.1 Empty key handled", HMAC (To_Bytes (""), To_Bytes ("msg"))'Length = 32);
   Check ("4.2 Empty msg handled", HMAC (To_Bytes ("key"), To_Bytes (""))'Length = 32);
   declare
      Long_Key : constant Byte_Array (1 .. 100) := [others => 16#AA#];
   begin
      Check ("4.3 Oversized key collapses safely", HMAC (Long_Key, To_Bytes ("m"))'Length = 32);
   end;

   -- TEST 5 - PBKDF2 Basic Functionality
   Put_Line ("TEST 5 — PBKDF2 Basic");
   declare
      Out1 : constant Byte_Array := PBKDF2 (To_Bytes ("pass"), To_Bytes ("salt"), 1, 32);
      Out2 : constant Byte_Array := PBKDF2 (To_Bytes ("pass"), To_Bytes ("salt"), 2, 32);
   begin
      Check ("5.1 Matches requested length", Out1'Length = 32);
      Check ("5.2 Iterations modify output", Out1 /= Out2);
      Check ("5.3 Deterministic extraction", Out2 = PBKDF2 (To_Bytes ("pass"), To_Bytes ("salt"), 2, 32));
   end;

   -- TEST 6 - PBKDF2 Multi-Block Boundaries
   Put_Line ("TEST 6 — PBKDF2 Large Output");
   declare
      Out_Large : constant Byte_Array := PBKDF2 (To_Bytes ("p"), To_Bytes ("s"), 1, 50);
      Out_Exact : constant Byte_Array := PBKDF2 (To_Bytes ("p"), To_Bytes ("s"), 1, 32);
   begin
      Check ("6.1 Truncates to requested length correctly", Out_Large'Length = 50);
      Check ("6.2 First block matches exactly", Out_Large (1 .. 32) = Out_Exact);
      Check ("6.3 Salt deeply influences block generation", Out_Large /= PBKDF2 (To_Bytes ("p"), To_Bytes ("s2"), 1, 50));
   end;

   -- TEST 7 - PBKDF2 Constraints & Errors
   Put_Line ("TEST 7 — PBKDF2 Exceptions");
   begin
      declare
         Bad_Len : constant Integer := 100_000;
         Dummy   : Natural;
      begin
         Dummy := PBKDF2 (To_Bytes ("p"), To_Bytes ("s"), 1, Positive (Bad_Len))'Length;
         Check ("7.1 Exceeded max length (should not reach)", Dummy = 0);
      end;
   exception
      when Invalid_Length_Error =>
         Check ("7.1 Exceeded max length raises expected error", True);
   end;

   begin
      declare
         Bad_Iter : constant Integer := Integer'Value ("0");
         Dummy    : Natural;
      begin
         Dummy := PBKDF2 (To_Bytes ("p"), To_Bytes ("s"), Positive (Bad_Iter), 32)'Length;
         Check ("7.2 Iterations = 0 (should not reach)", Dummy = 0);
      end;
   exception
      when Constraint_Error =>
         Check ("7.2 Iterations = 0 violates strong typing", True);
   end;

   begin
      declare
         Bad_Len : constant Integer := Integer'Value ("0");
         Dummy   : Natural;
      begin
         Dummy := PBKDF2 (To_Bytes ("p"), To_Bytes ("s"), 1, Positive (Bad_Len))'Length;
         Check ("7.3 Length = 0 (should not reach)", Dummy = 0);
      end;
   exception
      when Constraint_Error =>
         Check ("7.3 Length = 0 violates strong typing", True);
   end;

   -- TEST 8 - HKDF Extract Phase
   Put_Line ("TEST 8 — HKDF Extract");
   declare
      PRK1 : constant Byte_Array := HKDF_Extract (To_Bytes ("salt"), To_Bytes ("ikm"));
      PRK2 : constant Byte_Array := HKDF_Extract (To_Bytes (""), To_Bytes ("ikm"));
   begin
      Check ("8.1 Output matches underlying Hash length", PRK1'Length = 32);
      Check ("8.2 Empty salt handled securely", PRK1 /= PRK2);
      Check ("8.3 Empty salt is deterministic", PRK2 = HKDF_Extract (To_Bytes (""), To_Bytes ("ikm")));
   end;

   -- TEST 9 - HKDF Expand Phase
   Put_Line ("TEST 9 — HKDF Expand");
   declare
      PRK : constant Byte_Array := HKDF_Extract (To_Bytes ("salt"), To_Bytes ("ikm"));
      OKM : constant Byte_Array := HKDF_Expand (PRK, To_Bytes ("info"), 42);
   begin
      Check ("9.1 Length matches requested bound", OKM'Length = 42);
      Check ("9.2 Empty Info successfully expanded", HKDF_Expand (PRK, To_Bytes (""), 32)'Length = 32);
      Check ("9.3 Info influences final keying material", OKM /= HKDF_Expand (PRK, To_Bytes ("other"), 42));
   end;

   -- TEST 10 - HKDF Complete Flow (Extract -> Expand)
   Put_Line ("TEST 10 — HKDF Complete Flow");
   declare
      PRK  : constant Byte_Array := HKDF_Extract (To_Bytes ("s"), To_Bytes ("ikm"));
      OKM1 : constant Byte_Array := HKDF_Expand (PRK, To_Bytes ("i1"), 64);
      OKM2 : constant Byte_Array := HKDF_Expand (PRK, To_Bytes ("i2"), 64);
   begin
      Check ("10.1 Multi-block expansion works", OKM1'Length = 64);
      Check ("10.2 Different info generates divergent keys", OKM1 /= OKM2);
      Check ("10.3 Divergent extract salt changes expansion completely",
         OKM1 /= HKDF_Expand (HKDF_Extract (To_Bytes ("s2"), To_Bytes ("ikm")), To_Bytes ("i1"), 64));
   end;

   -- TEST 11 - HKDF Error Handling
   Put_Line ("TEST 11 — HKDF Exceptions");
   begin
      declare
         Bad_Len : constant Integer := 70_000;
         Dummy   : Natural;
      begin
         Dummy := HKDF_Expand (To_Bytes ("adequate_prk_length_string_here_32"), To_Bytes ("info"), Positive (Bad_Len))'Length;
         Check ("11.1 Max length check (should not reach)", Dummy = 0);
      end;
   exception
      when Invalid_Length_Error =>
         Check ("11.1 Max length limit raises correct error", True);
   end;

   begin
      declare
         Dummy : Natural;
      begin
         Dummy := HKDF_Expand (To_Bytes ("short"), To_Bytes ("info"), 32)'Length;
         Check ("11.2 Short PRK check (should not reach)", Dummy = 0);
      end;
   exception
      when Invalid_Key_Error =>
         Check ("11.2 Short PRK triggers error securely", True);
   end;

   begin
      declare
         Bad_Len : constant Integer := Integer'Value ("0");
         Dummy   : Natural;
      begin
         Dummy := HKDF_Expand (To_Bytes ("adequate_prk_length_string_here_32"), To_Bytes ("i"), Positive (Bad_Len))'Length;
         Check ("11.3 Zero length check (should not reach)", Dummy = 0);
      end;
   exception
      when Constraint_Error =>
         Check ("11.3 Zero length violates strong typing", True);
   end;

   -- TEST 12 - Simple Hash-Based KDF
   Put_Line ("TEST 12 — Simple KDF");
   declare
      K1 : constant Byte_Array := Simple_KDF (To_Bytes ("sec"), To_Bytes ("inf"), 20);
      K2 : constant Byte_Array := Simple_KDF (To_Bytes ("sec"), To_Bytes ("inf"), 40);
   begin
      Check ("12.1 Produces partial block length", K1'Length = 20);
      Check ("12.2 Produces multi block length", K2'Length = 40);
      Check ("12.3 Prefix matches between lengths", K1 = K2 (1 .. 20));
   end;

   -- TEST 13 - Simple KDF Edge Cases
   Put_Line ("TEST 13 — Simple KDF Edge Cases");
   Check ("13.1 Empty info processed securely", Simple_KDF (To_Bytes ("sec"), To_Bytes (""), 32)'Length = 32);
   Check ("13.2 Empty secret processed securely", Simple_KDF (To_Bytes (""), To_Bytes ("inf"), 32)'Length = 32);
   Check ("13.3 Output bound to specific secret completely",
      Simple_KDF (To_Bytes ("s1"), To_Bytes ("i"), 32) /= Simple_KDF (To_Bytes ("s2"), To_Bytes ("i"), 32));

   -- TEST 14 - Mixed Empty Array Edge Cases
   Put_Line ("TEST 14 — Mixed Edge Cases");
   declare
      Null_Bytes : constant Byte_Array (1 .. 0) := [others => 0];
   begin
      Check ("14.1 PBKDF2 tolerates empty salt explicitly", PBKDF2 (To_Bytes ("p"), Null_Bytes, 1, 16)'Length = 16);
      Check ("14.2 PBKDF2 tolerates empty password", PBKDF2 (Null_Bytes, To_Bytes ("s"), 1, 16)'Length = 16);
      Check ("14.3 HKDF tolerates empty Initial Keying Material", HKDF_Extract (To_Bytes ("s"), Null_Bytes)'Length = 32);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
