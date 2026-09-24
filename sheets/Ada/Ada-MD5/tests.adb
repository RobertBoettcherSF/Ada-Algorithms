with Ada.Text_IO; use Ada.Text_IO;
with MD5;         use MD5;

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

   -- Helper to execute exactly 3 assertions per standardized vector
   procedure Test_Case (Test_Name : String; Input : String; Expected_Hex : String) is
      Sub_Name : constant String := Test_Name & " - ";
      C        : Context;
      Dig      : Digest_Type;
   begin
      Put_Line (Test_Name);
      
      -- Assertion 1: One-shot String
      Check (Sub_Name & "One-shot String", Hash (Input) = Expected_Hex);
      
      -- Assertion 2: One-shot Byte_Array
      Check (Sub_Name & "One-shot Byte_Array", To_Hex (Hash (To_Bytes (Input))) = Expected_Hex);
      
      -- Assertion 3: Incremental State
      Init (C);
      Update (C, Input);
      Final (C, Dig);
      Check (Sub_Name & "Incremental Update", To_Hex (Dig) = Expected_Hex);
   end Test_Case;

   -- Constants for Padding Edge Case Data Verification
   Str_55 : constant String (1 .. 55) := (others => 'A');
   Str_56 : constant String (1 .. 56) := (others => 'A');
   Str_63 : constant String (1 .. 63) := (others => 'A');
   Str_64 : constant String (1 .. 64) := (others => 'A');

begin
   -- Standard RFC 1321 Test Vectors
   Test_Case ("TEST 1 — Empty String",
              "",
              "d41d8cd98f00b204e9800998ecf8427e");

   Test_Case ("TEST 2 — Single Character",
              "a",
              "0cc175b9c0f1b6a831c399e269772661");

   Test_Case ("TEST 3 — Alphabet subset",
              "abc",
              "900150983cd24fb0d6963f7d28e17f72");

   Test_Case ("TEST 4 — Standard Sentence",
              "message digest",
              "f96b697d7cb7938d525a2f31aaf161d0");

   Test_Case ("TEST 5 — Lowercase Alphabet",
              "abcdefghijklmnopqrstuvwxyz",
              "c3fcd3d76192e4007dfb496cca67e13b");

   Test_Case ("TEST 6 — Full Alphabet and Numerals",
              "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
              "d174ab98d277d9f5a5611c2c9f419d9f");

   Test_Case ("TEST 7 — Numbers Sequence (Length 80)",
              "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
              "57edf4a22be3c955ac49da2e2107b67a");

   -- Strict boundary edge cases testing exact byte-padding logic handling against state invariants
   Test_Case ("TEST 8 — Padding Boundary (55 bytes)",
              Str_55,
              Hash (Str_55));

   Test_Case ("TEST 9 — Padding Boundary (56 bytes)",
              Str_56,
              Hash (Str_56));

   Test_Case ("TEST 10 — Padding Boundary (63 bytes)",
              Str_63,
              Hash (Str_63));

   Test_Case ("TEST 11 — Padding Boundary (64 bytes)",
              Str_64,
              Hash (Str_64));

   -- Test 12: Split updating sequence invariant verification
   Put_Line ("TEST 12 — Incremental Hashing (Split)");
   declare
      C   : Context;
      Dig : Digest_Type;
   begin
      Init (C);
      Check ("12.1 Context is open after Init", Is_Open (C));
      Update (C, "a");
      Update (C, "b");
      Update (C, "c");
      Final (C, Dig);
      Check ("12.2 Split update matches combined sequence", To_Hex (Dig) = "900150983cd24fb0d6963f7d28e17f72");
      Check ("12.3 Context is closed after Final", not Is_Open (C));
   end;

   -- Test 13: Exception handling and robust state protections
   Put_Line ("TEST 13 — Exception Handling");
   declare
      Ctx    : Context;
      Dig    : Digest_Type;
      Thrown : Boolean := False;
   begin
      begin
         Update (Ctx, "a");
      exception
         when MD5_Error => Thrown := True;
      end;
      Check ("13.1 Update before Init raises MD5_Error", Thrown);

      Init (Ctx);
      Update (Ctx, "a");
      Final (Ctx, Dig);
      Thrown := False;
      begin
         Update (Ctx, "b");
      exception
         when MD5_Error => Thrown := True;
      end;
      Check ("13.2 Update after Final raises MD5_Error", Thrown);

      Thrown := False;
      begin
         Final (Ctx, Dig);
      exception
         when MD5_Error => Thrown := True;
      end;
      Check ("13.3 Final after Final raises MD5_Error", Thrown);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
