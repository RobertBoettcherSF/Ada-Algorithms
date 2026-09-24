--  Beam_Tracing — Ada 2023 educational implementation of Heckbert & Hanrahan
--  beam tracing (pyramidal beams, clipping, reflection / refraction, acoustics,
--  backwards caustic beams). Based on Wikipedia "Beam tracing".

pragma Ada_2022;

package Beam_Tracing
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (never bare Float / Integer where domain types apply)
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Index_Of_Refraction is Real range 1.0 .. 10.0;
   subtype Sound_Speed is Positive_Real;  -- m/s

   type Vec3 is record
      X, Y, Z : Real := 0.0;
   end record;

   subtype Apex_Point     is Vec3;
   subtype Axis_Direction is Vec3;  -- intended unit length after Normalize
   subtype Hit_Point      is Vec3;
   subtype Plane_Normal   is Vec3;

   --  Polygonal beam cross-section: unbounded pyramid from Apex through
   --  unit Corner directions (Heckbert & Hanrahan style).
   Max_Corners : constant := 8;
   subtype Corner_Count is Natural range 0 .. Max_Corners;
   subtype Corner_Index is Positive range 1 .. Max_Corners;
   type Corner_Dirs is array (Corner_Index) of Axis_Direction;

   type Beam is record
      Apex    : Apex_Point;
      Corners : Corner_Dirs;
      Count   : Corner_Count := 0;
   end record;

   --  Planar polygon in world space (convex, for clipping / intersection).
   Max_Vertices : constant := 8;
   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;
   type Vertex_Array is array (Vertex_Index) of Vec3;

   type Polygon is record
      Vertices : Vertex_Array;
      Count    : Vertex_Count := 0;
   end record;

   type Plane is record
      Point  : Vec3;
      Normal : Plane_Normal;  -- unit normal
   end record;

   type AABB is record
      Min_P, Max_P : Vec3;
   end record;

   type Beam_Polygon_Hit is record
      Intersects     : Boolean := False;
      Distance       : Non_Negative := 0.0;
      Hit            : Hit_Point := (0.0, 0.0, 0.0);
      Coverage       : Unit_Interval := 0.0;  -- approx aperture coverage
   end record;

   type Beam_AABB_Hit is record
      Overlaps       : Boolean := False;
      Near_Distance  : Non_Negative := 0.0;
      Far_Distance   : Non_Negative := 0.0;
   end record;

   type Split_Result is record
      Visible   : Beam;  -- portion still open after occluder
      Occluded  : Beam;  -- portion blocked by occluder silhouette
      Has_Visible  : Boolean := False;
      Has_Occluded : Boolean := False;
   end record;

   type Acoustic_Result is record
      Path_Length   : Non_Negative;   -- metres along beam axis
      Delay_Seconds : Non_Negative;   -- Path_Length / Speed
      Attenuation   : Unit_Interval;  -- geometric spreading proxy in [0,1]
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Input       : exception;
   Degenerate_Geometry : exception;

   ---------------------------------------------------------------------------
   -- Shared vector / numeric helpers
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

   function Distance_Between (A, B : Vec3) return Non_Negative
     with Global => null;

   function Beam_Axis (B : Beam) return Axis_Direction
     with Pre    => B.Count >= 3,
          Global => null;
   --  Unit average of corner directions (pyramid axis).

   function Make_Rectangle
     (Origin, U, V : Vec3) return Polygon
     with Pre    => Length (U) > 0.0 and then Length (V) > 0.0,
          Post   => Make_Rectangle'Result.Count = 4,
          Global => null;

   function Polygon_Plane (P : Polygon) return Plane
     with Pre    => P.Count >= 3,
          Global => null;

   ---------------------------------------------------------------------------
   -- 1. Viewing beam through entire frustum / image plane
   ---------------------------------------------------------------------------

   function Construct_Viewing_Beam
     (Eye          : Apex_Point;
      Image_Origin : Vec3;   -- lower-left of image rectangle
      Image_U      : Vec3;   -- width vector
      Image_V      : Vec3)   -- height vector
     return Beam
     with Pre    => Length (Image_U) > 0.0 and then Length (Image_V) > 0.0,
          Post   => Construct_Viewing_Beam'Result.Count = 4,
          Global => null;
   --  Initial pyramidal beam through the full viewing frustum (Heckbert).

   ---------------------------------------------------------------------------
   -- 2. Per-pixel pyramidal beam (four corners)
   ---------------------------------------------------------------------------

   function Construct_Pixel_Beam
     (Eye          : Apex_Point;
      Pixel_Origin : Vec3;
      Pixel_U      : Vec3;
      Pixel_V      : Vec3) return Beam
     with Pre    => Length (Pixel_U) > 0.0 and then Length (Pixel_V) > 0.0,
          Post   => Construct_Pixel_Beam'Result.Count = 4,
          Global => null;

   ---------------------------------------------------------------------------
   -- 3. Clip / subtract polygonal aperture against a planar polygon
   ---------------------------------------------------------------------------

   function Beam_Clip_Against_Polygon
     (B : Beam; Poly : Polygon) return Beam
     with Pre    => B.Count >= 3 and then Poly.Count >= 3,
          Global => null;
   --  Intersect beam with Poly's plane and clip the cross-section to Poly
   --  (visibility / aperture update; Sutherland–Hodgman in the plane).

   function Subtract_Polygon_From_Beam
     (B : Beam; Poly : Polygon) return Beam
     with Pre    => B.Count >= 3 and then Poly.Count >= 3,
          Global => null;
   --  CSG-style: remove Poly's silhouette from the beam aperture when the
   --  polygon fully covers the projected beam; otherwise return B unchanged
   --  (educational proxy for nearest-to-furthest visibility queueing).

   ---------------------------------------------------------------------------
   -- 4. Reflect beam from a planar mirror
   ---------------------------------------------------------------------------

   function Reflect_Beam
     (B : Beam; Mirror : Plane) return Beam
     with Pre    => B.Count >= 3 and then Length (Mirror.Normal) > 0.0,
          Post   => Reflect_Beam'Result.Count = B.Count,
          Global => null;
   --  Planar image method: reflect apex through Mirror; keep corner dirs
   --  from the image apex through the clipped hit polygon on the plane.

   ---------------------------------------------------------------------------
   -- 5. Refract / transmit beam through a planar interface (Snell)
   ---------------------------------------------------------------------------

   function Refract_Beam
     (B          : Beam;
      Interface_P : Plane;
      N1, N2     : Index_Of_Refraction) return Beam
     with Pre    => B.Count >= 3 and then Length (Interface_P.Normal) > 0.0,
          Global => null;
   --  Refracts each corner direction with Snell's law; new apex at the
   --  axis–plane hit. Raises Degenerate_Geometry on total internal reflection.

   ---------------------------------------------------------------------------
   -- 6. Scene queries: polygon and AABB
   ---------------------------------------------------------------------------

   function Beam_Intersect_Polygon
     (B : Beam; Poly : Polygon) return Beam_Polygon_Hit
     with Pre    => B.Count >= 3 and then Poly.Count >= 3,
          Global => null;

   function Beam_Intersect_AABB
     (B : Beam; Box : AABB) return Beam_AABB_Hit
     with Pre    => B.Count >= 3
                      and then Box.Min_P.X <= Box.Max_P.X
                      and then Box.Min_P.Y <= Box.Max_P.Y
                      and then Box.Min_P.Z <= Box.Max_P.Z,
          Global => null;

   ---------------------------------------------------------------------------
   -- 7. Sub-beam split for partial occlusion
   ---------------------------------------------------------------------------

   function Split_Beam_By_Occluder
     (B : Beam; Occluder : Polygon) return Split_Result
     with Pre    => B.Count >= 3 and then Occluder.Count >= 3,
          Global => null;
   --  If the occluder covers the beam axis hit, Occluded gets the clipped
   --  beam through the occluder and Visible is empty; if it misses, Visible
   --  keeps B. Partial coverage yields both a clipped occluded sub-beam and
   --  the original as a conservative visible remainder.

   ---------------------------------------------------------------------------
   -- 8. Acoustics: path length, delay, geometric spreading
   ---------------------------------------------------------------------------

   function Acoustic_Path_Attenuation
     (B              : Beam;
      Receiver       : Vec3;
      Speed          : Sound_Speed;
      Ref_Distance   : Positive_Real := 1.0) return Acoustic_Result
     with Pre    => B.Count >= 3,
          Global => null;
   --  Path length along apex→receiver; delay = length/speed; attenuation
   --  ≈ Ref_Distance / max(length, Ref_Distance) (inverse-distance spreading).

   function Propagation_Delay
     (Path_Length : Non_Negative; Speed : Sound_Speed) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- 9. Backwards beam from light toward a caustic receiver plane
   ---------------------------------------------------------------------------

   function Backwards_Beam_From_Light
     (Light           : Apex_Point;
      Receiver_Origin : Vec3;
      Receiver_U      : Vec3;
      Receiver_V      : Vec3) return Beam
     with Pre    => Length (Receiver_U) > 0.0
                      and then Length (Receiver_V) > 0.0,
          Post   => Backwards_Beam_From_Light'Result.Count = 4,
          Global => null;
   --  Watt-style backwards beam: pyramid from light through a receiver
   --  rectangle (caustic gather region).

end Beam_Tracing;
