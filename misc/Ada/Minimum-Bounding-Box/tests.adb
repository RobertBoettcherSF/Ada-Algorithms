--  Standalone test suite for Minimum_Bounding_Box (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Minimum_Bounding_Box; use Minimum_Bounding_Box;

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

   function Raised_Invalid_AABB (Pts : Point_Set) return Boolean is
      B : Axis_Aligned_Box;
   begin
      B := Axis_Aligned_Bounding_Box (Pts);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_AABB;

   function Raised_Invalid_OBB (Pts : Point_Set) return Boolean is
      B : Oriented_Box;
   begin
      B := Min_Area_Oriented_Box (Pts);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_OBB;

   function Raised_Invalid_Hull (Pts : Point_Set) return Boolean is
   begin
      declare
         H : constant Point_Array := Convex_Hull (Pts);
      begin
         pragma Unreferenced (H);
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Hull;

   function Empty_Set return Point_Set is
      Z : Point_Array (1 .. 0);
   begin
      return Z;
   end Empty_Set;

   function Too_Many return Point_Set is
      Z : Point_Array (1 .. Max_Points + 1) := [others => (X => 0.0, Y => 0.0)];
   begin
      for I in Z'Range loop
         Z (I) := P (Real (I), Real (I));
      end loop;
      return Z;
   end Too_Many;

begin
   Ada.Text_IO.Put_Line ("Minimum_Bounding_Box tests");
   Ada.Text_IO.Put_Line ("==========================");

   ------------------------------------------------------------------
   Section ("1. Near / Dist2 / Dist / Cross / Dot / Orient2D");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)), "Dist2 3-4-5");
   Check (Near (Dist (P (0.0, 0.0), P (3.0, 4.0)), R (5.0)), "Dist 3-4-5");
   Check (Near (Dist2 (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)), "Dist2 zero");
   Check (Near (Cross (1.0, 0.0, 0.0, 1.0), R (1.0)), "Cross e1×e2 = 1");
   Check (Near (Cross (P (1.0, 0.0), P (0.0, 1.0)), R (1.0)), "Cross pts");
   Check (Near (Cross (1.0, 0.0, 1.0, 0.0), R (0.0)), "Cross parallel 0");
   Check (Near (Dot (P (1.0, 0.0), P (0.0, 1.0)), R (0.0)), "Dot orthogonal");
   Check (Near (Dot (P (2.0, 3.0), P (4.0, 5.0)), R (23.0)), "Dot 2*4+3*5");
   Check (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)) > 0.0,
          "Orient2D CCW positive");
   Check (Orient2D (P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)) < 0.0,
          "Orient2D CW negative");
   Check (Near (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)), R (0.0)),
          "Orient2D collinear ~0");

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument: empty / oversized");
   ------------------------------------------------------------------
   Check (Raised_Invalid_AABB (Empty_Set), "AABB empty raises");
   Check (Raised_Invalid_OBB (Empty_Set), "OBB empty raises");
   Check (Raised_Invalid_Hull (Empty_Set), "Hull empty raises");
   Check (Raised_Invalid_AABB (Too_Many), "AABB oversized raises");
   Check (Raised_Invalid_OBB (Too_Many), "OBB oversized raises");
   Check (Raised_Invalid_Hull (Too_Many), "Hull oversized raises");

   ------------------------------------------------------------------
   Section ("3. Single point / two points");
   ------------------------------------------------------------------
   declare
      One : constant Point_Set := [P (2.0, 3.0)];
      Two : constant Point_Set := [P (0.0, 0.0), P (4.0, 0.0)];
      A1, A2 : Axis_Aligned_Box;
      O1, O2 : Oriented_Box;
      H1, H2 : Point_Array (1 .. Max_Points);
      HN1, HN2 : Point_Count;
   begin
      A1 := Axis_Aligned_Bounding_Box (One);
      Check (Near (A1.Min_X, R (2.0)), "single AABB Min_X");
      Check (Near (A1.Max_X, R (2.0)), "single AABB Max_X");
      Check (Near (A1.Min_Y, R (3.0)), "single AABB Min_Y");
      Check (Near (A1.Max_Y, R (3.0)), "single AABB Max_Y");
      Check (Near (A1.Area, R (0.0)), "single AABB area 0");
      Check (Near (AABB_Width (A1), R (0.0)), "single AABB width 0");
      Check (Near (AABB_Height (A1), R (0.0)), "single AABB height 0");

      O1 := Min_Area_Oriented_Box (One);
      Check (Near (OBB_Area (O1), R (0.0)), "single OBB area 0");
      Check (Near (OBB_Width (O1), R (0.0)), "single OBB width 0");
      Check (Near (OBB_Height (O1), R (0.0)), "single OBB height 0");
      Check (Near_Point (OBB_Corner (O1, 1), P (2.0, 3.0)),
             "single OBB corner at point");

      HN1 := Hull_Vertex_Count (One);
      Check (HN1 = 1, "single hull count 1");

      A2 := Axis_Aligned_Bounding_Box (Two);
      Check (Near (A2.Area, R (0.0)), "segment AABB area 0 (flat)");
      Check (Near (AABB_Width (A2), R (4.0)), "segment AABB width 4");
      Check (Near (AABB_Height (A2), R (0.0)), "segment AABB height 0");

      O2 := Min_Area_Oriented_Box (Two);
      Check (Near (OBB_Area (O2), R (0.0), R (1.0E-6)),
             "segment OBB area ~0");
      Check (Near (OBB_Width (O2), R (4.0), R (1.0E-6))
               or else Near (OBB_Height (O2), R (4.0), R (1.0E-6)),
             "segment OBB has extent 4");

      HN2 := Hull_Vertex_Count (Two);
      Check (HN2 = 2, "segment hull count 2");
      pragma Unreferenced (H1, H2);
   end;

   ------------------------------------------------------------------
   Section ("4. Unit square — AABB vs OBB");
   ------------------------------------------------------------------
   declare
      Sq : constant Point_Set :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      A : Axis_Aligned_Box;
      O, B : Oriented_Box;
   begin
      A := Axis_Aligned_Bounding_Box (Sq);
      Check (Near (A.Min_X, R (0.0)), "square AABB Min_X");
      Check (Near (A.Max_X, R (1.0)), "square AABB Max_X");
      Check (Near (A.Min_Y, R (0.0)), "square AABB Min_Y");
      Check (Near (A.Max_Y, R (1.0)), "square AABB Max_Y");
      Check (Near (AABB_Area (A), R (1.0)), "square AABB area 1");
      Check (Near (AABB_Width (A), R (1.0)), "square AABB width 1");
      Check (Near (AABB_Height (A), R (1.0)), "square AABB height 1");

      O := Min_Area_Oriented_Box (Sq);
      Check (Near (OBB_Area (O), R (1.0), R (1.0E-6)), "square OBB area 1");
      Check (Near (OBB_Width (O) * OBB_Height (O), R (1.0), R (1.0E-6)),
             "square OBB w*h = 1");
      Check (Near (OBB_Area (O), AABB_Area (A), R (1.0E-6)),
             "square OBB area = AABB area");

      B := Brute_Min_Area_OBB (Sq);
      Check (Near (OBB_Area (B), OBB_Area (O), R (1.0E-6)),
             "square brute OBB = OBB");

      Check (Hull_Vertex_Count (Sq) = 4, "square hull has 4 verts");
   end;

   ------------------------------------------------------------------
   Section ("5. Rectangle 4×3 — AABB vs OBB");
   ------------------------------------------------------------------
   declare
      Rect : constant Point_Set :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 3.0), P (0.0, 3.0)];
      A : Axis_Aligned_Box;
      O : Oriented_Box;
   begin
      A := Axis_Aligned_Bounding_Box (Rect);
      Check (Near (AABB_Area (A), R (12.0)), "4x3 AABB area 12");
      Check (Near (AABB_Width (A), R (4.0)), "4x3 AABB width 4");
      Check (Near (AABB_Height (A), R (3.0)), "4x3 AABB height 3");

      O := Min_Area_Oriented_Box (Rect);
      Check (Near (OBB_Area (O), R (12.0), R (1.0E-6)), "4x3 OBB area 12");
      Check (Near (OBB_Area (O), AABB_Area (A), R (1.0E-6)),
             "4x3 OBB = AABB");
      Check ((Near (OBB_Width (O), R (4.0), R (1.0E-6))
                and then Near (OBB_Height (O), R (3.0), R (1.0E-6)))
               or else
             (Near (OBB_Width (O), R (3.0), R (1.0E-6))
                and then Near (OBB_Height (O), R (4.0), R (1.0E-6))),
             "4x3 OBB sides 4 and 3");
      Check (Hull_Vertex_Count (Rect) = 4, "4x3 hull 4 verts");
   end;

   ------------------------------------------------------------------
   Section ("6. Triangle — AABB vs OBB");
   ------------------------------------------------------------------
   declare
      Tri : constant Point_Set :=
        [P (0.0, 0.0), P (4.0, 0.0), P (0.0, 3.0)];
      A : Axis_Aligned_Box;
      O : Oriented_Box;
      --  AABB is [0,4]×[0,3] → area 12.
      --  OBB with base on hypotenuse: hypot = 5, altitude to hypot = 12/5 = 2.4
      --  Actually min-area rect for right triangle: one side flush with a
      --  triangle edge. Flush with legs → 4×3 = 12. Flush with hypotenuse:
      --  width = 5, height = (4*3)/5 = 2.4 → area 12. Same area for right
      --  triangle! For a non-right acute triangle OBB can be smaller.
      --  Use an acute isosceles for a stricter OBB < AABB check below;
      --  here just check OBB ≤ AABB and hull.
   begin
      A := Axis_Aligned_Bounding_Box (Tri);
      Check (Near (AABB_Area (A), R (12.0)), "triangle AABB area 12");
      Check (Near (A.Min_X, R (0.0)) and then Near (A.Max_X, R (4.0)),
             "triangle AABB x-range");
      Check (Near (A.Min_Y, R (0.0)) and then Near (A.Max_Y, R (3.0)),
             "triangle AABB y-range");

      O := Min_Area_Oriented_Box (Tri);
      Check (OBB_Area (O) <= AABB_Area (A) + 1.0E-6,
             "triangle OBB ≤ AABB");
      Check (Near (OBB_Area (O), R (12.0), R (1.0E-5))
               or else OBB_Area (O) < 12.0 + 1.0E-5,
             "triangle OBB area ≤ 12");
      Check (Hull_Vertex_Count (Tri) = 3, "triangle hull 3 verts");
      Check (OBB_Width (O) > 0.0 and then OBB_Height (O) > 0.0,
             "triangle OBB positive sides");
   end;

   ------------------------------------------------------------------
   Section ("7. Rotated diamond — OBB tighter than AABB");
   ------------------------------------------------------------------
   declare
      --  Unit square rotated 45°: vertices on axes at distance √2/2
      --  from origin → diamond with AABB side √2, area 2; OBB is unit
      --  square area 1.
      S : constant Real := Real (Math.Sqrt (2.0)) / 2.0;
      Diamond : constant Point_Set :=
        [P (S, 0.0), P (0.0, S), P (-S, 0.0), P (0.0, -S)];
      A : Axis_Aligned_Box;
      O : Oriented_Box;
   begin
      A := Axis_Aligned_Bounding_Box (Diamond);
      Check (Near (AABB_Width (A), Real (Math.Sqrt (2.0)), R (1.0E-6)),
             "diamond AABB width √2");
      Check (Near (AABB_Height (A), Real (Math.Sqrt (2.0)), R (1.0E-6)),
             "diamond AABB height √2");
      Check (Near (AABB_Area (A), R (2.0), R (1.0E-6)),
             "diamond AABB area 2");

      O := Min_Area_Oriented_Box (Diamond);
      Check (Near (OBB_Area (O), R (1.0), R (1.0E-5)),
             "diamond OBB area 1");
      Check (OBB_Area (O) < AABB_Area (A) - 0.1,
             "diamond OBB strictly < AABB");
      Check (Near (OBB_Width (O), R (1.0), R (1.0E-5))
               and then Near (OBB_Height (O), R (1.0), R (1.0E-5)),
             "diamond OBB is 1×1");
      Check (Hull_Vertex_Count (Diamond) = 4, "diamond hull 4");
   end;

   ------------------------------------------------------------------
   Section ("8. Interior points do not change boxes");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Set :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0),
         P (1.0, 1.0), P (0.5, 0.5), P (1.5, 1.5)];
      Hull_Only : constant Point_Set :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      A1, A2 : Axis_Aligned_Box;
      O1, O2 : Oriented_Box;
   begin
      A1 := Axis_Aligned_Bounding_Box (Cloud);
      A2 := Axis_Aligned_Bounding_Box (Hull_Only);
      Check (Near (AABB_Area (A1), AABB_Area (A2)),
             "interior pts: AABB unchanged");
      O1 := Min_Area_Oriented_Box (Cloud);
      O2 := Min_Area_Oriented_Box (Hull_Only);
      Check (Near (OBB_Area (O1), OBB_Area (O2), R (1.0E-6)),
             "interior pts: OBB unchanged");
      Check (Hull_Vertex_Count (Cloud) = 4, "cloud hull drops interior");
   end;

   ------------------------------------------------------------------
   Section ("9. Duplicate / collinear points");
   ------------------------------------------------------------------
   declare
      Dups : constant Point_Set :=
        [P (0.0, 0.0), P (0.0, 0.0), P (1.0, 0.0), P (1.0, 0.0),
         P (1.0, 1.0), P (0.0, 1.0), P (0.0, 1.0)];
      Col : constant Point_Set :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0), P (3.0, 0.0)];
      A : Axis_Aligned_Box;
      O : Oriented_Box;
      HN : Point_Count;
   begin
      A := Axis_Aligned_Bounding_Box (Dups);
      Check (Near (AABB_Area (A), R (1.0)), "dups AABB area 1");
      O := Min_Area_Oriented_Box (Dups);
      Check (Near (OBB_Area (O), R (1.0), R (1.0E-6)), "dups OBB area 1");
      HN := Hull_Vertex_Count (Dups);
      Check (HN = 4, "dups hull 4 unique corners");

      A := Axis_Aligned_Bounding_Box (Col);
      Check (Near (AABB_Area (A), R (0.0)), "collinear AABB area 0");
      O := Min_Area_Oriented_Box (Col);
      Check (Near (OBB_Area (O), R (0.0), R (1.0E-6)),
             "collinear OBB area ~0");
      HN := Hull_Vertex_Count (Col);
      Check (HN = 2, "collinear hull endpoints only");
   end;

   ------------------------------------------------------------------
   Section ("10. Translated / scaled square");
   ------------------------------------------------------------------
   declare
      Sq : constant Point_Set :=
        [P (10.0, 20.0), P (13.0, 20.0), P (13.0, 24.0), P (10.0, 24.0)];
      A : Axis_Aligned_Box;
      O : Oriented_Box;
   begin
      A := Axis_Aligned_Bounding_Box (Sq);
      Check (Near (AABB_Area (A), R (12.0)), "translated 3x4 AABB 12");
      O := Min_Area_Oriented_Box (Sq);
      Check (Near (OBB_Area (O), R (12.0), R (1.0E-6)),
             "translated 3x4 OBB 12");
      Check (Near (A.Min_X, R (10.0)) and then Near (A.Min_Y, R (20.0)),
             "translated AABB origin");
   end;

   ------------------------------------------------------------------
   Section ("11. OBB corners form a rectangle of reported area");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Set :=
        [P (0.0, 1.0), P (1.0, 0.0), P (2.0, 1.0), P (1.0, 2.0)];
      O : Oriented_Box;
      C1, C2, C3, C4 : Point;
      D12, D23, D34, D41, D13 : Real;
   begin
      O := Min_Area_Oriented_Box (Pts);
      C1 := OBB_Corner (O, 1);
      C2 := OBB_Corner (O, 2);
      C3 := OBB_Corner (O, 3);
      C4 := OBB_Corner (O, 4);
      D12 := Dist (C1, C2);
      D23 := Dist (C2, C3);
      D34 := Dist (C3, C4);
      D41 := Dist (C4, C1);
      D13 := Dist (C1, C3);
      Check (Near (D12, D34, R (1.0E-5)), "OBB opposite sides equal (1)");
      Check (Near (D23, D41, R (1.0E-5)), "OBB opposite sides equal (2)");
      Check (Near (D12 * D23, OBB_Area (O), R (1.0E-4)),
             "OBB side product = area");
      Check (D13 > D12 and then D13 > D23, "OBB diagonal longer than sides");
      pragma Unreferenced (C1, C2, C3, C4);
   end;

   ------------------------------------------------------------------
   Section ("12. Angle accessor / accessors smoke");
   ------------------------------------------------------------------
   declare
      Rect : constant Point_Set :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 1.0), P (0.0, 1.0)];
      O : Oriented_Box;
      A : Axis_Aligned_Box;
      Ang : Real;
   begin
      O := Min_Area_Oriented_Box (Rect);
      Ang := OBB_Angle (O);
      Check (Ang'Valid, "OBB angle is valid Real");
      Check (Near (OBB_Area (O), R (2.0), R (1.0E-6)), "2x1 OBB area 2");
      A := Axis_Aligned_Bounding_Box (Rect);
      Check (Near (AABB_Area (A), R (2.0)), "2x1 AABB area 2");
      Check (Near (AABB_Area (A), OBB_Area (O), R (1.0E-6)),
             "2x1 AABB = OBB");
   end;

   ------------------------------------------------------------------
   Section ("13. Max_Points capacity smoke");
   ------------------------------------------------------------------
   declare
      Pts : Point_Array (1 .. Max_Points);
      A : Axis_Aligned_Box;
      O : Oriented_Box;
      HN : Point_Count;
   begin
      for I in Pts'Range loop
         --  Points on a circle (convex position).
         declare
            Ang : constant Long_Float :=
              2.0 * Ada.Numerics.Pi * Long_Float (I - 1)
              / Long_Float (Max_Points);
         begin
            Pts (I) :=
              (X => Real (Math.Cos (Ang)),
               Y => Real (Math.Sin (Ang)));
         end;
      end loop;
      A := Axis_Aligned_Bounding_Box (Pts);
      Check (AABB_Area (A) > 0.0, "circle AABB positive area");
      O := Min_Area_Oriented_Box (Pts);
      Check (OBB_Area (O) > 0.0, "circle OBB positive area");
      Check (OBB_Area (O) <= AABB_Area (A) + 1.0E-6,
             "circle OBB ≤ AABB");
      HN := Hull_Vertex_Count (Pts);
      Check (HN = Max_Points, "circle all points on hull");
   end;

   ------------------------------------------------------------------
   Section ("14. Irregular pentagon / hexagon");
   ------------------------------------------------------------------
   declare
      Pent : constant Point_Set :=
        [P (0.0, 0.0), P (3.0, 0.0), P (4.0, 2.0),
         P (2.0, 3.0), P (-1.0, 1.5)];
      Hex : constant Point_Set :=
        [P (1.0, 0.0), P (2.0, 0.0), P (3.0, 1.0),
         P (2.0, 2.0), P (1.0, 2.0), P (0.0, 1.0)];
      A : Axis_Aligned_Box;
      O : Oriented_Box;
   begin
      A := Axis_Aligned_Bounding_Box (Pent);
      O := Min_Area_Oriented_Box (Pent);
      Check (AABB_Area (A) > 0.0, "pentagon AABB > 0");
      Check (OBB_Area (O) > 0.0, "pentagon OBB > 0");
      Check (OBB_Area (O) <= AABB_Area (A) + 1.0E-6,
             "pentagon OBB ≤ AABB");
      Check (Hull_Vertex_Count (Pent) = 5, "pentagon hull 5");

      A := Axis_Aligned_Bounding_Box (Hex);
      O := Min_Area_Oriented_Box (Hex);
      Check (Near (OBB_Area (O), AABB_Area (A), R (1.0E-5))
               or else OBB_Area (O) <= AABB_Area (A) + 1.0E-5,
             "hexagon OBB ≤ AABB");
      Check (Hull_Vertex_Count (Hex) = 6, "hexagon hull 6");
   end;

   ------------------------------------------------------------------
   Section ("15. Negative coordinates");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Set :=
        [P (-2.0, -2.0), P (2.0, -2.0), P (2.0, 2.0), P (-2.0, 2.0)];
      A : Axis_Aligned_Box;
      O : Oriented_Box;
   begin
      A := Axis_Aligned_Bounding_Box (Pts);
      Check (Near (AABB_Area (A), R (16.0)), "neg coords AABB 16");
      O := Min_Area_Oriented_Box (Pts);
      Check (Near (OBB_Area (O), R (16.0), R (1.0E-6)),
             "neg coords OBB 16");
      Check (Near (A.Min_X, R (-2.0)) and then Near (A.Max_X, R (2.0)),
             "neg coords x-range");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line (
     "Result: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
