--  Ambient_Occlusion — Ada 2023 educational implementation of ambient
--  occlusion variants (hemisphere / Monte Carlo, sky visibility, accessibility,
--  SSAO, HBAO, GTAO-style integral, RTAO, tube / corner demos).
--  Based on Wikipedia "Ambient occlusion" and classic CG literature.

pragma Ada_2022;

package Ambient_Occlusion
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (never bare Float / Integer where domain types apply)
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   --  AO factor: 1 = fully exposed (bright), 0 = fully occluded (dark)
   subtype AO_Factor is Unit_Interval;
   subtype Angle_Rad is Real range 0.0 .. 3.141_593;  -- [0, pi]
   subtype Sample_Count is Positive range 1 .. 256;

   type Vec3 is record
      X, Y, Z : Real := 0.0;
   end record;

   subtype Point3        is Vec3;
   subtype Normal3       is Vec3;  -- intended unit length after Normalize
   subtype Direction3    is Vec3;  -- intended unit length after Normalize

   type Sphere is record
      Center : Point3;
      Radius : Non_Negative;
   end record;

   type Plane is record
      Point  : Point3;
      Normal : Normal3;  -- unit normal
   end record;

   type AABB is record
      Min_P, Max_P : Point3;
   end record;

   --  Small fixed scene of proxy occluders (educational fixtures).
   Max_Spheres : constant := 8;
   Max_Planes  : constant := 4;
   Max_AABBs   : constant := 4;

   subtype Sphere_Counts is Natural range 0 .. Max_Spheres;
   subtype Plane_Counts  is Natural range 0 .. Max_Planes;
   subtype AABB_Counts   is Natural range 0 .. Max_AABBs;
   subtype Sphere_Index is Positive range 1 .. Max_Spheres;
   subtype Plane_Index  is Positive range 1 .. Max_Planes;
   subtype AABB_Index   is Positive range 1 .. Max_AABBs;

   type Sphere_Array is array (Sphere_Index) of Sphere;
   type Plane_Array  is array (Plane_Index)  of Plane;
   type AABB_Array   is array (AABB_Index)   of AABB;

   type Scene is record
      Spheres       : Sphere_Array;
      Sphere_Count  : Sphere_Counts := 0;
      Planes        : Plane_Array;
      Plane_Count   : Plane_Counts := 0;
      Boxes         : AABB_Array;
      Box_Count     : AABB_Counts := 0;
   end record;

   --  Fixed hemisphere sample set (deterministic directions in local +Z).
   Max_Hemisphere_Samples : constant := 32;
   subtype Hemi_Sample_Count is Sample_Count range 1 .. Max_Hemisphere_Samples;
   subtype Hemi_Sample_Index is Positive range 1 .. Max_Hemisphere_Samples;
   type Direction_Array is array (Hemi_Sample_Index) of Direction3;

   --  Depth neighborhood for screen-space AO (no GPU; pure math).
   Max_Depth_Samples : constant := 16;
   subtype Depth_Sample_Count is Sample_Count range 1 .. Max_Depth_Samples;
   subtype Depth_Sample_Index is Positive range 1 .. Max_Depth_Samples;
   type Depth_Array is array (Depth_Sample_Index) of Non_Negative;
   --  Offset in pixel / UV space (X,Y) paired with a depth sample.
   type Offset2 is record
      X, Y : Real := 0.0;
   end record;
   type Offset_Array is array (Depth_Sample_Index) of Offset2;

   --  Horizon samples for one azimuthal direction (HBAO / GTAO).
   Max_Horizon_Steps : constant := 16;
   subtype Horizon_Step_Count is Sample_Count range 1 .. Max_Horizon_Steps;
   subtype Horizon_Step_Index is Positive range 1 .. Max_Horizon_Steps;
   type Height_Array is array (Horizon_Step_Index) of Real;
   --  Signed height relative to the shaded point; distance along ray in steps.

   type AO_Result is record
      Factor       : AO_Factor;       -- unoccluded fraction [0,1]
      Bent_Normal  : Normal3;         -- average unoccluded direction (approx)
      Sample_Hits  : Natural := 0;    -- how many samples were occluded
   end record;

   type Accessibility_Result is record
      Factor       : AO_Factor;       -- high = reachable / clean
      Reach_Radius : Non_Negative;    -- largest clear radius proxy
   end record;

   type Horizon_AO_Result is record
      Factor         : AO_Factor;
      Mean_Horizon   : Angle_Rad;     -- average horizon elevation
      Direction_Count : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Input       : exception;
   Degenerate_Geometry : exception;

   ---------------------------------------------------------------------------
   -- Shared vector / numeric helpers (public for tests & reuse)
   ---------------------------------------------------------------------------

   function Length (V : Vec3) return Non_Negative
     with Global => null;

   function Normalize (V : Vec3) return Direction3
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

   function Clamp_Unit (X : Real) return Unit_Interval
     with Post   => Clamp_Unit'Result >= 0.0
                      and then Clamp_Unit'Result <= 1.0,
          Global => null;

   function Distance_Between (A, B : Vec3) return Non_Negative
     with Global => null;

   --  Orthonormal tangent frame from a unit normal (N = Z of local frame).
   procedure Orthonormal_Basis
     (N          : Normal3;
      Tangent    : out Direction3;
      Bitangent  : out Direction3)
     with Pre    => Length (N) > 0.0,
          Global => null;

   --  Map a local (+Z up) direction into world space given N, T, B.
   function Local_To_World
     (Local : Direction3; N, T, B : Direction3) return Direction3
     with Global => null;

   --  Deterministic cosine-weighted-ish hemisphere directions in local +Z.
   function Fixed_Hemisphere_Samples
     (Count : Hemi_Sample_Count) return Direction_Array
     with Post   => (for all I in 1 .. Count =>
                       Length (Fixed_Hemisphere_Samples'Result (I)) > 0.0),
          Global => null;

   --  Ray vs scene proxies: first hit distance, or 0 if none within Max_Dist.
   function Ray_Hit_Distance
     (Origin   : Point3;
      Dir      : Direction3;
      Scn      : Scene;
      Max_Dist : Positive_Real) return Non_Negative
     with Pre    => Length (Dir) > 0.0,
          Global => null;
   --  Returns 0.0 on miss; positive distance on hit within Max_Dist.

   function Empty_Scene return Scene
     with Global => null;

   function Add_Sphere (Scn : Scene; S : Sphere) return Scene
     with Pre    => Scn.Sphere_Count < Max_Spheres,
          Global => null;

   function Add_Plane (Scn : Scene; P : Plane) return Scene
     with Pre    => Scn.Plane_Count < Max_Planes,
          Global => null;

   function Add_AABB (Scn : Scene; Box : AABB) return Scene
     with Pre    => Scn.Box_Count < Max_AABBs
                      and then Box.Min_P.X <= Box.Max_P.X
                      and then Box.Min_P.Y <= Box.Max_P.Y
                      and then Box.Min_P.Z <= Box.Max_P.Z,
          Global => null;

   ---------------------------------------------------------------------------
   -- 1. Hemisphere / Monte Carlo AO (cosine-weighted discrete samples)
   ---------------------------------------------------------------------------

   function Hemisphere_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Radius    : Positive_Real;
      Samples   : Hemi_Sample_Count := 16) return AO_Result
     with Pre    => Length (N) > 0.0,
          Post   => Hemisphere_AO'Result.Factor >= 0.0
                      and then Hemisphere_AO'Result.Factor <= 1.0,
          Global => null;
   --  Alias: Monte Carlo style with fixed (deterministic) hemisphere samples.

   function MonteCarlo_Hemisphere_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Radius    : Positive_Real;
      Samples   : Hemi_Sample_Count := 16) return AO_Result
     with Pre    => Length (N) > 0.0,
          Post   => MonteCarlo_Hemisphere_AO'Result.Factor >= 0.0
                      and then MonteCarlo_Hemisphere_AO'Result.Factor <= 1.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- 2. Sky visibility AO (open-sky fraction of the upper hemisphere)
   ---------------------------------------------------------------------------

   function Sky_Visibility_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Radius    : Positive_Real;
      Samples   : Hemi_Sample_Count := 16) return AO_Factor
     with Pre    => Length (N) > 0.0,
          Post   => Sky_Visibility_AO'Result >= 0.0
                      and then Sky_Visibility_AO'Result <= 1.0,
          Global => null;
   --  Fraction of hemisphere samples that see open sky (no hit within Radius).

   ---------------------------------------------------------------------------
   -- 3. Accessibility shading (dirt / reachability factor)
   ---------------------------------------------------------------------------

   function Accessibility_Shading
     (P            : Point3;
      N            : Normal3;
      Scn          : Scene;
      Probe_Radius : Positive_Real;
      Probes       : Hemi_Sample_Count := 12) return Accessibility_Result
     with Pre    => Length (N) > 0.0,
          Post   => Accessibility_Shading'Result.Factor >= 0.0
                      and then Accessibility_Shading'Result.Factor <= 1.0,
          Global => null;
   --  How "reachable" the point is (Miller-style accessibility proxy).

   ---------------------------------------------------------------------------
   -- 4. Screen-space AO sample (SSAO-style on a depth neighborhood)
   ---------------------------------------------------------------------------

   function Screen_Space_AO_Sample
     (Center_Depth : Positive_Real;
      Depths       : Depth_Array;
      Offsets      : Offset_Array;
      Count        : Depth_Sample_Count;
      Radius_Px    : Positive_Real;
      Intensity    : Positive_Real := 1.0;
      Bias         : Non_Negative := 0.01) return AO_Factor
     with Pre    => Count >= 1,
          Post   => Screen_Space_AO_Sample'Result >= 0.0
                      and then Screen_Space_AO_Sample'Result <= 1.0,
          Global => null;
   --  Classic SSAO: nearby depths closer than expected => occlusion.

   ---------------------------------------------------------------------------
   -- 5. Horizon-based AO (HBAO-style)
   ---------------------------------------------------------------------------

   function Horizon_Based_AO
     (Heights_Per_Dir : Height_Array;
      Steps_Per_Dir   : Horizon_Step_Count;
      Dir_Count       : Sample_Count;
      Step_Length     : Positive_Real) return Horizon_AO_Result
     with Pre    => Steps_Per_Dir >= 1 and then Dir_Count >= 1,
          Post   => Horizon_Based_AO'Result.Factor >= 0.0
                      and then Horizon_Based_AO'Result.Factor <= 1.0,
          Global => null;
   --  For each azimuth, find max horizon angle from height samples; integrate.

   ---------------------------------------------------------------------------
   -- 6. Ground-truth AO integral (GTAO-inspired analytical form)
   ---------------------------------------------------------------------------

   function Ground_Truth_AO_Integral
     (Horizon_Angles : Height_Array;
      --  Reused as list of horizon elevation angles (radians) per direction.
      Dir_Count      : Horizon_Step_Count;
      Normal_Angle   : Angle_Rad := 0.0) return AO_Factor
     with Pre    => Dir_Count >= 1,
          Post   => Ground_Truth_AO_Integral'Result >= 0.0
                      and then Ground_Truth_AO_Integral'Result <= 1.0,
          Global => null;
   --  Integrates cos-weighted visibility over horizon angles (GTAO-like).

   ---------------------------------------------------------------------------
   -- 7. Ray-traced AO (RTAO-style binary hit average)
   ---------------------------------------------------------------------------

   function Ray_Traced_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Max_Dist  : Positive_Real;
      Samples   : Hemi_Sample_Count := 16) return AO_Result
     with Pre    => Length (N) > 0.0,
          Post   => Ray_Traced_AO'Result.Factor >= 0.0
                      and then Ray_Traced_AO'Result.Factor <= 1.0,
          Global => null;
   --  Cast N hemisphere rays; binary hit within Max_Dist; average unoccluded.

   ---------------------------------------------------------------------------
   -- 8. Classic intuition demos: tube interior & corner darkening
   ---------------------------------------------------------------------------

   function Tube_Occlusion_Demo
     (Depth_Into_Tube : Non_Negative;
      Tube_Radius     : Positive_Real;
      Max_Depth       : Positive_Real) return AO_Factor
     with Pre    => Max_Depth > 0.0,
          Post   => Tube_Occlusion_Demo'Result >= 0.0
                      and then Tube_Occlusion_Demo'Result <= 1.0,
          Global => null;
   --  Deeper inside a tube => darker (classic AO intuition).

   function Corner_Darkening
     (Angle_Between_Walls : Angle_Rad;
      Distance_To_Corner  : Non_Negative;
      Influence_Radius    : Positive_Real) return AO_Factor
     with Pre    => Influence_Radius > 0.0,
          Post   => Corner_Darkening'Result >= 0.0
                      and then Corner_Darkening'Result <= 1.0,
          Global => null;
   --  Tighter / closer corners darken more (inner angles of corners).

end Ambient_Occlusion;
