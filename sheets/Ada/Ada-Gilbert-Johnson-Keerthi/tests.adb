--  Standalone test suite for Gilbert_Johnson_Keerthi (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Gilbert_Johnson_Keerthi; use Gilbert_Johnson_Keerthi;

procedure Tests is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

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

   function Raised_Invalid_Distance (A, B : Polygon) return Boolean is
      D : Real;
   begin
      D := Distance (A, B);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Distance;

   function Raised_Invalid_Intersect (A, B : Polygon) return Boolean is
      Bv : Boolean;
   begin
      Bv := Intersect (A, B);
      pragma Unreferenced (Bv);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Intersect;

   function Raised_Invalid_Ensure (Poly : Polygon) return Boolean is
   begin
      declare
         C : constant Polygon := Ensure_Convex_CCW (Poly);
      begin
         pragma Unreferenced (C);
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Ensure;

   function Raised_Invalid_Support (Poly : Polygon) return Boolean is
      Q : Point;
   begin
      Q := Support (Poly, (X => 1.0, Y => 0.0));
      pragma Unreferenced (Q);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Support;

   function Raised_Invalid_Regular (N : Vertex_Count; Radius : Real)
     return Boolean
   is
   begin
      declare
         Poly : constant Polygon := Regular_Polygon (N, Radius);
      begin
         pragma Unreferenced (Poly);
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Regular;

   function Raised_Invalid_Square (Half : Real) return Boolean is
   begin
      declare
         Poly : constant Polygon :=
           Axis_Aligned_Square ((X => 0.0, Y => 0.0), Half);
      begin
         pragma Unreferenced (Poly);
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Square;

   ---------------------------------------------------------------------------
   -- Fixtures
   ---------------------------------------------------------------------------

   --  Unit square [0,1]×[0,1], CCW.
   Unit_Square : constant Polygon :=
     [(X => 0.0, Y => 0.0),
      (X => 1.0, Y => 0.0),
      (X => 1.0, Y => 1.0),
      (X => 0.0, Y => 1.0)];

   --  Square translated to [2,3]×[2,3] — gap of 1 from Unit_Square.
   Far_Square : constant Polygon :=
     [(X => 2.0, Y => 2.0),
      (X => 3.0, Y => 2.0),
      (X => 3.0, Y => 3.0),
      (X => 2.0, Y => 3.0)];

   --  Square [1,2]×[0,1] — touches Unit_Square along x=1 edge.
   Touch_Square : constant Polygon :=
     [(X => 1.0, Y => 0.0),
      (X => 2.0, Y => 0.0),
      (X => 2.0, Y => 1.0),
      (X => 1.0, Y => 1.0)];

   --  Overlapping square [0.5,1.5]×[0.5,1.5].
   Overlap_Square : constant Polygon :=
     [(X => 0.5, Y => 0.5),
      (X => 1.5, Y => 0.5),
      (X => 1.5, Y => 1.5),
      (X => 0.5, Y => 1.5)];

   --  Triangle.
   Tri : constant Polygon :=
     [(X => 0.0, Y => 0.0),
      (X => 2.0, Y => 0.0),
      (X => 1.0, Y => 2.0)];

   --  Non-convex arrow (should raise).
   Nonconvex : constant Polygon :=
     [(X => 0.0, Y => 0.0),
      (X => 2.0, Y => 1.0),
      (X => 0.0, Y => 2.0),
      (X => 0.5, Y => 1.0)];

begin
   Ada.Text_IO.Put_Line
     ("Gilbert_Johnson_Keerthi — educational GJK test suite");

   ---------------------------------------------------------------------------
   Section ("Numeric helpers");
   ---------------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near equal reals");
   Check (not Near (R (1.0), R (2.0)), "Near rejects distant reals");
   Check (Near_Point (P (1.0, 2.0), P (1.0, 2.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)),
          "Near_Point rejects distant");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)),
          "Dist2 (0,0)-(3,4) = 25");
   Check (Near (Dist (P (0.0, 0.0), P (3.0, 4.0)), R (5.0)),
          "Dist (0,0)-(3,4) = 5");
   Check (Near (Norm2 (P (3.0, 4.0)), R (25.0)), "Norm2 (3,4) = 25");
   Check (Near (Norm (P (3.0, 4.0)), R (5.0)), "Norm (3,4) = 5");
   Check (Near (Dot (P (1.0, 2.0), P (3.0, 4.0)), R (11.0)), "Dot");
   Check (Near (Cross (P (1.0, 0.0), P (0.0, 1.0)), R (1.0)), "Cross i×j");
   Check (Near_Point (Sub (P (5.0, 3.0), P (2.0, 1.0)), P (3.0, 2.0)),
          "Sub");
   Check (Near_Point (Add (P (1.0, 2.0), P (3.0, 4.0)), P (4.0, 6.0)),
          "Add");
   Check (Near_Point (Scale (P (2.0, 3.0), R (0.5)), P (1.0, 1.5)),
          "Scale");
   Check (Near_Point (Negate (P (1.0, -2.0)), P (-1.0, 2.0)), "Negate");
   Check (Near_Point (Perp (P (1.0, 0.0)), P (0.0, 1.0)), "Perp");
   Check (Near (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)),
                R (1.0)),
          "Orient2D CCW positive");
   Check (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, -1.0)) < 0.0,
          "Orient2D CW negative");

   ---------------------------------------------------------------------------
   Section ("Polygon validation");
   ---------------------------------------------------------------------------
   Check (Near (Signed_Area (Unit_Square), R (1.0)), "Signed_Area unit square");
   Check (Is_Convex (Unit_Square), "Unit square is convex");
   Check (Is_CCW (Unit_Square), "Unit square is CCW");
   Check (Is_Convex (Tri), "Triangle is convex");
   Check (not Is_Convex (Nonconvex), "Arrow is nonconvex");
   Check (Raised_Invalid_Ensure (Nonconvex),
          "Ensure_Convex_CCW rejects nonconvex");
   declare
      Empty : Polygon (1 .. 0);
      Tiny  : constant Polygon := [(X => 0.0, Y => 0.0), (X => 1.0, Y => 0.0)];
   begin
      Check (Raised_Invalid_Ensure (Empty), "Ensure rejects empty");
      Check (Raised_Invalid_Ensure (Tiny), "Ensure rejects 2-gon");
   end;
   declare
      CW : constant Polygon :=
        [(X => 0.0, Y => 0.0),
         (X => 0.0, Y => 1.0),
         (X => 1.0, Y => 1.0),
         (X => 1.0, Y => 0.0)];
      Normed : constant Polygon := Ensure_Convex_CCW (CW);
   begin
      Check (Is_CCW (Normed), "Ensure reverses CW square to CCW");
      Check (Normed'Length = 4, "Ensure preserves length");
   end;
   declare
      C : constant Point := Centroid (Unit_Square);
   begin
      Check (Near_Point (C, P (0.5, 0.5)), "Centroid of unit square");
   end;

   ---------------------------------------------------------------------------
   Section ("Support functions");
   ---------------------------------------------------------------------------
   declare
      S : Point;
   begin
      S := Support (Unit_Square, (X => 1.0, Y => 0.0));
      Check (Near_Point (S, P (1.0, 0.0)) or else Near_Point (S, P (1.0, 1.0)),
             "Support +X is right edge vertex");
      S := Support (Unit_Square, (X => -1.0, Y => 0.0));
      Check (Near_Point (S, P (0.0, 0.0)) or else Near_Point (S, P (0.0, 1.0)),
             "Support −X is left edge vertex");
      S := Support (Unit_Square, (X => 0.0, Y => 1.0));
      Check (Near_Point (S, P (0.0, 1.0)) or else Near_Point (S, P (1.0, 1.0)),
             "Support +Y is top edge vertex");
      S := Support (Unit_Square, (X => 1.0, Y => 1.0));
      Check (Near_Point (S, P (1.0, 1.0)), "Support +X+Y is (1,1)");
      S := Support (Unit_Square, (X => -1.0, Y => -1.0));
      Check (Near_Point (S, P (0.0, 0.0)), "Support −X−Y is (0,0)");
   end;
   declare
      Empty : Polygon (1 .. 0);
   begin
      Check (Raised_Invalid_Support (Empty), "Support rejects empty");
   end;
   declare
      M : Point;
   begin
      --  Support_Minkowski (Unit, Far, +X) = Support(Unit,+X) − Support(Far,−X)
      --  = (1,*) − (2,*) = negative X roughly.
      M := Support_Minkowski
        (Unit_Square, Far_Square, (X => 1.0, Y => 0.0));
      Check (M.X < 0.0, "Minkowski support +X has negative X (separated)");
      M := Support_Minkowski
        (Unit_Square, Unit_Square, (X => 1.0, Y => 0.0));
      --  A−A contains origin; support of difference along +X is right−left.
      Check (Near (M.X, R (1.0)), "Minkowski A−A support +X ≈ 1");
   end;

   ---------------------------------------------------------------------------
   Section ("Separated squares");
   ---------------------------------------------------------------------------
   declare
      D : Real;
      Info : Distance_Result;
   begin
      D := Distance (Unit_Square, Far_Square);
      --  Closest points: (1,1) and (2,2) → distance √2.
      Check (Near (D, Real (Math.Sqrt (2.0)), R (1.0E-5)),
             "Separated squares distance ≈ √2");
      Check (not Intersect (Unit_Square, Far_Square),
             "Separated squares do not intersect");
      Info := Distance_Info (Unit_Square, Far_Square);
      Check (not Info.Intersecting, "Distance_Info Intersecting=False");
      Check (Near (Info.Distance, D), "Distance_Info matches Distance");
      Check (Info.Iterations > 0, "Distance_Info iterations > 0");
      Check (Near (Distance_Squared (Unit_Square, Far_Square),
                   R (2.0), R (1.0E-4)),
             "Distance_Squared ≈ 2");
   end;

   --  Horizontally separated: [0,1]² and [3,4]×[0,1] → distance 2.
   declare
      Right : constant Polygon :=
        [(X => 3.0, Y => 0.0),
         (X => 4.0, Y => 0.0),
         (X => 4.0, Y => 1.0),
         (X => 3.0, Y => 1.0)];
      D : Real;
   begin
      D := Distance (Unit_Square, Right);
      Check (Near (D, R (2.0), R (1.0E-5)),
             "Horizontal gap of 2");
      Check (not Intersect (Unit_Square, Right),
             "Horizontal gap: no intersect");
   end;

   --  Vertically separated.
   declare
      Above : constant Polygon :=
        [(X => 0.0, Y => 4.0),
         (X => 1.0, Y => 4.0),
         (X => 1.0, Y => 5.0),
         (X => 0.0, Y => 5.0)];
      D : Real;
   begin
      D := Distance (Unit_Square, Above);
      Check (Near (D, R (3.0), R (1.0E-5)),
             "Vertical gap of 3");
      Check (not Intersect (Unit_Square, Above),
             "Vertical gap: no intersect");
   end;

   ---------------------------------------------------------------------------
   Section ("Overlapping / identical");
   ---------------------------------------------------------------------------
   Check (Intersect (Unit_Square, Overlap_Square),
          "Overlapping squares intersect");
   Check (Near (Distance (Unit_Square, Overlap_Square), R (0.0)),
          "Overlapping distance = 0");
   Check (Intersect (Unit_Square, Unit_Square),
          "Identical squares intersect");
   Check (Near (Distance (Unit_Square, Unit_Square), R (0.0)),
          "Identical distance = 0");
   declare
      Info : constant Distance_Result :=
        Distance_Info (Unit_Square, Overlap_Square);
   begin
      Check (Info.Intersecting, "Overlap Distance_Info Intersecting");
      Check (Near (Info.Distance, R (0.0)), "Overlap Distance_Info Dist=0");
   end;

   --  Contained: small square inside large.
   declare
      Big : constant Polygon :=
        Axis_Aligned_Square ((X => 0.0, Y => 0.0), 2.0);
      Small : constant Polygon :=
        Axis_Aligned_Square ((X => 0.0, Y => 0.0), 0.5);
   begin
      Check (Intersect (Big, Small), "Contained square intersects");
      Check (Near (Distance (Big, Small), R (0.0)),
             "Contained distance = 0");
   end;

   ---------------------------------------------------------------------------
   Section ("Touching");
   ---------------------------------------------------------------------------
   Check (Intersect (Unit_Square, Touch_Square),
          "Edge-touching squares intersect (closed)");
   Check (Near (Distance (Unit_Square, Touch_Square), R (0.0), R (1.0E-5)),
          "Edge-touching distance = 0");

   --  Corner touch: [0,1]² and [1,2]×[1,2] share corner (1,1).
   declare
      Corner : constant Polygon :=
        [(X => 1.0, Y => 1.0),
         (X => 2.0, Y => 1.0),
         (X => 2.0, Y => 2.0),
         (X => 1.0, Y => 2.0)];
   begin
      Check (Intersect (Unit_Square, Corner),
             "Corner-touching squares intersect");
      Check (Near (Distance (Unit_Square, Corner), R (0.0), R (1.0E-5)),
             "Corner-touching distance = 0");
   end;

   ---------------------------------------------------------------------------
   Section ("Axis_Aligned_Square helper");
   ---------------------------------------------------------------------------
   declare
      S : constant Polygon :=
        Axis_Aligned_Square ((X => 0.0, Y => 0.0), 1.0);
   begin
      Check (S'Length = 4, "Square has 4 vertices");
      Check (Is_Convex (S), "Helper square is convex");
      Check (Is_CCW (S), "Helper square is CCW");
      Check (Near (Signed_Area (S), R (4.0)), "Half_Side=1 → area 4");
   end;
   Check (Raised_Invalid_Square (R (0.0)), "Square rejects Half_Side=0");
   Check (Raised_Invalid_Square (R (-1.0)), "Square rejects negative");

   ---------------------------------------------------------------------------
   Section ("Circles as regular polygons");
   ---------------------------------------------------------------------------
   declare
      C1 : constant Polygon :=
        Regular_Polygon (16, 1.0, (X => 0.0, Y => 0.0));
      C2 : constant Polygon :=
        Regular_Polygon (16, 1.0, (X => 3.0, Y => 0.0));
      C3 : constant Polygon :=
        Regular_Polygon (16, 1.0, (X => 1.5, Y => 0.0));
      C4 : constant Polygon :=
        Regular_Polygon (16, 1.0, (X => 2.0, Y => 0.0));
      D  : Real;
   begin
      Check (C1'Length = 16, "Regular 16-gon length");
      Check (Is_Convex (C1), "Regular 16-gon convex");
      Check (Is_CCW (C1), "Regular 16-gon CCW");
      D := Distance (C1, C2);
      --  Centers 3 apart, radii 1+1 → gap ≈ 1 (polygon under-approximates).
      Check (D > R (0.5) and then D < R (1.2),
             "Two disks gap ≈ 1 (regular-16)");
      Check (not Intersect (C1, C2), "Distant disks do not intersect");
      Check (Intersect (C1, C3), "Overlapping disks intersect");
      Check (Near (Distance (C1, C3), R (0.0)),
             "Overlapping disks distance 0");
      --  Centers 2 apart, radii 1+1 → nearly touching.
      D := Distance (C1, C4);
      Check (D < R (0.15),
             "Nearly-touching disks distance small");
   end;

   declare
      Oct : constant Polygon := Regular_Polygon (8, 2.0);
   begin
      Check (Oct'Length = 8, "Regular octagon length");
      Check (Is_Convex (Oct), "Octagon convex");
   end;

   Check (Raised_Invalid_Regular (2, R (1.0)), "Regular rejects N=2");
   Check (Raised_Invalid_Regular (4, R (0.0)), "Regular rejects Radius=0");
   Check (Raised_Invalid_Regular (4, R (-1.0)), "Regular rejects neg radius");

   --  Higher-fidelity circle approximation.
   declare
      A : constant Polygon :=
        Regular_Polygon (32, 1.0, (X => 0.0, Y => 0.0));
      B : constant Polygon :=
        Regular_Polygon (32, 1.0, (X => 5.0, Y => 0.0));
      D : Real;
   begin
      Check (A'Length = 32, "Max-vertex regular polygon");
      D := Distance (A, B);
      Check (Near (D, R (3.0), R (0.05)),
             "32-gon disks gap ≈ 3");
      Check (not Intersect (A, B), "32-gon disks separated");
   end;

   ---------------------------------------------------------------------------
   Section ("Triangles and mixed shapes");
   ---------------------------------------------------------------------------
   declare
      T2 : constant Polygon :=
        [(X => 5.0, Y => 0.0),
         (X => 7.0, Y => 0.0),
         (X => 6.0, Y => 2.0)];
      D : Real;
   begin
      D := Distance (Tri, T2);
      Check (D > R (2.0), "Separated triangles positive distance");
      Check (not Intersect (Tri, T2), "Separated triangles no intersect");
   end;
   declare
      T_Overlap : constant Polygon :=
        [(X => 0.5, Y => 0.1),
         (X => 1.5, Y => 0.1),
         (X => 1.0, Y => 1.0)];
   begin
      Check (Intersect (Tri, T_Overlap), "Overlapping triangles");
      Check (Near (Distance (Tri, T_Overlap), R (0.0)),
             "Overlapping triangles distance 0");
   end;

   --  Square vs triangle.
   declare
      D : Real;
      Far_Tri : constant Polygon :=
        [(X => 10.0, Y => 10.0),
         (X => 12.0, Y => 10.0),
         (X => 11.0, Y => 12.0)];
   begin
      D := Distance (Unit_Square, Far_Tri);
      Check (D > R (10.0), "Square vs far triangle large distance");
      Check (not Intersect (Unit_Square, Far_Tri),
             "Square vs far triangle no intersect");
      Check (Intersect (Unit_Square, Tri),
             "Unit square overlaps triangle");
   end;

   ---------------------------------------------------------------------------
   Section ("Symmetry / commutativity");
   ---------------------------------------------------------------------------
   declare
      D1 : constant Real := Distance (Unit_Square, Far_Square);
      D2 : constant Real := Distance (Far_Square, Unit_Square);
   begin
      Check (Near (D1, D2), "Distance (A,B) = Distance (B,A)");
   end;
   Check (Intersect (Overlap_Square, Unit_Square)
            = Intersect (Unit_Square, Overlap_Square),
          "Intersect commutative");

   ---------------------------------------------------------------------------
   Section ("Invalid arguments");
   ---------------------------------------------------------------------------
   declare
      Empty : Polygon (1 .. 0);
      Tiny  : constant Polygon := [(X => 0.0, Y => 0.0), (X => 1.0, Y => 0.0)];
   begin
      Check (Raised_Invalid_Distance (Empty, Unit_Square),
             "Distance rejects empty A");
      Check (Raised_Invalid_Distance (Unit_Square, Empty),
             "Distance rejects empty B");
      Check (Raised_Invalid_Distance (Tiny, Unit_Square),
             "Distance rejects 2-gon");
      Check (Raised_Invalid_Distance (Nonconvex, Unit_Square),
             "Distance rejects nonconvex");
      Check (Raised_Invalid_Intersect (Nonconvex, Unit_Square),
             "Intersect rejects nonconvex");
      Check (Raised_Invalid_Intersect (Empty, Unit_Square),
             "Intersect rejects empty");
   end;

   ---------------------------------------------------------------------------
   Section ("Translated copies");
   ---------------------------------------------------------------------------
   declare
      S0 : constant Polygon :=
        Axis_Aligned_Square ((X => 0.0, Y => 0.0), 0.5);
      S1 : constant Polygon :=
        Axis_Aligned_Square ((X => 2.0, Y => 0.0), 0.5);
      S2 : constant Polygon :=
        Axis_Aligned_Square ((X => 0.0, Y => 3.0), 0.5);
      D  : Real;
   begin
      D := Distance (S0, S1);
      Check (Near (D, R (1.0), R (1.0E-5)),
             "Translated squares gap 1 (horizontal)");
      D := Distance (S0, S2);
      Check (Near (D, R (2.0), R (1.0E-5)),
             "Translated squares gap 2 (vertical)");
   end;

   ---------------------------------------------------------------------------
   Section ("Degenerate-ish / thin shapes");
   ---------------------------------------------------------------------------
   declare
      Thin : constant Polygon :=
        [(X => 0.0, Y => 0.0),
         (X => 10.0, Y => 0.0),
         (X => 10.0, Y => 0.1),
         (X => 0.0, Y => 0.1)];
      Above : constant Polygon :=
        [(X => 0.0, Y => 1.0),
         (X => 10.0, Y => 1.0),
         (X => 10.0, Y => 1.1),
         (X => 0.0, Y => 1.1)];
      D : Real;
   begin
      Check (Is_Convex (Thin), "Thin rectangle convex");
      D := Distance (Thin, Above);
      Check (Near (D, R (0.9), R (1.0E-4)),
             "Thin rectangles gap 0.9");
      Check (not Intersect (Thin, Above), "Thin rectangles separated");
   end;

   ---------------------------------------------------------------------------
   Section ("Self-distance / point-like via tiny square");
   ---------------------------------------------------------------------------
   declare
      Tiny_A : constant Polygon :=
        Axis_Aligned_Square ((X => 1.0, Y => 1.0), 0.01);
      Tiny_B : constant Polygon :=
        Axis_Aligned_Square ((X => 4.0, Y => 5.0), 0.01);
      D : Real;
   begin
      D := Distance (Tiny_A, Tiny_B);
      --  Centers (1,1) and (4,5) → ‖(3,4)‖ = 5, minus ~0.02√2.
      Check (D > R (4.9) and then D < R (5.1),
             "Tiny squares ≈ point distance 5");
   end;

   ---------------------------------------------------------------------------
   Section ("Max_Vertices capacity");
   ---------------------------------------------------------------------------
   declare
      Big  : constant Polygon := Regular_Polygon (Max_Vertices, 1.0);
      Far  : constant Polygon :=
        Regular_Polygon (Max_Vertices, 1.0, (X => 10.0, Y => 0.0));
      D    : Real;
      Info : Distance_Result;
   begin
      Check (Big'Length = Max_Vertices, "Can build Max_Vertices gon");
      Check (Is_Convex (Big), "Max_Vertices gon convex");
      Check (Intersect (Big, Big), "Max gon self-intersects");
      D := Distance (Big, Far);
      Check (D > R (7.0) and then D < R (9.0),
             "Max-vertex disks gap ≈ 8");
      Check (not Intersect (Big, Far), "Max-vertex disks separated");
      Info := Distance_Info (Big, Far);
      Check (Info.Iterations <= Max_Iterations,
             "GJK iterations within Max_Iterations");
   end;

   ---------------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:"
      & Natural'Image (Pass_Count)
      & " PASS,"
      & Natural'Image (Fail_Count)
      & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
