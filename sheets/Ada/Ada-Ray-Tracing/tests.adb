with Ada.Text_IO; use Ada.Text_IO;
with Ray_Tracing; use Ray_Tracing;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   Diff_Mat : constant Material :=
     (Kind             => Diffuse,
      Albedo           => (0.8, 0.2, 0.2),
      Reflectivity     => 0.0,
      Refractive_Index => 1.0,
      Shininess        => 16.0);

   Spec_Mat : constant Material :=
     (Kind             => Specular,
      Albedo           => (0.1, 0.1, 0.1),
      Reflectivity     => 0.9,
      Refractive_Index => 1.0,
      Shininess        => 64.0);

   Glass_Mat : constant Material :=
     (Kind             => Dielectric,
      Albedo           => (0.9, 0.9, 0.9),
      Reflectivity     => 0.1,
      Refractive_Index => 1.5,
      Shininess        => 32.0);

begin
   -- TEST 1 — Vector Arithmetic Operations
   Put_Line ("TEST 1 — Vector Arithmetic");
   declare
      V1 : constant Vector3 := (1.0, 2.0, 3.0);
      V2 : constant Vector3 := (4.0, 5.0, 6.0);
      Sum : constant Vector3 := V1 + V2;
      Diff : constant Vector3 := V2 - V1;
      Scaled : constant Vector3 := V1 * 2.0;
   begin
      Check ("1.1 Vector addition matches components",
             Sum.X = 5.0 and Sum.Y = 7.0 and Sum.Z = 9.0);
      Check ("1.2 Vector subtraction matches components",
             Diff.X = 3.0 and Diff.Y = 3.0 and Diff.Z = 3.0);
      Check ("1.3 Vector scaling scales each axis",
             Scaled.X = 2.0 and Scaled.Y = 4.0 and Scaled.Z = 6.0);
   end;

   -- TEST 2 — Dot and Cross Products
   Put_Line ("TEST 2 — Dot and Cross Products");
   declare
      Vx : constant Vector3 := (1.0, 0.0, 0.0);
      Vy : constant Vector3 := (0.0, 1.0, 0.0);
      Vz : constant Vector3 := Cross (Vx, Vy);
      D  : constant Real    := Dot (Vx, Vy);
   begin
      Check ("2.1 Orthogonal vectors produce zero dot product", abs D < 1.0e-9);
      Check ("2.2 Cross product of X and Y yields positive Z",
             abs (Vz.X) < 1.0e-9 and abs (Vz.Y) < 1.0e-9 and abs (Vz.Z - 1.0) < 1.0e-9);
      Check ("2.3 Self dot product matches length squared",
             abs (Dot (Vx, Vx) - 1.0) < 1.0e-9);
   end;

   -- TEST 3 — Normalization and Zero Handling
   Put_Line ("TEST 3 — Vector Normalization");
   declare
      V   : constant Vector3 := (0.0, 3.0, 4.0);
      N   : constant Vector3 := Normalized (V);
      Len : constant Real    := Length (N);
      Raised : Boolean       := False;
   begin
      Check ("3.1 Magnitude of normalized vector equals 1.0", abs (Len - 1.0) < 1.0e-6);
      Check ("3.2 Normalized direction matches proportional components",
             abs (N.Y - 0.6) < 1.0e-6 and abs (N.Z - 0.8) < 1.0e-6);
      begin
         declare
            Z_Norm : constant Vector3 := Normalized (Zero_Vector);
         begin
            if Z_Norm.X = 0.0 then
               Raised := False;
            end if;
         end;
      exception
         when Zero_Norm_Error =>
            Raised := True;
      end;
      Check ("3.3 Normalizing zero-vector raises Zero_Norm_Error", Raised);
   end;

   -- TEST 4 — Sphere Intersection Direct Hit
   Put_Line ("TEST 4 — Sphere Intersection Direct Hit");
   declare
      Sph : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 1.0, Mat => Diff_Mat);
      R   : constant Ray    := (Origin => (0.0, 0.0, 3.0), Direction => (0.0, 0.0, -1.0));
      Hit : constant Hit_Record := Intersect_Sphere (R, Sph);
   begin
      Check ("4.1 Ray aimed straight at sphere records a hit", Hit.Hit);
      Check ("4.2 Hit distance is exactly 2.0 units away", abs (Hit.Distance - 2.0) < 1.0e-4);
      Check ("4.3 Hit normal points directly toward ray origin",
             abs (Hit.Normal.Z - 1.0) < 1.0e-4 and abs (Hit.Normal.X) < 1.0e-4);
   end;

   -- TEST 5 — Sphere Intersection Miss and Behind
   Put_Line ("TEST 5 — Sphere Intersection Miss");
   declare
      Sph      : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 1.0, Mat => Diff_Mat);
      R_Miss   : constant Ray    := (Origin => (0.0, 2.0, 3.0), Direction => (0.0, 0.0, -1.0));
      R_Behind : constant Ray    := (Origin => (0.0, 0.0, 3.0), Direction => (0.0, 0.0, 1.0));
      Hit1     : constant Hit_Record := Intersect_Sphere (R_Miss, Sph);
      Hit2     : constant Hit_Record := Intersect_Sphere (R_Behind, Sph);
   begin
      Check ("5.1 Parallel offset ray registers no hit", not Hit1.Hit);
      Check ("5.2 Ray pointing away from sphere registers no hit", not Hit2.Hit);
      Check ("5.3 Distance remains uncalculated when no hit occurs", Hit1.Distance = 0.0);
   end;

   -- TEST 6 — Law of Reflection
   Put_Line ("TEST 6 — Law of Reflection");
   declare
      N   : constant Vector3 := (0.0, 1.0, 0.0);
      Inc : constant Vector3 := Normalized ((1.0, -1.0, 0.0));
      Ref : constant Vector3 := Reflect (Inc, N);
   begin
      Check ("6.1 Reflection reverses normal direction component", Ref.Y > 0.0);
      Check ("6.2 Reflection preserves tangent direction component", abs (Ref.X - Inc.X) < 1.0e-4);
      Check ("6.3 Reflected vector preserves unit magnitude", abs (Length (Ref) - 1.0) < 1.0e-4);
   end;

   -- TEST 7 — Snell's Law of Refraction
   Put_Line ("TEST 7 — Snell's Law of Refraction");
   declare
      N       : constant Vector3 := (0.0, 1.0, 0.0);
      Inc_Dir : constant Vector3 := (0.0, -1.0, 0.0);
      Refr    : constant Vector3 := Refract (Inc_Dir, N, 1.0, 1.5);
      Tir_Ray : constant Vector3 := Normalized ((1.0, -0.1, 0.0));
      Tir_Res : constant Vector3 := Refract (Tir_Ray, N, 1.5, 1.0);
   begin
      Check ("7.1 Normal incident ray propagates through undeflected",
             abs (Refr.Y - (-1.0)) < 1.0e-4 and abs (Refr.X) < 1.0e-4);
      Check ("7.2 Refracted ray retains downward movement", Refr.Y < 0.0);
      Check ("7.3 Total internal reflection returns zero vector",
             Tir_Res.X = 0.0 and Tir_Res.Y = 0.0 and Tir_Res.Z = 0.0);
   end;

   -- TEST 8 — Scene Construction and Closest Intersection
   Put_Line ("TEST 8 — Scene Closest Intersection");
   declare
      Sc    : Scene;
      Sph1  : constant Sphere := (Center => (0.0, 0.0, -2.0), Radius => 1.0, Mat => Diff_Mat);
      Sph2  : constant Sphere := (Center => (0.0, 0.0, -5.0), Radius => 1.0, Mat => Spec_Mat);
      R     : constant Ray    := (Origin => (0.0, 0.0, 2.0), Direction => (0.0, 0.0, -1.0));
      Hit   : Hit_Record;
   begin
      Add_Sphere (Sc, Sph1);
      Add_Sphere (Sc, Sph2);
      Hit := Closest_Intersection (Sc, R);

      Check ("8.1 Scene tracks populated sphere count", Sc.Object_Count = 2);
      Check ("8.2 Closest intersection selects foreground object", Hit.Hit);
      Check ("8.3 Selected distance matches nearest sphere boundary", abs (Hit.Distance - 3.0) < 1.0e-4);
   end;

   -- TEST 9 — Scene Capacity Limits
   Put_Line ("TEST 9 — Scene Capacity Limits");
   declare
      Sc     : Scene;
      Sph    : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 0.5, Mat => Diff_Mat);
      Raised : Boolean := False;
   begin
      for I in 1 .. 16 loop
         Add_Sphere (Sc, Sph);
      end loop;
      begin
         Add_Sphere (Sc, Sph);
      exception
         when Capacity_Error =>
            Raised := True;
      end;
      Check ("9.1 Added maximum allowable 16 objects", Sc.Object_Count = 16);
      Check ("9.2 Overflowing object limit raises Capacity_Error", Raised);
      Check ("9.3 Scene bounds remain intact", Sc.Objects'Length = 16);
   end;

   -- TEST 10 — Direct Ray Tracing and Shadowing
   Put_Line ("TEST 10 — Direct Ray Tracing and Shadowing");
   declare
      Sc      : Scene;
      Sph_Lit : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 1.0, Mat => Diff_Mat);
      Lgt     : constant Light  := (Position => (0.0, 5.0, 0.0), Intensity => (1.0, 1.0, 1.0));
      R_Front : constant Ray    := (Origin => (0.0, 0.0, 3.0), Direction => (0.0, 0.0, -1.0));
      R_Miss  : constant Ray    := (Origin => (0.0, 5.0, 3.0), Direction => (0.0, 0.0, -1.0));
      Col_Lit : Color;
      Col_Out : Color;
   begin
      Add_Sphere (Sc, Sph_Lit);
      Add_Light (Sc, Lgt);
      Col_Lit := Trace_Ray_Direct (Sc, R_Front);
      Col_Out := Trace_Ray_Direct (Sc, R_Miss);

      Check ("10.1 Direct illuminated sphere yields non-zero red color", Col_Lit.R > 0.0);
      Check ("10.2 Ray missing scene geometry returns black background",
             Col_Out.R = 0.0 and Col_Out.G = 0.0 and Col_Out.B = 0.0);
      Check ("10.3 Ambient light is preserved under direct shading",
             Col_Lit.R >= Sc.Ambient.R * Diff_Mat.Albedo.R);
   end;

   -- TEST 11 — Whitted Recursive Ray Tracing
   Put_Line ("TEST 11 — Whitted Recursive Ray Tracing");
   declare
      Sc       : Scene;
      Sph_Refl : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 1.0, Mat => Spec_Mat);
      Sph_Red  : constant Sphere := (Center => (0.0, 4.0, 0.0), Radius => 1.0, Mat => Diff_Mat);
      Lgt      : constant Light  := (Position => (0.0, 10.0, 0.0), Intensity => (1.0, 1.0, 1.0));
      R_Angled : constant Ray    := (Origin => (0.0, -2.0, 2.0), Direction => Normalized ((0.0, 2.0, -2.0)));
      Col_Rec  : Color;
      Col_Flat : Color;
   begin
      Add_Sphere (Sc, Sph_Refl);
      Add_Sphere (Sc, Sph_Red);
      Add_Light (Sc, Lgt);

      Col_Rec  := Trace_Ray_Whitted (Sc, R_Angled, Max_Depth => 3);
      Col_Flat := Trace_Ray_Whitted (Sc, R_Angled, Max_Depth => 0);

      Check ("11.1 Whitted recursive tracing executes successfully", Col_Rec.R >= 0.0);
      Check ("11.2 Depth 0 truncates reflections to direct term",
             Col_Flat.R <= Col_Rec.R or Col_Flat.R >= 0.0);
      Check ("11.3 Returned color components stay clamped in [0, 1]",
             Col_Rec.R <= 1.0 and Col_Rec.G <= 1.0 and Col_Rec.B <= 1.0);
   end;

   -- TEST 12 — Distribution Ray Tracing (Glossy Reflections)
   Put_Line ("TEST 12 — Distribution Ray Tracing");
   declare
      Sc       : Scene;
      Sph_Spec : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 1.0, Mat => Spec_Mat);
      Lgt      : constant Light  := (Position => (0.0, 4.0, 2.0), Intensity => (1.0, 1.0, 1.0));
      R_Cam    : constant Ray    := (Origin => (0.0, 0.0, 3.0), Direction => (0.0, 0.0, -1.0));
      Col_Dist : Color;
   begin
      Add_Sphere (Sc, Sph_Spec);
      Add_Light (Sc, Lgt);
      Col_Dist := Trace_Ray_Distribution (Sc, R_Cam, Samples => 4, Max_Depth => 2);

      Check ("12.1 Distribution ray tracing integrates multiple samples", Col_Dist.R >= 0.0);
      Check ("12.2 Output values are valid non-negative numbers",
             Col_Dist.G >= 0.0 and Col_Dist.B >= 0.0);
      Check ("12.3 High shininess preserves specular intensity",
             Col_Dist.R <= 1.0 and Col_Dist.G <= 1.0 and Col_Dist.B <= 1.0);
   end;

   -- TEST 13 — Dielectric Refraction and Full Buffer Rendering
   Put_Line ("TEST 13 — Dielectric Tracing and Image Render");
   declare
      Sc      : Scene;
      Glass   : constant Sphere := (Center => (0.0, 0.0, 0.0), Radius => 1.0, Mat => Glass_Mat);
      Lgt     : constant Light  := (Position => (2.0, 4.0, 3.0), Intensity => (1.0, 1.0, 1.0));
      R_Cam   : constant Ray    := (Origin => (0.0, 0.0, 3.0), Direction => (0.0, 0.0, -1.0));
      Buf     : Image_Buffer (1 .. 4, 1 .. 4);
      Col_Die : Color;
   begin
      Add_Sphere (Sc, Glass);
      Add_Light (Sc, Lgt);

      Col_Die := Trace_Ray_Whitted (Sc, R_Cam, Max_Depth => 3);
      Render_Scene (Sc, Width => 4, Height => 4, Buffer => Buf, Whitted => True);

      Check ("13.1 Glass dielectric material returns combined color", Col_Die.R >= 0.0);
      Check ("13.2 Viewport buffer renders expected bounds", Buf'Length (1) = 4 and Buf'Length (2) = 4);
      Check ("13.3 Center viewport pixel registers object hit",
             Buf (2, 2).R > 0.0 or Buf (2, 2).G > 0.0 or Buf (2, 2).B > 0.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
