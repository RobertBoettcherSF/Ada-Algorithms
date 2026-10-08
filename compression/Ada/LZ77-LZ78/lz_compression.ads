-- lz_compression.ads
-- Specification for LZ77 and LZ78 Compression Algorithms

package Lz_Compression is

   -----------------------------------------------------------------------------
   -- Shared Definitions
   -----------------------------------------------------------------------------
   Empty_Input_Error   : exception;
   Invalid_Token_Error : exception;

   -----------------------------------------------------------------------------
   -- LZ77: Sliding Window Compression
   -- Variant 1 of Lempel-Ziv algorithms utilizing a Lookahead Buffer and Search Window.
   -----------------------------------------------------------------------------
   type Lz77_Token is record
      Offset    : Natural := 0;             -- Distance backward to start of match
      Length    : Natural := 0;             -- Length of the match
      Next_Char : Character := ASCII.NUL;   -- The character following the match
      Has_Next  : Boolean := True;          -- Flag to handle end of string gracefully
   end record;

   type Lz77_Token_Array is array (Positive range <>) of Lz77_Token;

   -- Encodes a string using the LZ77 sliding window algorithm
   -- Window_Size controls the search buffer size; Lookahead_Size limits match length.
   function Lz77_Encode
     (Input          : String;
      Window_Size    : Positive := 255;
      Lookahead_Size : Positive := 15) return Lz77_Token_Array;

   -- Decodes an LZ77 token array back into the original string
   function Lz77_Decode (Tokens : Lz77_Token_Array) return String;


   -----------------------------------------------------------------------------
   -- LZ78: Dictionary-Based Compression
   -- Variant 2 of Lempel-Ziv algorithms utilizing an explicit dynamic dictionary.
   -----------------------------------------------------------------------------
   type Lz78_Token is record
      Index     : Natural := 0;             -- Index in the dictionary (0 for empty)
      Next_Char : Character := ASCII.NUL;   -- The character appended to the dictionary entry
      Has_Next  : Boolean := True;          -- Flag for exact string termination match
   end record;

   type Lz78_Token_Array is array (Positive range <>) of Lz78_Token;

   -- Encodes a string using the LZ78 dictionary algorithm
   -- Max_Dict_Size prevents infinite growth of the compression dictionary.
   function Lz78_Encode
     (Input         : String;
      Max_Dict_Size : Positive := 4096) return Lz78_Token_Array;

   -- Decodes an LZ78 token array back into the original string
   function Lz78_Decode (Tokens : Lz78_Token_Array) return String;

end Lz_Compression;
