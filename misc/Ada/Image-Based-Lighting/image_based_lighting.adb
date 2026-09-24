--  Package body for Image-Based Lighting (IBL) computations
--  Standard: Ada 2023 (ISO/IEC 8652:2023)

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

package body Image_Based_Lighting with
  SPARK_Mode => Off
is

   package Math is new
     Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   Pi     : constant Real := Ada.Numerics.Pi;
   Two_Pi : constant Real := 2.0 * Ada.Numerics.Pi;

   type Word32 is mod 2**32;

   --  ======================================================================
   --  Vector and Color Operations
   --  ======================================================================

   function Vector_Length (V : Vector3) return Real is
   begin
      return Sqrt (V.X * V.X + V.Y * V.Y + V.Z * V.Z);
   end Vector_Length;

   function Normalize (V : Vector3) return Vector3 is
      Len : constant Real := Vector_Length (V);
   begin
      if Len < 1.0e-7 then
         raise Invalid_Direction_Error with "Cannot normalize near-zero vector";
      end if;
      return (X => V.X / Len, Y => V.Y / Len, Z => V.Z / Len);
   end Normalize;

   function Dot_Product (U, V : Vector3) return Real is
   begin
      return (U.X * V.X) + (U.Y * V.Y) + (U.Z * V.Z);
   end Dot_Product;

   function Clamp_Color (C : Color_RGB) return Color_RGB is
      function Max_Zero (Val : Real) return Real is
      begin
         if Val < 0.0 then
            return 0.0;
         else
            return Val;
         end if;
      end Max_Zero;
   begin
      return (R => Max_Zero (C.R),
              G => Max_Zero (C.G),
              B => Max_Zero (C.B));
   end Clamp_Color;

   function Direction_To_Spherical (Dir : Vector3) return Spherical_Coord is
      Clamped_Y : Real := Dir.Y;
      Theta     : Real;
      Phi       : Real;
   begin
      if Clamped_Y > 1.0 then
         Clamped_Y := 1.0;
      elsif Clamped_Y < -1.0 then
         Clamped_Y := -1.0;
      end if;

      --  Polar angle from +Y axis (elevation)
      Theta := Arccos (Clamped_Y);

      --  Azimuth angle in X-Z plane with protection against (0.0, 0.0) at poles
      if abs (Dir.X) < 1.0e-7 and then abs (Dir.Z) < 1.0e-7 then
         Phi := 0.0;
      else
         Phi := Arctan (Y => Dir.Z, X => Dir.X);
         if Phi < 0.0 then
            Phi := Phi + Two_Pi;
         end if;
      end if;

      return (Theta => Theta, Phi => Phi);
   end Direction_To_Spherical;

   function Spherical_To_Direction (Coord : Spherical_Coord) return Vector3 is
      Sin_T : constant Real := Sin (Coord.Theta);
      Cos_T : constant Real := Cos (Coord.Theta);
      Sin_P : constant Real := Sin (Coord.Phi);
      Cos_P : constant Real := Cos (Coord.Phi);
      Raw   : constant Vector3 :=
        (X => Sin_T * Cos_P,
         Y => Cos_T,
         Z => Sin_T * Sin_P);
   begin
      return Normalize (Raw);
   end Spherical_To_Direction;

   function Sample_Equirectangular
     (Env : Environment_Map;
      Dir : Vector3) return Color_RGB
   is
      Coord : constant Spherical_Coord := Direction_To_Spherical (Dir);
      U     : constant Real := Coord.Phi / Two_Pi;
      V     : constant Real := Coord.Theta / Pi;

      PX : Integer := Integer (Real'Floor (U * Real (Env.Width))) + 1;
      PY : Integer := Integer (Real'Floor (V * Real (Env.Height))) + 1;
   begin
      if PX < 1 then
         PX := 1;
      elsif PX > Env.Width then
         PX := Env.Width;
      end if;

      if PY < 1 then
         PY := 1;
      elsif PY > Env.Height then
         PY := Env.Height;
      end if;

      return Env.Data (Dimension_Index (PY), Dimension_Index (PX));
   end Sample_Equirectangular;

   --  ======================================================================
   --  Variant 1: Mirror Reflection
   --  ======================================================================

   function Evaluate_Mirror_Reflection
     (Env         : Environment_Map;
      View_Vector : Vector3;
      Normal      : Vector3) return Color_RGB
   is
      --  R = V - 2 * (V . N) * N
      VdotN : constant Real := Dot_Product (View_Vector, Normal);
      R     : constant Vector3 :=
        (X => View_Vector.X - 2.0 * VdotN * Normal.X,
         Y => View_Vector.Y - 2.0 * VdotN * Normal.Y,
         Z => View_Vector.Z - 2.0 * VdotN * Normal.Z);
      Norm_R : constant Vector3 := Normalize (R);
   begin
      return Sample_Equirectangular (Env, Norm_R);
   end Evaluate_Mirror_Reflection;

   --  ======================================================================
   --  Variant 2: Diffuse Hemisphere Convolution
   --  ======================================================================

   function Convolve_Diffuse_Irradiance
     (Env        : Environment_Map;
      Normal     : Vector3;
      Step_Theta : Real := 0.05;
      Step_Phi   : Real := 0.05) return Color_RGB
   is
      Up        : Vector3 := (0.0, 1.0, 0.0);
      Right     : Vector3;
      Up_Vec    : Vector3;
      Acc_R     : Real := 0.0;
      Acc_G     : Real := 0.0;
      Acc_B     : Real := 0.0;
      Num_Samps : Real := 0.0;

      Theta     : Real := 0.0;
      Phi       : Real;
   begin
      if abs (Normal.Y) > 0.999 then
         Up := (1.0, 0.0, 0.0);
      end if;

      --  Tangent frame basis
      Right := Normalize
        ((X => Up.Y * Normal.Z - Up.Z * Normal.Y,
          Y => Up.Z * Normal.X - Up.X * Normal.Z,
          Z => Up.X * Normal.Y - Up.Y * Normal.X));

      Up_Vec := Normalize
        ((X => Normal.Y * Right.Z - Normal.Z * Right.Y,
          Y => Normal.Z * Right.X - Normal.X * Right.Z,
          Z => Normal.X * Right.Y - Normal.Y * Right.X));

      while Theta <= (Pi / 2.0) loop
         Phi := 0.0;
         while Phi <= Two_Pi loop
            declare
               Sin_T : constant Real := Sin (Theta);
               Cos_T : constant Real := Cos (Theta);
               Sin_P : constant Real := Sin (Phi);
               Cos_P : constant Real := Cos (Phi);

               --  Tangent space direction
               Local_X : constant Real := Sin_T * Cos_P;
               Local_Y : constant Real := Cos_T;
               Local_Z : constant Real := Sin_T * Sin_P;

               --  World space sample vector
               World_Sample : constant Vector3 := Normalize
                 ((X => Right.X * Local_X + Up_Vec.X * Local_Z + Normal.X * Local_Y,
                   Y => Right.Y * Local_X + Up_Vec.Y * Local_Z + Normal.Y * Local_Y,
                   Z => Right.Z * Local_X + Up_Vec.Z * Local_Z + Normal.Z * Local_Y));

               Radiance : constant Color_RGB :=
                 Sample_Equirectangular (Env, World_Sample);

               Weight : constant Real := Cos_T * Sin_T;
            begin
               Acc_R := Acc_R + Radiance.R * Weight;
               Acc_G := Acc_G + Radiance.G * Weight;
               Acc_B := Acc_B + Radiance.B * Weight;
               Num_Samps := Num_Samps + Weight;
            end;
            Phi := Phi + Step_Phi;
         end loop;
         Theta := Theta + Step_Theta;
      end loop;

      if Num_Samps > 0.0 then
         return (R => Acc_R / Num_Samps,
                 G => Acc_G / Num_Samps,
                 B => Acc_B / Num_Samps);
      else
         return (0.0, 0.0, 0.0);
      end if;
   end Convolve_Diffuse_Irradiance;

   --  ======================================================================
   --  Variant 3: Spherical Harmonics
   --  ======================================================================

   type SH_Basis is array (SH_Index) of Real;

   function Compute_SH_Basis (Dir : Vector3) return SH_Basis is
      Result : SH_Basis;
   begin
      --  Order 0
      Result (1) := 0.282095;
      --  Order 1
      Result (2) := 0.488603 * Dir.Y;
      Result (3) := 0.488603 * Dir.Z;
      Result (4) := 0.488603 * Dir.X;
      --  Order 2
      Result (5) := 1.092548 * Dir.X * Dir.Y;
      Result (6) := 1.092548 * Dir.Y * Dir.Z;
      Result (7) := 0.315392 * (3.0 * Dir.Z * Dir.Z - 1.0);
      Result (8) := 1.092548 * Dir.X * Dir.Z;
      Result (9) := 0.546274 * (Dir.X * Dir.X - Dir.Y * Dir.Y);
      return Result;
   end Compute_SH_Basis;

   function Project_Spherical_Harmonics
     (Env         : Environment_Map;
      Sample_Step : Real := 0.05) return SH_Coefficients
   is
      Coeffs     : SH_Coefficients := [others => (0.0, 0.0, 0.0)];
      Theta      : Real := 0.0;
      Phi        : Real;
      Total_Weight : Real := 0.0;
   begin
      while Theta <= Pi loop
         Phi := 0.0;
         declare
            Sin_T : constant Real := Sin (Theta);
            dOmega : constant Real := Sin_T * Sample_Step * Sample_Step;
         begin
            while Phi <= Two_Pi loop
               declare
                  Dir    : constant Vector3 :=
                    Spherical_To_Direction ((Theta => Theta, Phi => Phi));
                  Sample : constant Color_RGB :=
                    Sample_Equirectangular (Env, Dir);
                  Basis  : constant SH_Basis := Compute_SH_Basis (Dir);
               begin
                  for I in SH_Index loop
                     Coeffs (I).R := Coeffs (I).R + Sample.R * Basis (I) * dOmega;
                     Coeffs (I).G := Coeffs (I).G + Sample.G * Basis (I) * dOmega;
                     Coeffs (I).B := Coeffs (I).B + Sample.B * Basis (I) * dOmega;
                  end loop;
                  Total_Weight := Total_Weight + dOmega;
               end;
               Phi := Phi + Sample_Step;
            end loop;
         end;
         Theta := Theta + Sample_Step;
      end loop;

      --  Normalize by sphere area 4*Pi
      if Total_Weight > 0.0 then
         declare
            Factor : constant Real := (4.0 * Pi) / Total_Weight;
         begin
            for I in SH_Index loop
               Coeffs (I).R := Coeffs (I).R * Factor;
               Coeffs (I).G := Coeffs (I).G * Factor;
               Coeffs (I).B := Coeffs (I).B * Factor;
            end loop;
         end;
      end if;

      return Coeffs;
   end Project_Spherical_Harmonics;

   function Evaluate_SH_Irradiance
     (Coeffs : SH_Coefficients;
      Normal : Vector3) return Color_RGB
   is
      --  Ramamoorthi and Hanrahan convolution constants A_l
      C1 : constant Real := 0.429043;
      C2 : constant Real := 0.511664;
      C3 : constant Real := 0.743125;
      C4 : constant Real := 0.886227;
      C5 : constant Real := 0.247708;

      X : constant Real := Normal.X;
      Y : constant Real := Normal.Y;
      Z : constant Real := Normal.Z;

      Irr : Color_RGB;
   begin
      --  L_{0,0} contribution
      Irr.R := C4 * Coeffs (1).R;
      Irr.G := C4 * Coeffs (1).G;
      Irr.B := C4 * Coeffs (1).B;

      --  L_1 contributions
      Irr.R := Irr.R + 2.0 * C2 * (Coeffs (4).R * X + Coeffs (2).R * Y + Coeffs (3).R * Z);
      Irr.G := Irr.G + 2.0 * C2 * (Coeffs (4).G * X + Coeffs (2).G * Y + Coeffs (3).G * Z);
      Irr.B := Irr.B + 2.0 * C2 * (Coeffs (4).B * X + Coeffs (2).B * Y + Coeffs (3).B * Z);

      --  L_2 contributions
      Irr.R := Irr.R +
        C1 * Coeffs (9).R * (X * X - Y * Y) +
        C3 * Coeffs (7).R * (Z * Z) - C5 * Coeffs (7).R +
        2.0 * C1 * (Coeffs (5).R * X * Y + Coeffs (8).R * X * Z + Coeffs (6).R * Y * Z);

      Irr.G := Irr.G +
        C1 * Coeffs (9).G * (X * X - Y * Y) +
        C3 * Coeffs (7).G * (Z * Z) - C5 * Coeffs (7).G +
        2.0 * C1 * (Coeffs (5).G * X * Y + Coeffs (8).G * X * Z + Coeffs (6).G * Y * Z);

      Irr.B := Irr.B +
        C1 * Coeffs (9).B * (X * X - Y * Y) +
        C3 * Coeffs (7).B * (Z * Z) - C5 * Coeffs (7).B +
        2.0 * C1 * (Coeffs (5).B * X * Y + Coeffs (8).B * X * Z + Coeffs (6).B * Y * Z);

      return Clamp_Color (Irr);
   end Evaluate_SH_Irradiance;

   --  ======================================================================
   --  Variant 4: Split-Sum Specular
   --  ======================================================================

   function Radical_Inverse_VdC (Bits_In : Positive) return Real is
      Bits : Word32 := Word32 (Bits_In);
   begin
      --  Reverses 32 bits into van der Corput sequence
      Bits := ((Bits and 16#55555555#) * 2) or ((Bits and 16#AAAAAAAA#) / 2);
      Bits := ((Bits and 16#33333333#) * 4) or ((Bits and 16#CCCCCCCC#) / 4);
      Bits := ((Bits and 16#0F0F0F0F#) * 16) or ((Bits and 16#F0F0F0F0#) / 16);
      Bits := ((Bits and 16#00FF00FF#) * 256) or ((Bits and 16#FF00FF00#) / 256);
      Bits := ((Bits and 16#0000FFFF#) * 65536) or ((Bits and 16#FFFF0000#) / 65536);
      return Real (Bits) * (1.0 / 4294967296.0);
   end Radical_Inverse_VdC;

   type Hammersley_Point is record
      U : Real;
      V : Real;
   end record;

   function Hammersley (Index : Positive; Total : Positive) return Hammersley_Point is
   begin
      return (U => Real (Index) / Real (Total),
              V => Radical_Inverse_VdC (Index));
   end Hammersley;

   function Importance_Sample_GGX
     (Xi        : Hammersley_Point;
      Normal    : Vector3;
      Roughness : Roughness_Value) return Vector3
   is
      A     : constant Real := Roughness * Roughness;
      Phi   : constant Real := Two_Pi * Xi.U;
      Cos_Theta : constant Real :=
        Sqrt ((1.0 - Xi.V) / (1.0 + (A * A - 1.0) * Xi.V));
      Sin_Theta : constant Real :=
        Sqrt (Real'Max (0.0, 1.0 - Cos_Theta * Cos_Theta));

      --  Spherical to Cartesian in tangent space
      H : constant Vector3 :=
        (X => Cos (Phi) * Sin_Theta,
         Y => Sin (Phi) * Sin_Theta,
         Z => Cos_Theta);

      --  Tangent-to-world frame
      Up : Vector3 := (0.0, 1.0, 0.0);
      Tangent_X : Vector3;
      Tangent_Y : Vector3;
   begin
      if abs (Normal.Z) < 0.999 then
         Up := (0.0, 0.0, 1.0);
      end if;

      Tangent_X := Normalize
        ((X => Up.Y * Normal.Z - Up.Z * Normal.Y,
          Y => Up.Z * Normal.X - Up.X * Normal.Z,
          Z => Up.X * Normal.Y - Up.Y * Normal.X));

      Tangent_Y := Normalize
        ((X => Normal.Y * Tangent_X.Z - Normal.Z * Tangent_X.Y,
          Y => Normal.Z * Tangent_X.X - Normal.X * Tangent_X.Z,
          Z => Normal.X * Tangent_X.Y - Normal.Y * Tangent_X.X));

      return Normalize
        ((X => Tangent_X.X * H.X + Tangent_Y.X * H.Y + Normal.X * H.Z,
          Y => Tangent_X.Y * H.X + Tangent_Y.Y * H.Y + Normal.Y * H.Z,
          Z => Tangent_X.Z * H.X + Tangent_Y.Z * H.Y + Normal.Z * H.Z));
   end Importance_Sample_GGX;

   function Evaluate_Prefiltered_Specular
     (Env          : Environment_Map;
      Reflect_Dir  : Vector3;
      Roughness    : Roughness_Value;
      Num_Samples  : Positive := 64) return Color_RGB
   is
      N : constant Vector3 := Reflect_Dir;
      V : constant Vector3 := Reflect_Dir;
      Total_Weight : Real := 0.0;
      Prefiltered  : Color_RGB := (0.0, 0.0, 0.0);
   begin
      if Roughness <= 1.0e-4 then
         return Sample_Equirectangular (Env, Reflect_Dir);
      end if;

      for I in 1 .. Num_Samples loop
         declare
            Xi : constant Hammersley_Point := Hammersley (I, Num_Samples);
            H  : constant Vector3 := Importance_Sample_GGX (Xi, N, Roughness);
            VdotH : constant Real := Dot_Product (V, H);
            L  : constant Vector3 := Normalize
              ((X => 2.0 * VdotH * H.X - V.X,
                Y => 2.0 * VdotH * H.Y - V.Y,
                Z => 2.0 * VdotH * H.Z - V.Z));
            NdotL : constant Real := Dot_Product (N, L);
         begin
            if NdotL > 0.0 then
               declare
                  Sample_Color : constant Color_RGB :=
                    Sample_Equirectangular (Env, L);
               begin
                  Prefiltered.R := Prefiltered.R + Sample_Color.R * NdotL;
                  Prefiltered.G := Prefiltered.G + Sample_Color.G * NdotL;
                  Prefiltered.B := Prefiltered.B + Sample_Color.B * NdotL;
                  Total_Weight  := Total_Weight + NdotL;
               end;
            end if;
         end;
      end loop;

      if Total_Weight > 0.0 then
         return (R => Prefiltered.R / Total_Weight,
                 G => Prefiltered.G / Total_Weight,
                 B => Prefiltered.B / Total_Weight);
      else
         return Sample_Equirectangular (Env, Reflect_Dir);
      end if;
   end Evaluate_Prefiltered_Specular;

   function Geometry_Schlick_GGX
     (NdotV     : Real;
      Roughness : Roughness_Value) return Real
   is
      K : constant Real := (Roughness * Roughness) / 2.0;
   begin
      return NdotV / (NdotV * (1.0 - K) + K);
   end Geometry_Schlick_GGX;

   function Geometry_Smith
     (NdotV     : Real;
      NdotL     : Real;
      Roughness : Roughness_Value) return Real
   is
      G1 : constant Real := Geometry_Schlick_GGX (NdotV, Roughness);
      G2 : constant Real := Geometry_Schlick_GGX (NdotL, Roughness);
   begin
      return G1 * G2;
   end Geometry_Smith;

   function Precompute_BRDF_LUT (Size : Dimension_Index) return BRDF_LUT is
      Result      : BRDF_LUT (Size);
      Num_Samples : constant Positive := 128;
   begin
      for Y_Idx in 1 .. Size loop
         declare
            Roughness : constant Roughness_Value :=
              Real (Y_Idx) / Real (Size);
         begin
            for X_Idx in 1 .. Size loop
               declare
                  NdotV : constant Real := Real (X_Idx) / Real (Size);
                  V     : constant Vector3 :=
                    (X => Sqrt (1.0 - NdotV * NdotV),
                     Y => 0.0,
                     Z => NdotV);
                  N     : constant Vector3 := (0.0, 0.0, 1.0);
                  Scale_Acc : Real := 0.0;
                  Bias_Acc  : Real := 0.0;
               begin
                  for S in 1 .. Num_Samples loop
                     declare
                        Xi : constant Hammersley_Point := Hammersley (S, Num_Samples);
                        H  : constant Vector3 :=
                          Importance_Sample_GGX (Xi, N, Roughness);
                        VdotH : constant Real := Dot_Product (V, H);
                        L  : constant Vector3 := Normalize
                          ((X => 2.0 * VdotH * H.X - V.X,
                            Y => 2.0 * VdotH * H.Y - V.Y,
                            Z => 2.0 * VdotH * H.Z - V.Z));
                        NdotL : constant Real := Real'Max (L.Z, 0.0);
                        NdotH : constant Real := Real'Max (H.Z, 0.0);
                        VdotH_Clamped : constant Real := Real'Max (VdotH, 0.0);
                     begin
                        if NdotL > 0.0 then
                           declare
                              G : constant Real :=
                                Geometry_Smith (NdotV, NdotL, Roughness);
                              G_Vis : constant Real :=
                                (G * VdotH_Clamped) / (NdotH * NdotV);
                              Fc : constant Real :=
                                (1.0 - VdotH_Clamped) ** 5;
                           begin
                              Scale_Acc := Scale_Acc + (1.0 - Fc) * G_Vis;
                              Bias_Acc  := Bias_Acc + Fc * G_Vis;
                           end;
                        end if;
                     end;
                  end loop;

                  Result.Data (Y_Idx, X_Idx) :=
                    (Scale => Scale_Acc / Real (Num_Samples),
                     Bias  => Bias_Acc / Real (Num_Samples));
               end;
            end loop;
         end;
      end loop;

      return Result;
   end Precompute_BRDF_LUT;

   function Sample_BRDF_LUT
     (Lut       : BRDF_LUT;
      NoV       : Unit_Interval;
      Roughness : Roughness_Value) return BRDF_Lut_Entry
   is
      X : Integer := Integer (Real'Floor (NoV * Real (Lut.Size))) + 1;
      Y : Integer := Integer (Real'Floor (Roughness * Real (Lut.Size))) + 1;
   begin
      if X < 1 then
         X := 1;
      elsif X > Lut.Size then
         X := Lut.Size;
      end if;

      if Y < 1 then
         Y := 1;
      elsif Y > Lut.Size then
         Y := Lut.Size;
      end if;

      return Lut.Data (Dimension_Index (Y), Dimension_Index (X));
   end Sample_BRDF_LUT;

   function Evaluate_Split_Sum_Specular
     (Prefiltered_Color : Color_RGB;
      BRDF_Scale_Bias   : BRDF_Lut_Entry;
      F0                : Color_RGB) return Color_RGB
   is
      Reflectance_R : constant Real :=
        F0.R * BRDF_Scale_Bias.Scale + BRDF_Scale_Bias.Bias;
      Reflectance_G : constant Real :=
        F0.G * BRDF_Scale_Bias.Scale + BRDF_Scale_Bias.Bias;
      Reflectance_B : constant Real :=
        F0.B * BRDF_Scale_Bias.Scale + BRDF_Scale_Bias.Bias;
   begin
      return (R => Prefiltered_Color.R * Reflectance_R,
              G => Prefiltered_Color.G * Reflectance_G,
              B => Prefiltered_Color.B * Reflectance_B);
   end Evaluate_Split_Sum_Specular;

end Image_Based_Lighting;
