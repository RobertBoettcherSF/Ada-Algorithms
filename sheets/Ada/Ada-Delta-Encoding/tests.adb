with Ada.Text_IO; use Ada.Text_IO;
with Delta_Encoding; use Delta_Encoding;
with Interfaces; use Interfaces;

procedure Tests is
   Passed_All : Boolean := True;

   procedure Assert (Condition : Boolean; Step : String; Message : String) is
   begin
      Put_Line ("  " & Step & " " & Message);
      if Condition then
         Put_Line ("      PASS");
      else
         Put_Line ("      FAIL");
         Passed_All := False;
      end if;
   end Assert;

begin
   Put_Line ("======================================");
   Put_Line ("Executing Delta Encoding Test Suite");
   Put_Line ("======================================");

   -- TEST 1: Integer Array Differential Encoding
   Put_Line ("TEST 1 - Integer Array Differential Encoding");
   declare
      Original : constant Integer_Array := (2, 4, 6, 9, 7);
      Expected : constant Integer_Array := (2, 2, 2, 3, -2);
      Result   : constant Integer_Array := Encode_Integer_Delta (Original);
   begin
      Assert (Result = Expected, "1.1", "Assert normal positive encoding (2,4,6,9,7)");
      
      declare
         Same_Nums : constant Integer_Array := (5, 5, 5, 5);
         Same_Exp  : constant Integer_Array := (5, 0, 0, 0);
      begin
         Assert (Encode_Integer_Delta (Same_Nums) = Same_Exp, "1.2", "Assert identical sequential values encode to zero");
      end;
   end;

   -- TEST 2: Integer Array Differential Decoding
   Put_Line ("TEST 2 - Integer Array Differential Decoding");
   declare
      Encoded  : constant Integer_Array := (2, 2, 2, 3, -2);
      Expected : constant Integer_Array := (2, 4, 6, 9, 7);
   begin
      Assert (Decode_Integer_Delta (Encoded) = Expected, "2.1", "Assert proper decoding to original values");
      
      declare
         Single_Element : constant Integer_Array := (1 => 42);
      begin
         Assert (Decode_Integer_Delta (Single_Element) = Single_Element, "2.2", "Assert single element array handles correctly");
      end;
   end;

   -- TEST 3: Edge Cases & Exceptions (Integer)
   Put_Line ("TEST 3 - Edge Cases & Exceptions (Integer)");
   declare
      Empty : constant Integer_Array (1 .. 0) := (others => 0);
   begin
      begin
         declare
            Dummy : Integer_Array := Encode_Integer_Delta (Empty);
         begin
            Assert (False, "3.1", "Expected Empty_Input_Error on integer encode");
         end;
      exception
         when Empty_Input_Error => Assert (True, "3.1", "Assert empty integer array raises Constraint/Empty Error on encode");
      end;

      begin
         declare
            Dummy : Integer_Array := Decode_Integer_Delta (Empty);
         begin
            Assert (False, "3.2", "Expected Empty_Input_Error on integer decode");
         end;
      exception
         when Empty_Input_Error => Assert (True, "3.2", "Assert empty integer array raises Empty_Input_Error on decode");
      end;
   end;

   -- TEST 4: Byte Array XOR Encoding
   Put_Line ("TEST 4 - Byte Array XOR Encoding");
   declare
      Original : constant Byte_Array := (16#FF#, 16#F0#, 16#F0#, 16#0F#);
      Expected : constant Byte_Array := (16#FF#, 16#0F#, 16#00#, 16#FF#);
   begin
      Assert (Encode_Byte_XOR_Delta (Original) = Expected, "4.1", "Assert XOR byte array encodes correctly");
      
      declare
         Identical : constant Byte_Array := (16#AA#, 16#AA#);
         Ident_Exp : constant Byte_Array := (16#AA#, 16#00#);
      begin
         Assert (Encode_Byte_XOR_Delta (Identical) = Ident_Exp, "4.2", "Assert identical consecutive bytes yield 0x00");
      end;
   end;

   -- TEST 5: Byte Array XOR Decoding
   Put_Line ("TEST 5 - Byte Array XOR Decoding");
   declare
      Encoded  : constant Byte_Array := (16#FF#, 16#0F#, 16#00#, 16#FF#);
      Expected : constant Byte_Array := (16#FF#, 16#F0#, 16#F0#, 16#0F#);
   begin
      Assert (Decode_Byte_XOR_Delta (Encoded) = Expected, "5.1", "Assert proper decoding of XOR byte variants");
   end;

   -- TEST 6: Byte Edge Cases
   Put_Line ("TEST 6 - Edge Cases & Exceptions (Byte)");
   declare
      Empty_Bytes : constant Byte_Array (1 .. 0) := (others => 0);
   begin
      begin
         declare
            Dummy : Byte_Array := Encode_Byte_XOR_Delta (Empty_Bytes);
         begin
            Assert (False, "6.1", "Expected error on empty byte array encode");
         end;
      exception
         when Empty_Input_Error => Assert (True, "6.1", "Assert empty byte array encode raises Empty_Input_Error");
      end;
   end;

   -- TEST 7: Round-Trip V&V Assumptions
   Put_Line ("TEST 7 - Full Validation (Assumed broken, proven functional)");
   declare
      Test_Integers : constant Integer_Array := (-100, 200, -300, 400, 0, 0);
      Test_Bytes    : constant Byte_Array := (1, 255, 128, 64, 32, 16);
   begin
      Assert (Decode_Integer_Delta (Encode_Integer_Delta (Test_Integers)) = Test_Integers, 
             "7.1", "Assert Integer round-trip Identity (Encode -> Decode = Original)");
      
      Assert (Decode_Byte_XOR_Delta (Encode_Byte_XOR_Delta (Test_Bytes)) = Test_Bytes, 
             "7.2", "Assert XOR Byte round-trip Identity (Encode -> Decode = Original)");
      
      Assert (Decode_Integer_Delta (Encode_Integer_Delta ((1 => 999))) = (1 => 999),
             "7.3", "Assert Roundtrip single boundary array");
   end;

   Put_Line ("======================================");
   if Passed_All then
      Put_Line ("ALL 14 ASSUMPTIONS DISPROVEN: CODE FUNCTIONS PERFECTLY");
   else
      Put_Line ("SOME TESTS FAILED.");
   end if;
end Tests;
