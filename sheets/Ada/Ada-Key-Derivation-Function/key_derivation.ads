package Key_Derivation is
   pragma Pure;

   -- Core type definitions
   type Byte is mod 256;
   type Byte_Array is array (Natural range <>) of Byte;

   -- Exceptions for error handling
   Invalid_Length_Error : exception;
   Invalid_Key_Error    : exception;

   -- Constants limiting operations
   Maximum_Output_Length : constant Natural := 65536;
   Hash_Output_Length    : constant Natural := 32;

   -- Primitive Hash and MAC functions (acting as the underlying Pseudorandom Functions)
   function Hash (Message : Byte_Array) return Byte_Array
     with Global => null,
          Post   => Hash'Result'Length = Hash_Output_Length;

   function HMAC (Key : Byte_Array; Message : Byte_Array) return Byte_Array
     with Global => null,
          Post   => HMAC'Result'Length = Hash_Output_Length;

   -- Variant 1: Password-Based Key Derivation Function 2 (PBKDF2)
   -- Incorporates salt and iteration count to defend against dictionary attacks.
   function PBKDF2
     (Password   : Byte_Array;
      Salt       : Byte_Array;
      Iterations : Positive;
      Length     : Positive) return Byte_Array
     with Global => null,
          Pre    => Length <= Maximum_Output_Length,
          Post   => PBKDF2'Result'Length = Length;

   -- Variant 2a: HMAC-based Extract-and-Expand KDF (HKDF) - Extract Phase
   -- Extracts a high-entropy pseudorandom key (PRK) from initial keying material.
   function HKDF_Extract
     (Salt : Byte_Array;
      IKM  : Byte_Array) return Byte_Array
     with Global => null,
          Post   => HKDF_Extract'Result'Length = Hash_Output_Length;

   -- Variant 2b: HMAC-based Extract-and-Expand KDF (HKDF) - Expand Phase
   -- Expands the pseudorandom key into desired output keying material (OKM).
   function HKDF_Expand
     (PRK    : Byte_Array;
      Info   : Byte_Array;
      Length : Positive) return Byte_Array
     with Global => null,
          Pre    => PRK'Length >= Hash_Output_Length and then Length <= Maximum_Output_Length,
          Post   => HKDF_Expand'Result'Length = Length;

   -- Variant 3: Simple Hash-based KDF (similar to KDF1/KDF2 or ANSI X9.63)
   -- Directly applies the Hash over a secret, counter, and optional info.
   function Simple_KDF
     (Secret : Byte_Array;
      Info   : Byte_Array;
      Length : Positive) return Byte_Array
     with Global => null,
          Pre    => Length <= Maximum_Output_Length,
          Post   => Simple_KDF'Result'Length = Length;

   -- Helper utilities for interfacing with Strings
   function To_Bytes (S : String) return Byte_Array
     with Global => null;
     
   function To_String (B : Byte_Array) return String
     with Global => null;

end Key_Derivation;
