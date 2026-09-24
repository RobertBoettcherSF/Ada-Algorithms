with Interfaces;

package Salsa20 is

   type Byte is mod 2**8;
   type Byte_Array is array (Natural range <>) of Byte;

   subtype Word is Interfaces.Unsigned_32;
   type Word_Array is array (Natural range 0 .. 15) of Word;

   -- Key sizes
   subtype Key_256_Index is Natural range 0 .. 31;
   type Key_256 is array (Key_256_Index) of Byte;

   subtype Key_128_Index is Natural range 0 .. 15;
   type Key_128 is array (Key_128_Index) of Byte;

   -- Nonce (IV) size: 8 bytes (64 bits)
   subtype Nonce_Index is Natural range 0 .. 7;
   type Nonce_64 is array (Nonce_Index) of Byte;

   -- Block size: 64 bytes (512 bits)
   subtype Block_Index is Natural range 0 .. 63;
   type Block_Bytes is array (Block_Index) of Byte;

   -- Exceptions
   Invalid_Key_Length  : exception;
   Invalid_Data_Length : exception;
   Invalid_Round_Count : exception;

   -- Public Subprograms for Salsa20 variants
   
   -- Salsa20/20 with 256-bit key (Standard Salsa20)
   procedure Encrypt_256_20 (
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Interfaces.Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) with
      Pre  => Output'Length = Input'Length,
      Post => True;

   -- Salsa20/12 with 256-bit key (12-round variant)
   procedure Encrypt_256_12 (
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Interfaces.Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) with
      Pre  => Output'Length = Input'Length,
      Post => True;

   -- Salsa20/8 with 256-bit key (8-round variant)
   procedure Encrypt_256_8 (
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Interfaces.Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) with
      Pre  => Output'Length = Input'Length,
      Post => True;

   -- Salsa20/20 with 128-bit key
   procedure Encrypt_128_20 (
      Key     : in Key_128;
      Nonce   : in Nonce_64;
      Counter : in Interfaces.Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) with
      Pre  => Output'Length = Input'Length,
      Post => True;

   -- General parameterized Salsa20 encryption (supports 256-bit key, arbitrary even round counts)
   procedure Encrypt_General (
      Rounds  : in Positive;
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Interfaces.Unsigned_64;
      Input   : in Byte_Array;
      Output  : out Byte_Array
   ) with
      Pre  => (Rounds mod 2 = 0) and then (Output'Length = Input'Length),
      Post => True;

   -- Generate a single 64-byte keystream block directly
   procedure Generate_Block (
      Rounds  : in Positive;
      Key     : in Key_256;
      Nonce   : in Nonce_64;
      Counter : in Interfaces.Unsigned_64;
      Block   : out Block_Bytes
   ) with
      Pre => Rounds mod 2 = 0;

end Salsa20;
