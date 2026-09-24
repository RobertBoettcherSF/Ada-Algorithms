--  Standalone test suite for Isosurfaces (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Isosurfaces; use Isosurfaces;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-4) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Approx_Vec (A, B : Vec3; Tol : Real := 1.0E-3) return Boolean is
   begin
      return Approx (A.X, B.X, Tol)
        and then Approx (A.Y, B.Y, Tol)
        and then Approx (A.Z, B.Z, Tol);
   end Approx_Vec;

begin
   Put_Line ("Isosurfaces test suite");
   Put_Line ("======================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers");
   ---------------------------------------------------------------------
   declare
      V  : constant Vec3 := (3.0, 0.0, 4.0);
      N  : constant Normal3 := Normalize (V);
      D  : constant Real := Dot ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Cr : constant Vec3 := Cross ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Sm : constant Vec3 := (1.0, 2.0, 3.0) + (4.0, 5.0, 6.0);
      Sc : constant Vec3 := 2.0 * (1.0, 1.5, 2.0);
   begin
      Check (Approx (Length (V), 5.0), "Length of (3,0,4) is 5");
      Check (Approx (Length (N), 1.0), "Normalize yields unit length");
      Check (abs (D) <= 1.0E-5, "Dot of orthogonal axes is 0");
      Check (Approx (Cr.Z, 1.0), "Cross i x j = k");
      Check (Approx (Sm.X, 5.0) and then Approx (Sm.Z, 9.0),
             "Vector addition");
      Check (Approx (Sc.Y, 3.0), "Scalar multiply");
   end;

   ---------------------------------------------------------------------
   Section ("2. Clamp / Distance / Cube_Corner_Offset");
   ---------------------------------------------------------------------
   declare
      C1   : constant Real := Clamp (5.0, 0.0, 1.0);
      C2   : constant Real := Clamp (-1.0, 0.0, 1.0);
      Dist : constant Non_Negative :=
        Distance_Between ((0.0, 0.0, 0.0), (0.0, 0.0, 3.0));
      O6   : constant Vec3 := Cube_Corner_Offset (6);
      O0   : constant Vec3 := Cube_Corner_Offset (0);
   begin
      Check (C1 = 1.0, "Clamp upper bound");
      Check (C2 = 0.0, "Clamp lower bound");
      Check (Approx (Dist, 3.0), "Distance_Between along Z");
      Check (Approx_Vec (O0, (0.0, 0.0, 0.0)), "Corner 0 at origin");
      Check (Approx_Vec (O6, (1.0, 1.0, 1.0)), "Corner 6 at (1,1,1)");
   end;

   ---------------------------------------------------------------------
   Section ("3. Evaluate_Field / Sample_Trilinear");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 2, 0 .. 2, 0 .. 2);
      Pos  : Position_Grid3 (0 .. 2, 0 .. 2, 0 .. 2);
      Mid  : Real;
      Corner : Real;
   begin
      Fill_Sphere_SDF
        (Vals, Pos, Origin => (0.0, 0.0, 0.0), Spacing => 1.0,
         Center => (1.0, 1.0, 1.0), Radius => 0.5);
      Corner := Evaluate_Field (Vals, 1, 1, 1);
      Check (Approx (Corner, -0.5, 0.05), "SDF at sphere center = -R");
      Check (Evaluate_Field (Vals, 0, 0, 0) > Corner,
             "Corner farther than center (larger SDF)");
      Mid := Sample_Trilinear (Vals, Pos, (1.0, 1.0, 1.0));
      Check (Approx (Mid, Corner, 0.05), "Trilinear at node matches sample");
      declare
         Edge : constant Real := Sample_Trilinear (Vals, Pos, (0.5, 1.0, 1.0));
      begin
         Check (Edge > Corner, "Trilinear between center and outside > center");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Is_Inside / Classify_Vertex");
   ---------------------------------------------------------------------
   declare
      Iso : constant Iso_Level := 0.0;
   begin
      Check (Is_Inside (-1.0, Iso), "Negative value is inside");
      Check (not Is_Inside (1.0, Iso), "Positive value is outside");
      Check (Classify_Vertex (-2.0, Iso) = Inside, "Classify Inside");
      Check (Classify_Vertex (2.0, Iso) = Outside, "Classify Outside");
      Check (Classify_Vertex (0.0, Iso, 1.0E-4) = On_Surface,
             "Classify On_Surface at isolevel");
   end;

   ---------------------------------------------------------------------
   Section ("5. Estimate_Gradient / Estimate_Normal");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 4, 0 .. 4, 0 .. 4);
      Pos  : Position_Grid3 (0 .. 4, 0 .. 4, 0 .. 4);
      G    : Vec3;
      N    : Normal3;
   begin
      for I in Vals'Range (1) loop
         for J in Vals'Range (2) loop
            for K in Vals'Range (3) loop
               Pos (I, J, K) := (Real (I), Real (J), Real (K));
               Vals (I, J, K) := Real (K);  -- f = Z
            end loop;
         end loop;
      end loop;
      G := Estimate_Gradient (Vals, Pos, 2, 2, 2);
      N := Estimate_Normal (Vals, Pos, 2, 2, 2);
      Check (Approx (G.X, 0.0, 0.05), "Gradient of f=Z has Gx≈0");
      Check (Approx (G.Y, 0.0, 0.05), "Gradient of f=Z has Gy≈0");
      Check (Approx (G.Z, 1.0, 0.05), "Gradient of f=Z has Gz≈1");
      Check (Approx_Vec (N, (0.0, 0.0, 1.0), 0.05), "Normal of f=Z is +Z");
   end;

   ---------------------------------------------------------------------
   Section ("6. Marching_Tetrahedra_Cell");
   ---------------------------------------------------------------------
   declare
      Tris : Small_Triangle_List;
      Cnt  : Natural;
      --  Unit cube with bottom below and top above isolevel 0 → planar cut.
   begin
      Marching_Tetrahedra_Cell
        (P0 => (0.0, 0.0, 0.0), P1 => (1.0, 0.0, 0.0),
         P2 => (1.0, 1.0, 0.0), P3 => (0.0, 1.0, 0.0),
         P4 => (0.0, 0.0, 1.0), P5 => (1.0, 0.0, 1.0),
         P6 => (1.0, 1.0, 1.0), P7 => (0.0, 1.0, 1.0),
         S0 => -1.0, S1 => -1.0, S2 => -1.0, S3 => -1.0,
         S4 =>  1.0, S5 =>  1.0, S6 =>  1.0, S7 =>  1.0,
         Isolevel => 0.0, Out_Tris => Tris, Out_Count => Cnt);
      Check (Cnt > 0, "Tet cell emits triangles for Z-plane cut");
      Check (Cnt <= 12, "Tet cell count within capacity");
      Check (Cnt >= 2, "Planar cut yields multiple triangles");
      declare
         Empty_Cnt : Natural;
         Empty_Tris : Small_Triangle_List;
      begin
         Marching_Tetrahedra_Cell
           (P0 => (0.0, 0.0, 0.0), P1 => (1.0, 0.0, 0.0),
            P2 => (1.0, 1.0, 0.0), P3 => (0.0, 1.0, 0.0),
            P4 => (0.0, 0.0, 1.0), P5 => (1.0, 0.0, 1.0),
            P6 => (1.0, 1.0, 1.0), P7 => (0.0, 1.0, 1.0),
            S0 => 1.0, S1 => 1.0, S2 => 1.0, S3 => 1.0,
            S4 => 1.0, S5 => 1.0, S6 => 1.0, S7 => 1.0,
            Isolevel => 0.0, Out_Tris => Empty_Tris, Out_Count => Empty_Cnt);
         Check (Empty_Cnt = 0, "All-outside cube emits zero triangles");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Extract_Via_Surface_Nets_Lite");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 6, 0 .. 6, 0 .. 6);
      Pos  : Position_Grid3 (0 .. 6, 0 .. 6, 0 .. 6);
      M    : Mesh;
      Stats : Mesh_Stats;
   begin
      Fill_Sphere_SDF
        (Vals, Pos, (0.0, 0.0, 0.0), 1.0, (3.0, 3.0, 3.0), 2.0);
      M := Extract_Via_Surface_Nets_Lite (Vals, Pos, 0.0);
      Stats := Compute_Mesh_Stats (M);
      Check (Count_Triangles (M) > 0, "Surface Nets sphere mesh non-empty");
      Check (Stats.Triangle_Count = Count_Triangles (M),
             "Stats triangle count matches");
      Check (Stats.Vertex_Slots = Count_Triangles (M) * 3,
             "Stats vertex slots = 3 * tris");
      Check (Stats.Min_Corner.X >= -0.1
               and then Stats.Max_Corner.X <= 6.1,
             "Surface Nets mesh AABB inside grid");
   end;

   ---------------------------------------------------------------------
   Section ("8. Extract_Via_Dual_Contouring_Lite");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 6, 0 .. 6, 0 .. 6);
      Pos  : Position_Grid3 (0 .. 6, 0 .. 6, 0 .. 6);
      M    : Mesh;
      Ms   : Mesh;
   begin
      Fill_Sphere_SDF
        (Vals, Pos, (0.0, 0.0, 0.0), 1.0, (3.0, 3.0, 3.0), 2.0);
      M := Extract_Via_Dual_Contouring_Lite (Vals, Pos, 0.0);
      Ms := Extract_Via_Surface_Nets_Lite (Vals, Pos, 0.0);
      Check (Count_Triangles (M) > 0, "DC lite sphere mesh non-empty");
      Check (Count_Triangles (M) = Count_Triangles (Ms),
             "DC and Surface Nets share connectivity count");
      declare
         Mid : Point3 := (0.0, 0.0, 0.0);
         N   : Natural := 0;
      begin
         for I in 1 .. M.Count loop
            Mid := Mid + M.Tris (I).A + M.Tris (I).B + M.Tris (I).C;
            N := N + 3;
         end loop;
         if N > 0 then
            Mid := (1.0 / Real (N)) * Mid;
         end if;
         Check (Distance_Between (Mid, (3.0, 3.0, 3.0)) < 1.5,
                "DC mesh centroid near sphere center");
      end;
      Check (Count_Triangles (Empty_Mesh) = 0, "Empty_Mesh has zero tris");
   end;

   ---------------------------------------------------------------------
   Section ("9. Mesh helpers Append / Merge / Face_Normal");
   ---------------------------------------------------------------------
   declare
      M1, M2, M3 : Mesh;
      T : constant Triangle :=
        (A => (0.0, 0.0, 0.0), B => (1.0, 0.0, 0.0), C => (0.0, 1.0, 0.0),
         NA => (0.0, 0.0, 1.0), NB => (0.0, 0.0, 1.0), NC => (0.0, 0.0, 1.0));
      FN : Normal3;
   begin
      M1 := Empty_Mesh;
      Append_Triangle (M1, T);
      Check (Count_Triangles (M1) = 1, "Append_Triangle grows mesh");
      M2 := Empty_Mesh;
      Append_Triangle (M2, T);
      Append_Triangle (M2, T);
      M3 := Merge_Meshes (M1, M2);
      Check (Count_Triangles (M3) = 3, "Merge_Meshes concatenates");
      Append_Mesh (M1, M2);
      Check (Count_Triangles (M1) = 3, "Append_Mesh mutates destination");
      FN := Face_Normal (T);
      Check (Approx_Vec (FN, (0.0, 0.0, 1.0), 0.05),
             "Face_Normal of XY triangle is +Z");
   end;

   ---------------------------------------------------------------------
   Section ("10. Fill_Plane_Field");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 4, 0 .. 4, 0 .. 4);
      Pos  : Position_Grid3 (0 .. 4, 0 .. 4, 0 .. 4);
      M    : Mesh;
   begin
      Fill_Plane_Field
        (Vals, Pos, (0.0, 0.0, 0.0), 1.0,
         Plane_Point => (0.0, 0.0, 2.0),
         Plane_Normal => (0.0, 0.0, 1.0));
      Check (Approx (Evaluate_Field (Vals, 0, 0, 2), 0.0, 0.05),
             "Plane field zero on plane z=2");
      Check (Evaluate_Field (Vals, 0, 0, 0) < 0.0, "Below plane negative");
      Check (Evaluate_Field (Vals, 0, 0, 4) > 0.0, "Above plane positive");
      M := Extract_Via_Surface_Nets_Lite (Vals, Pos, 0.0);
      Check (Count_Triangles (M) > 0, "Plane Surface Nets non-empty");
   end;

   ---------------------------------------------------------------------
   Section ("11. Fill_Gyroid_Field");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 5, 0 .. 5, 0 .. 5);
      Pos  : Position_Grid3 (0 .. 5, 0 .. 5, 0 .. 5);
      M    : Mesh;
      V000 : Real;
   begin
      Fill_Gyroid_Field
        (Vals, Pos, Origin => (0.0, 0.0, 0.0), Spacing => 0.5, Scale => 1.0);
      V000 := Evaluate_Field (Vals, 0, 0, 0);
      --  gyroid at origin: sin0 cos0 + sin0 cos0 + sin0 cos0 = 0
      Check (Approx (V000, 0.0, 0.05), "Gyroid at origin ≈ 0");
      Check (abs (Evaluate_Field (Vals, 3, 2, 1)) < 4.0,
             "Gyroid values stay bounded");
      M := Extract_Via_Dual_Contouring_Lite (Vals, Pos, 0.0);
      Check (Count_Triangles (M) >= 0, "Gyroid DC extraction runs");
      Check (Pos (1, 1, 1).X > 0.0, "Gyroid positions spaced from origin");
   end;

   ---------------------------------------------------------------------
   Section ("12. Collect_Level_Set_Band");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 6, 0 .. 6, 0 .. 6);
      Pos  : Position_Grid3 (0 .. 6, 0 .. 6, 0 .. 6);
      Band : Level_Set_Band;
   begin
      Fill_Sphere_SDF
        (Vals, Pos, (0.0, 0.0, 0.0), 1.0, (3.0, 3.0, 3.0), 2.0);
      Band := Collect_Level_Set_Band (Vals, Pos, 0.0, 0.6);
      Check (Count_Band_Points (Band) > 0, "Band near sphere surface non-empty");
      Check (Count_Band_Points (Empty_Band) = 0, "Empty_Band has zero points");
      declare
         All_Near : Boolean := True;
      begin
         for I in 1 .. Band.Count loop
            if abs (Band.Values (I) - 0.0) > 0.6 + 1.0E-5 then
               All_Near := False;
            end if;
         end loop;
         Check (All_Near, "Every band sample within epsilon of isolevel");
      end;
      Check (Count_Band_Points
               (Collect_Level_Set_Band (Vals, Pos, 0.0, 0.01))
             <= Count_Band_Points (Band),
             "Tighter epsilon yields fewer-or-equal band points");
   end;

   ---------------------------------------------------------------------
   Section ("13. Exceptions");
   ---------------------------------------------------------------------
   declare
      Raised_Inv : Boolean := False;
      Raised_Deg : Boolean := False;
      Vals : Scalar_Grid3 (0 .. 2, 0 .. 2, 0 .. 2);
      Pos  : Position_Grid3 (0 .. 2, 0 .. 2, 0 .. 2);
   begin
      Fill_Sphere_SDF
        (Vals, Pos, (0.0, 0.0, 0.0), 1.0, (1.0, 1.0, 1.0), 0.5);
      begin
         declare
            Unused : Real;
         begin
            Unused := Sample_Trilinear (Vals, Pos, (-1.0, 0.0, 0.0));
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised_Inv := True;
      end;
      Check (Raised_Inv, "Out-of-bounds trilinear raises Invalid_Argument");

      begin
         declare
            Unused : Normal3;
         begin
            Unused := Normalize ((0.0, 0.0, 0.0));
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised_Deg := True;
      end;
      Check (Raised_Deg, "Normalize zero raises Degenerate_Geometry");

      Raised_Inv := False;
      begin
         Fill_Sphere_SDF
           (Vals, Pos, (0.0, 0.0, 0.0), -1.0, (1.0, 1.0, 1.0), 0.5);
      exception
         when Invalid_Argument =>
            Raised_Inv := True;
      end;
      Check (Raised_Inv, "Negative spacing raises Invalid_Argument");
      Check (Fail_Count = 0, "No failures before end of exception tests");
   end;

   ---------------------------------------------------------------------
   Section ("14. Sphere vs plane mesh distinction");
   ---------------------------------------------------------------------
   declare
      Vs, Vp : Scalar_Grid3 (0 .. 5, 0 .. 5, 0 .. 5);
      Ps, Pp : Position_Grid3 (0 .. 5, 0 .. 5, 0 .. 5);
      Ms, Mp : Mesh;
   begin
      Fill_Sphere_SDF
        (Vs, Ps, (0.0, 0.0, 0.0), 1.0, (2.5, 2.5, 2.5), 1.5);
      Fill_Plane_Field
        (Vp, Pp, (0.0, 0.0, 0.0), 1.0, (0.0, 0.0, 2.5), (0.0, 0.0, 1.0));
      Ms := Extract_Via_Surface_Nets_Lite (Vs, Ps, 0.0);
      Mp := Extract_Via_Surface_Nets_Lite (Vp, Pp, 0.0);
      Check (Count_Triangles (Ms) > 0, "Sphere SN mesh non-empty");
      Check (Count_Triangles (Mp) > 0, "Plane SN mesh non-empty");
      Check (Count_Triangles (Ms) /= Count_Triangles (Mp),
             "Sphere and plane meshes differ in triangle count");
   end;

   New_Line;
   Put_Line ("======================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("======================");
   pragma Assert (Fail_Count = 0, "Some Isosurfaces tests failed");
   if Fail_Count > 0 then
      raise Program_Error with "Isosurfaces tests failed";
   end if;
   Put_Line ("All tests passed.");
end Tests;
