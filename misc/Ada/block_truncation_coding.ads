package Block_Truncation_Coding is
   
   -- We use a Mod type to enforce valid 8-bit Grayscale values strictly.
   -- This prevents Constraint_Errors on assignment and enables wrap/clamp logic testing.
   type Pixel_Value is mod 256;
   
   -- Standard BTC operates on 4x4 pixel blocks
   type Block_4x4 is array (1..4, 1..4) of Pixel_Value;
   type Bitmap_4x4 is array (1..4, 1..4) of Boolean;
   
   -- Holds the compressed representation of a block
   type BTC_Encoded_Block is record
      A      : Pixel_Value; -- Lower quantization level
      B      : Pixel_Value; -- Upper quantization level
      Bitmap : Bitmap_4x4;  -- 1-bit quantization mask
   end record;
   
   -- Variants supported by the implementation
   type BTC_Variant is (Standard_BTC, AMBTC);
   
   -----------------------------------------------------------------------------
   -- Core Algorithm Subprograms
   -----------------------------------------------------------------------------
   
   -- Encodes a 4x4 block of pixels into its compressed BTC representation.
   procedure Encode_Block (
      Input   : in  Block_4x4;
      Output  : out BTC_Encoded_Block;
      Variant : in  BTC_Variant := Standard_BTC
   );

   -- Decodes a compressed BTC block back into a 4x4 array of pixels.
   procedure Decode_Block (
      Input  : in  BTC_Encoded_Block;
      Output : out Block_4x4
   );

   -----------------------------------------------------------------------------
   -- Helper Functions (Exposed for Testing/Validation Verification)
   -----------------------------------------------------------------------------
   function Calculate_Mean (Block : Block_4x4) return Float;
   function Calculate_Std_Dev (Block : Block_4x4; Mean : Float) return Float;

end Block_Truncation_Coding;
