--  Package: Shading
--  Specification of 3D computer graphics shading models based on:
--  https://en.wikipedia.org/wiki/Shading
--  Complies with Ada 2023 (ISO/IEC 8652:2023).

with Ada.Numerics.Generic_Elementary_Functions;

package Shading with SPARK_Mode => On is

   --  ======================================================================
   --  Primitive & Domain Types
   --  ======================================================================

   type Real is new Long_Float;

   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   subtype Intensity_Value is Real range 0.0 .. 1.0;
   subtype Falloff_Power   is Real range 0.0 .. 10.0;
   subtype Shininess_Value is Real range 1.0 .. 500.0;
   subtype Attenuation_Val is Real range 0.0 .. Real'Last;
   subtype Distance_Value  is Real range 0.0 .. Real'Last;

   --  3D Vector and coordinate representations
   type Vector_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   --  Color representation with normalized color channels [0.0, 1.0]
   type Color_RGB is record
      R : Intensity_Value := 0.0;
      G : Intensity_Value := 0.0;
      B : Intensity_Value := 0.0;
   end record;

   Black : constant Color_RGB := (R => 0.0, G => 0.0, B => 0.0);
   White : constant Color_RGB := (R => 1.0, G => 1.0, B => 1.0);

   --  Barycentric coordinates for triangular interpolation:
   --  Weight_A + Weight_B + Weight_C must equal 1.0.
   type Barycentric_Weights is record
      U : Intensity_Value := 0.0;  --  Weight for Vertex A
      V : Intensity_Value := 0.0;  --  Weight for Vertex B
      W : Intensity_Value := 0.0;  --  Weight for Vertex C
   end record;

   --  ======================================================================
   --  Lighting Types
   --  ======================================================================

   --  Distance falloff models as detailed in Wikipedia article:
   --  None (n = 0), Linear (n = 1), Quadratic (n = 2), or Arbitrary Power
   type Falloff_Kind is (None, Linear, Quadratic, Custom_Power);

   type Distance_Falloff is record
      Kind  : Falloff_Kind  := None;
      Power : Falloff_Power := 0.0;
   end record;

   type Light_Kind is (Ambient, Directional, Point_Light, Spot_Light);

   --  Light Source configuration
   type Light_Source is record
      Kind      : Light_Kind        := Ambient;
      Color     : Color_RGB         := White;
      Intensity : Intensity_Value   := 1.0;
      Position  : Vector_3D         := (0.0, 0.0, 0.0);
      Direction : Vector_3D         := (0.0, -1.0, 0.0);  -- Direction light shines toward
      Falloff   : Distance_Falloff  := (Kind => None, Power => 0.0);
      Spot_Cone_Angle_Deg : Real    := 45.0;              -- Spotlight cutoff angle
      Spot_Dropoff_Exp    : Real    := 1.0;               -- Spot concentration factor
   end record;

   type Light_Array is array (Positive range <>) of Light_Source;

   --  ======================================================================
   --  Material and Geometry Types
   --  ======================================================================

   type Material is record
      Ambient_Color     : Color_RGB       := (0.1, 0.1, 0.1);
      Diffuse_Color     : Color_RGB       := (0.7, 0.7, 0.7);
      Specular_Color    : Color_RGB       := (1.0, 1.0, 1.0);
      Ambient_Coeff     : Intensity_Value := 0.2;
      Diffuse_Coeff     : Intensity_Value := 0.8;
      Specular_Coeff    : Intensity_Value := 0.5;
      Shininess         : Shininess_Value := 32.0;
   end record;

   type Vertex is record
      Position : Vector_3D  := (0.0, 0.0, 0.0);
      Normal   : Vector_3D  := (0.0, 1.0, 0.0);
      Color    : Color_RGB  := White;
   end record;

   type Triangle is record
      V0 : Vertex;
      V1 : Vertex;
      V2 : Vertex;
   end record;

   --  G-Buffer fragment for Deferred Shading:
   --  Stores world position, normal, material, and depth for lighting pass.
   type G_Buffer_Pixel is record
      Valid        : Boolean   := False;
      Position     : Vector_3D := (0.0, 0.0, 0.0);
      Normal       : Vector_3D := (0.0, 1.0, 0.0);
      Albedo       : Color_RGB := Black;
      Depth        : Real      := 0.0;
      Ambient_Amt  : Intensity_Value := 0.1;
      Specular_Amt : Intensity_Value := 0.5;
      Shininess    : Shininess_Value := 32.0;
   end record;

   type G_Buffer is array (Positive range <>, Positive range <>) of G_Buffer_Pixel;
   type Framebuffer is array (Positive range <>, Positive range <>) of Color_RGB;

   --  ======================================================================
   --  Exceptions
   --  ======================================================================

   Degenerate_Geometry_Error : exception;
   Zero_Vector_Error         : exception;
   Invalid_Weights_Error     : exception;
   Buffer_Dimension_Mismatch : exception;

   --  ======================================================================
   --  Vector & Color Operations
   --  ======================================================================

   function Make_Vector (X, Y, Z : Real) return Vector_3D is
     (Vector_3D'(X => X, Y => Y, Z => Z));

   function "+" (Left, Right : Vector_3D) return Vector_3D is
     (Vector_3D'(X => Left.X + Right.X,
                 Y => Left.Y + Right.Y,
                 Z => Left.Z + Right.Z));

   function "-" (Left, Right : Vector_3D) return Vector_3D is
     (Vector_3D'(X => Left.X - Right.X,
                 Y => Left.Y - Right.Y,
                 Z => Left.Z - Right.Z));

   function "*" (Left : Real; Right : Vector_3D) return Vector_3D is
     (Vector_3D'(X => Left * Right.X,
                 Y => Left * Right.Y,
                 Z => Left * Right.Z));

   function Dot_Product (Left, Right : Vector_3D) return Real is
     (Left.X * Right.X + Left.Y * Right.Y + Left.Z * Right.Z);

   function Cross_Product (Left, Right : Vector_3D) return Vector_3D is
     (Vector_3D'(X => Left.Y * Right.Z - Left.Z * Right.Y,
                 Y => Left.Z * Right.X - Left.X * Right.Z,
                 Z => Left.X * Right.Y - Left.Y * Right.X));

   function Magnitude_Squared (V : Vector_3D) return Real is
     (Dot_Product (V, V));

   function Magnitude (V : Vector_3D) return Distance_Value;

   function Normalize (V : Vector_3D) return Vector_3D with
     Pre => Magnitude_Squared (V) > 0.0;

   function Reflect (Light_Dir, Normal : Vector_3D) return Vector_3D with
     Pre => Magnitude_Squared (Normal) > 0.0;

   function Make_Color (R, G, B : Real) return Color_RGB;

   function Add_Colors (C1, C2 : Color_RGB) return Color_RGB;

   function Modulate_Colors (C1, C2 : Color_RGB) return Color_RGB;

   function Scale_Color (C : Color_RGB; Factor : Intensity_Value) return Color_RGB;

   function Distance (A, B : Vector_3D) return Distance_Value is
     (Magnitude (A - B));

   --  ======================================================================
   --  Distance Falloff Calculation
   --  ======================================================================

   function Compute_Falloff (Dist : Distance_Value; Falloff : Distance_Falloff)
      return Attenuation_Val with
     Post => Compute_Falloff'Result >= 0.0;

   --  ======================================================================
   --  Illumination Model Evaluation
   --  Evaluates Phong lighting equation at an arbitrary surface point
   --  given the point position, unit normal vector, camera position, material,
   --  and light list.
   --  ======================================================================

   function Evaluate_Lighting
     (Position    : Vector_3D;
      Normal      : Vector_3D;
      View_Pos    : Vector_3D;
      Mat         : Material;
      Lights      : Light_Array) return Color_RGB with
     Pre => Magnitude_Squared (Normal) > 0.0;

   --  ======================================================================
   --  Barycentric Interpolation Helpers
   --  ======================================================================

   function Make_Barycentric (U, V, W : Real) return Barycentric_Weights with
     Pre => (U >= 0.0 and then V >= 0.0 and then W >= 0.0);

   function Interpolate_Vector
     (A, B, C : Vector_3D;
      W       : Barycentric_Weights) return Vector_3D;

   function Interpolate_Color
     (A, B, C : Color_RGB;
      W       : Barycentric_Weights) return Color_RGB;

   --  Compute triangle surface face normal
   function Triangle_Face_Normal (Tri : Triangle) return Vector_3D with
     Pre => Magnitude_Squared (Cross_Product (Tri.V1.Position - Tri.V0.Position,
                                              Tri.V2.Position - Tri.V0.Position)) > 0.0;

   --  ======================================================================
   --  Variant 1: Flat Shading
   --  Evaluates lighting once per polygon (face) using the representative
   --  geometric face normal and centroid position.
   --  ======================================================================

   function Shade_Flat
     (Tri      : Triangle;
      Mat      : Material;
      View_Pos : Vector_3D;
      Lights   : Light_Array) return Color_RGB with
     Pre => Magnitude_Squared (Cross_Product (Tri.V1.Position - Tri.V0.Position,
                                              Tri.V2.Position - Tri.V0.Position)) > 0.0;

   --  ======================================================================
   --  Variant 2: Gouraud Shading
   --  Evaluates lighting at each vertex and bilinearly interpolates vertex
   --  colors across the face.
   --  ======================================================================

   function Shade_Gouraud
     (Tri      : Triangle;
      Mat      : Material;
      Weights  : Barycentric_Weights;
      View_Pos : Vector_3D;
      Lights   : Light_Array) return Color_RGB with
     Pre => (Magnitude_Squared (Tri.V0.Normal) > 0.0 and then
             Magnitude_Squared (Tri.V1.Normal) > 0.0 and then
             Magnitude_Squared (Tri.V2.Normal) > 0.0);

   --  ======================================================================
   --  Variant 3: Phong Shading
   --  Interpolates vertex normals across the polygon surface using barycentric
   --  coordinates, normalizes the interpolated normal, and evaluates lighting
   --  per fragment.
   --  ======================================================================

   function Shade_Phong
     (Tri      : Triangle;
      Mat      : Material;
      Weights  : Barycentric_Weights;
      View_Pos : Vector_3D;
      Lights   : Light_Array) return Color_RGB with
     Pre => (Magnitude_Squared (Tri.V0.Normal) > 0.0 and then
             Magnitude_Squared (Tri.V1.Normal) > 0.0 and then
             Magnitude_Squared (Tri.V2.Normal) > 0.0);

   --  ======================================================================
   --  Variant 4: Deferred Shading
   --  Two-pass pipeline:
   --  Pass 1: Geometry Pass populates G-Buffer (depth, position, normal, albedo).
   --  Pass 2: Lighting Pass evaluates lighting using G-Buffer data.
   --  ======================================================================

   procedure Deferred_Geometry_Pass
     (Buffer   : in out G_Buffer;
      X, Y     : Positive;
      Pos      : Vector_3D;
      Normal   : Vector_3D;
      Mat      : Material;
      Depth    : Real) with
     Pre => (X in Buffer'Range (1) and then
             Y in Buffer'Range (2) and then
             Magnitude_Squared (Normal) > 0.0);

   procedure Deferred_Lighting_Pass
     (Buffer   : in G_Buffer;
      Output   : out Framebuffer;
      View_Pos : Vector_3D;
      Lights   : Light_Array) with
     Pre => (Buffer'First (1) = Output'First (1) and then
             Buffer'Last (1)  = Output'Last (1)  and then
             Buffer'First (2) = Output'First (2) and then
             Buffer'Last (2)  = Output'Last (2));

end Shading;
