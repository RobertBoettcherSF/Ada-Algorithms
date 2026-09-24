--  Standalone test suite for Point_In_Polygon (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Point_In_Polygon; use Point_In_Polygon;

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

   function Raised_Invalid_Even_Odd (Poly : Polygon; Q : Point) return Boolean
   is
      B : Boolean;
   begin
      B := Contains_Even_Odd (Q, Poly);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Even_Odd;

   function Raised_Invalid_Winding (Poly : Polygon; Q : Point) return Boolean
   is
      B : Boolean;
   begin
      B := Contains_Winding (Q, Poly);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Winding;

   function Raised_Invalid_Boundary (Poly : Polygon; Q : Point) return Boolean
   is
      B : Boolean;
   begin
      B := On_Boundary (Q, Poly);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Boundary;

   function Raised_Invalid_Crossing (Poly : Polygon; Q : Point) return Boolean
   is
      N : Natural;
   begin
      N := Crossing_Number (Q, Poly);
      pragma Unreferenced (N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Crossing;

   function Raised_Invalid_Wn (Poly : Polygon; Q : Point) return Boolean is
      N : Integer;
   begin
      N := Winding_Number (Q, Poly);
      pragma Unreferenced (N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Wn;

   procedure Check_Both
     (Q : Point; Poly : Polygon; Expect_Inside : Boolean; Label : String)
   is
   begin
      Check (Contains_Even_Odd (Q, Poly) = Expect_Inside,
             Label & " even-odd");
      Check (Contains_Winding (Q, Poly) = Expect_Inside,
             Label & " winding");
      Check (Contains (Q, Poly, Use_Winding => False) = Expect_Inside,
             Label & " Contains(False)");
      Check (Contains (Q, Poly, Use_Winding => True) = Expect_Inside,
             Label & " Contains(True)");
   end Check_Both;

begin
   Ada.Text_IO.Put_Line ("Point_In_Polygon tests");
   Ada.Text_IO.Put_Line ("======================");

   ------------------------------------------------------------------
   Section ("1. Near / Near_Point / Dist2 / Orient2D");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)),
          "Dist2 3-4-5");
   Check (Near (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)), R (1.0)),
          "Orient2D left = +1");
   Check (Near (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, -1.0)),
                R (-1.0)),
          "Orient2D right = -1");
   Check (Near (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)), R (0.0)),
          "Orient2D collinear = 0");

   ------------------------------------------------------------------
   Section ("2. Point_On_Segment");
   ------------------------------------------------------------------
   Check (Point_On_Segment (P (0.5, 0.0), P (0.0, 0.0), P (1.0, 0.0)),
          "midpoint on horizontal segment");
   Check (Point_On_Segment (P (0.0, 0.0), P (0.0, 0.0), P (1.0, 0.0)),
          "endpoint A on segment");
   Check (Point_On_Segment (P (1.0, 0.0), P (0.0, 0.0), P (1.0, 0.0)),
          "endpoint B on segment");
   Check (not Point_On_Segment (P (0.5, 0.1), P (0.0, 0.0), P (1.0, 0.0)),
          "off horizontal segment");
   Check (not Point_On_Segment (P (1.5, 0.0), P (0.0, 0.0), P (1.0, 0.0)),
          "beyond endpoint");
   Check (Point_On_Segment (P (0.5, 0.5), P (0.0, 0.0), P (1.0, 1.0)),
          "midpoint on diagonal");
   Check (Point_On_Segment (P (0.0, 0.5), P (0.0, 0.0), P (0.0, 1.0)),
          "midpoint on vertical segment");
   Check (Point_On_Segment (P (0.0, 0.0), P (0.0, 0.0), P (0.0, 0.0)),
          "degenerate segment as point");

   ------------------------------------------------------------------
   Section ("3. Unit square — inside / outside / corners / edges");
   ------------------------------------------------------------------
   declare
      Sq : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
   begin
      Check_Both (P (0.5, 0.5), Sq, True, "square center");
      Check_Both (P (0.25, 0.75), Sq, True, "square interior");
      Check_Both (P (-0.5, 0.5), Sq, False, "square left outside");
      Check_Both (P (1.5, 0.5), Sq, False, "square right outside");
      Check_Both (P (0.5, -0.5), Sq, False, "square below outside");
      Check_Both (P (0.5, 1.5), Sq, False, "square above outside");
      Check_Both (P (2.0, 2.0), Sq, False, "square far outside");

      --  Corners (boundary ⇒ inside under closed policy)
      Check (On_Boundary (P (0.0, 0.0), Sq), "corner (0,0) On_Boundary");
      Check (On_Boundary (P (1.0, 0.0), Sq), "corner (1,0) On_Boundary");
      Check (On_Boundary (P (1.0, 1.0), Sq), "corner (1,1) On_Boundary");
      Check (On_Boundary (P (0.0, 1.0), Sq), "corner (0,1) On_Boundary");
      Check_Both (P (0.0, 0.0), Sq, True, "corner (0,0)");
      Check_Both (P (1.0, 0.0), Sq, True, "corner (1,0)");
      Check_Both (P (1.0, 1.0), Sq, True, "corner (1,1)");
      Check_Both (P (0.0, 1.0), Sq, True, "corner (0,1)");

      --  Edge midpoints
      Check (On_Boundary (P (0.5, 0.0), Sq), "bottom edge On_Boundary");
      Check (On_Boundary (P (1.0, 0.5), Sq), "right edge On_Boundary");
      Check (On_Boundary (P (0.5, 1.0), Sq), "top edge On_Boundary");
      Check (On_Boundary (P (0.0, 0.5), Sq), "left edge On_Boundary");
      Check_Both (P (0.5, 0.0), Sq, True, "bottom edge mid");
      Check_Both (P (1.0, 0.5), Sq, True, "right edge mid");
      Check_Both (P (0.5, 1.0), Sq, True, "top edge mid");
      Check_Both (P (0.0, 0.5), Sq, True, "left edge mid");

      Check (not On_Boundary (P (0.5, 0.5), Sq), "center not On_Boundary");
      Check (Crossing_Number (P (0.5, 0.5), Sq) mod 2 = 1,
             "center crossing odd");
      Check (Winding_Number (P (0.5, 0.5), Sq) /= 0,
             "center winding nonzero");
      Check (Crossing_Number (P (2.0, 0.5), Sq) mod 2 = 0,
             "outside crossing even");
      Check (Winding_Number (P (2.0, 0.5), Sq) = 0,
             "outside winding zero");
   end;

   ------------------------------------------------------------------
   Section ("4. CW vs CCW square");
   ------------------------------------------------------------------
   declare
      CCW_Sq : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      CW_Sq  : constant Polygon :=
        [P (0.0, 0.0), P (0.0, 1.0), P (1.0, 1.0), P (1.0, 0.0)];
   begin
      Check_Both (P (0.5, 0.5), CCW_Sq, True, "CCW center");
      Check_Both (P (0.5, 0.5), CW_Sq, True, "CW center");
      Check_Both (P (2.0, 0.5), CCW_Sq, False, "CCW outside");
      Check_Both (P (2.0, 0.5), CW_Sq, False, "CW outside");
      Check (Winding_Number (P (0.5, 0.5), CCW_Sq) = 1
             or else Winding_Number (P (0.5, 0.5), CCW_Sq) = -1,
             "CCW |wn|=1");
      Check (Winding_Number (P (0.5, 0.5), CW_Sq) = 1
             or else Winding_Number (P (0.5, 0.5), CW_Sq) = -1,
             "CW |wn|=1");
      Check (Winding_Number (P (0.5, 0.5), CCW_Sq)
             = -Winding_Number (P (0.5, 0.5), CW_Sq),
             "CW wn = -CCW wn");
   end;

   ------------------------------------------------------------------
   Section ("5. Triangle (convex)");
   ------------------------------------------------------------------
   declare
      Tri : constant Polygon :=
        [P (0.0, 0.0), P (4.0, 0.0), P (0.0, 3.0)];
   begin
      Check_Both (P (1.0, 1.0), Tri, True, "triangle interior");
      Check_Both (P (3.0, 2.0), Tri, False, "triangle outside hypotenuse");
      Check_Both (P (-1.0, 1.0), Tri, False, "triangle left outside");
      Check_Both (P (0.0, 0.0), Tri, True, "triangle vertex");
      Check_Both (P (2.0, 0.0), Tri, True, "triangle base midpoint");
      Check (On_Boundary (P (2.0, 1.5), Tri),
             "hypotenuse midpoint On_Boundary");
      Check_Both (P (2.0, 1.5), Tri, True, "hypotenuse midpoint");
   end;

   ------------------------------------------------------------------
   Section ("6. Rectangle");
   ------------------------------------------------------------------
   declare
      Rect : constant Polygon :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 3.0), P (0.0, 3.0)];
   begin
      Check_Both (P (2.0, 1.5), Rect, True, "rect center");
      Check_Both (P (0.1, 0.1), Rect, True, "rect near corner inside");
      Check_Both (P (5.0, 1.5), Rect, False, "rect right outside");
      Check_Both (P (2.0, -1.0), Rect, False, "rect below outside");
      Check_Both (P (4.0, 1.5), Rect, True, "rect right edge");
   end;

   ------------------------------------------------------------------
   Section ("7. Concave arrowhead / chevron");
   ------------------------------------------------------------------
   --  Concave pentagon: unit-ish arrow pointing right.
   --  Vertices CCW: (0,0), (2,1), (0,2), (0.5,1), (0,0) wait — use:
   --  (0,0), (3,1), (0,2), (1,1) — dart / arrowhead.
   declare
      Arrow : constant Polygon :=
        [P (0.0, 0.0), P (3.0, 1.0), P (0.0, 2.0), P (1.0, 1.0)];
   begin
      Check_Both (P (0.5, 1.0), Arrow, False,
                  "arrow notch outside (concave pocket)");
      Check_Both (P (2.0, 1.0), Arrow, True, "arrow tip interior");
      Check_Both (P (1.5, 0.7), Arrow, True, "arrow lower lobe");
      Check_Both (P (1.5, 1.3), Arrow, True, "arrow upper lobe");
      Check_Both (P (4.0, 1.0), Arrow, False, "arrow far right outside");
      Check_Both (P (-1.0, 1.0), Arrow, False, "arrow left outside");
      Check (On_Boundary (P (3.0, 1.0), Arrow), "arrow tip vertex");
      Check_Both (P (3.0, 1.0), Arrow, True, "arrow tip vertex inside");
   end;

   ------------------------------------------------------------------
   Section ("8. Concave C-shape");
   ------------------------------------------------------------------
   declare
      C_Poly : constant Polygon :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 1.0), P (1.0, 1.0),
         P (1.0, 2.0), P (3.0, 2.0), P (3.0, 3.0), P (0.0, 3.0)];
   begin
      Check_Both (P (0.5, 1.5), C_Poly, True, "C spine interior");
      Check_Both (P (2.0, 0.5), C_Poly, True, "C bottom arm");
      Check_Both (P (2.0, 2.5), C_Poly, True, "C top arm");
      Check_Both (P (2.0, 1.5), C_Poly, False, "C mouth outside");
      Check_Both (P (4.0, 1.5), C_Poly, False, "C right outside");
      Check_Both (P (-0.5, 1.5), C_Poly, False, "C left outside");
   end;

   ------------------------------------------------------------------
   Section ("9. Pentagon (convex regular-ish)");
   ------------------------------------------------------------------
   declare
      Pent : constant Polygon :=
        [P (1.0, 0.0), P (2.0, 0.5), P (1.5, 1.5),
         P (0.5, 1.5), P (0.0, 0.5)];
   begin
      Check_Both (P (1.0, 0.8), Pent, True, "pentagon centerish");
      Check_Both (P (1.0, -0.5), Pent, False, "pentagon below outside");
      Check_Both (P (3.0, 0.8), Pent, False, "pentagon right outside");
      Check_Both (P (1.0, 0.0), Pent, True, "pentagon bottom vertex");
   end;

   ------------------------------------------------------------------
   Section ("10. Strict interior vs boundary");
   ------------------------------------------------------------------
   declare
      Sq : constant Polygon :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      Edge_Pt : constant Point := P (1.0, 0.0);
      In_Pt   : constant Point := P (1.0, 1.0);
   begin
      Check (On_Boundary (Edge_Pt, Sq), "edge pt On_Boundary");
      Check (Contains_Even_Odd (Edge_Pt, Sq), "edge pt closed even-odd");
      Check (not On_Boundary (In_Pt, Sq)
             and then Contains_Even_Odd (In_Pt, Sq),
             "strict interior pattern");
      Check (not (not On_Boundary (Edge_Pt, Sq)
                  and then Contains_Even_Odd (Edge_Pt, Sq)),
             "edge fails strict-interior pattern");
   end;

   ------------------------------------------------------------------
   Section ("11. Invalid_Argument (n < 3)");
   ------------------------------------------------------------------
   declare
      Empty : Polygon (1 .. 0);
      One   : constant Polygon := [P (0.0, 0.0)];
      Two   : constant Polygon := [P (0.0, 0.0), P (1.0, 0.0)];
      Q     : constant Point := P (0.0, 0.0);
   begin
      Check (Raised_Invalid_Even_Odd (Empty, Q), "empty even-odd raises");
      Check (Raised_Invalid_Winding (Empty, Q), "empty winding raises");
      Check (Raised_Invalid_Boundary (Empty, Q), "empty boundary raises");
      Check (Raised_Invalid_Crossing (Empty, Q), "empty crossing raises");
      Check (Raised_Invalid_Wn (Empty, Q), "empty wn raises");
      Check (Raised_Invalid_Even_Odd (One, Q), "n=1 even-odd raises");
      Check (Raised_Invalid_Winding (One, Q), "n=1 winding raises");
      Check (Raised_Invalid_Even_Odd (Two, Q), "n=2 even-odd raises");
      Check (Raised_Invalid_Winding (Two, Q), "n=2 winding raises");
      Check (Raised_Invalid_Boundary (Two, Q), "n=2 boundary raises");
   end;

   ------------------------------------------------------------------
   Section ("12. Shifted / translated square");
   ------------------------------------------------------------------
   declare
      Sq : constant Polygon :=
        [P (10.0, 20.0), P (12.0, 20.0), P (12.0, 22.0), P (10.0, 22.0)];
   begin
      Check_Both (P (11.0, 21.0), Sq, True, "shifted center");
      Check_Both (P (9.0, 21.0), Sq, False, "shifted left outside");
      Check_Both (P (11.0, 19.0), Sq, False, "shifted below outside");
      Check_Both (P (10.0, 20.0), Sq, True, "shifted corner");
   end;

   ------------------------------------------------------------------
   Section ("13. Ray through vertex robustness");
   ------------------------------------------------------------------
   --  Horizontal ray from interior through a right-side vertex should
   --  still classify interior correctly (no double-count).
   declare
      Sq : constant Polygon :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      --  Point at y=2 would hit top corners; use y slightly inside.
      Q : constant Point := P (1.0, 1.0);
   begin
      Check (Contains_Even_Odd (Q, Sq), "vertex-ray safe interior even-odd");
      Check (Contains_Winding (Q, Sq), "vertex-ray safe interior winding");
      --  Query whose ray passes exactly through the right-edge midpoint
      --  (an edge, not only a vertex) — still interior.
      Check_Both (P (0.5, 1.0), Sq, True, "ray hits right edge mid from left");
   end;

   ------------------------------------------------------------------
   Section ("14. Large triangle / many queries");
   ------------------------------------------------------------------
   declare
      Big : constant Polygon :=
        [P (0.0, 0.0), P (10.0, 0.0), P (5.0, 8.0)];
   begin
      Check_Both (P (5.0, 2.0), Big, True, "big tri center");
      Check_Both (P (5.0, 7.5), Big, True, "big tri near apex inside");
      Check_Both (P (5.0, 8.5), Big, False, "big tri above apex");
      Check_Both (P (0.0, 0.0), Big, True, "big tri SW vertex");
      Check_Both (P (10.0, 0.0), Big, True, "big tri SE vertex");
      Check_Both (P (5.0, 8.0), Big, True, "big tri apex");
      Check_Both (P (-1.0, 0.0), Big, False, "big tri left");
      Check_Both (P (5.0, -1.0), Big, False, "big tri below");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("======================");
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
