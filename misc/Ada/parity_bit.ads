-- parity_bit.ads
-- Specification for the Parity Bit algorithm

package Parity_Bit is

   -- Strong typing: Define a specific type for bits to ensure type safety
   type Bit is range 0 .. 1;
   
   -- Array type for sequences of bits
   type Bit_Array is array (Positive range <>) of Bit;
   
   -- Variants of the Parity Bit algorithm found on Wikipedia
   type Parity_Type is (
      Even,  -- Ensures total count of 1s (including parity bit) is even
      Odd,   -- Ensures total count of 1s (including parity bit) is odd
      Mark,  -- Parity bit is always 1 (used in serial communications)
      Space  -- Parity bit is always 0 (used in serial communications)
   );
   
   -- Exceptions for edge cases
   Invalid_Data_Error : exception;

   -- Calculates the parity bit for a given array of bits
   function Calculate_Parity (Data : Bit_Array; Kind : Parity_Type) return Bit;
   
   -- Appends the calculated parity bit to the end of the bit array
   function Add_Parity (Data : Bit_Array; Kind : Parity_Type) return Bit_Array;
   
   -- Validates if a bit array (where the last bit is the parity bit) is correct
   function Check_Parity (Data_With_Parity : Bit_Array; Kind : Parity_Type) return Boolean;

end Parity_Bit;
