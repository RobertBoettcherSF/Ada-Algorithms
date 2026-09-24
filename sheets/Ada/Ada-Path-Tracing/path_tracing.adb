--  Package body: Path_Tracing
--  Implements ray intersection, BRDF evaluation, and Monte Carlo estimators.

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

package body Path_Tracing is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   --  =========================================================================
   --  Vector Operators and Functions
   --  =========================================================================

   function "+" (Left, Right : Vector_3D) return Vector_3D is
     ((X => Left.X + Right.X,
       Y => Left.Y + Right.Y,
       Z => Left.Z + Right.Z));

   function "-" (Left, Right : Vector_3D) return Vector_3D is
     ((X => Left.X - Right.X,
       Y => Left.Y - Right.Y,
       Z => Left.Z - Right.Z));

   function "*" (Left : Vector_3D; Right : Real) return Vector_3D is
     ((X => Left.X * Right,
       Y => Left.Y * Right,
       Z => Left.Z * Right));

   function "/" (Left : Vector_3D; Right : Real) return Vector_3D is
   begin
      if abs (Right) < 1.0e-14 then
         raise Degenerate_Vector_Error with "Division by zero in vector division";
      end if;
      return (X => Left.X / Right,
              Y => Left.Y / Right,
              Z => Left.Z / Right);
   end "/";

   function Dot (Left, Right : Vector_3D) return Real is
     (Left.X * Right.X + Left.Y * Right.Y + Left.Z * Right.Z);

   function Cross (Left, Right : Vector_3D) return Vector_3D is
     ((X => Left.Y * Right.Z - Left.Z * Right.Y,
       Y => Left.Z * Right.X - Left.X * Right.Z,
       Z => Left.X * Right.Y - Left.Y * Right.X));

   function Length_Squared (V : Vector_3D) return Non_Negative_Real is
      Val : constant Real := Dot (V, V);
   begin
      if Val < 0.0 then
         return 0.0;
      else
         return Val;
      end if;
   end Length_Squared;

   function Length (V : Vector_3D) return Non_Negative_Real is
     (Sqrt (Length_Squared (V)));

   function Normalize (V : Vector_3D) return Vector_3D is
      Len : constant Non_Negative_Real := Length (V);
   begin
      if Len < 1.0e-14 then
         raise Degenerate_Vector_Error with "Cannot normalize vector with zero magnitude";
      end if;
      return V / Len;
   end Normalize;

   function Reflect (V, Normal : Vector_3D) return Vector_3D is
      N : constant Vector_3D := Normalize (Normal);
   begin
      return V - N * (2.0 * Dot (V, N));
   end Reflect;

   function Cosine_Sample_Hemisphere
     (Normal : Vector_3D;
      U1, U2 : Unit_Real) return Vector_3D
   is
      N : constant Vector_3D := Normalize (Normal);
      R : constant Real := Sqrt (U1);
      Theta : constant Real := 2.0 * Ada.Numerics.Pi * U2;
      X_Local : constant Real := R * Cos (Theta);
      Y_Local : constant Real := R * Sin (Theta);
      Z_Local : constant Real := Sqrt (Real'Max (0.0, 1.0 - U1));

      --  Construct an orthonormal basis around N
      Up : constant Vector_3D :=
        (if abs (N.X) > 0.9 then (X => 0.0, Y => 1.0, Z => 0.0)
         else (X => 1.0, Y => 0.0, Z => 0.0));
      Tangent : constant Vector_3D := Normalize (Cross (Up, N));
      Bitangent : constant Vector_3D := Cross (N, Tangent);

      Sample_Dir : constant Vector_3D :=
        (Tangent * X_Local) + (Bitangent * Y_Local) + (N * Z_Local);
   begin
      return Normalize (Sample_Dir);
   end Cosine_Sample_Hemisphere;

   --  =========================================================================
   --  Radiance Operations
   --  =========================================================================

   function "+" (Left, Right : Radiance) return Radiance is
     ((R => Left.R + Right.R,
       G => Left.G + Right.G,
       B => Left.B + Right.B));

   function "*" (Left, Right : Radiance) return Radiance is
     ((R => Left.R * Right.R,
       G => Left.G * Right.G,
       B => Left.B * Right.B));

   function "*" (Left : Radiance; Right : Color_RGB) return Radiance is
     ((R => Left.R * Real (Right.R),
       G => Left.G * Real (Right.G),
       B => Left.B * Real (Right.B)));

   function "*" (Left : Radiance; Right : Real) return Radiance is
     ((R => Left.R * Right,
       G => Left.G * Right,
       B => Left.B * Right));

   function "/" (Left : Radiance; Right : Real) return Radiance is
     ((R => Left.R / Right,
       G => Left.G / Right,
       B => Left.B / Right));

   function Clamp_Unit (Val : Real) return Unit_Real is
   begin
      if Val < 0.0 then
         return 0.0;
      elsif Val > 1.0 then
         return 1.0;
      else
         return Unit_Real (Val);
      end if;
   end Clamp_Unit;

   function To_Color (Rad : Radiance) return Color_RGB is
     ((R => Clamp_Unit (Rad.R),
       G => Clamp_Unit (Rad.G),
       B => Clamp_Unit (Rad.B)));

   --  =========================================================================
   --  Intersection Routines
   --  =========================================================================

   function Intersect_Sphere
     (R     : Ray;
      S     : Sphere;
      T_Min : Real;
      T_Max : Real) return Intersection_Record
   is
      Result : Intersection_Record;
      Oc     : constant Vector_3D :=
        Vector_3D (R.Origin) - Vector_3D (S.Center);
      A      : constant Real := Dot (R.Direction, R.Direction);
      Half_B : constant Real := Dot (Oc, R.Direction);
      C      : constant Real := Dot (Oc, Oc) - (S.Radius * S.Radius);
      Discr  : constant Real := (Half_B * Half_B) - (A * C);
   begin
      Result.Hit := False;

      if Discr < 0.0 then
         return Result;
      end if;

      declare
         Sq_Discr : constant Real := Sqrt (Discr);
         Root_1   : constant Real := (-Half_B - Sq_Discr) / A;
         Root_2   : constant Real := (-Half_B + Sq_Discr) / A;
         Root     : Real := 0.0;
      begin
         if Root_1 >= T_Min and then Root_1 <= T_Max then
            Root := Root_1;
         elsif Root_2 >= T_Min and then Root_2 <= T_Max then
            Root := Root_2;
         else
            return Result;
         end if;

         Result.Hit := True;
         Result.Distance := Root;
         Result.Point := Point_3D (Vector_3D (R.Origin) + (R.Direction * Root));
         Result.Normal := (Vector_3D (Result.Point) - Vector_3D (S.Center)) / S.Radius;
         Result.Mat := S.Mat;
         return Result;
      end;
   end Intersect_Sphere;

   function Intersect_Scene
     (R       : Ray;
      Objects : Sphere_Array;
      T_Min   : Real;
      T_Max   : Real) return Intersection_Record
   is
      Closest_Hit : Intersection_Record;
      Closest_Dist : Real := T_Max;
   begin
      Closest_Hit.Hit := False;

      for I in Objects'Range loop
         declare
            Hit_Rec : constant Intersection_Record :=
              Intersect_Sphere (R, Objects (I), T_Min, Closest_Dist);
         begin
            if Hit_Rec.Hit then
               Closest_Dist := Hit_Rec.Distance;
               Closest_Hit  := Hit_Rec;
            end if;
         end;
      end loop;

      return Closest_Hit;
   end Intersect_Scene;

   function Validate_Scene (Scene : Sphere_Array) return Boolean is
   begin
      if Scene'Length = 0 then
         return False;
      end if;

      for S of Scene loop
         if S.Radius <= 0.0 then
            return False;
         end if;
      end loop;

      return True;
   end Validate_Scene;

   --  =========================================================================
   --  Monte Carlo Integrators
   --  =========================================================================

   function Random_Unit
     (Gen : in out Ada.Numerics.Float_Random.Generator) return Unit_Real
   is
      Val : constant Float := Ada.Numerics.Float_Random.Random (Gen);
   begin
      return Clamp_Unit (Real (Val));
   end Random_Unit;

   --  Variant 1: Pure Monte Carlo Path Tracing
   function Trace_Pure_Path
     (R           : Ray;
      Scene       : Sphere_Array;
      Max_Depth   : Positive;
      Gen         : in out Ada.Numerics.Float_Random.Generator) return Radiance
   is
      Current_Ray        : Ray := R;
      Accumulated_Radiance : Radiance := (0.0, 0.0, 0.0);
      Throughput          : Radiance := (1.0, 1.0, 1.0);
   begin
      for Depth in 1 .. Max_Depth loop
         declare
            Hit_Rec : constant Intersection_Record :=
              Intersect_Scene (Current_Ray, Scene, 0.001, 1.0e6);
         begin
            if not Hit_Rec.Hit then
               exit;
            end if;

            --  Direct emission hit
            if Hit_Rec.Mat.Kind = Emissive then
               Accumulated_Radiance := Accumulated_Radiance +
                 (Throughput * Hit_Rec.Mat.Emission);
               exit;
            end if;

            if Hit_Rec.Mat.Kind = Diffuse then
               declare
                  U1 : constant Unit_Real := Random_Unit (Gen);
                  U2 : constant Unit_Real := Random_Unit (Gen);
                  New_Dir : constant Vector_3D :=
                    Cosine_Sample_Hemisphere (Hit_Rec.Normal, U1, U2);
               begin
                  Current_Ray := (Origin => Hit_Rec.Point, Direction => New_Dir);
                  Throughput  := Throughput * Hit_Rec.Mat.Albedo;
               end;
            elsif Hit_Rec.Mat.Kind = Specular then
               declare
                  Refl_Dir : constant Vector_3D :=
                    Reflect (Current_Ray.Direction, Hit_Rec.Normal);
               begin
                  Current_Ray := (Origin => Hit_Rec.Point, Direction => Refl_Dir);
                  Throughput  := Throughput * Hit_Rec.Mat.Albedo;
               end;
            end if;

            --  Early break if radiance throughput diminishes to zero
            if Throughput.R < 1.0e-5 and then
               Throughput.G < 1.0e-5 and then
               Throughput.B < 1.0e-5
            then
               exit;
            end if;
         end;
      end loop;

      return Accumulated_Radiance;
   end Trace_Pure_Path;

   --  Variant 2: Path Tracing with Next Event Estimation (Explicit Light Sampling)
   function Trace_Next_Event_Estimation
     (R           : Ray;
      Scene       : Sphere_Array;
      Max_Depth   : Positive;
      Gen         : in out Ada.Numerics.Float_Random.Generator) return Radiance
   is
      Current_Ray          : Ray := R;
      Accumulated_Radiance : Radiance := (0.0, 0.0, 0.0);
      Throughput           : Radiance := (1.0, 1.0, 1.0);
   begin
      for Depth in 1 .. Max_Depth loop
         declare
            Hit_Rec : constant Intersection_Record :=
              Intersect_Scene (Current_Ray, Scene, 0.001, 1.0e6);
         begin
            if not Hit_Rec.Hit then
               exit;
            end if;

            --  If hitting an emissive surface on camera ray, include emission
            if Hit_Rec.Mat.Kind = Emissive then
               if Depth = 1 then
                  Accumulated_Radiance := Accumulated_Radiance +
                    (Throughput * Hit_Rec.Mat.Emission);
               end if;
               exit;
            end if;

            --  Next Event Estimation: Sample direct illumination from all light sources
            for Obj of Scene loop
               if Obj.Mat.Kind = Emissive then
                  declare
                     --  Sample center of emissive sphere for direct shadow ray
                     To_Light    : constant Vector_3D :=
                       Vector_3D (Obj.Center) - Vector_3D (Hit_Rec.Point);
                     Dist_Sq     : constant Real := Length_Squared (To_Light);
                     Dist        : constant Real := Sqrt (Dist_Sq);
                     Light_Dir   : constant Vector_3D := To_Light / Dist;
                     Cos_Theta   : constant Real :=
                       Real'Max (0.0, Dot (Hit_Rec.Normal, Light_Dir));
                  begin
                     if Cos_Theta > 0.0 then
                        declare
                           Shadow_Ray : constant Ray :=
                             (Origin    => Hit_Rec.Point,
                              Direction => Light_Dir);
                           Shadow_Hit : constant Intersection_Record :=
                             Intersect_Scene (Shadow_Ray, Scene, 0.001, Dist - Obj.Radius - 0.001);
                        begin
                           if not Shadow_Hit.Hit then
                              --  Visibility unoccluded, accumulate direct lighting
                              declare
                                 Direct_Light : Radiance := Obj.Mat.Emission;
                              begin
                                 Direct_Light := Direct_Light * Hit_Rec.Mat.Albedo;
                                 Direct_Light := Direct_Light * Cos_Theta;
                                 Accumulated_Radiance :=
                                   Accumulated_Radiance + (Throughput * Direct_Light);
                              end;
                           end if;
                        end;
                     end if;
                  end;
               end if;
            end loop;

            --  Scatter indirect ray
            if Hit_Rec.Mat.Kind = Diffuse then
               declare
                  U1 : constant Unit_Real := Random_Unit (Gen);
                  U2 : constant Unit_Real := Random_Unit (Gen);
                  New_Dir : constant Vector_3D :=
                    Cosine_Sample_Hemisphere (Hit_Rec.Normal, U1, U2);
               begin
                  Current_Ray := (Origin => Hit_Rec.Point, Direction => New_Dir);
                  Throughput  := Throughput * Hit_Rec.Mat.Albedo;
               end;
            elsif Hit_Rec.Mat.Kind = Specular then
               declare
                  Refl_Dir : constant Vector_3D :=
                    Reflect (Current_Ray.Direction, Hit_Rec.Normal);
               begin
                  Current_Ray := (Origin => Hit_Rec.Point, Direction => Refl_Dir);
                  Throughput  := Throughput * Hit_Rec.Mat.Albedo;
               end;
            end if;

            if Throughput.R < 1.0e-5 and then
               Throughput.G < 1.0e-5 and then
               Throughput.B < 1.0e-5
            then
               exit;
            end if;
         end;
      end loop;

      return Accumulated_Radiance;
   end Trace_Next_Event_Estimation;

   --  Variant 3: Path Tracing with Russian Roulette Termination
   function Trace_Russian_Roulette
     (R             : Ray;
      Scene         : Sphere_Array;
      Survival_Prob : Unit_Real;
      Gen           : in out Ada.Numerics.Float_Random.Generator) return Radiance
   is
      Current_Ray          : Ray := R;
      Accumulated_Radiance : Radiance := (0.0, 0.0, 0.0);
      Throughput           : Radiance := (1.0, 1.0, 1.0);
      Max_Bounces          : constant Positive := 32;
   begin
      for Bounce in 1 .. Max_Bounces loop
         declare
            Hit_Rec : constant Intersection_Record :=
              Intersect_Scene (Current_Ray, Scene, 0.001, 1.0e6);
         begin
            if not Hit_Rec.Hit then
               exit;
            end if;

            if Hit_Rec.Mat.Kind = Emissive then
               Accumulated_Radiance := Accumulated_Radiance +
                 (Throughput * Hit_Rec.Mat.Emission);
               exit;
            end if;

            --  Russian Roulette termination test after the first bounce
            if Bounce > 1 then
               declare
                  Xi : constant Unit_Real := Random_Unit (Gen);
               begin
                  if Xi > Survival_Prob then
                     exit;
                  end if;
                  --  Weight throughput by reciprocal of survival probability
                  Throughput := Throughput / Real (Survival_Prob);
               end;
            end if;

            if Hit_Rec.Mat.Kind = Diffuse then
               declare
                  U1 : constant Unit_Real := Random_Unit (Gen);
                  U2 : constant Unit_Real := Random_Unit (Gen);
                  New_Dir : constant Vector_3D :=
                    Cosine_Sample_Hemisphere (Hit_Rec.Normal, U1, U2);
               begin
                  Current_Ray := (Origin => Hit_Rec.Point, Direction => New_Dir);
                  Throughput  := Throughput * Hit_Rec.Mat.Albedo;
               end;
            elsif Hit_Rec.Mat.Kind = Specular then
               declare
                  Refl_Dir : constant Vector_3D :=
                    Reflect (Current_Ray.Direction, Hit_Rec.Normal);
               begin
                  Current_Ray := (Origin => Hit_Rec.Point, Direction => Refl_Dir);
                  Throughput  := Throughput * Hit_Rec.Mat.Albedo;
               end;
            end if;
         end;
      end loop;

      return Accumulated_Radiance;
   end Trace_Russian_Roulette;

   --  Unified dispatch function
   function Trace_Ray
     (R       : Ray;
      Scene   : Sphere_Array;
      Options : Rendering_Options;
      Gen     : in out Ada.Numerics.Float_Random.Generator) return Radiance
   is
      Total_Rad : Radiance := (0.0, 0.0, 0.0);
   begin
      if not Validate_Scene (Scene) then
         raise Invalid_Scene_Error with "Scene validation failed: contains invalid geometries";
      end if;

      for Sample in 1 .. Options.Samples_Per_Pixel loop
         declare
            Sample_Rad : Radiance;
         begin
            case Options.Mode is
               when Pure_Path_Tracing =>
                  Sample_Rad := Trace_Pure_Path
                    (R, Scene, Options.Max_Depth, Gen);
               when Next_Event_Estimation =>
                  Sample_Rad := Trace_Next_Event_Estimation
                    (R, Scene, Options.Max_Depth, Gen);
               when Russian_Roulette =>
                  Sample_Rad := Trace_Russian_Roulette
                    (R, Scene, Options.Russian_Roulette_Prob, Gen);
            end case;

            Total_Rad := Total_Rad + Sample_Rad;
         end;
      end loop;

      return Total_Rad / Real (Options.Samples_Per_Pixel);
   end Trace_Ray;

end Path_Tracing;
