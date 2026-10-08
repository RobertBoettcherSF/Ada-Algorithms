-- unrestricted_algorithms.ads
-- Specification for arbitrary-precision Unrestricted Algorithms.
-- Defines strong types and procedure contracts.

package Unrestricted_Algorithms is

   -- Strong typing: Digits are constrained between 0 and 9
   type Digit is range 0 .. 9;
   
   -- Array representing an arbitrary precision number.
   -- Index 1 is the whole number digit; Index > 1 are fractional digits.
   type Digit_Array is array (Positive range <>) of Digit;

   -- Exception raised when array inputs to arithmetic do not match in precision length.
   Precision_Mismatch_Error : exception;

   -- Variant 1: Iterative implementation of arbitrary precision 1/N
   -- Useful for step-by-step stateful generation (like a spigot)
   function Inverse_Iterative (N : Positive; Precision : Positive) return Digit_Array;

   -- Variant 2: Recursive implementation of arbitrary precision 1/N
   -- Useful for functional paradigms processing infinite sequences
   function Inverse_Recursive (N : Positive; Precision : Positive) return Digit_Array;

   -- Implementation of the unrestricted algorithm for Euler's Number (e) 
   -- Utilizes the infinite Taylor Series approximation: e = Sum (1 / i!)
   function Compute_E (Precision : Positive) return Digit_Array;

   -- Helper Functions
   function Add (A, B : Digit_Array) return Digit_Array;
   function Divide_By_Integer (A : Digit_Array; Divisor : Positive) return Digit_Array;
   function Is_Equal (A, B : Digit_Array) return Boolean;
   function Is_Zero (A : Digit_Array) return Boolean;
   
   -- Output Helper
   procedure Print_Number (Number : Digit_Array);

end Unrestricted_Algorithms;
