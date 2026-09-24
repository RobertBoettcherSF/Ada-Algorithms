--  Standalone test suite for Marching_Cubes (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Marching_Cubes; use Marching_Cubes;

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
   Put_Line ("Marching_Cubes test suite");
   Put_Line ("=========================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers");
   ---------------------------------------------------------------------
   declare
      V  : constant Vec3 := (3.0, 0.0, 4.0);
      N  : constant Normal3 := Normalize (V);
      D  : constant Real := Dot ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Cr : constant Vec3 := Cross ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
      Sm : constant Vec3 := (1.0, 2.0, 3.0) + (4.0, 5.0, 6.0);
   begin
      Check (Approx (Length (V), 5.0), "Length of (3,0,4) is 5");
      Check (Approx (Length (N), 1.0), "Normalize yields unit length");
      Check (abs (D) <= 1.0E-5, "Dot of orthogonal axes is 0");
      Check (Approx (Cr.Z, 1.0), "Cross i x j = k");
      Check (Approx (Sm.X, 5.0), "Vector addition X");
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
   Section ("3. Cube_Case_Index empty / full / single");
   ---------------------------------------------------------------------
   declare
      C0 : constant Case_Index :=
        Cube_Case_Index
          (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0);
      C255 : constant Case_Index :=
        Cube_Case_Index
          (-1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, 0.0);
      C1 : constant Case_Index :=
        Cube_Case_Index
          (-1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0);
      C3 : constant Case_Index :=
        Cube_Case_Index
          (-1.0, -1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0);
   begin
      Check (C0 = 0, "All outside => case 0");
      Check (C255 = 255, "All inside => case 255");
      Check (C1 = 1, "Only corner 0 inside => case 1");
      Check (C3 = 3, "Corners 0+1 inside => case 3");
   end;

   ---------------------------------------------------------------------
   Section ("4. Interpolate_Edge_Vertex");
   ---------------------------------------------------------------------
   declare
      Mid : constant Point3 := Interpolate_Edge_Vertex
        ((0.0, 0.0, 0.0), (2.0, 0.0, 0.0), -1.0, 1.0, 0.0);
      Q   : constant Point3 := Interpolate_Edge_Vertex
        ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0), -1.0, 3.0, 0.0);
      Pos : Point3;
      Grad : Vec3;
   begin
      Interpolate_Edge_Vertex
        ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0),
         -1.0, 1.0,
         (1.0, 0.0, 0.0), (3.0, 0.0, 0.0),
         0.0, Pos, Grad);
      Check (Approx_Vec (Mid, (1.0, 0.0, 0.0)),
             "Zero crossing midpoint on [-1,1]");
      Check (Approx (Q.X, 0.25), "Crossing at t=0.25 for (-1,3)");
      Check (Approx_Vec (Pos, (0.5, 0.0, 0.0)),
             "Overloaded form position at mid");
      Check (Approx (Grad.X, 2.0), "Blended gradient X = 2");
   end;

   ---------------------------------------------------------------------
   Section ("5. Lookup_Triangles / March_Cube empty and one-corner");
   ---------------------------------------------------------------------
   declare
      Edges : Edge_Id_List;
      N     : Natural;
      Tris  : Small_Triangle_List;
      P0 : constant Point3 := (0.0, 0.0, 0.0);
      P1 : constant Point3 := (1.0, 0.0, 0.0);
      P2 : constant Point3 := (1.0, 1.0, 0.0);
      P3 : constant Point3 := (0.0, 1.0, 0.0);
      P4 : constant Point3 := (0.0, 0.0, 1.0);
      P5 : constant Point3 := (1.0, 0.0, 1.0);
      P6 : constant Point3 := (1.0, 1.0, 1.0);
      P7 : constant Point3 := (0.0, 1.0, 1.0);
   begin
      Lookup_Triangles (0, Edges, N);
      Check (N = 0, "Case 0 lookup emits 0 triangles");
      Lookup_Triangles (255, Edges, N);
      Check (N = 0, "Case 255 lookup emits 0 triangles");
      Lookup_Triangles (1, Edges, N);
      Check (N = 1, "Case 1 lookup emits 1 triangle");
      Check (Edges (1) (1) = 0 and then Edges (1) (2) = 8
               and then Edges (1) (3) = 3,
             "Case 1 uses edges 0,8,3");

      March_Cube
        (P0, P1, P2, P3, P4, P5, P6, P7,
         1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
         0.0, Tris, N);
      Check (N = 0, "All-positive cube => 0 triangles");

      March_Cube
        (P0, P1, P2, P3, P4, P5, P6, P7,
         -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0, -1.0,
         0.0, Tris, N);
      Check (N = 0, "All-negative cube => 0 triangles");

      March_Cube
        (P0, P1, P2, P3, P4, P5, P6, P7,
         -1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
         0.0, Tris, N);
      Check (N = 1, "Single corner inside => 1 triangle");
      Check (Length (Face_Normal (Tris (1))) > 0.9,
             "Emitted triangle has unit-ish face normal");
   end;

   ---------------------------------------------------------------------
   Section ("6. Asymptotic_Decider / Face_Is_Ambiguous");
   ---------------------------------------------------------------------
   declare
      Amb : constant Boolean :=
        Face_Is_Ambiguous (-1.0, 1.0, -1.0, 1.0, 0.0);
      Not_Amb : constant Boolean :=
        Face_Is_Ambiguous (-1.0, -1.0, 1.0, 1.0, 0.0);
      Dec_A : constant Boolean :=
        Asymptotic_Decider (-2.0, 1.0, -0.5, 1.0, 0.0);
      Dec_B : constant Boolean :=
        Asymptotic_Decider (-1.0, 3.0, -1.0, 3.0, 0.0);
      Grid : Scalar_Grid3 (0 .. 1, 0 .. 1, 0 .. 1);
      Face_Dec : Boolean;
   begin
      Check (Amb, "Alternating face is ambiguous");
      Check (not Not_Amb, "Split face is not ambiguous");
      --  G00*G11 = (-2)*(-0.5)=1 ; G10*G01 = 1*1=1 => True (>=)
      Check (Dec_A, "Decider True when G00*G11 >= G10*G01");
      --  G00*G11 = 1 ; G10*G01 = 9 => False
      Check (not Dec_B, "Decider False when G00*G11 < G10*G01");
      for I in 0 .. 1 loop
         for J in 0 .. 1 loop
            for K in 0 .. 1 loop
               --  Ambiguous -Z face: alternating in XY at K=0
               if K = 0 then
                  if (I + J) mod 2 = 0 then
                     Grid (I, J, K) := -1.0;
                  else
                     Grid (I, J, K) := 1.0;
                  end if;
               else
                  Grid (I, J, K) := 1.0;
               end if;
            end loop;
         end loop;
      end loop;
      Face_Dec := Disambiguate_Face (Grid, 0, 0, 0, Face => 4, Isolevel => 0.0);
      Check (Face_Is_Ambiguous
               (Grid (0, 0, 0), Grid (1, 0, 0),
                Grid (1, 1, 0), Grid (0, 1, 0), 0.0),
             "-Z face of fixture is ambiguous");
      Check (Asymptotic_Decider
               (Grid (0, 0, 0), Grid (1, 0, 0),
                Grid (1, 1, 0), Grid (0, 1, 0), 0.0) = Face_Dec,
             "Disambiguate_Face matches Asymptotic_Decider on -Z");
      Check (Face_Dec = Asymptotic_Decider (-1.0, 1.0, -1.0, 1.0, 0.0),
             "Disambiguate_Face agrees with direct face samples");
   end;

   ---------------------------------------------------------------------
   Section ("7. Face_Normal / Estimate_Vertex_Normal");
   ---------------------------------------------------------------------
   declare
      T : constant Triangle :=
        (A => (0.0, 0.0, 0.0),
         B => (1.0, 0.0, 0.0),
         C => (0.0, 1.0, 0.0),
         others => <>);
      N : constant Normal3 := Face_Normal (T);
      Vals : Scalar_Grid3 (0 .. 2, 0 .. 2, 0 .. 2);
      Pos  : Position_Grid3 (0 .. 2, 0 .. 2, 0 .. 2);
      G    : Normal3;
   begin
      Check (Approx (N.Z, 1.0), "XY triangle normal is +Z");
      Check (Approx (Length (N), 1.0), "Face_Normal is unit");
      Fill_Plane_Field
        (Vals, Pos, (0.0, 0.0, 0.0), 1.0,
         (0.0, 0.0, 1.0), (0.0, 0.0, 1.0));
      G := Estimate_Vertex_Normal (Vals, Pos, 1, 1, 1);
      Check (Length (G) > 0.9, "Estimate_Vertex_Normal unit-ish");
      Check (G.Z > 0.5, "Plane gradient mostly +Z");
   end;

   ---------------------------------------------------------------------
   Section ("8. March_Single_Cube on a crossing cell");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 1, 0 .. 1, 0 .. 1);
      Pos  : Position_Grid3 (0 .. 1, 0 .. 1, 0 .. 1);
      Acc  : Mesh := Empty_Mesh;
      Idx  : Case_Index;
   begin
      for I in 0 .. 1 loop
         for J in 0 .. 1 loop
            for K in 0 .. 1 loop
               Pos (I, J, K) := (Real (I), Real (J), Real (K));
               Vals (I, J, K) := Real (K) - 0.5;
            end loop;
         end loop;
      end loop;
      Idx := Cube_Case_Index (Vals, 0, 0, 0, 0.0);
      Check (Idx /= 0 and then Idx /= 255, "Plane cell is neither empty nor full");
      March_Single_Cube (Pos, Vals, 0, 0, 0, 0.0, Acc);
      Check (Count_Triangles (Acc) > 0, "Plane cell yields triangles");
      Check (Count_Triangles (Acc) >= 2, "At least a quad-worth of tris");
      declare
         St : constant Mesh_Stats := Compute_Mesh_Stats (Acc);
      begin
         Check (St.Triangle_Count = Count_Triangles (Acc),
                "Mesh_Stats triangle count agrees");
         Check (Approx (St.Min_Corner.Z, 0.5, 0.05)
                  or else Approx (St.Max_Corner.Z, 0.5, 0.05),
                "Isosurface near Z=0.5");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. March_Grid plane field");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 4, 0 .. 4, 0 .. 4);
      Pos  : Position_Grid3 (0 .. 4, 0 .. 4, 0 .. 4);
      M    : Mesh;
      St   : Mesh_Stats;
   begin
      Fill_Plane_Field
        (Vals, Pos,
         Origin => (0.0, 0.0, 0.0),
         Spacing => 1.0,
         Plane_Point => (0.0, 0.0, 2.0),
         Plane_Normal => (0.0, 0.0, 1.0));
      M := March_Grid (Vals, Pos, Isolevel => 0.0);
      St := Compute_Mesh_Stats (M);
      Check (Count_Triangles (M) > 0, "Plane grid produces triangles");
      Check (St.Vertex_Slots = Count_Triangles (M) * 3,
             "Vertex slots = 3 * triangles");
      Check (Approx (St.Min_Corner.Z, 2.0, 0.15)
               and then Approx (St.Max_Corner.Z, 2.0, 0.15),
             "Plane mesh stays near Z=2");
      Check (St.Max_Corner.X >= St.Min_Corner.X, "AABB X ordered");
   end;

   ---------------------------------------------------------------------
   Section ("10. March_Grid sphere SDF");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 7, 0 .. 7, 0 .. 7);
      Pos  : Position_Grid3 (0 .. 7, 0 .. 7, 0 .. 7);
      M    : Mesh;
      St   : Mesh_Stats;
      Center : constant Point3 := (3.5, 3.5, 3.5);
   begin
      Fill_Sphere_SDF
        (Vals, Pos,
         Origin => (0.0, 0.0, 0.0),
         Spacing => 1.0,
         Center => Center,
         Radius => 2.0);
      M := March_Grid (Vals, Pos, Isolevel => 0.0);
      St := Compute_Mesh_Stats (M);
      Check (Count_Triangles (M) >= 8, "Sphere yields a closed-ish mesh");
      Check (St.Min_Corner.X < Center.X
               and then St.Max_Corner.X > Center.X,
             "Sphere mesh spans center in X");
      Check (St.Min_Corner.Y < Center.Y
               and then St.Max_Corner.Y > Center.Y,
             "Sphere mesh spans center in Y");
      Check (Distance_Between (St.Min_Corner, Center) > 0.5,
             "Bounding box extends away from center");
   end;

   ---------------------------------------------------------------------
   Section ("11. Adjacent cell shared-edge consistency");
   ---------------------------------------------------------------------
   declare
      --  Two cells side-by-side along X; plane Z=0.5.
      Vals : Scalar_Grid3 (0 .. 2, 0 .. 1, 0 .. 1);
      Pos  : Position_Grid3 (0 .. 2, 0 .. 1, 0 .. 1);
      Left, Right : Mesh := Empty_Mesh;
      Shared_Z_OK : Boolean := True;
      Found_Left, Found_Right : Natural := 0;
   begin
      for I in 0 .. 2 loop
         for J in 0 .. 1 loop
            for K in 0 .. 1 loop
               Pos (I, J, K) := (Real (I), Real (J), Real (K));
               Vals (I, J, K) := Real (K) - 0.5;
            end loop;
         end loop;
      end loop;
      March_Single_Cube (Pos, Vals, 0, 0, 0, 0.0, Left);
      March_Single_Cube (Pos, Vals, 1, 0, 0, 0.0, Right);
      Check (Count_Triangles (Left) > 0, "Left cell non-empty");
      Check (Count_Triangles (Right) > 0, "Right cell non-empty");
      --  Shared face is at X=1; vertices on that face must have Z≈0.5.
      for T in 1 .. Left.Count loop
         declare
            procedure Hit (P : Point3) is
            begin
               if Approx (P.X, 1.0, 0.05) then
                  Found_Left := Found_Left + 1;
                  if not Approx (P.Z, 0.5, 0.05) then
                     Shared_Z_OK := False;
                  end if;
               end if;
            end Hit;
         begin
            Hit (Left.Tris (T).A);
            Hit (Left.Tris (T).B);
            Hit (Left.Tris (T).C);
         end;
      end loop;
      for T in 1 .. Right.Count loop
         declare
            procedure Hit (P : Point3) is
            begin
               if Approx (P.X, 1.0, 0.05) then
                  Found_Right := Found_Right + 1;
                  if not Approx (P.Z, 0.5, 0.05) then
                     Shared_Z_OK := False;
                  end if;
               end if;
            end Hit;
         begin
            Hit (Right.Tris (T).A);
            Hit (Right.Tris (T).B);
            Hit (Right.Tris (T).C);
         end;
      end loop;
      Check (Found_Left > 0 and then Found_Right > 0,
             "Both cells contribute vertices on shared face X=1");
      Check (Shared_Z_OK, "Shared-face vertices agree on Z=0.5 plane");
   end;

   ---------------------------------------------------------------------
   Section ("12. Fill_Metaball_Field / Empty_Mesh / Append");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Grid3 (0 .. 5, 0 .. 5, 0 .. 5);
      Pos  : Position_Grid3 (0 .. 5, 0 .. 5, 0 .. 5);
      M    : Mesh;
      Em   : Mesh := Empty_Mesh;
      T    : constant Triangle :=
        (A => (0.0, 0.0, 0.0),
         B => (1.0, 0.0, 0.0),
         C => (0.0, 1.0, 0.0),
         others => <>);
   begin
      Fill_Metaball_Field
        (Vals, Pos,
         Origin => (0.0, 0.0, 0.0),
         Spacing => 1.0,
         C1 => (1.5, 2.5, 2.5),
         C2 => (3.5, 2.5, 2.5),
         R1 => 1.2,
         R2 => 1.2);
      M := March_Grid (Vals, Pos, Isolevel => 0.0);
      Check (Count_Triangles (M) > 0, "Metaball field yields triangles");
      Check (Vals (1, 2, 2) > 0.0 or else Vals (2, 2, 2) > 0.0,
             "Near first ball potential is positive (inside-ish)");
      Check (Count_Triangles (Em) = 0, "Empty_Mesh has 0 triangles");
      Append_Triangle (Em, T);
      Check (Count_Triangles (Em) = 1, "Append grows count to 1");
   end;

   ---------------------------------------------------------------------
   Section ("13. Named exceptions");
   ---------------------------------------------------------------------
   declare
      Raised_Deg : Boolean := False;
      Raised_Inv : Boolean := False;
   begin
      begin
         declare
            Dummy : constant Normal3 := Normalize ((0.0, 0.0, 0.0));
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised_Deg := True;
      end;
      Check (Raised_Deg, "Normalize(0) raises Degenerate_Geometry");

      Raised_Deg := False;
      begin
         declare
            Dummy : constant Point3 := Interpolate_Edge_Vertex
              ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0), 1.0, 1.0, 0.0);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised_Deg := True;
      end;
      Check (Raised_Deg, "equal scalars raise Degenerate_Geometry");

      begin
         declare
            Vals : Scalar_Grid3 (0 .. 1, 0 .. 1, 0 .. 1);
            Pos  : Position_Grid3 (0 .. 1, 0 .. 1, 0 .. 1);
         begin
            Fill_Sphere_SDF
              (Vals, Pos, (0.0, 0.0, 0.0), Spacing => -1.0,
               Center => (0.0, 0.0, 0.0), Radius => 1.0);
         end;
      exception
         when Invalid_Argument =>
            Raised_Inv := True;
      end;
      Check (Raised_Inv, "Negative spacing raises Invalid_Argument");
      Check (Fail_Count = 0, "No failures before end of exception tests");
   end;

   ---------------------------------------------------------------------
   Section ("14. Sphere vs plane vs metaball distinction");
   ---------------------------------------------------------------------
   declare
      Vs, Vp, Vm : Scalar_Grid3 (0 .. 5, 0 .. 5, 0 .. 5);
      Ps, Pp, Pm : Position_Grid3 (0 .. 5, 0 .. 5, 0 .. 5);
      Ms, Mp, Mm : Mesh;
   begin
      Fill_Sphere_SDF
        (Vs, Ps, (0.0, 0.0, 0.0), 1.0, (2.5, 2.5, 2.5), 1.5);
      Fill_Plane_Field
        (Vp, Pp, (0.0, 0.0, 0.0), 1.0, (0.0, 0.0, 2.5), (0.0, 0.0, 1.0));
      Fill_Metaball_Field
        (Vm, Pm, (0.0, 0.0, 0.0), 1.0,
         (1.5, 2.5, 2.5), (3.5, 2.5, 2.5), 1.0, 1.0);
      Ms := March_Grid (Vs, Ps, 0.0);
      Mp := March_Grid (Vp, Pp, 0.0);
      Mm := March_Grid (Vm, Pm, 0.0);
      Check (Count_Triangles (Ms) > 0, "Sphere mesh non-empty");
      Check (Count_Triangles (Mp) > 0, "Plane mesh non-empty");
      Check (Count_Triangles (Mm) > 0, "Metaball mesh non-empty");
      Check (Count_Triangles (Ms) /= Count_Triangles (Mp),
             "Sphere and plane meshes differ in triangle count");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("================================");
   pragma Assert (Fail_Count = 0, "Some Marching_Cubes tests failed");
   if Fail_Count > 0 then
      raise Program_Error with "Marching_Cubes tests failed";
   end if;
   Put_Line ("All tests passed.");
end Tests;
