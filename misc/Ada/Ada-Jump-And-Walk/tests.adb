--  Standalone test suite for Jump_And_Walk (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Jump_And_Walk; use Jump_And_Walk;

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
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function R (X : Real) return Real is (X);
   function P (X, Y : Real) return Point is ((X => X, Y => Y));

   function Raised_Invalid_Empty return Boolean is
      M : Mesh;
      L : Locate_Result;
   begin
      L := Locate (P (0.0, 0.0), M);
      pragma Unreferenced (L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Empty;

   function Raised_Invalid_Fan (Pts : Point_Array) return Boolean is
      M : Mesh;
   begin
      M := Build_Convex_Fan (Pts);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Fan;

begin
   Ada.Text_IO.Put_Line ("Jump_And_Walk tests");
   Ada.Text_IO.Put_Line ("===================");

   ------------------------------------------------------------------
   Section ("1. Near / Dist2 / Orient2D / CCW");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)), "Dist2 3-4-5");
   Check (Near (Dist2 (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)), "Dist2 zero");
   Check (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)) > 0.0,
          "Orient2D CCW positive");
   Check (Orient2D (P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)) < 0.0,
          "Orient2D CW negative");
   Check (Near (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)), R (0.0)),
          "Orient2D collinear ~0");
   Check (CCW (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)), "CCW true");
   Check (not CCW (P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)), "CCW false CW");
   Check (not CCW (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)), "CCW false colin");

   ------------------------------------------------------------------
   Section ("2. Point_In_Triangle / Centroid");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (2.0, 0.0);
      C : constant Point := P (0.0, 2.0);
      Cen : constant Point := Centroid (A, B, C);
   begin
      Check (Point_In_Triangle (P (0.5, 0.5), A, B, C), "interior in triangle");
      Check (Point_In_Triangle (A, A, B, C), "vertex A inside closed");
      Check (Point_In_Triangle (B, A, B, C), "vertex B inside closed");
      Check (Point_In_Triangle (C, A, B, C), "vertex C inside closed");
      Check (Point_In_Triangle (P (1.0, 0.0), A, B, C), "edge AB midpoint");
      Check (not Point_In_Triangle (P (2.0, 2.0), A, B, C), "outside far");
      Check (not Point_In_Triangle (P (-0.1, 0.5), A, B, C), "outside left");
      Check (not Point_In_Triangle (P (1.5, 1.5), A, B, C), "outside hypot");
      Check (Near (Cen.X, R (2.0 / 3.0), 1.0E-9)
               and then Near (Cen.Y, R (2.0 / 3.0), 1.0E-9),
             "centroid of right triangle");
   end;

   ------------------------------------------------------------------
   Section ("3. Build_Convex_Fan — square (2 triangles)");
   ------------------------------------------------------------------
   declare
      --  Unit square CCW: (0,0),(1,0),(1,1),(0,1)
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      M   : constant Mesh := Build_Convex_Fan (Pts);
      T1, T2 : Triangle;
      N1, N2 : Adjacency;
   begin
      Check (Triangle_Count_Of (M) = 2, "square fan has 2 tris");
      Check (M.Num_Points = 4, "square fan 4 points");
      T1 := Get_Triangle (M, 1);
      T2 := Get_Triangle (M, 2);
      Check (T1.A = 1 and then T1.B = 2 and then T1.C = 3,
             "T1 = (1,2,3)");
      Check (T2.A = 1 and then T2.B = 3 and then T2.C = 4,
             "T2 = (1,3,4)");
      N1 := Get_Neighbors (M, 1);
      N2 := Get_Neighbors (M, 2);
      Check (N1.N1 = -1, "T1 outer BC is boundary");
      Check (N1.N2 = 2, "T1 neighbor across CA is T2");
      Check (N1.N3 = -1, "T1 first has no prev");
      Check (N2.N1 = -1, "T2 outer BC is boundary");
      Check (N2.N2 = -1, "T2 last has no next");
      Check (N2.N3 = 1, "T2 neighbor across AB is T1");
      Check (CCW (M.Points (T1.A), M.Points (T1.B), M.Points (T1.C)),
             "T1 oriented CCW");
      Check (CCW (M.Points (T2.A), M.Points (T2.B), M.Points (T2.C)),
             "T2 oriented CCW");
   end;

   ------------------------------------------------------------------
   Section ("4. Walk_From on square fan");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      M   : constant Mesh := Build_Convex_Fan (Pts);
      --  Interior of T1 (1,2,3): centroid ~ (2/3, 1/3)
      L1 : constant Locate_Result :=
        Walk_From (P (0.6, 0.2), M, 1);
      --  Interior of T2 starting from T1 (must walk across)
      L2 : constant Locate_Result :=
        Walk_From (P (0.2, 0.6), M, 1);
      --  Start already in T2
      L3 : constant Locate_Result :=
        Walk_From (P (0.2, 0.6), M, 2);
      --  Outside: right of square
      L4 : constant Locate_Result :=
        Walk_From (P (2.0, 0.5), M, 1);
      --  Outside: below
      L5 : constant Locate_Result :=
        Walk_From (P (0.5, -1.0), M, 1);
   begin
      Check (L1 = 1, "Walk_From finds T1 from T1");
      Check (L2 = 2, "Walk_From T1 -> T2");
      Check (L3 = 2, "Walk_From already in T2");
      Check (L4 = 0, "Walk_From outside right -> 0");
      Check (L5 = 0, "Walk_From outside below -> 0");
      Check (Point_In_Triangle (P (0.6, 0.2), M, 1), "mesh PIT T1");
      Check (Point_In_Triangle (P (0.2, 0.6), M, 2), "mesh PIT T2");
      Check (not Point_In_Triangle (P (2.0, 0.5), M, 1), "mesh PIT outside");
   end;

   ------------------------------------------------------------------
   Section ("5. Locate / Locate_Jump_And_Walk — square");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      M   : constant Mesh := Build_Convex_Fan (Pts);
      R1  : constant Locate_Result := Locate (P (0.7, 0.2), M, 1);
      R2  : constant Locate_Result := Locate (P (0.2, 0.7), M, 2);
      R3  : constant Locate_Result :=
        Locate_Jump_And_Walk (P (0.5, 0.1), M, 7, 2);
      R4  : constant Locate_Result := Locate (P (3.0, 3.0), M, 3);
      R5  : constant Locate_Result := Locate (P (-1.0, 0.5), M);
   begin
      Check (R1 = 1, "Locate interior T1");
      Check (R2 = 2, "Locate interior T2");
      Check (R3 = 1, "Locate_Jump_And_Walk near AB");
      Check (R4 = 0, "Locate outside far -> 0");
      Check (R5 = 0, "Locate outside left -> 0");
   end;

   ------------------------------------------------------------------
   Section ("6. Regular hexagon fan (4 triangles)");
   ------------------------------------------------------------------
   declare
      --  Convex hexagon approximated (CCW), fan from vertex 1.
      Pts : constant Point_Array :=
        [P (2.0, 0.0),
         P (1.0, 1.732),
         P (-1.0, 1.732),
         P (-2.0, 0.0),
         P (-1.0, -1.732),
         P (1.0, -1.732)];
      M   : constant Mesh := Build_Convex_Fan (Pts);
      --  Slightly inside near center of polygon: (0,0) is inside fan
      --  from vertex 1=(2,0): triangles cover the hexagon.
      C0  : constant Locate_Result := Locate (P (0.0, 0.0), M, 11);
      --  Point near middle of first triangle (1,2,3)
      C1  : constant Point :=
        Centroid (Pts (1), Pts (2), Pts (3));
      L1  : constant Locate_Result := Locate (C1, M, 5);
      --  Outside
      Outside : constant Locate_Result := Locate (P (5.0, 5.0), M, 9);
   begin
      Check (Triangle_Count_Of (M) = 4, "hex fan 4 tris");
      Check (C0 /= 0, "hex center found");
      Check (Point_In_Triangle (P (0.0, 0.0), M, Triangle_Index (C0)),
             "hex center inside reported tri");
      Check (L1 = 1, "hex first-tri centroid -> T1");
      Check (Outside = 0, "hex outside -> 0");
      for K in 1 .. Triangle_Count_Of (M) loop
         Check
           (CCW (M.Points (M.Tris (K).A),
                 M.Points (M.Tris (K).B),
                 M.Points (M.Tris (K).C)),
            "hex T" & Triangle_Index'Image (K) & " CCW");
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("7. Larger fan — regular-ish octagon");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (1.0, 0.0),
         P (0.7071, 0.7071),
         P (0.0, 1.0),
         P (-0.7071, 0.7071),
         P (-1.0, 0.0),
         P (-0.7071, -0.7071),
         P (0.0, -1.0),
         P (0.7071, -0.7071)];
      M : constant Mesh := Build_Convex_Fan (Pts);
      Hits : Natural := 0;
   begin
      Check (Triangle_Count_Of (M) = 6, "octagon fan 6 tris");
      --  Probe several interior points near origin
      for DX in -2 .. 2 loop
         for DY in -2 .. 2 loop
            declare
               Q : constant Point :=
                 P (Real (DX) * 0.1, Real (DY) * 0.1);
               L : constant Locate_Result := Locate (Q, M, Natural (DX + 3));
            begin
               if abs (Q.X) + abs (Q.Y) < 0.35 then
                  if L /= 0 then
                     Hits := Hits + 1;
                     Check
                       (Point_In_Triangle (Q, M, Triangle_Index (L)),
                        "oct probe inside reported");
                  else
                     Check (False, "oct interior probe missed");
                  end if;
               end if;
            end;
         end loop;
      end loop;
      Check (Hits >= 5, "oct several interior hits");
      Check (Locate (P (2.0, 0.0), M) = 0, "oct outside far");
      Check (Locate (P (0.0, 2.0), M, 1) = 0, "oct outside north");
   end;

   ------------------------------------------------------------------
   Section ("8. Single triangle mesh");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0)];
      M   : constant Mesh := Build_Convex_Fan (Pts);
      Inp : constant Locate_Result := Locate (P (1.5, 1.0), M, 0);
      Outside : constant Locate_Result := Locate (P (10.0, 10.0), M, 0);
      W   : constant Locate_Result := Walk_From (P (1.5, 1.0), M, 1);
   begin
      Check (Triangle_Count_Of (M) = 1, "single tri count");
      Check (Get_Neighbors (M, 1).N1 = -1
               and then Get_Neighbors (M, 1).N2 = -1
               and then Get_Neighbors (M, 1).N3 = -1,
             "single tri all boundary");
      Check (Inp = 1, "single tri locate inside");
      Check (Outside = 0, "single tri locate outside");
      Check (W = 1, "single tri Walk_From inside");
      Check (Walk_From (P (-1.0, 0.0), M, 1) = 0,
             "single tri Walk_From outside");
   end;

   ------------------------------------------------------------------
   Section ("9. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Raised_Invalid_Empty, "Locate empty mesh raises");
   Check (Raised_Invalid_Fan ([P (0.0, 0.0), P (1.0, 0.0)]),
          "fan rejects 2 points");
   Check (Raised_Invalid_Fan ([P (0.0, 0.0)]),
          "fan rejects 1 point");

   declare
      Ok : Boolean := False;
      M  : Mesh;
   begin
      M := Build_Convex_Fan
        ([P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)]);
      Ok := Triangle_Count_Of (M) = 1;
      Check (Ok, "fan accepts 3 points");
   end;

   ------------------------------------------------------------------
   Section ("10. Centroid mesh helper / accessors");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (0.0, 3.0)];
      M   : constant Mesh := Build_Convex_Fan (Pts);
      C   : constant Point := Centroid (M, 1);
   begin
      Check (Near (C.X, R (1.0), 1.0E-9)
               and then Near (C.Y, R (1.0), 1.0E-9),
             "mesh Centroid");
      Check (Get_Triangle (M, 1).A = 1, "Get_Triangle A");
      Check (Near (Dist2 (C, P (1.0, 1.0)), R (0.0)), "centroid at (1,1)");
   end;

   ------------------------------------------------------------------
   Section ("11. Seed stability / sample budget");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.5, 1.5),
         P (0.0, 1.0)];
      M   : constant Mesh := Build_Convex_Fan (Pts);
      --  Convex? (0,0),(1,0),(1,1),(0,1),(0.5,1.5) — house shape, convex.
      A : constant Locate_Result :=
        Locate_Jump_And_Walk (P (0.5, 0.5), M, 99, 1);
      B : constant Locate_Result :=
        Locate_Jump_And_Walk (P (0.5, 0.5), M, 99, 1);
      C : constant Locate_Result :=
        Locate_Jump_And_Walk (P (0.5, 0.5), M, 99, 8);
      D : constant Locate_Result := Locate (P (0.5, 0.5), M, 0);
   begin
      Check (Triangle_Count_Of (M) = 3, "house fan 3 tris");
      Check (A /= 0 and then Point_In_Triangle
               (P (0.5, 0.5), M, Triangle_Index (A)),
             "seed sample=1 finds interior");
      Check (A = B, "same seed+budget reproducible");
      Check (C /= 0, "sample=8 finds interior");
      Check (D /= 0, "Locate default seed finds interior");
      Check (Locate (P (0.5, 1.2), M, 4) /= 0, "house roof interior");
      Check (Locate (P (2.0, 2.0), M, 4) = 0, "house outside");
   end;

   ------------------------------------------------------------------
   Section ("12. Walk across many fan triangles");
   ------------------------------------------------------------------
   declare
      --  Explicit convex polyline; fan from vertex 1.
      Pts : constant Point_Array :=
        [P (0.0, 0.0),
         P (5.0, 0.0),
         P (5.0, 1.0),
         P (4.5, 2.0),
         P (4.0, 3.0),
         P (3.0, 4.0),
         P (2.0, 4.5),
         P (1.0, 4.8),
         P (0.0, 5.0),
         P (-1.0, 4.5),
         P (-2.0, 3.0),
         P (-2.0, 0.5)];
      M : constant Mesh := Build_Convex_Fan (Pts);
      Far_Interior : Point;
      L : Locate_Result;
   begin
      Check (Triangle_Count_Of (M) = 10, "polyline fan 10 tris");

      --  Start Walk_From at T1, query near last triangles.
      Far_Interior := Centroid (M, 9);
      L := Walk_From (Far_Interior, M, 1);
      Check (L = 9, "long walk T1 -> T9");

      Far_Interior := Centroid (M, 10);
      L := Walk_From (Far_Interior, M, 1);
      Check (L = 10, "long walk T1 -> T10");

      Far_Interior := Centroid (M, 5);
      L := Locate (Far_Interior, M, 17);
      Check (L = 5, "Locate hits T5 centroid");

      Check (Locate (P (10.0, 10.0), M, 3) = 0, "polyline outside");
      Check (Walk_From (P (5.0, -1.0), M, 5) = 0,
             "walk exits to outside from mid");
   end;

   ------------------------------------------------------------------
   Section ("13. Boundary points / closed inclusion");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      M   : constant Mesh := Build_Convex_Fan (Pts);
      --  Shared internal edge from (0,0) to (2,2) — midpoint.
      Mid : constant Point := P (1.0, 1.0);
      L   : constant Locate_Result := Locate (Mid, M, 6);
      --  Outer edge midpoint of T1 BC = (2,0)-(2,2) wait T1=(1,2,3)=(0,0),(2,0),(2,2)
      Edge_Mid : constant Point := P (2.0, 1.0);
      LE : constant Locate_Result := Locate (Edge_Mid, M, 8);
   begin
      Check (L /= 0, "shared diagonal midpoint located");
      Check (Point_In_Triangle (Mid, M, Triangle_Index (L)),
             "diagonal midpoint in reported tri");
      Check (LE /= 0, "outer edge midpoint located");
      Check (Point_In_Triangle (Edge_Mid, M, Triangle_Index (LE)),
             "edge midpoint in reported tri");
      Check (Locate (P (0.0, 1.0), M, 2) /= 0, "left edge midpoint");
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;

   pragma Assert (Fail_Count = 0);
end Tests;
