--  Standalone test suite and API demonstration for Gouraud Shading
--  Compliant with Ada 2022 / Ada 2023 (ISO/IEC 8652:2023)

with Ada.Text_IO; use Ada.Text_IO;
with Gouraud_Shading; use Gouraud_Shading;

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

   function Approx_Eq (A, B : Real; Tol : Real := 1.0e-4) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx_Eq;

   function Color_Approx_Eq (C1, C2 : RGB_Color; Tol : Real := 1.0e-3) return Boolean is
   begin
      return Approx_Eq (Real (C1.R), Real (C2.R), Tol) and then
             Approx_Eq (Real (C1.G), Real (C2.G), Tol) and then
             Approx_Eq (Real (C1.B), Real (C2.B), Tol);
   end Color_Approx_Eq;

begin
   --  TEST 1 -- Vector Geometry and Normalization
   Put_Line ("TEST 1 -- Vector Geometry and Normalization");
   declare
      V1 : constant Vector_3D := (X => 3.0, Y => 0.0, Z => 4.0);
      Len : constant Real := Vector_Length (V1);
      Norm : constant Vector_3D := Normalize (V1);
      Dot : constant Real := Dot_Product (Norm, Norm);
   begin
      Check ("1.1 Vector magnitude calculation is accurate (3,0,4 -> 5)", Approx_Eq (Len, 5.0));
      Check ("1.2 Normalized vector components are correct (3/5, 0, 4/5)", Approx_Eq (Norm.X, 0.6) and then Approx_Eq (Norm.Z, 0.8));
      Check ("1.3 Normalized vector dot product with itself is 1.0", Approx_Eq (Dot, 1.0));
   end;

   --  TEST 2 -- Vector Cross Product Orthogonality
   Put_Line ("TEST 2 -- Vector Cross Product Orthogonality");
   declare
      UX : constant Vector_3D := (X => 1.0, Y => 0.0, Z => 0.0);
      UY : constant Vector_3D := (X => 0.0, Y => 1.0, Z => 0.0);
      UZ : constant Vector_3D := Cross_Product (UX, UY);
   begin
      Check ("2.1 Cross product X and Y yields positive Z", Approx_Eq (UZ.Z, 1.0));
      Check ("2.2 Orthogonal cross product dot with UX is 0", Approx_Eq (Dot_Product (UZ, UX), 0.0));
      Check ("2.3 Orthogonal cross product dot with UY is 0", Approx_Eq (Dot_Product (UZ, UY), 0.0));
   end;

   --  TEST 3 -- Color Operations and Clamping
   Put_Line ("TEST 3 -- Color Operations and Clamping");
   declare
      C1 : constant RGB_Color := (R => 0.6, G => 0.3, B => 0.1);
      C2 : constant RGB_Color := (R => 0.6, G => 0.8, B => 0.2);
      Sum_C : constant RGB_Color := Add_Colors (C1, C2);
      Scaled : constant RGB_Color := Scale_Color (C1, 0.5);
      Mult : constant RGB_Color := Multiply_Colors (C1, C2);
      Expected_Scaled : constant RGB_Color := (R => 0.3, G => 0.15, B => 0.05);
   begin
      Check ("3.1 Add colors clamps red component to 1.0", Approx_Eq (Real (Sum_C.R), 1.0));
      Check ("3.2 Scale color matches expected color record", Color_Approx_Eq (Scaled, Expected_Scaled));
      Check ("3.3 Multiply colors modulates channels correctly", Approx_Eq (Real (Mult.R), 0.36));
   end;

   --  TEST 4 -- Linear Interpolation (Scalar & Color Lerp)
   Put_Line ("TEST 4 -- Linear Interpolation");
   declare
      I1 : constant Intensity := 0.2;
      I2 : constant Intensity := 0.8;
      Mid_I : constant Intensity := Lerp_Intensity (I1, I2, 0.5);
      Col1 : constant RGB_Color := (R => 0.0, G => 0.5, B => 1.0);
      Col2 : constant RGB_Color := (R => 1.0, G => 0.5, B => 0.0);
      Mid_Col : constant RGB_Color := Lerp_Color (Col1, Col2, 0.5);
      Expected_Col : constant RGB_Color := (R => 0.5, G => 0.5, B => 0.5);
   begin
      Check ("4.1 Midpoint scalar interpolation is 0.5", Approx_Eq (Real (Mid_I), 0.5));
      Check ("4.2 Color lerp matches expected intermediate color", Color_Approx_Eq (Mid_Col, Expected_Col));
      Check ("4.3 Color lerp at T=0.5 preserves constant Green", Approx_Eq (Real (Mid_Col.G), 0.5));
   end;

   --  TEST 5 -- Vertex Normal Averaging (Gouraud Smoothing)
   Put_Line ("TEST 5 -- Vertex Normal Averaging Across Adjacent Faces");
   declare
      --  Two triangles sharing an edge along the Z-axis (V1=(0,0,0) and V2=(0,0,1)).
      --  V3=(-1,1,0) forms the left facet; V4=(1,1,0) forms the right facet.
      --  Counter-clockwise winding orders produce outward normals with +Y components:
      --    Tri 1: V1 -> V3 -> V2  => (P3 - P1) x (P2 - P1) has +Y
      --    Tri 2: V1 -> V2 -> V4  => (P2 - P1) x (P4 - P1) has +Y
      Verts : constant Vertex_3D_Array :=
        [(Pos => (X => 0.0, Y => 0.0, Z => 0.0), Normal => (X => 0.0, Y => 0.0, Z => 0.0)),
         (Pos => (X => 0.0, Y => 0.0, Z => 1.0), Normal => (X => 0.0, Y => 0.0, Z => 0.0)),
         (Pos => (X => -1.0, Y => 1.0, Z => 0.0), Normal => (X => 0.0, Y => 0.0, Z => 0.0)),
         (Pos => (X => 1.0, Y => 1.0, Z => 0.0), Normal => (X => 0.0, Y => 0.0, Z => 0.0))];

      Tris : constant Triangle_Index_Array :=
        [(V1 => 1, V2 => 3, V3 => 2),
         (V1 => 1, V2 => 2, V3 => 4)];

      Averaged_Normals : constant Vector_3D_Array := Compute_Vertex_Normals (Verts, Tris);
   begin
      Check ("5.1 Resulting array length matches vertex count", Averaged_Normals'Length = 4);
      --  Shared vertices 1 and 2 should have symmetric normal pointing upward in +Y direction with X=0
      Check ("5.2 Shared vertex 1 normal has symmetric X cancellation", Approx_Eq (Averaged_Normals (1).X, 0.0));
      Check ("5.3 Shared vertex 1 normal has positive upward Y orientation", Averaged_Normals (1).Y > 0.0);
   end;

   --  TEST 6 -- Vertex Illumination: Lambertian Reflectance
   Put_Line ("TEST 6 -- Lambertian Vertex Lighting");
   declare
      Normal_Z : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 1.0);
      Light_Direct : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 1.0);
      Light_Perp   : constant Vector_3D := (X => 1.0, Y => 0.0, Z => 0.0);
      Light_Back   : constant Vector_3D := (X => 0.0, Y => 0.0, Z => -1.0);

      I_Direct : constant Intensity :=
        Calculate_Vertex_Lambert_Intensity (Normal_Z, Light_Direct, Ambient => 0.1, Diffuse => 0.9);
      I_Perp : constant Intensity :=
        Calculate_Vertex_Lambert_Intensity (Normal_Z, Light_Perp, Ambient => 0.1, Diffuse => 0.9);
      I_Back : constant Intensity :=
        Calculate_Vertex_Lambert_Intensity (Normal_Z, Light_Back, Ambient => 0.1, Diffuse => 0.9);
   begin
      Check ("6.1 Direct incidence yields maximum lighting (1.0)", Approx_Eq (Real (I_Direct), 1.0));
      Check ("6.2 Perpendicular light yields only ambient term (0.1)", Approx_Eq (Real (I_Perp), 0.1));
      Check ("6.3 Back-facing light is clamped to ambient term (0.1)", Approx_Eq (Real (I_Back), 0.1));
   end;

   --  TEST 7 -- Vertex Illumination: Full Phong / Blinn-Phong Shading
   Put_Line ("TEST 7 -- Vertex Phong Illumination Model");
   declare
      Pos : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 0.0);
      Norm : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 1.0);
      View : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 5.0);
      Light : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 5.0);
      Light_Col : constant RGB_Color := (R => 1.0, G => 1.0, B => 1.0);
      Mat_Col : constant RGB_Color := (R => 0.8, G => 0.0, B => 0.0);

      Lit_Color : constant RGB_Color :=
        Calculate_Vertex_Phong_Color
          (Position       => Pos,
           Normal         => Norm,
           View_Pos       => View,
           Light_Pos      => Light,
           Light_Color    => Light_Col,
           Material_Color => Mat_Col,
           Ka             => 0.1,
           Kd             => 0.6,
           Ks             => 0.3,
           Shininess      => 16.0);
   begin
      Check ("7.1 Red diffuse channel is illuminated", Real (Lit_Color.R) > 0.5);
      Check ("7.2 Specular highlight adds white light to green channel", Real (Lit_Color.G) > 0.1);
      Check ("7.3 Specular highlight adds white light to blue channel", Real (Lit_Color.B) > 0.1);
   end;

   --  TEST 8 -- Barycentric Gouraud Interpolation (Scalar Intensity)
   Put_Line ("TEST 8 -- Barycentric Gouraud Interpolation (Scalar)");
   declare
      V1 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 0.0, Y => 0.0), Intensity => 0.0);
      V2 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 10.0, Y => 0.0), Intensity => 1.0);
      V3 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 0.0, Y => 10.0), Intensity => 0.5);

      P_Center : constant Vertex_2D := (X => 10.0 / 3.0, Y => 10.0 / 3.0);
      I_Center : constant Intensity := Interpolate_Barycentric_Intensity (V1, V2, V3, P_Center);

      I_At_V2 : constant Intensity := Interpolate_Barycentric_Intensity (V1, V2, V3, V2.Pos);

      I_Edge : constant Intensity := Interpolate_Barycentric_Intensity (V1, V2, V3, (X => 5.0, Y => 0.0));
   begin
      Check ("8.1 Center point is average of vertex intensities (0.5)", Approx_Eq (Real (I_Center), 0.5, 0.01));
      Check ("8.2 Interpolation exactly at vertex V2 yields 1.0", Approx_Eq (Real (I_At_V2), 1.0));
      Check ("8.3 Interpolation on edge midpoint yields 0.5", Approx_Eq (Real (I_Edge), 0.5));
   end;

   --  TEST 9 -- Barycentric Gouraud Interpolation (RGB Color)
   Put_Line ("TEST 9 -- Barycentric Gouraud Interpolation (RGB Color)");
   declare
      V1 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 0.0, Y => 0.0), Color => (R => 1.0, G => 0.0, B => 0.0));
      V2 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 10.0, Y => 0.0), Color => (R => 0.0, G => 1.0, B => 0.0));
      V3 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 0.0, Y => 10.0), Color => (R => 0.0, G => 0.0, B => 1.0));

      P_Centroid : constant Vertex_2D := (X => 10.0 / 3.0, Y => 10.0 / 3.0);
      C_Centroid : constant RGB_Color := Interpolate_Barycentric_Color (V1, V2, V3, P_Centroid);
      Expected_Centroid : constant RGB_Color :=
        (R => Color_Component (1.0 / 3.0),
         G => Color_Component (1.0 / 3.0),
         B => Color_Component (1.0 / 3.0));
   begin
      Check ("9.1 Centroid Red is ~0.333", Approx_Eq (Real (C_Centroid.R), 1.0 / 3.0, 0.01));
      Check ("9.2 Centroid Green is ~0.333", Approx_Eq (Real (C_Centroid.G), 1.0 / 3.0, 0.01));
      Check ("9.3 Centroid color matches expected average", Color_Approx_Eq (C_Centroid, Expected_Centroid, 0.02));
   end;

   --  TEST 10 -- Scanline Rasterization (RGB Gradient)
   Put_Line ("TEST 10 -- Scanline Rasterization (RGB Triangle)");
   declare
      FB : Framebuffer (0 .. 15, 0 .. 15) :=
        [others => [others => (R => 0.0, G => 0.0, B => 0.0)]];

      V1 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 2.0, Y => 2.0), Color => (R => 1.0, G => 0.0, B => 0.0));
      V2 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 12.0, Y => 2.0), Color => (R => 0.0, G => 1.0, B => 0.0));
      V3 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 2.0, Y => 12.0), Color => (R => 0.0, G => 0.0, B => 1.0));
   begin
      Rasterize_Triangle_RGB (V1, V2, V3, FB);

      Check ("10.1 Pixel near vertex 1 has predominant Red", Real (FB (2, 2).R) > 0.8);
      Check ("10.2 Pixel near vertex 2 has predominant Green", Real (FB (2, 12).G) > 0.8);
      Check ("10.3 Interior pixel has non-zero mixed channels",
             Real (FB (4, 4).R) > 0.0 and then Real (FB (4, 4).G) > 0.0 and then Real (FB (4, 4).B) > 0.0);
   end;

   --  TEST 11 -- Scanline Rasterization (Scalar Intensity Mode)
   Put_Line ("TEST 11 -- Scanline Rasterization (Scalar Mode)");
   declare
      FB : Framebuffer (0 .. 10, 0 .. 10) :=
        [others => [others => (R => 0.0, G => 0.0, B => 0.0)]];

      V1 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 0.0, Y => 0.0), Intensity => 0.0);
      V2 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 10.0, Y => 0.0), Intensity => 1.0);
      V3 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 5.0, Y => 10.0), Intensity => 0.5);

      Tint : constant RGB_Color := (R => 0.0, G => 1.0, B => 0.0);
   begin
      Rasterize_Triangle_Scalar (V1, V2, V3, FB, Base_Color => Tint);

      Check ("11.1 Pixel near low intensity corner is dark", Real (FB (0, 0).G) < 0.2);
      Check ("11.2 Pixel near high intensity corner is bright green", Real (FB (0, 10).G) > 0.8);
      Check ("11.3 Red and Blue channels remain zero",
             Real (FB (5, 5).R) = 0.0 and then Real (FB (5, 5).B) = 0.0);
   end;

   --  TEST 12 -- Edge Cases: Degenerate Triangles and Collinearity
   Put_Line ("TEST 12 -- Edge Cases and Degenerate Geometry");
   declare
      V1 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 0.0, Y => 0.0), Intensity => 0.2);
      V2 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 2.0, Y => 2.0), Intensity => 0.5);
      V3 : constant Shaded_Vertex_Scalar :=
        (Pos => (X => 4.0, Y => 4.0), Intensity => 0.8);

      P : constant Vertex_2D := (X => 1.0, Y => 1.0);
      Exception_Caught : Boolean := False;
   begin
      begin
         declare
            Unused_I : constant Intensity := Interpolate_Barycentric_Intensity (V1, V2, V3, P);
            pragma Unreferenced (Unused_I);
         begin
            null;
         end;
      exception
         when Degenerate_Triangle_Error =>
            Exception_Caught := True;
      end;
      Check ("12.1 Collinear points raise Degenerate_Triangle_Error", Exception_Caught);

      declare
         FB : Framebuffer (0 .. 5, 0 .. 5) :=
           [others => [others => (R => 0.0, G => 0.0, B => 0.0)]];
         Flat_V1 : constant Shaded_Vertex_RGB :=
           (Pos => (X => 0.0, Y => 2.0), Color => (R => 1.0, G => 0.0, B => 0.0));
         Flat_V2 : constant Shaded_Vertex_RGB :=
           (Pos => (X => 2.0, Y => 2.0), Color => (R => 0.0, G => 1.0, B => 0.0));
         Flat_V3 : constant Shaded_Vertex_RGB :=
           (Pos => (X => 4.0, Y => 2.0), Color => (R => 0.0, G => 0.0, B => 1.0));
      begin
         Rasterize_Triangle_RGB (Flat_V1, Flat_V2, Flat_V3, FB);
         Check ("12.2 Rasterizing flat triangle completes without panic", True);
         Check ("12.3 Flat triangle leaves surrounding cells uncorrupted", Real (FB (0, 0).R) = 0.0);
      end;
   end;

   --  TEST 13 -- Error Handling: Zero Normals and Out of Bounds Indexing
   Put_Line ("TEST 13 -- Error Handling");
   declare
      Zero_V : constant Vector_3D := (X => 0.0, Y => 0.0, Z => 0.0);
      Invalid_Normal_Caught : Boolean := False;
      Bounds_Error_Caught    : Boolean := False;

      Verts : constant Vertex_3D_Array :=
        [(Pos => (X => 0.0, Y => 0.0, Z => 0.0), Normal => (X => 0.0, Y => 0.0, Z => 1.0))];
      Invalid_Tris : constant Triangle_Index_Array :=
        [(V1 => 1, V2 => 2, V3 => 3)];
   begin
      begin
         declare
            Unused_N : constant Vector_3D := Normalize (Zero_V);
            pragma Unreferenced (Unused_N);
         begin
            null;
         end;
      exception
         when Invalid_Normal_Error =>
            Invalid_Normal_Caught := True;
      end;
      Check ("13.1 Normalizing zero-length vector raises Invalid_Normal_Error", Invalid_Normal_Caught);

      begin
         declare
            Unused_Norms : constant Vector_3D_Array := Compute_Vertex_Normals (Verts, Invalid_Tris);
            pragma Unreferenced (Unused_Norms);
         begin
            null;
         end;
      exception
         when Constraint_Error =>
            Bounds_Error_Caught := True;
      end;
      Check ("13.2 Invalid vertex index raises Constraint_Error", Bounds_Error_Caught);

      Check ("13.3 Math clamps avoid NaN or out of bounds intensity",
             Approx_Eq (Real (Clamp_Intensity (1.5)), 1.0) and then
             Approx_Eq (Real (Clamp_Intensity (-0.5)), 0.0));
   end;

   --  TEST 14 -- Precision and Monotonicity across Scanline Span
   Put_Line ("TEST 14 -- Scanline Monotonicity and Edge Clamping");
   declare
      FB : Framebuffer (0 .. 20, 0 .. 20) :=
        [others => [others => (R => 0.0, G => 0.0, B => 0.0)]];

      V1 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 0.0, Y => 0.0), Color => (R => 0.0, G => 0.0, B => 0.0));
      V2 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 10.0, Y => 0.0), Color => (R => 1.0, G => 0.0, B => 0.0));
      V3 : constant Shaded_Vertex_RGB :=
        (Pos => (X => 10.0, Y => 10.0), Color => (R => 1.0, G => 0.0, B => 0.0));
   begin
      Rasterize_Triangle_RGB (V1, V2, V3, FB);

      Check ("14.1 Start of span is dark", Real (FB (0, 0).R) < 0.1);
      Check ("14.2 End of span is bright red", Real (FB (0, 10).R) > 0.9);
      Check ("14.3 Intermediate pixel is intermediate shade",
             Real (FB (0, 5).R) >= Real (FB (0, 2).R) and then
             Real (FB (0, 8).R) >= Real (FB (0, 5).R));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
