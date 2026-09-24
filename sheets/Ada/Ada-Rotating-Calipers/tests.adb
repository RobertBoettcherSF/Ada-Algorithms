--  Standalone test suite for Rotating_Calipers (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Rotating_Calipers; use Rotating_Calipers;

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

   function Raised_Invalid_Diameter (Poly : Polygon) return Boolean is
      D : Real;
   begin
      D := Diameter (Poly);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Diameter;

   function Raised_Invalid_Width (Poly : Polygon) return Boolean is
      W : Real;
   begin
      W := Width (Poly);
      pragma Unreferenced (W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Width;

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

   function Raised_Invalid_Pairs (Poly : Polygon) return Boolean is
      L : Antipodal_List;
   begin
      L := Antipodal_Pairs (Poly);
      pragma Unreferenced (L);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Pairs;

   function Raised_Invalid_Rect (Poly : Polygon) return Boolean is
      B : Bounding_Rect;
   begin
      B := Min_Area_Rect (Poly);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Rect;

begin
   Ada.Text_IO.Put_Line ("Rotating_Calipers tests");
   Ada.Text_IO.Put_Line ("=======================");

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
   Section ("2. Unit square diameter / width");
   ------------------------------------------------------------------
   declare
      Sq : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      D, W : Real;
      Ep : Antipodal_Pair;
      L  : Antipodal_List;
      Sqrt2 : constant Real := Real (Math.Sqrt (2.0));
   begin
      Check (Is_Convex (Sq), "unit square Is_Convex");
      Check (Is_CCW (Sq), "unit square Is_CCW");
      D := Diameter (Sq);
      Check (Near (D, Sqrt2, R (1.0E-6)), "unit square Diameter = √2");
      Check (Near (Diameter_Squared (Sq), R (2.0), R (1.0E-6)),
             "unit square Diameter_Squared = 2");
      Check (Near (D, Brute_Diameter (Sq), R (1.0E-6)),
             "unit square Diameter = brute");
      W := Width (Sq);
      Check (Near (W, R (1.0), R (1.0E-6)), "unit square Width = 1");
      Check (Near (W, Brute_Width (Sq), R (1.0E-6)),
             "unit square Width = brute");
      Ep := Diameter_Endpoints (Sq);
      Check (Near (Dist (Sq (Ep.I), Sq (Ep.J)), Sqrt2, R (1.0E-6)),
             "endpoints realize √2");
      L := Antipodal_Pairs (Sq);
      Check (Pair_Count_Of (L) >= 4, "square has >= 4 antipodal pairs");
      Check (Pair_Count_Of (L) <= Max_Pairs, "pairs within Max_Pairs");
   end;

   ------------------------------------------------------------------
   Section ("3. Rectangle 4×3");
   ------------------------------------------------------------------
   declare
      Rect : constant Polygon :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 3.0), P (0.0, 3.0)];
      D, W : Real;
   begin
      Check (Is_Convex (Rect), "4x3 rect Is_Convex");
      D := Diameter (Rect);
      Check (Near (D, R (5.0), R (1.0E-6)), "4x3 rect Diameter = 5");
      Check (Near (D, Brute_Diameter (Rect), R (1.0E-6)),
             "4x3 rect Diameter = brute");
      W := Width (Rect);
      Check (Near (W, R (3.0), R (1.0E-6)), "4x3 rect Width = 3");
      Check (Near (W, Brute_Width (Rect), R (1.0E-6)),
             "4x3 rect Width = brute");
   end;

   ------------------------------------------------------------------
   Section ("4. Equilateral triangle");
   ------------------------------------------------------------------
   declare
      Side : constant Real := 2.0;
      H    : constant Real := Real (Math.Sqrt (3.0));
      Tri  : constant Polygon :=
        [P (0.0, 0.0), P (Side, 0.0), P (Side / 2.0, H)];
      D, W : Real;
      Expected_W : constant Real := H;  --  altitude = width for equilateral
   begin
      Check (Is_Convex (Tri), "equilateral Is_Convex");
      Check (Is_CCW (Tri), "equilateral Is_CCW");
      D := Diameter (Tri);
      Check (Near (D, Side, R (1.0E-6)), "equilateral Diameter = side");
      Check (Near (D, Brute_Diameter (Tri), R (1.0E-6)),
             "equilateral Diameter = brute");
      W := Width (Tri);
      Check (Near (W, Expected_W, R (1.0E-5)),
             "equilateral Width = altitude");
      Check (Near (W, Brute_Width (Tri), R (1.0E-5)),
             "equilateral Width = brute");
   end;

   ------------------------------------------------------------------
   Section ("5. Regular pentagon / hexagon");
   ------------------------------------------------------------------
   declare
      Gon5 : Polygon (1 .. 5);
      Gon6 : Polygon (1 .. 6);
      Ang  : Long_Float;
      D5, D6, W5, W6 : Real;
      Brute_D5, Brute_D6 : Real;
   begin
      for I in Gon5'Range loop
         Ang := Long_Float (I - 1) * (2.0 * Ada.Numerics.Pi / 5.0);
         Gon5 (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
      end loop;
      for I in Gon6'Range loop
         Ang := Long_Float (I - 1) * (2.0 * Ada.Numerics.Pi / 6.0);
         Gon6 (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
      end loop;

      Check (Is_Convex (Gon5), "pentagon Is_Convex");
      Check (Is_CCW (Gon5), "pentagon Is_CCW");
      D5 := Diameter (Gon5);
      Brute_D5 := Brute_Diameter (Gon5);
      Check (Near (D5, Brute_D5, R (1.0E-5)), "pentagon Diameter = brute");
      W5 := Width (Gon5);
      Check (Near (W5, Brute_Width (Gon5), R (1.0E-5)),
             "pentagon Width = brute");
      Check (W5 < D5, "pentagon Width < Diameter");

      Check (Is_Convex (Gon6), "hexagon Is_Convex");
      D6 := Diameter (Gon6);
      Brute_D6 := Brute_Diameter (Gon6);
      Check (Near (D6, Brute_D6, R (1.0E-5)), "hexagon Diameter = brute");
      --  Regular hexagon inscribed in unit circle: diameter = 2.
      Check (Near (D6, R (2.0), R (1.0E-5)), "hexagon Diameter = 2");
      W6 := Width (Gon6);
      Check (Near (W6, Brute_Width (Gon6), R (1.0E-5)),
             "hexagon Width = brute");
      --  Flat-to-flat width of unit circumradius hex = √3.
      Check (Near (W6, Real (Math.Sqrt (3.0)), R (1.0E-5)),
             "hexagon Width = √3");
   end;

   ------------------------------------------------------------------
   Section ("6. CW input normalized by Ensure_Convex_CCW");
   ------------------------------------------------------------------
   declare
      CW_Sq : constant Polygon :=
        [P (0.0, 0.0), P (0.0, 1.0), P (1.0, 1.0), P (1.0, 0.0)];
      Norm  : constant Polygon := Ensure_Convex_CCW (CW_Sq);
      Sqrt2 : constant Real := Real (Math.Sqrt (2.0));
   begin
      Check (Signed_Area (CW_Sq) < 0.0, "CW square signed < 0");
      Check (Is_Convex (CW_Sq), "CW square still Is_Convex");
      Check (Is_CCW (Norm), "Ensure_Convex_CCW yields CCW");
      Check (Near (Diameter (CW_Sq), Sqrt2, R (1.0E-6)),
             "CW square Diameter = √2");
      Check (Near (Width (CW_Sq), R (1.0), R (1.0E-6)),
             "CW square Width = 1");
      Check (Near (Diameter (CW_Sq), Brute_Diameter (CW_Sq), R (1.0E-6)),
             "CW Diameter = brute");
   end;

   ------------------------------------------------------------------
   Section ("7. Non-convex / degenerate → Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Too_Small : constant Polygon := [P (0.0, 0.0), P (1.0, 0.0)];
      Concave   : constant Polygon :=
        [P (0.0, 0.0), P (3.0, 0.0), P (1.0, 1.0), P (3.0, 2.0), P (0.0, 2.0)];
      --  Arrow / dart: reflex at (1,1)
      Collinear : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0), P (1.0, 1.0)];
      --  wait, last makes a triangle with base collinear triple on bottom
      Flat : constant Polygon :=
        [P (0.0, 0.0), P (2.0, 0.0), P (1.0, 0.0)];  --  collinear
   begin
      Check (Raised_Invalid_Diameter (Too_Small), "n=2 Diameter raises");
      Check (Raised_Invalid_Width (Too_Small), "n=2 Width raises");
      Check (Raised_Invalid_Ensure (Too_Small), "n=2 Ensure raises");
      Check (Raised_Invalid_Pairs (Too_Small), "n=2 Pairs raises");
      Check (Raised_Invalid_Rect (Too_Small), "n=2 Rect raises");
      Check (not Is_Convex (Concave), "concave not Is_Convex");
      Check (Raised_Invalid_Diameter (Concave), "concave Diameter raises");
      Check (Raised_Invalid_Ensure (Concave), "concave Ensure raises");
      Check (Raised_Invalid_Diameter (Flat), "collinear Diameter raises");
      Check (Raised_Invalid_Ensure (Flat), "collinear Ensure raises");
      pragma Unreferenced (Collinear);
   end;

   ------------------------------------------------------------------
   Section ("8. Antipodal pairs cover diameter");
   ------------------------------------------------------------------
   declare
      Sq : constant Polygon :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      L  : constant Antipodal_List := Antipodal_Pairs (Sq);
      D  : constant Real := Diameter (Sq);
      Found : Boolean := False;
      Pair  : Antipodal_Pair;
      Dense : constant Polygon := Ensure_Convex_CCW (Sq);
   begin
      Check (Pair_Count_Of (L) > 0, "antipodal list non-empty");
      for K in 1 .. Pair_Count_Of (L) loop
         Pair := Get_Pair (L, K);
         if Near (Dist (Dense (Pair.I), Dense (Pair.J)), D, R (1.0E-6)) then
            Found := True;
         end if;
         Check (Pair.I in Dense'Range and then Pair.J in Dense'Range,
                "pair indices in range #" & Pair_Index'Image (K));
      end loop;
      Check (Found, "some antipodal pair realizes diameter");
   end;

   ------------------------------------------------------------------
   Section ("9. Min_Area_Rect sketch");
   ------------------------------------------------------------------
   declare
      Sq : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Rect : constant Polygon :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 2.0), P (0.0, 2.0)];
      B1, B2 : Bounding_Rect;
   begin
      B1 := Min_Area_Rect (Sq);
      Check (Near (B1.Area, R (1.0), R (1.0E-5)), "square OBB area = 1");
      Check (Near (B1.Width * B1.Height, B1.Area, R (1.0E-5)),
             "square OBB area = w*h");
      B2 := Min_Area_Rect (Rect);
      Check (Near (B2.Area, R (8.0), R (1.0E-5)), "4x2 rect OBB area = 8");
      Check (B2.Area + R (0.01) >= abs (Signed_Area (Rect)), "OBB covers rect");
   end;

   ------------------------------------------------------------------
   Section ("10. Shifted / scaled polygons");
   ------------------------------------------------------------------
   declare
      Base : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Shifted : constant Polygon :=
        [P (10.0, 20.0), P (11.0, 20.0), P (11.0, 21.0), P (10.0, 21.0)];
      Scaled : constant Polygon :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 3.0), P (0.0, 3.0)];
      Sqrt2 : constant Real := Real (Math.Sqrt (2.0));
   begin
      Check (Near (Diameter (Shifted), Diameter (Base), R (1.0E-6)),
             "translation preserves Diameter");
      Check (Near (Width (Shifted), Width (Base), R (1.0E-6)),
             "translation preserves Width");
      Check (Near (Diameter (Scaled), R (3.0) * Sqrt2, R (1.0E-6)),
             "3x scale Diameter = 3√2");
      Check (Near (Width (Scaled), R (3.0), R (1.0E-6)),
             "3x scale Width = 3");
      Check (Near (Diameter (Scaled), Brute_Diameter (Scaled), R (1.0E-6)),
             "scaled Diameter = brute");
   end;

   ------------------------------------------------------------------
   Section ("11. Irregular convex pentagon vs brute");
   ------------------------------------------------------------------
   declare
      Irr : constant Polygon :=
        [P (0.0, 0.0), P (4.0, 0.0), P (5.0, 2.0), P (3.0, 4.0), P (0.0, 3.0)];
      D, W : Real;
   begin
      Check (Is_Convex (Irr), "irregular pentagon Is_Convex");
      Check (Is_CCW (Irr), "irregular pentagon Is_CCW");
      D := Diameter (Irr);
      W := Width (Irr);
      Check (Near (D, Brute_Diameter (Irr), R (1.0E-5)),
             "irregular Diameter = brute");
      Check (Near (W, Brute_Width (Irr), R (1.0E-5)),
             "irregular Width = brute");
      Check (W < D, "irregular Width < Diameter");
      Check (D > R (5.0), "irregular Diameter > 5");
   end;

   ------------------------------------------------------------------
   Section ("12. Regular 12-gon");
   ------------------------------------------------------------------
   declare
      Gon : Polygon (1 .. 12);
      Ang : Long_Float;
      D, W : Real;
   begin
      for I in Gon'Range loop
         Ang := Long_Float (I - 1) * (2.0 * Ada.Numerics.Pi / 12.0);
         Gon (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
      end loop;
      Check (Gon'Length <= Max_Vertices, "12-gon within Max_Vertices");
      Check (Is_Convex (Gon), "12-gon Is_Convex");
      D := Diameter (Gon);
      W := Width (Gon);
      Check (Near (D, Brute_Diameter (Gon), R (1.0E-5)),
             "12-gon Diameter = brute");
      Check (Near (W, Brute_Width (Gon), R (1.0E-5)),
             "12-gon Width = brute");
      Check (Near (D, R (2.0), R (1.0E-4)), "12-gon Diameter ≈ 2");
      Check (W < D, "12-gon Width < Diameter");
      Check (Pair_Count_Of (Antipodal_Pairs (Gon)) >= 12,
             "12-gon has >= 12 antipodal pairs");
   end;

   ------------------------------------------------------------------
   Section ("13. Right triangle 3-4-5");
   ------------------------------------------------------------------
   declare
      Tri : constant Polygon :=
        [P (0.0, 0.0), P (3.0, 0.0), P (0.0, 4.0)];
      D, W : Real;
   begin
      D := Diameter (Tri);
      Check (Near (D, R (5.0), R (1.0E-6)), "3-4-5 Diameter = 5");
      Check (Near (D, Brute_Diameter (Tri), R (1.0E-6)),
             "3-4-5 Diameter = brute");
      W := Width (Tri);
      Check (Near (W, Brute_Width (Tri), R (1.0E-6)),
             "3-4-5 Width = brute");
      --  Width of right triangle = min altitude = (3*4)/5 = 2.4 to hypotenuse
      Check (Near (W, R (2.4), R (1.0E-5)), "3-4-5 Width = 2.4");
   end;

   ------------------------------------------------------------------
   Section ("14. Diameter_Endpoints consistency");
   ------------------------------------------------------------------
   declare
      Poly : constant Polygon :=
        [P (1.0, 1.0), P (5.0, 0.0), P (6.0, 3.0), P (3.0, 5.0), P (0.0, 3.0)];
      Ep : Antipodal_Pair;
      Dense : Polygon (1 .. 5);
   begin
      Check (Is_Convex (Poly), "kite-like Is_Convex");
      Dense := Ensure_Convex_CCW (Poly);
      Ep := Diameter_Endpoints (Poly);
      Check (Near (Dist (Dense (Ep.I), Dense (Ep.J)), Diameter (Poly),
                   R (1.0E-6)),
             "endpoints distance = Diameter");
      Check (Near (Diameter (Poly), Brute_Diameter (Poly), R (1.0E-5)),
             "kite Diameter = brute");
   end;

   ------------------------------------------------------------------
   Section ("15. Max_Vertices capacity note");
   ------------------------------------------------------------------
   declare
      Gon : Polygon (1 .. 24);
      Ang : Long_Float;
   begin
      for I in Gon'Range loop
         Ang := Long_Float (I - 1) * (2.0 * Ada.Numerics.Pi / 24.0);
         Gon (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
      end loop;
      Check (Gon'Length <= Max_Vertices, "24-gon within Max_Vertices");
      Check (Near (Diameter (Gon), Brute_Diameter (Gon), R (1.0E-4)),
             "24-gon Diameter = brute");
      Check (Near (Width (Gon), Brute_Width (Gon), R (1.0E-4)),
             "24-gon Width = brute");
      Check (Min_Area_Rect (Gon).Area >= R (2.0),
             "24-gon OBB area >= 2");
   end;

   ------------------------------------------------------------------
   -- Summary
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
end Tests;
