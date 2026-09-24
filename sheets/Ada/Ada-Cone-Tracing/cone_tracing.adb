--  Cone_Tracing body — algorithmic variants for educational cone tracing.

pragma Ada_2022;

with Ada.Numerics;                       use Ada.Numerics;
with Ada.Numerics.Elementary_Functions;  use Ada.Numerics.Elementary_Functions;

package body Cone_Tracing
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (Sqrt (Float (X)));
      end if;
   end Sqrt_Safe;

   function Atan2_Safe (Y, X : Real) return Real is
   begin
      return Real (Arctan (Float (Y), Float (X)));
   end Atan2_Safe;

   function Acos_Clamped (X : Real) return Real is
      C : constant Real := Clamp (X, -1.0, 1.0);
   begin
      return Real (Arccos (Float (C)));
   end Acos_Clamped;


   -------------------------------------------------------------------------
   -- Vector helpers
   -------------------------------------------------------------------------

   function Length (V : Vec3) return Non_Negative is
      S : constant Real := V.X * V.X + V.Y * V.Y + V.Z * V.Z;
   begin
      return Non_Negative (Sqrt_Safe (S));
   end Length;

   function Normalize (V : Vec3) return Axis_Direction is
      L : constant Non_Negative := Length (V);
   begin
      if L = 0.0 then
         raise Degenerate_Geometry with "Normalize of zero vector";
      end if;
      return (V.X / L, V.Y / L, V.Z / L);
   end Normalize;

   function Dot (A, B : Vec3) return Real is
   begin
      return A.X * B.X + A.Y * B.Y + A.Z * B.Z;
   end Dot;

   function Cross (A, B : Vec3) return Vec3 is
   begin
      return
        (A.Y * B.Z - A.Z * B.Y,
         A.Z * B.X - A.X * B.Z,
         A.X * B.Y - A.Y * B.X);
   end Cross;

   function "-" (A, B : Vec3) return Vec3 is
   begin
      return (A.X - B.X, A.Y - B.Y, A.Z - B.Z);
   end "-";

   function "+" (A, B : Vec3) return Vec3 is
   begin
      return (A.X + B.X, A.Y + B.Y, A.Z + B.Z);
   end "+";

   function "*" (S : Real; V : Vec3) return Vec3 is
   begin
      return (S * V.X, S * V.Y, S * V.Z);
   end "*";

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   function Clamp_Half_Angle (A : Real) return Half_Angle_Rad is
   begin
      return Half_Angle_Rad (Clamp (A, 0.0, Half_Angle_Rad'Last));
   end Clamp_Half_Angle;

   function Distance_Between (A, B : Vec3) return Non_Negative is
   begin
      return Length (A - B);
   end Distance_Between;

   function Radius_At_Distance
     (C : Cone; Dist : Non_Negative) return Non_Negative
   is
      T : constant Real := Real (Tan (Float (C.Half_Angle)));
   begin
      return Non_Negative (abs (Dist * T));
   end Radius_At_Distance;

   -------------------------------------------------------------------------
   -- 1. Circular cone from eye / pixel
   -------------------------------------------------------------------------

   function Construct_Circular_Cone
     (Eye            : Apex_Point;
      Pixel_Center   : Vec3;
      Pixel_Half_Ext : Positive_Real) return Cone
   is
      Offset : constant Vec3 := Pixel_Center - Eye;
      Dist   : constant Non_Negative := Length (Offset);
      Axis   : Axis_Direction;
      Angle  : Half_Angle_Rad;
   begin
      if Dist = 0.0 then
         raise Invalid_Input with "Pixel center coincides with eye";
      end if;
      Axis  := Normalize (Offset);
      --  half-angle = atan (pixel_half_extent / distance_to_plane)
      Angle := Clamp_Half_Angle (Atan2_Safe (Pixel_Half_Ext, Dist));
      return (Apex => Eye, Axis => Axis, Half_Angle => Angle);
   end Construct_Circular_Cone;

   -------------------------------------------------------------------------
   -- 2. Pyramidal beam through pixel corners
   -------------------------------------------------------------------------

   function Construct_Pixel_Beam
     (Eye          : Apex_Point;
      Pixel_Origin : Vec3;
      Pixel_U      : Vec3;
      Pixel_V      : Vec3) return Beam_Frustum
   is
      C0 : constant Vec3 := Pixel_Origin;
      C1 : constant Vec3 := Pixel_Origin + Pixel_U;
      C2 : constant Vec3 := Pixel_Origin + Pixel_U + Pixel_V;
      C3 : constant Vec3 := Pixel_Origin + Pixel_V;
      Result : Beam_Frustum;
   begin
      if Length (C0 - Eye) = 0.0
        or else Length (C1 - Eye) = 0.0
        or else Length (C2 - Eye) = 0.0
        or else Length (C3 - Eye) = 0.0
      then
         raise Degenerate_Geometry with "Pixel corner coincides with eye";
      end if;
      Result.Origin := Eye;
      Result.Corners (1) := Normalize (C0 - Eye);
      Result.Corners (2) := Normalize (C1 - Eye);
      Result.Corners (3) := Normalize (C2 - Eye);
      Result.Corners (4) := Normalize (C3 - Eye);
      return Result;
   end Construct_Pixel_Beam;

   function Beam_Half_Angles (B : Beam_Frustum) return Half_Angle_Rad is
      --  Axis = normalized average of corner directions; half-angle =
      --  max angle between axis and any corner.
      Sum  : Vec3 := (0.0, 0.0, 0.0);
      Axis : Axis_Direction;
      Max_A : Real := 0.0;
      Cos_A : Real;
   begin
      for I in Corner_Index loop
         Sum := Sum + B.Corners (I);
      end loop;
      if Length (Sum) = 0.0 then
         raise Degenerate_Geometry with "Beam corners cancel";
      end if;
      Axis := Normalize (Sum);
      for I in Corner_Index loop
         Cos_A := Clamp (Dot (Axis, B.Corners (I)), -1.0, 1.0);
         declare
            A : constant Real := Acos_Clamped (Cos_A);
         begin
            if A > Max_A then
               Max_A := A;
            end if;
         end;
      end loop;
      return Clamp_Half_Angle (Max_A);
   end Beam_Half_Angles;

   -------------------------------------------------------------------------
   -- 3. Cone–sphere intersection
   -------------------------------------------------------------------------

   function Intersect_Cone_Sphere
     (C : Cone; S : Sphere) return Cone_Sphere_Hit
   is
      --  Analytical test: angle between cone axis and vector to sphere
      --  center vs. cone half-angle expanded by asin(R / |OC|).
      OC     : constant Vec3 := S.Center - C.Apex;
      Dist   : constant Non_Negative := Length (OC);
      Result : Cone_Sphere_Hit :=
        (Intersects => False, Enter_Distance => 0.0,
         Exit_Distance => 0.0, Coverage => 0.0);
      Axis_U : Axis_Direction;
      Cos_Axis : Real;
      Ang_Axis : Real;
      Ang_Ext  : Real;
      Proj     : Real;
      Radial   : Real;
   begin
      if Dist = 0.0 then
         --  Apex inside / at sphere center: treat as full coverage
         Result.Intersects     := True;
         Result.Enter_Distance := 0.0;
         Result.Exit_Distance  := S.Radius;
         Result.Coverage       := 1.0;
         return Result;
      end if;

      Axis_U   := Normalize (C.Axis);
      Cos_Axis := Clamp (Dot (Axis_U, Normalize (OC)), -1.0, 1.0);
      Ang_Axis := Acos_Clamped (Cos_Axis);

      if Dist <= S.Radius then
         Ang_Ext := Half_Angle_Rad'Last;  -- apex inside sphere
      else
         Ang_Ext := Real (Arcsin (Float (Clamp (S.Radius / Dist, 0.0, 1.0))));
      end if;

      if Ang_Axis <= Real (C.Half_Angle) + Ang_Ext then
         Result.Intersects := True;
         Proj   := Dot (OC, Axis_U);
         Radial := Sqrt_Safe (Dist * Dist - Proj * Proj);
         --  Approximate enter/exit along axis using sphere slab
         declare
            Half_Chord : constant Real :=
              Sqrt_Safe (S.Radius * S.Radius
                         - (if Radial > S.Radius then S.Radius * S.Radius
                            else Radial * Radial));
            Enter : constant Real := Proj - Half_Chord;
            T_Exit : constant Real := Proj + Half_Chord;
         begin
            Result.Enter_Distance :=
              Non_Negative (if Enter > 0.0 then Enter else 0.0);
            Result.Exit_Distance  :=
              Non_Negative (if T_Exit > 0.0 then T_Exit else 0.0);
         end;
         --  Coverage proxy: how much of the cone aperture the sphere subtends
         declare
            Overlap : constant Real :=
              (Real (C.Half_Angle) + Ang_Ext - Ang_Axis)
              / (if Real (C.Half_Angle) + Ang_Ext > 0.0
                 then Real (C.Half_Angle) + Ang_Ext
                 else 1.0);
         begin
            Result.Coverage :=
              Unit_Interval (Clamp (Overlap, 0.0, 1.0));
         end;
      end if;
      return Result;
   end Intersect_Cone_Sphere;

   -------------------------------------------------------------------------
   -- 4. Cone–plane and cone–AABB
   -------------------------------------------------------------------------

   function Intersect_Cone_Plane
     (C : Cone; P : Plane) return Cone_Plane_Hit
   is
      N      : constant Axis_Direction := Normalize (P.Normal);
      Axis_U : constant Axis_Direction := Normalize (C.Axis);
      Denom  : constant Real := Dot (Axis_U, N);
      Result : Cone_Plane_Hit :=
        (Intersects => False, Distance => 0.0,
         Disk_Radius => 0.0, Center_Hit => (0.0, 0.0, 0.0));
      Numer  : Real;
      T      : Real;
   begin
      --  Nearly parallel: no reliable single hit
      if abs Denom < 1.0E-6 then
         return Result;
      end if;
      Numer := Dot (P.Point - C.Apex, N);
      T     := Numer / Denom;
      if T < 0.0 then
         return Result;  -- behind apex
      end if;
      Result.Intersects  := True;
      Result.Distance    := Non_Negative (T);
      Result.Center_Hit  := C.Apex + (T * Axis_U);
      Result.Disk_Radius := Radius_At_Distance (C, Result.Distance);
      return Result;
   end Intersect_Cone_Plane;

   function Cone_Overlaps_AABB (C : Cone; Box : AABB) return Boolean is
      --  Conservative test: distance from box to cone axis vs. cone radius
      --  at closest-point projection, plus sphere-at-corners fallback.
      Axis_U : constant Axis_Direction := Normalize (C.Axis);
      --  Closest point on AABB to apex
      Closest : Vec3;
      To_C    : Vec3;
      Proj    : Real;
      Radial  : Real;
      R_Cone  : Non_Negative;
      Margin  : constant Real := Length (Box.Max_P - Box.Min_P) * 0.5;
   begin
      Closest :=
        (Clamp (C.Apex.X, Box.Min_P.X, Box.Max_P.X),
         Clamp (C.Apex.Y, Box.Min_P.Y, Box.Max_P.Y),
         Clamp (C.Apex.Z, Box.Min_P.Z, Box.Max_P.Z));

      --  Apex inside box => overlap
      if Closest.X = C.Apex.X
        and then Closest.Y = C.Apex.Y
        and then Closest.Z = C.Apex.Z
        and then C.Apex.X >= Box.Min_P.X and then C.Apex.X <= Box.Max_P.X
        and then C.Apex.Y >= Box.Min_P.Y and then C.Apex.Y <= Box.Max_P.Y
        and then C.Apex.Z >= Box.Min_P.Z and then C.Apex.Z <= Box.Max_P.Z
      then
         return True;
      end if;

      --  Box center along axis
      declare
         Center : constant Vec3 :=
           (0.5 * (Box.Min_P.X + Box.Max_P.X),
            0.5 * (Box.Min_P.Y + Box.Max_P.Y),
            0.5 * (Box.Min_P.Z + Box.Max_P.Z));
      begin
         To_C   := Center - C.Apex;
         Proj   := Dot (To_C, Axis_U);
         if Proj < 0.0 then
            --  Box mostly behind apex: check near-apex overlap only
            return Length (Closest - C.Apex) <= Margin * 0.01
              or else Distance_Between (Closest, C.Apex) = 0.0;
         end if;
         Radial := Length (To_C - (Proj * Axis_U));
         R_Cone := Radius_At_Distance (C, Non_Negative (Proj));
         --  Expand cone radius by AABB half-diagonal for conservatism
         return Radial <= Real (R_Cone) + Margin;
      end;
   end Cone_Overlaps_AABB;

   -------------------------------------------------------------------------
   -- 5. Soft shadow / penumbra
   -------------------------------------------------------------------------

   function Soft_Shadow_Cone
     (Hit           : Hit_Point;
      Light_Center  : Vec3;
      Light_Radius  : Non_Negative;
      Occluder_Dist : Non_Negative;
      Occluder_Size : Non_Negative) return Soft_Shadow_Result
   is
      To_Light : constant Vec3 := Light_Center - Hit;
      Dist_L   : constant Non_Negative := Length (To_Light);
      Axis     : Axis_Direction;
      Light_A  : Half_Angle_Rad;
      Occ_A    : Half_Angle_Rad;
      Result   : Soft_Shadow_Result;
      Umbra    : Real;
   begin
      if Dist_L = 0.0 then
         raise Invalid_Input with "Light coincides with hit";
      end if;
      Axis := Normalize (To_Light);
      --  Angular radius of light as seen from hit
      if Dist_L <= Light_Radius then
         Light_A := Half_Angle_Rad'Last;
      else
         Light_A := Clamp_Half_Angle
           (Atan2_Safe (Light_Radius, Dist_L));
      end if;
      --  Angular size of occluder at given distance
      if Occluder_Dist <= 0.0 then
         Occ_A := 0.0;
      else
         Occ_A := Clamp_Half_Angle
           (Atan2_Safe (Occluder_Size, Occluder_Dist));
      end if;

      Result.Cone_Used :=
        (Apex => Hit, Axis => Axis, Half_Angle => Light_A);

      if Occ_A >= Light_A and then Light_A > 0.0 then
         Umbra := 0.0;  -- fully in umbra
      elsif Occ_A <= 0.0 or else Light_A = 0.0 then
         Umbra := 1.0;  -- no occluder or point light: fully lit / binary
         if Occ_A > 0.0 and then Light_A = 0.0 then
            Umbra := 0.0;
         end if;
      else
         --  Penumbra blend: lit fraction ~ 1 - occ_angle / light_angle
         Umbra := 1.0 - Real (Occ_A) / Real (Light_A);
         Umbra := Clamp (Umbra, 0.0, 1.0);
      end if;

      Result.Umbra_Factor   := Unit_Interval (Umbra);
      Result.Penumbra_Width :=
        Non_Negative (abs (Real (Light_A) - Real (Occ_A)));
      return Result;
   end Soft_Shadow_Cone;

   -------------------------------------------------------------------------
   -- 6. Glossy reflection cone
   -------------------------------------------------------------------------

   function Glossy_Reflection_Cone
     (Hit_Point_P : Hit_Point;
      Incident    : Axis_Direction;
      Normal      : Axis_Direction;
      Rough       : Roughness;
      Base_Angle  : Half_Angle_Rad := 0.0) return Cone
   is
      N : constant Axis_Direction := Normalize (Normal);
      I : constant Axis_Direction := Normalize (Incident);
      --  Reflect I about N: R = I - 2 (I·N) N   (I points toward surface)
      I_Dot_N : constant Real := Dot (I, N);
      R       : Vec3;
      Spread  : Half_Angle_Rad;
   begin
      R := I - ((2.0 * I_Dot_N) * N);
      if Length (R) = 0.0 then
         --  Degenerate grazing; fall back to normal
         R := N;
      else
         R := Vec3'(Normalize (R));
      end if;
      --  Expand aperture by roughness (linear map into half-angle)
      Spread := Clamp_Half_Angle
        (Real (Base_Angle) + Real (Rough) * (Pi / 2.0));
      return (Apex => Hit_Point_P, Axis => Axis_Direction (R),
              Half_Angle => Spread);
   end Glossy_Reflection_Cone;

   -------------------------------------------------------------------------
   -- 7. Footprint / LOD
   -------------------------------------------------------------------------

   function Footprint_LOD
     (C              : Cone;
      Hit_Distance   : Positive_Real;
      Texel_World    : Positive_Real;
      Max_Mip        : LOD_Level := 16) return Footprint_Result
   is
      Radius : constant Non_Negative :=
        Radius_At_Distance (C, Hit_Distance);
      Width  : Non_Negative;
      Ratio  : Real;
      Mip    : LOD_Level;
   begin
      Width := Radius;  -- filter width ~ footprint radius
      if Texel_World <= 0.0 then
         raise Invalid_Input with "Texel world size must be positive";
      end if;
      Ratio := Real (Width) / Real (Texel_World);
      if Ratio <= 1.0 then
         Mip := 0;
      else
         Mip := LOD_Level
           (Natural (Float'(Log (Float (Ratio), 2.0))));
         if Mip > Max_Mip then
            Mip := Max_Mip;
         end if;
      end if;
      return (Radius_At_Hit => Radius,
              Filter_Width  => Width,
              Mip_Level     => Mip);
   end Footprint_LOD;

   -------------------------------------------------------------------------
   -- 8. Depth-of-field cone
   -------------------------------------------------------------------------

   function Depth_Of_Field_Cone
     (Lens_Center    : Apex_Point;
      Lens_Radius    : Positive_Real;
      Focus_Distance : Positive_Real;
      View_Direction : Axis_Direction;
      Query_Distance : Non_Negative) return DoF_Cone_Result
   is
      Axis : constant Axis_Direction := Normalize (View_Direction);
      --  Cross-section radius: |1 - d/f| * Lens_Radius
      --  (zero at focus plane, Lens_Radius at the lens d=0)
      Scale : constant Real :=
        abs (1.0 - Real (Query_Distance) / Real (Focus_Distance));
      Cross : constant Non_Negative :=
        Non_Negative (Scale * Real (Lens_Radius));
      --  Equivalent half-angle from lens apex through cross-section at query
      Angle : Half_Angle_Rad;
      Cone_Out : Cone;
   begin
      if Query_Distance = 0.0 then
         Angle := 0.0;
      else
         Angle := Clamp_Half_Angle
           (Atan2_Safe (Cross, Query_Distance));
      end if;
      Cone_Out :=
        (Apex => Lens_Center, Axis => Axis, Half_Angle => Angle);
      return (Cone_At_Distance => Cone_Out,
              Cross_Section    => Cross,
              Focus_Distance   => Focus_Distance);
   end Depth_Of_Field_Cone;

end Cone_Tracing;
