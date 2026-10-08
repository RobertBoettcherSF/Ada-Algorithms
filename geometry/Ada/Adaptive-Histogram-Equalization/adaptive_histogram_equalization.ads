-- adaptive_histogram_equalization.ads
-- Specification for the AHE algorithm and its variants.

package Adaptive_Histogram_Equalization is

   -- Strong typing for algorithm-specific data
   type Pixel_Type is range 0 .. 255;
   type Image_Type is array (Positive range <>, Positive range <>) of Pixel_Type;

   -- Exceptions for edge cases and invalid states
   Invalid_Window     : exception;
   Invalid_Image      : exception;
   Invalid_Clip_Limit : exception;
   Invalid_Grid       : exception;

   -- Variant 1: Standard Global Histogram Equalization
   -- Uses a single global histogram for the entire image.
   procedure Global_HE
     (Input  : in  Image_Type;
      Output : out Image_Type);

   -- Variant 2: Adaptive Histogram Equalization (AHE) 
   -- Uses a sliding window to compute histograms locally for every pixel.
   procedure Sliding_Window_AHE
     (Input       : in  Image_Type;
      Output      : out Image_Type;
      Window_Size : in  Positive);

   -- Variant 3: Contrast Limited AHE (CLAHE)
   -- Enhances AHE by clipping the local histogram before computing the CDF
   -- to prevent over-amplification of noise in homogeneous regions.
   procedure Sliding_Window_CLAHE
     (Input       : in  Image_Type;
      Output      : out Image_Type;
      Window_Size : in  Positive;
      Clip_Limit  : in  Natural);

   -- Variant 4: Block-Based (Tiled) CLAHE
   -- Implements the grid-based approach discussed in the literature. 
   -- Partitions the image into tiles, computes CDFs per tile, mapping pixels
   -- efficiently (uses nearest neighbor for interpolation step).
   procedure Block_Based_CLAHE
     (Input       : in  Image_Type;
      Output      : out Image_Type;
      Grid_Rows   : in  Positive;
      Grid_Cols   : in  Positive;
      Clip_Limit  : in  Natural);

end Adaptive_Histogram_Equalization;
