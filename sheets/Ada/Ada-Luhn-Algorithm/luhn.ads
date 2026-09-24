-- luhn.ads
-- Specification for the Luhn algorithm package.
-- Implements strongly typed data structures and procedures for calculating
-- and validating identification numbers using the Luhn algorithm.

package Luhn is

   -- Strong typing for algorithm-specific data
   type Luhn_Sequence is new String;
   subtype Check_Digit is Character range '0' .. '9';

   -- Exception raised when input contains non-digit/non-space characters
   Invalid_Format : exception;

   -- Variant 1: Validation
   -- Validates a complete sequence including its check digit.
   -- Ignores spaces. Raises Invalid_Format if alphabetic/symbolic characters exist.
   function Validate (Number : Luhn_Sequence) return Boolean;

   -- Variant 2: Check Digit Calculation
   -- Calculates the required check digit for a given partial sequence.
   -- Ignores spaces. Raises Invalid_Format if invalid characters exist.
   function Calculate_Check_Digit (Partial_Number : Luhn_Sequence) return Check_Digit;

   -- Variant 3: Sequence Generation
   -- Generates a full, valid sequence by appending the calculated check digit
   -- to the provided partial sequence.
   function Generate_Full_Number (Partial_Number : Luhn_Sequence) return Luhn_Sequence;

end Luhn;
