-- verhoeff.ads
-- Specification for the Verhoeff algorithm.
-- The Verhoeff algorithm is a checksum formula for error detection, specifically 
-- designed to catch all single errors and all adjacent transposition errors.

package Verhoeff is

   -- Exception raised when the input string contains non-digit characters or is empty
   Invalid_Input : exception;

   -- Variant 1: Generate Check Digit
   -- Calculates the Verhoeff check digit for a given numerical string.
   -- Returns the character representing the calculated check digit.
   function Generate_Check_Digit (Number : String) return Character;

   -- Variant 2: Validate Check Digit
   -- Validates a numerical string that already includes the Verhoeff check digit 
   -- at the end of the string.
   -- Returns True if the number is valid, False otherwise.
   function Validate (Number : String) return Boolean;

end Verhoeff;
