--  Package specification: Path_Tracing
--  Implementation of Monte Carlo Path Tracing as described in James Kajiya (1986).
--  Adheres to ISO/IEC 8652:2023 (Ada 2023).

with Ada.Numerics.Float_Random;

package Path_Tracing is

   --  =========================================================================
   --  Domain Types and Subtypes
   --  =========================================================================

   type Real is new Long_Float;
   subtype Unit_Real is Real range 0.0 .. 1.0;
   subtype Non_Negative_Real is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range 1.0e-7 .. Real'Last;

   type Vector_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   type Point_3D is new Vector_3D;

   type Radiance is record
      R : Non_Negative_Real := 0.0;
      G : Non_Negative_Real := 0.0;
      B : Non_Negative_Real := 0.0;
   end record;

   type Color_RGB is record
      R : Unit_Real := 0.0;
      G : Unit_Real := 0.0;
      B : Unit_Real := 0.0;
   end record;

   type Ray is record
      Origin    : Point_3D;
      Direction : Vector_3D;
   end record;

   type Material_Kind is (Diffuse, Specular, Emissive);

   type Material is record
      Kind        : Material_Kind    := Diffuse;
      Albedo      : Color_RGB        := (R => 0.0, G => 0.0, B => 0.0);
      Emission    : Radiance         := (R => 0.0, G => 0.0, B => 0.0);
      Roughness   : Unit_Real        := 0.0;
   end record;

   type Sphere is record
      Center   : Point_3D;
      Radius   : Positive_Real := 1.0;
      Mat      : Material;
   end record;

   type Sphere_Array is array (Positive range <>) of Sphere;

   type Intersection_Record is record
      Hit            : Boolean := False;
      Distance       : Non_Negative_Real := 0.0;
      Point          : Point_3D;
      Normal         : Vector_3D;
      Mat            : Material;
   end record;

   type Trace_Mode is
     (Pure_Path_Tracing,
      Next_Event_Estimation,
      Russian_Roulette);

   type Rendering_Options is record
      Mode                    : Trace_Mode := Pure_Path_Tracing;
      Max_Depth               : Positive   := 5;
      Samples_Per_Pixel       : Positive   := 1;
      Russian_Roulette_Prob   : Unit_Real  := 0.8;
   end record;

   --  =========================================================================
   --  Exceptions
   --  =========================================================================

   Degenerate_Vector_Error  : exception;
   Invalid_Scene_Error      : exception;
   Invalid_Parameters_Error : exception;

   --  =========================================================================
   --  Vector Arithmetic and Geometric Helpers
   --  =========================================================================

   function "+" (Left, Right : Vector_3D) return Vector_3D;
   function "-" (Left, Right : Vector_3D) return Vector_3D;
   function "*" (Left : Vector_3D; Right : Real) return Vector_3D;
   function "/" (Left : Vector_3D; Right : Real) return Vector_3D;

   function Dot (Left, Right : Vector_3D) return Real;
   function Cross (Left, Right : Vector_3D) return Vector_3D;
   function Length_Squared (V : Vector_3D) return Non_Negative_Real;
   function Length (V : Vector_3D) return Non_Negative_Real;

   function Normalize (V : Vector_3D) return Vector_3D
     with Pre => Length_Squared (V) > 1.0e-14;

   function Reflect (V, Normal : Vector_3D) return Vector_3D;

   function Cosine_Sample_Hemisphere
     (Normal : Vector_3D;
      U1, U2 : Unit_Real) return Vector_3D
     with Pre => Length_Squared (Normal) > 1.0e-14;

   --  =========================================================================
   --  Radiance and Color Operations
   --  =========================================================================

   function "+" (Left, Right : Radiance) return Radiance;
   function "*" (Left, Right : Radiance) return Radiance;
   function "*" (Left : Radiance; Right : Color_RGB) return Radiance;
   function "*" (Left : Radiance; Right : Real) return Radiance
     with Pre => Right >= 0.0;
   function "/" (Left : Radiance; Right : Real) return Radiance
     with Pre => Right > 0.0;

   function To_Color (Rad : Radiance) return Color_RGB;

   --  =========================================================================
   --  Ray-Scene Intersection Routines
   --  =========================================================================

   function Intersect_Sphere
     (R : Ray;
      S : Sphere;
      T_Min : Real;
      T_Max : Real) return Intersection_Record;

   function Intersect_Scene
     (R : Ray;
      Objects : Sphere_Array;
      T_Min : Real;
      T_Max : Real) return Intersection_Record;

   --  =========================================================================
   --  Path Tracing Variants (Article Equivalents)
   --  =========================================================================

   --  Variant 1: Pure Monte Carlo Path Tracing (Naive recursion up to Max_Depth)
   function Trace_Pure_Path
     (R           : Ray;
      Scene       : Sphere_Array;
      Max_Depth   : Positive;
      Gen         : in out Ada.Numerics.Float_Random.Generator) return Radiance
     with Pre => Scene'Length > 0;

   --  Variant 2: Path Tracing with Direct Light Sampling (Next Event Estimation)
   function Trace_Next_Event_Estimation
     (R           : Ray;
      Scene       : Sphere_Array;
      Max_Depth   : Positive;
      Gen         : in out Ada.Numerics.Float_Random.Generator) return Radiance
     with Pre => Scene'Length > 0;

   --  Variant 3: Path Tracing with Russian Roulette Termination
   function Trace_Russian_Roulette
     (R             : Ray;
      Scene         : Sphere_Array;
      Survival_Prob : Unit_Real;
      Gen           : in out Ada.Numerics.Float_Random.Generator) return Radiance
     with Pre => Scene'Length > 0 and Survival_Prob > 0.0;

   --  Unified dispatch entry point
   function Trace_Ray
     (R       : Ray;
      Scene   : Sphere_Array;
      Options : Rendering_Options;
      Gen     : in out Ada.Numerics.Float_Random.Generator) return Radiance
     with Pre => Scene'Length > 0;

   --  Validation helper
   function Validate_Scene (Scene : Sphere_Array) return Boolean;

end Path_Tracing;
