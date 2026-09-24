package Ray_Tracing is

   type Real is new Long_Float;

   type Vector3 is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   type Color is record
      R : Real range 0.0 .. 1.0 := 0.0;
      G : Real range 0.0 .. 1.0 := 0.0;
      B : Real range 0.0 .. 1.0 := 0.0;
   end record;

   type Ray is record
      Origin    : Vector3;
      Direction : Vector3;
   end record;

   type Material_Kind is (Diffuse, Specular, Dielectric);

   type Material is record
      Kind            : Material_Kind := Diffuse;
      Albedo          : Color         := (0.8, 0.8, 0.8);
      Reflectivity    : Real          := 0.0;
      Refractive_Index: Real          := 1.0;
      Shininess       : Real          := 32.0;
   end record;

   type Sphere is record
      Center   : Vector3;
      Radius   : Real;
      Mat      : Material;
   end record;

   type Light is record
      Position  : Vector3;
      Intensity : Color;
   end record;

   type Hit_Record is record
      Hit      : Boolean := False;
      Distance : Real    := 0.0;
      Point    : Vector3 := (0.0, 0.0, 0.0);
      Normal   : Vector3 := (0.0, 0.0, 0.0);
      Mat      : Material;
   end record;

   type Sphere_Array is array (Positive range <>) of Sphere;
   type Light_Array is array (Positive range <>) of Light;

   type Scene is record
      Objects      : Sphere_Array (1 .. 16);
      Object_Count : Natural := 0;
      Lights       : Light_Array (1 .. 4);
      Light_Count  : Natural := 0;
      Ambient      : Color   := (0.1, 0.1, 0.1);
   end record;

   type Image_Buffer is array (Positive range <>, Positive range <>) of Color;

   Zero_Vector : constant Vector3 := (0.0, 0.0, 0.0);
   Black_Color : constant Color   := (0.0, 0.0, 0.0);
   White_Color : constant Color   := (1.0, 1.0, 1.0);

   Capacity_Error : exception;
   Zero_Norm_Error : exception;

   function "+" (A, B : Vector3) return Vector3 with Inline;
   function "-" (A, B : Vector3) return Vector3 with Inline;
   function "-" (V : Vector3) return Vector3 with Inline;
   function "*" (A : Vector3; S : Real) return Vector3 with Inline;
   function "*" (S : Real; A : Vector3) return Vector3 with Inline;
   function "/" (A : Vector3; S : Real) return Vector3 with Inline;

   function Dot (A, B : Vector3) return Real with Inline;
   function Cross (A, B : Vector3) return Vector3 with Inline;
   function Length_Squared (V : Vector3) return Real with Inline;
   function Length (V : Vector3) return Real with Inline;
   function Normalized (V : Vector3) return Vector3 with Inline;

   function "+" (A, B : Color) return Color with Inline;
   function "*" (A, B : Color) return Color with Inline;
   function "*" (C : Color; S : Real) return Color with Inline;
   function Clamp_Color (C : Color) return Color with Inline;

   procedure Add_Sphere
     (S      : in out Scene;
      Object : Sphere)
   with
      Pre  => Object.Radius > 0.0,
      Post => S.Object_Count = S.Object_Count'Old + 1;

   procedure Add_Light
     (S     : in out Scene;
      Source : Light)
   with
      Post => S.Light_Count = S.Light_Count'Old + 1;

   function Intersect_Sphere
     (R : Ray;
      S : Sphere) return Hit_Record;

   function Closest_Intersection
     (S : Scene;
      R : Ray) return Hit_Record;

   function Reflect
     (V, N : Vector3) return Vector3
   with
      Inline;

   function Refract
     (V, N  : Vector3;
      Eta_I : Real;
      Eta_T : Real) return Vector3;

   function Trace_Ray_Direct
     (S : Scene;
      R : Ray) return Color;

   function Trace_Ray_Whitted
     (S         : Scene;
      R         : Ray;
      Max_Depth : Natural := 4) return Color;

   function Trace_Ray_Distribution
     (S         : Scene;
      R         : Ray;
      Samples   : Positive := 4;
      Max_Depth : Natural  := 2) return Color;

   procedure Render_Scene
     (S       : Scene;
      Width   : Positive;
      Height  : Positive;
      Buffer  : out Image_Buffer;
      Whitted : Boolean := True);

end Ray_Tracing;
