-- deflate.ads
-- Specification for the Deflate compression algorithm (LZ77 + Huffman)
-- Implements variants: Stored (Uncompressed), Static Huffman, and Dynamic Huffman.

with Ada.Streams; use Ada.Streams;

package Deflate is

   -- Strong typing for algorithm-specific data
   type Compression_Variant is (Stored, Static_Huffman, Dynamic_Huffman);
   
   -- Token kinds for LZ77 output
   type Token_Kind is (Literal, Match);
   
   -- LZ77 Token: Either a single literal byte, or a Length/Distance pair
   type Token (Kind : Token_Kind := Literal) is record
      case Kind is
         when Literal => 
            Value : Stream_Element;
         when Match =>
            Length   : Positive;
            Distance : Positive;
      end case;
   end record;
   
   type Token_Array is array (Positive range <>) of Token;

   -- Exceptions for edge cases and invalid data
   Deflate_Error : exception;
   Buffer_Overflow : exception;

   -- Core Compression procedure
   -- Selects the optimal variant based on input size and redundancy
   procedure Compress 
     (Input    : in  Stream_Element_Array;
      Output   : out Stream_Element_Array;
      Last     : out Stream_Element_Offset;
      Variant  : in  Compression_Variant := Static_Huffman);

   -- Core Decompression procedure
   procedure Decompress 
     (Input    : in  Stream_Element_Array;
      Output   : out Stream_Element_Array;
      Last     : out Stream_Element_Offset);

   -- Modular Variant Procedures (exposed for testing)
   
   -- Variant 1: Non-compressed (Stored) blocks (Max 65535 bytes per block)
   procedure Process_Stored_Block 
     (Input  : in  Stream_Element_Array;
      Output : out Stream_Element_Array;
      Last   : out Stream_Element_Offset);

   -- Variant 2: Static Huffman blocks (Pre-defined Huffman trees)
   procedure Process_Static_Block 
     (Input  : in  Stream_Element_Array;
      Output : out Stream_Element_Array;
      Last   : out Stream_Element_Offset);

   -- Variant 3: Dynamic Huffman blocks (Custom trees based on data frequency)
   procedure Process_Dynamic_Block 
     (Input  : in  Stream_Element_Array;
      Output : out Stream_Element_Array;
      Last   : out Stream_Element_Offset);

   -- Helper Function: LZ77 sliding window tokenization
   procedure LZ77_Encode 
     (Input  : in  Stream_Element_Array;
      Tokens : out Token_Array;
      Count  : out Natural);

end Deflate;
