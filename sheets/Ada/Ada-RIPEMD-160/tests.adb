with Ada.Text_IO; use Ada.Text_IO;
with Ripemd_160; use Ripemd_160;

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

   function To_Hex (Digest : Digest_Type) return String is
      Hex_Chars : constant String := "0123456789abcdef";
      Result    : String (1 .. 40);
      High, Low : Byte;
   begin
      for I in Digest'Range loop
         High := Digest (I) / 16;
         Low  := Digest (I) mod 16;
         Result (I * 2 + 1) := Hex_Chars (Natural (High) + 1);
         Result (I * 2 + 2) := Hex_Chars (Natural (Low) + 1);
      end loop;
      return Result;
   end To_Hex;

   -- Standard Test Vectors
   Empty_Hash : constant String := "9c1185a5c5e9fc54612808977ee8f548b2258d31";
   A_Hash     : constant String := "0bdc9d2d256b3ee9daae347be6f4dc835a467ffe";
   Abc_Hash   : constant String := "8eb208f7e05d987a9b044a8e98c6b087f15a0bfc";
   Md_Hash    : constant String := "5d0689ef49d2fae572b881b123a85ffa21595f36";
   Az_Hash    : constant String := "f71c27109c692c1b56bbdceb5b9d2865b3708dbc";

begin
   Put_Line ("TEST 1 — Empty Hash Variants");
   declare
      Ctx : Context;
      D   : Digest_Type;
   begin
      Check ("1.1 Empty String Hash", To_Hex (Hash ("")) = Empty_Hash);
      Check ("1.2 Empty Byte_Array Hash", To_Hex (Hash (To_Bytes (""))) = Empty_Hash);
      Init (Ctx);
      Update (Ctx, "");
      Finalize (Ctx, D);
      Check ("1.3 Empty Incremental Hash", To_Hex (D) = Empty_Hash);
   end;
   Put_Line ("");

   Put_Line ("TEST 2 — Single Character Vectors");
   declare
      Ctx : Context;
      D   : Digest_Type;
   begin
      Check ("2.1 String 'a'", To_Hex (Hash ("a")) = A_Hash);
      Check ("2.2 Byte_Array 'a'", To_Hex (Hash (To_Bytes ("a"))) = A_Hash);
      Init (Ctx);
      Update (Ctx, "a");
      Finalize (Ctx, D);
      Check ("2.3 Incremental 'a'", To_Hex (D) = A_Hash);
   end;
   Put_Line ("");

   Put_Line ("TEST 3 — Short String 'abc'");
   declare
      Ctx : Context;
      D   : Digest_Type;
   begin
      Check ("3.1 Single shot 'abc'", To_Hex (Hash ("abc")) = Abc_Hash);
      Init (Ctx);
      Update (Ctx, "a");
      Update (Ctx, "b");
      Update (Ctx, "c");
      Finalize (Ctx, D);
      Check ("3.2 Byte-by-byte 'abc'", To_Hex (D) = Abc_Hash);
      Init (Ctx);
      Update (Ctx, "ab");
      Update (Ctx, "c");
      Finalize (Ctx, D);
      Check ("3.3 Split 2+1 'abc'", To_Hex (D) = Abc_Hash);
   end;
   Put_Line ("");

   Put_Line ("TEST 4 — Phrase 'message digest'");
   declare
      Ctx : Context;
      D   : Digest_Type;
      Msg : constant String := "message digest";
   begin
      Check ("4.1 Single shot", To_Hex (Hash (Msg)) = Md_Hash);
      Init (Ctx);
      Update (Ctx, "message ");
      Update (Ctx, "digest");
      Finalize (Ctx, D);
      Check ("4.2 Word-by-word", To_Hex (D) = Md_Hash);
      Init (Ctx);
      for I in Msg'Range loop
         Update (Ctx, Msg (I .. I));
      end loop;
      Finalize (Ctx, D);
      Check ("4.3 Char-by-char", To_Hex (D) = Md_Hash);
   end;
   Put_Line ("");

   Put_Line ("TEST 5 — Alphabet 'a' to 'z'");
   declare
      Ctx : Context;
      D   : Digest_Type;
   begin
      Check ("5.1 Single shot", To_Hex (Hash ("abcdefghijklmnopqrstuvwxyz")) = Az_Hash);
      Init (Ctx);
      Update (Ctx, "abcdefghijklm");
      Update (Ctx, "nopqrstuvwxyz");
      Finalize (Ctx, D);
      Check ("5.2 Half-and-half split", To_Hex (D) = Az_Hash);
      Check ("5.3 Output length correctness", D'Length = 20);
   end;
   Put_Line ("");

   Put_Line ("TEST 6 — Block Size Multiples (64 Bytes)");
   declare
      Str_64 : constant String (1 .. 64) := [others => 'x'];
      D1, D2, D3 : Digest_Type;
      Ctx : Context;
   begin
      D1 := Hash (Str_64);
      Init (Ctx);
      Update (Ctx, Str_64 (1 .. 32));
      Update (Ctx, Str_64 (33 .. 64));
      Finalize (Ctx, D2);
      Init (Ctx);
      for I in 1 .. 64 loop
         Update (Ctx, Str_64 (I .. I));
      end loop;
      Finalize (Ctx, D3);
      Check ("6.1 Hash(64 chars) vs chunked 32+32", To_Hex (D1) = To_Hex (D2));
      Check ("6.2 Chunked 32+32 vs chunked 1x64", To_Hex (D2) = To_Hex (D3));
      Check ("6.3 Digest is well-formed", D1'Length = 20);
   end;
   Put_Line ("");

   Put_Line ("TEST 7 — Block Size Multiples + 1 (65 Bytes)");
   declare
      Str_65 : constant String (1 .. 65) := [others => 'y'];
      D1, D2 : Digest_Type;
      Ctx : Context;
   begin
      D1 := Hash (Str_65);
      Init (Ctx);
      Update (Ctx, Str_65 (1 .. 64));
      Update (Ctx, Str_65 (65 .. 65));
      Finalize (Ctx, D2);
      Check ("7.1 Hash(65 chars) vs chunked 64+1", To_Hex (D1) = To_Hex (D2));
      Init (Ctx);
      Update (Ctx, Str_65 (1 .. 1));
      Update (Ctx, Str_65 (2 .. 65));
      Finalize (Ctx, D2);
      Check ("7.2 Chunked 64+1 vs chunked 1+64", To_Hex (D1) = To_Hex (D2));
      Check ("7.3 State length validation", D1'Length = 20);
   end;
   Put_Line ("");

   Put_Line ("TEST 8 — Two Full Blocks (128 Bytes)");
   declare
      Str_128 : constant String (1 .. 128) := [others => 'z'];
      D1, D2 : Digest_Type;
      Ctx : Context;
   begin
      D1 := Hash (Str_128);
      Init (Ctx);
      Update (Ctx, Str_128 (1 .. 64));
      Update (Ctx, Str_128 (65 .. 128));
      Finalize (Ctx, D2);
      Check ("8.1 Hash(128 chars) vs chunked 64+64", To_Hex (D1) = To_Hex (D2));
      Init (Ctx);
      Update (Ctx, Str_128 (1 .. 100));
      Update (Ctx, Str_128 (101 .. 128));
      Finalize (Ctx, D2);
      Check ("8.2 Chunked 100+28 matches", To_Hex (D1) = To_Hex (D2));
      Check ("8.3 Digest length", D1'Length = 20);
   end;
   Put_Line ("");

   Put_Line ("TEST 9 — Long Pattern Sequence (80 Bytes)");
   declare
      Str_80 : constant String := "1234567890123456789012345678901234567890" &
                                  "1234567890123456789012345678901234567890";
      Vector : constant String := "9b752e45573d4b39f4dbd3323cab82bf63326bfb";
      D1, D2 : Digest_Type;
      Ctx : Context;
   begin
      D1 := Hash (Str_80);
      Check ("9.1 Hash matches standard vector for 80 bytes", To_Hex (D1) = Vector);
      Init (Ctx);
      Update (Ctx, Str_80 (1 .. 40));
      Update (Ctx, Str_80 (41 .. 80));
      Finalize (Ctx, D2);
      Check ("9.2 Chunked 40+40 matches", To_Hex (D2) = Vector);
      Check ("9.3 Internal length verifies", D1'Length = 20);
   end;
   Put_Line ("");

   Put_Line ("TEST 10 — Contract Exceptions (Uninitialized)");
   declare
      Ctx_Uninit : Context;
      D_Dummy    : Digest_Type;
      Ex_Raised  : Boolean;
   begin
      Ex_Raised := False;
      begin
         pragma Warnings (Off);
         Update (Ctx_Uninit, "fail");
         pragma Warnings (On);
      exception
         when State_Error => Ex_Raised := True;
      end;
      Check ("10.1 Update (String) raises State_Error", Ex_Raised);

      Ex_Raised := False;
      begin
         pragma Warnings (Off);
         Update (Ctx_Uninit, To_Bytes ("fail"));
         pragma Warnings (On);
      exception
         when State_Error => Ex_Raised := True;
      end;
      Check ("10.2 Update (Byte_Array) raises State_Error", Ex_Raised);

      Ex_Raised := False;
      begin
         pragma Warnings (Off);
         Finalize (Ctx_Uninit, D_Dummy);
         pragma Warnings (On);
      exception
         when State_Error => Ex_Raised := True;
      end;
      Check ("10.3 Finalize raises State_Error", Ex_Raised);
   end;
   Put_Line ("");

   Put_Line ("TEST 11 — Array Slicing and Empty Bounds");
   declare
      Data       : constant Byte_Array (5 .. 10) := To_Bytes ("123456");
      Empty_Data : constant Byte_Array (10 .. 9) := [others => 0];
      D1, D2, D3 : Digest_Type;
      Ctx        : Context;
   begin
      Init (Ctx);
      Update (Ctx, Empty_Data);
      Finalize (Ctx, D1);
      Check ("11.1 Empty bounds hash to Empty_Hash", To_Hex (D1) = Empty_Hash);
      D2 := Hash (Data);
      Check ("11.2 Hash of slice is correct", To_Hex (D2) = To_Hex (Hash ("123456")));
      Init (Ctx);
      Update (Ctx, Data (7 .. 9)); -- Maps to "345"
      Finalize (Ctx, D3);
      Check ("11.3 Incremental update of slice is correct", To_Hex (D3) = To_Hex (Hash ("345")));
   end;
   Put_Line ("");

   Put_Line ("TEST 12 — Context Reuse After Finalize");
   declare
      Ctx : Context;
      D : Digest_Type;
      Ex_Raised : Boolean;
   begin
      Init (Ctx);
      Update (Ctx, "test");
      Finalize (Ctx, D);
      Check ("12.1 First run successful", To_Hex (D) = To_Hex (Hash ("test")));
      Ex_Raised := False;
      begin
         Update (Ctx, "more");
      exception
         when State_Error => Ex_Raised := True;
      end;
      Check ("12.2 Update after Finalize raises State_Error", Ex_Raised);
      Init (Ctx);
      Update (Ctx, "reuse");
      Finalize (Ctx, D);
      Check ("12.3 Init resets state for reuse", To_Hex (D) = To_Hex (Hash ("reuse")));
   end;
   Put_Line ("");

   Put_Line ("TEST 13 — Byte Array vs String Equivalence");
   declare
      Str : constant String := "equivalence test";
      Bytes : constant Byte_Array := To_Bytes (Str);
      D1, D2, D3 : Digest_Type;
      Ctx : Context;
   begin
      D1 := Hash (Str);
      D2 := Hash (Bytes);
      Check ("13.1 Hash(String) equals Hash(Byte_Array)", To_Hex (D1) = To_Hex (D2));
      Init (Ctx);
      Update (Ctx, Bytes (Bytes'First .. Bytes'First + 4));
      Update (Ctx, Str (6 .. Str'Last));
      Finalize (Ctx, D3);
      Check ("13.2 Mixing Update(String) and Update(Byte_Array)", To_Hex (D1) = To_Hex (D3));
      Check ("13.3 Output limits", D1'Length = 20);
   end;
   Put_Line ("");

   Put_Line ("TEST 14 — One Million 'a's (Performance & Large Data)");
   declare
      Ctx   : Context;
      D     : Digest_Type;
      Chunk : constant Byte_Array (1 .. 1000) := [others => Character'Pos('a')];
   begin
      Init (Ctx);
      for I in 1 .. 1000 loop
         Update (Ctx, Chunk);
      end loop;
      Finalize (Ctx, D);
      Check ("14.1 Million 'a's digest matches standard vector",
             To_Hex (D) = "52783243c1697bdbe16d37f97f68f08325dc1528");
      Check ("14.2 Digest array length is exactly 20", D'Length = 20);
      Check ("14.3 Context is safely reset", not Is_Initialized (Ctx));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
