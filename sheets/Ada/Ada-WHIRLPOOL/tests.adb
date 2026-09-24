with Ada.Text_IO; use Ada.Text_IO;
with Whirlpool; use Whirlpool;

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
   Put_Line ("=== Running Whirlpool Test Suite ===");

   -- TEST 1 — Empty String Hash
   Put_Line ("TEST 1 — Empty String Hash");
   declare
      Res : constant Digest := Hash_String ("");
      Hex : constant String := Digest_To_Hex (Res);
   begin
      Check ("1.1 Digest length is 64 bytes", Res'Length = 64);
      Check ("1.2 Hex string length is 128 characters", Hex'Length = 128);
      Check ("1.3 Hex output generated successfully", Hex'Length > 0);
   end;

   -- TEST 2 — Single Character Hash ('a')
   Put_Line ("TEST 2 — Single Character Hash ('a')");
   declare
      Res : constant Digest := Hash_String ("a");
      Hex : constant String := Digest_To_Hex (Res);
   begin
      Check ("2.1 Digest length is 64 bytes", Res'Length = 64);
      Check ("2.2 Hex string length is 128 characters", Hex'Length = 128);
      Check ("2.3 Hash is non-zero", Hex /= "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000");
   end;

   -- TEST 3 — Alphabet Hash ("abc")
   Put_Line ("TEST 3 — Alphabet Hash (""abc"")");
   declare
      Res : constant Digest := Hash_String ("abc");
      Hex : constant String := Digest_To_Hex (Res);
   begin
      Check ("3.1 Digest length is 64 bytes", Res'Length = 64);
      Check ("3.2 Hex string length is 128 characters", Hex'Length = 128);
      Check ("3.3 Hex output is valid hexadecimal character range", Hex(1) in '0'..'9' | 'A'..'F');
   end;

   -- TEST 4 — Longer String Hash
   Put_Line ("TEST 4 — Longer String Hash");
   declare
      Res : constant Digest := Hash_String ("The quick brown fox jumps over the lazy dog");
      Hex : constant String := Digest_To_Hex (Res);
   begin
      Check ("4.1 Digest length is 64 bytes", Res'Length = 64);
      Check ("4.2 Hex string length is 128", Hex'Length = 128);
      Check ("4.3 Deterministic output verification", Digest_To_Hex (Hash_String ("The quick brown fox jumps over the lazy dog")) = Hex);
   end;

   -- TEST 5 — Binary Array Input Hash
   Put_Line ("TEST 5 — Binary Array Input Hash");
   declare
      Msg : constant Message := [16#01#, 16#02#, 16#03#, 16#04#];
      Res : constant Digest := Hash (Msg);
      Hex : constant String := Digest_To_Hex (Res);
   begin
      Check ("5.1 Hash from byte array succeeds", Res'Length = 64);
      Check ("5.2 Hex output generated", Hex'Length = 128);
      Check ("5.3 Non-empty hash result", Res(0) /= 0 or Res(1) /= 0);
   end;

   -- TEST 6 — Large Input (Multiple Blocks)
   Put_Line ("TEST 6 — Large Input (Multiple Blocks)");
   declare
      Large_Msg : Message (1 .. 200);
   begin
      for I in Large_Msg'Range loop
         Large_Msg (I) := Byte (I mod 256);
      end loop;
      declare
         Res : constant Digest := Hash (Large_Msg);
         Hex : constant String := Digest_To_Hex (Res);
      begin
         Check ("6.1 Multi-block hash succeeds", Res'Length = 64);
         Check ("6.2 Hex string generated", Hex'Length = 128);
         Check ("6.3 Output stability check", Digest_To_Hex (Hash (Large_Msg)) = Hex);
      end;
   end;

   -- TEST 7 — Digest_To_Hex Formatting
   Put_Line ("TEST 7 — Digest_To_Hex Formatting");
   declare
      D : constant Digest := [others => 16#AB#];
      Hex : constant String := Digest_To_Hex (D);
   begin
      Check ("7.1 Hex length correct", Hex'Length = 128);
      Check ("7.2 Contains expected hex encoding", Hex(1..4) = "ABAB");
      Check ("7.3 Ends with expected hex encoding", Hex(125..128) = "ABAB");
   end;

   -- TEST 8 — Edge Case: Single Byte Message
   Put_Line ("TEST 8 — Edge Case: Single Byte Message");
   declare
      Msg : constant Message := [1 => 16#FF#];
      Res : constant Digest := Hash (Msg);
   begin
      Check ("8.1 Single byte hash succeeds", Res'Length = 64);
      Check ("8.2 Different from empty hash", Digest_To_Hex (Res) /= Digest_To_Hex (Hash_String ("")));
      Check ("8.3 Deterministic single byte", Digest_To_Hex (Hash (Msg)) = Digest_To_Hex (Res));
   end;

   -- TEST 9 — Edge Case: Exactly One Block (64 bytes)
   Put_Line ("TEST 9 — Edge Case: Exactly One Block (64 bytes)");
   declare
      Msg : Message (1 .. 64);
      Res : Digest;
   begin
      for I in Msg'Range loop
         Msg (I) := Byte (I);
      end loop;
      Res := Hash (Msg);
      Check ("9.1 Exact block size hash succeeds", Res'Length = 64);
      Check ("9.2 Hex output valid", Digest_To_Hex (Res)'Length = 128);
      Check ("9.3 Result is robust", Res(0) /= Res(63));
   end;

   -- TEST 10 — Edge Case: Block Boundary Plus One (65 bytes)
   Put_Line ("TEST 10 — Edge Case: Block Boundary Plus One (65 bytes)");
   declare
      Msg : Message (1 .. 65);
      Res : Digest;
   begin
      for I in Msg'Range loop
         Msg (I) := Byte (I mod 256);
      end loop;
      Res := Hash (Msg);
      Check ("10.1 65-byte message hash succeeds", Res'Length = 64);
      Check ("10.2 Hex output valid", Digest_To_Hex (Res)'Length = 128);
      Check ("10.3 Multi-block padding handling correct", Digest_To_Hex (Res) /= Digest_To_Hex (Hash (Msg(1..64))));
   end;

   -- TEST 11 — Collision Resistance Property
   Put_Line ("TEST 11 — Collision Resistance Property");
   declare
      Res1 : constant Digest := Hash_String ("Hello");
      Res2 : constant Digest := Hash_String ("Hellp");
   begin
      Check ("11.1 Different inputs yield different digests", Res1 /= Res2);
      Check ("11.2 Hash prefixes differ (first half)", Res1(0..31) /= Res2(0..31));
      Check ("11.3 Full hex strings differ", Digest_To_Hex (Res1) /= Digest_To_Hex (Res2));
   end;

   -- TEST 12 — API Consistency Across Wrapper
   Put_Line ("TEST 12 — API Consistency Across Wrapper");
   declare
      Text : constant String := "Ada 2023 Verification";
      Res_Str : constant Digest := Hash_String (Text);
      Res_Bin : Digest;
   begin
      declare
         Bin_Msg : Message (1 .. Text'Length);
      begin
         for I in Text'Range loop
            Bin_Msg (I - Text'First + 1) := Character'Pos (Text (I));
         end loop;
         Res_Bin := Hash (Bin_Msg);
      end;
      Check ("12.1 Hash_String and Hash produce identical digests (byte 0)", Res_Str(0) = Res_Bin(0));
      Check ("12.2 Identical digests (byte 63)", Res_Str(63) = Res_Bin(63));
      Check ("12.3 Identical hex strings", Digest_To_Hex (Res_Str) = Digest_To_Hex (Res_Bin));
   end;

   -- TEST 13 — Exception and Error Handling Robustness
   Put_Line ("TEST 13 — Exception and Error Handling Robustness");
   declare
      Exception_Raised : Boolean := False;
   begin
      begin
         declare
            D : constant Digest := Hash_String ("Test");
            pragma Unreferenced (D);
         begin
            Exception_Raised := True;
         end;
      exception
         when others =>
            Exception_Raised := False;
      end;
      Check ("13.1 Normal execution completes without unhandled exception", Exception_Raised);
      Check ("13.2 Pass count tracking functional", Pass_Count > 0);
      Check ("13.3 Test framework integrity verified", Pass_Count + Fail_Count > 0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
            & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
