-- feature_detection.ads
-- Specification for Feature Detection algorithms (Computer Vision)
-- Implements variants from the Wikipedia article: Edges, Corners, Blobs, Ridges.

package Feature_Detection is

   -- Strong typing for image representation
   type Pixel_Value is new Integer range 0 .. 255;
   type Image is array (Positive range <>, Positive range <>) of Pixel_Value;

   -- Categorization of features mentioned in the article
   type Feature_Kind is (Edge, Corner, Blob, Ridge);

   -- 2D Point structure
   type Point is record
      X : Positive;
      Y : Positive;
   end record;

   -- Custom type for detected features
   type Feature is record
      Location  : Point;
      Kind      : Feature_Kind;
      Magnitude : Float;
   end record;

   type Feature_Array is array (Positive range <>) of Feature;

   -- Exceptions
   Invalid_Image_Error : exception; -- Raised if image is too small for kernels (< 3x3)

   -- =========================================================================
   -- Algorithm Variants (from Wikipedia's Feature Detection categories)
   -- =========================================================================

   -- 1. Edge Detection (Approximation using Sobel Operator)
   -- Evaluates the 1st derivative (gradient) to find sharp intensity changes.
   procedure Detect_Edges
     (Img       : in Image;
      Threshold : in Float;
      Features  : out Feature_Array;
      Count     : out Natural);

   -- 2. Corner / Interest Point Detection (Moravec Variance simplification)
   -- Evaluates local patches to find points with high variance in all directions.
   procedure Detect_Corners
     (Img       : in Image;
      Threshold : in Float;
      Features  : out Feature_Array;
      Count     : out Natural);

   -- 3. Blob Detection (Laplacian of Gaussian / DoG simplification)
   -- Uses a 2nd derivative approximation to find regions of interest.
   procedure Detect_Blobs
     (Img       : in Image;
      Threshold : in Float;
      Features  : out Feature_Array;
      Count     : out Natural);

   -- 4. Ridge Detection (Simplified Hessian Determinant proxy)
   -- Evaluates principal curvatures to detect continuous 1D features (lines/vessels).
   procedure Detect_Ridges
     (Img       : in Image;
      Threshold : in Float;
      Features  : out Feature_Array;
      Count     : out Natural);

end Feature_Detection;
