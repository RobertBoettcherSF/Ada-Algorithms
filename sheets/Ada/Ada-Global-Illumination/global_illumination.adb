--  Global_Illumination body — educational GI-layer algorithmic variants.

pragma Ada_2022;

with Ada.Numerics;                       use Ada.Numerics;
with Ada.Numerics.Elementary_Functions;  use Ada.Numerics.Elementary_Functions;

package body Global_Illumination
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

   -------------------------------------------------------------------------
   -- Color helpers
   -------------------------------------------------------------------------

   function Color_Add (A, B : Color_RGB) return Color_RGB is
   begin
      return (A.R + B.R, A.G + B.G, A.B + B.B);
   end Color_Add;

   function Color_Scale (S : Real; C : Color_RGB) return Color_RGB is
      function Ch (X : Non_Negative) return Non_Negative is
         V : constant Real := S * Real (X);
      begin
         if V <= 0.0 then
            return 0.0;
         else
            return Non_Negative (V);
         end if;
      end Ch;
   begin
      return (Ch (C.R), Ch (C.G), Ch (C.B));
   end Color_Scale;

   function Color_Mul (A, B : Color_RGB) return Color_RGB is
   begin
      return (A.R * B.R, A.G * B.G, A.B * B.B);
   end Color_Mul;

   function Luminance (C : Color_RGB) return Non_Negative is
   begin
      --  Rec. 709 luma coefficients.
      return Non_Negative (0.2126 * C.R + 0.7152 * C.G + 0.0722 * C.B);
   end Luminance;

   -------------------------------------------------------------------------
   -- Patch / occluder builders
   -------------------------------------------------------------------------

   function Empty_Patch_Set return Patch_Set is
      R : Patch_Set;
   begin
      R.Count := 0;
      return R;
   end Empty_Patch_Set;

   function Add_Patch (Set : Patch_Set; P : Patch) return Patch_Set is
      R : Patch_Set := Set;
   begin
      if R.Count = Max_Patches then
         raise Invalid_Input with "Patch_Set full";
      end if;
      R.Count := R.Count + 1;
      R.Patches (R.Count) := P;
      return R;
   end Add_Patch;

   function Empty_Occluders return Occluder_Set is
      R : Occluder_Set;
   begin
      R.Count := 0;
      return R;
   end Empty_Occluders;

   function Add_Occluder (Set : Occluder_Set; O : Occluder) return Occluder_Set is
      R : Occluder_Set := Set;
   begin
      if R.Count = Max_Occluders then
         raise Invalid_Input with "Occluder_Set full";
      end if;
      R.Count := R.Count + 1;
      R.Items (R.Count) := O;
      return R;
   end Add_Occluder;

   --  Ray-sphere: does segment A->B intersect sphere (center, radius)?
   function Segment_Hits_Sphere
     (A, B : Point3; Center : Point3; Radius : Non_Negative) return Boolean
   is
      AB  : constant Vec3 := B - A;
      AC  : constant Vec3 := Center - A;
      Len2 : constant Real := Dot (AB, AB);
      T    : Real;
      Closest : Vec3;
      Dist2   : Real;
   begin
      if Radius <= 0.0 then
         return False;
      end if;
      if Len2 <= 0.0 then
         return Distance_Between (A, Center) <= Radius;
      end if;
      T := Dot (AC, AB) / Len2;
      T := Clamp (T, 0.0, 1.0);
      Closest := A + (T * AB);
      Dist2 := Dot (Closest - Center, Closest - Center);
      return Dist2 <= Radius * Radius;
   end Segment_Hits_Sphere;

   function Segment_Occluded
     (A, B : Point3; Occ : Occluder_Set) return Boolean
   is
   begin
      for I in 1 .. Occ.Count loop
         if Segment_Hits_Sphere
           (A, B, Occ.Items (I).Center, Occ.Items (I).Radius)
         then
            return True;
         end if;
      end loop;
      return False;
   end Segment_Occluded;

   -------------------------------------------------------------------------
   -- 1. Direct_Illumination
   -------------------------------------------------------------------------

   function Direct_Illumination
     (P           : Point3;
      N           : Normal3;
      Albedo      : Color_RGB;
      Lgt         : Light;
      Occ         : Occluder_Set := (others => <>);
      Use_Shadows : Boolean := False) return Direct_Result
   is
      Nn     : constant Direction3 := Normalize (N);
      L_Dir  : Direction3;
      Cos_T  : Real;
      Inv_Pi : constant Real := 1.0 / Pi_F;
      Vis    : Boolean := True;
      Light_P : Point3;
      Result  : Direct_Result;
   begin
      case Lgt.Kind is
         when Point_Light =>
            declare
               To_L : constant Vec3 := Lgt.Position - P;
               Dist : constant Non_Negative := Length (To_L);
            begin
               if Dist = 0.0 then
                  raise Degenerate_Geometry with "Light coincides with point";
               end if;
               L_Dir := Normalize (To_L);
               Light_P := Lgt.Position;
               --  Inverse-square attenuation (educational).
               Cos_T := Dot (Nn, L_Dir);
               if Cos_T <= 0.0 then
                  Result.Radiance_Out := (0.0, 0.0, 0.0);
                  Result.Cos_Term := 0.0;
                  Result.Shadowed := False;
                  return Result;
               end if;
               if Use_Shadows then
                  Vis := not Segment_Occluded (P, Light_P, Occ);
               end if;
               if not Vis then
                  Result.Radiance_Out := (0.0, 0.0, 0.0);
                  Result.Cos_Term := Clamp_Unit (Cos_T);
                  Result.Shadowed := True;
                  return Result;
               end if;
               declare
                  Att : constant Real := 1.0 / (Dist * Dist);
                  Scale : constant Real := Inv_Pi * Cos_T * Att;
               begin
                  Result.Radiance_Out := Color_Mul
                    (Albedo, Color_Scale (Scale, Lgt.Intensity));
                  Result.Cos_Term := Clamp_Unit (Cos_T);
                  Result.Shadowed := False;
               end;
            end;

         when Directional_Light =>
            --  Direction points toward the scene (from light); reverse for L.
            if Length (Lgt.Direction) = 0.0 then
               raise Degenerate_Geometry with "Zero light direction";
            end if;
            L_Dir := Normalize ((-1.0) * Lgt.Direction);
            Cos_T := Dot (Nn, L_Dir);
            if Cos_T <= 0.0 then
               Result.Radiance_Out := (0.0, 0.0, 0.0);
               Result.Cos_Term := 0.0;
               Result.Shadowed := False;
               return Result;
            end if;
            if Use_Shadows then
               --  Trace far along light direction reverse (toward light).
               Light_P := P + (1000.0 * L_Dir);
               Vis := not Segment_Occluded (P, Light_P, Occ);
            end if;
            if not Vis then
               Result.Radiance_Out := (0.0, 0.0, 0.0);
               Result.Cos_Term := Clamp_Unit (Cos_T);
               Result.Shadowed := True;
               return Result;
            end if;
            declare
               Scale : constant Real := Inv_Pi * Cos_T;
            begin
               Result.Radiance_Out := Color_Mul
                 (Albedo, Color_Scale (Scale, Lgt.Intensity));
               Result.Cos_Term := Clamp_Unit (Cos_T);
               Result.Shadowed := False;
            end;
      end case;
      return Result;
   end Direct_Illumination;

   -------------------------------------------------------------------------
   -- 3. Radiosity_Form_Factor (used by bounce / gather)
   -------------------------------------------------------------------------

   function Radiosity_Form_Factor
     (I, J : Patch) return Unit_Interval
   is
      Ni : constant Direction3 := Normalize (I.Normal);
      Nj : constant Direction3 := Normalize (J.Normal);
      R_Vec : constant Vec3 := J.Center - I.Center;
      Dist  : constant Non_Negative := Length (R_Vec);
      R_Hat : Direction3;
      Cos_I, Cos_J : Real;
      FF : Real;
   begin
      if Dist < 1.0E-5 then
         return 0.0;  -- coincident / self; F_ii = 0 for planar
      end if;
      R_Hat := Normalize (R_Vec);
      Cos_I := Dot (Ni, R_Hat);
      Cos_J := Dot (Nj, (-1.0) * R_Hat);
      if Cos_I <= 0.0 or else Cos_J <= 0.0 then
         return 0.0;  -- back-facing
      end if;
      --  Differential-area / Nusselt analog: F_ij ≈ cos_i cos_j A_j / (π r²)
      FF := (Cos_I * Cos_J * Real (J.Area)) / (Pi_F * Dist * Dist);
      return Clamp_Unit (FF);
   end Radiosity_Form_Factor;

   -------------------------------------------------------------------------
   -- 2. Indirect_Bounce / One_Bounce_GI
   -------------------------------------------------------------------------

   function Indirect_Bounce
     (Receiver : Patch;
      Emitter  : Patch) return Bounce_Result
   is
      FF   : constant Unit_Interval := Radiosity_Form_Factor (Receiver, Emitter);
      --  Source radiosity: prefer stored Radiosity, else Emission.
      Src  : Color_RGB;
      Result : Bounce_Result;
      Visible : constant Boolean := FF > 0.0;
   begin
      if Luminance (Emitter.Radiosity) > 0.0 then
         Src := Emitter.Radiosity;
      else
         Src := Emitter.Emission;
      end if;
      --  Indirect ≈ ρ_r * Src * F; FF already embeds differential-area 1/π.
      Result.Form_Factor := FF;
      Result.Visible := Visible;
      if not Visible then
         Result.Indirect := (0.0, 0.0, 0.0);
      else
         Result.Indirect := Color_Mul
           (Receiver.Reflectance, Color_Scale (Real (FF), Src));
      end if;
      return Result;
   end Indirect_Bounce;

   function One_Bounce_GI
     (Receiver : Patch;
      Emitters : Patch_Set) return Bounce_Result
   is
      Acc : Color_RGB := (0.0, 0.0, 0.0);
      Max_FF : Unit_Interval := 0.0;
      Any_Vis : Boolean := False;
      Br : Bounce_Result;
      Result : Bounce_Result;
   begin
      for K in 1 .. Emitters.Count loop
         Br := Indirect_Bounce (Receiver, Emitters.Patches (K));
         Acc := Color_Add (Acc, Br.Indirect);
         if Br.Form_Factor > Max_FF then
            Max_FF := Br.Form_Factor;
         end if;
         if Br.Visible then
            Any_Vis := True;
         end if;
      end loop;
      Result.Indirect := Acc;
      Result.Form_Factor := Max_FF;
      Result.Visible := Any_Vis;
      return Result;
   end One_Bounce_GI;

   -------------------------------------------------------------------------
   -- 4. Radiosity_Gather
   -------------------------------------------------------------------------

   function Radiosity_Gather
     (Receiver  : Patch;
      Neighbors : Patch_Set) return Gather_Result
   is
      Incoming : Color_RGB := (0.0, 0.0, 0.0);
      FF : Unit_Interval;
      Used : Natural := 0;
      Src  : Color_RGB;
      Result : Gather_Result;
   begin
      for K in 1 .. Neighbors.Count loop
         FF := Radiosity_Form_Factor (Receiver, Neighbors.Patches (K));
         if FF > 0.0 then
            if Luminance (Neighbors.Patches (K).Radiosity) > 0.0 then
               Src := Neighbors.Patches (K).Radiosity;
            else
               Src := Neighbors.Patches (K).Emission;
            end if;
            Incoming := Color_Add (Incoming, Color_Scale (Real (FF), Src));
            Used := Used + 1;
         end if;
      end loop;
      --  B_i = E_i + ρ_i * Σ F_ij B_j
      Result.Incoming_Sum := Incoming;
      Result.Radiosity := Color_Add
        (Receiver.Emission,
         Color_Mul (Receiver.Reflectance, Incoming));
      Result.Neighbor_N := Used;
      return Result;
   end Radiosity_Gather;

   -------------------------------------------------------------------------
   -- 5. Path_Throughput_Bounce
   -------------------------------------------------------------------------

   function Path_Throughput_Bounce
     (Initial    : Color_RGB;
      Dirs       : Bounce_Dirs;
      BRDFs      : Bounce_BRDFs;
      Cosines    : Bounce_Cos;
      PDFs       : Bounce_PDFs;
      Count      : Bounce_Count) return Throughput_Result
   is
      T : Color_RGB := Initial;
      Factor : Real;
      Result : Throughput_Result;
      pragma Unreferenced (Dirs);
   begin
      Result.Path_Length := 0;
      Result.Survived := True;
      for K in 1 .. Count loop
         if PDFs (K) <= 0.0 then
            Result.Throughput := (0.0, 0.0, 0.0);
            Result.Survived := False;
            Result.Path_Length := K - 1;
            return Result;
         end if;
         Factor := Real (BRDFs (K)) * Real (Cosines (K)) / Real (PDFs (K));
         if Factor <= 0.0 then
            Result.Throughput := (0.0, 0.0, 0.0);
            Result.Survived := False;
            Result.Path_Length := K - 1;
            return Result;
         end if;
         T := Color_Scale (Factor, T);
         Result.Path_Length := K;
      end loop;
      Result.Throughput := T;
      return Result;
   end Path_Throughput_Bounce;

   -------------------------------------------------------------------------
   -- 6. Color_Bleeding
   -------------------------------------------------------------------------

   function Color_Bleeding
     (Receiver : Patch;
      Emitter  : Patch;
      Strength : Unit_Interval := 1.0) return Color_RGB
   is
      Br : constant Bounce_Result := Indirect_Bounce (Receiver, Emitter);
   begin
      return Color_Scale (Real (Strength), Br.Indirect);
   end Color_Bleeding;

   -------------------------------------------------------------------------
   -- 7. Caustic_Proxy
   -------------------------------------------------------------------------

   function Caustic_Proxy
     (Receiver       : Point3;
      Photon_Hits    : Direction_Array;
      Photon_Power   : Radiance_Array;
      Count          : Dir_Count;
      Kernel_Radius  : Positive_Real;
      Specular_Boost : Positive_Real := 1.0) return Caustic_Result
   is
      Acc : Color_RGB := (0.0, 0.0, 0.0);
      N_In : Natural := 0;
      R2 : constant Real := Real (Kernel_Radius) * Real (Kernel_Radius);
      Area : constant Real := Pi_F * R2;
      Dist2 : Real;
      Result : Caustic_Result;
   begin
      for K in 1 .. Count loop
         Dist2 := Dot (Photon_Hits (K) - Receiver, Photon_Hits (K) - Receiver);
         if Dist2 <= R2 then
            Acc := Color_Add (Acc, Photon_Power (K));
            N_In := N_In + 1;
         end if;
      end loop;
      if Area > 0.0 and then N_In > 0 then
         Result.Density_Est := Color_Scale
           (Real (Specular_Boost) / Area, Acc);
      else
         Result.Density_Est := (0.0, 0.0, 0.0);
      end if;
      Result.Photon_Count := N_In;
      Result.Kernel_Radius := Kernel_Radius;
      return Result;
   end Caustic_Proxy;

   -------------------------------------------------------------------------
   -- 8. Rendering_Equation_Sample
   -------------------------------------------------------------------------

   function Rendering_Equation_Sample
     (Le       : Color_RGB;
      N        : Normal3;
      Dirs     : Direction_Array;
      Li       : Radiance_Array;
      BRDF_Val : BRDF_Array;
      PDFs     : PDF_Array;
      Count    : Dir_Count) return RE_Sample_Result
   is
      Nn : constant Direction3 := Normalize (N);
      Acc : Color_RGB := (0.0, 0.0, 0.0);
      Cos_T : Real;
      W : Real;
      Used : Natural := 0;
      Result : RE_Sample_Result;
   begin
      for K in 1 .. Count loop
         if Length (Dirs (K)) = 0.0 or else PDFs (K) <= 0.0 then
            null;
         else
            Cos_T := Dot (Nn, Normalize (Dirs (K)));
            if Cos_T > 0.0 then
               W := Real (BRDF_Val (K)) * Cos_T / Real (PDFs (K));
               Acc := Color_Add (Acc, Color_Scale (W, Li (K)));
               Used := Used + 1;
            end if;
         end if;
      end loop;
      Result.Sample_Sum := Acc;
      Result.Lo := Color_Add (Le, Acc);
      Result.Used := Used;
      return Result;
   end Rendering_Equation_Sample;

   -------------------------------------------------------------------------
   -- 9. Ambient_Term_Vs_GI
   -------------------------------------------------------------------------

   function Ambient_Term_Vs_GI
     (Albedo         : Color_RGB;
      Ambient_Color  : Color_RGB;
      Direct         : Color_RGB;
      Indirect       : Color_RGB) return Ambient_Vs_GI_Result
   is
      Amb_Term : constant Color_RGB := Color_Mul (Albedo, Ambient_Color);
      Result   : Ambient_Vs_GI_Result;
      D1, D2   : Non_Negative;
   begin
      Result.Ambient_Only := Color_Add (Direct, Amb_Term);
      Result.With_GI := Color_Add (Direct, Indirect);
      Result.Indirect := Indirect;
      D1 := Luminance (Result.With_GI);
      D2 := Luminance (Result.Ambient_Only);
      if D1 >= D2 then
         Result.Delta_Luma := D1 - D2;
      else
         Result.Delta_Luma := D2 - D1;
      end if;
      return Result;
   end Ambient_Term_Vs_GI;

end Global_Illumination;
