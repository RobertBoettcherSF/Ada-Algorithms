-- surf.ads
-- Specification for the Speeded Up Robust Features (SURF) algorithm.
-- Includes definitions for all variants: Standard, U-SURF, SURF-128, and U-SURF-128.

package SURF is

   -- Strong typing for numerical precision
   type Real is new Float;
   
   -- 2D arrays representing images and integral images
   type Image is array (Integer range <>, Integer range <>) of Real;
   type Integral_Image is array (Integer range <>, Integer range <>) of Real;

   -- SURF Variants as described in the literature
   -- Standard_SURF : Rotation invariant, 64-dimensional
   -- U_SURF        : Upright (not rotation invariant, faster), 64-dimensional
   -- SURF_128      : Rotation invariant, 128-dimensional (extended for distinctiveness)
   -- U_SURF_128    : Upright, 128-dimensional
   type SURF_Variant is (Standard_SURF, U_SURF, SURF_128, U_SURF_128);

   -- Representation of a detected interest point
   type Keypoint is record
      X           : Integer;
      Y           : Integer;
      Scale       : Real;
      Orientation : Real; -- 0.0 for U-SURF variants
      Response    : Real; -- Hessian determinant value
      Laplacian   : Integer; -- Sign of the Laplacian (+1 or -1) for fast matching
   end record;

   type Keypoint_Array is array (Positive range <>) of Keypoint;

   -- Descriptor types for standard and extended variants
   type Descriptor_64 is array (1 .. 64) of Real;
   type Descriptor_128 is array (1 .. 128) of Real;

   -- Combined feature representations
   type Feature_64 is record
      Pt   : Keypoint;
      Desc : Descriptor_64;
   end record;

   type Feature_128 is record
      Pt   : Keypoint;
      Desc : Descriptor_128;
   end record;

   type Feature_64_Array is array (Positive range <>) of Feature_64;
   type Feature_128_Array is array (Positive range <>) of Feature_128;

   -- Exceptions
   Image_Error : exception;

   -- Helper Functions
   function Compute_Integral_Image (Img : Image) return Integral_Image;
   function Box_Area_Sum (I_Img : Integral_Image; X, Y, W, H : Integer) return Real;
   function Determinant_Of_Hessian (I_Img : Integral_Image; X, Y, Filter_Size : Integer) return Real;

   -- Core Algorithm Procedures
   procedure Extract_Features_64
     (Img       : in Image;
      Variant   : in SURF_Variant;
      Features  : out Feature_64_Array;
      Count     : out Natural;
      Threshold : in Real := 1000.0);

   procedure Extract_Features_128
     (Img       : in Image;
      Variant   : in SURF_Variant;
      Features  : out Feature_128_Array;
      Count     : out Natural;
      Threshold : in Real := 1000.0);

end SURF;
