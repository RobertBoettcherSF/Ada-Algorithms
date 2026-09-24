--  damm_algorithm.ads
--  Specification for the Damm Algorithm.
--  Defines strongly-typed digits, arrays, exceptions, and core subprograms.

package Damm_Algorithm is

   --  Strong typing: A digit strictly bounded between 0 and 9.
   type Digit is range 0 .. 9;
   
   --  Custom array type for sequences of digits.
   type Digit_Array is array (Positive range <>) of Digit;

   --  Exception raised when an empty sequence or invalid character
   --  is processed.
   Invalid_Input : exception;

   --  Calculates the Damm check digit for an array of digits.
   function Calculate_Check_Digit (Number : Digit_Array) return Digit;

   --  Verifies if an array of digits (including its check digit) is valid.
   function Verify_Number (Number : Digit_Array) return Boolean;

   --  Helper: Returns a new array with the calculated check digit appended.
   function Append_Check_Digit (Number : Digit_Array) return Digit_Array;

   --  Variant: String inputs for easier integration with textual data.
   function Calculate_Check_Digit_Str (Number : String) return Digit;
   
   --  Variant: String input verification.
   function Verify_Number_Str (Number : String) return Boolean;

end Damm_Algorithm;
