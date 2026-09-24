--  Package specification for Image-Based Lighting (IBL) computations
--  Standard: Ada 2023 (ISO/IEC 8652:2023)

package Image_Based_Lighting with
  SPARK_Mode => Off
is

   --  ======================================================================
   --  Types and Domain Subtypes
   --  ======================================================================

   type Real is digits 6;

   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Dimension_Index is Positive range 1 .. 8192;
   subtype Roughness_Value is Real range 0.0 .. 1.0;

   --  3D Euclidean vector representing directions or positions
   type Vector3 is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   --  Linear photometric RGB radiance / irradiance color
   type Color_RGB is record
      R : Real := 0.0;
      G : Real := 0.0;
      B : Real := 0.0;
   end record;

   --  Spherical Coordinates: Polar angle Theta [0, Pi], Azimuth Phi [0, 2*Pi]
   type Spherical_Coord is record
      Theta : Real := 0.0;
      Phi   : Real := 0.0;
   end record;

   --  Equirectangular (Latitude-Longitude) Environment Map Matrix
   type Radiance_Matrix is
     array (Dimension_Index range <>, Dimension_Index range <>) of Color_RGB;

   type Environment_Map
     (Width  : Dimension_Index;
      Height : Dimension_Index) is record
      Data : Radiance_Matrix (1 .. Height, 1 .. Width);
   end record;

   --  Order-2 Spherical Harmonics coefficients (L_0,0 through L_2,2: 9 bands)
   type SH_Index is range 1 .. 9;
   type SH_Coefficients is array (SH_Index) of Color_RGB;

   --  Split-Sum BRDF Integration Look-Up Table (LUT) item
   type BRDF_Lut_Entry is record
      Scale : Real := 0.0;
      Bias  : Real := 0.0;
   end record;

   type BRDF_Lut_Matrix is
     array (Dimension_Index range <>, Dimension_Index range <>) of BRDF_Lut_Entry;

   type BRDF_LUT (Size : Dimension_Index) is record
      Data : BRDF_Lut_Matrix (1 .. Size, 1 .. Size);
   end record;

   --  Exceptions
   Invalid_Direction_Error : exception;
   Invalid_Dimension_Error : exception;

   --  ======================================================================
   --  Math and Geometric Helpers
   --  ======================================================================

   function Vector_Length (V : Vector3) return Real with
     Post => Vector_Length'Result >= 0.0;

   function Normalize (V : Vector3) return Vector3 with
     Pre  => Vector_Length (V) > 1.0e-7,
     Post => abs (Vector_Length (Normalize'Result) - 1.0) <= 1.0e-3;

   function Dot_Product (U, V : Vector3) return Real;

   function Clamp_Color (C : Color_RGB) return Color_RGB with
     Post => Clamp_Color'Result.R >= 0.0 and then
             Clamp_Color'Result.G >= 0.0 and then
             Clamp_Color'Result.B >= 0.0;

   function Direction_To_Spherical (Dir : Vector3) return Spherical_Coord with
     Pre => abs (Vector_Length (Dir) - 1.0) <= 1.0e-3;

   function Spherical_To_Direction (Coord : Spherical_Coord) return Vector3 with
     Post => abs (Vector_Length (Spherical_To_Direction'Result) - 1.0) <= 1.0e-3;

   --  Sample environment map using continuous equirectangular coordinates
   function Sample_Equirectangular
     (Env : Environment_Map;
      Dir : Vector3) return Color_RGB with
     Pre => abs (Vector_Length (Dir) - 1.0) <= 1.0e-3;

   --  ======================================================================
   --  Variant 1: Mirror / Perfect Specular Reflection Mapping
   --  ======================================================================
   --  Computes the reflected radiance ray R = V - 2(V.N)N and queries the map.
   function Evaluate_Mirror_Reflection
     (Env         : Environment_Map;
      View_Vector : Vector3;
      Normal      : Vector3) return Color_RGB with
     Pre => abs (Vector_Length (View_Vector) - 1.0) <= 1.0e-3 and then
            abs (Vector_Length (Normal) - 1.0) <= 1.0e-3;

   --  ======================================================================
   --  Variant 2: Diffuse Cosine-Weighted Hemisphere Irradiance Convolution
   --  ======================================================================
   --  Numerically integrates E(N) = Integral (L(w) * max(N . w, 0) dw) over
   --  the hemisphere aligned with normal N using discrete angular steps.
   function Convolve_Diffuse_Irradiance
     (Env        : Environment_Map;
      Normal     : Vector3;
      Step_Theta : Real := 0.05;
      Step_Phi   : Real := 0.05) return Color_RGB with
     Pre => abs (Vector_Length (Normal) - 1.0) <= 1.0e-3 and then
            Step_Theta > 0.0 and then Step_Phi > 0.0;

   --  ======================================================================
   --  Variant 3: Spherical Harmonics (Order-2, 9 Coefficients) Irradiance
   --  ======================================================================
   --  Projects radiance into 9 SH basis functions, then evaluates diffuse
   --  irradiance efficiently via Ramamoorthi-Hanrahan convolution formulas.
   function Project_Spherical_Harmonics
     (Env         : Environment_Map;
      Sample_Step : Real := 0.05) return SH_Coefficients with
     Pre => Sample_Step > 0.0;

   function Evaluate_SH_Irradiance
     (Coeffs : SH_Coefficients;
      Normal : Vector3) return Color_RGB with
     Pre => abs (Vector_Length (Normal) - 1.0) <= 1.0e-3;

   --  ======================================================================
   --  Variant 4: Split-Sum Specular Approximation (Karis / Epic Games PBR)
   --  ======================================================================
   --  Part A: Pre-filtered environment radiance sample for roughness alpha
   function Evaluate_Prefiltered_Specular
     (Env          : Environment_Map;
      Reflect_Dir  : Vector3;
      Roughness    : Roughness_Value;
      Num_Samples  : Positive := 64) return Color_RGB with
     Pre => abs (Vector_Length (Reflect_Dir) - 1.0) <= 1.0e-3;

   --  Part B: Pre-integrate 2D environment BRDF (Scale, Bias)
   function Precompute_BRDF_LUT (Size : Dimension_Index) return BRDF_LUT;

   function Sample_BRDF_LUT
     (Lut       : BRDF_LUT;
      NoV       : Unit_Interval;
      Roughness : Roughness_Value) return BRDF_Lut_Entry;

   --  Part C: Combine Split-Sum specular parts with Fresnel Schlick
   function Evaluate_Split_Sum_Specular
     (Prefiltered_Color : Color_RGB;
      BRDF_Scale_Bias   : BRDF_Lut_Entry;
      F0                : Color_RGB) return Color_RGB;

end Image_Based_Lighting;
