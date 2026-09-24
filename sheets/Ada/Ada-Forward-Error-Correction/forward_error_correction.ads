pragma Assertion_Policy (Pre => Check, Post => Check);

package Forward_Error_Correction is

   -- Basic unit of data is a Bit (0 or 1)
   type Bit is range 0 .. 1;
   type Bit_Array is array (Positive range <>) of Bit;

   -- Subtypes for block codes
   subtype Nibble is Bit_Array (1 .. 4);
   subtype Hamming_Block is Bit_Array (1 .. 7);

   -----------------------------------------------------------------------------
   -- Repetition Code (Rate 1/Times)
   -- The simplest form of Forward Error Correction, repeating each bit.
   -----------------------------------------------------------------------------
   
   -- Encodes a bit array by repeating each bit `Times` times.
   function Repetition_Encode (Data : Bit_Array; Times : Positive := 3) return Bit_Array
     with Global => null,
          Pre    => Times mod 2 /= 0, -- Must be odd for majority vote to work without ties
          Post   => Repetition_Encode'Result'Length = Data'Length * Times;

   -- Decodes a repetition-coded bit array using majority voting.
   function Repetition_Decode (Codeword : Bit_Array; Times : Positive := 3) return Bit_Array
     with Global => null,
          Pre    => Times mod 2 /= 0 and then Codeword'Length mod Times = 0,
          Post   => Repetition_Decode'Result'Length = Codeword'Length / Times;

   -----------------------------------------------------------------------------
   -- Hamming(7,4) Code
   -- A block code that encodes 4 bits of data into 7 bits, allowing for
   -- single-bit error correction.
   -----------------------------------------------------------------------------

   -- Encodes a single 4-bit Nibble into a 7-bit Hamming codeword.
   function Hamming_74_Encode (Data : Nibble) return Hamming_Block
     with Global => null;

   -- Decodes a 7-bit Hamming codeword back into a 4-bit Nibble.
   -- Can detect and correct any single-bit error.
   function Hamming_74_Decode (Codeword : Hamming_Block) return Nibble
     with Global => null;

   -- Encodes an entire array of bits using Hamming(7,4).
   function Hamming_Encode_Message (Data : Bit_Array) return Bit_Array
     with Global => null,
          Pre    => Data'Length mod 4 = 0,
          Post   => Hamming_Encode_Message'Result'Length = (Data'Length / 4) * 7;

   -- Decodes an entire array of Hamming(7,4) codewords.
   function Hamming_Decode_Message (Codeword : Bit_Array) return Bit_Array
     with Global => null,
          Pre    => Codeword'Length mod 7 = 0,
          Post   => Hamming_Decode_Message'Result'Length = (Codeword'Length / 7) * 4;

   -----------------------------------------------------------------------------
   -- Interleaving
   -- A technique to spread burst errors across multiple blocks so that they
   -- appear as correctable single-bit errors in individual blocks.
   -----------------------------------------------------------------------------

   -- Interleaves data by treating it as a matrix of `Block_Size` columns,
   -- writing by rows and reading by columns.
   function Interleave (Data : Bit_Array; Block_Size : Positive) return Bit_Array
     with Global => null,
          Pre    => Data'Length mod Block_Size = 0,
          Post   => Interleave'Result'Length = Data'Length;

   -- Deinterleaves data, the inverse operation of Interleave.
   function Deinterleave (Data : Bit_Array; Block_Size : Positive) return Bit_Array
     with Global => null,
          Pre    => Data'Length mod Block_Size = 0,
          Post   => Deinterleave'Result'Length = Data'Length;

end Forward_Error_Correction;
