-- cyclic_redundancy_check.ads
-- Specification for the Cyclic Redundancy Check (CRC) algorithm
-- Implements variants from Wikipedia: Bit-by-bit, Table-driven, Normal, and Reversed representations.

with Interfaces; use Interfaces;

package Cyclic_Redundancy_Check is

   -- Custom strong typing for data processing
   type Data_Array is array (Natural range <>) of Unsigned_8;
   
   -- Lookup table for Byte-by-Byte (Table-Driven) CRC computation
   type CRC_Table is array (Unsigned_8) of Unsigned_32;

   -- CRC Polynomial variants (Normal: MSB first, Reversed: LSB first)
   type CRC_Variant is (Normal, Reversed);

   -- CRC Configuration Record allowing highly modular instances
   type CRC_Config is record
      Variant  : CRC_Variant;
      Poly     : Unsigned_32;
      Init     : Unsigned_32;
      Xor_Out  : Unsigned_32;
   end record;

   -- =========================================================================
   -- Standard CRC Configurations (as mentioned in Wikipedia)
   -- =========================================================================
   
   -- Standard CRC-32/BZIP2 (Normal Polynomial)
   CRC_32_BZIP2 : constant CRC_Config :=
     (Variant => Normal, Poly => 16#04C11DB7#, Init => 16#FFFFFFFF#, Xor_Out => 16#FFFFFFFF#);

   -- Standard CRC-32 Ethernet / ZIP (Reversed Polynomial)
   CRC_32_ETHERNET : constant CRC_Config :=
     (Variant => Reversed, Poly => 16#EDB88320#, Init => 16#FFFFFFFF#, Xor_Out => 16#FFFFFFFF#);

   -- =========================================================================
   -- Helper Functions
   -- =========================================================================
   
   -- Reflects (reverses) the bits of an 8-bit or 32-bit integer
   function Reflect_8 (Value : Unsigned_8) return Unsigned_8;
   function Reflect_32 (Value : Unsigned_32) return Unsigned_32;

   -- =========================================================================
   -- Algorithm Variants
   -- =========================================================================
   
   -- 1. Bit-by-Bit Computation:
   -- Simulates a hardware shift-register. Slow but uses minimal memory.
   function Compute_Bit_By_Bit
     (Data   : Data_Array;
      Config : CRC_Config) return Unsigned_32;

   -- 2. Pre-computation Table Generator:
   -- Generates a 256-entry lookup table for the provided configuration.
   function Generate_Table (Config : CRC_Config) return CRC_Table;

   -- 3. Table-Driven Computation:
   -- Byte-by-Byte calculation. Consumes more memory but executes much faster.
   function Compute_Table_Driven
     (Data   : Data_Array;
      Config : CRC_Config;
      Table  : CRC_Table) return Unsigned_32;

end Cyclic_Redundancy_Check;
