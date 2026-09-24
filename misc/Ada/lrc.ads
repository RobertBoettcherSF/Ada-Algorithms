-- lrc.ads
-- Specification for the Longitudinal Redundancy Check (LRC) algorithm.
-- Includes variants based on standard XOR, Modbus (Arithmetic), and Odd Parity.

package LRC is

   -- Strong typing: Define a custom Byte type for 8-bit unsigned arithmetic.
   type Byte is mod 256;
   
   -- Custom type for dynamic sequences of bytes.
   type Byte_Array is array (Positive range <>) of Byte;

   -- Exception raised when LRC is requested on an empty dataset.
   Empty_Data_Error : exception;

   -- =========================================================================
   -- Variant 1: Standard XOR-based LRC (Even Parity)
   -- Used in many standard protocols. Computes the bitwise XOR of all bytes.
   -- =========================================================================
   function Calculate_XOR_LRC (Data : Byte_Array) return Byte;
   function Verify_XOR_LRC (Data : Byte_Array; Expected : Byte) return Boolean;

   -- =========================================================================
   -- Variant 2: Modbus ASCII style LRC (Arithmetic 2's Complement)
   -- Calculates the 2's complement of the arithmetic sum of all bytes.
   -- =========================================================================
   function Calculate_Modbus_LRC (Data : Byte_Array) return Byte;
   function Verify_Modbus_LRC (Data : Byte_Array; Expected : Byte) return Boolean;

   -- =========================================================================
   -- Variant 3: Odd Parity XOR-based LRC
   -- Uses the bitwise complement of the standard XOR-based LRC.
   -- =========================================================================
   function Calculate_Odd_Parity_LRC (Data : Byte_Array) return Byte;
   function Verify_Odd_Parity_LRC (Data : Byte_Array; Expected : Byte) return Boolean;

end LRC;
