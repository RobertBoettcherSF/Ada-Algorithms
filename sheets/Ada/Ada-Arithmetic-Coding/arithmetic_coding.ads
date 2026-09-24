-- arithmetic_coding.ads
-- Specification for the Arithmetic Coding algorithm.
-- Implements both Static and Adaptive (Dynamic) variants using robust
-- integer rescaling techniques.

with Interfaces; use Interfaces;

package Arithmetic_Coding is

   -- Strong typing for bits and bit streams
   type Bit is mod 2;
   type Bit_Stream is array (Positive range <>) of Bit;

   -- Exceptions for edge cases
   Empty_Input_Error    : exception;
   Invalid_Symbol_Error : exception;
   Stream_Corrupt_Error : exception;

   -- Models for Static and Adaptive Arithmetic Coding
   type Frequency_Table is array (Character) of Natural;
   
   type Static_Model is private;
   type Adaptive_Model is private;

   -- =========================================================================
   -- Variant 1: Static Arithmetic Coding
   -- Uses a fixed frequency model built beforehand.
   -- =========================================================================

   -- Build a frequency model from a given input string.
   function Build_Static_Model (Data : String) return Static_Model;

   -- Encode data using a pre-built static model.
   function Static_Encode (Data : String; M : Static_Model) return Bit_Stream;

   -- Decode bits back to a string using the static model and known output length.
   function Static_Decode (Bits          : Bit_Stream; 
                           M             : Static_Model; 
                           Output_Length : Natural) return String;

   -- =========================================================================
   -- Variant 2: Adaptive (Dynamic) Arithmetic Coding
   -- Model updates dynamically as symbols are processed.
   -- =========================================================================

   -- Encode data dynamically (model starts flat and learns).
   function Adaptive_Encode (Data : String) return Bit_Stream;

   -- Decode data dynamically.
   function Adaptive_Decode (Bits          : Bit_Stream; 
                             Output_Length : Natural) return String;

private

   type Static_Model is record
      Freq  : Frequency_Table := (others => 0);
      Total : Natural := 0;
   end record;

   type Adaptive_Model is record
      Freq  : Frequency_Table := (others => 1);
      Total : Natural := 256; -- 256 characters initially at freq 1
   end record;

   -- Constants for 32-bit Integer Interval Rescaling
   Code_Bits      : constant := 32;
   Max_Code       : constant Unsigned_32 := 16#FFFF_FFFF#;
   One_Half       : constant Unsigned_32 := 16#8000_0000#;
   One_Quarter    : constant Unsigned_32 := 16#4000_0000#;
   Three_Quarters : constant Unsigned_32 := 16#C000_0000#;

end Arithmetic_Coding;
