--  Global_Illumination — Ada 2023 educational GI layer: direct vs indirect
--  lighting, one-bounce color bleeding, radiosity form factors / gather,
--  path-throughput accumulator, caustic proxy, rendering-equation sample,
--  and ambient-vs-GI contrast. Based on Wikipedia "Global illumination".
--  Complements dedicated radiosity / path-tracing / AO / photon-mapping repos
--  with composable educational variants rather than full sibling reimplementations.

pragma Ada_2022;

package Global_Illumination
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (never bare Float / Integer where domain types apply)
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Radiance is Non_Negative;
   subtype Reflectance is Unit_Interval;
   subtype Sample_Count is Positive range 1 .. 64;

   type Vec3 is record
      X, Y, Z : Real := 0.0;
   end record;

   subtype Point3     is Vec3;
   subtype Normal3    is Vec3;  -- intended unit length after Normalize
   subtype Direction3 is Vec3;  -- intended unit length after Normalize

   --  RGB color / radiance / irradiance channels (educational linear RGB).
   type Color_RGB is record
      R, G, B : Non_Negative := 0.0;
   end record;

   --  Diffuse planar patch (radiosity / inter-reflection fixture).
   type Patch is record
      Center      : Point3;
      Normal      : Normal3;
      Area        : Positive_Real := 1.0;
      Reflectance : Color_RGB := (0.5, 0.5, 0.5);
      Emission    : Color_RGB := (0.0, 0.0, 0.0);  -- Le (self-emitted)
      Radiosity   : Color_RGB := (0.0, 0.0, 0.0);  -- B (gathered)
   end record;

   Max_Patches : constant := 16;
   subtype Patch_Counts is Natural range 0 .. Max_Patches;
   subtype Patch_Index  is Positive range 1 .. Max_Patches;
   type Patch_Array is array (Patch_Index) of Patch;

   type Patch_Set is record
      Patches : Patch_Array;
      Count   : Patch_Counts := 0;
   end record;

   --  Point or directional light (directional uses infinite Distance proxy).
   type Light_Kind is (Point_Light, Directional_Light);

   type Light is record
      Kind      : Light_Kind := Point_Light;
      Position  : Point3 := (0.0, 0.0, 0.0);     -- for Point_Light
      Direction : Direction3 := (0.0, -1.0, 0.0); -- toward scene, Directional
      Intensity : Color_RGB := (1.0, 1.0, 1.0);
   end record;

   --  Simple occluder sphere for hard-shadow tests.
   type Occluder is record
      Center : Point3;
      Radius : Non_Negative := 0.0;
   end record;

   Max_Occluders : constant := 8;
   subtype Occluder_Counts is Natural range 0 .. Max_Occluders;
   subtype Occluder_Index  is Positive range 1 .. Max_Occluders;
   type Occluder_Array is array (Occluder_Index) of Occluder;

   type Occluder_Set is record
      Items : Occluder_Array;
      Count : Occluder_Counts := 0;
   end record;

   --  Discrete hemisphere / path samples for RE and path throughput.
   Max_Dirs : constant := 32;
   subtype Dir_Count is Sample_Count range 1 .. Max_Dirs;
   subtype Dir_Index is Positive range 1 .. Max_Dirs;
   type Direction_Array is array (Dir_Index) of Direction3;
   type Radiance_Array  is array (Dir_Index) of Color_RGB;
   type PDF_Array       is array (Dir_Index) of Positive_Real;
   type BRDF_Array      is array (Dir_Index) of Non_Negative;

   --  Fixed path of bounce directions (path-tracing style without MC).
   Max_Bounces : constant := 8;
   subtype Bounce_Count is Sample_Count range 1 .. Max_Bounces;
   subtype Bounce_Index is Positive range 1 .. Max_Bounces;
   type Bounce_Dirs is array (Bounce_Index) of Direction3;
   type Bounce_BRDFs is array (Bounce_Index) of Non_Negative;
   type Bounce_PDFs  is array (Bounce_Index) of Positive_Real;
   type Bounce_Cos   is array (Bounce_Index) of Unit_Interval;

   type Direct_Result is record
      Radiance_Out : Color_RGB;
      Cos_Term     : Unit_Interval := 0.0;
      Shadowed     : Boolean := False;
   end record;

   type Bounce_Result is record
      Indirect     : Color_RGB;
      Form_Factor  : Unit_Interval := 0.0;
      Visible      : Boolean := True;
   end record;

   type Gather_Result is record
      Radiosity    : Color_RGB;
      Incoming_Sum : Color_RGB;
      Neighbor_N   : Natural := 0;
   end record;

   type Throughput_Result is record
      Throughput   : Color_RGB;       -- product along path
      Path_Length  : Natural := 0;
      Survived     : Boolean := True;
   end record;

   type Caustic_Result is record
      Density_Est  : Color_RGB;
      Photon_Count : Natural := 0;
      Kernel_Radius : Non_Negative := 0.0;
   end record;

   type RE_Sample_Result is record
      Lo           : Color_RGB;       -- outgoing radiance approx
      Sample_Sum   : Color_RGB;
      Used         : Natural := 0;
   end record;

   type Ambient_Vs_GI_Result is record
      Ambient_Only : Color_RGB;
      With_GI      : Color_RGB;
      Indirect     : Color_RGB;
      Delta_Luma   : Non_Negative := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Input       : exception;
   Degenerate_Geometry : exception;

   ---------------------------------------------------------------------------
   -- Shared vector / color / numeric helpers (public for tests & reuse)
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

   function Color_Add (A, B : Color_RGB) return Color_RGB
     with Global => null;

   function Color_Scale (S : Real; C : Color_RGB) return Color_RGB
     with Global => null;

   function Color_Mul (A, B : Color_RGB) return Color_RGB
     with Global => null;

   function Luminance (C : Color_RGB) return Non_Negative
     with Global => null;

   function Empty_Patch_Set return Patch_Set
     with Global => null;

   function Add_Patch (Set : Patch_Set; P : Patch) return Patch_Set
     with Pre    => Set.Count < Max_Patches,
          Global => null;

   function Empty_Occluders return Occluder_Set
     with Global => null;

   function Add_Occluder (Set : Occluder_Set; O : Occluder) return Occluder_Set
     with Pre    => Set.Count < Max_Occluders,
          Global => null;

   --  Hard shadow: True if segment from A to B intersects an occluder sphere.
   function Segment_Occluded
     (A, B : Point3; Occ : Occluder_Set) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- 1. Direct_Illumination — Lambertian response to a light + optional shadow
   ---------------------------------------------------------------------------

   function Direct_Illumination
     (P           : Point3;
      N           : Normal3;
      Albedo      : Color_RGB;
      Lgt         : Light;
      Occ         : Occluder_Set := (others => <>);
      Use_Shadows : Boolean := False) return Direct_Result
     with Pre    => Length (N) > 0.0,
          Global => null;
   --  Lo = (albedo/π) * Intensity * max(0, N·L) * V; V from occluder test.

   ---------------------------------------------------------------------------
   -- 2. Indirect_Bounce / One_Bounce_GI — single diffuse bounce color bleeding
   ---------------------------------------------------------------------------

   function Indirect_Bounce
     (Receiver : Patch;
      Emitter  : Patch) return Bounce_Result
     with Pre    => Length (Receiver.Normal) > 0.0
                      and then Length (Emitter.Normal) > 0.0
                      and then Receiver.Area > 0.0
                      and then Emitter.Area > 0.0,
          Global => null;
   --  One-bounce diffuse transfer: ρ_r / π * B_e * F_re * Area terms.

   function One_Bounce_GI
     (Receiver : Patch;
      Emitters : Patch_Set) return Bounce_Result
     with Pre    => Length (Receiver.Normal) > 0.0
                      and then Receiver.Area > 0.0
                      and then Emitters.Count >= 1,
          Global => null;
   --  Sum Indirect_Bounce over all emitter patches.

   ---------------------------------------------------------------------------
   -- 3. Radiosity_Form_Factor — Nusselt / differential-area form factor
   ---------------------------------------------------------------------------

   function Radiosity_Form_Factor
     (I, J : Patch) return Unit_Interval
     with Pre    => Length (I.Normal) > 0.0
                      and then Length (J.Normal) > 0.0
                      and then I.Area > 0.0
                      and then J.Area > 0.0,
          Post   => Radiosity_Form_Factor'Result >= 0.0
                      and then Radiosity_Form_Factor'Result <= 1.0,
          Global => null;
   --  F_ij ≈ (cos θ_i cos θ_j / (π r²)) * A_j, clamped to [0,1].

   ---------------------------------------------------------------------------
   -- 4. Radiosity_Gather — gather radiosity from neighbors
   ---------------------------------------------------------------------------

   function Radiosity_Gather
     (Receiver  : Patch;
      Neighbors : Patch_Set) return Gather_Result
     with Pre    => Length (Receiver.Normal) > 0.0
                      and then Receiver.Area > 0.0,
          Global => null;
   --  B_i = E_i + ρ_i * Σ F_ij B_j  (one Jacobi gather step).

   ---------------------------------------------------------------------------
   -- 5. Path_Throughput_Bounce — BRDF*cos/pdf product along a fixed path
   ---------------------------------------------------------------------------

   function Path_Throughput_Bounce
     (Initial    : Color_RGB;
      Dirs       : Bounce_Dirs;
      BRDFs      : Bounce_BRDFs;
      Cosines    : Bounce_Cos;
      PDFs       : Bounce_PDFs;
      Count      : Bounce_Count) return Throughput_Result
     with Pre    => Count >= 1,
          Global => null;
   --  T *= (f_r * cos θ / pdf) at each bounce; educational PT accumulator.

   ---------------------------------------------------------------------------
   -- 6. Color_Bleeding — tinted irradiance from colored emitter onto receiver
   ---------------------------------------------------------------------------

   function Color_Bleeding
     (Receiver : Patch;
      Emitter  : Patch;
      Strength : Unit_Interval := 1.0) return Color_RGB
     with Pre    => Length (Receiver.Normal) > 0.0
                      and then Length (Emitter.Normal) > 0.0,
          Global => null;
   --  Transfers Emitter radiosity/emission tint through form factor * ρ_r.

   ---------------------------------------------------------------------------
   -- 7. Caustic_Proxy — photon-map style density estimate at a receiver
   ---------------------------------------------------------------------------

   function Caustic_Proxy
     (Receiver       : Point3;
      Photon_Hits    : Direction_Array;  -- hit positions stored as Vec3
      Photon_Power   : Radiance_Array;
      Count          : Dir_Count;
      Kernel_Radius  : Positive_Real;
      Specular_Boost : Positive_Real := 1.0) return Caustic_Result
     with Pre    => Count >= 1 and then Kernel_Radius > 0.0,
          Global => null;
   --  Educational density estimate: sum powers in ball / (π r²).

   ---------------------------------------------------------------------------
   -- 8. Rendering_Equation_Sample — discrete hemisphere integral for one point
   ---------------------------------------------------------------------------

   function Rendering_Equation_Sample
     (Le       : Color_RGB;
      N        : Normal3;
      Dirs     : Direction_Array;
      Li       : Radiance_Array;
      BRDF_Val : BRDF_Array;
      PDFs     : PDF_Array;
      Count    : Dir_Count) return RE_Sample_Result
     with Pre    => Length (N) > 0.0 and then Count >= 1,
          Global => null;
   --  Lo ≈ Le + Σ (f_r * Li * cos θ / pdf)  (discrete RE sample sum).

   ---------------------------------------------------------------------------
   -- 9. Ambient_Term_Vs_GI — crude constant ambient vs computed indirect
   ---------------------------------------------------------------------------

   function Ambient_Term_Vs_GI
     (Albedo         : Color_RGB;
      Ambient_Color  : Color_RGB;
      Direct         : Color_RGB;
      Indirect       : Color_RGB) return Ambient_Vs_GI_Result
     with Global => null;
   --  Ambient_Only = Direct + Albedo*Ambient; With_GI = Direct + Indirect.

end Global_Illumination;
