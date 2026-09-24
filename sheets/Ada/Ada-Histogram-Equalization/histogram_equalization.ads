-- histogram_equalization.ads
package Histogram_Equalization is

    -- Define Intensity as 8-bit unsigned
    type Intensity is range 0 .. 255;
    
    -- Pixel grid definition (multidimensional array)
    type Pixel_Grid is array (Integer range <>, Integer range <>) of Intensity;
    
    -- Exception for invalid operations
    Empty_Image_Error : exception;
    
    -- Variant 1: Global Histogram Equalization
    -- Standard approach using global CDF
    procedure Equalize_Global (Img : in out Pixel_Grid);
    
    -- Variant 2: Adaptive Histogram Equalization (Simplified Block-based)
    -- Operates on tiles to improve local contrast
    procedure Equalize_Adaptive (Img : in out Pixel_Grid; Tile_Size : Positive := 8);

end Histogram_Equalization;
