package Run_Length_Encoding is

   -- Exception raised when encountering malformed RLE data or invalid inputs
   Invalid_Format : exception;

   -------------------------------------------------------------------------
   -- Variant 1: String-based Run-Length Encoding
   -------------------------------------------------------------------------
   -- Used for text compression (e.g. "WWWWWWWWWWWWBWWWW" -> "12W1B4W").
   -- Note: Input strings to Encode_String must NOT contain numeric digits 
   -- to prevent ambiguity during decoding. Raises Invalid_Format if they do.
   
   function Encode_String (Input : String) return String;
   function Decode_String (Input : String) return String;

   -------------------------------------------------------------------------
   -- Variant 2: Binary Run-Length Encoding (e.g., Bitmaps, Fax machines)
   -------------------------------------------------------------------------
   -- Stores counts of alternating boolean values.
   
   type Binary_Array is array (Positive range <>) of Boolean;
   type Count_Array is array (Positive range <>) of Positive;

   -- Encodes a sequence of bits into an array of run-lengths.
   -- Start_Bit indicates the boolean value of the very first run.
   function Encode_Binary 
     (Input     : Binary_Array; 
      Start_Bit : out Boolean) return Count_Array;

   -- Decodes an array of run-lengths back into a bit sequence.
   function Decode_Binary 
     (Counts    : Count_Array; 
      Start_Bit : Boolean) return Binary_Array;

end Run_Length_Encoding;
