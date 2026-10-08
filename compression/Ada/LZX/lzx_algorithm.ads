-- lzx_algorithm.ads
-- Specification for the LZX Compression Algorithm Core
-- Covers sliding window LZ77 dictionary matching with LZX Repeated Offsets.

with Ada.Exceptions;

package LZX_Algorithm is

   -- Strong typing for data manipulation
   type Byte is mod 256;
   type Byte_Array is array (Natural range <>) of Byte;
   
   -- LZX Algorithm Variants defined in the specification
   type LZX_Variant is (
      Amiga_LZX,    -- Original 1995 Amiga version
      CAB_LZX,      -- Microsoft Cabinet (up to 2MB window)
      CHM_LZX,      -- HTML Help (different reset intervals)
      Xbox_LZX,     -- Fixed 32KB window for XBE executables
      DELTA_LZX     -- Windows Update patch creation (extended windows)
   );

   -- Configuration for the compressor
   type LZX_Configuration is record
      Variant       : LZX_Variant;
      Window_Size   : Natural;
      Max_Match_Len : Natural := 256;
   end record;

   -- Exceptions for error handling
   LZX_Error : exception;
   Buffer_Overflow : exception;

   -- Factory function to initialize configuration safely based on variant rules
   function Create_Config (Variant : LZX_Variant; Window : Natural) return LZX_Configuration;

   -- Core Algorithm Procedures
   -- Note: Input/Output bounds are strictly checked to prevent overflows.
   
   procedure Compress (
      Config     : in  LZX_Configuration;
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );

   procedure Decompress (
      Config     : in  LZX_Configuration;
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );

end LZX_Algorithm;
