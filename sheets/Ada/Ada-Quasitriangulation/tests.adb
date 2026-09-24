--  Standalone test suite for Quasitriangulation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Quasitriangulation; use Quasitriangulation;

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
   function S (A, B : Point) return Segment is ((A => A, B => B));
   function Seg (X1, Y1, X2, Y2 : Real) return Segment is
     (S (P (X1, Y1), P (X2, Y2)));

   function Raised_Build (Segs : Segment_Array) return Boolean is
      M : Quasi_Mesh;
   begin
      M := Build_From_Segments (Segs);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Build;

   function Raised_Points (Pts : Point_Array) return Boolean is
      M : Quasi_Mesh;
   begin
      M := From_Point_Sites (Pts);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Points;

   function Raised_Refine_Empty return Boolean is
      M : Quasi_Mesh;
      R : Quasi_Mesh;
   begin
      R := Refine_Toward_Delaunay_Like (M);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Refine_Empty;

begin
   Ada.Text_IO.Put_Line ("Quasitriangulation tests");
   Ada.Text_IO.Put_Line ("========================");

   ------------------------------------------------------------------
   Section ("1. Near / Dist2 / Distance / Orient2D / CCW");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)), "Dist2 3-4-5");
   Check (Near (Dist2 (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)), "Dist2 zero");
   Check (Near (Distance (P (0.0, 0.0), P (3.0, 4.0)), R (5.0), 1.0E-6),
          "Distance 3-4-5");
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
   Section ("2. Segment helpers / point-sites");
   ------------------------------------------------------------------
   declare
      Long : constant Segment := Seg (0.0, 0.0, 2.0, 0.0);
      Pt   : constant Segment := Seg (1.0, 1.0, 1.0, 1.0);
      M    : constant Point := Midpoint (Long);
   begin
      Check (Near (Segment_Length (Long), R (2.0), 1.0E-6), "Segment_Length 2");
      Check (Near (Segment_Length (Pt), R (0.0)), "Segment_Length 0");
      Check (Is_Point_Site (Pt), "Is_Point_Site true");
      Check (not Is_Point_Site (Long), "Is_Point_Site false for long");
      Check (Near (M.X, R (1.0)) and then Near (M.Y, R (0.0)), "Midpoint");
   end;

   ------------------------------------------------------------------
   Section ("3. Classify_Intersection");
   ------------------------------------------------------------------
   declare
      --  Proper cross: + axes through origin.
      H : constant Segment := Seg (-1.0, 0.0, 1.0, 0.0);
      V : constant Segment := Seg (0.0, -1.0, 0.0, 1.0);
      --  Disjoint parallel.
      A : constant Segment := Seg (0.0, 0.0, 1.0, 0.0);
      B : constant Segment := Seg (0.0, 1.0, 1.0, 1.0);
      --  Endpoint touch (share corner).
      C : constant Segment := Seg (0.0, 0.0, 1.0, 0.0);
      D : constant Segment := Seg (1.0, 0.0, 1.0, 1.0);
      --  Collinear overlap.
      E : constant Segment := Seg (0.0, 0.0, 2.0, 0.0);
      F : constant Segment := Seg (1.0, 0.0, 3.0, 0.0);
      --  Collinear disjoint.
      G : constant Segment := Seg (0.0, 0.0, 1.0, 0.0);
      I : constant Segment := Seg (2.0, 0.0, 3.0, 0.0);
   begin
      Check (Classify_Intersection (H, V) = Proper_Cross, "proper cross");
      Check (Segments_Properly_Cross (H, V), "Segments_Properly_Cross");
      Check (Classify_Intersection (A, B) = None, "parallel disjoint None");
      Check (not Segments_Properly_Cross (A, B), "not properly cross parallel");
      Check (Classify_Intersection (C, D) = Endpoint_Touch, "endpoint touch");
      Check (Classify_Intersection (E, F) = Collinear_Overlap, "collinear overlap");
      Check (Classify_Intersection (G, I) = None, "collinear disjoint None");
   end;

   ------------------------------------------------------------------
   Section ("4. Has_Proper_Crossing / All_Point_Sites");
   ------------------------------------------------------------------
   declare
      Crossers : constant Segment_Array :=
        [Seg (-1.0, 0.0, 1.0, 0.0),
         Seg (0.0, -1.0, 0.0, 1.0),
         Seg (2.0, 2.0, 3.0, 2.0)];
      Safe : constant Segment_Array :=
        [Seg (0.0, 0.0, 1.0, 0.0),
         Seg (0.0, 1.0, 1.0, 1.0),
         Seg (0.0, 2.0, 1.0, 2.0)];
      Points : constant Segment_Array :=
        [Seg (0.0, 0.0, 0.0, 0.0),
         Seg (1.0, 0.0, 1.0, 0.0),
         Seg (0.0, 1.0, 0.0, 1.0)];
   begin
      Check (Has_Proper_Crossing (Crossers), "detect crossing set");
      Check (not Has_Proper_Crossing (Safe), "safe set no crossing");
      Check (All_Point_Sites (Points), "All_Point_Sites");
      Check (not All_Point_Sites (Safe), "not All_Point_Sites for segments");
   end;

   ------------------------------------------------------------------
   Section ("5. Invalid_Argument guards (Build_From_Segments)");
   ------------------------------------------------------------------
   declare
      Too_Few : constant Segment_Array :=
        [Seg (0.0, 0.0, 1.0, 0.0), Seg (0.0, 1.0, 1.0, 1.0)];
      Degenerate : constant Segment_Array :=
        [Seg (0.0, 0.0, 0.0, 0.0),
         Seg (1.0, 0.0, 2.0, 0.0),
         Seg (0.0, 1.0, 1.0, 1.0)];
      Crossing : constant Segment_Array :=
        [Seg (-1.0, 0.0, 1.0, 0.0),
         Seg (0.0, -1.0, 0.0, 1.0),
         Seg (2.0, 2.0, 3.0, 3.0)];
      Overlap : constant Segment_Array :=
        [Seg (0.0, 0.0, 2.0, 0.0),
         Seg (1.0, 0.0, 3.0, 0.0),
         Seg (0.0, 1.0, 1.0, 2.0)];
      Collinear_Mids : constant Segment_Array :=
        [Seg (0.0, 0.0, 0.0, 1.0),
         Seg (1.0, 0.0, 1.0, 1.0),
         Seg (2.0, 0.0, 2.0, 1.0)];
      --  Midpoints at (0,0.5),(1,0.5),(2,0.5) — collinear → Invalid.
   begin
      Check (Raised_Build (Too_Few), "reject 2 segments");
      Check (Raised_Build (Degenerate), "reject zero-length site");
      Check (Raised_Build (Crossing), "reject proper crossing");
      Check (Raised_Build (Overlap), "reject collinear overlap");
      Check (Raised_Build (Collinear_Mids), "reject collinear midpoints");
      Check (Raised_Points ([P (0.0, 0.0), P (1.0, 0.0)]), "reject 2 points");
      Check (Raised_Points ([P (0.0, 0.0), P (1.0, 0.0), P (0.0, 0.0)]),
             "reject duplicate points");
      Check (Raised_Refine_Empty, "refine empty raises");
   end;

   ------------------------------------------------------------------
   Section ("6. Tiny quasi-triangulation (3 non-crossing segments)");
   ------------------------------------------------------------------
   declare
      Segs : constant Segment_Array :=
        [Seg (0.0, 0.0, 1.0, 0.0),    -- bottom
         Seg (0.5, 1.0, 1.5, 1.0),    -- top-rightish
         Seg (-0.5, 1.0, 0.2, 1.5)];  -- top-leftish
      M : constant Quasi_Mesh := Build_From_Segments (Segs);
   begin
      Check (Segment_Count_Of (M) = 3, "3 segment-sites");
      Check (Face_Count (M) = 1, "one triangular face");
      Check (Edge_Count (M) = 3, "three edges");
      Check (Is_Quasi_Setting (M), "Is_Quasi_Setting");
      Check (not Is_Classical_Point_Setting (M), "not classical points");
      Check (Faces_Reference_Valid_Sites (M), "faces valid sites");
      Check (Euler_Characteristic (M) = 1, "Euler chi = 1");
      Check (Euler_Check (M), "Euler_Check");
      Check (Is_Topological_Triangulation (M), "Is_Topological_Triangulation");
      declare
         F : constant Simplex := Get_Face (M, 1);
      begin
         Check (F.U /= F.V and then F.V /= F.W and then F.W /= F.U,
                "face corners distinct");
         Check (F.U <= 3 and then F.V <= 3 and then F.W <= 3,
                "face indices in range");
      end;
      declare
         S1 : constant Segment := Get_Segment (M, 1);
      begin
         Check (not Is_Point_Site (S1), "stored site still a segment");
         Check (Near (Segment_Length (S1), R (1.0), 1.0E-6),
                "stored segment length");
      end;
   end;

   ------------------------------------------------------------------
   Section ("7. Four non-crossing segments (fan)");
   ------------------------------------------------------------------
   declare
      Segs : constant Segment_Array :=
        [Seg (0.0, 0.0, 0.5, 0.2),
         Seg (2.0, 0.0, 2.5, 0.1),
         Seg (1.0, 2.0, 1.5, 2.2),
         Seg (-1.0, 1.5, -0.5, 1.7)];
      M : constant Quasi_Mesh := Build_From_Segments (Segs);
   begin
      Check (Segment_Count_Of (M) = 4, "4 sites");
      Check (Face_Count (M) >= 1, "at least one face");
      Check (Face_Count (M) <= 2, "fan has at most 2 faces for 4 sites");
      Check (Is_Quasi_Setting (M), "quasi setting (4)");
      Check (Is_Topological_Triangulation (M), "topo triangulation (4)");
      Check (Euler_Check (M), "Euler (4)");
      Check (Edge_Count (M) >= 3, "edges >= 3");
      --  Accessors
      Check (Get_Edge (M, 1).P < Get_Edge (M, 1).Q
               or else Get_Edge (M, 1).P > 0,
             "edge accessor ordered/valid");
   end;

   ------------------------------------------------------------------
   Section ("8. From_Point_Sites (classical contrast)");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (1.0, 1.5)];
      M : constant Quasi_Mesh := From_Point_Sites (Pts);
   begin
      Check (Segment_Count_Of (M) = 3, "point wrap: 3 sites");
      Check (Face_Count (M) = 1, "point wrap: 1 face");
      Check (Is_Classical_Point_Setting (M), "classical point setting");
      Check (not Is_Quasi_Setting (M), "not quasi when all points");
      Check (Is_Topological_Triangulation (M), "topo from points");
      Check (Is_Point_Site (Get_Segment (M, 1)), "wrapped site is point");
      Check (Is_Point_Site (Get_Segment (M, 2)), "wrapped site 2 point");
      Check (Is_Point_Site (Get_Segment (M, 3)), "wrapped site 3 point");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 2.0), P (0.0, 2.0)];
      M : constant Quasi_Mesh := From_Point_Sites (Pts);
   begin
      Check (Segment_Count_Of (M) = 4, "square: 4 point sites");
      Check (Face_Count (M) = 2, "square fan: 2 faces");
      Check (Euler_Check (M), "square Euler");
      Check (Is_Topological_Triangulation (M), "square topo");
      Check (Is_Classical_Point_Setting (M), "square classical");
   end;

   ------------------------------------------------------------------
   Section ("9. Refine_Toward_Delaunay_Like stub");
   ------------------------------------------------------------------
   declare
      Segs : constant Segment_Array :=
        [Seg (0.0, 0.0, 1.0, 0.0),
         Seg (0.5, 1.0, 1.5, 1.0),
         Seg (-0.5, 1.0, 0.2, 1.5)];
      M : constant Quasi_Mesh := Build_From_Segments (Segs);
      R : constant Quasi_Mesh := Refine_Toward_Delaunay_Like (M);
   begin
      Check (Segment_Count_Of (R) = Segment_Count_Of (M), "refine preserves V");
      Check (Face_Count (R) = Face_Count (M), "refine preserves F");
      Check (Is_Topological_Triangulation (R), "refine still topo");
      Check (Is_Quasi_Setting (R), "refine still quasi");
      --  Proxy orientation CCW after refine.
      declare
         F : constant Simplex := Get_Face (R, 1);
         O : constant Real :=
           Orient2D
             (Midpoint (Get_Segment (R, F.U)),
              Midpoint (Get_Segment (R, F.V)),
              Midpoint (Get_Segment (R, F.W)));
      begin
         Check (O > -Epsilon, "refine face CCW (or flat)");
      end;
   end;

   ------------------------------------------------------------------
   Section ("10. Endpoint-touch allowed (non-crossing)");
   ------------------------------------------------------------------
   declare
      --  Three segments meeting at a shared corner — no proper cross.
      Segs : constant Segment_Array :=
        [Seg (0.0, 0.0, 1.0, 0.0),
         Seg (1.0, 0.0, 1.0, 1.0),
         Seg (1.0, 0.0, 0.0, 1.0)];
      Kind : constant Intersection_Kind :=
        Classify_Intersection (Segs (1), Segs (2));
   begin
      Check (Kind = Endpoint_Touch, "L-joint is Endpoint_Touch");
      Check (not Has_Proper_Crossing (Segs), "touching set not proper-cross");
      declare
         M : constant Quasi_Mesh := Build_From_Segments (Segs);
      begin
         Check (Is_Topological_Triangulation (M), "touching set builds");
         Check (Face_Count (M) = 1, "touching set one face");
      end;
   end;

   ------------------------------------------------------------------
   Section ("11. Capacity / constants sanity");
   ------------------------------------------------------------------
   declare
      function Nat (N : Natural) return Natural is (N);
      function RR (X : Real) return Real is (X);
   begin
      Check (Nat (Max_Segments) >= 8, "Max_Segments classroom-sized");
      Check (Nat (Max_Faces) >= Nat (Max_Segments), "Max_Faces >= Max_Segments");
      Check (Nat (Max_Edges) >= 3, "Max_Edges >= 3");
      Check (RR (Epsilon) > 0.0, "Epsilon positive");
   end;

   ------------------------------------------------------------------
   Section ("12. More orientation / intersection edge cases");
   ------------------------------------------------------------------
   declare
      --  T-junction: vertical hits middle of horizontal.
      H : constant Segment := Seg (0.0, 0.0, 2.0, 0.0);
      T : constant Segment := Seg (1.0, 0.0, 1.0, 1.0);
      K : constant Intersection_Kind := Classify_Intersection (H, T);
      --  Almost parallel disjoint.
      A : constant Segment := Seg (0.0, 0.0, 1.0, 0.1);
      B : constant Segment := Seg (0.0, 1.0, 1.0, 1.1);
   begin
      Check (K = Endpoint_Touch, "T-junction Endpoint_Touch");
      Check (Classify_Intersection (A, B) = None, "skew parallel-ish None");
      Check (not Segments_Properly_Cross (H, T), "T not proper cross");
   end;

   ------------------------------------------------------------------
   Section ("13. Five segments fan");
   ------------------------------------------------------------------
   declare
      Segs : constant Segment_Array :=
        [Seg (0.0, 0.0, 0.3, 0.1),
         Seg (3.0, 0.0, 3.2, 0.2),
         Seg (1.5, 3.0, 1.7, 3.1),
         Seg (-1.0, 2.0, -0.8, 2.1),
         Seg (4.0, 2.0, 4.2, 2.2)];
      M : constant Quasi_Mesh := Build_From_Segments (Segs);
   begin
      Check (Segment_Count_Of (M) = 5, "5 sites");
      Check (Face_Count (M) = 3, "fan: N-2 = 3 faces");
      Check (Is_Topological_Triangulation (M), "5-site topo");
      Check (Euler_Check (M), "5-site Euler");
      Check (Is_Quasi_Setting (M), "5-site quasi");
      Check (Edge_Count (M) = 3 + 2 * (Face_Count (M) - 1)
               or else Edge_Count (M) >= Face_Count (M) + 2,
             "edge count plausible for fan");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
