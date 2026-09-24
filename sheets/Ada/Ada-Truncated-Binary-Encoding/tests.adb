with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with Truncated_Binary; use Truncated_Binary;

procedure Tests is

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line("      FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;

   Consumed : Natural;

begin
   Put_Line("=========================================");
   Put_Line("TRUNCATED BINARY ENCODING - TEST SUITE");
   Put_Line("=========================================");

   -- TEST 1 - Functionality: Standard k-bit encoding (Lower bounds)
   Put_Line("TEST 1 - Standard K-bit encoding");
   Put_Line("  1.1 Assert Encode(X=0, N=5) returns '00'");
   Assert (Encode(0, 5) = "00", "Encoding failed for standard K-bit route");
   Put_Line("    PASS");

   -- TEST 2 - Functionality: Standard k-bit encoding (Upper bounds of k-bits)
   Put_Line("TEST 2 - K-bit boundary encoding");
   Put_Line("  2.1 Assert Encode(X=2, N=5) returns '10'");
   Assert (Encode(2, 5) = "10", "Boundary K-bit encoding failed");
   Put_Line("    PASS");

   -- TEST 3 - Functionality: Shifted (k+1)-bit encoding (Lower bounds)
   Put_Line("TEST 3 - Shifted K+1 bit encoding lower bounds");
   Put_Line("  3.1 Assert Encode(X=3, N=5) returns '110'");
   Assert (Encode(3, 5) = "110", "Shifted encoding failed");
   Put_Line("    PASS");

   -- TEST 4 - Functionality: Shifted (k+1)-bit encoding (Upper bounds)
   Put_Line("TEST 4 - Shifted K+1 bit encoding upper bounds");
   Put_Line("  4.1 Assert Encode(X=4, N=5) returns '111'");
   Assert (Encode(4, 5) = "111", "Shifted encoding failed");
   Put_Line("    PASS");

   -- TEST 5 - Edge Case: N is a power of 2
   Put_Line("TEST 5 - N as a Power of 2 (Standard binary equivalent)");
   Put_Line("  5.1 Assert Encode(X=7, N=8) returns '111' (No shifting required)");
   Assert (Encode(7, 8) = "111", "Power of 2 optimization failed");
   Put_Line("    PASS");

   -- TEST 6 - Edge Case: Alphabet size of 1
   Put_Line("TEST 6 - Alphabet Size 1");
   Put_Line("  6.1 Assert Encode(X=0, N=1) requires 0 bits (Empty string)");
   Assert (Encode(0, 1) = "", "Empty string expected for N=1");
   Put_Line("    PASS");

   -- TEST 7 - Validation: Exact Decoding Success
   Put_Line("TEST 7 - Decode_Exact Success");
   Put_Line("  7.1 Assert Decode_Exact('111', N=5) yields Symbol 4");
   Assert (Decode_Exact("111", 5) = 4, "Exact decoding mismatch");
   Put_Line("    PASS");

   -- TEST 8 - Validation: Stream Decoding with Trailing Bits
   Put_Line("TEST 8 - Stream Decoding");
   Put_Line("  8.1 Assert Decode('1011', N=5) reads '10' and leaves '11'");
   Assert (Decode("1011", 5, Consumed) = 2, "Stream decoded wrong symbol");
   Put_Line("  8.2 Assert Consumed bit count is exactly 2");
   Assert (Consumed = 2, "Stream consumed wrong number of bits");
   Put_Line("    PASS");

   -- TEST 9 - Robustness: Out-of-bounds Symbol
   Put_Line("TEST 9 - Invalid Symbol Protection");
   Put_Line("  9.1 Assert encoding X=5 for N=5 raises Invalid_Symbol_Error");
   begin
      declare
         Result : String := Encode(5, 5);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Symbol_Error => Put_Line("    PASS");
   end;

   -- TEST 10 - Robustness: Invalid Alphabet Constraints
   Put_Line("TEST 10 - Strong Typing Enforcement (N=0)");
   Put_Line("  10.1 Assert N=0 causes Constraint_Error at boundary layer");
   begin
      declare
         -- Bypass static compiler check by evaluating the '0' at runtime, 
         -- proving the runtime environment still protects the boundary.
         Zero_N : Alphabet_Size := Alphabet_Size(Natural'Value("0"));
      begin
         Assert (False, "Should have caught 0 at type boundary");
      end;
   exception
      when Constraint_Error => Put_Line("    PASS");
   end;

   -- TEST 11 - Robustness: String truncation error
   Put_Line("TEST 11 - Decoded string missing bits");
   Put_Line("  11.1 Assert Decode('11', N=5) raises Decoding_Error (expects 3 bits)");
   begin
      declare
         Result : Symbol_Value := Decode_Exact("11", 5);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Decoding_Error => Put_Line("    PASS");
   end;

   -- TEST 12 - Robustness: Invalid Bit Characters
   Put_Line("TEST 12 - Invalid Characters in Bitstream");
   Put_Line("  12.1 Assert Decode('1a0', N=5) raises Decoding_Error");
   begin
      declare
         Result : Symbol_Value := Decode_Exact("1a0", 5);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Decoding_Error => Put_Line("    PASS");
   end;

   -- TEST 13 - Robustness: Decode_Exact with excess bits
   Put_Line("TEST 13 - Strict Decoding Validation");
   Put_Line("  13.1 Assert Decode_Exact('001', N=5) raises Decoding_Error due to trailing '1'");
   begin
      declare
         Result : Symbol_Value := Decode_Exact("001", 5);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Decoding_Error => Put_Line("    PASS");
   end;

   -- TEST 14 - Functionality: Large value bounds
   Put_Line("TEST 14 - Large N Encoding Behavior");
   Put_Line("  14.1 Assert Encode(X=99, N=100) returns 7-bit string '1111111'");
   Assert (Encode(99, 100) = "1111111", "Large N calculation failed");
   Put_Line("    PASS");
   
   Put_Line("=========================================");
   Put_Line("ALL TESTS PROVED CORRECT. SYSTEM VERIFIED.");

end Tests;
