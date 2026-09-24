with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Entropy_Encoding is

   -- Strong typing for algorithm-specific data
   type Frequency_Map is array (Character) of Natural;
   
   type Code_Record is record
      Bit_Code : Unbounded_String;
      Length   : Natural := 0;
   end record;
   
   type Encoding_Map is array (Character) of Code_Record;

   -- Exceptions for edge cases and errors
   Empty_Input_Error      : exception;
   Invalid_Encoding_Error : exception;
   Arithmetic_Overflow    : exception;

   -- Helper: Generates a frequency map from a given text string
   function Generate_Frequencies (Text : String) return Frequency_Map;

   -- ========================================================================
   -- Variant 1: Huffman Coding (Optimal Prefix, Bottom-up tree construction)
   -- ========================================================================
   procedure Generate_Huffman_Codes
     (Freqs : in Frequency_Map;
      Codes : out Encoding_Map);

   -- ========================================================================
   -- Variant 2: Shannon-Fano Coding (Sub-optimal Prefix, Top-down splitting)
   -- ========================================================================
   procedure Generate_Shannon_Fano_Codes
     (Freqs : in Frequency_Map;
      Codes : out Encoding_Map);

   -- ========================================================================
   -- Variant 3: Arithmetic Coding (Continuous interval division)
   -- Note: Implemented using Long_Float. Restricted to short strings due to
   -- floating-point precision limits inherent in basic arithmetic coding.
   -- ========================================================================
   function Arithmetic_Encode (Text : String; Freqs : Frequency_Map) return Long_Float;

   -- ========================================================================
   -- Core Encoding and Decoding Operations (For Prefix Codes)
   -- ========================================================================
   function Encode (Text : String; Codes : Encoding_Map) return String;
   function Decode (Bitstream : String; Codes : Encoding_Map) return String;

end Entropy_Encoding;
