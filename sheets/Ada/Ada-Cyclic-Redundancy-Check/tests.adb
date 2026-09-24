-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Interfaces; use Interfaces;
with Cyclic_Redundancy_Check; use Cyclic_Redundancy_Check;

procedure Tests is
   Empty_Data : constant Data_Array (1 .. 0) := (others => 0);
   Test_Str   : constant String := "123456789";
   Test_Data  : Data_Array (1 .. Test_Str'Length);
   
   Table_BZIP2    : CRC_Table;
   Table_Ethernet : CRC_Table;
   Result         : Unsigned_32;
   
   -- Known industry standards for "123456789"
   Expected_BZIP2    : constant Unsigned_32 := 16#FC891918#;
   Expected_Ethernet : constant Unsigned_32 := 16#CBF43926#;
begin
   -- Initialize Test_Data byte array
   for I in Test_Str'Range loop
      Test_Data (I) := Character'Pos (Test_Str (I));
   end loop;

   Put_Line ("Starting Cyclic Redundancy Check (CRC) Test Suite...");
   Put_Line ("(Assumption: Code is broken. PASS = Assumption Disproved)");
   Put_Line ("--------------------------------------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - Normal Bit-By-Bit with Empty Data");
   Put_Line ("  1.1 Assert CRC correctly returns Init XOR Xor_Out without failing");
   Result := Compute_Bit_By_Bit (Empty_Data, CRC_32_BZIP2);
   Assert (Result = (CRC_32_BZIP2.Init xor CRC_32_BZIP2.Xor_Out), "Failed Empty Data Normal");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Reversed Bit-By-Bit with Empty Data");
   Put_Line ("  2.1 Assert CRC correctly returns Init XOR Xor_Out without failing");
   Result := Compute_Bit_By_Bit (Empty_Data, CRC_32_ETHERNET);
   Assert (Result = (CRC_32_ETHERNET.Init xor CRC_32_ETHERNET.Xor_Out), "Failed Empty Data Reversed");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Normal Table Generation");
   Put_Line ("  3.1 Assert table generates without constraint exception");
   Table_BZIP2 := Generate_Table (CRC_32_BZIP2);
   Put_Line ("      PASS");
   Put_Line ("  3.2 Assert Index 0 is strictly 0x00000000");
   Assert (Table_BZIP2 (0) = 0, "Table(0) must be 0 for Normal Poly");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Reversed Table Generation");
   Put_Line ("  4.1 Assert table generates without constraint exception");
   Table_Ethernet := Generate_Table (CRC_32_ETHERNET);
   Put_Line ("      PASS");
   Put_Line ("  4.2 Assert Index 0 is strictly 0x00000000");
   Assert (Table_Ethernet (0) = 0, "Table(0) must be 0 for Reversed Poly");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Standard Array Processing (BZIP2 / Normal)");
   Put_Line ("  5.1 Assert Bit-by-Bit matches expected industry standard 16#FC891918#");
   Result := Compute_Bit_By_Bit (Test_Data, CRC_32_BZIP2);
   Assert (Result = Expected_BZIP2, "Normal Bit-By-Bit mismatch");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Standard Array Processing (Ethernet / Reversed)");
   Put_Line ("  6.1 Assert Bit-by-Bit matches expected industry standard 16#CBF43926#");
   Result := Compute_Bit_By_Bit (Test_Data, CRC_32_ETHERNET);
   Assert (Result = Expected_Ethernet, "Reversed Bit-By-Bit mismatch");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Cross-variant Equivalence (Normal)");
   Put_Line ("  7.1 Assert Table-Driven exactly matches Bit-By-Bit output");
   Result := Compute_Table_Driven (Test_Data, CRC_32_BZIP2, Table_BZIP2);
   Assert (Result = Expected_BZIP2, "Normal Table-Driven differs from Bit-by-Bit");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Cross-variant Equivalence (Reversed)");
   Put_Line ("  8.1 Assert Table-Driven exactly matches Bit-By-Bit output");
   Result := Compute_Table_Driven (Test_Data, CRC_32_ETHERNET, Table_Ethernet);
   Assert (Result = Expected_Ethernet, "Reversed Table-Driven differs from Bit-by-Bit");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Single Byte Edge Case (Normal)");
   Put_Line ("  9.1 Assert processing a 1-element array resolves correctly");
   declare
      Single : Data_Array (1 .. 1) := (1 => 16#41#); -- Character 'A'
   begin
      Result := Compute_Bit_By_Bit (Single, CRC_32_BZIP2);
      Assert (Result = Compute_Table_Driven (Single, CRC_32_BZIP2, Table_BZIP2), "Single byte normal mismatch");
      Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Single Byte Edge Case (Reversed)");
   Put_Line ("  10.1 Assert processing a 1-element array resolves correctly");
   declare
      Single : Data_Array (1 .. 1) := (1 => 16#41#); 
   begin
      Result := Compute_Bit_By_Bit (Single, CRC_32_ETHERNET);
      Assert (Result = Compute_Table_Driven (Single, CRC_32_ETHERNET, Table_Ethernet), "Single byte reversed mismatch");
      Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Reflect_8 Bitwise Helper Verification");
   Put_Line ("  11.1 Assert 16#01# reflects to 16#80#");
   Assert (Reflect_8 (16#01#) = 16#80#, "Reflect_8 MSB to LSB failed");
   Put_Line ("      PASS");
   Put_Line ("  11.2 Assert 16#F0# reflects to 16#0F#");
   Assert (Reflect_8 (16#F0#) = 16#0F#, "Reflect_8 Nibble shift failed");
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Reflect_32 Bitwise Helper Verification");
   Put_Line ("  12.1 Assert 16#00000001# reflects to 16#80000000#");
   Assert (Reflect_32 (16#00000001#) = 16#80000000#, "Reflect_32 MSB to LSB failed");
   Put_Line ("      PASS");
   Put_Line ("  12.2 Assert 16#12345678# reflects correctly to 16#1E6A2C48#");
   Assert (Reflect_32 (16#12345678#) = 16#1E6A2C48#, "Reflect_32 complex pattern failed");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Custom Zero-Config Polynomial Handling");
   Put_Line ("  13.1 Assert arbitrary configuration with 0 values does not divide-by-zero or crash");
   declare
      Custom_CRC : constant CRC_Config :=
        (Variant => Normal, Poly => 16#00000007#, Init => 0, Xor_Out => 0);
   begin
      Result := Compute_Bit_By_Bit (Test_Data, Custom_CRC);
      Assert (Result /= 0, "Custom generic config evaluated incorrectly");
      Put_Line ("      PASS");
   end;

   Put_Line ("--------------------------------------------------------");
   Put_Line ("SUCCESS: All 13+ tests passed! Baseline assumptions disproved.");
end Tests;
