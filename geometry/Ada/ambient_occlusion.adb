--  Ambient_Occlusion body — algorithmic variants for educational AO.

pragma Ada_2022;

with Ada.Numerics;                       use Ada.Numerics;
with Ada.Numerics.Elementary_Functions;  use Ada.Numerics.Elementary_Functions;

package body Ambient_Occlusion
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

   function Sin_F (X : Real) return Real is
   begin
      return Real (Sin (Float (X)));
   end Sin_F;

   function Cos_F (X : Real) return Real is
   begin
      return Real (Cos (Float (X)));
   end Cos_F;

   function Atan2_Safe (Y, X : Real) return Real is
   begin
      return Real (Arctan (Float (Y), Float (X)));
   end Atan2_Safe;

   Pi_F : constant Real := Real (Pi);

   -------------------------------------------------------------------------
   -- Vector helpers
   -------------------------------------------------------------------------

   function Length (V : Vec3) return Non_Negative is
      S : constant Real := V.X * V.X + V.Y * V.Y + V.Z * V.Z;
   begin
      return Non_Negative (Sqrt_Safe (S));
   end Length;

   function Normalize (V : Vec3) return Direction3 is
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

   function Clamp_Unit (X : Real) return Unit_Interval is
   begin
      return Unit_Interval (Clamp (X, 0.0, 1.0));
   end Clamp_Unit;

   function Distance_Between (A, B : Vec3) return Non_Negative is
   begin
      return Length (A - B);
   end Distance_Between;

   procedure Orthonormal_Basis
     (N          : Normal3;
      Tangent    : out Direction3;
      Bitangent  : out Direction3)
   is
      Nn : constant Direction3 := Normalize (N);
      A  : Vec3;
   begin
      --  Pick an axis least aligned with N to avoid degeneracy.
      if abs (Nn.X) < 0.9 then
         A := (1.0, 0.0, 0.0);
      else
         A := (0.0, 1.0, 0.0);
      end if;
      Tangent   := Normalize (Cross (A, Nn));
      Bitangent := Cross (Nn, Tangent);
   end Orthonormal_Basis;

   function Local_To_World
     (Local : Direction3; N, T, B : Direction3) return Direction3
   is
   begin
      return Normalize
        ((Local.X * T.X + Local.Y * B.X + Local.Z * N.X,
          Local.X * T.Y + Local.Y * B.Y + Local.Z * N.Y,
          Local.X * T.Z + Local.Y * B.Z + Local.Z * N.Z));
   end Local_To_World;

   -------------------------------------------------------------------------
   -- Fixed hemisphere samples (local +Z = normal)
   -------------------------------------------------------------------------

   function Fixed_Hemisphere_Samples
     (Count : Hemi_Sample_Count) return Direction_Array
   is
      Result : Direction_Array := [others => (0.0, 0.0, 1.0)];
      --  Fibonacci-ish spiral on the hemisphere for even coverage.
      Golden : constant Real := Pi_F * (3.0 - Sqrt_Safe (5.0));
   begin
      for I in 1 .. Count loop
         declare
            Fi    : constant Real := Real (I - 1);
            Z     : constant Real :=
              1.0 - (Fi + 0.5) / Real (Count);  -- (0,1]
            R_XY  : constant Real := Sqrt_Safe (1.0 - Z * Z);
            Phi   : constant Real := Fi * Golden;
            X     : constant Real := Cos_F (Phi) * R_XY;
            Y     : constant Real := Sin_F (Phi) * R_XY;
            L     : Non_Negative;
         begin
            Result (I) := (X, Y, Z);
            L := Length (Result (I));
            if L > 0.0 then
               Result (I) := (Result (I).X / L,
                              Result (I).Y / L,
                              Result (I).Z / L);
            else
               Result (I) := (0.0, 0.0, 1.0);
            end if;
         end;
      end loop;
      return Result;
   end Fixed_Hemisphere_Samples;

   -------------------------------------------------------------------------
   -- Scene helpers & ray intersection
   -------------------------------------------------------------------------

   function Empty_Scene return Scene is
      S : Scene;
   begin
      S.Sphere_Count := 0;
      S.Plane_Count  := 0;
      S.Box_Count    := 0;
      return S;
   end Empty_Scene;

   function Add_Sphere (Scn : Scene; S : Sphere) return Scene is
      R : Scene := Scn;
   begin
      R.Sphere_Count := R.Sphere_Count + 1;
      R.Spheres (R.Sphere_Count) := S;
      return R;
   end Add_Sphere;

   function Add_Plane (Scn : Scene; P : Plane) return Scene is
      R : Scene := Scn;
   begin
      R.Plane_Count := R.Plane_Count + 1;
      R.Planes (R.Plane_Count) := P;
      return R;
   end Add_Plane;

   function Add_AABB (Scn : Scene; Box : AABB) return Scene is
      R : Scene := Scn;
   begin
      R.Box_Count := R.Box_Count + 1;
      R.Boxes (R.Box_Count) := Box;
      return R;
   end Add_AABB;

   function Ray_Sphere_T
     (Origin : Point3; Dir : Direction3; S : Sphere) return Real
   is
      --  Smallest positive t, or -1 on miss.
      OC : constant Vec3 := Origin - S.Center;
      B  : constant Real := 2.0 * Dot (OC, Dir);
      C  : constant Real := Dot (OC, OC) - S.Radius * S.Radius;
      Disc : constant Real := B * B - 4.0 * C;
      T0, T1, Sq : Real;
   begin
      if Disc < 0.0 then
         return -1.0;
      end if;
      Sq := Sqrt_Safe (Disc);
      T0 := (-B - Sq) * 0.5;
      T1 := (-B + Sq) * 0.5;
      if T0 > 1.0E-4 then
         return T0;
      elsif T1 > 1.0E-4 then
         return T1;
      else
         return -1.0;
      end if;
   end Ray_Sphere_T;

   function Ray_Plane_T
     (Origin : Point3; Dir : Direction3; P : Plane) return Real
   is
      Den : constant Real := Dot (Dir, P.Normal);
      Num : Real;
   begin
      if abs (Den) < 1.0E-6 then
         return -1.0;
      end if;
      Num := Dot (P.Point - Origin, P.Normal);
      declare
         T : constant Real := Num / Den;
      begin
         if T > 1.0E-4 then
            return T;
         else
            return -1.0;
         end if;
      end;
   end Ray_Plane_T;

   function Ray_AABB_T
     (Origin : Point3; Dir : Direction3; Box : AABB) return Real
   is
      T_Min : Real := 0.0;
      T_Max : Real := Real'Last;

      procedure Slab (O, D, B_Min, B_Max : Real) is
         Inv, T1, T2, Lo, Hi : Real;
      begin
         if abs (D) < 1.0E-8 then
            if O < B_Min or else O > B_Max then
               T_Min := Real'Last;
               T_Max := -Real'Last;
            end if;
         else
            Inv := 1.0 / D;
            T1  := (B_Min - O) * Inv;
            T2  := (B_Max - O) * Inv;
            if T1 < T2 then
               Lo := T1;
               Hi := T2;
            else
               Lo := T2;
               Hi := T1;
            end if;
            if Lo > T_Min then
               T_Min := Lo;
            end if;
            if Hi < T_Max then
               T_Max := Hi;
            end if;
         end if;
      end Slab;
   begin
      Slab (Origin.X, Dir.X, Box.Min_P.X, Box.Max_P.X);
      Slab (Origin.Y, Dir.Y, Box.Min_P.Y, Box.Max_P.Y);
      Slab (Origin.Z, Dir.Z, Box.Min_P.Z, Box.Max_P.Z);
      if T_Max >= T_Min and then T_Max > 1.0E-4 then
         if T_Min > 1.0E-4 then
            return T_Min;
         else
            return T_Max;  -- origin inside: exit distance
         end if;
      else
         return -1.0;
      end if;
   end Ray_AABB_T;

   function Ray_Hit_Distance
     (Origin   : Point3;
      Dir      : Direction3;
      Scn      : Scene;
      Max_Dist : Positive_Real) return Non_Negative
   is
      Best : Real := -1.0;
      T    : Real;
      D    : constant Direction3 := Normalize (Dir);
   begin
      for I in 1 .. Scn.Sphere_Count loop
         T := Ray_Sphere_T (Origin, D, Scn.Spheres (I));
         if T > 0.0 and then T <= Max_Dist
           and then (Best < 0.0 or else T < Best)
         then
            Best := T;
         end if;
      end loop;
      for I in 1 .. Scn.Plane_Count loop
         T := Ray_Plane_T (Origin, D, Scn.Planes (I));
         if T > 0.0 and then T <= Max_Dist
           and then (Best < 0.0 or else T < Best)
         then
            Best := T;
         end if;
      end loop;
      for I in 1 .. Scn.Box_Count loop
         T := Ray_AABB_T (Origin, D, Scn.Boxes (I));
         if T > 0.0 and then T <= Max_Dist
           and then (Best < 0.0 or else T < Best)
         then
            Best := T;
         end if;
      end loop;
      if Best < 0.0 then
         return 0.0;
      else
         return Non_Negative (Best);
      end if;
   end Ray_Hit_Distance;

   -------------------------------------------------------------------------
   -- Shared hemisphere sampling AO core
   -------------------------------------------------------------------------

   function Sample_Hemisphere_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Radius    : Positive_Real;
      Samples   : Hemi_Sample_Count;
      Cos_Weight : Boolean) return AO_Result
   is
      Nn      : constant Direction3 := Normalize (N);
      T, B    : Direction3;
      Locals  : constant Direction_Array := Fixed_Hemisphere_Samples (Samples);
      Acc     : Real := 0.0;
      W_Sum   : Real := 0.0;
      Hits    : Natural := 0;
      Bent_Acc : Vec3 := (0.0, 0.0, 0.0);
      Origin  : constant Point3 := P + (1.0E-3 * Nn);  -- bias off surface
      R       : AO_Result;
   begin
      Orthonormal_Basis (Nn, T, B);
      for I in 1 .. Samples loop
         declare
            World : constant Direction3 :=
              Local_To_World (Locals (I), Nn, T, B);
            W     : Real := 1.0;
            Hit_T : Non_Negative;
            Vis   : Real;
         begin
            if Cos_Weight then
               W := Clamp (Dot (World, Nn), 0.0, 1.0);
            end if;
            Hit_T := Ray_Hit_Distance (Origin, World, Scn, Radius);
            if Hit_T > 0.0 then
               --  Soft falloff: closer hits occlude more.
               Vis := Clamp (Hit_T / Radius, 0.0, 1.0);
               Hits := Hits + 1;
            else
               Vis := 1.0;
               Bent_Acc := Bent_Acc + World;
            end if;
            Acc   := Acc + Vis * W;
            W_Sum := W_Sum + W;
         end;
      end loop;
      if W_Sum <= 0.0 then
         R.Factor := 1.0;
      else
         R.Factor := Clamp_Unit (Acc / W_Sum);
      end if;
      R.Sample_Hits := Hits;
      if Length (Bent_Acc) > 0.0 then
         R.Bent_Normal := Normalize (Bent_Acc);
      else
         R.Bent_Normal := Nn;
      end if;
      return R;
   end Sample_Hemisphere_AO;

   -------------------------------------------------------------------------
   -- 1. Hemisphere / Monte Carlo AO
   -------------------------------------------------------------------------

   function Hemisphere_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Radius    : Positive_Real;
      Samples   : Hemi_Sample_Count := 16) return AO_Result
   is
   begin
      return Sample_Hemisphere_AO (P, N, Scn, Radius, Samples, True);
   end Hemisphere_AO;

   function MonteCarlo_Hemisphere_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Radius    : Positive_Real;
      Samples   : Hemi_Sample_Count := 16) return AO_Result
   is
   begin
      --  Same deterministic sampler; name mirrors Wikipedia Monte Carlo AO.
      return Sample_Hemisphere_AO (P, N, Scn, Radius, Samples, True);
   end MonteCarlo_Hemisphere_AO;

   -------------------------------------------------------------------------
   -- 2. Sky visibility
   -------------------------------------------------------------------------

   function Sky_Visibility_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Radius    : Positive_Real;
      Samples   : Hemi_Sample_Count := 16) return AO_Factor
   is
      Nn     : constant Direction3 := Normalize (N);
      T, B   : Direction3;
      Locals : constant Direction_Array := Fixed_Hemisphere_Samples (Samples);
      Open_C : Natural := 0;
      Origin : constant Point3 := P + (1.0E-3 * Nn);
   begin
      Orthonormal_Basis (Nn, T, B);
      for I in 1 .. Samples loop
         declare
            World : constant Direction3 :=
              Local_To_World (Locals (I), Nn, T, B);
         begin
            if Ray_Hit_Distance (Origin, World, Scn, Radius) = 0.0 then
               Open_C := Open_C + 1;
            end if;
         end;
      end loop;
      return Clamp_Unit (Real (Open_C) / Real (Samples));
   end Sky_Visibility_AO;

   -------------------------------------------------------------------------
   -- 3. Accessibility shading
   -------------------------------------------------------------------------

   function Accessibility_Shading
     (P            : Point3;
      N            : Normal3;
      Scn          : Scene;
      Probe_Radius : Positive_Real;
      Probes       : Hemi_Sample_Count := 12) return Accessibility_Result
   is
      Nn     : constant Direction3 := Normalize (N);
      T, B   : Direction3;
      Locals : constant Direction_Array := Fixed_Hemisphere_Samples (Probes);
      Origin : constant Point3 := P + (1.0E-3 * Nn);
      Clear  : Non_Negative := Probe_Radius;
      Acc    : Real := 0.0;
      R      : Accessibility_Result;
   begin
      Orthonormal_Basis (Nn, T, B);
      for I in 1 .. Probes loop
         declare
            World : constant Direction3 :=
              Local_To_World (Locals (I), Nn, T, B);
            Hit_T : constant Non_Negative :=
              Ray_Hit_Distance (Origin, World, Scn, Probe_Radius);
            Reach : Non_Negative;
         begin
            if Hit_T = 0.0 then
               Reach := Probe_Radius;
            else
               Reach := Hit_T;
               if Hit_T < Clear then
                  Clear := Hit_T;
               end if;
            end if;
            Acc := Acc + Real (Reach) / Real (Probe_Radius);
         end;
      end loop;
      R.Factor       := Clamp_Unit (Acc / Real (Probes));
      R.Reach_Radius := Clear;
      return R;
   end Accessibility_Shading;

   -------------------------------------------------------------------------
   -- 4. Screen-space AO
   -------------------------------------------------------------------------

   function Screen_Space_AO_Sample
     (Center_Depth : Positive_Real;
      Depths       : Depth_Array;
      Offsets      : Offset_Array;
      Count        : Depth_Sample_Count;
      Radius_Px    : Positive_Real;
      Intensity    : Positive_Real := 1.0;
      Bias         : Non_Negative := 0.01) return AO_Factor
   is
      Occ : Real := 0.0;
      W_S : Real := 0.0;
   begin
      for I in 1 .. Count loop
         declare
            Ox   : constant Real := Offsets (I).X;
            Oy   : constant Real := Offsets (I).Y;
            Dist : constant Real := Sqrt_Safe (Ox * Ox + Oy * Oy);
            Range_Check : Real;
            Diff : Real;
         begin
            if Dist <= Radius_Px and then Dist > 0.0 then
               Range_Check := 1.0 - Dist / Radius_Px;
               Diff := Center_Depth - Depths (I);
               --  Sample in front of center (smaller depth) => occluder.
               if Diff > Bias then
                  Occ := Occ + (Diff / (Center_Depth + 1.0E-4))
                           * Range_Check * Intensity;
               end if;
               W_S := W_S + Range_Check;
            end if;
         end;
      end loop;
      if W_S <= 0.0 then
         return 1.0;
      end if;
      return Clamp_Unit (1.0 - Occ / W_S);
   end Screen_Space_AO_Sample;

   -------------------------------------------------------------------------
   -- 5. Horizon-based AO
   -------------------------------------------------------------------------

   function Horizon_Based_AO
     (Heights_Per_Dir : Height_Array;
      Steps_Per_Dir   : Horizon_Step_Count;
      Dir_Count       : Sample_Count;
      Step_Length     : Positive_Real) return Horizon_AO_Result
   is
      --  Educational HBAO: one shared height profile applied to Dir_Count
      --  azimuths (tests supply a representative radial height walk).
      Acc_AO   : Real := 0.0;
      Acc_H    : Real := 0.0;
      Max_Ang  : Real;
      R        : Horizon_AO_Result;
   begin
      for D in 1 .. Dir_Count loop
         Max_Ang := 0.0;
         for S in 1 .. Steps_Per_Dir loop
            declare
               Dist : constant Real := Real (S) * Step_Length;
               H    : constant Real := Heights_Per_Dir (S);
               Ang  : Real;
            begin
               if Dist > 0.0 then
                  Ang := Atan2_Safe (H, Dist);
                  if Ang > Max_Ang then
                     Max_Ang := Ang;
                  end if;
               end if;
            end;
         end loop;
         --  Occlusion grows with horizon elevation; sin^2 style falloff.
         Acc_AO := Acc_AO + (1.0 - Sin_F (Max_Ang) * Sin_F (Max_Ang));
         Acc_H  := Acc_H + Max_Ang;
      end loop;
      R.Factor := Clamp_Unit (Acc_AO / Real (Dir_Count));
      R.Mean_Horizon := Angle_Rad
        (Clamp (Acc_H / Real (Dir_Count), 0.0, Angle_Rad'Last));
      R.Direction_Count := Natural (Dir_Count);
      return R;
   end Horizon_Based_AO;

   -------------------------------------------------------------------------
   -- 6. Ground-truth AO integral (GTAO-inspired)
   -------------------------------------------------------------------------

   function Ground_Truth_AO_Integral
     (Horizon_Angles : Height_Array;
      Dir_Count      : Horizon_Step_Count;
      Normal_Angle   : Angle_Rad := 0.0) return AO_Factor
   is
      --  Approximate (1/pi) * integral V * cos(theta) over the horizon.
      --  Per direction: integrate from -h to +h with cos weighting relative
      --  to the surface normal tilt Normal_Angle.
      Acc : Real := 0.0;
   begin
      for I in 1 .. Dir_Count loop
         declare
            H   : constant Real :=
              Clamp (Horizon_Angles (I), 0.0, Pi_F * 0.5);
            --  Analytical slice: sin(h) * cos(n) contribution proxy.
            Slice : constant Real :=
              Sin_F (H) * Cos_F (Normal_Angle) +
              (1.0 - Cos_F (H)) * 0.5;
            Vis : constant Real := 1.0 - Clamp (Slice, 0.0, 1.0);
         begin
            Acc := Acc + Vis;
         end;
      end loop;
      return Clamp_Unit (Acc / Real (Dir_Count));
   end Ground_Truth_AO_Integral;

   -------------------------------------------------------------------------
   -- 7. Ray-traced AO
   -------------------------------------------------------------------------

   function Ray_Traced_AO
     (P         : Point3;
      N         : Normal3;
      Scn       : Scene;
      Max_Dist  : Positive_Real;
      Samples   : Hemi_Sample_Count := 16) return AO_Result
   is
      Nn     : constant Direction3 := Normalize (N);
      T, B   : Direction3;
      Locals : constant Direction_Array := Fixed_Hemisphere_Samples (Samples);
      Origin : constant Point3 := P + (1.0E-3 * Nn);
      Open_C : Natural := 0;
      Hits   : Natural := 0;
      Bent   : Vec3 := (0.0, 0.0, 0.0);
      R      : AO_Result;
   begin
      Orthonormal_Basis (Nn, T, B);
      for I in 1 .. Samples loop
         declare
            World : constant Direction3 :=
              Local_To_World (Locals (I), Nn, T, B);
         begin
            if Ray_Hit_Distance (Origin, World, Scn, Max_Dist) = 0.0 then
               Open_C := Open_C + 1;
               Bent   := Bent + World;
            else
               Hits := Hits + 1;
            end if;
         end;
      end loop;
      R.Factor := Clamp_Unit (Real (Open_C) / Real (Samples));
      R.Sample_Hits := Hits;
      if Length (Bent) > 0.0 then
         R.Bent_Normal := Normalize (Bent);
      else
         R.Bent_Normal := Nn;
      end if;
      return R;
   end Ray_Traced_AO;

   -------------------------------------------------------------------------
   -- 8. Tube / corner intuition helpers
   -------------------------------------------------------------------------

   function Tube_Occlusion_Demo
     (Depth_Into_Tube : Non_Negative;
      Tube_Radius     : Positive_Real;
      Max_Depth       : Positive_Real) return AO_Factor
   is
      --  Solid-angle proxy: sky visible from depth D inside a tube of radius R
      --  shrinks roughly as R / sqrt(R^2 + D^2); also fade by Max_Depth.
      D     : constant Real := Depth_Into_Tube;
      R     : constant Real := Tube_Radius;
      Sky   : Real;
      Depth_Fade : Real;
   begin
      Sky := R / Sqrt_Safe (R * R + D * D);
      Depth_Fade := 1.0 - Clamp (D / Max_Depth, 0.0, 1.0);
      return Clamp_Unit (Sky * (0.5 + 0.5 * Depth_Fade));
   end Tube_Occlusion_Demo;

   function Corner_Darkening
     (Angle_Between_Walls : Angle_Rad;
      Distance_To_Corner  : Non_Negative;
      Influence_Radius    : Positive_Real) return AO_Factor
   is
      --  Inner corner (small angle) + proximity => more occlusion.
      --  Open flat (pi) => little darkening.
      Openness : constant Real :=
        Clamp (Angle_Between_Walls / Pi_F, 0.0, 1.0);
      Prox     : constant Real :=
        Clamp (Distance_To_Corner / Influence_Radius, 0.0, 1.0);
      --  Blend: far from corner => ~1; tight corner nearby => darker.
      Factor   : constant Real :=
        Openness * 0.5 + Prox * 0.5 + Openness * Prox * 0.5;
   begin
      return Clamp_Unit (Factor);
   end Corner_Darkening;

end Ambient_Occlusion;
