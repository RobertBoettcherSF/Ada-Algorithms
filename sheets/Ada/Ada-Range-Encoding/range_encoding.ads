-- range_encoding.ads
-- Specification for the Range Encoding algorithm (Floating-Point and Integer variants).

with Interfaces; use Interfaces;

package Range_Encoding is

   -- =========================================================================
   -- Common Types and Exceptions
   -- =========================================================================
   
   Encoding_Error : exception;
   Decoding_Error : exception;
   Invalid_Model  : exception;
   
   type Digit_Array is array (Positive range <>) of Natural;
   
   -- Symbol model for the Integer Variant (using discrete frequencies)
   type Symbol_Model is record
      Sym      : Character;
      Freq     : Positive;
      Cum_Freq : Natural;
   end record;
   type Model_Array is array (Positive range <>) of Symbol_Model;
   
   -- Symbol model for the Float Variant (using mathematical probabilities)
   type Float_Symbol_Model is record
      Sym      : Character;
      Prob     : Long_Float;
      Cum_Prob : Long_Float;
   end record;
   type Float_Model_Array is array (Positive range <>) of Float_Symbol_Model;

   -- =========================================================================
   -- Variant 1: Floating-Point Mathematical Encoding
   -- Represents the theoretical concept mapping to [0, 1).
   -- Note: Due to precision limits, only works for very short strings.
   -- =========================================================================
   
   procedure Encode_Float (
      Input  : in  String;
      Model  : in  Float_Model_Array;
      Output : out Long_Float
   );

   procedure Decode_Float (
      Input  : in  Long_Float;
      Length : in  Positive;
      Model  : in  Float_Model_Array;
      Output : out String
   );

   -- =========================================================================
   -- Variant 2: Integer Arithmetic Encoding (Base 10 Normalization)
   -- Represents the practical computer implementation to avoid precision limits.
   -- Normalizes digits out to an array. Matches the Wikipedia Base-10 example.
   -- =========================================================================

   procedure Encode_Integer (
      Input      : in  String;
      Model      : in  Model_Array;
      Total_Freq : in  Positive;
      Output     : out Digit_Array;
      Out_Len    : out Natural
   );

   procedure Decode_Integer (
      Input      : in  Digit_Array;
      Length     : in  Positive;
      Model      : in  Model_Array;
      Total_Freq : in  Positive;
      Output     : out String
   );

end Range_Encoding;
