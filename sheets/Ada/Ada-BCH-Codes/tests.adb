with Ada.Text_IO; use Ada.Text_IO;
with BCH_Codes; use BCH_Codes;

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
   Put_Line ("=== Starting BCH Code Test Suite ===");

   -- TEST 1 — Basic Encoding and Validity
   Put_Line ("TEST 1 — Basic Encoding and Validity");
   declare
      Msg : constant Message_Type := [1, 0, 1, 1, 0, 1, 0];
      CW : constant Codeword_Type := Encode (Msg);
   begin
      Check ("1.1 Codeword length is N", CW'Length = N);
      Check ("1.2 Encoded message matches source message prefix", (for all I in Msg'Range => CW (I) = Msg (I)));
      Check ("1.3 Encoded codeword is recognized as valid", Is_Valid_Codeword (CW));
   end;

   -- TEST 2 — Alternative Message Encoding
   Put_Line ("TEST 2 — Alternative Message Encoding");
   declare
      Msg : constant Message_Type := [0, 1, 1, 0, 1, 0, 1];
      CW : constant Codeword_Type := Encode (Msg);
   begin
      Check ("2.1 Codeword length is correct", CW'Length = N);
      Check ("2.2 Message part preserved", (for all I in Msg'Range => CW (I) = Msg (I)));
      Check ("2.3 Codeword validity check passes", Is_Valid_Codeword (CW));
   end;

   -- TEST 3 — All-Zero Message
   Put_Line ("TEST 3 — All-Zero Message");
   declare
      Msg : constant Message_Type := [others => 0];
      CW : constant Codeword_Type := Encode (Msg);
   begin
      Check ("3.1 All-zero message encodes successfully", CW'Length = N);
      Check ("3.2 All-zero codeword is all zeros", (for all B of CW => B = 0));
      Check ("3.3 All-zero codeword is valid", Is_Valid_Codeword (CW));
   end;

   -- TEST 4 — All-One Message
   Put_Line ("TEST 4 — All-One Message");
   declare
      Msg : constant Message_Type := [others => 1];
      CW : constant Codeword_Type := Encode (Msg);
   begin
      Check ("4.1 All-one message encodes successfully", CW'Length = N);
      Check ("4.2 Message part is all ones", (for all B of CW (1 .. K) => B = 1));
      Check ("4.3 All-one generated codeword is valid", Is_Valid_Codeword (CW));
   end;

   -- TEST 5 — Syndrome Computation on Valid Codeword
   Put_Line ("TEST 5 — Syndrome Computation on Valid Codeword");
   declare
      Msg : constant Message_Type := [1, 1, 0, 0, 1, 1, 0];
      CW : constant Codeword_Type := Encode (Msg);
      Syms : constant Syndrome_Array := Compute_Syndromes (CW);
   begin
      Check ("5.1 Syndrome array length is 2*T", Syms'Length = 2 * T);
      Check ("5.2 First syndrome is zero for valid codeword", Syms (1) = 0);
      Check ("5.3 All syndromes are zero for valid codeword", (for all S of Syms => S = 0));
   end;

   -- TEST 6 — Syndrome Computation on Corrupted Codeword
   Put_Line ("TEST 6 — Syndrome Computation on Corrupted Codeword");
   declare
      Msg : constant Message_Type := [1, 0, 1, 0, 1, 0, 1];
      CW : constant Codeword_Type := Encode (Msg);
      Corrupted : Codeword_Type := CW;
      Syms : Syndrome_Array;
   begin
      Corrupted (3) := Corrupted (3) xor 1;
      Syms := Compute_Syndromes (Corrupted);
      Check ("6.1 Syndrome array length correct", Syms'Length = 4);
      Check ("6.2 First syndrome non-zero after corruption", Syms (1) /= 0);
      Check ("6.3 Codeword no longer valid", not Is_Valid_Codeword (Corrupted));
   end;

   -- TEST 7 — Decoding Zero-Error Codeword
   Put_Line ("TEST 7 — Decoding Zero-Error Codeword");
   declare
      Msg : constant Message_Type := [0, 0, 1, 1, 1, 0, 0];
      CW : constant Codeword_Type := Encode (Msg);
      Decoded : constant Codeword_Type := Decode (CW);
   begin
      Check ("7.1 Decoded length matches N", Decoded'Length = N);
      Check ("7.2 Decoded matches original codeword", Decoded = CW);
      Check ("7.3 Decoded codeword is valid", Is_Valid_Codeword (Decoded));
   end;

   -- TEST 8 — Decoding Single-Error Codeword
   Put_Line ("TEST 8 — Decoding Single-Error Codeword");
   declare
      Msg : constant Message_Type := [1, 0, 1, 1, 1, 1, 0];
      CW : constant Codeword_Type := Encode (Msg);
      Corrupted : Codeword_Type := CW;
      Decoded : Codeword_Type;
   begin
      Corrupted (5) := Corrupted (5) xor 1;
      Decoded := Decode (Corrupted);
      Check ("8.1 Decoded length is N", Decoded'Length = N);
      Check ("8.2 Single error corrected successfully", Decoded = CW);
      Check ("8.3 Decoded codeword is valid", Is_Valid_Codeword (Decoded));
   end;

   -- TEST 9 — Decoding Double-Error Codeword
   Put_Line ("TEST 9 — Decoding Double-Error Codeword");
   declare
      Msg : constant Message_Type := [1, 1, 0, 1, 0, 1, 1];
      CW : constant Codeword_Type := Encode (Msg);
      Corrupted : Codeword_Type := CW;
      Decoded : Codeword_Type;
   begin
      Corrupted (2) := Corrupted (2) xor 1;
      Corrupted (12) := Corrupted (12) xor 1;
      Decoded := Decode (Corrupted);
      Check ("9.1 Decoded length is N", Decoded'Length = N);
      Check ("9.2 Double errors corrected successfully", Decoded = CW);
      Check ("9.3 Decoded codeword is valid", Is_Valid_Codeword (Decoded));
   end;

   -- TEST 10 — Decoding Single-Error at Position 1
   Put_Line ("TEST 10 — Decoding Single-Error at Position 1");
   declare
      Msg : constant Message_Type := [0, 1, 0, 1, 0, 1, 0];
      CW : constant Codeword_Type := Encode (Msg);
      Corrupted : Codeword_Type := CW;
      Decoded : Codeword_Type;
   begin
      Corrupted (1) := Corrupted (1) xor 1;
      Decoded := Decode (Corrupted);
      Check ("10.1 Length correct", Decoded'Length = N);
      Check ("10.2 Error at pos 1 corrected", Decoded = CW);
      Check ("10.3 Valid result", Is_Valid_Codeword (Decoded));
   end;

   -- TEST 11 — Decoding Double-Error at Edge Positions
   Put_Line ("TEST 11 — Decoding Double-Error at Edge Positions");
   declare
      Msg : constant Message_Type := [1, 0, 0, 0, 1, 1, 1];
      CW : constant Codeword_Type := Encode (Msg);
      Corrupted : Codeword_Type := CW;
      Decoded : Codeword_Type;
   begin
      Corrupted (1) := Corrupted (1) xor 1;
      Corrupted (N) := Corrupted (N) xor 1;
      Decoded := Decode (Corrupted);
      Check ("11.1 Length correct", Decoded'Length = N);
      Check ("11.2 Edge errors corrected", Decoded = CW);
      Check ("11.3 Valid result", Is_Valid_Codeword (Decoded));
   end;

   -- TEST 12 — Alternating Bit Message
   Put_Line ("TEST 12 — Alternating Bit Message");
   declare
      Msg : constant Message_Type := [1, 0, 1, 0, 1, 0, 1];
      CW : constant Codeword_Type := Encode (Msg);
      Decoded : constant Codeword_Type := Decode (CW);
   begin
      Check ("12.1 Length correct", Decoded'Length = N);
      Check ("12.2 Alternating pattern encodes and decodes correctly", Decoded = CW);
      Check ("12.3 Valid codeword", Is_Valid_Codeword (Decoded));
   end;

   -- TEST 13 — Uncorrectable Error Handling
   Put_Line ("TEST 13 — Uncorrectable Error Handling");
   declare
      Msg : constant Message_Type := [1, 1, 1, 0, 0, 0, 1];
      CW : constant Codeword_Type := Encode (Msg);
      Corrupted : Codeword_Type := CW;
      Exception_Raised : Boolean := False;
   begin
      Corrupted (1) := Corrupted (1) xor 1;
      Corrupted (5) := Corrupted (5) xor 1;
      Corrupted (10) := Corrupted (10) xor 1;
      begin
         declare
            Dummy : constant Codeword_Type := Decode (Corrupted);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Decoding_Failed_Error =>
            Exception_Raised := True;
      end;
      Check ("13.1 Length of codeword is N", Corrupted'Length = N);
      Check ("13.2 Uncorrectable errors detected", not Is_Valid_Codeword (Corrupted));
      Check ("13.3 Decoding_Failed_Error raised for >t errors", Exception_Raised);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
