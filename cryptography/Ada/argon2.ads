--------------------------------------------------------------------------------
-- Package Argon2
-- Implementation of the Argon2 memory-hard key derivation function (RFC 9106)
-- Variants: Argon2d, Argon2i, Argon2id
--------------------------------------------------------------------------------

package Argon2 is

   -- Algorithm variants specified in RFC 9106
   type Variant_Type is (Argon2d, Argon2i, Argon2id);

   -- Domain-specific strongly typed parameters
   type Memory_Size_Kib is range 8 .. 2**31 - 1;
   type Iterations_Count is range 1 .. 2**31 - 1;
   type Parallelism_Count is range 1 .. 2**24 - 1;
   type Tag_Length_Bytes is range 4 .. 2**31 - 1;

   type Byte is mod 2**8;
   type Byte_Array is array (Positive range <>) of Byte;

   -- Named exceptions for robust error handling
   Invalid_Parameter   : exception;
   Invalid_Password    : exception;
   Invalid_Salt        : exception;
   Verification_Failed : exception;

   -- Computes Argon2d hash (data-dependent addressing)
   function Hash_Argon2d
     (Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4;
      Tag_Length  : Tag_Length_Bytes := 32) return Byte_Array
     with Pre  => Password'Length > 0 and then Salt'Length >= 8 and then Memory_Cost >= Memory_Size_Kib (8 * Natural (Parallel)),
          Post => Hash_Argon2d'Result'Length = Integer (Tag_Length);

   -- Computes Argon2i hash (data-independent addressing)
   function Hash_Argon2i
     (Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4;
      Tag_Length  : Tag_Length_Bytes := 32) return Byte_Array
     with Pre  => Password'Length > 0 and then Salt'Length >= 8 and then Memory_Cost >= Memory_Size_Kib (8 * Natural (Parallel)),
          Post => Hash_Argon2i'Result'Length = Integer (Tag_Length);

   -- Computes Argon2id hash (hybrid data-independent / data-dependent addressing)
   function Hash_Argon2id
     (Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4;
      Tag_Length  : Tag_Length_Bytes := 32) return Byte_Array
     with Pre  => Password'Length > 0 and then Salt'Length >= 8 and then Memory_Cost >= Memory_Size_Kib (8 * Natural (Parallel)),
          Post => Hash_Argon2id'Result'Length = Integer (Tag_Length);

   -- Generic entry point dispatching by Variant_Type
   function Hash
     (Variant     : Variant_Type;
      Password    : Byte_Array;
      Salt        : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4;
      Tag_Length  : Tag_Length_Bytes := 32) return Byte_Array
     with Pre  => Password'Length > 0 and then Salt'Length >= 8 and then Memory_Cost >= Memory_Size_Kib (8 * Natural (Parallel)),
          Post => Hash'Result'Length = Integer (Tag_Length);

   -- Verifies a password against expected hash output for a given variant and parameters
   function Verify
     (Variant     : Variant_Type;
      Password    : Byte_Array;
      Salt        : Byte_Array;
      Expected    : Byte_Array;
      Memory_Cost : Memory_Size_Kib  := 64 * 1024;
      Time_Cost   : Iterations_Count := 3;
      Parallel    : Parallelism_Count := 4) return Boolean
     with Pre => Password'Length > 0 and then Salt'Length >= 8 and then Expected'Length > 0;

end Argon2;
