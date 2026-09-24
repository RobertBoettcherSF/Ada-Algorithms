--  Standalone test suite for Bentley_Ottmann (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Bentley_Ottmann; use Bentley_Ottmann;

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

   function Raised_Invalid_Find (Segs : Segment_Set) return Boolean is
      L : Intersection_List;
   begin
      L := Find_Intersections (Segs);
      pragma Unreferenced (L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Find;

   function Raised_Invalid_Any (Segs : Segment_Set) return Boolean is
      B : Boolean;
   begin
      B := Any_Intersection (Segs);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Any;

   function Raised_Invalid_Brute (Segs : Segment_Set) return Boolean is
      L : Intersection_List;
   begin
      L := Brute_Force_Intersections (Segs);
      pragma Unreferenced (L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Brute;

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

   function Matches_Brute (Segs : Segment_Set) return Boolean is
      A : constant Intersection_List := Find_Intersections (Segs);
      B : constant Intersection_List := Brute_Force_Intersections (Segs);
   begin
      return Same_Intersection_Set (A, B);
   end Matches_Brute;

begin
   Ada.Text_IO.Put_Line ("Bentley_Ottmann tests");
   Ada.Text_IO.Put_Line ("=====================");

   ---------------------------------------------------------------------
   Section ("Helpers: Near / Orient2D / Left_Of / Right_Of");
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
   declare
      Seg : constant Segment := S (2.0, 3.0, 0.0, 1.0);
      L   : constant Point := Left_Of (Seg);
      Rt  : constant Point := Right_Of (Seg);
   begin
      Check (Near_Point (L, P (0.0, 1.0)), "Left_Of picks smaller X");
      Check (Near_Point (Rt, P (2.0, 3.0)), "Right_Of picks larger X");
   end;
   Check (Near (Y_At_X (S (0.0, 0.0, 2.0, 2.0), R (1.0)), R (1.0)),
          "Y_At_X diagonal at mid");
   Check (Near (Y_At_X (S (0.0, 5.0, 10.0, 5.0), R (3.0)), R (5.0)),
          "Y_At_X horizontal");

   ---------------------------------------------------------------------
   Section ("Event_Before ordering");
   ---------------------------------------------------------------------
   declare
      E1 : constant Event :=
        (Kind => Left_Endpoint, Loc => P (0.0, 0.0), Seg_A => 1, Seg_B => 1);
      E2 : constant Event :=
        (Kind => Left_Endpoint, Loc => P (1.0, 0.0), Seg_A => 1, Seg_B => 1);
      E3 : constant Event :=
        (Kind => Crossing, Loc => P (0.0, 0.0), Seg_A => 1, Seg_B => 2);
      E4 : constant Event :=
        (Kind => Right_Endpoint, Loc => P (0.0, 0.0), Seg_A => 1, Seg_B => 1);
   begin
      Check (Event_Before (E1, E2), "Event_Before by X");
      Check (not Event_Before (E1 => E2, E2 => E1), "Event_Before X asymmetric");
      Check (Event_Before (E1, E3), "Left before Crossing at same point");
      Check (Event_Before (E3, E4), "Crossing before Right at same point");
   end;

   ---------------------------------------------------------------------
   Section ("Proper intersection predicate");
   ---------------------------------------------------------------------
   Check (Segments_Properly_Intersect
            (S (0.0, 0.0, 2.0, 2.0), S (0.0, 2.0, 2.0, 0.0)),
          "X-crossing proper");
   Check (not Segments_Properly_Intersect
            (S (0.0, 0.0, 1.0, 0.0), S (2.0, 0.0, 3.0, 0.0)),
          "disjoint collinear not proper");
   Check (not Segments_Properly_Intersect
            (S (0.0, 0.0, 2.0, 0.0), S (1.0, 0.0, 3.0, 0.0)),
          "overlapping collinear not proper (limited)");
   Check (not Segments_Properly_Intersect
            (S (0.0, 0.0, 1.0, 1.0), S (1.0, 1.0, 2.0, 0.0)),
          "shared endpoint not proper");
   Check (not Segments_Properly_Intersect
            (S (0.0, 0.0, 1.0, 0.0), S (0.0, 1.0, 1.0, 1.0)),
          "parallel disjoint not proper");
   Check (not Segments_Properly_Intersect
            (S (0.0, 0.0, 2.0, 0.0), S (1.0, -1.0, 1.0, 0.0)),
          "T-junction at endpoint not proper");
   declare
      IP : constant Point :=
        Intersection_Point
          (S (0.0, 0.0, 2.0, 2.0), S (0.0, 2.0, 2.0, 0.0));
   begin
      Check (Near_Point (IP, P (1.0, 1.0)), "Intersection_Point at (1,1)");
   end;

   ---------------------------------------------------------------------
   Section ("Invalid_Argument: empty / oversized");
   ---------------------------------------------------------------------
   Check (Raised_Invalid_Find (Empty_Set), "Find empty raises");
   Check (Raised_Invalid_Any (Empty_Set), "Any empty raises");
   Check (Raised_Invalid_Brute (Empty_Set), "Brute empty raises");
   Check (Raised_Invalid_Find (Too_Many), "Find oversized raises");
   Check (Raised_Invalid_Any (Too_Many), "Any oversized raises");
   Check (Raised_Invalid_Brute (Too_Many), "Brute oversized raises");

   ---------------------------------------------------------------------
   Section ("Single segment / disjoint pairs");
   ---------------------------------------------------------------------
   declare
      One : constant Segment_Array := [S (0.0, 0.0, 1.0, 1.0)];
      L   : Intersection_List;
   begin
      L := Find_Intersections (One);
      Check (L.Count = 0, "single segment → 0 intersections");
      Check (not Any_Intersection (One), "single segment → Any False");
      Check (Matches_Brute (One), "single matches brute");
   end;
   declare
      Two : constant Segment_Array :=
        [S (0.0, 0.0, 1.0, 0.0), S (0.0, 1.0, 1.0, 1.0)];
      L   : Intersection_List;
   begin
      L := Find_Intersections (Two);
      Check (L.Count = 0, "parallel horizontal → 0");
      Check (not Any_Intersection (Two), "parallel → Any False");
      Check (Matches_Brute (Two), "parallel matches brute");
   end;
   declare
      Dis : constant Segment_Array :=
        [S (0.0, 0.0, 1.0, 1.0), S (3.0, 0.0, 4.0, 1.0)];
   begin
      Check (Intersection_Count_Of (Dis) = 0, "far apart → count 0");
      Check (not Any_Intersection (Dis), "far apart → Any False");
      Check (Matches_Brute (Dis), "far apart matches brute");
   end;

   ---------------------------------------------------------------------
   Section ("Classic X crossing");
   ---------------------------------------------------------------------
   declare
      Cross : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 2.0), S (0.0, 2.0, 2.0, 0.0)];
      L : Intersection_List;
   begin
      L := Find_Intersections (Cross);
      Check (L.Count = 1, "X-cross count 1");
      Check (Any_Intersection (Cross), "X-cross Any True");
      Check (Contains_Pair (L, 1, 2), "X-cross pair (1,2)");
      Check (Near_Point (L.Items (1).Location, P (1.0, 1.0)),
             "X-cross at (1,1)");
      Check (Matches_Brute (Cross), "X-cross matches brute");
      Check (Intersection_Count_Of (Cross) = 1, "X-cross Count_Of");
   end;

   ---------------------------------------------------------------------
   Section ("Axis-aligned + / disjoint axis-aligned");
   ---------------------------------------------------------------------
   declare
      Plus : constant Segment_Array :=
        [S (-1.0, 0.0, 1.0, 0.0), S (0.0, -1.0, 0.0, 1.0)];
      L : Intersection_List;
   begin
      L := Find_Intersections (Plus);
      Check (L.Count = 1, "+ cross count 1");
      Check (Near_Point (L.Items (1).Location, P (0.0, 0.0)),
             "+ cross at origin");
      Check (Matches_Brute (Plus), "+ matches brute");
   end;
   declare
      No : constant Segment_Array :=
        [S (0.0, 0.0, 1.0, 0.0), S (2.0, -1.0, 2.0, 1.0)];
   begin
      Check (Intersection_Count_Of (No) = 0, "vertical miss → 0");
      Check (Matches_Brute (No), "vertical miss matches brute");
   end;

   ---------------------------------------------------------------------
   Section ("Multiple crossings");
   ---------------------------------------------------------------------
   declare
      --  Three segments: two diagonals of a square + one horizontal mid.
      --  Diagonals cross once; horizontal crosses both diagonals ⇒ 3.
      Tri : constant Segment_Array :=
        [S (0.0, 0.0, 4.0, 4.0),
         S (0.0, 4.0, 4.0, 0.0),
         S (0.0, 2.0, 4.0, 2.0)];
      L : Intersection_List;
   begin
      L := Find_Intersections (Tri);
      Check (L.Count = 3, "triangle-ish 3 crossings");
      Check (Any_Intersection (Tri), "triangle-ish Any True");
      Check (Contains_Pair (L, 1, 2), "has pair 1-2");
      Check (Contains_Pair (L, 1, 3), "has pair 1-3");
      Check (Contains_Pair (L, 2, 3), "has pair 2-3");
      Check (Matches_Brute (Tri), "triangle-ish matches brute");
   end;

   declare
      --  Four sides of a square: adjacent sides share endpoints only ⇒ 0
      --  proper intersections.
      Sq : constant Segment_Array :=
        [S (0.0, 0.0, 1.0, 0.0),
         S (1.0, 0.0, 1.0, 1.0),
         S (1.0, 1.0, 0.0, 1.0),
         S (0.0, 1.0, 0.0, 0.0)];
   begin
      Check (Intersection_Count_Of (Sq) = 0, "square boundary → 0 proper");
      Check (not Any_Intersection (Sq), "square boundary Any False");
      Check (Matches_Brute (Sq), "square matches brute");
   end;

   declare
      --  Square with both diagonals: 1 proper crossing at center
      --  (side–side only share endpoints).
      SqD : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 0.0),
         S (2.0, 0.0, 2.0, 2.0),
         S (2.0, 2.0, 0.0, 2.0),
         S (0.0, 2.0, 0.0, 0.0),
         S (0.0, 0.0, 2.0, 2.0),
         S (0.0, 2.0, 2.0, 0.0)];
      L : Intersection_List;
   begin
      L := Find_Intersections (SqD);
      Check (L.Count = 1, "square+diagonals → 1 proper (diagonals)");
      Check (Contains_Pair (L, 5, 6), "diagonal pair present");
      Check (Matches_Brute (SqD), "square+diagonals matches brute");
   end;

   ---------------------------------------------------------------------
   Section ("Brute oracle agreement on random-ish sets");
   ---------------------------------------------------------------------
   declare
      A : constant Segment_Array :=
        [S (0.0, 0.0, 5.0, 1.0),
         S (0.0, 1.0, 5.0, 0.0),
         S (1.0, -1.0, 1.0, 2.0),
         S (2.0, 2.0, 4.0, -1.0)];
   begin
      Check (Matches_Brute (A), "set A matches brute");
      Check (Any_Intersection (A) = (Brute_Force_Intersections (A).Count > 0),
             "set A Any iff brute nonempty");
   end;
   declare
      B : constant Segment_Array :=
        [S (0.0, 0.0, 1.0, 0.5),
         S (0.0, 1.0, 1.0, 0.5),
         S (0.0, 0.5, 1.0, 1.0),
         S (0.0, 0.5, 1.0, 0.0),
         S (-1.0, 0.25, 2.0, 0.25)];
   begin
      Check (Matches_Brute (B), "set B matches brute");
      Check (Intersection_Count_Of (B) =
               Brute_Force_Intersections (B).Count,
             "set B count equals brute count");
   end;

   ---------------------------------------------------------------------
   Section ("Same_Intersection_Set / Empty list");
   ---------------------------------------------------------------------
   declare
      E : constant Intersection_List := Empty_Intersection_List;
      Cross : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 2.0), S (0.0, 2.0, 2.0, 0.0)];
      L1 : constant Intersection_List := Find_Intersections (Cross);
      L2 : constant Intersection_List := Brute_Force_Intersections (Cross);
   begin
      Check (E.Count = 0, "Empty_Intersection_List count 0");
      Check (Same_Intersection_Set (E, E), "empty same as empty");
      Check (Same_Intersection_Set (L1, L2), "find same as brute set");
      Check (not Same_Intersection_Set (L1, E), "nonempty ≠ empty");
   end;

   ---------------------------------------------------------------------
   Section ("Constructors / Make_*");
   ---------------------------------------------------------------------
   declare
      Pt : constant Point := Make_Point (R (3.0), R (4.0));
      Sg : constant Segment := Make_Segment (0.0, 0.0, 1.0, 1.0);
   begin
      Check (Near_Point (Pt, P (3.0, 4.0)), "Make_Point");
      Check (Near_Point (Sg.A, P (0.0, 0.0))
               and then Near_Point (Sg.B, P (1.0, 1.0)),
             "Make_Segment");
   end;

   ---------------------------------------------------------------------
   Section ("Max capacity single pass");
   ---------------------------------------------------------------------
   declare
      --  n disjoint vertical sticks: no intersections.
      Stick : Segment_Array (1 .. Max_Segments);
      L : Intersection_List;
   begin
      for I in Stick'Range loop
         Stick (I) := S (Real (I), 0.0, Real (I), 1.0);
      end loop;
      L := Find_Intersections (Stick);
      Check (L.Count = 0, "Max_Segments vertical sticks → 0");
      Check (not Any_Intersection (Stick), "Max sticks Any False");
      Check (Matches_Brute (Stick), "Max sticks matches brute");
   end;

   declare
      --  Fan of segments from left side crossing a long diagonal.
      Fan : Segment_Array (1 .. 8);
      L : Intersection_List;
   begin
      Fan (1) := S (0.0, 0.0, 10.0, 10.0);
      for I in 2 .. 8 loop
         Fan (I) :=
           S (0.0, Real (I), 10.0, Real (8 - I));
      end loop;
      L := Find_Intersections (Fan);
      Check (L.Count = Brute_Force_Intersections (Fan).Count,
             "fan count equals brute");
      Check (Matches_Brute (Fan), "fan matches brute");
      Check (Any_Intersection (Fan), "fan Any True");
   end;

   ---------------------------------------------------------------------
   Section ("Shared endpoint / collinear limited handling");
   ---------------------------------------------------------------------
   declare
      Touch : constant Segment_Array :=
        [S (0.0, 0.0, 1.0, 1.0), S (1.0, 1.0, 2.0, 0.0)];
      Over : constant Segment_Array :=
        [S (0.0, 0.0, 2.0, 0.0), S (1.0, 0.0, 3.0, 0.0)];
   begin
      Check (Intersection_Count_Of (Touch) = 0,
             "shared endpoint → 0 proper");
      Check (Intersection_Count_Of (Over) = 0,
             "collinear overlap → 0 proper (limited)");
      Check (Matches_Brute (Touch), "touch matches brute");
      Check (Matches_Brute (Over), "overlap matches brute");
   end;

   ---------------------------------------------------------------------
   Section ("Non-1-based caller bounds");
   ---------------------------------------------------------------------
   declare
      --  Ensure copy-to-dense handles 'First /= 1.
      Raw : Segment_Array (5 .. 6);
      L : Intersection_List;
   begin
      Raw (5) := S (0.0, 0.0, 2.0, 2.0);
      Raw (6) := S (0.0, 2.0, 2.0, 0.0);
      L := Find_Intersections (Raw);
      Check (L.Count = 1, "non-1-based array count 1");
      Check (Contains_Pair (L, 1, 2), "non-1-based remapped indices");
      Check (Matches_Brute (Raw), "non-1-based matches brute");
   end;

   ---------------------------------------------------------------------
   Section ("Any_Intersection early-exit vs full report");
   ---------------------------------------------------------------------
   declare
      Many : constant Segment_Array :=
        [S (0.0, 0.0, 9.0, 1.0),
         S (0.0, 1.0, 9.0, 0.0),
         S (0.0, 0.5, 9.0, 0.5),
         S (1.0, -1.0, 1.0, 2.0),
         S (2.0, 2.0, 2.0, -1.0)];
      Full : constant Intersection_List := Find_Intersections (Many);
   begin
      Check (Any_Intersection (Many), "many → Any True");
      Check (Full.Count >= 1, "many → at least one reported");
      Check (Matches_Brute (Many), "many matches brute");
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
