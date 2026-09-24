-- shannon_fano_elias.ads
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Shannon_Fano_Elias is

   -- Strong typing for probabilities to ensure valid ranges
   type Probability is new Long_Float range 0.0 .. 1.0;

   -- Data structure representing a single symbol and its encoding parameters
   type Symbol_Data is record
      ID     : Positive;
      Prob   : Probability;
      F      : Probability;       -- Cumulative Distribution F(x)
      F_Bar  : Probability;       -- Modified Cumulative Distribution \bar{F}(x)
      Length : Positive;          -- Code Length l(x)
      Code   : Unbounded_String;  -- Binary representation
   end record;

   -- Array to hold the probability distribution and output codes
   type Symbol_Array is array (Positive range <>) of Symbol_Data;

   -- Exceptions for error handling and boundary conditions
   Invalid_Distribution : exception;
   Empty_Input          : exception;

   -- Main algorithm implementation
   procedure Encode (Data : in out Symbol_Array);

   -- Exposed helper functions for validation and testing
   function Calculate_Length (P : Probability) return Positive;
   function Float_To_Binary (Value : Probability; Len : Positive) return Unbounded_String;

end Shannon_Fano_Elias;
