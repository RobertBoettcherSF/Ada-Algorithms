with Interfaces;

package PBKDF2 is
   pragma Pure;

   -- Fundamental data types for cryptography operations
   type Byte is new Interfaces.Unsigned_8;
   type Byte_Array is array (Natural range <>) of Byte;

   subtype Iteration_Count is Positive;
   subtype Key_Length is Positive;

   -- Exceptions
   Derived_Key_Too_Long : exception;

   -- =========================================================================
   -- PBKDF1 Implementation
   -- Historic variant (RFC 2898) limiting key length to the underlying hash.
   -- =========================================================================
   generic
      Hash_Length : Positive;
      with function Hash (Data : Byte_Array) return Byte_Array;
   package PBKDF1_Algorithm is
      function Derive
        (Password   : Byte_Array;
         Salt       : Byte_Array;
         Iterations : Iteration_Count;
         Length     : Key_Length) return Byte_Array
         with Global => null,
              Post   => Derive'Result'Length = Length;
   end PBKDF1_Algorithm;

   -- =========================================================================
   -- PBKDF2 Implementation
   -- Modern variant utilizing a Pseudorandom Function (PRF) and supporting 
   -- arbitrarily long derived keys through block concatenation.
   -- =========================================================================
   generic
      Hash_Length : Positive;
      with function PRF (Key : Byte_Array; Data : Byte_Array) return Byte_Array;
   package PBKDF2_Algorithm is
      function Derive
        (Password   : Byte_Array;
         Salt       : Byte_Array;
         Iterations : Iteration_Count;
         Length     : Key_Length) return Byte_Array
         with Global => null,
              Post   => Derive'Result'Length = Length;
   end PBKDF2_Algorithm;

   -- =========================================================================
   -- Helper Subprograms
   -- =========================================================================

   -- Bitwise XOR for equally-sized byte arrays
   function "xor" (Left, Right : Byte_Array) return Byte_Array
     with Global => null,
          Pre    => Left'Length = Right'Length,
          Post   => "xor"'Result'Length = Left'Length;

   -- Converts a 32-bit positive integer into a 4-byte Big-Endian array
   function To_Big_Endian (Value : Positive) return Byte_Array
     with Global => null,
          Post   => To_Big_Endian'Result'Length = 4;

end PBKDF2;
