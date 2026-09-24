--  Cone_Tracing — Ada 2023 educational implementation of cone / beam tracing
--  algorithms (circular cones, pyramidal beams, soft shadows, DoF, LOD).
--  Based on principles from Wikipedia "Cone tracing" and classic CG literature.

pragma Ada_2022;

package Cone_Tracing
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (never bare Float / Integer where domain types apply)
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   --  Half-angle of a circular cone: [0, pi/2]
   subtype Half_Angle_Rad is Real range 0.0 .. 1.570_796;
   subtype Roughness is Unit_Interval;
   subtype LOD_Level is Natural;

   type Vec3 is record
      X, Y, Z : Real := 0.0;
   end record;

   subtype Apex_Point    is Vec3;
   subtype Axis_Direction is Vec3;  -- intended unit length after Normalize
   subtype Hit_Point     is Vec3;

   type Cone is record
      Apex       : Apex_Point;
      Axis       : Axis_Direction;  -- unit direction from apex
      Half_Angle : Half_Angle_Rad;      -- aperture half-angle (radians)
   end record;

   --  Pyramidal beam / frustum through a rectangular pixel (four corner dirs)
   type Corner_Index is range 1 .. 4;
   type Corner_Dirs is array (Corner_Index) of Axis_Direction;

   type Beam_Frustum is record
      Origin  : Apex_Point;
      Corners : Corner_Dirs;  -- unit directions through pixel corners
   end record;

   type Sphere is record
      Center : Vec3;
      Radius : Non_Negative;
   end record;

   type Plane is record
      Point  : Vec3;   -- any point on the plane
      Normal : Vec3;   -- unit normal
   end record;

   type AABB is record
      Min_P, Max_P : Vec3;
   end record;

   type Soft_Shadow_Result is record
      Umbra_Factor    : Unit_Interval;  -- 0 = full shadow, 1 = fully lit
      Penumbra_Width  : Non_Negative;   -- angular / linear proxy
      Cone_Used       : Cone;
   end record;

   type Footprint_Result is record
      Radius_At_Hit : Non_Negative;
      Filter_Width  : Non_Negative;
      Mip_Level     : LOD_Level;
   end record;

   type DoF_Cone_Result is record
      Cone_At_Distance : Cone;
      Cross_Section    : Non_Negative;  -- radius of cone at query distance
      Focus_Distance   : Non_Negative;
   end record;

   type Cone_Sphere_Hit is record
      Intersects     : Boolean;
      Enter_Distance : Non_Negative;
      Exit_Distance  : Non_Negative;
      Coverage       : Unit_Interval;  -- approximate solid-angle coverage
   end record;

   type Cone_Plane_Hit is record
      Intersects     : Boolean;
      Distance       : Non_Negative;
      Disk_Radius    : Non_Negative;  -- footprint radius on the plane
      Center_Hit     : Hit_Point;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Input      : exception;
   Degenerate_Geometry : exception;

   ---------------------------------------------------------------------------
   -- Shared vector / numeric helpers (public for tests & reuse)
   ---------------------------------------------------------------------------

   function Length (V : Vec3) return Non_Negative
     with Global => null;

   function Normalize (V : Vec3) return Axis_Direction
     with Pre    => Length (V) > 0.0,
          Post   => abs (Length (Normalize'Result) - 1.0) <= 1.0E-4,
          Global => null;

   function Dot (A, B : Vec3) return Real
     with Global => null;

   function Cross (A, B : Vec3) return Vec3
     with Global => null;

   function "-" (A, B : Vec3) return Vec3
     with Global => null;

   function "+" (A, B : Vec3) return Vec3
     with Global => null;

   function "*" (S : Real; V : Vec3) return Vec3
     with Global => null;

   function Clamp (X, Lo, Hi : Real) return Real
     with Pre    => Lo <= Hi,
          Post   => Clamp'Result >= Lo and then Clamp'Result <= Hi,
          Global => null;

   function Clamp_Half_Angle (A : Real) return Half_Angle_Rad
     with Global => null;

   function Distance_Between (A, B : Vec3) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- 1. Classic circular cone from eye / pixel (apex, axis, apex angle)
   ---------------------------------------------------------------------------

   function Construct_Circular_Cone
     (Eye            : Apex_Point;
      Pixel_Center   : Vec3;
      Pixel_Half_Ext : Positive_Real) return Cone
     with Pre    => Length (Pixel_Center - Eye) > 0.0,
          Post   => Length (Construct_Circular_Cone'Result.Axis) > 0.0,
          Global => null;
   --  Builds a circular cone whose apex is Eye, axis toward Pixel_Center,
   --  and half-angle from the pixel half-extent at the image plane distance.

   ---------------------------------------------------------------------------
   -- 2. Beam / pyramidal frustum through a pixel (four corner rays)
   ---------------------------------------------------------------------------

   function Construct_Pixel_Beam
     (Eye          : Apex_Point;
      Pixel_Origin : Vec3;          -- lower-left corner of pixel on plane
      Pixel_U      : Vec3;          -- width vector of pixel
      Pixel_V      : Vec3)          -- height vector of pixel
     return Beam_Frustum
     with Pre    => Length (Pixel_U) > 0.0 and then Length (Pixel_V) > 0.0,
          Global => null;

   function Beam_Half_Angles (B : Beam_Frustum) return Half_Angle_Rad
     with Global => null;
   --  Conservative circular half-angle enclosing the pyramidal beam.

   ---------------------------------------------------------------------------
   -- 3. Cone–sphere intersection (analytical)
   ---------------------------------------------------------------------------

   function Intersect_Cone_Sphere
     (C : Cone; S : Sphere) return Cone_Sphere_Hit
     with Pre    => Length (C.Axis) > 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- 4. Cone–plane and cone–AABB intersection helpers
   ---------------------------------------------------------------------------

   function Intersect_Cone_Plane
     (C : Cone; P : Plane) return Cone_Plane_Hit
     with Pre    => Length (C.Axis) > 0.0 and then Length (P.Normal) > 0.0,
          Global => null;

   function Cone_Overlaps_AABB (C : Cone; Box : AABB) return Boolean
     with Pre    => Length (C.Axis) > 0.0
                      and then Box.Min_P.X <= Box.Max_P.X
                      and then Box.Min_P.Y <= Box.Max_P.Y
                      and then Box.Min_P.Z <= Box.Max_P.Z,
          Global => null;

   ---------------------------------------------------------------------------
   -- 5. Soft-shadow / penumbra via cone aperture toward a light
   ---------------------------------------------------------------------------

   function Soft_Shadow_Cone
     (Hit           : Hit_Point;
      Light_Center  : Vec3;
      Light_Radius  : Non_Negative;
      Occluder_Dist : Non_Negative;
      Occluder_Size : Non_Negative) return Soft_Shadow_Result
     with Pre    => Length (Light_Center - Hit) > 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- 6. Glossy reflection cone expanded by roughness
   ---------------------------------------------------------------------------

   function Glossy_Reflection_Cone
     (Hit_Point_P : Hit_Point;
      Incident    : Axis_Direction;  -- toward surface (unit)
      Normal      : Axis_Direction;  -- unit surface normal
      Rough       : Roughness;
      Base_Angle  : Half_Angle_Rad := 0.0) return Cone
     with Pre    => Length (Incident) > 0.0 and then Length (Normal) > 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- 7. Footprint / LOD from cone radius at hit distance
   ---------------------------------------------------------------------------

   function Footprint_LOD
     (C              : Cone;
      Hit_Distance   : Positive_Real;
      Texel_World    : Positive_Real;
      Max_Mip        : LOD_Level := 16) return Footprint_Result
     with Pre    => Length (C.Axis) > 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- 8. Depth-of-field style cone (cross-section shrinks then expands)
   ---------------------------------------------------------------------------

   function Depth_Of_Field_Cone
     (Lens_Center    : Apex_Point;
      Lens_Radius    : Positive_Real;
      Focus_Distance : Positive_Real;
      View_Direction : Axis_Direction;
      Query_Distance : Non_Negative) return DoF_Cone_Result
     with Pre    => Length (View_Direction) > 0.0,
          Global => null;
   --  Models a lens cone whose radius decreases from Lens_Radius at the
   --  lens to ~0 at Focus_Distance, then increases beyond the focal plane.

   ---------------------------------------------------------------------------
   -- Convenience: cone radius at a given distance along the axis
   ---------------------------------------------------------------------------

   function Radius_At_Distance
     (C : Cone; Dist : Non_Negative) return Non_Negative
     with Global => null;

end Cone_Tracing;
