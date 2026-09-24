with Interfaces;

package Redundancy_Checks is

   -- Custom types for strong typing
   type Byte is mod 2**8;
   type Byte_Array is array (Natural range <>) of Byte;

   -- Exception raised when an empty array is passed to algorithms requiring data
   Empty_Data_Error : exception;

   -- =========================================================
   -- 1. Parity Checks
   -- =========================================================
   -- Returns the parity bit (0 or 1) required to make the total 
   -- number of 1-bits in the data even or odd.
   function Calculate_Even_Parity (Data : Byte) return Byte;
   function Calculate_Odd_Parity  (Data : Byte) return Byte;

   -- =========================================================
   -- 2. Longitudinal Redundancy Check (LRC)
   -- =========================================================
   -- Calculates the XOR sum of all bytes in the data array.
   function Calculate_LRC (Data : Byte_Array) return Byte;

   -- =========================================================
   -- 3. Modular Checksum
   -- =========================================================
   -- Calculates the 8-bit sum modulo 256 of the array.
   function Calculate_Checksum_8 (Data : Byte_Array) return Byte;

   -- =========================================================
   -- 4. Cyclic Redundancy Check (CRC-32)
   -- =========================================================
   -- Implements standard CRC-32 (IEEE 802.3) using the reversed 
   -- polynomial 0xEDB88320.
   function Calculate_CRC32 (Data : Byte_Array) return Interfaces.Unsigned_32;

   -- =========================================================
   -- 5. Adler-32 Checksum
   -- =========================================================
   -- A checksum algorithm faster than CRC-32, often used in zlib.
   function Calculate_Adler32 (Data : Byte_Array) return Interfaces.Unsigned_32;

end Redundancy_Checks;
