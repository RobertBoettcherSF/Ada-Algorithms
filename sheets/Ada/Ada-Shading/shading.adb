--  Package: Shading
--  Implementation of 3D computer graphics shading models based on:
--  https://en.wikipedia.org/wiki/Shading
--  Complies with Ada 2023 (ISO/IEC 8652:2023).

with Ada.Numerics;

package body Shading with SPARK_Mode => On is

   --  Clamp helper for normalized intensity bounds [0.0, 1.0]
   function Clamp_01 (Val : Real) return Intensity_Value is
   begin
      if Val < 0.0 then
         return 0.0;
      elsif Val > 1.0 then
         return 1.0;
      else
         return Val;
      end if;
   end Clamp_01;

   ---------------------------------------------------------------------------
   --  Magnitude
   ---------------------------------------------------------------------------
   function Magnitude (V : Vector_3D) return Distance_Value is
      Sum_Sq : constant Real := Magnitude_Squared (V);
   begin
      if Sum_Sq <= 0.0 then
         return 0.0;
      else
         return Real_Math.Sqrt (Sum_Sq);
      end if;
   end Magnitude;

   ---------------------------------------------------------------------------
   --  Normalize
   ---------------------------------------------------------------------------
   function Normalize (V : Vector_3D) return Vector_3D is
      Mag : constant Real := Magnitude (V);
   begin
      if Mag <= 0.0 then
         raise Zero_Vector_Error;
      end if;
      return (X => V.X / Mag,
              Y => V.Y / Mag,
              Z => V.Z / Mag);
   end Normalize;

   ---------------------------------------------------------------------------
   --  Reflect: R = 2 * (N . L) * N - L
   ---------------------------------------------------------------------------
   function Reflect (Light_Dir, Normal : Vector_3D) return Vector_3D is
      N   : constant Vector_3D := Normalize (Normal);
      Ndl : constant Real      := Dot_Product (N, Light_Dir);
   begin
      return (2.0 * Ndl * N) - Light_Dir;
   end Reflect;

   ---------------------------------------------------------------------------
   --  Make_Color
   ---------------------------------------------------------------------------
   function Make_Color (R, G, B : Real) return Color_RGB is
   begin
      return (R => Clamp_01 (R),
              G => Clamp_01 (G),
              B => Clamp_01 (B));
   end Make_Color;

   ---------------------------------------------------------------------------
   --  Add_Colors
   ---------------------------------------------------------------------------
   function Add_Colors (C1, C2 : Color_RGB) return Color_RGB is
   begin
      return (R => Clamp_01 (C1.R + C2.R),
              G => Clamp_01 (C1.G + C2.G),
              B => Clamp_01 (C1.B + C2.B));
   end Add_Colors;

   ---------------------------------------------------------------------------
   --  Modulate_Colors
   ---------------------------------------------------------------------------
   function Modulate_Colors (C1, C2 : Color_RGB) return Color_RGB is
   begin
      return (R => Clamp_01 (C1.R * C2.R),
              G => Clamp_01 (C1.G * C2.G),
              B => Clamp_01 (C1.B * C2.B));
   end Modulate_Colors;

   ---------------------------------------------------------------------------
   --  Scale_Color
   ---------------------------------------------------------------------------
   function Scale_Color (C : Color_RGB; Factor : Intensity_Value) return Color_RGB is
   begin
      return (R => Clamp_01 (C.R * Factor),
              G => Clamp_01 (C.G * Factor),
              B => Clamp_01 (C.B * Factor));
   end Scale_Color;

   ---------------------------------------------------------------------------
   --  Compute_Falloff
   --  Distance falloff calculation from Wikipedia:
   --  None (n=0)      => 1.0
   --  Linear (n=1)    => 1.0 / (1.0 + Dist)
   --  Quadratic (n=2) => 1.0 / (1.0 + Dist^2)
   --  Custom_Power    => 1.0 / (1.0 + Dist^Power)
   ---------------------------------------------------------------------------
   function Compute_Falloff (Dist : Distance_Value; Falloff : Distance_Falloff)
      return Attenuation_Val
   is
   begin
      case Falloff.Kind is
         when None =>
            return 1.0;

         when Linear =>
            return 1.0 / (1.0 + Dist);

         when Quadratic =>
            return 1.0 / (1.0 + (Dist * Dist));

         when Custom_Power =>
            if Falloff.Power = 0.0 then
               return 1.0;
            elsif Dist = 0.0 then
               return 1.0;
            else
               return 1.0 / (1.0 + Real_Math."**" (Dist, Real (Falloff.Power)));
            end if;
      end case;
   end Compute_Falloff;

   ---------------------------------------------------------------------------
   --  Barycentric Helper
   ---------------------------------------------------------------------------
   function Make_Barycentric (U, V, W : Real) return Barycentric_Weights is
      Sum : constant Real := U + V + W;
   begin
      if Sum <= 0.0 then
         raise Invalid_Weights_Error;
      end if;

      return (U => Clamp_01 (U / Sum),
              V => Clamp_01 (V / Sum),
              W => Clamp_01 (W / Sum));
   end Make_Barycentric;

   ---------------------------------------------------------------------------
   --  Interpolate_Vector
   ---------------------------------------------------------------------------
   function Interpolate_Vector
     (A, B, C : Vector_3D;
      W       : Barycentric_Weights) return Vector_3D
   is
   begin
      return (W.U * A) + (W.V * B) + (W.W * C);
   end Interpolate_Vector;

   ---------------------------------------------------------------------------
   --  Interpolate_Color
   ---------------------------------------------------------------------------
   function Interpolate_Color
     (A, B, C : Color_RGB;
      W       : Barycentric_Weights) return Color_RGB
   is
      R     : constant Real := (A.R * W.U) + (B.R * W.V) + (C.R * W.W);
      G     : constant Real := (A.G * W.U) + (B.G * W.V) + (C.G * W.W);
      B_Val : constant Real := (A.B * W.U) + (B.B * W.V) + (C.B * W.W);
   begin
      return Make_Color (R, G, B_Val);
   end Interpolate_Color;

   ---------------------------------------------------------------------------
   --  Triangle_Face_Normal
   --  Calculates the geometric surface normal via cross product of edges.
   ---------------------------------------------------------------------------
   function Triangle_Face_Normal (Tri : Triangle) return Vector_3D is
      Edge1 : constant Vector_3D := Tri.V1.Position - Tri.V0.Position;
      Edge2 : constant Vector_3D := Tri.V2.Position - Tri.V0.Position;
      Cross : constant Vector_3D := Cross_Product (Edge1, Edge2);
   begin
      if Magnitude_Squared (Cross) <= 0.0 then
         raise Degenerate_Geometry_Error;
      end if;
      return Normalize (Cross);
   end Triangle_Face_Normal;

   ---------------------------------------------------------------------------
   --  Evaluate_Lighting
   --  Computes Ambient, Diffuse (Lambertian), and Specular (Phong) lighting.
   ---------------------------------------------------------------------------
   function Evaluate_Lighting
     (Position    : Vector_3D;
      Normal      : Vector_3D;
      View_Pos    : Vector_3D;
      Mat         : Material;
      Lights      : Light_Array) return Color_RGB
   is
      N : constant Vector_3D := Normalize (Normal);
      V : Vector_3D;
      Accumulated : Color_RGB := Black;
   begin
      if Magnitude_Squared (View_Pos - Position) > 0.0 then
         V := Normalize (View_Pos - Position);
      else
         V := (0.0, 0.0, 1.0);
      end if;

      for L of Lights loop
         case L.Kind is
            when Ambient =>
               declare
                  Amb_Light : constant Color_RGB := Scale_Color (L.Color, L.Intensity);
                  Amb_Term  : constant Color_RGB :=
                    Modulate_Colors (Mat.Ambient_Color, Amb_Light);
               begin
                  Accumulated := Add_Colors
                    (Accumulated,
                     Scale_Color (Amb_Term, Mat.Ambient_Coeff));
               end;

            when Directional =>
               declare
                  -- Direction vector L_Dir points from surface point to light source
                  Light_Dir : constant Vector_3D :=
                    Normalize (Vector_3D'(X => -L.Direction.X,
                                          Y => -L.Direction.Y,
                                          Z => -L.Direction.Z));
                  N_Dot_L   : constant Real := Real'Max (0.0, Dot_Product (N, Light_Dir));
               begin
                  if N_Dot_L > 0.0 then
                     declare
                        Diff_Light : constant Color_RGB := Scale_Color (L.Color, L.Intensity);
                        Diff_Term  : constant Color_RGB :=
                          Scale_Color (Modulate_Colors (Mat.Diffuse_Color, Diff_Light),
                                       Clamp_01 (N_Dot_L * Mat.Diffuse_Coeff));

                        Reflect_Dir : constant Vector_3D := Reflect (Light_Dir, N);
                        R_Dot_V     : constant Real :=
                          Real'Max (0.0, Dot_Product (Reflect_Dir, V));
                        Spec_Factor : Real := 0.0;
                     begin
                        if R_Dot_V > 0.0 then
                           Spec_Factor := Real_Math."**" (R_Dot_V, Real (Mat.Shininess));
                        end if;

                        declare
                           Spec_Light : constant Color_RGB := Scale_Color (L.Color, L.Intensity);
                           Spec_Term  : constant Color_RGB :=
                             Scale_Color (Modulate_Colors (Mat.Specular_Color, Spec_Light),
                                          Clamp_01 (Spec_Factor * Mat.Specular_Coeff));
                        begin
                           Accumulated := Add_Colors (Accumulated, Diff_Term);
                           Accumulated := Add_Colors (Accumulated, Spec_Term);
                        end;
                     end;
                  end if;
               end;

            when Point_Light =>
               declare
                  To_Light : constant Vector_3D      := L.Position - Position;
                  Dist     : constant Distance_Value := Magnitude (To_Light);
               begin
                  if Dist > 0.0 then
                     declare
                        Light_Dir : constant Vector_3D := Normalize (To_Light);
                        N_Dot_L   : constant Real      :=
                          Real'Max (0.0, Dot_Product (N, Light_Dir));
                        Atten     : constant Attenuation_Val :=
                          Compute_Falloff (Dist, L.Falloff);
                     begin
                        if N_Dot_L > 0.0 and then Atten > 0.0 then
                           declare
                              Effective_Int : constant Intensity_Value :=
                                Clamp_01 (L.Intensity * Atten);
                              Diff_Light    : constant Color_RGB :=
                                Scale_Color (L.Color, Effective_Int);
                              Diff_Term     : constant Color_RGB :=
                                Scale_Color (Modulate_Colors (Mat.Diffuse_Color, Diff_Light),
                                             Clamp_01 (N_Dot_L * Mat.Diffuse_Coeff));

                              Reflect_Dir : constant Vector_3D := Reflect (Light_Dir, N);
                              R_Dot_V     : constant Real :=
                                Real'Max (0.0, Dot_Product (Reflect_Dir, V));
                              Spec_Factor : Real := 0.0;
                           begin
                              if R_Dot_V > 0.0 then
                                 Spec_Factor := Real_Math."**" (R_Dot_V, Real (Mat.Shininess));
                              end if;

                              declare
                                 Spec_Term : constant Color_RGB :=
                                   Scale_Color (Modulate_Colors (Mat.Specular_Color, Diff_Light),
                                                Clamp_01 (Spec_Factor * Mat.Specular_Coeff));
                              begin
                                 Accumulated := Add_Colors (Accumulated, Diff_Term);
                                 Accumulated := Add_Colors (Accumulated, Spec_Term);
                              end;
                           end;
                        end if;
                     end;
                  end if;
               end;

            when Spot_Light =>
               declare
                  To_Light : constant Vector_3D      := L.Position - Position;
                  Dist     : constant Distance_Value := Magnitude (To_Light);
               begin
                  if Dist > 0.0 then
                     declare
                        Light_Dir     : constant Vector_3D := Normalize (To_Light);
                        Spot_Dir      : constant Vector_3D := Normalize (L.Direction);
                        Neg_Light_Dir : constant Vector_3D :=
                          Vector_3D'(X => -Light_Dir.X, Y => -Light_Dir.Y, Z => -Light_Dir.Z);
                        Cos_Angle     : constant Real := Dot_Product (Neg_Light_Dir, Spot_Dir);
                        Cutoff_Rad    : constant Real :=
                          L.Spot_Cone_Angle_Deg * (Ada.Numerics.Pi / 180.0);
                        Cos_Cutoff    : constant Real := Real_Math.Cos (Cutoff_Rad);
                     begin
                        --  Inside spotlight cone
                        if Cos_Angle >= Cos_Cutoff and then Cos_Angle > 0.0 then
                           declare
                              Spot_Effect : constant Real :=
                                Real_Math."**" (Cos_Angle, L.Spot_Dropoff_Exp);
                              N_Dot_L     : constant Real :=
                                Real'Max (0.0, Dot_Product (N, Light_Dir));
                              Atten       : constant Attenuation_Val :=
                                Compute_Falloff (Dist, L.Falloff);
                           begin
                              if N_Dot_L > 0.0 and then Atten > 0.0 then
                                 declare
                                    Effective_Int : constant Intensity_Value :=
                                      Clamp_01 (L.Intensity * Atten * Spot_Effect);
                                    Light_Col     : constant Color_RGB :=
                                      Scale_Color (L.Color, Effective_Int);
                                    Diff_Term     : constant Color_RGB :=
                                      Scale_Color (Modulate_Colors (Mat.Diffuse_Color, Light_Col),
                                                   Clamp_01 (N_Dot_L * Mat.Diffuse_Coeff));

                                    Reflect_Dir : constant Vector_3D := Reflect (Light_Dir, N);
                                    R_Dot_V     : constant Real :=
                                      Real'Max (0.0, Dot_Product (Reflect_Dir, V));
                                    Spec_Factor : Real := 0.0;
                                 begin
                                    if R_Dot_V > 0.0 then
                                       Spec_Factor := Real_Math."**" (R_Dot_V, Real (Mat.Shininess));
                                    end if;

                                    declare
                                       Spec_Term : constant Color_RGB :=
                                         Scale_Color
                                           (Modulate_Colors (Mat.Specular_Color, Light_Col),
                                            Clamp_01 (Spec_Factor * Mat.Specular_Coeff));
                                    begin
                                       Accumulated := Add_Colors (Accumulated, Diff_Term);
                                       Accumulated := Add_Colors (Accumulated, Spec_Term);
                                    end;
                                 end;
                              end if;
                           end;
                        end if;
                     end;
                  end if;
               end;
         end case;
      end loop;

      return Accumulated;
   end Evaluate_Lighting;

   ---------------------------------------------------------------------------
   --  Variant 1: Shade_Flat
   --  Per Wikipedia: Lighting value is computed once for the polygon face
   --  using the polygon face normal and centroid.
   ---------------------------------------------------------------------------
   function Shade_Flat
     (Tri      : Triangle;
      Mat      : Material;
      View_Pos : Vector_3D;
      Lights   : Light_Array) return Color_RGB
   is
      Centroid : constant Vector_3D :=
        (1.0 / 3.0) * (Tri.V0.Position + Tri.V1.Position + Tri.V2.Position);
      Face_Norm : constant Vector_3D := Triangle_Face_Normal (Tri);
   begin
      return Evaluate_Lighting
        (Position => Centroid,
         Normal   => Face_Norm,
         View_Pos => View_Pos,
         Mat      => Mat,
         Lights   => Lights);
   end Shade_Flat;

   ---------------------------------------------------------------------------
   --  Variant 2: Shade_Gouraud
   --  Per Wikipedia: Determine normal at each vertex, calculate lighting at
   --  each vertex, then bilinearly interpolate vertex colors.
   ---------------------------------------------------------------------------
   function Shade_Gouraud
     (Tri      : Triangle;
      Mat      : Material;
      Weights  : Barycentric_Weights;
      View_Pos : Vector_3D;
      Lights   : Light_Array) return Color_RGB
   is
      Color_V0 : constant Color_RGB := Evaluate_Lighting
        (Position => Tri.V0.Position,
         Normal   => Tri.V0.Normal,
         View_Pos => View_Pos,
         Mat      => Mat,
         Lights   => Lights);

      Color_V1 : constant Color_RGB := Evaluate_Lighting
        (Position => Tri.V1.Position,
         Normal   => Tri.V1.Normal,
         View_Pos => View_Pos,
         Mat      => Mat,
         Lights   => Lights);

      Color_V2 : constant Color_RGB := Evaluate_Lighting
        (Position => Tri.V2.Position,
         Normal   => Tri.V2.Normal,
         View_Pos => View_Pos,
         Mat      => Mat,
         Lights   => Lights);
   begin
      return Interpolate_Color (Color_V0, Color_V1, Color_V2, Weights);
   end Shade_Gouraud;

   ---------------------------------------------------------------------------
   --  Variant 3: Shade_Phong
   --  Per Wikipedia: Normals are interpolated across vertices using
   --  barycentric interpolation, re-normalized, and lighting evaluated per
   --  sample.
   ---------------------------------------------------------------------------
   function Shade_Phong
     (Tri      : Triangle;
      Mat      : Material;
      Weights  : Barycentric_Weights;
      View_Pos : Vector_3D;
      Lights   : Light_Array) return Color_RGB
   is
      Interp_Pos  : constant Vector_3D :=
        Interpolate_Vector (Tri.V0.Position, Tri.V1.Position, Tri.V2.Position, Weights);
      Interp_Norm : constant Vector_3D :=
        Interpolate_Vector (Tri.V0.Normal, Tri.V1.Normal, Tri.V2.Normal, Weights);
      Normalized_N : Vector_3D;
   begin
      if Magnitude_Squared (Interp_Norm) > 0.0 then
         Normalized_N := Normalize (Interp_Norm);
      else
         --  Fallback to geometric face normal if interpolated normal vanishes
         Normalized_N := Triangle_Face_Normal (Tri);
      end if;

      return Evaluate_Lighting
        (Position => Interp_Pos,
         Normal   => Normalized_N,
         View_Pos => View_Pos,
         Mat      => Mat,
         Lights   => Lights);
   end Shade_Phong;

   ---------------------------------------------------------------------------
   --  Variant 4: Deferred_Geometry_Pass
   --  Writes surface attributes into G-Buffer.
   ---------------------------------------------------------------------------
   procedure Deferred_Geometry_Pass
     (Buffer   : in out G_Buffer;
      X, Y     : Positive;
      Pos      : Vector_3D;
      Normal   : Vector_3D;
      Mat      : Material;
      Depth    : Real)
   is
   begin
      if (not Buffer (X, Y).Valid) or else (Depth < Buffer (X, Y).Depth) then
         Buffer (X, Y) :=
           (Valid        => True,
            Position     => Pos,
            Normal       => Normalize (Normal),
            Albedo       => Mat.Diffuse_Color,
            Depth        => Depth,
            Ambient_Amt  => Mat.Ambient_Coeff,
            Specular_Amt => Mat.Specular_Coeff,
            Shininess    => Mat.Shininess);
      end if;
   end Deferred_Geometry_Pass;

   ---------------------------------------------------------------------------
   --  Variant 4: Deferred_Lighting_Pass
   --  Evaluates lighting for all populated G-Buffer pixels.
   ---------------------------------------------------------------------------
   procedure Deferred_Lighting_Pass
     (Buffer   : in G_Buffer;
      Output   : out Framebuffer;
      View_Pos : Vector_3D;
      Lights   : Light_Array)
   is
   begin
      for Row in Buffer'Range (1) loop
         for Col in Buffer'Range (2) loop
            if Buffer (Row, Col).Valid then
               declare
                  Pix : constant G_Buffer_Pixel := Buffer (Row, Col);
                  Pixel_Mat : constant Material :=
                    (Ambient_Color  => Pix.Albedo,
                     Diffuse_Color  => Pix.Albedo,
                     Specular_Color => White,
                     Ambient_Coeff  => Pix.Ambient_Amt,
                     Diffuse_Coeff  => 0.8,
                     Specular_Coeff => Pix.Specular_Amt,
                     Shininess      => Pix.Shininess);
               begin
                  Output (Row, Col) := Evaluate_Lighting
                    (Position => Pix.Position,
                     Normal   => Pix.Normal,
                     View_Pos => View_Pos,
                     Mat      => Pixel_Mat,
                     Lights   => Lights);
               end;
            else
               Output (Row, Col) := Black;
            end if;
         end loop;
      end loop;
   end Deferred_Lighting_Pass;

end Shading;
