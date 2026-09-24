with Ada.Text_IO; use Ada.Text_IO;
with Phong_Shading; use Phong_Shading;

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

   function Approx (A, B : Real; Tolerance : Real := 0.001) return Boolean is
   begin
      return abs (A - B) <= Tolerance;
   end Approx;

   --  Default setup items
   Default_Mat : constant Material_Properties :=
     (Ambient_Coeff   => 0.1,
      Diffuse_Coeff   => 0.7,
      Specular_Coeff  => 0.5,
      Shininess       => 32.0,
      Ambient_Color   => (1.0, 1.0, 1.0),
      Diffuse_Color   => (1.0, 1.0, 1.0),
      Specular_Color  => (1.0, 1.0, 1.0));

   White_Ambient : constant Color_RGB := (1.0, 1.0, 1.0);
begin
   --  TEST 1 — Vector Fundamentals & Normalization
   Put_Line ("TEST 1 — Vector Fundamentals and Normalization");
   declare
      V1 : constant Vector_3D := (3.0, 4.0, 0.0);
      V2 : constant Vector_3D := (0.0, 0.0, 5.0);
      NV : constant Unit_Vector_3D := Normalize (V1);
      DP : constant Real := Dot_Product (V1, V2);
      CP : constant Vector_3D := Cross_Product ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
   begin
      Check ("1.1 Vector norm calculation", Approx (Norm (V1), 5.0));
      Check ("1.2 Normalization yields unit length", Approx (Norm (NV), 1.0));
      Check ("1.3 Dot product of orthogonal vectors is zero", Approx (DP, 0.0));
      Check ("1.4 Cross product basis correctness",
             Approx (CP.X, 0.0) and then Approx (CP.Y, 0.0) and then Approx (CP.Z, 1.0));
   end;

   --  TEST 2 — Reflection Vector Geometry
   Put_Line ("TEST 2 — Reflection Vector Geometry");
   declare
      N : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      L45 : constant Unit_Vector_3D := Normalize ((1.0, 1.0, 0.0));
      R : constant Unit_Vector_3D := Reflect (L45, N);
      L_Direct : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      R_Direct : constant Unit_Vector_3D := Reflect (L_Direct, N);
   begin
      Check ("2.1 45-degree reflection angle X symmetry", Approx (R.X, -L45.X));
      Check ("2.2 45-degree reflection angle Y symmetry", Approx (R.Y, L45.Y));
      Check ("2.3 Direct normal reflection matches incoming vector",
             Approx (R_Direct.X, 0.0) and then Approx (R_Direct.Y, 1.0) and then Approx (R_Direct.Z, 0.0));
   end;

   --  TEST 3 — Halfway Vector for Blinn-Phong
   Put_Line ("TEST 3 — Halfway Vector for Blinn-Phong");
   declare
      L : constant Unit_Vector_3D := Normalize ((1.0, 1.0, 0.0));
      V : constant Unit_Vector_3D := Normalize ((-1.0, 1.0, 0.0));
      H : constant Unit_Vector_3D := Halfway_Vector (L, V);
   begin
      Check ("3.1 Symmetrical vectors produce purely vertical halfway vector", Approx (H.X, 0.0));
      Check ("3.2 Halfway vector vertical component is 1.0", Approx (H.Y, 1.0));
      Check ("3.3 Halfway vector has unit length", Approx (Norm (H), 1.0));
   end;

   --  TEST 4 — Barycentric Normal Interpolation
   Put_Line ("TEST 4 — Barycentric Normal Interpolation");
   declare
      Normals : constant Triangle_Normals :=
        (N0 => (0.0, 1.0, 0.0),
         N1 => (1.0, 0.0, 0.0),
         N2 => (0.0, 0.0, 1.0));
      N_Vertex0 : constant Unit_Vector_3D := Interpolate_Normal (Normals, 1.0, 0.0, 0.0);
      N_Mid     : constant Unit_Vector_3D := Interpolate_Normal (Normals, 0.5, 0.5, 0.0);
      Expected  : constant Real := Real_Math.Sqrt (0.5);
   begin
      Check ("4.1 Pure vertex normal matches exactly", Approx (N_Vertex0.Y, 1.0));
      Check ("4.2 Normal length after interpolation is normalized", Approx (Norm (N_Mid), 1.0));
      Check ("4.3 Midpoint normal has equal components", Approx (N_Mid.X, Expected) and then Approx (N_Mid.Y, Expected));
   end;

   --  TEST 5 — Color Space Operations & Clamping
   Put_Line ("TEST 5 — Color Space Operations and Clamping");
   declare
      C1 : constant Color_RGB := Make_Color (0.8, 0.4, 0.2);
      C2 : constant Color_RGB := Make_Color (0.5, 0.8, 0.9);
      Sum_C : constant Color_RGB := Add_Colors (C1, C2);
      Mod_C : constant Color_RGB := Modulate_Colors (C1, C2);
      Scale_C : constant Color_RGB := Scale_Color (C1, 0.5);
   begin
      Check ("5.1 Addition clamps red channel at 1.0", Approx (Real (Sum_C.R), 1.0));
      Check ("5.2 Modulation computes channel-wise product", Approx (Real (Mod_C.R), 0.4));
      Check ("5.3 Scaling scales channel intensity correctly", Approx (Real (Scale_C.R), 0.4));
   end;

   --  TEST 6 — Distance Attenuation Formulation
   Put_Line ("TEST 6 — Distance Attenuation Formulation");
   declare
      Atten_Zero : constant Light_Attenuation := (Constant_Term => 1.0, Linear_Term => 0.0, Quadratic_Term => 0.0);
      Atten_Quad : constant Light_Attenuation := (Constant_Term => 1.0, Linear_Term => 0.0, Quadratic_Term => 1.0);
      A0 : constant Real := Compute_Attenuation (10.0, Atten_Zero);
      A1 : constant Real := Compute_Attenuation (3.0, Atten_Quad);
   begin
      Check ("6.1 Constant attenuation gives unity factor", Approx (A0, 1.0));
      Check ("6.2 Quadratic attenuation matches inverse polynomial", Approx (A1, 0.1));
      Check ("6.3 Attenuation at distance 0 is 1.0", Approx (Compute_Attenuation (0.0, Atten_Quad), 1.0));
   end;

   --  TEST 7 — Classic Phong Point Light (Frontal vs Specular Peak)
   Put_Line ("TEST 7 — Classic Phong Point Light Illumination");
   declare
      Pos   : constant Vector_3D := (0.0, 0.0, 0.0);
      Norm  : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      View  : constant Unit_Vector_3D := Normalize ((0.0, 1.0, 1.0));
      Light : constant Point_Light :=
        (Position    => (0.0, 10.0, 10.0),
         Color       => (1.0, 1.0, 1.0),
         Attenuation => (1.0, 0.0, 0.0));
      Res   : constant Color_RGB :=
        Classic_Phong_Light (Pos, Norm, View, Light, Default_Mat, White_Ambient);
   begin
      Check ("7.1 Frontal lighting emits non-zero red intensity", Real (Res.R) > 0.1);
      Check ("7.2 Color channels remain balanced for white source", Approx (Real (Res.R), Real (Res.G)));
      Check ("7.3 Maximum channel does not overflow 1.0", Real (Res.R) <= 1.0);
   end;

   --  TEST 8 — Back-Face and Shadow Illumination (Ambient only)
   Put_Line ("TEST 8 — Back-Face and Shadow Illumination");
   declare
      Pos   : constant Vector_3D := (0.0, 0.0, 0.0);
      Norm  : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      View  : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      Light_Behind : constant Point_Light :=
        (Position    => (0.0, -10.0, 0.0),
         Color       => (1.0, 1.0, 1.0),
         Attenuation => (1.0, 0.0, 0.0));
      Res : constant Color_RGB :=
        Classic_Phong_Light (Pos, Norm, View, Light_Behind, Default_Mat, White_Ambient);
   begin
      Check ("8.1 Light from behind produces zero diffuse component", Approx (Real (Res.R), 0.1));
      Check ("8.2 Green channel equals pure ambient term", Approx (Real (Res.G), 0.1));
      Check ("8.3 Blue channel equals pure ambient term", Approx (Real (Res.B), 0.1));
   end;

   --  TEST 9 — Blinn-Phong Point Light Specular Peak
   Put_Line ("TEST 9 — Blinn-Phong Point Light Specular Peak");
   declare
      Pos   : constant Vector_3D := (0.0, 0.0, 0.0);
      Norm  : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      View  : constant Unit_Vector_3D := Normalize ((0.0, 1.0, 1.0));
      Light : constant Point_Light :=
        (Position    => (0.0, 10.0, 10.0),
         Color       => (1.0, 1.0, 1.0),
         Attenuation => (1.0, 0.0, 0.0));
      Res_Blinn : constant Color_RGB :=
        Blinn_Phong_Light (Pos, Norm, View, Light, Default_Mat, White_Ambient);
      Res_Classic : constant Color_RGB :=
        Classic_Phong_Light (Pos, Norm, View, Light, Default_Mat, White_Ambient);
   begin
      Check ("9.1 Blinn-Phong produces valid illuminated range", Real (Res_Blinn.R) > 0.1);
      Check ("9.2 Blinn-Phong and Classic Phong are both bright on specular peak",
             Real (Res_Blinn.R) > 0.5 and then Real (Res_Classic.R) > 0.5);
      Check ("9.3 Channel balance holds for Blinn-Phong with white light",
             Approx (Real (Res_Blinn.R), Real (Res_Blinn.B)));
   end;

   --  TEST 10 — Classic Phong Directional Light
   Put_Line ("TEST 10 — Classic Phong Directional Light");
   declare
      Norm      : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      View      : constant Unit_Vector_3D := Normalize ((0.0, 1.0, 1.0));
      Dir_Light : constant Directional_Light :=
        (Direction => Normalize ((0.0, -1.0, -1.0)),
         Color     => (1.0, 0.5, 0.2));
      Res : constant Color_RGB :=
        Classic_Phong_Directional (Norm, View, Dir_Light, Default_Mat, (0.2, 0.2, 0.2));
   begin
      Check ("10.1 Directional light colors red channel strongly", Real (Res.R) > Real (Res.G));
      Check ("10.2 Directional light green channel higher than blue", Real (Res.G) > Real (Res.B));
      Check ("10.3 Attenuation is infinite (no distance decay)", Real (Res.R) > 0.2);
   end;

   --  TEST 11 — Blinn-Phong Directional Light
   Put_Line ("TEST 11 — Blinn-Phong Directional Light");
   declare
      Norm      : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      View      : constant Unit_Vector_3D := Normalize ((0.0, 1.0, 1.0));
      Dir_Light : constant Directional_Light :=
        (Direction => Normalize ((0.0, -1.0, -1.0)),
         Color     => (1.0, 0.5, 0.2));
      Res : constant Color_RGB :=
        Blinn_Phong_Directional (Norm, View, Dir_Light, Default_Mat, (0.2, 0.2, 0.2));
   begin
      Check ("11.1 Blinn-Phong directional calculates non-zero response", Real (Res.R) > 0.0);
      Check ("11.2 Preserves input color hue predominance", Real (Res.R) > Real (Res.B));
      Check ("11.3 Ambient floor is preserved", Real (Res.B) >= 0.02);
   end;

   --  TEST 12 — Error Handling: Zero Vectors & Degenerate Barycentrics
   Put_Line ("TEST 12 — Error Handling for Degenerate Inputs");
   declare
      Zero_Caught : Boolean := False;
      Bary_Caught : Boolean := False;
      Degen_Norm_Caught : Boolean := False;
      Normals : constant Triangle_Normals :=
        (N0 => (1.0, 0.0, 0.0),
         N1 => (-1.0, 0.0, 0.0),
         N2 => (0.0, 0.0, 0.0));
      Dummy_V : Unit_Vector_3D;
      pragma Unreferenced (Dummy_V);
   begin
      begin
         Dummy_V := Normalize ((0.0, 0.0, 0.0));
      exception
         when Zero_Vector_Error =>
            Zero_Caught := True;
      end;

      begin
         Dummy_V := Interpolate_Normal (Normals, 0.8, 0.8, 0.2);
      exception
         when Invalid_Barycentric_Coord =>
            Bary_Caught := True;
      end;

      begin
         Dummy_V := Interpolate_Normal (Normals, 0.5, 0.5, 0.0);
      exception
         when Degenerate_Normal_Error =>
            Degen_Norm_Caught := True;
      end;

      Check ("12.1 Zero vector normalization raises Zero_Vector_Error", Zero_Caught);
      Check ("12.2 Non-unitary barycentric coords raise Invalid_Barycentric_Coord", Bary_Caught);
      Check ("12.3 Opposing normal cancellation raises Degenerate_Normal_Error", Degen_Norm_Caught);
   end;

   --  TEST 13 — Material Shininess Invariant (High vs Low Exponent)
   Put_Line ("TEST 13 — Material Shininess Invariant");
   declare
      Pos   : constant Vector_3D := (0.0, 0.0, 0.0);
      Norm  : constant Unit_Vector_3D := (0.0, 1.0, 0.0);
      --  Off-axis viewing angle to test lobe falloff
      View  : constant Unit_Vector_3D := Normalize ((0.2, 0.8, 0.5));
      Light : constant Point_Light :=
        (Position    => (0.0, 10.0, 10.0),
         Color       => (1.0, 1.0, 1.0),
         Attenuation => (1.0, 0.0, 0.0));

      Mat_Rough : Material_Properties := Default_Mat;
      Mat_Shiny : Material_Properties := Default_Mat;

      Res_Rough : Color_RGB;
      Res_Shiny : Color_RGB;
   begin
      Mat_Rough.Shininess := 2.0;
      Mat_Shiny.Shininess := 256.0;

      Res_Rough := Classic_Phong_Light (Pos, Norm, View, Light, Mat_Rough, (0.0, 0.0, 0.0));
      Res_Shiny := Classic_Phong_Light (Pos, Norm, View, Light, Mat_Shiny, (0.0, 0.0, 0.0));

      Check ("13.1 Broader specular lobe yields higher off-axis intensity",
             Real (Res_Rough.R) > Real (Res_Shiny.R));
      Check ("13.2 Narrow specular lobe preserves non-negative color",
             Real (Res_Shiny.R) >= 0.0);
      Check ("13.3 Diffuse contributions remain invariant across shininess shifts",
             Approx (Real (Res_Rough.R) - Real (Res_Shiny.R),
                     Real (Res_Rough.G) - Real (Res_Shiny.G)));
   end;

   --  Summary
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
