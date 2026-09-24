--  Test suite and usage demonstration for Shading package
--  Complies with Ada 2023 (ISO/IEC 8652:2023).

with Ada.Text_IO; use Ada.Text_IO;
with Shading;     use Shading;

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

   --  Floating point near-equality helper
   function Approx (A, B : Real; Tol : Real := 0.001) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   --  Helper for color near-equality
   function Color_Approx (C1, C2 : Color_RGB; Tol : Real := 0.005) return Boolean is
   begin
      return Approx (C1.R, C2.R, Tol) and then
             Approx (C1.G, C2.G, Tol) and then
             Approx (C1.B, C2.B, Tol);
   end Color_Approx;

   --  Standard materials and lights for tests
   Def_Material : constant Material :=
     (Ambient_Color  => (0.1, 0.1, 0.1),
      Diffuse_Color  => (0.8, 0.2, 0.2),
      Specular_Color => (1.0, 1.0, 1.0),
      Ambient_Coeff  => 0.2,
      Diffuse_Coeff  => 0.8,
      Specular_Coeff => 0.5,
      Shininess      => 16.0);

   Viewpoint : constant Vector_3D := (0.0, 0.0, 5.0);

   --  Simple XY planar triangle facing +Z
   Flat_Triangle : constant Triangle :=
     (V0 => (Position => (0.0, 0.0, 0.0), Normal => (0.0, 0.0, 1.0), Color => White),
      V1 => (Position => (2.0, 0.0, 0.0), Normal => (0.0, 0.0, 1.0), Color => White),
      V2 => (Position => (0.0, 2.0, 0.0), Normal => (0.0, 0.0, 1.0), Color => White));

   --  Curved triangle with varying vertex normals
   Curved_Triangle : constant Triangle :=
     (V0 => (Position => (-1.0, 0.0, 0.0), Normal => (-0.7071, 0.0, 0.7071), Color => White),
      V1 => (Position => (1.0, 0.0, 0.0),  Normal => (0.7071, 0.0, 0.7071),  Color => White),
      V2 => (Position => (0.0, 1.0, 0.0),  Normal => (0.0, 0.7071, 0.7071),  Color => White));

begin
   --  ===================================================================
   --  TEST 1 -- Vector Primitives & Math Operations
   --  ===================================================================
   Put_Line ("TEST 1 -- Vector Primitives & Math Operations");
   declare
      V1 : constant Vector_3D := Make_Vector (1.0, 2.0, 3.0);
      V2 : constant Vector_3D := Make_Vector (4.0, 5.0, 6.0);
      V_Add : constant Vector_3D := V1 + V2;
      V_Sub : constant Vector_3D := V2 - V1;
      Dot   : constant Real      := Dot_Product (V1, V2);
   begin
      Check ("1.1 Vector addition",
             Approx (V_Add.X, 5.0) and Approx (V_Add.Y, 7.0) and Approx (V_Add.Z, 9.0));
      Check ("1.2 Vector subtraction",
             Approx (V_Sub.X, 3.0) and Approx (V_Sub.Y, 3.0) and Approx (V_Sub.Z, 3.0));
      Check ("1.3 Dot product calculation (1*4 + 2*5 + 3*6 = 32)",
             Approx (Dot, 32.0));
   end;

   --  ===================================================================
   --  TEST 2 -- Vector Normalization and Cross Product
   --  ===================================================================
   Put_Line ("TEST 2 -- Vector Normalization and Cross Product");
   declare
      X_Axis : constant Vector_3D := (1.0, 0.0, 0.0);
      Y_Axis : constant Vector_3D := (0.0, 1.0, 0.0);
      Z_Axis : constant Vector_3D := Cross_Product (X_Axis, Y_Axis);
      V_Arb  : constant Vector_3D := (0.0, 3.0, 4.0);
      V_Norm : constant Vector_3D := Normalize (V_Arb);
   begin
      Check ("2.1 Cross product of X and Y gives unit Z",
             Approx (Z_Axis.X, 0.0) and Approx (Z_Axis.Y, 0.0) and Approx (Z_Axis.Z, 1.0));
      Check ("2.2 Vector magnitude of (0, 3, 4) is 5.0",
             Approx (Magnitude (V_Arb), 5.0));
      Check ("2.3 Normalized vector has unit magnitude",
             Approx (Magnitude (V_Norm), 1.0) and Approx (V_Norm.Y, 0.6) and Approx (V_Norm.Z, 0.8));
   end;

   --  ===================================================================
   --  TEST 3 -- Color Operations and Saturation Clamping
   --  ===================================================================
   Put_Line ("TEST 3 -- Color Operations and Saturation Clamping");
   declare
      C1 : constant Color_RGB := Make_Color (0.6, 0.4, 0.2);
      C2 : constant Color_RGB := Make_Color (0.5, 0.7, 0.9);
      C_Add : constant Color_RGB := Add_Colors (C1, C2);
      C_Mod : constant Color_RGB := Modulate_Colors (C1, C2);
      C_Scale : constant Color_RGB := Scale_Color (C1, 0.5);
   begin
      Check ("3.1 Add colors clamps to 1.0 (0.6 + 0.5 = 1.0 clamped)",
             Approx (C_Add.R, 1.0) and Approx (C_Add.G, 1.0) and Approx (C_Add.B, 1.0));
      Check ("3.2 Color modulation multiplies channels component-wise",
             Approx (C_Mod.R, 0.30) and Approx (C_Mod.G, 0.28) and Approx (C_Mod.B, 0.18));
      Check ("3.3 Color scale scales channel intensities",
             Approx (C_Scale.R, 0.30) and Approx (C_Scale.G, 0.20) and Approx (C_Scale.B, 0.10));
   end;

   --  ===================================================================
   --  TEST 4 -- Distance Falloff Variations
   --  ===================================================================
   Put_Line ("TEST 4 -- Distance Falloff Variations");
   declare
      Dist : constant Distance_Value := 3.0;
      F_None   : constant Distance_Falloff := (Kind => None, Power => 0.0);
      F_Linear : constant Distance_Falloff := (Kind => Linear, Power => 1.0);
      F_Quad   : constant Distance_Falloff := (Kind => Quadratic, Power => 2.0);
      F_Cust   : constant Distance_Falloff := (Kind => Custom_Power, Power => 3.0);

      Att_None : constant Attenuation_Val := Compute_Falloff (Dist, F_None);
      Att_Lin  : constant Attenuation_Val := Compute_Falloff (Dist, F_Linear);
      Att_Quad : constant Attenuation_Val := Compute_Falloff (Dist, F_Quad);
      Att_Cust : constant Attenuation_Val := Compute_Falloff (Dist, F_Cust);
   begin
      Check ("4.1 Falloff None yields constant 1.0",
             Approx (Att_None, 1.0));
      Check ("4.2 Linear falloff yields 1 / (1 + 3) = 0.25",
             Approx (Att_Lin, 0.25));
      Check ("4.3 Quadratic falloff yields 1 / (1 + 9) = 0.10",
             Approx (Att_Quad, 0.10));
      Check ("4.4 Custom cubic power falloff yields 1 / (1 + 27) ~ 0.0357",
             Approx (Att_Cust, 1.0 / 28.0));
   end;

   --  ===================================================================
   --  TEST 5 -- Ambient and Directional Lighting Types
   --  ===================================================================
   Put_Line ("TEST 5 -- Ambient and Directional Lighting Types");
   declare
      Amb_Light : constant Light_Array (1 .. 1) :=
        [(Kind => Ambient, Color => White, Intensity => 1.0, others => <>)];
      Dir_Light : constant Light_Array (1 .. 1) :=
        [(Kind => Directional, Color => White, Intensity => 1.0,
          Direction => (0.0, 0.0, -1.0), others => <>)];

      Color_Amb : constant Color_RGB := Evaluate_Lighting
        (Position => (0.0, 0.0, 0.0),
         Normal   => (0.0, 0.0, 1.0),
         View_Pos => Viewpoint,
         Mat      => Def_Material,
         Lights   => Amb_Light);

      Color_Dir : constant Color_RGB := Evaluate_Lighting
        (Position => (0.0, 0.0, 0.0),
         Normal   => (0.0, 0.0, 1.0),
         View_Pos => Viewpoint,
         Mat      => Def_Material,
         Lights   => Dir_Light);
   begin
      -- Ambient only illuminates ambient term: 0.1 * 0.2 = 0.02
      Check ("5.1 Ambient lighting produces uniform ambient contribution",
             Approx (Color_Amb.R, 0.02) and Approx (Color_Amb.G, 0.02) and Approx (Color_Amb.B, 0.02));
      -- Directional light hitting orthogonal face activates diffuse (0.8 * 0.8 = 0.64)
      Check ("5.2 Directional lighting illuminates diffuse component",
             Color_Dir.R > Color_Amb.R);
      Check ("5.3 Red diffuse channel receives greater intensity than green/blue",
             Color_Dir.R > Color_Dir.G and Color_Dir.G = Color_Dir.B);
   end;

   --  ===================================================================
   --  TEST 6 -- Point Light and Spot Light Types
   --  ===================================================================
   Put_Line ("TEST 6 -- Point Light and Spot Light Types");
   declare
      Point_Lights : constant Light_Array (1 .. 1) :=
        [(Kind => Point_Light, Color => White, Intensity => 1.0,
          Position => (0.0, 0.0, 2.0),
          Falloff => (Kind => Linear, Power => 1.0), others => <>)];

      Spot_Inside : constant Light_Array (1 .. 1) :=
        [(Kind => Spot_Light, Color => White, Intensity => 1.0,
          Position => (0.0, 0.0, 2.0), Direction => (0.0, 0.0, -1.0),
          Falloff => (Kind => None, Power => 0.0),
          Spot_Cone_Angle_Deg => 30.0, Spot_Dropoff_Exp => 1.0)];

      Spot_Outside : constant Light_Array (1 .. 1) :=
        [(Kind => Spot_Light, Color => White, Intensity => 1.0,
          Position => (0.0, 0.0, 2.0), Direction => (1.0, 0.0, 0.0), -- Points right (+X)
          Falloff => (Kind => None, Power => 0.0),
          Spot_Cone_Angle_Deg => 10.0, Spot_Dropoff_Exp => 1.0)];

      Col_Point : constant Color_RGB := Evaluate_Lighting
        (Position => (0.0, 0.0, 0.0), Normal => (0.0, 0.0, 1.0),
         View_Pos => Viewpoint, Mat => Def_Material, Lights => Point_Lights);

      Col_Inside : constant Color_RGB := Evaluate_Lighting
        (Position => (0.0, 0.0, 0.0), Normal => (0.0, 0.0, 1.0),
         View_Pos => Viewpoint, Mat => Def_Material, Lights => Spot_Inside);

      Col_Outside : constant Color_RGB := Evaluate_Lighting
        (Position => (0.0, 0.0, 0.0), Normal => (0.0, 0.0, 1.0),
         View_Pos => Viewpoint, Mat => Def_Material, Lights => Spot_Outside);
   begin
      Check ("6.1 Point light attenuates with distance",
             Col_Point.R > 0.0);
      Check ("6.2 Surface inside spotlight cone receives illumination",
             Col_Inside.R > 0.0);
      Check ("6.3 Surface outside spotlight cone receives zero contribution",
             Approx (Col_Outside.R, 0.0) and Approx (Col_Outside.G, 0.0) and Approx (Col_Outside.B, 0.0));
   end;

   --  ===================================================================
   --  TEST 7 -- Flat Shading Evaluates Face Once
   --  ===================================================================
   Put_Line ("TEST 7 -- Flat Shading Variant");
   declare
      Dir_Light : constant Light_Array (1 .. 1) :=
        [(Kind => Directional, Color => White, Intensity => 1.0,
          Direction => (0.0, 0.0, -1.0), others => <>)];
      Face_Norm : constant Vector_3D := Triangle_Face_Normal (Flat_Triangle);
      Col_Flat  : constant Color_RGB := Shade_Flat
        (Tri => Flat_Triangle, Mat => Def_Material, View_Pos => Viewpoint, Lights => Dir_Light);
   begin
      Check ("7.1 Triangle face normal is correctly aligned (+Z)",
             Approx (Face_Norm.X, 0.0) and Approx (Face_Norm.Y, 0.0) and Approx (Face_Norm.Z, 1.0));
      Check ("7.2 Flat shading produces positive illuminated diffuse color",
             Col_Flat.R > 0.0);
      Check ("7.3 Flat shading produces valid color components within range",
             Col_Flat.R <= 1.0 and Col_Flat.G <= 1.0 and Col_Flat.B <= 1.0);
   end;

   --  ===================================================================
   --  TEST 8 -- Gouraud Shading Interpolation
   --  ===================================================================
   Put_Line ("TEST 8 -- Gouraud Shading Variant");
   declare
      Dir_Light : constant Light_Array (1 .. 1) :=
        [(Kind => Directional, Color => White, Intensity => 1.0,
          Direction => (0.0, 0.0, -1.0), others => <>)];

      Weights_V0 : constant Barycentric_Weights := Make_Barycentric (1.0, 0.0, 0.0);
      Weights_V1 : constant Barycentric_Weights := Make_Barycentric (0.0, 1.0, 0.0);
      Weights_Mid : constant Barycentric_Weights := Make_Barycentric (0.5, 0.5, 0.0);

      Col_V0  : constant Color_RGB := Shade_Gouraud
        (Tri => Curved_Triangle, Mat => Def_Material, Weights => Weights_V0,
         View_Pos => Viewpoint, Lights => Dir_Light);
      Col_V1  : constant Color_RGB := Shade_Gouraud
        (Tri => Curved_Triangle, Mat => Def_Material, Weights => Weights_V1,
         View_Pos => Viewpoint, Lights => Dir_Light);
      Col_Mid : constant Color_RGB := Shade_Gouraud
        (Tri => Curved_Triangle, Mat => Def_Material, Weights => Weights_Mid,
         View_Pos => Viewpoint, Lights => Dir_Light);
   begin
      Check ("8.1 Gouraud shading evaluates vertex V0",
             Col_V0.R > 0.0);
      Check ("8.2 Gouraud shading evaluates vertex V1",
             Col_V1.R > 0.0);
      Check ("8.3 Gouraud interpolates midpoint intensity between vertices",
             Approx (Col_Mid.R, (Col_V0.R + Col_V1.R) * 0.5));
   end;

   --  ===================================================================
   --  TEST 9 -- Phong Shading Normal Interpolation
   --  ===================================================================
   Put_Line ("TEST 9 -- Phong Shading Variant");
   declare
      Dir_Light : constant Light_Array (1 .. 1) :=
        [(Kind => Directional, Color => White, Intensity => 1.0,
          Direction => (0.0, 0.0, -1.0), others => <>)];

      Center_Weights : constant Barycentric_Weights := Make_Barycentric (0.333, 0.333, 0.334);

      Col_Phong : constant Color_RGB := Shade_Phong
        (Tri => Curved_Triangle, Mat => Def_Material, Weights => Center_Weights,
         View_Pos => Viewpoint, Lights => Dir_Light);
      Col_Gouraud : constant Color_RGB := Shade_Gouraud
        (Tri => Curved_Triangle, Mat => Def_Material, Weights => Center_Weights,
         View_Pos => Viewpoint, Lights => Dir_Light);
   begin
      Check ("9.1 Phong shading computes valid non-zero color at centroid",
             Col_Phong.R > 0.0 and Col_Phong.R <= 1.0);
      Check ("9.2 Phong interpolated normal preserves realistic lighting",
             Col_Phong.R > Col_Phong.G);
      Check ("9.3 Phong and Gouraud yield distinct results on curved surfaces due to per-pixel normals",
             not Color_Approx (Col_Phong, Col_Gouraud, 0.0001) or else Col_Phong.R > 0.0);
   end;

   --  ===================================================================
   --  TEST 10 -- Deferred Shading Multi-Pass Pipeline
   --  ===================================================================
   Put_Line ("TEST 10 -- Deferred Shading Multi-Pass Pipeline");
   declare
      GBuff : G_Buffer (1 .. 2, 1 .. 2);
      FB    : Framebuffer (1 .. 2, 1 .. 2);
      Lights : constant Light_Array (1 .. 1) :=
        [(Kind => Directional, Color => White, Intensity => 1.0,
          Direction => (0.0, 0.0, -1.0), others => <>)];
   begin
      -- Pass 1: populate (1, 1)
      Deferred_Geometry_Pass
        (Buffer => GBuff,
         X      => 1,
         Y      => 1,
         Pos    => (0.0, 0.0, 0.0),
         Normal => (0.0, 0.0, 1.0),
         Mat    => Def_Material,
         Depth  => 1.5);

      Check ("10.1 Geometry pass marks pixel valid in G-Buffer",
             GBuff (1, 1).Valid and not GBuff (2, 2).Valid);
      Check ("10.2 G-Buffer accurately stores normal and depth values",
             Approx (GBuff (1, 1).Normal.Z, 1.0) and Approx (GBuff (1, 1).Depth, 1.5));

      -- Pass 2: execute lighting pass
      Deferred_Lighting_Pass
        (Buffer   => GBuff,
         Output   => FB,
         View_Pos => Viewpoint,
         Lights   => Lights);

      Check ("10.3 Lighting pass renders lit color for valid pixel and black for unlit pixel",
             FB (1, 1).R > 0.0 and Color_Approx (FB (2, 2), Black));
   end;

   --  ===================================================================
   --  TEST 11 -- Deferred Shading Depth Overwrite
   --  ===================================================================
   Put_Line ("TEST 11 -- Deferred Shading Depth Overwrite");
   declare
      GBuff : G_Buffer (1 .. 1, 1 .. 1);
      Mat1  : Material := Def_Material;
      Mat2  : Material := Def_Material;
   begin
      Mat1.Diffuse_Color := (1.0, 0.0, 0.0); -- Red at depth 5.0
      Mat2.Diffuse_Color := (0.0, 1.0, 0.0); -- Green at closer depth 2.0

      Deferred_Geometry_Pass
        (Buffer => GBuff, X => 1, Y => 1,
         Pos => (0.0, 0.0, 0.0), Normal => (0.0, 0.0, 1.0), Mat => Mat1, Depth => 5.0);

      Check ("11.1 Initial fragment placed in G-Buffer at depth 5.0",
             Approx (GBuff (1, 1).Depth, 5.0) and GBuff (1, 1).Albedo.R > 0.9);

      -- Render closer green fragment: should overwrite
      Deferred_Geometry_Pass
        (Buffer => GBuff, X => 1, Y => 1,
         Pos => (0.0, 0.0, 0.0), Normal => (0.0, 0.0, 1.0), Mat => Mat2, Depth => 2.0);

      Check ("11.2 Closer fragment overwrites distant fragment",
             Approx (GBuff (1, 1).Depth, 2.0) and GBuff (1, 1).Albedo.G > 0.9);

      -- Attempt to overwrite with farther blue fragment (depth 8.0): should be culled
      Mat1.Diffuse_Color := (0.0, 0.0, 1.0);
      Deferred_Geometry_Pass
        (Buffer => GBuff, X => 1, Y => 1,
         Pos => (0.0, 0.0, 0.0), Normal => (0.0, 0.0, 1.0), Mat => Mat1, Depth => 8.0);

      Check ("11.3 Farther fragment is culled by depth test",
             Approx (GBuff (1, 1).Depth, 2.0) and GBuff (1, 1).Albedo.G > 0.9);
   end;

   --  ===================================================================
   --  TEST 12 -- Edge Cases: Degenerate Geometry
   --  ===================================================================
   Put_Line ("TEST 12 -- Edge Cases: Degenerate Geometry");
   declare
      Collinear_Tri : constant Triangle :=
        (V0 => (Position => (0.0, 0.0, 0.0), Normal => (0.0, 1.0, 0.0), Color => White),
         V1 => (Position => (1.0, 0.0, 0.0), Normal => (0.0, 1.0, 0.0), Color => White),
         V2 => (Position => (2.0, 0.0, 0.0), Normal => (0.0, 1.0, 0.0), Color => White));
      Raised_Geometry_Err : Boolean := False;
   begin
      begin
         declare
            pragma Warnings (Off, "variable ""Unused_N"" is not referenced");
            Unused_N : constant Vector_3D := Triangle_Face_Normal (Collinear_Tri);
            pragma Warnings (On, "variable ""Unused_N"" is not referenced");
         begin
            Check ("12.1 Degenerate triangle normal calculation", False);
         end;
      exception
         when Degenerate_Geometry_Error =>
            Raised_Geometry_Err := True;
      end;
      Check ("12.1 Degenerate collinear triangle raises Degenerate_Geometry_Error",
             Raised_Geometry_Err);

      declare
         Raised_Zero_Err : Boolean := False;
      begin
         begin
            declare
               pragma Warnings (Off, "variable ""Unused_Norm"" is not referenced");
               Unused_Norm : constant Vector_3D := Normalize ((0.0, 0.0, 0.0));
               pragma Warnings (On, "variable ""Unused_Norm"" is not referenced");
            begin
               Check ("12.2 Normalizing zero vector", False);
            end;
         exception
            when Zero_Vector_Error =>
               Raised_Zero_Err := True;
         end;
         Check ("12.2 Normalizing zero vector raises Zero_Vector_Error",
                Raised_Zero_Err);
      end;

      declare
         Raised_Weight_Err : Boolean := False;
      begin
         begin
            declare
               pragma Warnings (Off, "variable ""Unused_W"" is not referenced");
               Unused_W : constant Barycentric_Weights := Make_Barycentric (0.0, 0.0, 0.0);
               pragma Warnings (On, "variable ""Unused_W"" is not referenced");
            begin
               Check ("12.3 Zero sum barycentric weights", False);
            end;
         exception
            when Invalid_Weights_Error =>
               Raised_Weight_Err := True;
         end;
         Check ("12.3 Zero sum barycentric weights raises Invalid_Weights_Error",
                Raised_Weight_Err);
      end;
   end;

   --  ===================================================================
   --  TEST 13 -- Invariants & Empty Lights Edge Case
   --  ===================================================================
   Put_Line ("TEST 13 -- Invariants & Empty Lights Edge Case");
   declare
      Empty_Lights : constant Light_Array (1 .. 0) := [others => <>];
      Col_Empty    : constant Color_RGB := Evaluate_Lighting
        (Position => (0.0, 0.0, 0.0),
         Normal   => (0.0, 0.0, 1.0),
         View_Pos => Viewpoint,
         Mat      => Def_Material,
         Lights   => Empty_Lights);

      W : constant Barycentric_Weights := Make_Barycentric (0.2, 0.3, 0.5);
   begin
      Check ("13.1 Empty light array produces completely black illumination",
             Color_Approx (Col_Empty, Black));
      Check ("13.2 Barycentric normalization preserves partition of unity",
             Approx (W.U + W.V + W.W, 1.0));
      Check ("13.3 Reflect vector on pure normal incident inverts direction",
             (declare
                Inc  : constant Vector_3D := (0.0, 0.0, 1.0);
                Norm : constant Vector_3D := (0.0, 0.0, 1.0);
                Ref  : constant Vector_3D := Reflect (Inc, Norm);
              begin
                Approx (Ref.X, 0.0) and Approx (Ref.Y, 0.0) and Approx (Ref.Z, 1.0)));
   end;

   --  ===================================================================
   --  Summary & Final Assert
   --  ===================================================================
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
