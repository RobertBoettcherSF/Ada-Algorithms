with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with SPIHT; use SPIHT;

procedure Tests is
   Total_Tests : constant Natural := 13;
   Passed_Tests : Natural := 0;

   procedure Run_Test_1 is
   begin
      Put_Line ("TEST 1 - Robustness: Invalid Dimensions");
      Put_Line ("  1.1 Assume: Code fails to reject non-power-of-2 matrices.");
      Put_Line ("  1.2 Assert: Invalid_Size_Error is raised for 3x3 matrix.");
      declare
         Mat : constant Matrix_2D (1..3, 1..3) := (others => (others => 0));
         Bits : Bit_Stream;
      begin
         Encode_2D (Mat, 100, Lossless, Bits);
         Assert (False, "Failed: Expected Invalid_Size_Error");
      exception
         when Invalid_Size_Error =>
            Put_Line ("      PASS: Assumption disproven. Exception handled safely.");
            Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_1;

   procedure Run_Test_2 is
   begin
      Put_Line ("TEST 2 - Robustness: Empty Input");
      Put_Line ("  2.1 Assume: Empty matrix causes out-of-bounds crash.");
      Put_Line ("  2.2 Assert: Empty_Input_Error is gracefully raised.");
      declare
         Mat : constant Matrix_2D (1..0, 1..0) := (others => (others => 0));
         Bits : Bit_Stream;
      begin
         Encode_2D (Mat, 100, Lossless, Bits);
         Assert (False, "Failed: Expected Empty_Input_Error");
      exception
         when Empty_Input_Error =>
            Put_Line ("      PASS: Assumption disproven. Empty input caught.");
            Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_2;

   procedure Run_Test_3 is
   begin
      Put_Line ("TEST 3 - Correctness: Power of 2 Utility");
      Put_Line ("  3.1 Assume: Is_Power_Of_Two calculates incorrectly.");
      Put_Line ("  3.2 Assert: 16 is True, 15 is False, 1 is True.");
      Assert (Is_Power_Of_Two(16), "16 should be true");
      Assert (not Is_Power_Of_Two(15), "15 should be false");
      Assert (Is_Power_Of_Two(1), "1 should be true");
      Put_Line ("      PASS: Assumption disproven. Math is correct.");
      Passed_Tests := Passed_Tests + 1;
   end Run_Test_3;

   procedure Run_Test_4 is
   begin
      Put_Line ("TEST 4 - Correctness: Zero Matrix Handling");
      Put_Line ("  4.1 Assume: Algorithm enters infinite loop on zero matrix.");
      Put_Line ("  4.2 Assert: Output stream is exactly 0 length.");
      declare
         Mat : constant Matrix_2D (1..4, 1..4) := (others => (others => 0));
         Bits : Bit_Stream;
      begin
         Encode_2D (Mat, 100, Lossless, Bits);
         Assert (Natural(Bits.Length) = 0, "Zero matrix must produce empty stream");
         Put_Line ("      PASS: Assumption disproven. Zero matrices handled.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_4;

   procedure Run_Test_5 is
   begin
      Put_Line ("TEST 5 - Correctness: Magnitude Calculation 2D");
      Put_Line ("  5.1 Assume: Max_Magnitude_2D misses absolute max value.");
      declare
         Mat : Matrix_2D (1..2, 1..2) := ((1, -50), (20, 3));
      begin
         Assert (Max_Magnitude_2D(Mat) = 50, "Max magnitude should be 50");
         Put_Line ("      PASS: Assumption disproven. Absolute max extracted properly.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_5;

   procedure Run_Test_6 is
   begin
      Put_Line ("TEST 6 - Functionality: Rate-Constrained Lossy Targeting");
      Put_Line ("  6.1 Assume: Lossy variant ignores Target_Bits constraint.");
      Put_Line ("  6.2 Assert: Output stream size exactly matches target limit (5).");
      declare
         Mat : Matrix_2D (1..4, 1..4) := (others => (others => 10));
         Bits : Bit_Stream;
      begin
         Encode_2D (Mat, 5, Lossy_Target_Bits, Bits);
         Assert (Natural(Bits.Length) = 5, "Stream exceeded limit!");
         Put_Line ("      PASS: Assumption disproven. Constraint respected.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_6;

   procedure Run_Test_7 is
   begin
      Put_Line ("TEST 7 - Functionality: Lossless Encoding Completes");
      Put_Line ("  7.1 Assume: Lossless variant fails to encode single high value.");
      declare
         Mat : Matrix_2D (1..2, 1..2) := ((8, 0), (0, 0));
         Bits : Bit_Stream;
      begin
         Encode_2D (Mat, 1000, Lossless, Bits);
         Assert (Natural(Bits.Length) > 0, "Stream should have data");
         Put_Line ("      PASS: Assumption disproven. Lossless completes.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_7;

   procedure Run_Test_8 is
   begin
      Put_Line ("TEST 8 - Functionality: 3D SPIHT Variant");
      Put_Line ("  8.1 Assume: 3D extension raises unhandled exception on valid input.");
      declare
         Mat : Matrix_3D (1..2, 1..2, 1..2) := (others => (others => (others => 5)));
         Bits : Bit_Stream;
      begin
         Encode_3D (Mat, 100, Lossless, Bits);
         Assert (Natural(Bits.Length) > 0, "3D encoding failed to yield bits");
         Put_Line ("      PASS: Assumption disproven. 3D variant functional.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_8;

   procedure Run_Test_9 is
   begin
      Put_Line ("TEST 9 - Correctness: Magnitude Calculation 3D");
      Put_Line ("  9.1 Assume: Max_Magnitude_3D fails on depth tracking.");
      declare
         Mat : Matrix_3D (1..2, 1..2, 1..2) := (others => (others => (others => 0)));
      begin
         Mat (2, 1, 2) := -128;
         Assert (Max_Magnitude_3D(Mat) = 128, "Max magnitude should be 128");
         Put_Line ("      PASS: Assumption disproven. 3D traversal is correct.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_9;
   
   procedure Run_Test_10 is
   begin
      Put_Line ("TEST 10 - Edge Case: Single Element Array (Power of 2 = 2^0)");
      Put_Line ("  10.1 Assume: 1x1 Array causes loop bound crashes.");
      declare
         Mat : Matrix_2D (1..1, 1..1) := (others => (others => 10));
         Bits : Bit_Stream;
      begin
         Encode_2D(Mat, 100, Lossless, Bits);
         Assert(Natural(Bits.Length) > 0, "Failed to encode 1x1");
         Put_Line ("      PASS: Assumption disproven. 1x1 supported safely.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_10;

   procedure Run_Test_11 is
   begin
      Put_Line ("TEST 11 - State: Target Bits = 0 Edge Case");
      Put_Line ("  11.1 Assume: Setting Target_Bits to 0 causes infinite loop or crash.");
      declare
         Mat : Matrix_2D (1..2, 1..2) := (others => (others => 50));
         Bits : Bit_Stream;
      begin
         Encode_2D(Mat, 0, Lossy_Target_Bits, Bits);
         Assert(Natural(Bits.Length) = 0, "Should generate 0 bits");
         Put_Line ("      PASS: Assumption disproven. Truncates properly at 0.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_11;

   procedure Run_Test_12 is
   begin
      Put_Line ("TEST 12 - Logic: Bit sequence evaluation for positive coeff");
      Put_Line ("  12.1 Assume: Sign bit encoding maps positive values to 0 incorrectly.");
      declare
         Mat : Matrix_2D (1..2, 1..2) := ((10, 0), (0, 0));
         Bits : Bit_Stream;
      begin
         Encode_2D(Mat, 100, Lossless, Bits);
         -- In SPIHT, passing threshold appends '1', followed by sign bit '1' for positive
         Assert(Bits(2) = 1, "Sign bit must be 1 for positive numbers");
         Put_Line ("      PASS: Assumption disproven. Sign bits are correct.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_12;

   procedure Run_Test_13 is
   begin
      Put_Line ("TEST 13 - Logic: Bit sequence evaluation for negative coeff");
      Put_Line ("  13.1 Assume: Sign bit encoding maps negative values to 1 incorrectly.");
      declare
         Mat : Matrix_2D (1..2, 1..2) := ((-10, 0), (0, 0));
         Bits : Bit_Stream;
      begin
         Encode_2D(Mat, 100, Lossless, Bits);
         -- Sign bit is 0 for negative
         Assert(Bits(2) = 0, "Sign bit must be 0 for negative numbers");
         Put_Line ("      PASS: Assumption disproven. Negative signs correct.");
         Passed_Tests := Passed_Tests + 1;
      end;
   end Run_Test_13;

begin
   Put_Line ("=================================================");
   Put_Line ("     SPIHT VALIDATION & VERIFICATION SUITE       ");
   Put_Line ("=================================================");
   
   Run_Test_1;
   Run_Test_2;
   Run_Test_3;
   Run_Test_4;
   Run_Test_5;
   Run_Test_6;
   Run_Test_7;
   Run_Test_8;
   Run_Test_9;
   Run_Test_10;
   Run_Test_11;
   Run_Test_12;
   Run_Test_13;
   
   Put_Line ("=================================================");
   Put_Line ("RESULTS: " & Natural'Image(Passed_Tests) & " /" & Natural'Image(Total_Tests) & " Passed.");
   if Passed_Tests = Total_Tests then
      Put_Line ("STATUS: ALL SYSTEMS NOMINAL");
   else
      Put_Line ("STATUS: FAILURE DETECTED");
   end if;
end Tests;
