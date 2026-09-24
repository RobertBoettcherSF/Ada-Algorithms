-- adaptive_huffman.ads
package Adaptive_Huffman is
   pragma Elaborate_Body;

   -- Represents the two primary variants of the Adaptive Huffman algorithm
   type Variant_Type is (FGK, Vitter);

   -- Exception raised when decoding an incomplete or corrupted bit stream
   Invalid_Bit_Stream : exception;

   -- Encode a plain text string into a bit string composed of '0' and '1'
   function Encode (Text : String; Variant : Variant_Type) return String;

   -- Decode a bit string back into the original text
   function Decode (Bits : String; Variant : Variant_Type) return String;

end Adaptive_Huffman;
