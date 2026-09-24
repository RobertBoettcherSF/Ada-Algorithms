pragma Ada_2012;

package Gray_Code is

   -- =========================================================================
   -- Domain Types
   -- =========================================================================

   -- Word represents an unsigned 32-bit integer for standard Gray code operations.
   -- A modular type natively supports bitwise operations (xor, shift equivalents).
   type Word is mod 2**32;
   type Word_Array is array (Positive range <>) of Word;

   -- Bit_Count restricts sequence generation to prevent massive memory allocations.
   subtype Bit_Count is Natural range 1 .. 16;
   
   -- Types for N-Ary (Non-Boolean) Gray Code sequences
   subtype Base_Type is Natural range 2 .. 36;
   type Digit_Type is range 0 .. 35;
   type Digit_Array is array (Positive range <>) of Digit_Type;

   -- =========================================================================
   -- Exceptions
   -- =========================================================================

   Invalid_String   : exception;
   Invalid_Digit    : exception;
   Empty_Constraint : exception;

   -- =========================================================================
   -- 1. Standard Binary Reflected Gray Code (BRGC) for Integers
   -- =========================================================================

   function Binary_To_Gray (Value : Word) return Word
     with Global => null,
          Post   => Binary_To_Gray'Result = (Value xor (Value / 2));

   function Gray_To_Binary (Value : Word) return Word
     with Global => null,
          Post   => Binary_To_Gray (Gray_To_Binary'Result) = Value;

   -- =========================================================================
   -- 2. String Representations of BRGC
   -- =========================================================================

   function Binary_String_To_Gray (Binary_Str : String) return String
     with Global => null;

   function Gray_String_To_Binary (Gray_Str : String) return String
     with Global => null;

   -- =========================================================================
   -- 3. Sequence Generation and Validation
   -- =========================================================================

   -- Generates the full Gray Code sequence for a given number of bits.
   function Generate_BRGC (Bits : Bit_Count) return Word_Array
     with Global => null,
          Post   => Generate_BRGC'Result'Length = 2**Bits;

   -- Validates that a given sequence changes by exactly one bit per step.
   function Is_Valid_Gray_Sequence (Seq : Word_Array) return Boolean
     with Global => null;

   -- =========================================================================
   -- 4. N-Ary Gray Code (Non-Boolean)
   -- =========================================================================

   -- Converts standard N-ary base digits to N-ary Gray code digits.
   function N_Ary_To_Gray (Values : Digit_Array; Base : Base_Type) return Digit_Array
     with Global => null;

   -- Converts N-ary Gray code digits back to standard base digits.
   function Gray_To_N_Ary (Values : Digit_Array; Base : Base_Type) return Digit_Array
     with Global => null;

end Gray_Code;
