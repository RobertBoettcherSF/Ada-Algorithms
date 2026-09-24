-- sift_algorithm.ads
-- Specification for the SIFT pipeline
package Sift_Algorithm is

   type Scalar is new Float;
   type Dimension is range 0 .. 10000;

   -- Represents a 128-dimensional SIFT descriptor
   type Descriptor is array (1 .. 128) of Scalar;

   type Keypoint is record
      X, Y          : Scalar;
      Scale         : Scalar;
      Orientation   : Scalar;
      Feature_Vector : Descriptor;
   end record;

   type Keypoint_Array is array (Positive range <>) of Keypoint;

   -- Exceptions for robust error handling
   Invalid_Image_Dimensions : exception;
   Processing_Error         : exception;

   -- Main SIFT Pipeline Stages
   -- 1. Build Scale Space (Octaves & Gaussian Blurring)
   procedure Build_Scale_Space(Width, Height : Dimension);

   -- 2. Detect Extrema (Difference of Gaussians)
   procedure Detect_Extrema(Output_Keypoints : out Keypoint_Array);

   -- 3. Keypoint Localization (Refining sub-pixel accuracy)
   procedure Localize_Keypoints(Points : in out Keypoint_Array);

   -- 4. Orientation Assignment (Gradient calculation)
   procedure Assign_Orientation(Point : in out Keypoint);

   -- 5. Generate Descriptors (128-dim vectors)
   procedure Generate_Descriptor(Point : in out Keypoint);

end Sift_Algorithm;
