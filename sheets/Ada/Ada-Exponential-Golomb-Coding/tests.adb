with Ada.Text_IO; use Ada.Text_IO;
with Exponential_Golomb; use Exponential_Golomb;

procedure Tests is

   -- Custom assert to evaluate the pessimistic assumption
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;

   Consumed : Natural;
   Decoded_Unsigned : Natural;
   Decoded_Signed   : Integer;
begin
   Put_Line ("=====================================================");
   Put_Line ("EXP-GOLOMB VERIFICATION AND VALIDATION TEST SUITE");
   Put_Line ("=====================================================");

   -- TEST 1
   Put_Line ("TEST 1 - Order-0 Unsigned Normal Encoding");
   Put_Line ("  1.1 Assert Value 0 encodes to '1'");
   Assert (Encode_Order_0_Unsigned (0) = "1", "0 encoding failed");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Order-0 Unsigned Boundary Encoding");
   Put_Line ("  2.1 Assert Value 8 encodes to '0001001'");
   Assert (Encode_Order_0_Unsigned (8) = "0001001", "8 encoding failed");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Order-0 Unsigned Decoding Verification");
   Put_Line ("  3.1 Assert '010' decodes to 1 and consumes 3 bits");
   Decoded_Unsigned := Decode_Order_0_Unsigned ("010", Consumed);
   Assert (Decoded_Unsigned = 1, "Decode 010 failed");
   Assert (Consumed = 3, "Consumed bits incorrect for 010");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Order-K Unsigned Encoding (K=1)");
   Put_Line ("  4.1 Assert Value 4 with K=1 encodes to '0110'");
   Assert (Encode_Order_K_Unsigned (4, 1) = "0110", "K=1 encoding failed");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Order-K Unsigned Edge Case (K=0)");
   Put_Line ("  5.1 Assert Order-K (K=0) matches Order-0 for Value 5");
   Assert (Encode_Order_K_Unsigned (5, 0) = Encode_Order_0_Unsigned (5), "K=0 equivalence failed");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Order-K Unsigned Decoding (K=2)");
   Put_Line ("  6.1 Assert '01110' decodes to 14, consumed 5");
   Assert (Encode_Order_K_Unsigned (14, 2) = "0010010", "14 with K=2 encoding check");
   Decoded_Unsigned := Decode_Order_K_Unsigned ("0010010", 2, Consumed);
   Assert (Decoded_Unsigned = 14, "Decode Order-K failed");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Order-0 Signed Positive Encoding");
   Put_Line ("  7.1 Assert Value 2 encodes to '00100' (maps to 3)");
   Assert (Encode_Order_0_Signed (2) = "00100", "Signed pos encoding failed");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Order-0 Signed Negative Encoding");
   Put_Line ("  8.1 Assert Value -2 encodes to '00101' (maps to 4)");
   Assert (Encode_Order_0_Signed (-2) = "00101", "Signed neg encoding failed");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Order-0 Signed Decoding");
   Put_Line ("  9.1 Assert '00101' decodes to -2");
   Decoded_Signed := Decode_Order_0_Signed ("00101", Consumed);
   Assert (Decoded_Signed = -2, "Signed decode failed");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Order-K Signed Encoding (K=1)");
   Put_Line ("  10.1 Assert Value -2, K=1 encodes mapped 4 -> '0110'");
   Assert (Encode_Order_K_Signed (-2, 1) = "0110", "Signed K=1 failed");
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Order-K Signed Decoding (K=1)");
   Put_Line ("  11.1 Assert '0110' with K=1 decodes to -2");
   Decoded_Signed := Decode_Order_K_Signed ("0110", 1, Consumed);
   Assert (Decoded_Signed = -2, "Decode signed K=1 failed");
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Error Handling: Empty Stream");
   Put_Line ("  12.1 Assert Decoding empty string raises Decoding_Error");
   begin
      Decoded_Unsigned := Decode_Order_0_Unsigned ("", Consumed);
      Assert (False, "Should have raised exception");
   exception
      when Decoding_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Error Handling: Missing Terminating Bit");
   Put_Line ("  13.1 Assert Decoding '000' raises Decoding_Error");
   begin
      Decoded_Unsigned := Decode_Order_0_Unsigned ("000", Consumed);
      Assert (False, "Should have raised exception");
   exception
      when Decoding_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 14
   Put_Line ("TEST 14 - Error Handling: Truncated Remainder in Order-K");
   Put_Line ("  14.1 Assert Decoding '011' with K=2 raises Decoding_Error");
   begin
      Decoded_Unsigned := Decode_Order_K_Unsigned ("011", 2, Consumed);
      Assert (False, "Should have raised exception");
   exception
      when Decoding_Error =>
         Put_Line ("      PASS");
   end;

end Tests;
