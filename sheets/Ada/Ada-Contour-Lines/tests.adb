--  Standalone test suite for Contour_Lines (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Contour_Lines; use Contour_Lines;

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

   function Approx_L (A, B : Level_Value; Tol : Real := 1.0E-4) return Boolean is
   begin
      return abs (Real (A) - Real (B)) <= Tol;
   end Approx_L;

   function Approx_Vec (A, B : Vec2; Tol : Real := 1.0E-3) return Boolean is
   begin
      return Approx (A.X, B.X, Tol) and then Approx (A.Y, B.Y, Tol);
   end Approx_Vec;

begin
   Put_Line ("Contour_Lines test suite");
   Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers");
   ---------------------------------------------------------------------
   declare
      V  : constant Vec2 := (3.0, 4.0);
      N  : constant Vec2 := Normalize (V);
      D  : constant Real := Dot ((1.0, 0.0), (0.0, 1.0));
      Sm : constant Vec2 := (1.0, 2.0) + (3.0, 4.0);
      Sc : constant Vec2 := 2.0 * (1.0, 1.5);
      Pr : constant Vec2 := Perp ((1.0, 0.0));
   begin
      Check (Approx (Length (V), 5.0), "Length of (3,4) is 5");
      Check (Approx (Length (N), 1.0), "Normalize yields unit length");
      Check (abs (D) <= 1.0E-5, "Dot of orthogonal axes is 0");
      Check (Approx (Sm.X, 4.0) and then Approx (Sm.Y, 6.0),
             "Vector addition");
      Check (Approx (Sc.X, 2.0) and then Approx (Sc.Y, 3.0),
             "Scalar multiply");
      Check (Approx_Vec (Pr, (0.0, 1.0)), "Perp of (1,0) is (0,1)");
   end;

   ---------------------------------------------------------------------
   Section ("2. Contour_Interval / Level_From_Index");
   ---------------------------------------------------------------------
   declare
      N   : constant Natural :=
        Contour_Level_Count (0.0, 100.0, 20.0);
      L0  : constant Level_Value := Level_From_Index (0.0, 20.0, 0);
      L2  : constant Level_Value := Level_From_Index (0.0, 20.0, 2);
      L5  : constant Level_Value := Level_From_Index (0.0, 20.0, 5);
      Int : constant Contour_Interval_Value :=
        Contour_Interval_Of (0.0, 100.0, 6);
   begin
      Check (N = 6, "Levels 0..100 step 20 => 6");
      Check (Approx_L (L0, 0.0), "Index 0 => min level");
      Check (Approx_L (L2, 40.0), "Index 2 => 40");
      Check (Approx_L (L5, 100.0), "Index 5 => max level");
      Check (Approx (Real (Int), 20.0), "Interval_Of 6 levels on 0..100");
   end;

   ---------------------------------------------------------------------
   Section ("3. Sample_Height_Field / Bilinear_Sample");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 2, 0 .. 2);
      Pos  : Position_Field (0 .. 2, 0 .. 2);
      Mid  : Real;
      Corner : Real;
   begin
      Fill_Hill_Field
        (Vals, Pos, Origin => (0.0, 0.0), Spacing => 1.0,
         Center => (1.0, 1.0), Peak => 4.0, Width => 2.0);
      Corner := Sample_Height_Field (Vals, 1, 1);
      Check (Approx (Corner, 4.0, 0.05), "Peak sample at hill center");
      Check (Sample_Height_Field (Vals, 0, 0) < Corner,
             "Corner lower than peak");
      Mid := Bilinear_Sample (Vals, Pos, (1.0, 1.0));
      Check (Approx (Mid, Corner, 0.05), "Bilinear at node matches sample");
      declare
         Edge : constant Real := Bilinear_Sample (Vals, Pos, (0.5, 1.0));
      begin
         Check (Edge > 0.0 and then Edge < Corner + 0.1,
                "Bilinear edge between nodes is positive");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("4. Gradient_2D / Gradient_Perpendicular_Check");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 4, 0 .. 4);
      Pos  : Position_Field (0 .. 4, 0 .. 4);
      G    : Vec2;
      Mag  : Non_Negative;
      Tangent : Vec2;
   begin
      --  Planar field f = X via ridge-like fill along Y=2 is not planar;
      --  build manually: f = X
      for I in Vals'Range (1) loop
         for J in Vals'Range (2) loop
            Pos (I, J) := (Real (I), Real (J));
            Vals (I, J) := Real (I);
         end loop;
      end loop;
      G := Gradient_2D (Vals, Pos, 2, 2);
      Mag := Gradient_Magnitude (G);
      Check (Approx (G.X, 1.0, 0.05), "Gradient of f=X has Gx≈1");
      Check (Approx (G.Y, 0.0, 0.05), "Gradient of f=X has Gy≈0");
      Check (Approx (Mag, 1.0, 0.05), "Gradient magnitude ≈ 1");
      --  Contour of f=X is vertical line → tangent (0,1)
      Tangent := (0.0, 1.0);
      Check (Gradient_Perpendicular_Check (G, Tangent, 1.0E-2),
             "Gradient perpendicular to vertical contour");
      Check (not Gradient_Perpendicular_Check (G, (1.0, 0.0), 1.0E-2),
             "Gradient not perpendicular to parallel tangent");
   end;

   ---------------------------------------------------------------------
   Section ("5. Trace_Isoline_Cell");
   ---------------------------------------------------------------------
   declare
      TL : constant Point2 := (0.0, 1.0);
      TR : constant Point2 := (1.0, 1.0);
      BR : constant Point2 := (1.0, 0.0);
      BL : constant Point2 := (0.0, 0.0);
      Segs : Small_Segment_List;
      N : Natural;
   begin
      Trace_Isoline_Cell
        (TL, TR, BR, BL, 0.0, 0.0, 0.0, 0.0, 0.5, Segs, N);
      Check (N = 0, "All-below cell: no segments");

      Trace_Isoline_Cell
        (TL, TR, BR, BL, 1.0, 1.0, 1.0, 1.0, 0.5, Segs, N);
      Check (N = 0, "All-above cell: no segments");

      Trace_Isoline_Cell
        (TL, TR, BR, BL, 0.0, 0.0, 0.0, 1.0, 0.5, Segs, N);
      Check (N = 1, "Single corner above: one segment");
      Check (Distance_Between (Segs (1).A, Segs (1).B) > 0.0,
             "Cell segment has positive length");

      Trace_Isoline_Cell
        (TL, TR, BR, BL, 0.0, 1.0, 0.0, 1.0, 0.5, Segs, N);
      Check (N = 2, "Saddle case emits two segments");
   end;

   ---------------------------------------------------------------------
   Section ("6. Extract_Isolines_At_Level");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 6, 0 .. 6);
      Pos  : Position_Field (0 .. 6, 0 .. 6);
      Poly : Polyline;
   begin
      Fill_Hill_Field
        (Vals, Pos, (0.0, 0.0), 1.0, Center => (3.0, 3.0),
         Peak => 10.0, Width => 2.5);
      Poly := Extract_Isolines_At_Level (Vals, Pos, 5.0);
      Check (Count_Segments (Poly) > 0, "Hill isoline at mid level");
      Check (Approx_L (Poly.Level, 5.0), "Polyline stores level");
      Check (Total_Length (Poly) > 0.0, "Isoline total length positive");
      declare
         Empty : constant Polyline :=
           Extract_Isolines_At_Level (Vals, Pos, 50.0);
      begin
         Check (Count_Segments (Empty) = 0, "Above-peak level empty");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Build_Contour_Map");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 8, 0 .. 8);
      Pos  : Position_Field (0 .. 8, 0 .. 8);
      Map  : Contour_Map;
   begin
      Fill_Hill_Field
        (Vals, Pos, (0.0, 0.0), 1.0, Center => (4.0, 4.0),
         Peak => 10.0, Width => 3.0);
      Map := Build_Contour_Map (Vals, Pos, 2.0, 8.0, 2.0);
      Check (Contour_Map_Level_Count (Map) = 4, "Levels 2,4,6,8 => 4");
      Check (Approx_L (Map.Levels (1), 2.0), "First map level is 2");
      Check (Approx_L (Map.Levels (4), 8.0), "Last map level is 8");
      Check (Map.Contours (2).Count > 0, "Mid contour non-empty");
      Check (Empty_Contour_Map.Count = 0, "Empty contour map");
   end;

   ---------------------------------------------------------------------
   Section ("8. Classify_Spacing / Spacing_From_Gradient");
   ---------------------------------------------------------------------
   declare
      Sp_Flat : constant Slope_Class := Classify_Spacing (0.0);
      Sp_Gen  : constant Slope_Class := Classify_Spacing (0.1);
      Sp_Mod  : constant Slope_Class := Classify_Spacing (0.5);
      Sp_Stp  : constant Slope_Class := Classify_Spacing (2.0);
      Sp_Clf  : constant Slope_Class := Classify_Spacing (10.0);
      Dist    : constant Non_Negative :=
        Spacing_From_Gradient (2.0, 10.0);
   begin
      Check (Sp_Flat = Flat, "Zero gradient => Flat");
      Check (Sp_Gen = Gentle, "Small gradient => Gentle");
      Check (Sp_Mod = Moderate, "Mid gradient => Moderate");
      Check (Sp_Stp = Steep, "Large gradient => Steep");
      Check (Sp_Clf = Cliff, "Huge gradient => Cliff");
      Check (Approx (Dist, 5.0), "Spacing = interval / |grad|");
   end;

   ---------------------------------------------------------------------
   Section ("9. Closest_Contour_Label / Format helpers");
   ---------------------------------------------------------------------
   declare
      Near : constant Level_Value :=
        Closest_Contour_Label (47.0, 0.0, 20.0);
      Lab  : constant String := Format_Level_Label (100.0, Contour);
      Iso  : constant String := Format_Level_Label (1013.0, Isobar);
      Nm   : constant String := Isoline_Kind_Name (Isotherm);
   begin
      Check (Approx_L (Near, 40.0) or else Approx_L (Near, 60.0),
             "Closest contour to 47 among 20-interval");
      Check (Approx_L (Closest_Contour_Label (50.0, 0.0, 20.0), 40.0)
               or else Approx_L (Closest_Contour_Label (50.0, 0.0, 20.0), 60.0),
             "Closest contour to exact midpoint");
      Check (Lab'Length > 5, "Format contour label non-empty");
      Check (Iso'Length > 5, "Format isobar label non-empty");
      Check (Nm = "isotherm", "Isoline_Kind_Name isotherm");
      Check (Isoline_Kind_Name (Isohyet) = "isohyet", "isohyet name");
   end;

   ---------------------------------------------------------------------
   Section ("10. Profile_Along_Line");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 4, 0 .. 4);
      Pos  : Position_Field (0 .. 4, 0 .. 4);
      Prof : Transect_Profile;
   begin
      Fill_Hill_Field
        (Vals, Pos, (0.0, 0.0), 1.0, Center => (2.0, 2.0),
         Peak => 9.0, Width => 2.0);
      Prof := Profile_Along_Line
        (Vals, Pos, A => (0.0, 2.0), B => (4.0, 2.0), Samples => 5);
      Check (Prof.Count = 5, "Profile has requested samples");
      Check (Approx_Vec (Prof.Points (1), (0.0, 2.0)), "Profile starts at A");
      Check (Approx_Vec (Prof.Points (5), (4.0, 2.0)), "Profile ends at B");
      --  Peak should be near middle sample
      Check (Prof.Values (3) >= Prof.Values (1)
               and then Prof.Values (3) >= Prof.Values (5),
             "Hill transect peaks near center");
      Check (Empty_Profile.Count = 0, "Empty profile");
   end;

   ---------------------------------------------------------------------
   Section ("11. Fill_Hill_Field / Fill_Valley_Field / Fill_Ridge_Field");
   ---------------------------------------------------------------------
   declare
      Vh : Scalar_Field (0 .. 4, 0 .. 4);
      Ph : Position_Field (0 .. 4, 0 .. 4);
      Vv : Scalar_Field (0 .. 4, 0 .. 4);
      Pv : Position_Field (0 .. 4, 0 .. 4);
      Vr : Scalar_Field (0 .. 4, 0 .. 4);
      Pr : Position_Field (0 .. 4, 0 .. 4);
   begin
      Fill_Hill_Field
        (Vh, Ph, (0.0, 0.0), 1.0, Center => (2.0, 2.0), Peak => 5.0);
      Check (Approx (Vh (2, 2), 5.0, 0.05), "Hill peak at center");
      Check (Vh (0, 0) < Vh (2, 2), "Hill falls off from center");
      Check (Approx_Vec (Ph (0, 0), (0.0, 0.0)), "Hill origin position");

      Fill_Valley_Field
        (Vv, Pv, (0.0, 0.0), 1.0, Center => (2.0, 2.0),
         Floor_H => 0.0, Depth => 6.0, Width => 2.0);
      Check (Vv (2, 2) < Vv (0, 0), "Valley lower at center");
      Check (Vv (2, 2) < 0.0, "Valley center below floor");

      Fill_Ridge_Field
        (Vr, Pr, (0.0, 0.0), 1.0, Axis_Y => 2.0, Peak => 7.0, Width => 1.5);
      Check (Approx (Vr (0, 2), 7.0, 0.1), "Ridge peak along axis");
      Check (Vr (0, 2) > Vr (0, 0), "Ridge higher on axis than off");
      Check (Approx (Vr (4, 2), Vr (0, 2), 0.05),
             "Ridge roughly constant along X");
   end;

   ---------------------------------------------------------------------
   Section ("12. Polyline helpers / Append_Segment");
   ---------------------------------------------------------------------
   declare
      P : Polyline := Empty_Polyline;
   begin
      Check (Count_Segments (P) = 0, "Empty polyline");
      Append_Segment (P, ((0.0, 0.0), (1.0, 0.0)));
      Append_Segment (P, ((1.0, 0.0), (1.0, 1.0)));
      Check (Count_Segments (P) = 2, "Appended two segments");
      Check (Approx (Total_Length (P), 2.0), "Total length is 2");
      Check (Clamp (5.0, 0.0, 1.0) = 1.0, "Clamp upper");
      Check (Clamp (-1.0, 0.0, 1.0) = 0.0, "Clamp lower");
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

      begin
         declare
            N : constant Natural :=
              Contour_Level_Count (0.0, 1.0, Contour_Interval_Value (-1.0));
            pragma Unreferenced (N);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised_Inv := True;
      end;
      Check (Raised_Inv, "Negative interval raises Invalid_Argument");

      Raised_Inv := False;
      begin
         declare
            Vals : Scalar_Field (0 .. 1, 0 .. 1);
            Pos  : Position_Field (0 .. 1, 0 .. 1);
         begin
            Fill_Hill_Field
              (Vals, Pos, (0.0, 0.0), Spacing => -1.0,
               Center => (0.0, 0.0));
         end;
      exception
         when Invalid_Argument =>
            Raised_Inv := True;
      end;
      Check (Raised_Inv, "Negative spacing raises Invalid_Argument");
      Check (Fail_Count = 0, "No failures before end of exception tests");
   end;

   ---------------------------------------------------------------------
   Section ("14. Valley / ridge contour maps");
   ---------------------------------------------------------------------
   declare
      Vals : Scalar_Field (0 .. 6, 0 .. 6);
      Pos  : Position_Field (0 .. 6, 0 .. 6);
      Map  : Contour_Map;
      Poly : Polyline;
   begin
      Fill_Valley_Field
        (Vals, Pos, (0.0, 0.0), 1.0, Center => (3.0, 3.0),
         Floor_H => 0.0, Depth => 8.0, Width => 2.5);
      Map := Build_Contour_Map (Vals, Pos, -6.0, -2.0, 2.0);
      Check (Contour_Map_Level_Count (Map) >= 2, "Valley map has levels");
      Check (Map.Contours (1).Count > 0 or else Map.Contours (2).Count > 0,
             "Valley contours non-empty at some level");

      Fill_Ridge_Field
        (Vals, Pos, (0.0, 0.0), 1.0, Axis_Y => 3.0, Peak => 8.0, Width => 1.5);
      Poly := Extract_Isolines_At_Level (Vals, Pos, 4.0);
      Check (Count_Segments (Poly) > 0, "Ridge isoline non-empty");
      Check (Total_Length (Poly) > 2.0, "Ridge isoline spans length");
   end;

   New_Line;
   Put_Line ("========================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("========================");
   pragma Assert (Fail_Count = 0, "Some Contour_Lines tests failed");
   if Fail_Count > 0 then
      raise Program_Error with "Contour_Lines tests failed";
   end if;
   Put_Line ("All tests passed.");
end Tests;
