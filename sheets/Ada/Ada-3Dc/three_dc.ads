with Interfaces; use Interfaces;

package Three_Dc is
   -- Strong typing for pixel channels (0-255)
   type Byte is mod 256;
   
   -- A 4x4 block of pixels for a single channel (3Dc+ / ATI1N)
   type Block_1D is array (0 .. 15) of Byte;
   
   -- Compressed 8-byte format for a single channel
   type Compressed_Block_1D is array (0 .. 7) of Byte;
   
   -- A 4x4 block of pixels for dual channels (3Dc X and Y / ATI2N)
   type Block_2D is record
      X : Block_1D;
      Y : Block_1D;
   end record;
   
   -- Compressed 16-byte format for dual channels
   type Compressed_Block_2D is record
      X : Compressed_Block_1D;
      Y : Compressed_Block_1D;
   end record;
   
   -- Reconstructed Z channel (represented as floats for unit vector length)
   type Block_Z is array (0 .. 15) of Float;
   
   -- Error definitions
   Compression_Error : exception;
   
   -- 3Dc+ (Single Channel) Variant
   -- Used for heightmaps, alpha channels, or individual scalar maps.
   procedure Compress_3Dc_Plus (Input : in Block_1D; Output : out Compressed_Block_1D);
   procedure Decompress_3Dc_Plus (Input : in Compressed_Block_1D; Output : out Block_1D);
   
   -- 3Dc (Dual Channel) Variant
   -- Used for normal maps (X and Y components).
   procedure Compress_3Dc (Input : in Block_2D; Output : out Compressed_Block_2D);
   procedure Decompress_3Dc (Input : in Compressed_Block_2D; Output : out Block_2D);
   
   -- Reconstructs the Z channel of the normal map assuming X^2 + Y^2 + Z^2 = 1.
   -- Inputs X and Y are expected to be 0..255 mapped to -1.0..1.0.
   procedure Reconstruct_Z (Input_X : in Block_1D; Input_Y : in Block_1D; Output_Z : out Block_Z);

end Three_Dc;
