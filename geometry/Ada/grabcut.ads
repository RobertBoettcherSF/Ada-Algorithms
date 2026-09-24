package Grabcut is
   pragma Preelaborate;

   -- Represents an 8-bit grayscale pixel intensity.
   type Pixel_Value is new Natural range 0 .. 255;
   
   -- 2D Image type. Note the bounds can be any positive range.
   type Image is array (Positive range <>, Positive range <>) of Pixel_Value;

   -- Standard GrabCut labels for graph-cut segmentation.
   type Label is (Background, Foreground, Probable_Background, Probable_Foreground);
   
   -- The resulting segmentation mask matching the image dimensions.
   type Segmentation_Mask is array (Positive range <>, Positive range <>) of Label;

   -- A rectangular region used for initializing the GrabCut algorithm.
   type Bounding_Box is record
      Min_X : Positive;
      Min_Y : Positive;
      Max_X : Positive;
      Max_Y : Positive;
   end record;

   -- Exceptions for error handling edge cases.
   Invalid_Image_Error : exception;
   Invalid_Box_Error   : exception;
   Invalid_Mask_Error  : exception;

   -- Helpers
   
   -- Validates if a bounding box completely fits within the image boundaries
   -- and has valid min/max coordinates.
   function Is_Valid_Box (Img : Image; Box : Bounding_Box) return Boolean;

   -- Generates an initial mask from a bounding box. 
   -- Pixels inside the box are Probable_Foreground, outside are Background.
   function Initialize_Mask (Img : Image; Box : Bounding_Box) return Segmentation_Mask
     with Pre => Img'Length(1) > 0 and Img'Length(2) > 0;

   -- Converts a mask containing Probable labels into a strict binary Mask 
   -- containing only Foreground and Background.
   function To_Binary (Mask : Segmentation_Mask) return Segmentation_Mask;

   -- Variants of the GrabCut algorithm
   
   -- Variant 1: Segment using a bounding box for initialization.
   -- Runs the specified number of iterations of the GMM and Graph Cut steps.
   function Segment_By_Box
     (Img        : Image;
      Box        : Bounding_Box;
      Iterations : Positive := 1) return Segmentation_Mask
     with Pre => Img'Length(1) > 0 and Img'Length(2) > 0;

   -- Variant 2: Segment using an explicitly provided initial mask.
   -- Useful for user-guided strokes or iterative refinement.
   function Segment_By_Mask
     (Img        : Image;
      Mask       : Segmentation_Mask;
      Iterations : Positive := 1) return Segmentation_Mask
     with Pre => Img'Length(1) > 0 and Img'Length(2) > 0;

   -- Variant 3: Segment one-shot until convergence.
   -- Iterates until the mask stops changing or a maximum iteration limit is hit.
   function Segment_One_Shot
     (Img : Image;
      Box : Bounding_Box) return Segmentation_Mask
     with Pre => Img'Length(1) > 0 and Img'Length(2) > 0;

end Grabcut;
