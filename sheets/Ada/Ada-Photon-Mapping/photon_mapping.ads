package Photon_Mapping with SPARK_Mode => On is

   type Real is new Long_Float;

   type Vector_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   type Spectral_Power is record
      R : Real := 0.0;
      G : Real := 0.0;
      B : Real := 0.0;
   end record;

   type Ray is record
      Origin    : Vector_3D;
      Direction : Vector_3D;
   end record;

   type Surface_Interaction is (Diffuse, Specular, Absorbed);
   type Map_Kind is (Global_Map, Caustic_Map, Volume_Map);

   type Photon is record
      Position  : Vector_3D;
      Power     : Spectral_Power;
      Incident  : Vector_3D;
      Plane     : Natural range 0 .. 2 := 0;
   end record;

   type Photon_Array is array (Positive range <>) of Photon;

   type Kd_Tree (Capacity : Natural) is record
      Photons : Photon_Array (1 .. Capacity);
      Length  : Natural := 0;
   end record;

   type Filter_Kind is (Constant_Filter, Linear_Filter, Gaussian_Filter);

   type Surface_Material is record
      Diffuse_Reflectance  : Real := 0.0;
      Specular_Reflectance : Real := 0.0;
      Absorption           : Real := 1.0;
   end record;

   type Sphere is record
      Center   : Vector_3D;
      Radius   : Real;
      Material : Surface_Material;
   end record;

   type Medium_Properties is record
      Scattering_Coeff : Real := 0.0;
      Absorption_Coeff : Real := 0.0;
   end record;

   type Distance_Array is array (Positive range <>) of Real;

   type Query_Result (Max_Results : Natural) is record
      Photons         : Photon_Array (1 .. Max_Results);
      Distances_Sq    : Distance_Array (1 .. Max_Results) := [others => 0.0];
      Count           : Natural := 0;
      Max_Distance_Sq : Real    := 0.0;
   end record;

   Invalid_Geometry_Error : exception;
   Invalid_Capacity_Error : exception;
   Zero_Photons_Error     : exception;

   function Dot (A, B : Vector_3D) return Real;
   function Norm_Sq (V : Vector_3D) return Real;
   function Norm (V : Vector_3D) return Real;
   function Normalize (V : Vector_3D) return Vector_3D
     with Pre => Norm_Sq (V) > 0.0;

   function Vector_Add (A, B : Vector_3D) return Vector_3D;
   function Vector_Sub (A, B : Vector_3D) return Vector_3D;
   function Vector_Scale (V : Vector_3D; S : Real) return Vector_3D;
   function Distance_Sq (A, B : Vector_3D) return Real;

   function Spectral_Add (A, B : Spectral_Power) return Spectral_Power;
   function Spectral_Scale (S : Spectral_Power; Factor : Real) return Spectral_Power;

   function Intersect_Sphere
     (R : Ray; S : Sphere; Hit_Point : out Vector_3D; Normal : out Vector_3D) return Boolean
     with Pre => S.Radius > 0.0;

   function Russian_Roulette
     (Mat : Surface_Material; Random_Val : Real) return Surface_Interaction
     with Pre => Random_Val >= 0.0 and then Random_Val <= 1.0;

   function Trace_Photon_Path
     (Initial_Ray : Ray;
      Power       : Spectral_Power;
      Scene_Obj   : Sphere;
      Random_Val  : Real) return Photon
     with Pre => Scene_Obj.Radius > 0.0 and then Random_Val >= 0.0 and then Random_Val <= 1.0;

   procedure Build_Kd_Tree
     (Tree : in out Kd_Tree)
     with Pre => Tree.Length <= Tree.Capacity;

   procedure Locate_Photons
     (Tree        : Kd_Tree;
      Center      : Vector_3D;
      Max_Count   : Positive;
      Max_Dist_Sq : Real;
      Result      : out Query_Result)
     with Pre => Max_Dist_Sq > 0.0 and then Tree.Length <= Tree.Capacity;

   function Estimate_Radiance_Surface
     (Tree        : Kd_Tree;
      Point       : Vector_3D;
      Normal      : Vector_3D;
      Max_Photons : Positive;
      Max_Dist_Sq : Real;
      Filter      : Filter_Kind) return Spectral_Power
     with Pre => Max_Dist_Sq > 0.0 and then Norm_Sq (Normal) > 0.0;

   function Estimate_Radiance_Volume
     (Tree        : Kd_Tree;
      Point       : Vector_3D;
      Medium      : Medium_Properties;
      Max_Photons : Positive;
      Max_Dist_Sq : Real) return Spectral_Power
     with Pre => Max_Dist_Sq > 0.0;

   function Combine_Two_Pass
     (Direct_Light     : Spectral_Power;
      Specular_Light   : Spectral_Power;
      Caustic_Estimate : Spectral_Power;
      Global_Estimate  : Spectral_Power) return Spectral_Power;

end Photon_Mapping;
