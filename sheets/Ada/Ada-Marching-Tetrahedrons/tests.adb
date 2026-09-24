--  Standalone test suite for Marching_Tetrahedrons (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Marching_Tetrahedrons; use Marching_Tetrahedrons;

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
   Put_Line ("Marching_Tetrahedrons test suite");
   Put_Line ("================================");

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
   Section ("3. Split_Cube_Into_Tetrahedra");
   ---------------------------------------------------------------------
   declare
      Tets : constant Tetrahedra_Six := Split_Cube_Into_Tetrahedra;
      All_Share_06 : Boolean := True;
      Seen_Corners : array (Cube_Corner) of Boolean := [others => False];
   begin
      Check (Tets'Length = 6, "Six tetrahedra returned");
      for T in Tets'Range loop
         declare
            Has0, Has6 : Boolean := False;
         begin
            for K in 0 .. 3 loop
               Seen_Corners (Tets (T).Corners (K)) := True;
               if Tets (T).Corners (K) = 0 then
                  Has0 := True;
               end if;
               if Tets (T).Corners (K) = 6 then
                  Has6 := True;
               end if;
            end loop;
            if not (Has0 and then Has6) then
               All_Share_06 := False;
            end if;
         end;
      end loop;
      Check (All_Share_06, "Every tet shares main diagonal 0-6");
      Check (Seen_Corners (2) and then Seen_Corners (7),
             "Interior mapping covers distant corners 2 and 7");
      --  First tet is (0,5,1,6)
      Check (Tets (1).Corners (0) = 0
               and then Tets (1).Corners (1) = 5
               and then Tets (1).Corners (2) = 1
               and then Tets (1).Corners (3) = 6,
             "Tet 1 corners are (0,5,1,6)");
   end;

   ---------------------------------------------------------------------
   Section ("4. Tetra_Case_Index");
   ---------------------------------------------------------------------
   declare
      C0 : constant Case_Index :=
        Tetra_Case_Index (1.0, 1.0, 1.0, 1.0, 0.0);
      C1 : constant Case_Index :=
        Tetra_Case_Index (-1.0, 1.0, 1.0, 1.0, 0.0);
      C15 : constant Case_Index :=
        Tetra_Case_Index (-1.0, -1.0, -1.0, -1.0, 0.0);
      C5 : constant Case_Index :=
        Tetra_Case_Index (-1.0, 1.0, -1.0, 1.0, 0.0);
   begin
      Check (C0 = 0, "All outside => case 0");
      Check (C1 = 1, "Only S0 inside => case 1");
      Check (C15 = 15, "All inside => case 15");
      Check (C5 = 5, "S0+S2 inside => case 5");
   end;

   ---------------------------------------------------------------------
   Section ("5. Interpolate_Edge_Vertex");
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
   Section ("6. Triangulate_Tetrahedron empty / one / two");
   ---------------------------------------------------------------------
   declare
      Tris : Small_Triangle_List;
      N    : Natural;
      P0 : constant Point3 := (0.0, 0.0, 0.0);
      P1 : constant Point3 := (1.0, 0.0, 0.0);
      P2 : constant Point3 := (0.0, 1.0, 0.0);
      P3 : constant Point3 := (0.0, 0.0, 1.0);
   begin
      Triangulate_Tetrahedron
        (P0, P1, P2, P3, 1.0, 1.0, 1.0, 1.0, 0.0, Tris, N);
      Check (N = 0, "All-positive scalars => 0 triangles");

      Triangulate_Tetrahedron
        (P0, P1, P2, P3, -1.0, -1.0, -1.0, -1.0, 0.0, Tris, N);
      Check (N = 0, "All-negative scalars => 0 triangles");

      Triangulate_Tetrahedron
        (P0, P1, P2, P3, -1.0, 1.0, 1.0, 1.0, 0.0, Tris, N);
      Check (N = 1, "Single corner inside => 1 triangle");
      Check (Length (Face_Normal (Tris (1))) > 0.9,
             "Emitted triangle has unit-ish face normal");

      Triangulate_Tetrahedron
        (P0, P1, P2, P3, -1.0, -1.0, 1.0, 1.0, 0.0, Tris, N);
      Check (N = 2, "Two corners inside => 2 triangles");
   end;

   ---------------------------------------------------------------------
   Section ("7. Face_Normal / Estimate_Normal");
   ---------------------------------------------------------------------
   declare
      T : constant Triangle :=
        (A => (0.0, 0.0, 0.0),
         B => (1.0, 0.0, 0.0),
         C => (0.0, 1.0, 0.0),
         others => <>);
      N : constant Normal3 := Face_Normal (T);
      G : constant Normal3 := Estimate_Normal
        ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0),
         -1.0, 1.0, 1.0, 1.0);
   begin
      Check (Approx (N.Z, 1.0), "XY triangle normal is +Z");
      Check (Approx (Length (N), 1.0), "Face_Normal is unit");
      Check (Length (G) > 0.9, "Estimate_Normal returns unit-ish");
      --  Mathematical gradient points toward increasing scalar (away from P0).
      Check (G.X > 0.0, "Gradient points toward increasing samples from P0");
   end;

   ---------------------------------------------------------------------
   Section ("8. March_Single_Cube on a crossing cell");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 1, 0 .. 1, 0 .. 1);
      Pos  : Position_Field (0 .. 1, 0 .. 1, 0 .. 1);
      Acc  : Mesh := Empty_Mesh;
   begin
      --  Plane Z = 0.5 through the unit cell.
      for I in 0 .. 1 loop
         for J in 0 .. 1 loop
            for K in 0 .. 1 loop
               Pos (I, J, K) :=
                 (Real (I), Real (J), Real (K));
               Vals (I, J, K) := Real (K) - 0.5;
            end loop;
         end loop;
      end loop;
      March_Single_Cube (Pos, Vals, 0, 0, 0, 0.0, Acc);
      Check (Count_Triangles (Acc) > 0, "Plane cell yields triangles");
      Check (Count_Triangles (Acc) >= 2, "At least a quad-worth of tris");
      Check (Acc.Count = Count_Triangles (Acc), "Count matches mesh field");
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
      Vals : Scalar_Field (0 .. 4, 0 .. 4, 0 .. 4);
      Pos  : Position_Field (0 .. 4, 0 .. 4, 0 .. 4);
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
      Vals : Scalar_Field (0 .. 7, 0 .. 7, 0 .. 7);
      Pos  : Position_Field (0 .. 7, 0 .. 7, 0 .. 7);
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
   Section ("11. Empty_Mesh / Append / Count_Triangles");
   ---------------------------------------------------------------------
   declare
      M : Mesh := Empty_Mesh;
      T : constant Triangle :=
        (A => (0.0, 0.0, 0.0),
         B => (1.0, 0.0, 0.0),
         C => (0.0, 1.0, 0.0),
         others => <>);
   begin
      Check (Count_Triangles (M) = 0, "Empty_Mesh has 0 triangles");
      Append_Triangle (M, T);
      Check (Count_Triangles (M) = 1, "Append grows count to 1");
      Append_Triangle (M, T);
      Check (Count_Triangles (M) = 2, "Append grows count to 2");
      Check (Approx_Vec (M.Tris (1).A, (0.0, 0.0, 0.0)),
             "Stored triangle vertex A");
   end;

   ---------------------------------------------------------------------
   Section ("12. Fill_Sphere_SDF sample signs");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 2, 0 .. 2, 0 .. 2);
      Pos  : Position_Field (0 .. 2, 0 .. 2, 0 .. 2);
      Center : constant Point3 := (1.0, 1.0, 1.0);
   begin
      Fill_Sphere_SDF
        (Vals, Pos,
         Origin => (0.0, 0.0, 0.0),
         Spacing => 1.0,
         Center => Center,
         Radius => 0.75);
      Check (Vals (1, 1, 1) < 0.0, "Center sample is inside (negative SDF)");
      Check (Vals (0, 0, 0) > 0.0, "Far corner is outside");
      Check (Approx_Vec (Pos (1, 1, 1), Center), "Center lattice point");
      Check (Approx_Vec (Pos (0, 0, 0), (0.0, 0.0, 0.0)), "Origin lattice");
   end;

   ---------------------------------------------------------------------
   Section ("13. Case coverage across all 16 tetra cases");
   ---------------------------------------------------------------------
   declare
      P0 : constant Point3 := (0.0, 0.0, 0.0);
      P1 : constant Point3 := (1.0, 0.0, 0.0);
      P2 : constant Point3 := (0.0, 1.0, 0.0);
      P3 : constant Point3 := (0.0, 0.0, 1.0);
      Tris : Small_Triangle_List;
      N    : Natural;
      Total : Natural := 0;
      Empty_Cases : Natural := 0;
      One_Cases   : Natural := 0;
      Two_Cases   : Natural := 0;
      S : array (0 .. 3) of Real;
   begin
      for Mask in 0 .. 15 loop
         for B in 0 .. 3 loop
            if (Mask / (2 ** B)) mod 2 = 1 then
               S (B) := -1.0;
            else
               S (B) := 1.0;
            end if;
         end loop;
         Triangulate_Tetrahedron
           (P0, P1, P2, P3, S (0), S (1), S (2), S (3), 0.0, Tris, N);
         Total := Total + N;
         if N = 0 then
            Empty_Cases := Empty_Cases + 1;
         elsif N = 1 then
            One_Cases := One_Cases + 1;
         elsif N = 2 then
            Two_Cases := Two_Cases + 1;
         end if;
         Check (N <= 2, "Case" & Mask'Image & " emits at most 2 tris");
      end loop;
      Check (Empty_Cases = 2, "Exactly two empty cases (0 and 15)");
      Check (One_Cases = 8, "Eight single-triangle cases");
      Check (Two_Cases = 6, "Six two-triangle (quad) cases");
      Check (Total = 8 + 12, "Total triangles over all cases = 20");
   end;

   ---------------------------------------------------------------------
   Section ("14. Named exceptions");
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
            Vals : Scalar_Field (0 .. 1, 0 .. 1, 0 .. 1);
            Pos  : Position_Field (0 .. 1, 0 .. 1, 0 .. 1);
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
   Section ("15. Sphere vs plane mesh distinction");
   ---------------------------------------------------------------------
   declare
      Vs, Vp : Scalar_Field (0 .. 5, 0 .. 5, 0 .. 5);
      Ps, Pp : Position_Field (0 .. 5, 0 .. 5, 0 .. 5);
      Ms, Mp : Mesh;
   begin
      Fill_Sphere_SDF
        (Vs, Ps, (0.0, 0.0, 0.0), 1.0, (2.5, 2.5, 2.5), 1.5);
      Fill_Plane_Field
        (Vp, Pp, (0.0, 0.0, 0.0), 1.0, (0.0, 0.0, 2.5), (0.0, 0.0, 1.0));
      Ms := March_Grid (Vs, Ps, 0.0);
      Mp := March_Grid (Vp, Pp, 0.0);
      Check (Count_Triangles (Ms) > 0, "Sphere mesh non-empty");
      Check (Count_Triangles (Mp) > 0, "Plane mesh non-empty");
      Check (Count_Triangles (Ms) /= Count_Triangles (Mp),
             "Sphere and plane meshes differ in triangle count");
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("================================");
   pragma Assert (Fail_Count = 0, "Some Marching_Tetrahedrons tests failed");
   if Fail_Count > 0 then
      raise Program_Error with "Marching_Tetrahedrons tests failed";
   end if;
   Put_Line ("All tests passed.");
end Tests;
