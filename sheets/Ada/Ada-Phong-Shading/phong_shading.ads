--  Package: Phong_Shading
--  Specification for Phong shading interpolation and illumination models:
--  classic Phong reflection, Blinn-Phong reflection, and normal interpolation.

with Ada.Numerics.Generic_Elementary_Functions;

package Phong_Shading with SPARK_Mode => On is

   --  ========================================================================
   --  Custom Scalar and Vector Types
   --  ========================================================================

   type Real is new Long_Float;

   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   subtype Intensity_Value is Real range 0.0 .. 1.0;
   subtype Shininess_Value is Real range 0.1 .. 10_000.0;
   subtype Attenuation_Coeff is Real range 0.0 .. 100.0;

   type Vector_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   subtype Unit_Vector_3D is Vector_3D;

   type Color_RGB is record
      R : Intensity_Value := 0.0;
      G : Intensity_Value := 0.0;
      B : Intensity_Value := 0.0;
   end record;

   --  ========================================================================
   --  Material and Light Structures
   --  ========================================================================

   type Material_Properties is record
      Ambient_Coeff   : Intensity_Value := 0.1;
      Diffuse_Coeff   : Intensity_Value := 0.7;
      Specular_Coeff  : Intensity_Value := 0.5;
      Shininess       : Shininess_Value := 32.0;
      Ambient_Color   : Color_RGB       := (1.0, 1.0, 1.0);
      Diffuse_Color   : Color_RGB       := (1.0, 1.0, 1.0);
      Specular_Color  : Color_RGB       := (1.0, 1.0, 1.0);
   end record;

   type Light_Attenuation is record
      Constant_Term  : Attenuation_Coeff := 1.0;
      Linear_Term    : Attenuation_Coeff := 0.0;
      Quadratic_Term : Attenuation_Coeff := 0.0;
   end record;

   type Point_Light is record
      Position    : Vector_3D;
      Color       : Color_RGB;
      Attenuation : Light_Attenuation;
   end record;

   type Directional_Light is record
      Direction : Unit_Vector_3D;
      Color     : Color_RGB;
   end record;

   type Triangle_Normals is record
      N0 : Vector_3D;
      N1 : Vector_3D;
      N2 : Vector_3D;
   end record;

   --  ========================================================================
   --  Exceptions
   --  ========================================================================

   Zero_Vector_Error       : exception;
   Degenerate_Normal_Error : exception;
   Invalid_Barycentric_Coord : exception;

   --  ========================================================================
   --  Vector Operations and Math Helpers
   --  ========================================================================

   function "+" (Left, Right : Vector_3D) return Vector_3D with
     Global => null;

   function "-" (Left, Right : Vector_3D) return Vector_3D with
     Global => null;

   function "-" (V : Vector_3D) return Vector_3D with
     Global => null;

   function "*" (Scalar : Real; V : Vector_3D) return Vector_3D with
     Global => null;

   function Dot_Product (Left, Right : Vector_3D) return Real with
     Global => null;

   function Cross_Product (Left, Right : Vector_3D) return Vector_3D with
     Global => null;

   function Squared_Norm (V : Vector_3D) return Real with
     Global => null,
     Post   => Squared_Norm'Result >= 0.0;

   function Norm (V : Vector_3D) return Real with
     Global => null,
     Post   => Norm'Result >= 0.0;

   function Normalize (V : Vector_3D) return Unit_Vector_3D with
     Global => null;

   function Reflect
     (L : Unit_Vector_3D;
      N : Unit_Vector_3D) return Unit_Vector_3D with
     Global => null;

   function Halfway_Vector
     (L : Unit_Vector_3D;
      V : Unit_Vector_3D) return Unit_Vector_3D with
     Global => null;

   --  ========================================================================
   --  Color Operations
   --  ========================================================================

   function Make_Color
     (R, G, B : Real) return Color_RGB with
     Global => null;

   function Add_Colors (C1, C2 : Color_RGB) return Color_RGB with
     Global => null;

   function Modulate_Colors (C1, C2 : Color_RGB) return Color_RGB with
     Global => null;

   function Scale_Color
     (C     : Color_RGB;
      Scale : Intensity_Value) return Color_RGB with
     Global => null;

   --  ========================================================================
   --  Normal Interpolation (Phong Shading Interpolation Kernel)
   --  ========================================================================

   function Interpolate_Normal
     (Normals : Triangle_Normals;
      W0, W1, W2 : Real) return Unit_Vector_3D with
     Global => null,
     Pre    => (W0 >= -0.0001 and then W1 >= -0.0001 and then W2 >= -0.0001)
               and then (abs (W0 + W1 + W2 - 1.0) < 0.001);

   --  ========================================================================
   --  Illumination Model Variants
   --  ========================================================================

   --  Classic Phong Illumination Model:
   --  I = I_amb + I_diff * (L . N) + I_spec * (R . V)^alpha
   function Classic_Phong_Light
     (Surface_Pos : Vector_3D;
      Normal      : Unit_Vector_3D;
      View_Dir    : Unit_Vector_3D;
      Light       : Point_Light;
      Material    : Material_Properties;
      Ambient_Light : Color_RGB) return Color_RGB with
     Global => null;

   --  Blinn-Phong Illumination Model:
   --  I = I_amb + I_diff * (L . N) + I_spec * (N . H)^alpha
   function Blinn_Phong_Light
     (Surface_Pos  : Vector_3D;
      Normal       : Unit_Vector_3D;
      View_Dir     : Unit_Vector_3D;
      Light        : Point_Light;
      Material     : Material_Properties;
      Ambient_Light : Color_RGB) return Color_RGB with
     Global => null;

   --  Directional Light Classic Phong Model
   function Classic_Phong_Directional
     (Normal       : Unit_Vector_3D;
      View_Dir     : Unit_Vector_3D;
      Light        : Directional_Light;
      Material     : Material_Properties;
      Ambient_Light : Color_RGB) return Color_RGB with
     Global => null;

   --  Directional Light Blinn-Phong Model
   function Blinn_Phong_Directional
     (Normal       : Unit_Vector_3D;
      View_Dir     : Unit_Vector_3D;
      Light        : Directional_Light;
      Material     : Material_Properties;
      Ambient_Light : Color_RGB) return Color_RGB with
     Global => null;

   --  Helper for Distance Attenuation calculation
   function Compute_Attenuation
     (Distance : Real;
      Atten    : Light_Attenuation) return Real with
     Global => null,
     Pre    => Distance >= 0.0,
     Post   => Compute_Attenuation'Result >= 0.0;

end Phong_Shading;
