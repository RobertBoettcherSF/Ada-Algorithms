with Interfaces;

package Tiger_Hash is

   -- Standard domain types for the hash implementation
   subtype Word64 is Interfaces.Unsigned_64;
   subtype Byte   is Interfaces.Unsigned_8;
   
   type Byte_Array is array (Natural range <>) of Byte;

   -- Exception raised when custom parameters exceed domain limits
   Hash_Error : exception;

   -- =========================================================================
   -- STANDARD TIGER VARIANTS (Tiger/192, Tiger/160, Tiger/128)
   -- Uses standard padding (appends 16#01# byte)
   -- =========================================================================

   function Tiger_192 (Message : Byte_Array) return Byte_Array
     with Pre  => True,
          Post => Tiger_192'Result'Length = 24;

   function Tiger_160 (Message : Byte_Array) return Byte_Array
     with Pre  => True,
          Post => Tiger_160'Result'Length = 20;

   function Tiger_128 (Message : Byte_Array) return Byte_Array
     with Pre  => True,
          Post => Tiger_128'Result'Length = 16;

   -- =========================================================================
   -- TIGER2 VARIANTS
   -- Uses MD4/MD5/SHA standard padding (appends 16#80# byte)
   -- =========================================================================

   function Tiger2_192 (Message : Byte_Array) return Byte_Array
     with Pre  => True,
          Post => Tiger2_192'Result'Length = 24;

   function Tiger2_160 (Message : Byte_Array) return Byte_Array
     with Pre  => True,
          Post => Tiger2_160'Result'Length = 20;

   function Tiger2_128 (Message : Byte_Array) return Byte_Array
     with Pre  => True,
          Post => Tiger2_128'Result'Length = 16;

   -- =========================================================================
   -- CUSTOM LENGTH EXTENSION
   -- Computes Tiger hash truncated to any valid byte length (1 to 24)
   -- =========================================================================

   function Tiger_Custom (Message : Byte_Array; Length : Positive) return Byte_Array
     with Pre  => True,
          Post => Tiger_Custom'Result'Length = Length;

end Tiger_Hash;
