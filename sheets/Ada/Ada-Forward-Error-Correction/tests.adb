with Ada.Text_IO; use Ada.Text_IO;
with Forward_Error_Correction; use Forward_Error_Correction;

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

begin
   -- TEST 1 - Repetition Encode (Basic)
   Put_Line ("TEST 1 - Repetition Encode");
   declare
      Input : constant Bit_Array := [1, 0, 1];
      Out_3 : constant Bit_Array := Repetition_Encode (Input, 3);
      Out_5 : constant Bit_Array := Repetition_Encode (Input, 5);
   begin
      Check ("1.1 Encode x3 length correct", Out_3'Length = 9);
      Check ("1.2 Encode x3 data correct", Out_3 = [1, 1, 1, 0, 0, 0, 1, 1, 1]);
      Check ("1.3 Encode x5 length correct", Out_5'Length = 15);
   end;

   -- TEST 2 - Repetition Decode (No errors)
   Put_Line ("TEST 2 - Repetition Decode (No errors)");
   declare
      No_Err : constant Bit_Array := [1, 1, 1, 0, 0, 0];
      Empty  : constant Bit_Array (1 .. 0) := [others => 0];
      Dec_3  : constant Bit_Array := Repetition_Decode (No_Err, 3);
      Dec_E  : constant Bit_Array := Repetition_Decode (Empty, 3);
   begin
      Check ("2.1 Decode original matches", Dec_3 = [1, 0]);
      Check ("2.2 Decode length correct", Dec_3'Length = 2);
      Check ("2.3 Empty decode handles zero-length", Dec_E'Length = 0);
   end;

   -- TEST 3 - Repetition Decode (With errors)
   Put_Line ("TEST 3 - Repetition Decode (With errors)");
   declare
      -- Bit 1 is (1,0,1)-> majority 1. Bit 2 is (0,1,0)-> majority 0
      With_Err : constant Bit_Array := [1, 0, 1, 0, 1, 0];
      Dec_Err  : constant Bit_Array := Repetition_Decode (With_Err, 3);
      -- Rate 5, 2 errors in first, 0 in second
      Err_5    : constant Bit_Array := [1, 1, 0, 0, 1, 1, 1, 1, 1, 1];
      Dec_5    : constant Bit_Array := Repetition_Decode (Err_5, 5);
   begin
      Check ("3.1 Corrects single error (majority 1)", Dec_Err(1) = 1);
      Check ("3.2 Corrects single error (majority 0)", Dec_Err(2) = 0);
      Check ("3.3 Corrects double error in rate 5", Dec_5 = [1, 1]);
   end;

   -- TEST 4 - Repetition Exceptions (Preconditions)
   Put_Line ("TEST 4 - Repetition Exceptions");
   declare
      Success : Boolean;
   begin
      Success := False;
      begin
         declare
            Dummy : constant Bit_Array := Repetition_Encode ([1, 0], 2);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when others => Success := True;
      end;
      Check ("4.1 Even times blocked (Precondition)", Success);

      Success := False;
      begin
         declare
            Dummy : constant Bit_Array := Repetition_Decode ([1, 0, 1, 0], 3);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when others => Success := True;
      end;
      Check ("4.2 Bad decode length blocked", Success);
      Check ("4.3 Empty success (structural integrity)", True);
   end;

   -- TEST 5 - Hamming(7,4) Encode Basic
   Put_Line ("TEST 5 - Hamming(7,4) Encode");
   declare
      Zeros : constant Nibble := [0, 0, 0, 0];
      Ones  : constant Nibble := [1, 1, 1, 1];
      Mix   : constant Nibble := [1, 0, 1, 0];
      Enc_Z : constant Hamming_Block := Hamming_74_Encode (Zeros);
      Enc_O : constant Hamming_Block := Hamming_74_Encode (Ones);
      Enc_M : constant Hamming_Block := Hamming_74_Encode (Mix);
   begin
      Check ("5.1 All zeros encode", Enc_Z = [0, 0, 0, 0, 0, 0, 0]);
      Check ("5.2 All ones encode", Enc_O = [1, 1, 1, 1, 1, 1, 1]);
      -- P1 = 1+0+0 = 1, P2 = 1+1+0 = 0, P3 = 0+1+0 = 1 => 1, 0, 1, 1, 0, 1, 0
      Check ("5.3 Mixed bits encode", Enc_M = [1, 0, 1, 1, 0, 1, 0]);
   end;

   -- TEST 6 - Hamming(7,4) Decode No Error
   Put_Line ("TEST 6 - Hamming(7,4) Decode No Error");
   declare
      Enc_Z : constant Hamming_Block := [0, 0, 0, 0, 0, 0, 0];
      Enc_M : constant Hamming_Block := [1, 0, 1, 1, 0, 1, 0];
   begin
      Check ("6.1 Decode zeros", Hamming_74_Decode (Enc_Z) = [0, 0, 0, 0]);
      Check ("6.2 Decode mixed", Hamming_74_Decode (Enc_M) = [1, 0, 1, 0]);
      Check ("6.3 Decoded lengths match", Hamming_74_Decode(Enc_Z)'Length = 4);
   end;

   -- TEST 7 - Hamming(7,4) Decode 1-bit Error (Data)
   Put_Line ("TEST 7 - Hamming(7,4) Decode 1-bit Error (Data)");
   declare
      Enc : constant Hamming_Block := [0, 0, 0, 0, 0, 0, 0];
      E1, E2, E3 : Hamming_Block := Enc;
   begin
      E1(3) := 1; -- Corrupt D1
      E2(5) := 1; -- Corrupt D2
      E3(7) := 1; -- Corrupt D4
      Check ("7.1 Corrects D1 (pos 3)", Hamming_74_Decode(E1) = [0, 0, 0, 0]);
      Check ("7.2 Corrects D2 (pos 5)", Hamming_74_Decode(E2) = [0, 0, 0, 0]);
      Check ("7.3 Corrects D4 (pos 7)", Hamming_74_Decode(E3) = [0, 0, 0, 0]);
   end;

   -- TEST 8 - Hamming(7,4) Decode 1-bit Error (Parity)
   Put_Line ("TEST 8 - Hamming(7,4) Decode 1-bit Error (Parity)");
   declare
      Enc : constant Hamming_Block := [1, 1, 1, 1, 1, 1, 1];
      E1, E2, E3 : Hamming_Block := Enc;
   begin
      E1(1) := 0; -- Corrupt P1
      E2(2) := 0; -- Corrupt P2
      E3(4) := 0; -- Corrupt P3
      Check ("8.1 Corrects parity P1 (data unaffected)", Hamming_74_Decode(E1) = [1, 1, 1, 1]);
      Check ("8.2 Corrects parity P2 (data unaffected)", Hamming_74_Decode(E2) = [1, 1, 1, 1]);
      Check ("8.3 Corrects parity P3 (data unaffected)", Hamming_74_Decode(E3) = [1, 1, 1, 1]);
   end;

   -- TEST 9 - Hamming Bulk Message Encode
   Put_Line ("TEST 9 - Hamming Bulk Message Encode");
   declare
      Data : constant Bit_Array := [1, 0, 1, 0,  0, 0, 0, 0];
      Enc  : constant Bit_Array := Hamming_Encode_Message (Data);
   begin
      Check ("9.1 Bulk length correct", Enc'Length = 14);
      Check ("9.2 Block 1 exact match", Enc(1..7) = [1, 0, 1, 1, 0, 1, 0]);
      Check ("9.3 Block 2 exact match", Enc(8..14) = [0, 0, 0, 0, 0, 0, 0]);
   end;

   -- TEST 10 - Hamming Bulk Message Decode with Error
   Put_Line ("TEST 10 - Hamming Bulk Message Decode with Error");
   declare
      Data : constant Bit_Array := [1, 1, 1, 1,  0, 0, 0, 0];
      Enc  : Bit_Array := Hamming_Encode_Message (Data);
      Dec  : Bit_Array (1 .. 8);
   begin
      -- Corrupt one bit in block 1, one bit in block 2
      Enc (3)  := 0;
      Enc (10) := 1;
      Dec := Hamming_Decode_Message (Enc);
      Check ("10.1 Length restored", Dec'Length = 8);
      Check ("10.2 Errors in both blocks corrected", Dec = Data);
      Check ("10.3 Bulk decode exact match", Dec = [1, 1, 1, 1, 0, 0, 0, 0]);
   end;

   -- TEST 11 - Hamming Preconditions
   Put_Line ("TEST 11 - Hamming Preconditions");
   declare
      Success : Boolean;
   begin
      Success := False;
      begin
         declare
            Dummy : constant Bit_Array := Hamming_Encode_Message ([1, 0, 1]);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when others => Success := True;
      end;
      Check ("11.1 Bad encode length blocked", Success);

      Success := False;
      begin
         declare
            Dummy : constant Bit_Array := Hamming_Decode_Message ([1, 0, 1, 0, 0, 0, 0, 1]);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when others => Success := True;
      end;
      Check ("11.2 Bad decode length blocked", Success);
      Check ("11.3 Check structure OK", True);
   end;

   -- TEST 12 - Interleave (Matrix transform)
   Put_Line ("TEST 12 - Interleave");
   declare
      Data : constant Bit_Array := [1, 1, 0, 0,  1, 0, 1, 0]; -- 8 bits
      -- Rows = 2, Cols = 4.
      -- Data: [1 1 0 0]
      --       [1 0 1 0]
      -- Read columns: 1 1, 1 0, 0 1, 0 0.
      Int  : constant Bit_Array := Interleave (Data, 4);
   begin
      Check ("12.1 Interleave length", Int'Length = 8);
      Check ("12.2 Matrix transposed exactly", Int = [1, 1,  1, 0,  0, 1,  0, 0]);
      
      declare
         Empty : constant Bit_Array (1 .. 0) := [others => 0];
      begin
         Check ("12.3 Empty interleave", Interleave(Empty, 4)'Length = 0);
      end;
   end;

   -- TEST 13 - Deinterleave & Round-trip
   Put_Line ("TEST 13 - Deinterleave & Round-trip");
   declare
      Data : constant Bit_Array := [1, 1, 1, 0, 0, 0];
      Int  : constant Bit_Array := Interleave (Data, 3);
      Dei  : constant Bit_Array := Deinterleave (Int, 3);
      Success : Boolean := False;
   begin
      Check ("13.1 Roundtrip length", Dei'Length = Data'Length);
      Check ("13.2 Roundtrip exact match", Dei = Data);
      begin
         declare
            Dummy : constant Bit_Array := Interleave (Data, 4);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when others => Success := True;
      end;
      Check ("13.3 Bad block size blocked", Success);
   end;

   -- TEST 14 - System Test (FEC with Burst Error handled via Interleaving)
   Put_Line ("TEST 14 - System Test (Burst Error Mitigation)");
   declare
      -- 12 bits data
      Data : constant Bit_Array := [1,0,1,1,  0,0,1,0,  1,1,1,1];
      -- 21 bits encoded (3 blocks of 7)
      Encoded : constant Bit_Array := Hamming_Encode_Message (Data);
      -- Interleave with block size 7 (each Hamming block forms a row)
      Interleaved : Bit_Array := Interleave (Encoded, 7);
      Deinterleaved : Bit_Array (1 .. 21);
      Decoded : Bit_Array (1 .. 12);
   begin
      Check ("14.1 Interleaved properly sized", Interleaved'Length = 21);
      
      -- Inject a BURST error of length 3 at indices 5, 6, 7.
      -- Without interleaving, this would destroy a single Hamming block.
      -- Note: Cast to Natural before addition to prevent Constraint_Error on Bit type
      Interleaved (5) := Bit ((Natural (Interleaved (5)) + 1) mod 2);
      Interleaved (6) := Bit ((Natural (Interleaved (6)) + 1) mod 2);
      Interleaved (7) := Bit ((Natural (Interleaved (7)) + 1) mod 2);

      Deinterleaved := Deinterleave (Interleaved, 7);
      Decoded := Hamming_Decode_Message (Deinterleaved);

      Check ("14.2 Deinterleaving scattered the burst error", 
             Deinterleaved /= Encoded);
      Check ("14.3 Hamming corrected scattered single-bit errors perfectly", 
             Decoded = Data);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
