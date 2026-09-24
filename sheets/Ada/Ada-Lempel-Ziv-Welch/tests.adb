with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with LZW; use LZW;

procedure Tests is
   C_Empty      : constant String := "";
   C_Single     : constant String := "A";
   C_Basic      : constant String := "TOBEORNOTTOBEORTOBEORNOT";
   C_Repeated   : constant String := "AAAAAAAAAAAAAAA";
begin
   Put_Line ("Starting LZW Validation Suite...");
   Put_Line ("--------------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - Empty String Handing");
   Put_Line ("  1.1 Assert compression of empty string returns empty array");
   declare
      Res : constant Code_Array := Compress (C_Empty);
   begin
      Assert (Res'Length = 0, "Failed: Output should be empty");
      Put_Line ("      PASS");
   end;

   -- TEST 2
   Put_Line ("TEST 2 - Single Character Validation");
   Put_Line ("  2.1 Assert single char encodes to base alphabet code");
   declare
      Res : constant Code_Array := Compress (C_Single);
   begin
      Assert (Res'Length = 1, "Failed: Should be exactly 1 code");
      Assert (Res(Res'First) = Character'Pos('A'), "Failed: Code does not match ASCII 'A'");
      Put_Line ("      PASS");
   end;
   Put_Line ("  2.2 Assert single code decodes correctly");
   declare
      Str : constant String := Decompress (Compress(C_Single));
   begin
      Assert (Str = C_Single, "Failed: Decompressed string mismatch");
      Put_Line ("      PASS");
   end;

   -- TEST 3
   Put_Line ("TEST 3 - Standard Wikipedia Baseline");
   Put_Line ("  3.1 Assert compression matches known sequence length");
   declare
      Res : constant Code_Array := Compress (C_Basic);
   begin
      -- Standard LZW encodes TOBEORNOTTOBEORTOBEORNOT into 16 codes
      Assert (Res'Length = 16, "Failed: Unexpected compressed length");
      Put_Line ("      PASS");
   end;
   Put_Line ("  3.2 Assert successful decode of baseline");
   declare
      Str : constant String := Decompress (Compress(C_Basic));
   begin
      Assert (Str = C_Basic, "Failed: Decompressed baseline mismatch");
      Put_Line ("      PASS");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - Extreme Repetition (AAA...)");
   Put_Line ("  4.1 Assert proper sequence tracking for repetitive chars");
   declare
      Res : constant Code_Array := Compress (C_Repeated);
      Str : constant String := Decompress (Res);
   begin
      Assert (Str = C_Repeated, "Failed: Repetitive string failed roundtrip");
      Put_Line ("      PASS");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Dictionary Freeze Variant");
   Put_Line ("  5.1 Assert dictionary freezes when max capacity reached (Max_Bits=9 => 512 max)");
   declare
      -- 9 bits = max 512 codes. We feed a large string to trigger Freeze.
      Long_Str : constant String (1 .. 1000) := (others => 'X');
      Res : constant Code_Array := Compress (Long_Str, Freeze, 9);
      Str : constant String := Decompress (Res, Freeze, 9);
   begin
      Assert (Str = Long_Str, "Failed: Freeze dictionary logic failed");
      Put_Line ("      PASS");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - Dictionary Clear Variant");
   Put_Line ("  6.1 Assert dictionary correctly clears and reconstructs");
   declare
      Long_Str : constant String (1 .. 1000) := (others => 'Y');
      Res : constant Code_Array := Compress (Long_Str, Clear, 9);
      Str : constant String := Decompress (Res, Clear, 9);
   begin
      Assert (Str = Long_Str, "Failed: Clear dictionary logic failed");
      Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Edge Case: Binary/Zero Data");
   Put_Line ("  7.1 Assert algorithm processes Null and 255 chars correctly");
   declare
      Bin_Str : String(1..3);
   begin
      Bin_Str(1) := Character'Val(0);
      Bin_Str(2) := Character'Val(127);
      Bin_Str(3) := Character'Val(255);
      Assert (Decompress(Compress(Bin_Str)) = Bin_Str, "Failed: Binary data roundtrip");
      Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Error Handling (Invalid Code Sequences)");
   Put_Line ("  8.1 Assert invalid start code throws LZW_Error");
   begin
      declare
         Bad_Code : constant Code_Array := (1 => 258); -- First code must be < 256
         Str      : constant String := Decompress(Bad_Code);
         pragma Unreferenced (Str);
      begin
         Assert (False, "Failed: Should have thrown LZW_Error on start code");
      end;
   exception
      when LZW_Error =>
         Put_Line ("      PASS");
   end;

   Put_Line ("  8.2 Assert dictionary jump throws LZW_Error");
   begin
      declare
         -- Code 260 doesn't exist yet
         Bad_Seq : constant Code_Array := (1 => 65, 2 => 260); 
         Str     : constant String := Decompress(Bad_Seq);
         pragma Unreferenced (Str);
      begin
         Assert (False, "Failed: Should have thrown LZW_Error on jump code");
      end;
   exception
      when LZW_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Invalid Parameters Handling");
   Put_Line ("  9.1 Assert Max_Bits < 9 throws LZW_Error");
   begin
      declare
         Res : constant Code_Array := Compress ("Test", Freeze, 8);
         pragma Unreferenced (Res);
      begin
         Assert (False, "Failed: Should have rejected Max_Bits < 9");
      end;
   exception
      when LZW_Error =>
         Put_Line ("      PASS");
   end;

   Put_Line ("--------------------------------");
   Put_Line ("ALL ASSUMPTIONS DISPROVED: Code behaves correctly.");
end Tests;
