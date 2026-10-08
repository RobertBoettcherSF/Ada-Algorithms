with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Shannon_Fano is

   -- Record representing a single symbol, its probability/weight, and resulting code
   type Symbol_Data is record
      Symbol      : Character;
      Probability : Float;
      Code        : Unbounded_String;
   end record;

   -- Array type for holding a set of symbols
   type Symbol_Array is array (Positive range <>) of Symbol_Data;

   -- Exceptions for error handling
   Invalid_Probability : exception;
   Empty_Input         : exception;

   -- Variant 1: Fano's Method
   -- Recursively divides the array into two halves such that the sum of 
   -- probabilities in each half is as close to equal as possible.
   procedure Generate_Fano_Codes (Symbols : in out Symbol_Array);

   -- Variant 2: Shannon's Method
   -- Uses cumulative probabilities and logarithmic code lengths 
   -- (length = ceil(-log2(p))) to generate prefix codes.
   procedure Generate_Shannon_Codes (Symbols : in out Symbol_Array);

end Shannon_Fano;
