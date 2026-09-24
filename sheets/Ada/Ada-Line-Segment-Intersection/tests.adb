--  Standalone test suite for Line_Segment_Intersection (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Line_Segment_Intersection; use Line_Segment_Intersection;

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
   function S (Ax, Ay, Bx, By : Real) return Segment is
     (Make_Segment (Ax, Ay, Bx, By));

   function Raised_Invalid_Classify (A, B : Segment) return Boolean is
      K : Intersection_Kind;
   begin
      K := Classify_Intersection (A, B);
      pragma Unreferenced (K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Classify;

   function Raised_Invalid_Point (A, B : Segment) return Boolean is
      Q : Point;
   begin
      Q := Intersection_Point (A, B);
      pragma Unreferenced (Q);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Point;

   function Raised_Invalid_Brute (Segs : Segment_Set) return Boolean is
      L : Intersection_List;
   begin
      L := Brute_Force_Find_All (Segs);
      pragma Unreferenced (L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Brute;

   function Raised_Invalid_Find (Segs : Segment_Set) return Boolean is
      L : Intersection_List;
   begin
      L := Find_All (Segs);
      pragma Unreferenced (L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Find;

   function Raised_Invalid_Overlap (A, B : Segment) return Boolean is
      Q : Point;
   begin
      Q := Overlap_Representative (A, B);
      pragma Unreferenced (Q);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Overlap;

   function Empty_Set return Segment_Set is
      Z : Segment_Array (1 .. 0);
   begin
      return Z;
   end Empty_Set;

   function Too_Many return Segment_Set is
      Z : Segment_Array (1 .. Max_Segments + 1);
   begin
      for I in Z'Range loop
         Z (I) := S (Real (I), 0.0, Real (I), 1.0);
      end loop;
      return Z;
   end Too_Many;

   function Contains_Pair
     (L : Intersection_List; I, J : Segment_Index) return Boolean
   is
      Lo : constant Segment_Index := (if I < J then I else J);
      Hi : constant Segment_Index := (if I < J then J else I);
   begin
      for K in 1 .. L.Count loop
         if L.Items (K).Seg_I = Lo and then L.Items (K).Seg_J = Hi then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Pair;

   function Proper_Matches_Brute (Segs : Segment_Set) return Boolean is
      A : constant Intersection_List := Find_All (Segs);
      B : constant Intersection_List :=
        Filter_By_Kind (Brute_Force_Find_All (Segs), Proper);
   begin
      return Same_Intersection_Set (A, B);
   end Proper_Matches_Brute;

begin
   Ada.Text_IO.Put_Line ("Line_Segment_Intersection tests");
   Ada.Text_IO.Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("Helpers: Near / Orient2D / On_Segment / Dist2");
   ---------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near equal reals");
   Check (not Near (R (1.0), R (2.0)), "Near distinct reals");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "Near_Point distinct");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)),
          "Dist2 3-4-5");
   Check (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)) > 0.0,
          "Orient2D left turn positive");
   Check (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, -1.0)) < 0.0,
          "Orient2D right turn negative");
   Check (Near (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)), R (0.0)),
          "Orient2D collinear ~0");
   Check (On_Segment (P (0.5, 0.0), S (0.0, 0.0, 1.0, 0.0)),
          "On_Segment interior of horizontal");
   Check (On_Segment (P (0.0, 0.0), S (0.0, 0.0, 1.0, 0.0)),
          "On_Segment endpoint");
   Check (not On_Segment (P (1.5, 0.0), S (0.0, 0.0, 1.0, 0.0)),
          "On_Segment beyond endpoint");
   Check (not On_Segment (P (0.5, 0.1), S (0.0, 0.0, 1.0, 0.0)),
          "On_Segment off the line");
   Check (On_Segment (P (0.5, 0.5), S (0.0, 0.0, 1.0, 1.0)),
          "On_Segment diagonal mid");
   Check (Is_Degenerate (S (1.0, 1.0, 1.0, 1.0)), "Is_Degenerate true");
   Check (not Is_Degenerate (S (0.0, 0.0, 1.0, 0.0)), "Is_Degenerate false");

   ---------------------------------------------------------------------
   Section ("Crossing — Proper");
   ---------------------------------------------------------------------
   declare
      A : constant Segment := S (0.0, 0.0, 2.0, 2.0);
      B : constant Segment := S (0.0, 2.0, 2.0, 0.0);
      Q : Point;
   begin
      Check (Classify_Intersection (A, B) = Proper, "X-cross Proper");
      Check (Segments_Intersect (A, B), "X-cross Segments_Intersect");
      Check (Has_Unique_Intersection_Point (A, B), "X-cross unique");
      Q := Intersection_Point (A, B);
      Check (Near_Point (Q, P (1.0, 1.0)), "X-cross point (1,1)");
   end;
   declare
      A : constant Segment := S (0.0, 1.0, 4.0, 1.0);
      B : constant Segment := S (2.0, 0.0, 2.0, 3.0);
      Q : Point;
   begin
      Check (Classify_Intersection (A, B) = Proper, "axis + Proper");
      Q := Intersection_Point (A, B);
      Check (Near_Point (Q, P (2.0, 1.0)), "axis + point (2,1)");
   end;
   declare
      A : constant Segment := S (-1.0, 0.0, 1.0, 0.0);
      B : constant Segment := S (0.0, -1.0, 0.0, 1.0);
   begin
      Check (Classify_Intersection (A, B) = Proper, "unit + Proper");
      Check (Near_Point (Intersection_Point (A, B), P (0.0, 0.0)),
             "unit + at origin");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 1.0);
      B : constant Segment := S (0.0, 1.0, 1.0, 2.0);
   begin
      Check (Classify_Intersection (A, B) = None, "parallel diagonal None");
      Check (not Segments_Intersect (A, B), "parallel diagonal no intersect");
   end;

   ---------------------------------------------------------------------
   Section ("T-junction — Improper");
   ---------------------------------------------------------------------
   declare
      --  Vertical stem meets horizontal bar mid-edge.
      Stem : constant Segment := S (1.0, 0.0, 1.0, 1.0);
      Bar  : constant Segment := S (0.0, 1.0, 2.0, 1.0);
      Q    : Point;
   begin
      Check (Classify_Intersection (Stem, Bar) = Improper,
             "T-junction Improper");
      Check (Segments_Intersect (Stem, Bar), "T-junction intersects");
      Check (Has_Unique_Intersection_Point (Stem, Bar), "T-junction unique");
      Q := Intersection_Point (Stem, Bar);
      Check (Near_Point (Q, P (1.0, 1.0)), "T-junction at (1,1)");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 2.0, 0.0);
      B : constant Segment := S (1.0, 0.0, 1.0, 2.0);
   begin
      Check (Classify_Intersection (A, B) = Improper,
             "endpoint on interior Improper");
      Check (Near_Point (Intersection_Point (A, B), P (1.0, 0.0)),
             "endpoint-on-interior point");
   end;

   ---------------------------------------------------------------------
   Section ("Endpoint touch — Improper");
   ---------------------------------------------------------------------
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 0.0);
      B : constant Segment := S (1.0, 0.0, 2.0, 1.0);
   begin
      Check (Classify_Intersection (A, B) = Improper,
             "shared endpoint Improper");
      Check (Segments_Intersect (A, B), "shared endpoint intersects");
      Check (Near_Point (Intersection_Point (A, B), P (1.0, 0.0)),
             "shared endpoint at (1,0)");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 1.0);
      B : constant Segment := S (1.0, 1.0, 2.0, 0.0);
   begin
      Check (Classify_Intersection (A, B) = Improper,
             "shared corner Improper");
      Check (Near_Point (Intersection_Point (A, B), P (1.0, 1.0)),
             "shared corner at (1,1)");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 0.0);
      B : constant Segment := S (1.0, 0.0, 2.0, 0.0);
   begin
      --  Collinear, touch at single endpoint → Improper (not overlap).
      Check (Classify_Intersection (A, B) = Improper,
             "collinear endpoint touch Improper");
   end;

   ---------------------------------------------------------------------
   Section ("Parallel disjoint — None");
   ---------------------------------------------------------------------
   declare
      A : constant Segment := S (0.0, 0.0, 2.0, 0.0);
      B : constant Segment := S (0.0, 1.0, 2.0, 1.0);
   begin
      Check (Classify_Intersection (A, B) = None, "parallel horizontal None");
      Check (not Segments_Intersect (A, B), "parallel horizontal no hit");
      Check (Raised_Invalid_Point (A, B),
             "Intersection_Point raises on parallel miss");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 0.0, 2.0);
      B : constant Segment := S (1.0, 0.0, 1.0, 2.0);
   begin
      Check (Classify_Intersection (A, B) = None, "parallel vertical None");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 0.0);
      B : constant Segment := S (2.0, 0.0, 3.0, 0.0);
   begin
      Check (Classify_Intersection (A, B) = None,
             "collinear disjoint None");
      Check (not Segments_Intersect (A, B), "collinear disjoint no hit");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 1.0);
      B : constant Segment := S (2.0, 0.0, 3.0, 1.0);
   begin
      Check (Classify_Intersection (A, B) = None, "skew miss None");
   end;

   ---------------------------------------------------------------------
   Section ("Collinear overlap");
   ---------------------------------------------------------------------
   declare
      A : constant Segment := S (0.0, 0.0, 3.0, 0.0);
      B : constant Segment := S (1.0, 0.0, 2.0, 0.0);
      Q : Point;
   begin
      Check (Classify_Intersection (A, B) = Collinear_Overlap,
             "nested collinear Collinear_Overlap");
      Check (Segments_Intersect (A, B), "nested collinear intersects");
      Check (not Has_Unique_Intersection_Point (A, B),
             "nested collinear not unique");
      Check (Raised_Invalid_Point (A, B),
             "Intersection_Point raises on overlap");
      Q := Overlap_Representative (A, B);
      Check (Near_Point (Q, P (1.5, 0.0)), "overlap mid ~ (1.5,0)");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 2.0, 0.0);
      B : constant Segment := S (1.0, 0.0, 3.0, 0.0);
   begin
      Check (Classify_Intersection (A, B) = Collinear_Overlap,
             "partial collinear overlap");
      Check (Near_Point (Overlap_Representative (A, B), P (1.5, 0.0)),
             "partial overlap mid");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 1.0);
      B : constant Segment := S (0.5, 0.5, 1.5, 1.5);
   begin
      Check (Classify_Intersection (A, B) = Collinear_Overlap,
             "diagonal collinear overlap");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 0.0);
      B : constant Segment := S (0.0, 1.0, 1.0, 1.0);
   begin
      Check (Raised_Invalid_Overlap (A, B),
             "Overlap_Representative raises on non-overlap");
   end;

   ---------------------------------------------------------------------
   Section ("Degenerate / Invalid_Argument");
   ---------------------------------------------------------------------
   declare
      Deg : constant Segment := S (1.0, 1.0, 1.0, 1.0);
      Ok  : constant Segment := S (0.0, 0.0, 1.0, 0.0);
   begin
      Check (Raised_Invalid_Classify (Deg, Ok),
             "Classify raises on degenerate");
      Check (Raised_Invalid_Classify (Ok, Deg),
             "Classify raises on degenerate other");
      Check (Raised_Invalid_Point (Deg, Ok),
             "Intersection_Point raises on degenerate");
   end;
   Check (Raised_Invalid_Brute (Empty_Set), "Brute raises on empty");
   Check (Raised_Invalid_Find (Empty_Set), "Find_All raises on empty");
   Check (Raised_Invalid_Brute (Too_Many), "Brute raises on too many");
   Check (Raised_Invalid_Find (Too_Many), "Find_All raises on too many");
   declare
      One : constant Segment_Array := [S (0.0, 0.0, 1.0, 0.0)];
      L   : Intersection_List;
   begin
      L := Brute_Force_Find_All (One);
      Check (L.Count = 0, "single segment brute count 0");
      L := Find_All (One);
      Check (L.Count = 0, "single segment Find_All count 0");
   end;

   ---------------------------------------------------------------------
   Section ("Brute_Force_Find_All multi-segment");
   ---------------------------------------------------------------------
   declare
      Segs : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 2.0),   -- 1
         S (0.0, 2.0, 2.0, 0.0),   -- 2  crosses 1 Proper
         S (3.0, 0.0, 4.0, 0.0),   -- 3  isolated
         S (0.0, 3.0, 2.0, 3.0)];  -- 4  parallel above
      L : Intersection_List;
   begin
      L := Brute_Force_Find_All (Segs);
      Check (L.Count = 1, "brute four segs: one hit");
      Check (Contains_Pair (L, 1, 2), "brute reports pair 1-2");
      Check (L.Items (1).Kind = Proper, "brute kind Proper");
      Check (Near_Point (L.Items (1).Location, P (1.0, 1.0)),
             "brute location (1,1)");
   end;
   declare
      Segs : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 0.0),
         S (1.0, 0.0, 1.0, 1.0),   -- T on first
         S (2.0, 0.0, 3.0, 0.0)];  -- endpoint touch with first
      L : Intersection_List;
   begin
      L := Brute_Force_Find_All (Segs);
      Check (L.Count = 2, "brute T+touch: two hits");
      Check (Contains_Pair (L, 1, 2), "brute has 1-2 T");
      Check (Contains_Pair (L, 1, 3), "brute has 1-3 touch");
   end;
   declare
      Segs : constant Segment_Array :=
        [S (0.0, 0.0, 3.0, 0.0),
         S (1.0, 0.0, 2.0, 0.0)];
      L : Intersection_List;
   begin
      L := Brute_Force_Find_All (Segs);
      Check (L.Count = 1, "brute overlap count 1");
      Check (L.Items (1).Kind = Collinear_Overlap, "brute overlap kind");
   end;

   ---------------------------------------------------------------------
   Section ("Find_All Proper sweep vs brute Proper");
   ---------------------------------------------------------------------
   declare
      Segs : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 2.0),
         S (0.0, 2.0, 2.0, 0.0)];
      L : Intersection_List;
   begin
      L := Find_All (Segs);
      Check (L.Count = 1, "Find_All X-cross count 1");
      Check (L.Items (1).Kind = Proper, "Find_All kind Proper");
      Check (Near_Point (L.Items (1).Location, P (1.0, 1.0)),
             "Find_All location");
      Check (Intersection_Count_Of (Segs) = 1, "Intersection_Count_Of 1");
      Check (Proper_Matches_Brute (Segs), "Find_All matches brute Proper");
   end;
   declare
      Segs : constant Segment_Array :=
        [S (0.0, 0.0, 1.0, 1.0),
         S (0.0, 1.0, 1.0, 0.0),
         S (0.5, -1.0, 0.5, 2.0)];
      L : Intersection_List;
   begin
      L := Find_All (Segs);
      Check (L.Count = 3, "Find_All triple-cross count 3");
      Check (Proper_Matches_Brute (Segs), "triple matches brute Proper");
   end;
   declare
      --  Improper-only set: Find_All should report nothing.
      Segs : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 0.0),
         S (1.0, 0.0, 1.0, 1.0)];
      L : Intersection_List;
   begin
      L := Find_All (Segs);
      Check (L.Count = 0, "Find_All ignores T-junction");
      Check (Brute_Force_Find_All (Segs).Count = 1,
             "brute still sees T-junction");
      Check (Proper_Matches_Brute (Segs), "T-only Proper match (empty)");
   end;
   declare
      Segs : constant Segment_Array :=
        [S (0.0, 0.0, 1.0, 0.0),
         S (0.0, 1.0, 1.0, 1.0),
         S (0.0, 2.0, 1.0, 2.0)];
   begin
      Check (Find_All (Segs).Count = 0, "Find_All parallel none");
      Check (Brute_Force_Find_All (Segs).Count = 0, "brute parallel none");
      Check (Proper_Matches_Brute (Segs), "parallel Proper match");
   end;
   declare
      Segs : constant Segment_Array :=
        [S (0.0, 1.0, 4.0, 1.0),
         S (1.0, 0.0, 1.0, 3.0),
         S (2.0, 0.0, 2.0, 3.0),
         S (3.0, 0.0, 3.0, 3.0)];
   begin
      Check (Find_All (Segs).Count = 3, "comb Find_All 3");
      Check (Proper_Matches_Brute (Segs), "comb matches brute");
   end;

   ---------------------------------------------------------------------
   Section ("Filter_By_Kind / Same_Intersection_Set / constructors");
   ---------------------------------------------------------------------
   declare
      --  Disjoint-role segments so kinds do not interfere:
      --  1-2 Proper X-cross; 3-4 Improper T-junction; 5-6 Collinear_Overlap.
      Segs : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 2.0),
         S (0.0, 2.0, 2.0, 0.0),
         S (10.0, 0.0, 12.0, 0.0),
         S (11.0, 0.0, 11.0, 1.0),
         S (20.0, 0.0, 23.0, 0.0),
         S (21.0, 0.0, 22.0, 0.0)];
      All_L : constant Intersection_List := Brute_Force_Find_All (Segs);
      Prop  : constant Intersection_List := Filter_By_Kind (All_L, Proper);
      Over  : constant Intersection_List :=
        Filter_By_Kind (All_L, Collinear_Overlap);
      Imp   : constant Intersection_List := Filter_By_Kind (All_L, Improper);
   begin
      Check (All_L.Count = 3, "mixed brute count 3");
      Check (Prop.Count = 1, "filter Proper count 1");
      Check (Over.Count = 1, "filter Overlap count 1");
      Check (Imp.Count = 1, "filter Improper count 1");
      Check (Same_Intersection_Set (Prop, Prop), "Same set reflexive");
      Check (not Same_Intersection_Set (Prop, Over), "Same set distinct");
   end;
   Check (Empty_Intersection_List.Count = 0, "Empty_Intersection_List");
   Check (Near_Point (Make_Point (2.0, 3.0), P (2.0, 3.0)), "Make_Point");
   declare
      Seg : constant Segment := Make_Segment (0.0, 0.0, 1.0, 1.0);
   begin
      Check (Near_Point (Seg.A, P (0.0, 0.0)), "Make_Segment A");
      Check (Near_Point (Seg.B, P (1.0, 1.0)), "Make_Segment B");
   end;

   ---------------------------------------------------------------------
   Section ("Additional Proper / None classroom cases");
   ---------------------------------------------------------------------
   declare
      A : constant Segment := S (0.0, 0.0, 10.0, 0.0);
      B : constant Segment := S (5.0, -1.0, 5.0, 1.0);
   begin
      Check (Classify_Intersection (A, B) = Proper, "long bar cross Proper");
      Check (Near_Point (Intersection_Point (A, B), P (5.0, 0.0)),
             "long bar at (5,0)");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 0.0);
      B : constant Segment := S (0.0, 0.0, 0.0, 1.0);
   begin
      Check (Classify_Intersection (A, B) = Improper,
             "L-shape shared origin Improper");
   end;
   declare
      A : constant Segment := S (1.0, 1.0, 2.0, 2.0);
      B : constant Segment := S (3.0, 0.0, 4.0, 1.0);
   begin
      Check (Classify_Intersection (A, B) = None, "far apart None");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 0.0, 2.0);
      B : constant Segment := S (-1.0, 1.0, 1.0, 1.0);
   begin
      Check (Classify_Intersection (A, B) = Proper, "vertical-horizontal Proper");
      Check (Near_Point (Intersection_Point (A, B), P (0.0, 1.0)),
             "vh at (0,1)");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 2.0, 2.0);
      B : constant Segment := S (1.0, 1.0, 3.0, 3.0);
   begin
      Check (Classify_Intersection (A, B) = Collinear_Overlap,
             "partial diagonal overlap");
   end;
   declare
      A : constant Segment := S (0.0, 0.0, 1.0, 0.0);
      B : constant Segment := S (0.5, 0.0, 0.5, 0.0);
   begin
      Check (Raised_Invalid_Classify (A, B),
             "degenerate partner raises");
   end;

   ---------------------------------------------------------------------
   Section ("Larger Find_All stress (n=8 grid)");
   ---------------------------------------------------------------------
   declare
      Segs : Segment_Array (1 .. 8);
      L    : Intersection_List;
   begin
      --  4 horizontal + 4 vertical → 16 Proper crossings.
      for I in 1 .. 4 loop
         Segs (I) := S (0.0, Real (I), 5.0, Real (I));
         Segs (4 + I) := S (Real (I), 0.0, Real (I), 5.0);
      end loop;
      L := Find_All (Segs);
      Check (L.Count = 16, "grid 4x4 Find_All count 16");
      Check (Brute_Force_Find_All (Segs).Count = 16,
             "grid 4x4 brute count 16");
      Check (Proper_Matches_Brute (Segs), "grid matches brute Proper");
      Check (Intersection_Count_Of (Segs) = 16, "grid Intersection_Count_Of");
   end;

   ---------------------------------------------------------------------
   Section ("Symmetric Classify");
   ---------------------------------------------------------------------
   declare
      A : constant Segment := S (0.0, 0.0, 2.0, 2.0);
      B : constant Segment := S (0.0, 2.0, 2.0, 0.0);
      C : constant Segment := S (0.0, 0.0, 2.0, 0.0);
      D : constant Segment := S (1.0, 0.0, 1.0, 1.0);
      E : constant Segment := S (0.0, 0.0, 3.0, 0.0);
      F : constant Segment := S (1.0, 0.0, 2.0, 0.0);
   begin
      Check (Classify_Intersection (A, B) = Classify_Intersection (B, A),
             "Proper symmetric");
      Check (Classify_Intersection (C, D) = Classify_Intersection (D, C),
             "Improper symmetric");
      Check (Classify_Intersection (E, F) = Classify_Intersection (F, E),
             "Overlap symmetric");
      Check (Near_Point (Intersection_Point (A, B), Intersection_Point (B, A)),
             "Intersection_Point symmetric");
   end;

   ---------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
