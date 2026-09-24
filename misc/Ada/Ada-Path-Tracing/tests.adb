with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Float_Random;
with Path_Tracing; use Path_Tracing;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   Gen : Ada.Numerics.Float_Random.Generator;
begin
   Ada.Numerics.Float_Random.Reset (Gen, 1337);

   --  ======================================================================
   --  TEST 1 -- Vector Arithmetic and Dot Product
   --  ======================================================================
   Put_Line ("TEST 1 -- Vector Arithmetic");
   declare
      V1 : constant Vector_3D := (X => 1.0, Y => 2.0, Z => 3.0);
      V2 : constant Vector_3D := (X => 4.0, Y => -2.0, Z => 1.0);
      V_Add : constant Vector_3D := V1 + V2;
      V_Sub : constant Vector_3D := V1 - V2;
      Dot_P : constant Real := Dot (V1, V2);
   begin
      Check ("1.1 Vector addition component sum",
             V_Add.X = 5.0 and V_Add.Y = 0.0 and V_Add.Z = 4.0);
      Check ("1.2 Vector subtraction component difference",
             V_Sub.X = -3.0 and V_Sub.Y = 4.0 and V_Sub.Z = 2.0);
      Check ("1.3 Vector dot product accuracy",
             abs (Dot_P - 3.0) < 1.0e-7);
   end;

   --  ======================================================================
   --  TEST 2 -- Vector Normalization, Length, and Cross Product
   --  ======================================================================
   Put_Line ("TEST 2 -- Normalization and Cross Product");
   declare
      V : constant Vector_3D := (X => 0.0, Y => 3.0, Z => 4.0);
      Norm_V : constant Vector_3D := Normalize (V);
      Cross_X : constant Vector_3D :=
        Cross ((X => 1.0, Y => 0.0, Z => 0.0), (X => 0.0, Y => 1.0, Z => 0.0));
   begin
      Check ("2.1 Un-normalized length equals 5.0",
             abs (Length (V) - 5.0) < 1.0e-7);
      Check ("2.2 Normalized vector has unit length",
             abs (Length (Norm_V) - 1.0) < 1.0e-7);
      Check ("2.3 Right-hand orthogonal cross product creates Z unit",
             Cross_X.X = 0.0 and Cross_X.Y = 0.0 and abs (Cross_X.Z - 1.0) < 1.0e-7);
   end;

   --  ======================================================================
   --  TEST 3 -- Vector Exception Handling on Degenerate Norm/Div
   --  ======================================================================
   Put_Line ("TEST 3 -- Degenerate Vector Handling");
   declare
      Zero_V : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 0.0);
      Norm_Caught : Boolean := False;
      Div_Caught  : Boolean := False;
      Quotient    : constant Vector_3D := (X => 2.0, Y => 4.0, Z => 6.0) / 2.0;
   begin
      begin
         declare
            Unused_V : constant Vector_3D := Normalize (Zero_V);
            pragma Unreferenced (Unused_V);
         begin
            null;
         end;
      exception
         when Degenerate_Vector_Error =>
            Norm_Caught := True;
      end;

      begin
         declare
            Unused_V : constant Vector_3D := Zero_V / 0.0;
            pragma Unreferenced (Unused_V);
         begin
            null;
         end;
      exception
         when Degenerate_Vector_Error =>
            Div_Caught := True;
      end;

      Check ("3.1 Normalizing zero vector raises Degenerate_Vector_Error", Norm_Caught);
      Check ("3.2 Division by zero raises Degenerate_Vector_Error", Div_Caught);
      Check ("3.3 Valid vector division preserves ratio",
             Quotient.Y = 2.0);
   end;

   --  ======================================================================
   --  TEST 4 -- Specular Reflection Calculations
   --  ======================================================================
   Put_Line ("TEST 4 -- Specular Reflection");
   declare
      Ray_Dir : constant Vector_3D := Normalize ((X => 1.0, Y => -1.0, Z => 0.0));
      Normal  : constant Vector_3D := (X => 0.0, Y => 1.0, Z => 0.0);
      Reflected : constant Vector_3D := Reflect (Ray_Dir, Normal);
   begin
      Check ("4.1 X direction remains positive", Reflected.X > 0.0);
      Check ("4.2 Y direction sign inverts upwards", Reflected.Y > 0.0);
      Check ("4.3 Length preserved under reflection",
             abs (Length (Reflected) - 1.0) < 1.0e-6);
   end;

   --  ======================================================================
   --  TEST 5 -- Radiance Math and Color Clamping
   --  ======================================================================
   Put_Line ("TEST 5 -- Radiance Math and Clamping");
   declare
      Rad1 : constant Radiance := (R => 0.5, G => 1.2, B => 0.1);
      Rad2 : constant Radiance := (R => 0.2, G => 0.5, B => 2.0);
      Rad_Sum : constant Radiance := Rad1 + Rad2;
      Rad_Mul : constant Radiance := Rad1 * Color_RGB'(R => 0.5, G => 0.5, B => 0.5);
      Color   : constant Color_RGB := To_Color (Rad1);
   begin
      Check ("5.1 Radiance addition arithmetic",
             abs (Rad_Sum.R - 0.7) < 1.0e-6 and abs (Rad_Sum.G - 1.7) < 1.0e-6);
      Check ("5.2 Radiance multiplication by albedo",
             abs (Rad_Mul.R - 0.25) < 1.0e-6);
      Check ("5.3 Radiance clamped to unit interval [0, 1] in Color conversion",
             Color.G = 1.0 and Color.R = 0.5 and Color.B = 0.1);
   end;

   --  ======================================================================
   --  TEST 6 -- Direct Ray-Sphere Intersection Geometry
   --  ======================================================================
   Put_Line ("TEST 6 -- Ray-Sphere Intersection");
   declare
      S : constant Sphere :=
        (Center => (X => 0.0, Y => 0.0, Z => -5.0),
         Radius => 1.0,
         Mat    => (Kind => Diffuse, Albedo => (0.8, 0.8, 0.8),
                    Emission => (0.0, 0.0, 0.0), Roughness => 0.0));
      Ray_Hit : constant Ray :=
        (Origin => (X => 0.0, Y => 0.0, Z => 0.0),
         Direction => (X => 0.0, Y => 0.0, Z => -1.0));
      Ray_Miss : constant Ray :=
        (Origin => (X => 0.0, Y => 0.0, Z => 0.0),
         Direction => (X => 0.0, Y => 1.0, Z => 0.0));
      Hit_Rec : constant Intersection_Record := Intersect_Sphere (Ray_Hit, S, 0.001, 100.0);
      Miss_Rec : constant Intersection_Record := Intersect_Sphere (Ray_Miss, S, 0.001, 100.0);
   begin
      Check ("6.1 Hit record confirms sphere intersection", Hit_Rec.Hit);
      Check ("6.2 Distance to sphere surface is exactly 4.0",
             abs (Hit_Rec.Distance - 4.0) < 1.0e-6);
      Check ("6.3 Miss record returns False for hit", not Miss_Rec.Hit);
   end;

   --  ======================================================================
   --  TEST 7 -- Multi-Object Scene Intersections and Occlusion
   --  ======================================================================
   Put_Line ("TEST 7 -- Multi-Object Scene Intersections");
   declare
      Near_Sphere : constant Sphere :=
        (Center => (X => 0.0, Y => 0.0, Z => -3.0),
         Radius => 0.5,
         Mat    => (Kind => Diffuse, Albedo => (1.0, 0.0, 0.0),
                    Emission => (0.0, 0.0, 0.0), Roughness => 0.0));
      Far_Sphere : constant Sphere :=
        (Center => (X => 0.0, Y => 0.0, Z => -8.0),
         Radius => 1.0,
         Mat    => (Kind => Diffuse, Albedo => (0.0, 1.0, 0.0),
                    Emission => (0.0, 0.0, 0.0), Roughness => 0.0));
      Scene : constant Sphere_Array (1 .. 2) := [Near_Sphere, Far_Sphere];
      R : constant Ray :=
        (Origin => (X => 0.0, Y => 0.0, Z => 0.0),
         Direction => (X => 0.0, Y => 0.0, Z => -1.0));
      Hit : constant Intersection_Record := Intersect_Scene (R, Scene, 0.001, 100.0);
   begin
      Check ("7.1 Intersect_Scene detects hit", Hit.Hit);
      Check ("7.2 Nearest sphere occludes farther sphere (distance = 2.5)",
             abs (Hit.Distance - 2.5) < 1.0e-6);
      Check ("7.3 Nearest sphere material is identified (Red Albedo)",
             Hit.Mat.Albedo.R = 1.0 and Hit.Mat.Albedo.G = 0.0);
   end;

   --  ======================================================================
   --  TEST 8 -- Pure Path Tracing Direct Light Source
   --  ======================================================================
   Put_Line ("TEST 8 -- Pure Path Tracing Direct Light");
   declare
      Light_Sphere : constant Sphere :=
        (Center => (X => 0.0, Y => 0.0, Z => -4.0),
         Radius => 1.0,
         Mat    => (Kind => Emissive, Albedo => (0.0, 0.0, 0.0),
                    Emission => (R => 12.0, G => 8.0, B => 4.0), Roughness => 0.0));
      Scene : constant Sphere_Array (1 .. 1) := [1 => Light_Sphere];
      R : constant Ray :=
        (Origin => (X => 0.0, Y => 0.0, Z => 0.0),
         Direction => (X => 0.0, Y => 0.0, Z => -1.0));
      Rad : constant Radiance := Trace_Pure_Path (R, Scene, 3, Gen);
   begin
      Check ("8.1 Directly visible emissive sphere returns Red radiance",
             abs (Rad.R - 12.0) < 1.0e-5);
      Check ("8.2 Direct emissive sphere returns Green radiance",
             abs (Rad.G - 8.0) < 1.0e-5);
      Check ("8.3 Direct emissive sphere returns Blue radiance",
             abs (Rad.B - 4.0) < 1.0e-5);
   end;

   --  ======================================================================
   --  TEST 9 -- Next Event Estimation (Direct Lighting)
   --  ======================================================================
   Put_Line ("TEST 9 -- Next Event Estimation Direct Lighting");
   declare
      Light_Sphere : constant Sphere :=
        (Center => (X => 0.0, Y => 5.0, Z => -3.0),
         Radius => 1.0,
         Mat    => (Kind => Emissive, Albedo => (0.0, 0.0, 0.0),
                    Emission => (R => 10.0, G => 10.0, B => 10.0), Roughness => 0.0));
      Floor_Sphere : constant Sphere :=
        (Center => (X => 0.0, Y => -100.0, Z => -3.0),
         Radius => 100.0,
         Mat    => (Kind => Diffuse, Albedo => (0.8, 0.8, 0.8),
                    Emission => (0.0, 0.0, 0.0), Roughness => 0.0));
      Scene : constant Sphere_Array (1 .. 2) := [Light_Sphere, Floor_Sphere];
      R : constant Ray :=
        (Origin => (X => 0.0, Y => 1.0, Z => 0.0),
         Direction => Normalize ((X => 0.0, Y => -1.0, Z => -3.0)));
      Rad : constant Radiance := Trace_Next_Event_Estimation (R, Scene, 2, Gen);
   begin
      Check ("9.1 NEE illuminates diffuse surface from light source", Rad.R > 0.0);
      Check ("9.2 NEE produces balanced white light on grey albedo",
             abs (Rad.R - Rad.G) < 1.0e-5);
      Check ("9.3 Radiance is non-negative and finite", Rad.B >= 0.0 and Rad.B < 100.0);
   end;

   --  ======================================================================
   --  TEST 10 -- Russian Roulette Path Tracing
   --  ======================================================================
   Put_Line ("TEST 10 -- Russian Roulette Termination");
   declare
      Light_Sphere : constant Sphere :=
        (Center => (X => 0.0, Y => 0.0, Z => -5.0),
         Radius => 1.0,
         Mat    => (Kind => Emissive, Albedo => (0.0, 0.0, 0.0),
                    Emission => (R => 5.0, G => 5.0, B => 5.0), Roughness => 0.0));
      Scene : constant Sphere_Array (1 .. 1) := [1 => Light_Sphere];
      R : constant Ray :=
        (Origin => (X => 0.0, Y => 0.0, Z => 0.0),
         Direction => (X => 0.0, Y => 0.0, Z => -1.0));
      Rad : constant Radiance := Trace_Russian_Roulette (R, Scene, 0.75, Gen);
   begin
      Check ("10.1 Russian Roulette hits direct emitter cleanly",
             abs (Rad.R - 5.0) < 1.0e-5);
      Check ("10.2 Russian Roulette color consistency G",
             abs (Rad.G - 5.0) < 1.0e-5);
      Check ("10.3 Russian Roulette color consistency B",
             abs (Rad.B - 5.0) < 1.0e-5);
   end;

   --  ======================================================================
   --  TEST 11 -- Hemispherical Cosine Sampling Validation
   --  ======================================================================
   Put_Line ("TEST 11 -- Cosine Sampling Hemisphere");
   declare
      Norm : constant Vector_3D := (X => 0.0, Y => 1.0, Z => 0.0);
      Sample_Dir : constant Vector_3D := Cosine_Sample_Hemisphere (Norm, 0.5, 0.25);
   begin
      Check ("11.1 Generated sample is normalized",
             abs (Length (Sample_Dir) - 1.0) < 1.0e-6);
      Check ("11.2 Generated sample points into positive hemisphere",
             Dot (Sample_Dir, Norm) >= 0.0);
      Check ("11.3 Sampling with extreme U1=0.0 stays oriented with normal",
             Dot (Cosine_Sample_Hemisphere (Norm, 0.0, 0.0), Norm) >= 0.999);
   end;

   --  ======================================================================
   --  TEST 12 -- Unified Dispatch API and Options
   --  ======================================================================
   Put_Line ("TEST 12 -- Unified Trace_Ray API");
   declare
      Emitter : constant Sphere :=
        (Center => (X => 0.0, Y => 0.0, Z => -2.0),
         Radius => 0.5,
         Mat    => (Kind => Emissive, Albedo => (0.0, 0.0, 0.0),
                    Emission => (R => 2.0, G => 2.0, B => 2.0), Roughness => 0.0));
      Scene : constant Sphere_Array (1 .. 1) := [1 => Emitter];
      R : constant Ray :=
        (Origin => (X => 0.0, Y => 0.0, Z => 0.0),
         Direction => (X => 0.0, Y => 0.0, Z => -1.0));
      Opt_Pure : constant Rendering_Options :=
        (Mode => Pure_Path_Tracing, Max_Depth => 3, Samples_Per_Pixel => 4, Russian_Roulette_Prob => 0.8);
      Opt_NEE : constant Rendering_Options :=
        (Mode => Next_Event_Estimation, Max_Depth => 3, Samples_Per_Pixel => 4, Russian_Roulette_Prob => 0.8);
      Rad_Pure : constant Radiance := Trace_Ray (R, Scene, Opt_Pure, Gen);
      Rad_NEE  : constant Radiance := Trace_Ray (R, Scene, Opt_NEE, Gen);
   begin
      Check ("12.1 Pure path multi-sample average matches emitter",
             abs (Rad_Pure.R - 2.0) < 1.0e-5);
      Check ("12.2 NEE multi-sample average matches emitter",
             abs (Rad_NEE.R - 2.0) < 1.0e-5);
      Check ("12.3 Dispatch preserves positive non-zero radiance",
             Rad_Pure.G > 0.0 and Rad_NEE.G > 0.0);
   end;

   --  ======================================================================
   --  TEST 13 -- Scene Validation and Invariants
   --  ======================================================================
   Put_Line ("TEST 13 -- Scene Validation and Invariants");
   declare
      Valid_Sphere : constant Sphere :=
        (Center => (X => 0.0, Y => 0.0, Z => 0.0),
         Radius => 1.0,
         Mat    => (Kind => Diffuse, Albedo => (0.5, 0.5, 0.5),
                    Emission => (0.0, 0.0, 0.0), Roughness => 0.0));
      Valid_Scene   : constant Sphere_Array (1 .. 1) := [1 => Valid_Sphere];
   begin
      Check ("13.1 Positive radius sphere validates successfully",
             Validate_Scene (Valid_Scene));
      Check ("13.2 Empty scene validation evaluates to False",
             not Validate_Scene (Sphere_Array'[]));
   end;

   --  ======================================================================
   --  TEST 14 -- Background Miss Path Termination
   --  ======================================================================
   Put_Line ("TEST 14 -- Background Miss Invariant");
   declare
      Scene : constant Sphere_Array (1 .. 1) :=
        [1 => (Center => (X => 10.0, Y => 10.0, Z => -10.0),
               Radius => 1.0,
               Mat    => (Kind => Diffuse, Albedo => (0.5, 0.5, 0.5),
                          Emission => (1.0, 1.0, 1.0), Roughness => 0.0))];
      Miss_Ray : constant Ray :=
        (Origin => (X => 0.0, Y => 0.0, Z => 0.0),
         Direction => (X => 0.0, Y => 0.0, Z => 1.0));
      Opt : constant Rendering_Options :=
        (Mode => Pure_Path_Tracing, Max_Depth => 4, Samples_Per_Pixel => 1, Russian_Roulette_Prob => 0.8);
      Rad : constant Radiance := Trace_Ray (Miss_Ray, Scene, Opt, Gen);
   begin
      Check ("14.1 Ray pointing away from all geometry returns 0.0 Red", Rad.R = 0.0);
      Check ("14.2 Ray pointing away returns 0.0 Green", Rad.G = 0.0);
      Check ("14.3 Ray pointing away returns 0.0 Blue", Rad.B = 0.0);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
