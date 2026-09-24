with Ada.Numerics.Generic_Elementary_Functions;

package body Ray_Tracing is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   Epsilon : constant Real := 1.0e-4;

   function "+" (A, B : Vector3) return Vector3 is
   begin
      return (X => A.X + B.X, Y => A.Y + B.Y, Z => A.Z + B.Z);
   end "+";

   function "-" (A, B : Vector3) return Vector3 is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y, Z => A.Z - B.Z);
   end "-";

   function "-" (V : Vector3) return Vector3 is
   begin
      return (X => -V.X, Y => -V.Y, Z => -V.Z);
   end "-";

   function "*" (A : Vector3; S : Real) return Vector3 is
   begin
      return (X => A.X * S, Y => A.Y * S, Z => A.Z * S);
   end "*";

   function "*" (S : Real; A : Vector3) return Vector3 is
   begin
      return (X => A.X * S, Y => A.Y * S, Z => A.Z * S);
   end "*";

   function "/" (A : Vector3; S : Real) return Vector3 is
   begin
      if abs S < 1.0e-12 then
         raise Zero_Norm_Error;
      end if;
      return (X => A.X / S, Y => A.Y / S, Z => A.Z / S);
   end "/";

   function Dot (A, B : Vector3) return Real is
   begin
      return (A.X * B.X) + (A.Y * B.Y) + (A.Z * B.Z);
   end Dot;

   function Cross (A, B : Vector3) return Vector3 is
   begin
      return
        (X => (A.Y * B.Z) - (A.Z * B.Y),
         Y => (A.Z * B.X) - (A.X * B.Z),
         Z => (A.X * B.Y) - (A.Y * B.X));
   end Cross;

   function Length_Squared (V : Vector3) return Real is
   begin
      return Dot (V, V);
   end Length_Squared;

   function Length (V : Vector3) return Real is
   begin
      return Sqrt (Length_Squared (V));
   end Length;

   function Normalized (V : Vector3) return Vector3 is
      L : constant Real := Length (V);
   begin
      if L < 1.0e-12 then
         raise Zero_Norm_Error;
      end if;
      return V / L;
   end Normalized;

   function "+" (A, B : Color) return Color is
      R_Val : constant Real := Real'Min (1.0, A.R + B.R);
      G_Val : constant Real := Real'Min (1.0, A.G + B.G);
      B_Val : constant Real := Real'Min (1.0, A.B + B.B);
   begin
      return (R => R_Val, G => G_Val, B => B_Val);
   end "+";

   function "*" (A, B : Color) return Color is
   begin
      return
        (R => Real'Min (1.0, Real'Max (0.0, A.R * B.R)),
         G => Real'Min (1.0, Real'Max (0.0, A.G * B.G)),
         B => Real'Min (1.0, Real'Max (0.0, A.B * B.B)));
   end "*";

   function "*" (C : Color; S : Real) return Color is
      Factor : constant Real := Real'Max (0.0, S);
   begin
      return
        (R => Real'Min (1.0, C.R * Factor),
         G => Real'Min (1.0, C.G * Factor),
         B => Real'Min (1.0, C.B * Factor));
   end "*";

   function Clamp_Color (C : Color) return Color is
   begin
      return
        (R => Real'Min (1.0, Real'Max (0.0, C.R)),
         G => Real'Min (1.0, Real'Max (0.0, C.G)),
         B => Real'Min (1.0, Real'Max (0.0, C.B)));
   end Clamp_Color;

   procedure Add_Sphere
     (S      : in out Scene;
      Object : Sphere)
   is
   begin
      if S.Object_Count >= S.Objects'Length then
         raise Capacity_Error;
      end if;
      S.Object_Count := S.Object_Count + 1;
      S.Objects (S.Object_Count) := Object;
   end Add_Sphere;

   procedure Add_Light
     (S      : in out Scene;
      Source : Light)
   is
   begin
      if S.Light_Count >= S.Lights'Length then
         raise Capacity_Error;
      end if;
      S.Light_Count := S.Light_Count + 1;
      S.Lights (S.Light_Count) := Source;
   end Add_Light;

   function Intersect_Sphere
     (R : Ray;
      S : Sphere) return Hit_Record
   is
      Oc           : constant Vector3 := R.Origin - S.Center;
      A            : constant Real    := Dot (R.Direction, R.Direction);
      Half_B       : constant Real    := Dot (Oc, R.Direction);
      C            : constant Real    := Dot (Oc, Oc) - (S.Radius * S.Radius);
      Discriminant : constant Real    := (Half_B * Half_B) - (A * C);
      Result       : Hit_Record;
      Sq_D         : Real;
      Root         : Real;
   begin
      Result.Hit := False;
      if Discriminant < 0.0 then
         return Result;
      end if;

      Sq_D := Sqrt (Discriminant);
      Root := (-Half_B - Sq_D) / A;

      if Root < Epsilon then
         Root := (-Half_B + Sq_D) / A;
         if Root < Epsilon then
            return Result;
         end if;
      end if;

      Result.Hit      := True;
      Result.Distance := Root;
      Result.Point    := R.Origin + (R.Direction * Root);
      Result.Normal   := Normalized (Result.Point - S.Center);
      Result.Mat      := S.Mat;
      return Result;
   end Intersect_Sphere;

   function Closest_Intersection
     (S : Scene;
      R : Ray) return Hit_Record
   is
      Best_Hit : Hit_Record;
      Closest  : Real := Real'Last;
   begin
      Best_Hit.Hit := False;
      for I in 1 .. S.Object_Count loop
         declare
            Rec : constant Hit_Record := Intersect_Sphere (R, S.Objects (I));
         begin
            if Rec.Hit and then Rec.Distance < Closest then
               Closest  := Rec.Distance;
               Best_Hit := Rec;
            end if;
         end;
      end loop;
      return Best_Hit;
   end Closest_Intersection;

   function Reflect
     (V, N : Vector3) return Vector3
   is
   begin
      return V - (2.0 * Dot (V, N) * N);
   end Reflect;

   function Refract
     (V, N  : Vector3;
      Eta_I : Real;
      Eta_T : Real) return Vector3
   is
      Cos_Theta : Real := Dot (-V, N);
      Actual_N  : Vector3 := N;
      Eta       : Real;
      K         : Real;
   begin
      if Cos_Theta < 0.0 then
         Cos_Theta := -Cos_Theta;
         Actual_N  := -N;
         Eta       := Eta_T / Eta_I;
      else
         Eta       := Eta_I / Eta_T;
      end if;

      K := 1.0 - (Eta * Eta * (1.0 - (Cos_Theta * Cos_Theta)));
      if K < 0.0 then
         return Zero_Vector;
      else
         return (Eta * V) + (((Eta * Cos_Theta) - Sqrt (K)) * Actual_N);
      end if;
   end Refract;

   function In_Shadow
     (S         : Scene;
      Pt        : Vector3;
      Light_Pos : Vector3) return Boolean
   is
      Light_Dir : constant Vector3 := Light_Pos - Pt;
      Dist      : constant Real    := Length (Light_Dir);
      Shadow_R  : Ray;
   begin
      if Dist < Epsilon then
         return False;
      end if;

      Shadow_R.Origin    := Pt + (Normalized (Light_Dir) * Epsilon);
      Shadow_R.Direction := Normalized (Light_Dir);

      for I in 1 .. S.Object_Count loop
         declare
            Rec : constant Hit_Record :=
              Intersect_Sphere (Shadow_R, S.Objects (I));
         begin
            if Rec.Hit and then Rec.Distance < Dist then
               return True;
            end if;
         end;
      end loop;
      return False;
   end In_Shadow;

   function Shade_Direct
     (S        : Scene;
      Rec      : Hit_Record;
      View_Dir : Vector3) return Color
   is
      Shaded : Color := S.Ambient * Rec.Mat.Albedo;
   begin
      for I in 1 .. S.Light_Count loop
         declare
            L_Pos     : constant Vector3 := S.Lights (I).Position;
            L_Dir     : constant Vector3 := Normalized (L_Pos - Rec.Point);
            N_Dot_L   : constant Real    := Dot (Rec.Normal, L_Dir);
            Intensity : constant Color   := S.Lights (I).Intensity;
         begin
            if not In_Shadow (S, Rec.Point, L_Pos) and then N_Dot_L > 0.0 then
               declare
                  Diff : constant Color :=
                    (Rec.Mat.Albedo * Intensity) * N_Dot_L;
                  Refl_Dir : constant Vector3 := Reflect (-L_Dir, Rec.Normal);
                  R_Dot_V  : constant Real :=
                    Real'Max (0.0, Dot (Refl_Dir, View_Dir));
                  Spec_Val : constant Real :=
                    (if R_Dot_V > 0.0 and Rec.Mat.Shininess > 0.0
                     then R_Dot_V ** Integer (Rec.Mat.Shininess)
                     else 0.0);
                  Spec : constant Color :=
                    (White_Color * Intensity) * Spec_Val;
               begin
                  Shaded := Shaded + Diff + Spec;
               end;
            end if;
         end;
      end loop;
      return Shaded;
   end Shade_Direct;

   function Trace_Ray_Direct
     (S : Scene;
      R : Ray) return Color
   is
      Hit : constant Hit_Record := Closest_Intersection (S, R);
   begin
      if not Hit.Hit then
         return Black_Color;
      end if;
      return Shade_Direct (S, Hit, -Normalized (R.Direction));
   end Trace_Ray_Direct;

   function Trace_Ray_Whitted
     (S         : Scene;
      R         : Ray;
      Max_Depth : Natural := 4) return Color
   is
      Hit : constant Hit_Record := Closest_Intersection (S, R);
   begin
      if not Hit.Hit then
         return Black_Color;
      end if;

      declare
         Direct_Col : constant Color :=
           Shade_Direct (S, Hit, -Normalized (R.Direction));
      begin
         if Max_Depth = 0 then
            return Direct_Col;
         end if;

         case Hit.Mat.Kind is
            when Diffuse =>
               return Direct_Col;

            when Specular =>
               declare
                  Refl_Dir : constant Vector3 :=
                    Reflect (Normalized (R.Direction), Hit.Normal);
                  Refl_Ray : constant Ray :=
                    (Origin    => Hit.Point + (Refl_Dir * Epsilon),
                     Direction => Refl_Dir);
                  Refl_Col : constant Color :=
                    Trace_Ray_Whitted (S, Refl_Ray, Max_Depth - 1);
                  Factor   : constant Real  := Hit.Mat.Reflectivity;
               begin
                  return Direct_Col * (1.0 - Factor) + (Refl_Col * Factor);
               end;

            when Dielectric =>
               declare
                  Refl_Dir : constant Vector3 :=
                    Reflect (Normalized (R.Direction), Hit.Normal);
                  Refl_Ray : constant Ray :=
                    (Origin    => Hit.Point + (Refl_Dir * Epsilon),
                     Direction => Refl_Dir);
                  Refl_Col : constant Color :=
                    Trace_Ray_Whitted (S, Refl_Ray, Max_Depth - 1);

                  Refr_Dir : constant Vector3 :=
                    Refract
                      (Normalized (R.Direction), Hit.Normal, 1.0,
                       Hit.Mat.Refractive_Index);
               begin
                  if Length_Squared (Refr_Dir) < 1.0e-6 then
                     return Refl_Col;
                  else
                     declare
                        Refr_Ray : constant Ray :=
                          (Origin    => Hit.Point + (Refr_Dir * Epsilon),
                           Direction => Refr_Dir);
                        Refr_Col : constant Color :=
                          Trace_Ray_Whitted (S, Refr_Ray, Max_Depth - 1);
                     begin
                        return Refl_Col * 0.2 + Refr_Col * 0.8;
                     end;
                  end if;
               end;
         end case;
      end;
   end Trace_Ray_Whitted;

   function Trace_Ray_Distribution
     (S         : Scene;
      R         : Ray;
      Samples   : Positive := 4;
      Max_Depth : Natural  := 2) return Color
   is
      Hit : constant Hit_Record := Closest_Intersection (S, R);
   begin
      if not Hit.Hit then
         return Black_Color;
      end if;

      if Hit.Mat.Kind /= Specular or else Max_Depth = 0 then
         return Shade_Direct (S, Hit, -Normalized (R.Direction));
      end if;

      declare
         Base_Refl : constant Vector3 :=
           Reflect (Normalized (R.Direction), Hit.Normal);
         Roughness : constant Real := Real'Max (0.01, 1.0 / Hit.Mat.Shininess);
         Sum_R     : Real := 0.0;
         Sum_G     : Real := 0.0;
         Sum_B     : Real := 0.0;
         Direct_C  : constant Color :=
           Shade_Direct (S, Hit, -Normalized (R.Direction));
      begin
         for J in 1 .. Samples loop
            declare
               Offset_Scale : constant Real :=
                 (Real (J) - Real (Samples) / 2.0) * (Roughness / Real (Samples));
               Perturbed_Dir : constant Vector3 :=
                 Normalized (Base_Refl + (Offset_Scale * Hit.Normal));
               Sample_Ray : constant Ray :=
                 (Origin    => Hit.Point + (Perturbed_Dir * Epsilon),
                  Direction => Perturbed_Dir);
               Col : constant Color :=
                 Trace_Ray_Distribution
                   (S, Sample_Ray, Samples => 1, Max_Depth => Max_Depth - 1);
            begin
               Sum_R := Sum_R + Col.R;
               Sum_G := Sum_G + Col.G;
               Sum_B := Sum_B + Col.B;
            end;
         end loop;

         declare
            Avg_Col : constant Color :=
              (R => Sum_R / Real (Samples),
               G => Sum_G / Real (Samples),
               B => Sum_B / Real (Samples));
            Factor : constant Real := Hit.Mat.Reflectivity;
         begin
            return Direct_C * (1.0 - Factor) + (Avg_Col * Factor);
         end;
      end;
   end Trace_Ray_Distribution;

   procedure Render_Scene
     (S       : Scene;
      Width   : Positive;
      Height  : Positive;
      Buffer  : out Image_Buffer;
      Whitted : Boolean := True)
   is
      W_Real : constant Real := Real (Width);
      H_Real : constant Real := Real (Height);
   begin
      for Py in 1 .. Height loop
         for Px in 1 .. Width loop
            declare
               U : constant Real := ((Real (Px) - 0.5) / W_Real) * 2.0 - 1.0;
               V : constant Real := -(((Real (Py) - 0.5) / H_Real) * 2.0 - 1.0);
               Cam_Ray : constant Ray :=
                 (Origin    => (0.0, 0.0, 3.0),
                  Direction => Normalized ((U, V, -1.0)));
            begin
               if Whitted then
                  Buffer (Px, Py) := Trace_Ray_Whitted (S, Cam_Ray);
               else
                  Buffer (Px, Py) := Trace_Ray_Direct (S, Cam_Ray);
               end if;
            end;
         end loop;
      end loop;
   end Render_Scene;

end Ray_Tracing;
