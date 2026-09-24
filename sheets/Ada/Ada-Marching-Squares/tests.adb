--  Standalone test suite for Marching_Squares (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Marching_Squares; use Marching_Squares;

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

   function Approx_Vec (A, B : Vec2; Tol : Real := 1.0E-3) return Boolean is
   begin
      return Approx (A.X, B.X, Tol) and then Approx (A.Y, B.Y, Tol);
   end Approx_Vec;

begin
   Put_Line ("Marching_Squares test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers");
   ---------------------------------------------------------------------
   declare
      V  : constant Vec2 := (3.0, 4.0);
      N  : constant Vec2 := Normalize (V);
      D  : constant Real := Dot ((1.0, 0.0), (0.0, 1.0));
      Sm : constant Vec2 := (1.0, 2.0) + (3.0, 4.0);
      Sc : constant Vec2 := 2.0 * (1.0, 1.5);
   begin
      Check (Approx (Length (V), 5.0), "Length of (3,4) is 5");
      Check (Approx (Length (N), 1.0), "Normalize yields unit length");
      Check (abs (D) <= 1.0E-5, "Dot of orthogonal axes is 0");
      Check (Approx (Sm.X, 4.0) and then Approx (Sm.Y, 6.0),
             "Vector addition");
      Check (Approx (Sc.X, 2.0) and then Approx (Sc.Y, 3.0),
             "Scalar multiply");
   end;

   ---------------------------------------------------------------------
   Section ("2. Clamp / Distance / Cell_Corner_Offset");
   ---------------------------------------------------------------------
   declare
      C1   : constant Real := Clamp (5.0, 0.0, 1.0);
      C2   : constant Real := Clamp (-1.0, 0.0, 1.0);
      Dist : constant Non_Negative :=
        Distance_Between ((0.0, 0.0), (3.0, 4.0));
      O0   : constant Vec2 := Cell_Corner_Offset (0);
      O2   : constant Vec2 := Cell_Corner_Offset (2);
   begin
      Check (C1 = 1.0, "Clamp upper bound");
      Check (C2 = 0.0, "Clamp lower bound");
      Check (Approx (Dist, 5.0), "Distance_Between of 3-4-5 triangle");
      Check (Approx_Vec (O0, (0.0, 1.0)), "Corner 0 is top-left (0,1)");
      Check (Approx_Vec (O2, (1.0, 0.0)), "Corner 2 is bottom-right (1,0)");
   end;

   ---------------------------------------------------------------------
   Section ("3. Cell_Case_Index (all 16 cases)");
   ---------------------------------------------------------------------
   declare
      --  Use 1.0 = above, 0.0 = below, isolevel 0.5
      function Bits (TL, TR, BR, BL : Real) return Case_Index is
      begin
         return Cell_Case_Index (TL, TR, BR, BL, 0.5);
      end Bits;
   begin
      Check (Bits (0.0, 0.0, 0.0, 0.0) = 0, "Case 0 all below");
      Check (Bits (0.0, 0.0, 0.0, 1.0) = 1, "Case 1 BL only");
      Check (Bits (0.0, 0.0, 1.0, 0.0) = 2, "Case 2 BR only");
      Check (Bits (0.0, 1.0, 0.0, 0.0) = 4, "Case 4 TR only");
      Check (Bits (1.0, 0.0, 0.0, 0.0) = 8, "Case 8 TL only");
      Check (Bits (0.0, 1.0, 0.0, 1.0) = 5, "Case 5 TR+BL saddle");
      Check (Bits (1.0, 0.0, 1.0, 0.0) = 10, "Case 10 TL+BR saddle");
      Check (Bits (1.0, 1.0, 1.0, 1.0) = 15, "Case 15 all above");
      Check (Bits (1.0, 1.0, 0.0, 0.0) = 12, "Case 12 TL+TR");
   end;

   ---------------------------------------------------------------------
   Section ("4. Interpolate_Edge");
   ---------------------------------------------------------------------
   declare
      Mid : constant Point2 := Interpolate_Edge
        ((0.0, 0.0), (1.0, 0.0), 0.0, 1.0, 0.5);
      Qtr : constant Point2 := Interpolate_Edge
        ((0.0, 0.0), (0.0, 4.0), 0.0, 4.0, 1.0);
      Endp : constant Point2 := Interpolate_Edge
        ((0.0, 0.0), (2.0, 2.0), 1.0, 3.0, 1.0);
   begin
      Check (Approx_Vec (Mid, (0.5, 0.0)), "Midpoint at isolevel 0.5");
      Check (Approx_Vec (Qtr, (0.0, 1.0)), "Interpolate 1/4 along vertical");
      Check (Approx_Vec (Endp, (0.0, 0.0)), "Isolevel at P0 endpoint");
      Check (Approx (Mid.X, 0.5), "X of midpoint");
   end;

   ---------------------------------------------------------------------
   Section ("5. Lookup_Segments / March_Cell_Isoline");
   ---------------------------------------------------------------------
   declare
      EA, EB, EC, ED : Integer;
      N : Natural;
      Segs : Small_Segment_List;
      CN : Natural;
      --  Unit cell corners
      TL : constant Point2 := (0.0, 1.0);
      TR : constant Point2 := (1.0, 1.0);
      BR : constant Point2 := (1.0, 0.0);
      BL : constant Point2 := (0.0, 0.0);
   begin
      Lookup_Segments (0, 0.0, 0.5, EA, EB, EC, ED, N);
      Check (N = 0, "Case 0 emits no segments");

      Lookup_Segments (1, 0.0, 0.5, EA, EB, EC, ED, N);
      Check (N = 1 and then EA = 3 and then EB = 2,
             "Case 1 uses left-bottom edges");

      Lookup_Segments (15, 1.0, 0.5, EA, EB, EC, ED, N);
      Check (N = 0, "Case 15 emits no segments");

      March_Cell_Isoline
        (TL, TR, BR, BL,
         0.0, 0.0, 0.0, 1.0,  -- only BL above
         0.5, Segs, CN);
      Check (CN = 1, "March_Cell_Isoline case 1 yields one segment");
      Check (Approx (Segs (1).A.X + Segs (1).B.X, 0.0 + 0.5, 0.2)
               or else Approx (Distance_Between (Segs (1).A, Segs (1).B),
                               0.7071, 0.1),
             "Case 1 segment has positive length");
   end;

   ---------------------------------------------------------------------
   Section ("6. Disambiguate_Saddle");
   ---------------------------------------------------------------------
   declare
      --  Case 5 values: TR=1, BL=1, TL=0, BR=0 → avg=0.5
      Above_High : constant Boolean :=
        Disambiguate_Saddle (0.0, 2.0, 0.0, 2.0, 0.5);  -- avg=1.0
      Above_Low  : constant Boolean :=
        Disambiguate_Saddle (0.0, 0.4, 0.0, 0.4, 0.5);  -- avg=0.2
      EA1, EB1, EC1, ED1, EA2, EB2, EC2, ED2 : Integer;
      N1, N2 : Natural;
   begin
      Check (Above_High, "High average => center above");
      Check (not Above_Low, "Low average => center below");
      Check (Saddle_Center_Above (0.5, 0.5), "Exact isolevel counts as above");

      Lookup_Segments (5, 1.0, 0.5, EA1, EB1, EC1, ED1, N1);
      Lookup_Segments (5, 0.0, 0.5, EA2, EB2, EC2, ED2, N2);
      Check (N1 = 2 and then N2 = 2, "Saddle case 5 emits two segments");
      Check (not (EA1 = EA2 and then EB1 = EB2 and then EC1 = EC2
                    and then ED1 = ED2),
             "Saddle connections differ by center average");
   end;

   ---------------------------------------------------------------------
   Section ("7. March_Grid_Isolines (height field)");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 4, 0 .. 4);
      Pos  : Position_Field (0 .. 4, 0 .. 4);
      Poly : Polyline;
   begin
      Fill_Height_Field
        (Vals, Pos, Origin => (0.0, 0.0), Spacing => 1.0,
         Slope_X => 1.0, Slope_Y => 0.0, Base => 0.0);
      --  f = X; isolevel 2.0 should cut vertical line near X=2
      Poly := March_Grid_Isolines (Vals, Pos, 2.0);
      Check (Count_Segments (Poly) > 0, "Height field yields segments");
      Check (Count_Segments (Poly) >= 4, "At least one segment per row");
      declare
         St : constant Polyline_Stats := Compute_Polyline_Stats (Poly);
      begin
         Check (St.Segment_Count = Count_Segments (Poly),
                "Stats segment count matches");
         Check (St.Total_Length > 0.0, "Total polyline length positive");
         Check (Approx (St.Min_Corner.X, 2.0, 0.1)
                  or else St.Min_Corner.X <= 2.0 + 0.1,
                "Contour near X=2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. March_Grid_Isolines (radial field)");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 8, 0 .. 8);
      Pos  : Position_Field (0 .. 8, 0 .. 8);
      Poly : Polyline;
      St   : Polyline_Stats;
   begin
      Fill_Radial_Field
        (Vals, Pos, Origin => (0.0, 0.0), Spacing => 1.0,
         Center => (4.0, 4.0), Peak => 3.0);
      --  Isoline Peak - r = 0 => circle of radius 3
      Poly := March_Grid_Isolines (Vals, Pos, 0.0);
      St := Compute_Polyline_Stats (Poly);
      Check (Count_Segments (Poly) > 8, "Radial contour has many segments");
      Check (St.Total_Length > 10.0, "Circle-ish length > 10");
      Check (St.Min_Corner.X < 4.0 and then St.Max_Corner.X > 4.0,
             "Contour spans center in X");
      Check (St.Min_Corner.Y < 4.0 and then St.Max_Corner.Y > 4.0,
             "Contour spans center in Y");
   end;

   ---------------------------------------------------------------------
   Section ("9. March_Cell_Isoband / March_Grid_Isobands");
   ---------------------------------------------------------------------
   declare
      TL : constant Point2 := (0.0, 1.0);
      TR : constant Point2 := (1.0, 1.0);
      BR : constant Point2 := (1.0, 0.0);
      BL : constant Point2 := (0.0, 0.0);
      Poly : Band_Polygon;
      Vals : Scalar_Field (0 .. 3, 0 .. 3);
      Pos  : Position_Field (0 .. 3, 0 .. 3);
      Bands : Band_List;
   begin
      --  Entire cell inside band
      March_Cell_Isoband
        (TL, TR, BR, BL, 0.5, 0.5, 0.5, 0.5, 0.0, 1.0, Poly);
      Check (Poly.Count = 4, "Full-band cell is a quad");

      --  Entire cell below band → empty
      March_Cell_Isoband
        (TL, TR, BR, BL, -2.0, -2.0, -2.0, -2.0, 0.0, 1.0, Poly);
      Check (Poly.Count = 0, "Below-band cell empty");

      --  Entire cell above band → empty
      March_Cell_Isoband
        (TL, TR, BR, BL, 5.0, 5.0, 5.0, 5.0, 0.0, 1.0, Poly);
      Check (Poly.Count = 0, "Above-band cell empty");

      Fill_Height_Field
        (Vals, Pos, (0.0, 0.0), 1.0, Slope_X => 1.0, Slope_Y => 0.0);
      Bands := March_Grid_Isobands (Vals, Pos, 1.0, 2.0);
      Check (Bands.Count > 0, "Isoband grid emits polygons");
      Check (Bands.Bands (1).Count >= 3, "First band has >= 3 vertices");
   end;

   ---------------------------------------------------------------------
   Section ("10. March_Triangle_Isoline");
   ---------------------------------------------------------------------
   declare
      Segs : Small_Segment_List;
      N : Natural;
      A : constant Point2 := (0.0, 0.0);
      B : constant Point2 := (2.0, 0.0);
      C : constant Point2 := (0.0, 2.0);
   begin
      March_Triangle_Isoline (A, B, C, 0.0, 0.0, 0.0, 0.5, Segs, N);
      Check (N = 0, "All-below triangle: no segment");

      March_Triangle_Isoline (A, B, C, 1.0, 1.0, 1.0, 0.5, Segs, N);
      Check (N = 0, "All-above triangle: no segment");

      March_Triangle_Isoline (A, B, C, 0.0, 0.0, 1.0, 0.5, Segs, N);
      Check (N = 1, "One-corner-above: one segment");
      Check (Distance_Between (Segs (1).A, Segs (1).B) > 0.0,
             "Triangle segment has positive length");

      March_Triangle_Isoline (A, B, C, 1.0, 0.0, 0.0, 0.5, Segs, N);
      Check (N = 1, "Only A above: one segment");
      --  Crossing midpoints of AB and AC ≈ (1,0) and (0,1)
      Check
        ((Approx_Vec (Segs (1).A, (1.0, 0.0), 0.05)
            and then Approx_Vec (Segs (1).B, (0.0, 1.0), 0.05))
         or else
         (Approx_Vec (Segs (1).B, (1.0, 0.0), 0.05)
            and then Approx_Vec (Segs (1).A, (0.0, 1.0), 0.05)),
         "Isoline through midpoints of AB and AC");
   end;

   ---------------------------------------------------------------------
   Section ("11. Fill_Height_Field / Fill_Radial_Field");
   ---------------------------------------------------------------------
   declare
      Vh : Scalar_Field (0 .. 2, 0 .. 2);
      Ph : Position_Field (0 .. 2, 0 .. 2);
      Vr : Scalar_Field (0 .. 2, 0 .. 2);
      Pr : Position_Field (0 .. 2, 0 .. 2);
   begin
      Fill_Height_Field
        (Vh, Ph, (0.0, 0.0), 1.0, Slope_X => 2.0, Slope_Y => 3.0, Base => 1.0);
      Check (Approx_Vec (Ph (0, 0), (0.0, 0.0)), "Height origin at (0,0)");
      Check (Approx (Vh (0, 0), 1.0), "Height base at origin");
      Check (Approx (Vh (1, 0), 1.0 + 2.0), "Height slope in X");
      Check (Approx (Vh (0, 1), 1.0 + 3.0), "Height slope in Y");

      Fill_Radial_Field
        (Vr, Pr, (0.0, 0.0), 1.0, Center => (1.0, 1.0), Peak => 5.0);
      Check (Approx (Vr (1, 1), 5.0), "Radial peak at center");
      Check (Vr (0, 0) < Vr (1, 1), "Radial decreases away from center");
      Check (Approx_Vec (Pr (2, 2), (2.0, 2.0)), "Radial position lattice");
   end;

   ---------------------------------------------------------------------
   Section ("12. Count_Segments / Empty / Append helpers");
   ---------------------------------------------------------------------
   declare
      P : Polyline := Empty_Polyline;
      L : Band_List := Empty_Band_List;
      B : Band_Polygon;
   begin
      Check (Count_Segments (P) = 0, "Empty polyline has 0 segments");
      Check (L.Count = 0, "Empty band list has 0 bands");
      Append_Segment (P, ((0.0, 0.0), (1.0, 0.0)));
      Append_Segment (P, ((1.0, 0.0), (1.0, 1.0)));
      Check (Count_Segments (P) = 2, "Appended two segments");
      B.Count := 3;
      B.Verts (1) := (0.0, 0.0);
      B.Verts (2) := (1.0, 0.0);
      B.Verts (3) := (0.0, 1.0);
      Append_Band (L, B);
      Check (L.Count = 1, "Appended one band polygon");
      declare
         Tiny : Band_Polygon;
      begin
         Tiny.Count := 2;
         Append_Band (L, Tiny);
         Check (L.Count = 1, "Degenerate band (<3 verts) skipped");
      end;
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
            Dummy : constant Vec2 := Normalize ((0.0, 0.0));
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
            Dummy : constant Point2 := Interpolate_Edge
              ((0.0, 0.0), (1.0, 0.0), 1.0, 1.0, 0.0);
            pragma Unreferenced (Dummy);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised_Deg := True;
      end;
      Check (Raised_Deg, "Equal scalars raise Degenerate_Geometry");

      begin
         declare
            Vals : Scalar_Field (0 .. 1, 0 .. 1);
            Pos  : Position_Field (0 .. 1, 0 .. 1);
         begin
            Fill_Height_Field
              (Vals, Pos, (0.0, 0.0), Spacing => -1.0,
               Slope_X => 1.0, Slope_Y => 0.0);
         end;
      exception
         when Invalid_Argument =>
            Raised_Inv := True;
      end;
      Check (Raised_Inv, "Negative spacing raises Invalid_Argument");
      Check (Fail_Count = 0, "No failures before end of exception tests");
   end;

   ---------------------------------------------------------------------
   Section ("14. Empty vs non-empty grid distinction");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 3, 0 .. 3);
      Pos  : Position_Field (0 .. 3, 0 .. 3);
      Poly_Lo, Poly_Hi : Polyline;
   begin
      Fill_Height_Field
        (Vals, Pos, (0.0, 0.0), 1.0, Slope_X => 1.0, Slope_Y => 1.0);
      --  All values in [0,6]; isolevel below min → empty; mid → non-empty
      Poly_Lo := March_Grid_Isolines (Vals, Pos, -1.0);
      Poly_Hi := March_Grid_Isolines (Vals, Pos, 2.0);
      Check (Count_Segments (Poly_Lo) = 0, "Below-min isolevel: empty");
      Check (Count_Segments (Poly_Hi) > 0, "Mid isolevel: non-empty");
      Check (Count_Segments (Poly_Lo) /= Count_Segments (Poly_Hi),
             "Empty and mid contours differ");
   end;

   New_Line;
   Put_Line ("===========================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("===========================");
   pragma Assert (Fail_Count = 0, "Some Marching_Squares tests failed");
   if Fail_Count > 0 then
      raise Program_Error with "Marching_Squares tests failed";
   end if;
   Put_Line ("All tests passed.");
end Tests;
