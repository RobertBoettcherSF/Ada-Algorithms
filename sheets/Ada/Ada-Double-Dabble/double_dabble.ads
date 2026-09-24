with Interfaces;

package Double_Dabble is
   -- Strong typing for algorithm-specific data
   type BCD_Digit is mod 16;
   type BCD_Array is array (Positive range <>) of BCD_Digit;
   type Bit_Array is array (Positive range <>) of Boolean;

   -- Exceptions for edge cases
   Invalid_Input    : exception;
   Conversion_Error : exception;

   -- =========================================================
   -- Variant 1: Forward Double Dabble (Binary to BCD)
   -- =========================================================
   
   -- Core hardware-like combinational logic module 
   -- Adds 3 to the nibble if it is 5 or greater
   function Add_3_Module (Nibble : BCD_Digit) return BCD_Digit;

   -- Generic unconstrained bit array conversion
   function To_BCD (Bits : Bit_Array) return BCD_Array;

   -- Standard Fixed-Width Integer conversions
   function To_BCD (Value : Interfaces.Unsigned_8)  return BCD_Array;
   function To_BCD (Value : Interfaces.Unsigned_16) return BCD_Array;
   function To_BCD (Value : Interfaces.Unsigned_32) return BCD_Array;

   -- =========================================================
   -- Variant 2: Reverse Double Dabble (BCD to Binary)
   -- =========================================================
   
   -- Generic unconstrained BCD to bit array conversion
   function To_Binary (BCD : BCD_Array; Bit_Length : Positive) return Bit_Array;

   -- Standard Fixed-Width Integer conversions from BCD
   function To_Unsigned_8  (BCD : BCD_Array) return Interfaces.Unsigned_8;
   function To_Unsigned_16 (BCD : BCD_Array) return Interfaces.Unsigned_16;
   function To_Unsigned_32 (BCD : BCD_Array) return Interfaces.Unsigned_32;

end Double_Dabble;
