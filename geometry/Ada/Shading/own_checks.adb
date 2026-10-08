--  Own checks (see tests/SOURCES.txt). Assume Shading is wrong or does
--  nothing. References, all computed here and different from the code:
--  * vector algebra: dot and cross from the component formulas, magnitude
--    from the square root, checked by their identities (the cross product
--    is perpendicular to both arguments, the triple product is the signed
--    volume, normalizing gives length 1);
--  * falloff: 1 / (1 + dist**n) with an own exponentiation (repeated
--    squaring), not Real_Math."**";
--  * lighting: the Phong model (Phong 1975) evaluated from the formulas,
--    with one light kind at a time and no clamping inside the formula, so
--    the code's clamped result must equal the formula's result clamped
--    channel by channel at the end;
--  * the four variants: flat = the model at the centroid with the face
--    normal; Gouraud = the model at the vertices, colors interpolated;
--    Phong = the model at the interpolated position with the renormalized
--    interpolated normal; deferred = the geometry pass keeps the closest
--    fragment, the lighting pass is the model with the pixel's stored
--    material (diffuse coefficient 0.8, white specular, as the code's
--    lighting pass builds it).
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Environment_Variables;
with Ada.Numerics.Long_Elementary_Functions;
with Shading; use Shading;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 25 then
            Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   --  test-data seed: fixed default, printed, overridable with AA_SEED
   type U32 is mod 2 ** 32;
   Default_Seed : constant U32 := 20261008;
   function Seed_From_Env return U32 is
      S : U32 := Default_Seed;
   begin
      if Ada.Environment_Variables.Exists ("AA_SEED") then
         S := U32'Value (Ada.Environment_Variables.Value ("AA_SEED"));
      end if;
      Put_Line ("own checks seed:" & S'Image & " (default" & Default_Seed'Image
                & "; set AA_SEED to override)");
      return S;
   end Seed_From_Env;
   Lcg : U32 := Seed_From_Env;
   function Rand (M : Positive) return Natural is
   begin
      Lcg := Lcg * 1664525 + 1013904223;
      return Natural ((Lcg / 256) mod U32 (M));
   end Rand;
   function Rnd (Lo, Hi : Long_Float) return Long_Float is
     (Lo + Long_Float (Rand (1_000_001)) / 1_000_000.0 * (Hi - Lo));

   function Ref_Pow (Base : Long_Float; N : Natural) return Long_Float is
      R : Long_Float := 1.0;
      B : Long_Float := Base;
      E : Natural := N;
   begin
      while E > 0 loop
         if E mod 2 = 1 then
            R := R * B;
         end if;
         B := B * B;
         E := E / 2;
      end loop;
      return R;
   end Ref_Pow;

   function Clamp (X : Long_Float) return Long_Float is
     (Long_Float'Max (0.0, Long_Float'Min (1.0, X)));

   function Close (A, B : Long_Float; Tol : Long_Float := 1.0E-6) return Boolean is
     (abs (A - B) <= Tol * Long_Float'Max (1.0, Long_Float'Max (abs A, abs B)));

   function V (X, Y, Z : Long_Float) return Vector_3D is
     (Vector_3D'(Real (X), Real (Y), Real (Z)));

   function Dot (A, B : Vector_3D) return Long_Float is
     (Long_Float (A.X) * Long_Float (B.X) + Long_Float (A.Y) * Long_Float (B.Y)
      + Long_Float (A.Z) * Long_Float (B.Z));

   function Cross (A, B : Vector_3D) return Vector_3D is
     (V (Long_Float (A.Y) * Long_Float (B.Z) - Long_Float (A.Z) * Long_Float (B.Y),
         Long_Float (A.Z) * Long_Float (B.X) - Long_Float (A.X) * Long_Float (B.Z),
         Long_Float (A.X) * Long_Float (B.Y) - Long_Float (A.Y) * Long_Float (B.X)));

   function Mag (A : Vector_3D) return Long_Float is
     (Ada.Numerics.Long_Elementary_Functions.Sqrt (Dot (A, A)));

   function Unit (A : Vector_3D) return Vector_3D is
      M : constant Long_Float := Mag (A);
   begin
      return V (Long_Float (A.X) / M, Long_Float (A.Y) / M, Long_Float (A.Z) / M);
   end Unit;

   type FCol is array (1 .. 3) of Long_Float;

   function To_F (C : Color_RGB) return FCol is [Long_Float (C.R), Long_Float (C.G), Long_Float (C.B)];

   function Same (C : Color_RGB; F : FCol; Tol : Long_Float := 1.0E-5) return Boolean is
     (Close (Long_Float (C.R), Clamp (F (1)), Tol)
      and then Close (Long_Float (C.G), Clamp (F (2)), Tol)
      and then Close (Long_Float (C.B), Clamp (F (3)), Tol));

   function Ch (C : Color_RGB; K : FCol; Scale : Long_Float) return FCol is
     ([for I in 1 .. 3 => To_F (C) (I) * K (I) * Scale]);

   function Add (A, B : FCol) return FCol is ([for I in 1 .. 3 => A (I) + B (I)]);

   --  Phong model, unclamped: ambient ka Ca Ia; diffuse kd Cd Il max(n.l, 0);
   --  specular ks Cs Il max(r.v, 0)**shininess; point and spot lights
   --  multiply by the falloff 1/(1+dist**n) and the spot by
   --  max(cos theta, 0)**dropoff inside the cone
   function Ref_Light (Pos, Normal, View : Vector_3D; Mat : Material; L : Light_Source) return FCol is
      N : constant Vector_3D := Unit (Normal);
      Vw : constant Vector_3D :=
        (if Mag (V (Long_Float (View.X) - Long_Float (Pos.X), Long_Float (View.Y) - Long_Float (Pos.Y),
                    Long_Float (View.Z) - Long_Float (Pos.Z))) > 0.0
         then Unit (V (Long_Float (View.X) - Long_Float (Pos.X), Long_Float (View.Y) - Long_Float (Pos.Y),
                       Long_Float (View.Z) - Long_Float (Pos.Z)))
         else V (0.0, 0.0, 1.0));
      function Term (Dir : Vector_3D; Atten : Long_Float) return FCol is
         Ndl : constant Long_Float := Long_Float'Max (0.0, Dot (N, Dir));
         --  the reflection of a unit vector in a unit normal is a unit
         --  vector, so r.v is at most 1 and the power stays in range
         R   : constant Vector_3D :=
           V (2.0 * Dot (N, Dir) * Long_Float (N.X) - Long_Float (Dir.X),
              2.0 * Dot (N, Dir) * Long_Float (N.Y) - Long_Float (Dir.Y),
              2.0 * Dot (N, Dir) * Long_Float (N.Z) - Long_Float (Dir.Z));
         Rdv : constant Long_Float := Long_Float'Max (0.0, Dot (R, Vw));
         Spec : constant Long_Float :=
           (if Ndl = 0.0 or else Rdv = 0.0 then 0.0
            else Ada.Numerics.Long_Elementary_Functions."**" (Rdv, Long_Float (Mat.Shininess)));
      begin
         return Add (Ch (Mat.Diffuse_Color, To_F (L.Color), Long_Float (Mat.Diffuse_Coeff) * Clamp (Ndl) * Long_Float (L.Intensity) * Atten),
                     Ch (Mat.Specular_Color, To_F (L.Color), Long_Float (Mat.Specular_Coeff) * Clamp (Spec) * Long_Float (L.Intensity) * Atten));
      end Term;
   begin
      case L.Kind is
         when Ambient =>
            return Ch (Mat.Ambient_Color, To_F (L.Color), Clamp (Long_Float (Mat.Ambient_Coeff) * Long_Float (L.Intensity)));
         when Directional =>
            return Term (Unit (V (-Long_Float (L.Direction.X), -Long_Float (L.Direction.Y), -Long_Float (L.Direction.Z))), 1.0);
         when Point_Light | Spot_Light =>
            declare
               To_L : constant Vector_3D :=
                 V (Long_Float (L.Position.X) - Long_Float (Pos.X), Long_Float (L.Position.Y) - Long_Float (Pos.Y),
                    Long_Float (L.Position.Z) - Long_Float (Pos.Z));
               D : constant Long_Float := Mag (To_L);
               N : constant Natural := (case L.Falloff.Kind is when None => 0, when Linear => 1, when Quadratic => 2,
                                        when Custom_Power => Natural (Long_Float (L.Falloff.Power)));
               Atten : constant Long_Float := (if D = 0.0 or else N = 0 then 1.0 else 1.0 / (1.0 + Ref_Pow (D, N)));
            begin
               if L.Kind = Point_Light then
                  return (if D = 0.0 then [others => 0.0] else Term (Unit (To_L), Atten));
               else
                  declare
                     Cos_A : constant Long_Float := Dot (V (-Long_Float (Unit (To_L).X), -Long_Float (Unit (To_L).Y),
                                                            -Long_Float (Unit (To_L).Z)), Unit (L.Direction));
                     --  inside the cone: the angle itself (arccos) is at most
                     --  the cutoff angle
                     Angle_Deg : constant Long_Float :=
                       Ada.Numerics.Long_Elementary_Functions.Arccos (Long_Float'Max (-1.0, Long_Float'Min (1.0, Cos_A)))
                       * 180.0 / Ada.Numerics.Pi;
                  begin
                     if D = 0.0 or else Angle_Deg > Long_Float (L.Spot_Cone_Angle_Deg) or else Cos_A <= 0.0 then
                        return [others => 0.0];
                     end if;
                     return Term (Unit (To_L), Atten * Ada.Numerics.Long_Elementary_Functions."**" (Cos_A, Long_Float (L.Spot_Dropoff_Exp)));
                  end;
               end if;
            end;
      end case;
   end Ref_Light;

   function Sum_Lights (Pos, Normal, View : Vector_3D; Mat : Material; Ls : Light_Array) return FCol is
      S : FCol := [others => 0.0];
   begin
      for L of Ls loop
         S := Add (S, Ref_Light (Pos, Normal, View, Mat, L));
      end loop;
      return S;
   end Sum_Lights;

   procedure Check_Light (Pos, Normal, View : Vector_3D; Mat : Material; Ls : Light_Array; What : String) is
      Got : constant Color_RGB := Evaluate_Lighting (Pos, Normal, View, Mat, Ls);
   begin
      Expect (Same (Got, Sum_Lights (Pos, Normal, View, Mat, Ls)), What);
   end Check_Light;

   function Rand_Vec (Lo, Hi : Long_Float) return Vector_3D is (V (Rnd (Lo, Hi), Rnd (Lo, Hi), Rnd (Lo, Hi)));

   function Rand_Unit return Vector_3D is
      A : Vector_3D;
   begin
      loop
         A := Rand_Vec (-1.0, 1.0);
         exit when Mag (A) > 0.1;
      end loop;
      return Unit (A);
   end Rand_Unit;

   function Rand_Color return Color_RGB is (Make_Color (Real (Rnd (0.0, 1.0)), Real (Rnd (0.0, 1.0)), Real (Rnd (0.0, 1.0))));

   function Rand_Mat return Material is
     ((Ambient_Color => Rand_Color, Diffuse_Color => Rand_Color, Specular_Color => Rand_Color,
       Ambient_Coeff => Intensity_Value (Rnd (0.0, 1.0)), Diffuse_Coeff => Intensity_Value (Rnd (0.0, 1.0)),
       Specular_Coeff => Intensity_Value (Rnd (0.0, 1.0)), Shininess => Shininess_Value (1.0 + Rnd (0.0, 30.0))));

   function Rand_Light (K : Light_Kind) return Light_Source is
      Ks : constant array (0 .. 3) of Falloff_Kind := [None, Linear, Quadratic, Custom_Power];
   begin
      return (Kind => K, Color => Rand_Color, Intensity => Intensity_Value (Rnd (0.1, 1.0)),
              Position => Rand_Vec (-3.0, 3.0), Direction => Rand_Unit,
              Falloff => (Kind => Ks (Rand (4)), Power => Falloff_Power (Long_Float (Rand (5)))),
              Spot_Cone_Angle_Deg => Real (10.0 + Rnd (0.0, 70.0)),
              Spot_Dropoff_Exp => Real (1.0 + Rnd (0.0, 4.0)));
   end Rand_Light;

   function Face_Normal (T : Triangle) return Vector_3D is
     (Unit (Cross (V (Long_Float (T.V1.Position.X) - Long_Float (T.V0.Position.X),
                      Long_Float (T.V1.Position.Y) - Long_Float (T.V0.Position.Y),
                      Long_Float (T.V1.Position.Z) - Long_Float (T.V0.Position.Z)),
                   V (Long_Float (T.V2.Position.X) - Long_Float (T.V0.Position.X),
                      Long_Float (T.V2.Position.Y) - Long_Float (T.V0.Position.Y),
                      Long_Float (T.V2.Position.Z) - Long_Float (T.V0.Position.Z)))));

   function Centroid (T : Triangle) return Vector_3D is
     (V ((Long_Float (T.V0.Position.X) + Long_Float (T.V1.Position.X) + Long_Float (T.V2.Position.X)) / 3.0,
         (Long_Float (T.V0.Position.Y) + Long_Float (T.V1.Position.Y) + Long_Float (T.V2.Position.Y)) / 3.0,
         (Long_Float (T.V0.Position.Z) + Long_Float (T.V1.Position.Z) + Long_Float (T.V2.Position.Z)) / 3.0));

   function Interp (A, B, C : Vector_3D; U, Vw, W : Long_Float) return Vector_3D is
     (V (U * Long_Float (A.X) + Vw * Long_Float (B.X) + W * Long_Float (C.X),
         U * Long_Float (A.Y) + Vw * Long_Float (B.Y) + W * Long_Float (C.Y),
         U * Long_Float (A.Z) + Vw * Long_Float (B.Z) + W * Long_Float (C.Z)));

   function Rand_Triangle return Triangle is
      function Vert return Vertex is (Vertex'(Position => Rand_Vec (-2.0, 2.0), Normal => Rand_Unit, Color => Rand_Color));
   begin
      return (Vert, Vert, Vert);
   end Rand_Triangle;

begin
   --  vector identities
   for I in 1 .. 200 loop
      declare
         A : constant Vector_3D := Rand_Vec (-5.0, 5.0);
         B : constant Vector_3D := Rand_Vec (-5.0, 5.0);
         C : constant Vector_3D := Cross (A, B);
      begin
         Expect (Close (Long_Float (Dot_Product (A, B)), Dot (A, B)), "dot product");
         Expect (Close (Long_Float (Cross_Product (A, B).X), Long_Float (C.X))
                 and then Close (Long_Float (Cross_Product (A, B).Y), Long_Float (C.Y))
                 and then Close (Long_Float (Cross_Product (A, B).Z), Long_Float (C.Z)), "cross product");
         Expect (Close (Long_Float (Dot_Product (C, A)), 0.0, 1.0E-9) and then Close (Long_Float (Dot_Product (C, B)), 0.0, 1.0E-9),
                 "cross product perpendicular to both");
         --  a x (b x c) = b (a.c) - c (a.b)
         declare
            T : constant Vector_3D := Cross (A, Cross (B, C));
            W : constant Vector_3D :=
              V (Long_Float (B.X) * Dot (A, C) - Long_Float (C.X) * Dot (A, B),
                 Long_Float (B.Y) * Dot (A, C) - Long_Float (C.Y) * Dot (A, B),
                 Long_Float (B.Z) * Dot (A, C) - Long_Float (C.Z) * Dot (A, B));
         begin
            Expect (Close (Long_Float (T.X), Long_Float (W.X), 1.0E-8)
                    and then Close (Long_Float (T.Y), Long_Float (W.Y), 1.0E-8)
                    and then Close (Long_Float (T.Z), Long_Float (W.Z), 1.0E-8), "vector triple product");
         end;
         if Mag (A) > 0.01 then
            declare
               U : constant Vector_3D := Normalize (A);
            begin
               Expect (Close (Mag (U), 1.0, 1.0E-9), "normalized length");
               Expect (Close (Long_Float (Magnitude (A)), Mag (A), 1.0E-9), "magnitude");
            end;
         end if;
      end;
   end loop;

   --  falloff
   for I in 1 .. 100 loop
      declare
         D : constant Long_Float := Rnd (0.0, 6.0);
         P : constant Natural := Rand (9);
         Ks : constant array (0 .. 3) of Falloff_Kind := [None, Linear, Quadratic, Custom_Power];
         F : constant Distance_Falloff := (Kind => Ks (Rand (4)), Power => Falloff_Power (Long_Float (P)));
         N : constant Natural := (case F.Kind is when None => 0, when Linear => 1, when Quadratic => 2, when Custom_Power => P);
         --  the code treats power 0 and distance 0 as no falloff (1.0)
         Want : constant Long_Float :=
           (if N = 0 or else D = 0.0 then 1.0 else 1.0 / (1.0 + Ref_Pow (D, N)));
      begin
         Expect (Close (Long_Float (Compute_Falloff (Real (D), F)), Want, 1.0E-9), "falloff" & F.Kind'Image);
      end;
   end loop;

   --  lighting, one kind at a time, then mixtures
   for K in Light_Kind loop
      for I in 1 .. 40 loop
         Check_Light (Rand_Vec (-2.0, 2.0), Rand_Unit, Rand_Vec (-4.0, 4.0), Rand_Mat, [1 => Rand_Light (K)],
                      "one " & K'Image);
      end loop;
   end loop;
   for I in 1 .. 40 loop
      declare
         Ls : Light_Array (1 .. 1 + Rand (4));
      begin
         for J in Ls'Range loop
            Ls (J) := Rand_Light (Light_Kind'Val (Rand (4)));
         end loop;
         Check_Light (Rand_Vec (-2.0, 2.0), Rand_Unit, Rand_Vec (-4.0, 4.0), Rand_Mat, Ls, "mixture");
      end;
   end loop;
   Check_Light ((0.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 0.0, 5.0), Rand_Mat, [1 .. 0 => <>], "no lights");

   --  the four variants
   for I in 1 .. 30 loop
      declare
         T  : constant Triangle := Rand_Triangle;
         M  : constant Material := Rand_Mat;
         Ls : Light_Array (1 .. 1 + Rand (3));
         View : constant Vector_3D := Rand_Vec (-4.0, 4.0);
         U : constant Long_Float := Rnd (0.05, 0.6);
         Vw : constant Long_Float := Rnd (0.05, 0.3);
         W : constant Long_Float := 1.0 - U - Vw;
         Wt : constant Barycentric_Weights := Make_Barycentric (Real (U), Real (Vw), Real (W));
      begin
         for J in Ls'Range loop
            Ls (J) := Rand_Light (Light_Kind'Val (Rand (4)));
         end loop;
         Expect (Same (Shade_Flat (T, M, View, Ls), Sum_Lights (Centroid (T), Face_Normal (T), View, M, Ls)), "flat = model at centroid");
         Expect (Same (Shade_Gouraud (T, M, Wt, View, Ls),
                       [for K in 1 .. 3 =>
                          U * To_F (Evaluate_Lighting (T.V0.Position, T.V0.Normal, View, M, Ls)) (K)
                          + Vw * To_F (Evaluate_Lighting (T.V1.Position, T.V1.Normal, View, M, Ls)) (K)
                          + W * To_F (Evaluate_Lighting (T.V2.Position, T.V2.Normal, View, M, Ls)) (K)]),
                 "Gouraud = interpolated vertex colors");
         declare
            P : constant Vector_3D := Interp (T.V0.Position, T.V1.Position, T.V2.Position, U, Vw, W);
            N : constant Vector_3D := Unit (Interp (T.V0.Normal, T.V1.Normal, T.V2.Normal, U, Vw, W));
         begin
            Expect (Same (Shade_Phong (T, M, Wt, View, Ls), Sum_Lights (P, N, View, M, Ls)), "Phong = model at interpolated normal");
         end;
         declare
            Buf : G_Buffer (2 .. 3, 5 .. 6) := [others => [others => <>]];
            FB : Framebuffer (2 .. 3, 5 .. 6);
            Depths : constant array (1 .. 3) of Long_Float := [Rnd (0.1, 5.0), Rnd (0.1, 5.0), Rnd (0.1, 5.0)];
            Mats   : constant array (1 .. 3) of Material := [Rand_Mat, Rand_Mat, Rand_Mat];
            Poss   : constant array (1 .. 3) of Vector_3D := [Rand_Vec (-2.0, 2.0), Rand_Vec (-2.0, 2.0), Rand_Vec (-2.0, 2.0)];
            Norms  : constant array (1 .. 3) of Vector_3D := [Rand_Unit, Rand_Unit, Rand_Unit];
            Best : Natural := 1;
         begin
            for K in 1 .. 3 loop
               Deferred_Geometry_Pass (Buf, 2, 5, Poss (K), Norms (K), Mats (K), Real (Depths (K)));
               if Depths (K) < Depths (Best) then
                  Best := K;
               end if;
            end loop;
            Expect (Buf (2, 5).Valid and then Close (Long_Float (Buf (2, 5).Depth), Depths (Best), 1.0E-12),
                    "geometry pass keeps the closest fragment");
            Deferred_Lighting_Pass (Buf, FB, View, Ls);
            declare
               Pix : constant G_Buffer_Pixel := Buf (2, 5);
               PM  : constant Material :=
                 (Ambient_Color => Pix.Albedo, Diffuse_Color => Pix.Albedo, Specular_Color => White,
                  Ambient_Coeff => Pix.Ambient_Amt, Diffuse_Coeff => 0.8, Specular_Coeff => Pix.Specular_Amt,
                  Shininess => Pix.Shininess);
            begin
               Expect (Same (FB (2, 5), Sum_Lights (Pix.Position, Pix.Normal, View, PM, Ls)), "deferred lighting = the model");
               --  deferred shading defers the same lighting: the result must
               --  equal forward shading of the closest fragment with its
               --  own material
               Expect (Same (FB (2, 5), Sum_Lights (Poss (Best), Norms (Best), View, Mats (Best), Ls)),
                       "deferred = forward shading of the closest fragment");
               Expect (FB (2, 6) = Black and then FB (3, 5) = Black and then FB (3, 6) = Black, "unwritten pixels stay black");
            end;
         end;
      end;
   end loop;

   --  colors, barycentric weights, reflection, face normal
   for I in 1 .. 200 loop
      declare
         A : constant Color_RGB := Rand_Color;
         B : constant Color_RGB := Rand_Color;
         F : constant Long_Float := Rnd (0.0, 1.0);
         X : constant Long_Float := Rnd (-0.5, 1.5);
      begin
         Expect (Same (Add_Colors (A, B), Add (To_F (A), To_F (B)), 1.0E-12), "Add_Colors saturates at 1");
         Expect (Same (Modulate_Colors (A, B), [for K in 1 .. 3 => To_F (A) (K) * To_F (B) (K)], 1.0E-12), "Modulate_Colors");
         Expect (Same (Scale_Color (A, Intensity_Value (F)), [for K in 1 .. 3 => To_F (A) (K) * F], 1.0E-12), "Scale_Color");
         Expect (Same (Make_Color (Real (X), Real (1.0 - X), Real (X - 0.5)), [X, 1.0 - X, X - 0.5], 1.0E-12), "Make_Color clamps");
      end;
   end loop;
   for I in 1 .. 200 loop
      declare
         U : constant Long_Float := Rnd (0.0, 3.0);
         Vw : constant Long_Float := Rnd (0.0, 3.0);
         W : constant Long_Float := (if I mod 10 = 0 then 0.0 else Rnd (0.0, 3.0));
         S : constant Long_Float := U + Vw + W;
      begin
         if S > 0.0 then
            declare
               B : constant Barycentric_Weights := Make_Barycentric (Real (U), Real (Vw), Real (W));
               P : constant Vector_3D := Rand_Vec (-3.0, 3.0);
               Q : constant Vector_3D := Rand_Vec (-3.0, 3.0);
               R : constant Vector_3D := Rand_Vec (-3.0, 3.0);
               Got : constant Vector_3D := Interpolate_Vector (P, Q, R, B);
               Want : constant Vector_3D := Interp (P, Q, R, U / S, Vw / S, W / S);
               CA : constant Color_RGB := Rand_Color;
               CB : constant Color_RGB := Rand_Color;
               CC : constant Color_RGB := Rand_Color;
            begin
               Expect (Close (Long_Float (B.U), U / S, 1.0E-12) and then Close (Long_Float (B.V), Vw / S, 1.0E-12)
                       and then Close (Long_Float (B.W), W / S, 1.0E-12), "Make_Barycentric normalizes");
               Expect (Close (Long_Float (Got.X), Long_Float (Want.X), 1.0E-9) and then Close (Long_Float (Got.Y), Long_Float (Want.Y), 1.0E-9)
                       and then Close (Long_Float (Got.Z), Long_Float (Want.Z), 1.0E-9), "Interpolate_Vector");
               Expect (Same (Interpolate_Color (CA, CB, CC, B),
                             [for K in 1 .. 3 => U / S * To_F (CA) (K) + Vw / S * To_F (CB) (K) + W / S * To_F (CC) (K)], 1.0E-9),
                       "Interpolate_Color");
            end;
         end if;
      end;
   end loop;
   declare
      Raised : Boolean := False;
   begin
      declare
         B : constant Barycentric_Weights := Make_Barycentric (0.0, 0.0, 0.0);
      begin
         Expect (B.U < 0.0, "Make_Barycentric (0, 0, 0) returned");
      end;
   exception
      when Invalid_Weights_Error =>
         Raised := True;
         Expect (Raised, "zero weights raise Invalid_Weights_Error");
   end;
   for I in 1 .. 200 loop
      declare
         L : constant Vector_3D := Rand_Vec (-2.0, 2.0);
         N : constant Vector_3D := Rand_Vec (-2.0, 2.0);
      begin
         if Mag (N) > 0.05 then
            declare
               Nu : constant Vector_3D := Unit (N);
               R : constant Vector_3D := Reflect (L, N);
               D : constant Long_Float := Dot (Nu, L);
            begin
               Expect (Close (Long_Float (R.X), 2.0 * D * Long_Float (Nu.X) - Long_Float (L.X), 1.0E-9)
                       and then Close (Long_Float (R.Y), 2.0 * D * Long_Float (Nu.Y) - Long_Float (L.Y), 1.0E-9)
                       and then Close (Long_Float (R.Z), 2.0 * D * Long_Float (Nu.Z) - Long_Float (L.Z), 1.0E-9),
                       "Reflect = 2 (n.l) n - l with the unit normal");
               Expect (Close (Mag (R), Mag (L), 1.0E-9), "reflection keeps the length");
            end;
         end if;
      end;
   end loop;
   for I in 1 .. 100 loop
      declare
         T : constant Triangle := Rand_Triangle;
         E1 : constant Vector_3D := T.V1.Position - T.V0.Position;
         E2 : constant Vector_3D := T.V2.Position - T.V0.Position;
      begin
         if Mag (Cross (E1, E2)) > 0.01 then
            declare
               N : constant Vector_3D := Triangle_Face_Normal (T);
            begin
               Expect (Close (Mag (N), 1.0, 1.0E-9) and then Close (Dot (N, E1), 0.0, 1.0E-9) and then Close (Dot (N, E2), 0.0, 1.0E-9)
                       and then Dot (N, Cross (E1, E2)) > 0.0, "face normal: unit, perpendicular, right-handed");
            end;
         end if;
      end;
   end loop;
   declare
      Flat : constant Triangle :=
        ((Position => V (0.0, 0.0, 0.0), Normal => V (1.0, 0.0, 0.0), Color => White),
         (Position => V (1.0, 0.0, 0.0), Normal => V (-1.0, 0.0, 0.0), Color => White),
         (Position => V (0.0, 1.0, 0.0), Normal => V (0.0, 0.0, 1.0), Color => White));
      Lt : constant Light_Array := [1 => (Kind => Point_Light, Position => V (0.3, 0.2, 2.0), others => <>)];
      M  : constant Material := Rand_Mat;
      Collinear : constant Triangle :=
        ((Position => V (0.0, 0.0, 0.0), others => <>), (Position => V (1.0, 1.0, 1.0), others => <>),
         (Position => V (2.0, 2.0, 2.0), others => <>));
   begin
      --  weights (1/2, 1/2, 0): the vertex normals cancel, the face normal is used
      Expect (Same (Shade_Phong (Flat, M, Make_Barycentric (0.5, 0.5, 0.0), V (0.2, 0.3, 4.0), Lt),
                    Sum_Lights (V (0.5, 0.0, 0.0), V (0.0, 0.0, 1.0), V (0.2, 0.3, 4.0), M, Lt)),
              "Phong falls back to the face normal when the normals cancel");
      --  viewer at the surface point: view direction +Z
      Check_Light (V (0.1, 0.2, 0.0), V (0.0, 0.3, 1.0), V (0.1, 0.2, 0.0), M,
                   [1 => (Kind => Directional, Direction => V (0.2, -0.1, -1.0), others => <>)], "viewer at the point");
      begin
         Expect (Mag (Triangle_Face_Normal (Collinear)) < 0.0, "collinear triangle gave a normal");
      exception
         when Degenerate_Geometry_Error =>
            Expect (True, "collinear triangle raises Degenerate_Geometry_Error");
      end;
      begin
         Expect (Mag (Normalize (V (0.0, 0.0, 0.0))) < 0.0, "zero vector normalized");
      exception
         when Zero_Vector_Error =>
            Expect (True, "zero vector raises Zero_Vector_Error");
      end;
   end;

   Expect (Checked > 1_000, "enough checks:" & Checked'Image);
   if Failures > 0 then
      Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Put_Line ("PASS own checks:" & Checked'Image & " (Phong model, vector identities, falloff, four variants)");
end Own_Checks;
