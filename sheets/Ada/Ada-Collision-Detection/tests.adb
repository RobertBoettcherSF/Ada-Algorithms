--  Standalone test suite for Collision_Detection (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Collision_Detection; use Collision_Detection;

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
   function Pt (X, Y : Real) return Point is ((X => X, Y => Y));

   function Raised_AABB (A, B : AABB) return Boolean is
      Bv : Boolean;
   begin
      Bv := AABB_Overlap (A, B);
      pragma Unreferenced (Bv);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_AABB;

   function Raised_Circle
     (C1 : Point; R1 : Real; C2 : Point; R2 : Real) return Boolean
   is
      Bv : Boolean;
   begin
      Bv := Circle_Overlap (C1, R1, C2, R2);
      pragma Unreferenced (Bv);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Circle;

   function Raised_SAT (A, B : Polygon) return Boolean is
      Bv : Boolean;
   begin
      Bv := Convex_Polygons_Overlap (A, B);
      pragma Unreferenced (Bv);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_SAT;

   function Raised_Seg
     (P1, Q1, P2, Q2 : Point) return Boolean
   is
      Bv : Boolean;
   begin
      Bv := Segments_Intersect (P1, Q1, P2, Q2);
      pragma Unreferenced (Bv);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Seg;

   function Raised_Brute_AABB (Boxes : AABB_Array) return Boolean is
      P : Pair_List;
   begin
      P := Brute_Force_Pairs (Boxes);
      pragma Unreferenced (P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Brute_AABB;

   function Raised_SAP (Boxes : AABB_Array) return Boolean is
      P : Pair_List;
   begin
      P := Sweep_And_Prune_Pairs (Boxes);
      pragma Unreferenced (P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_SAP;

   function Raised_Brute_Circ (Circles : Circle_Array) return Boolean is
      P : Pair_List;
   begin
      P := Brute_Force_Pairs (Circles);
      pragma Unreferenced (P);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Brute_Circ;

   function Raised_Make_AABB
     (Min_X, Min_Y, Max_X, Max_Y : Real) return Boolean
   is
      B : AABB;
   begin
      B := Make_AABB (Min_X, Min_Y, Max_X, Max_Y);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Make_AABB;

   function Raised_Make_Circle (Cx, Cy, Radius : Real) return Boolean is
      C : Circle;
   begin
      C := Make_Circle (Cx, Cy, Radius);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Make_Circle;

begin
   Ada.Text_IO.Put_Line ("Collision_Detection test suite");
   Ada.Text_IO.Put_Line ("==============================");

   ---------------------------------------------------------------------
   Section ("1. AABB overlap (closed intervals)");
   ---------------------------------------------------------------------
   declare
      A : constant AABB := Make_AABB (0.0, 0.0, 1.0, 1.0);
      B : constant AABB := Make_AABB (0.5, 0.5, 1.5, 1.5);
      C : constant AABB := Make_AABB (2.0, 2.0, 3.0, 3.0);
      D : constant AABB := Make_AABB (1.0, 0.0, 2.0, 1.0);  -- touch on x=1
      E : constant AABB := Make_AABB (1.0, 1.0, 2.0, 2.0);  -- touch corner
      F : constant AABB := Make_AABB (-1.0, -1.0, 0.0, 0.0);
      Bad : constant AABB := (Min => Pt (1.0, 0.0), Max => Pt (0.0, 1.0));
   begin
      Check (AABB_Overlap (A, B), "interior overlap");
      Check (not AABB_Overlap (A, C), "far separated");
      Check (AABB_Overlap (A, D), "edge-touching closed overlap");
      Check (AABB_Overlap (A, E), "corner-touching closed overlap");
      Check (AABB_Overlap (A, F), "touch at origin corner");
      Check (AABB_Overlap (A, A), "identical boxes");
      Check (Is_Valid_AABB (A), "valid unit box");
      Check (not Is_Valid_AABB (Bad), "inverted X invalid");
      Check (Raised_AABB (A, Bad), "invalid B raises");
      Check (Raised_AABB (Bad, A), "invalid A raises");
      Check (Raised_Make_AABB (1.0, 0.0, 0.0, 1.0), "Make_AABB Max<Min raises");
      Check (not Raised_Make_AABB (0.0, 0.0, 0.0, 0.0), "degenerate point AABB ok");
   end;

   ---------------------------------------------------------------------
   Section ("2. Circle overlap (closed)");
   ---------------------------------------------------------------------
   declare
      C1 : constant Point := Pt (0.0, 0.0);
      C2 : constant Point := Pt (3.0, 0.0);
      C3 : constant Point := Pt (1.0, 1.0);
      Cir_A : constant Circle := Make_Circle (0.0, 0.0, 1.0);
      Cir_B : constant Circle := Make_Circle (2.0, 0.0, 1.0);  -- touch
      Cir_C : constant Circle := Make_Circle (3.0, 0.0, 1.0);  -- separated
      Cir_D : constant Circle := Make_Circle (0.5, 0.0, 1.0);  -- overlap
   begin
      Check (Circle_Overlap (C1, R (1.0), C3, R (1.0)), "circles overlap");
      Check (Circle_Overlap (C1, R (1.0), C2, R (2.0)), "touching distance=3");
      Check (not Circle_Overlap (C1, R (1.0), C2, R (1.0)), "separated r=1+1");
      Check (Circle_Overlap (Cir_A, Cir_B), "record touch at x=1");
      Check (not Circle_Overlap (Cir_A, Cir_C), "record separated");
      Check (Circle_Overlap (Cir_A, Cir_D), "record interior");
      Check (Circle_Overlap (C1, R (0.0), C1, R (0.0)), "point=point radius 0");
      Check (Is_Valid_Circle (Cir_A), "valid circle");
      Check (Raised_Circle (C1, R (-1.0), C2, R (1.0)), "neg R1 raises");
      Check (Raised_Circle (C1, R (1.0), C2, R (-0.1)), "neg R2 raises");
      Check (Raised_Make_Circle (0.0, 0.0, R (-1.0)), "Make_Circle neg raises");
      Check (not Raised_Make_Circle (0.0, 0.0, R (0.0)), "zero radius ok");
   end;

   ---------------------------------------------------------------------
   Section ("3. SAT convex polygons");
   ---------------------------------------------------------------------
   declare
      --  Unit square [0,1]² CCW
      Sq1 : constant Polygon :=
        [1 => Pt (0.0, 0.0), 2 => Pt (1.0, 0.0),
         3 => Pt (1.0, 1.0), 4 => Pt (0.0, 1.0)];
      --  Overlapping square [0.5,1.5]²
      Sq2 : constant Polygon :=
        [1 => Pt (0.5, 0.5), 2 => Pt (1.5, 0.5),
         3 => Pt (1.5, 1.5), 4 => Pt (0.5, 1.5)];
      --  Separated square [3,4]²
      Sq3 : constant Polygon :=
        [1 => Pt (3.0, 3.0), 2 => Pt (4.0, 3.0),
         3 => Pt (4.0, 4.0), 4 => Pt (3.0, 4.0)];
      --  Edge-touching square [1,2]×[0,1]
      Sq4 : constant Polygon :=
        [1 => Pt (1.0, 0.0), 2 => Pt (2.0, 0.0),
         3 => Pt (2.0, 1.0), 4 => Pt (1.0, 1.0)];
      --  Triangles
      Tri1 : constant Polygon :=
        [1 => Pt (0.0, 0.0), 2 => Pt (2.0, 0.0), 3 => Pt (1.0, 2.0)];
      Tri2 : constant Polygon :=
        [1 => Pt (1.0, 0.5), 2 => Pt (3.0, 0.5), 3 => Pt (2.0, 2.5)];
      Tri3 : constant Polygon :=
        [1 => Pt (5.0, 5.0), 2 => Pt (6.0, 5.0), 3 => Pt (5.5, 6.0)];
      --  Separated by vertical axis: left vs right
      Left : constant Polygon :=
        [1 => Pt (0.0, 0.0), 2 => Pt (1.0, 0.0),
         3 => Pt (1.0, 1.0), 4 => Pt (0.0, 1.0)];
      Right : constant Polygon :=
        [1 => Pt (2.0, 0.0), 2 => Pt (3.0, 0.0),
         3 => Pt (3.0, 1.0), 4 => Pt (2.0, 1.0)];
      Deg : constant Polygon := [1 => Pt (0.0, 0.0), 2 => Pt (1.0, 0.0)];
   begin
      Check (Convex_Polygons_Overlap (Sq1, Sq2), "square vs square overlap");
      Check (not Convex_Polygons_Overlap (Sq1, Sq3), "square vs square far");
      Check (Convex_Polygons_Overlap (Sq1, Sq4), "square edge-touch closed");
      Check (Convex_Polygons_Overlap (Sq1, Sq1), "identical squares");
      Check (Convex_Polygons_Overlap (Tri1, Tri2), "triangle vs triangle overlap");
      Check (not Convex_Polygons_Overlap (Tri1, Tri3), "triangle vs triangle sep");
      Check (not Convex_Polygons_Overlap (Left, Right), "separated by vertical axis");
      Check (Raised_SAT (Deg, Sq1), "n<3 raises");
      Check (Raised_SAT (Sq1, Deg), "n<3 on B raises");
   end;

   ---------------------------------------------------------------------
   Section ("4. Segment intersection");
   ---------------------------------------------------------------------
   declare
      --  Crossing +
      A1 : constant Point := Pt (0.0, 0.0);
      A2 : constant Point := Pt (2.0, 2.0);
      B1 : constant Point := Pt (0.0, 2.0);
      B2 : constant Point := Pt (2.0, 0.0);
      --  Parallel separated
      C1 : constant Point := Pt (0.0, 0.0);
      C2 : constant Point := Pt (1.0, 0.0);
      D1 : constant Point := Pt (0.0, 1.0);
      D2 : constant Point := Pt (1.0, 1.0);
      --  Endpoint touch (improper)
      E1 : constant Point := Pt (0.0, 0.0);
      E2 : constant Point := Pt (1.0, 0.0);
      F1 : constant Point := Pt (1.0, 0.0);
      F2 : constant Point := Pt (2.0, 1.0);
      --  Collinear overlap
      G1 : constant Point := Pt (0.0, 0.0);
      G2 : constant Point := Pt (2.0, 0.0);
      H1 : constant Point := Pt (1.0, 0.0);
      H2 : constant Point := Pt (3.0, 0.0);
      --  Degenerate
      Z : constant Point := Pt (1.0, 1.0);
   begin
      Check (Segments_Intersect (A1, A2, B1, B2), "proper cross");
      Check (not Segments_Intersect (C1, C2, D1, D2), "parallel separated");
      Check (Segments_Intersect (E1, E2, F1, F2), "improper endpoint touch");
      Check (Segments_Intersect (G1, G2, H1, H2), "collinear overlap");
      Check (not Segments_Intersect
               (Pt (0.0, 0.0), Pt (1.0, 0.0),
                Pt (2.0, 0.0), Pt (3.0, 0.0)),
             "collinear gap no intersect");
      Check (Raised_Seg (Z, Z, A1, A2), "degenerate segment raises");
   end;

   ---------------------------------------------------------------------
   Section ("5. Brute force AABB / circles");
   ---------------------------------------------------------------------
   declare
      Boxes : constant AABB_Array (1 .. 4) :=
        [1 => Make_AABB (0.0, 0.0, 1.0, 1.0),
         2 => Make_AABB (0.5, 0.5, 1.5, 1.5),  -- overlaps 1
         3 => Make_AABB (3.0, 3.0, 4.0, 4.0),  -- alone
         4 => Make_AABB (0.9, 0.9, 1.1, 1.1)]; -- overlaps 1 and 2
      P : constant Pair_List := Brute_Force_Pairs (Boxes);
      F : constant Pair_List := Find_Colliding_AABBs (Boxes);
      Circs : constant Circle_Array (1 .. 3) :=
        [1 => Make_Circle (0.0, 0.0, 1.0),
         2 => Make_Circle (1.5, 0.0, 1.0),  -- overlaps 1
         3 => Make_Circle (10.0, 10.0, 0.5)];
      CP : constant Pair_List := Find_Colliding_Circles (Circs);
      Empty_B : AABB_Array (1 .. 0);
      One_Bad : constant AABB_Array (1 .. 1) :=
        [1 => (Min => Pt (1.0, 0.0), Max => Pt (0.0, 1.0))];
   begin
      Check (P.Count = 3, "brute AABB three pairs");
      Check (Contains_Pair (P, 1, 2), "brute has (1,2)");
      Check (Contains_Pair (P, 1, 4), "brute has (1,4)");
      Check (Contains_Pair (P, 2, 4), "brute has (2,4)");
      Check (not Contains_Pair (P, 1, 3), "brute no (1,3)");
      Check (Same_Pair_Set (P, F), "Find_Colliding_AABBs = brute");
      Check (CP.Count = 1, "circle one pair");
      Check (Contains_Pair (CP, 1, 2), "circle pair (1,2)");
      Check (Raised_Brute_AABB (Empty_B), "empty AABB array raises");
      Check (Raised_Brute_AABB (One_Bad), "bad AABB in brute raises");
      Check (Raised_Brute_Circ
               ([1 => (Center => Pt (0.0, 0.0), Radius => R (-1.0))]),
             "neg radius in brute raises");
   end;

   ---------------------------------------------------------------------
   Section ("6. Sweep-and-prune vs brute (same pair sets)");
   ---------------------------------------------------------------------
   declare
      Scene1 : constant AABB_Array (1 .. 5) :=
        [1 => Make_AABB (0.0, 0.0, 1.0, 1.0),
         2 => Make_AABB (0.5, 0.0, 1.5, 0.5),
         3 => Make_AABB (2.0, 2.0, 3.0, 3.0),
         4 => Make_AABB (2.5, 2.5, 3.5, 3.5),
         5 => Make_AABB (10.0, 10.0, 11.0, 11.0)];
      Scene2 : constant AABB_Array (1 .. 4) :=
        [1 => Make_AABB (0.0, 0.0, 2.0, 2.0),
         2 => Make_AABB (1.0, 1.0, 3.0, 3.0),
         3 => Make_AABB (0.0, 1.5, 0.5, 2.5),
         4 => Make_AABB (5.0, 0.0, 6.0, 1.0)];
      Scene3 : constant AABB_Array (1 .. 3) :=
        [1 => Make_AABB (0.0, 0.0, 1.0, 1.0),
         2 => Make_AABB (1.0, 0.0, 2.0, 1.0),  -- touch on edge
         3 => Make_AABB (2.0, 0.0, 3.0, 1.0)]; -- touch 2
      Scene4 : constant AABB_Array (1 .. 6) :=
        [1 => Make_AABB (0.0, 0.0, 0.5, 0.5),
         2 => Make_AABB (0.4, 0.4, 0.9, 0.9),
         3 => Make_AABB (0.8, 0.0, 1.2, 0.3),
         4 => Make_AABB (2.0, 2.0, 2.1, 2.1),
         5 => Make_AABB (2.05, 2.05, 2.2, 2.2),
         6 => Make_AABB (-1.0, -1.0, -0.5, -0.5)];
      B1 : constant Pair_List := Brute_Force_Pairs (Scene1);
      S1 : constant Pair_List := Sweep_And_Prune_Pairs (Scene1);
      B2 : constant Pair_List := Brute_Force_Pairs (Scene2);
      S2 : constant Pair_List := Sweep_And_Prune_Pairs (Scene2);
      B3 : constant Pair_List := Brute_Force_Pairs (Scene3);
      S3 : constant Pair_List := Sweep_And_Prune_Pairs (Scene3);
      B4 : constant Pair_List := Brute_Force_Pairs (Scene4);
      S4 : constant Pair_List := Sweep_And_Prune_Pairs (Scene4);
      Empty_B : AABB_Array (1 .. 0);
   begin
      Check (Same_Pair_Set (B1, S1), "scene1 brute=SAP");
      Check (Same_Pair_Set (B2, S2), "scene2 brute=SAP");
      Check (Same_Pair_Set (B3, S3), "scene3 touching brute=SAP");
      Check (Same_Pair_Set (B4, S4), "scene4 brute=SAP");
      Check (B1.Count = 2, "scene1 has 2 pairs");
      Check (Contains_Pair (S1, 1, 2), "SAP scene1 (1,2)");
      Check (Contains_Pair (S1, 3, 4), "SAP scene1 (3,4)");
      Check (B3.Count = 2, "scene3 two touching pairs");
      Check (Raised_SAP (Empty_B), "empty SAP raises");
   end;

   ---------------------------------------------------------------------
   Section ("7. Pair list helpers");
   ---------------------------------------------------------------------
   declare
      P : Pair_List := Empty_Pair_List;
      Q : Pair_List;
   begin
      Check (P.Count = 0, "empty pair list");
      Append_Pair (P, 3, 1);
      Check (P.Count = 1, "one pair after append");
      Check (P.Items (1).A = 1 and then P.Items (1).B = 3, "canonical A<B");
      Append_Pair (P, 1, 3);
      Check (P.Count = 1, "duplicate append ignored");
      Append_Pair (P, 2, 5);
      Append_Pair (P, 4, 2);
      Normalize_Pairs (P);
      Check (P.Count = 3, "three unique after normalize");
      Check (P.Items (1).A = 1 and then P.Items (1).B = 3, "sorted first");
      Check (Contains_Pair (P, 5, 2), "contains unordered");
      Q := P;
      Clear (P);
      Check (P.Count = 0, "cleared");
      Check (not Same_Pair_Set (P, Q), "empty ≠ nonempty");
      Check (Same_Pair_Set (Q, Q), "reflexive same set");
   end;

   ---------------------------------------------------------------------
   Section ("8. Near / Dot / Cross / Dist2 / Orient2D");
   ---------------------------------------------------------------------
   declare
      A : constant Point := Pt (1.0, 0.0);
      B : constant Point := Pt (0.0, 1.0);
      O : constant Point := Pt (0.0, 0.0);
   begin
      Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near close");
      Check (not Near (R (1.0), R (2.0)), "Near far");
      Check (Near (Dot (A, B), R (0.0)), "Dot orthogonal");
      Check (Near (Cross (A, B), R (1.0)), "Cross right-handed");
      Check (Near (Dist2 (O, A), R (1.0)), "Dist2 unit");
      Check (Orient2D (O, A, B) > 0.0, "Orient2D CCW positive");
      Check (Orient2D (O, B, A) < 0.0, "Orient2D CW negative");
   end;

   ---------------------------------------------------------------------
   Section ("9. More AABB / circle edge cases");
   ---------------------------------------------------------------------
   declare
      Tiny : constant AABB := Make_AABB (0.0, 0.0, 0.0, 0.0);
      Big  : constant AABB := Make_AABB (-10.0, -10.0, 10.0, 10.0);
      Nest : constant AABB := Make_AABB (-1.0, -1.0, 1.0, 1.0);
      Inner : constant AABB := Make_AABB (-0.5, -0.5, 0.5, 0.5);
   begin
      Check (AABB_Overlap (Tiny, Big), "point inside big");
      Check (AABB_Overlap (Nest, Inner), "nested AABBs");
      Check (AABB_Overlap (Inner, Nest), "nested symmetric");
   end;

   --  Correct circle count check outside messy comment block
   declare
      Circs : constant Circle_Array (1 .. 4) :=
        [1 => Make_Circle (0.0, 0.0, 2.0),
         2 => Make_Circle (0.0, 0.0, 1.0),
         3 => Make_Circle (5.0, 0.0, 1.0),
         4 => Make_Circle (5.0, 0.0, 1.0)];
      CP : constant Pair_List := Brute_Force_Pairs (Circs);
      Boxes : constant AABB_Array (1 .. 2) :=
        [1 => Make_AABB (0.0, 0.0, 1.0, 1.0),
         2 => Make_AABB (0.0, 0.0, 1.0, 1.0)];
      BP : constant Pair_List := Sweep_And_Prune_Pairs (Boxes);
   begin
      Check (CP.Count = 2, "nested+identical circles two pairs");
      Check (Contains_Pair (CP, 1, 2), "concentric overlap");
      Check (Contains_Pair (CP, 3, 4), "identical circles overlap");
      Check (BP.Count = 1, "identical AABBs one SAP pair");
      Check (Contains_Pair (BP, 1, 2), "SAP identical pair");
   end;

   ---------------------------------------------------------------------
   Section ("10. Oversized / capacity guards");
   ---------------------------------------------------------------------
   declare
      --  Build an array larger than Max_Objects via a constrained view
      --  is hard at compile time; test Max_Vertices via SAT and empty.
      Big_Poly : Polygon (1 .. 3);
      Tiny_Poly : constant Polygon :=
        [1 => Pt (0.0, 0.0), 2 => Pt (1.0, 0.0), 3 => Pt (0.0, 1.0)];
   begin
      Big_Poly :=
        [1 => Pt (0.0, 0.0), 2 => Pt (1.0, 0.0), 3 => Pt (0.5, 1.0)];
      Check (Convex_Polygons_Overlap (Big_Poly, Tiny_Poly),
             "minimal triangles overlap-ish");
      Check (Raised_SAT
               ([1 => Pt (0.0, 0.0)], Tiny_Poly),
             "single-vertex polygon raises");
   end;

   ---------------------------------------------------------------------
   Section ("11. Extra SAP / brute scenes");
   ---------------------------------------------------------------------
   declare
      --  All pairwise overlap in a chain along X with Y overlap
      Chain : constant AABB_Array (1 .. 5) :=
        [1 => Make_AABB (0.0, 0.0, 1.1, 1.0),
         2 => Make_AABB (1.0, 0.0, 2.1, 1.0),
         3 => Make_AABB (2.0, 0.0, 3.1, 1.0),
         4 => Make_AABB (3.0, 0.0, 4.1, 1.0),
         5 => Make_AABB (4.0, 0.0, 5.0, 1.0)];
      BC : constant Pair_List := Brute_Force_Pairs (Chain);
      SC : constant Pair_List := Sweep_And_Prune_Pairs (Chain);
      --  No overlaps
      Alone : constant AABB_Array (1 .. 3) :=
        [1 => Make_AABB (0.0, 0.0, 0.5, 0.5),
         2 => Make_AABB (2.0, 2.0, 2.5, 2.5),
         3 => Make_AABB (4.0, 0.0, 4.5, 0.5)];
      BA : constant Pair_List := Brute_Force_Pairs (Alone);
      SA : constant Pair_List := Sweep_And_Prune_Pairs (Alone);
      --  Y-separated but X-overlapping (SAP must filter via Y)
      YSep : constant AABB_Array (1 .. 2) :=
        [1 => Make_AABB (0.0, 0.0, 1.0, 1.0),
         2 => Make_AABB (0.0, 2.0, 1.0, 3.0)];
      BY : constant Pair_List := Brute_Force_Pairs (YSep);
      SY : constant Pair_List := Sweep_And_Prune_Pairs (YSep);
   begin
      Check (Same_Pair_Set (BC, SC), "chain brute=SAP");
      Check (BC.Count = 4, "chain adjacent pairs only");
      Check (Same_Pair_Set (BA, SA), "alone brute=SAP");
      Check (BA.Count = 0, "alone zero pairs");
      Check (Same_Pair_Set (BY, SY), "Y-sep brute=SAP");
      Check (BY.Count = 0, "Y-separated zero pairs");
   end;

   ---------------------------------------------------------------------
   Section ("12. SAT more shapes");
   ---------------------------------------------------------------------
   declare
      Hex : constant Polygon :=
        [1 => Pt (1.0, 0.0),
         2 => Pt (0.5, 0.866),
         3 => Pt (-0.5, 0.866),
         4 => Pt (-1.0, 0.0),
         5 => Pt (-0.5, -0.866),
         6 => Pt (0.5, -0.866)];
      Small : constant Polygon :=
        [1 => Pt (-0.2, -0.2),
         2 => Pt (0.2, -0.2),
         3 => Pt (0.2, 0.2),
         4 => Pt (-0.2, 0.2)];
      Far : constant Polygon :=
        [1 => Pt (10.0, 10.0),
         2 => Pt (11.0, 10.0),
         3 => Pt (10.5, 11.0)];
      Diamond : constant Polygon :=
        [1 => Pt (0.0, -1.0),
         2 => Pt (1.0, 0.0),
         3 => Pt (0.0, 1.0),
         4 => Pt (-1.0, 0.0)];
   begin
      Check (Convex_Polygons_Overlap (Hex, Small), "hex contains square");
      Check (not Convex_Polygons_Overlap (Hex, Far), "hex vs far triangle");
      Check (Convex_Polygons_Overlap (Hex, Diamond), "hex vs diamond");
      Check (Convex_Polygons_Overlap (Diamond, Small), "diamond vs center sq");
   end;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
