--  Package specification for Gouraud Shading
--  Compliant with Ada 2022 / Ada 2023 (ISO/IEC 8652:2023)
--  Implements vertex illumination, edge interpolation, scanline rasterization,
--  and normal vector averaging according to Henri Gouraud (1971).

package Gouraud_Shading with SPARK_Mode => Off is

   --  -------------------------------------------------------------
   --  Type Definitions
   --  -------------------------------------------------------------

   type Real is new Long_Float;

   type Intensity is new Real range 0.0 .. 1.0;

   type Color_Component is new Real range 0.0 .. 1.0;

   type RGB_Color is record
      R : Color_Component := 0.0;
      G : Color_Component := 0.0;
      B : Color_Component := 0.0;
   end record;

   type Vector_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   type Vertex_2D is record
      X : Real := 0.0;
      Y : Real := 0.0;
   end record;

   --  Shaded vertex with scalar intensity
   type Shaded_Vertex_Scalar is record
      Pos       : Vertex_2D;
      Intensity : Gouraud_Shading.Intensity := 0.0;
   end record;

   --  Shaded vertex with full RGB color
   type Shaded_Vertex_RGB is record
      Pos   : Vertex_2D;
      Color : RGB_Color;
   end record;

   --  3D Vertex with position and surface normal
   type Vertex_3D is record
      Pos    : Vector_3D;
      Normal : Vector_3D;
   end record;

   type Triangle_3D_Indices is record
      V1 : Positive;
      V2 : Positive;
      V3 : Positive;
   end record;

   type Vertex_3D_Array is array (Positive range <>) of Vertex_3D;
   type Triangle_Index_Array is array (Positive range <>) of Triangle_3D_Indices;
   type Vector_3D_Array is array (Positive range <>) of Vector_3D;

   --  Frame buffer pixel representations
   type Pixel_Span is record
      X_Start     : Integer;
      X_End       : Integer;
      Y           : Integer;
      Color_Start : RGB_Color;
      Color_End   : RGB_Color;
   end record;

   --  A 2D Framebuffer grid of RGB pixels
   type Framebuffer is array (Natural range <>, Natural range <>) of RGB_Color;

   --  Exceptions
   Degenerate_Triangle_Error : exception;
   Invalid_Normal_Error      : exception;
   Zero_Division_Error       : exception;

   --  -------------------------------------------------------------
   --  Helper Subprograms: Vector, Color, and Math Operations
   --  -------------------------------------------------------------

   function Dot_Product (U, V : Vector_3D) return Real with
     Global => null;

   function Vector_Length (V : Vector_3D) return Real with
     Global => null;

   function Normalize (V : Vector_3D) return Vector_3D with
     Global => null;

   function Cross_Product (U, V : Vector_3D) return Vector_3D with
     Global => null;

   function Add_Colors (C1, C2 : RGB_Color) return RGB_Color with
     Global => null;

   function Scale_Color (C : RGB_Color; Factor : Real) return RGB_Color with
     Pre    => Factor >= 0.0,
     Global => null;

   function Multiply_Colors (C1, C2 : RGB_Color) return RGB_Color with
     Global => null;

   function Clamp_Color (C : RGB_Color) return RGB_Color with
     Global => null;

   function Clamp_Intensity (Val : Real) return Intensity with
     Global => null;

   --  Linear interpolation between two intensities
   function Lerp_Intensity (I1, I2 : Intensity; T : Real) return Intensity with
     Pre    => T >= 0.0 and then T <= 1.0,
     Global => null;

   --  Linear interpolation between two RGB colors
   function Lerp_Color (C1, C2 : RGB_Color; T : Real) return RGB_Color with
     Pre    => T >= 0.0 and then T <= 1.0,
     Global => null;

   --  -------------------------------------------------------------
   --  Variant 1: Vertex Normal Averaging
   --  Calculates smooth vertex normals from neighboring polygon faces
   --  -------------------------------------------------------------

   function Compute_Vertex_Normals
     (Vertices  : Vertex_3D_Array;
      Triangles : Triangle_Index_Array) return Vector_3D_Array with
     Pre    => Vertices'Length > 0 and then Triangles'Length > 0,
     Post   => Compute_Vertex_Normals'Result'Length = Vertices'Length,
     Global => null;

   --  -------------------------------------------------------------
   --  Variant 2: Vertex Illumination Calculation
   --  Computes vertex intensity / color using Lambertian + Blinn-Phong
   --  -------------------------------------------------------------

   function Calculate_Vertex_Lambert_Intensity
     (Surface_Normal : Vector_3D;
      Light_Dir      : Vector_3D;
      Ambient        : Intensity := 0.1;
      Diffuse        : Intensity := 0.9) return Intensity with
     Global => null;

   function Calculate_Vertex_Phong_Color
     (Position       : Vector_3D;
      Normal         : Vector_3D;
      View_Pos       : Vector_3D;
      Light_Pos      : Vector_3D;
      Light_Color    : RGB_Color;
      Material_Color : RGB_Color;
      Ka             : Real := 0.1;
      Kd             : Real := 0.7;
      Ks             : Real := 0.2;
      Shininess      : Real := 32.0) return RGB_Color with
     Pre    => Ka >= 0.0 and then Kd >= 0.0 and then Ks >= 0.0 and then Shininess > 0.0,
     Global => null;

   --  -------------------------------------------------------------
   --  Variant 3: Analytical Barycentric Gouraud Interpolation
   --  Evaluates the shaded color/intensity directly at a point (P)
   --  -------------------------------------------------------------

   function Interpolate_Barycentric_Intensity
     (V1, V2, V3 : Shaded_Vertex_Scalar;
      P          : Vertex_2D) return Intensity with
     Global => null;

   function Interpolate_Barycentric_Color
     (V1, V2, V3 : Shaded_Vertex_RGB;
      P          : Vertex_2D) return RGB_Color with
     Global => null;

   --  -------------------------------------------------------------
   --  Variant 4: Scanline Gouraud Rasterization (Scalar Intensity)
   --  Renders a triangle into a buffer using scanline edge walking
   --  -------------------------------------------------------------

   procedure Rasterize_Triangle_Scalar
     (V1, V2, V3 : Shaded_Vertex_Scalar;
      Buffer     : in out Framebuffer;
      Base_Color : RGB_Color := (R => 1.0, G => 1.0, B => 1.0)) with
     Global => null;

   --  -------------------------------------------------------------
   --  Variant 5: Scanline Gouraud Rasterization (Full RGB Colors)
   --  Performs standard Gouraud interpolation across edges and scanlines
   --  -------------------------------------------------------------

   procedure Rasterize_Triangle_RGB
     (V1, V2, V3 : Shaded_Vertex_RGB;
      Buffer     : in out Framebuffer) with
     Global => null;

end Gouraud_Shading;
