--  Standalone test suite for Shoelace_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Shoelace_Algorithm; use Shoelace_Algorithm;

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

   function Raised_Invalid_Area (Poly : Polygon) return Boolean is
      A : Real;
   begin
      A := Area (Poly);
      pragma Unreferenced (A);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Area;

   function Raised_Invalid_Signed (Poly : Polygon) return Boolean is
      A : Real;
   begin
      A := Signed_Area (Poly);
      pragma Unreferenced (A);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Signed;

   function Raised_Invalid_Centroid (Poly : Polygon) return Boolean is
      C : Point;
   begin
      C := Centroid (Poly);
      pragma Unreferenced (C);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Centroid;

   function Raised_Invalid_CCW (Poly : Polygon) return Boolean is
      B : Boolean;
   begin
      B := Is_CCW (Poly);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_CCW;

   function Raised_Invalid_Det (Poly : Polygon) return Boolean is
      D : Real;
   begin
      D := Determinant_Sum (Poly);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Det;

begin
   Ada.Text_IO.Put_Line ("Shoelace_Algorithm tests");
   Ada.Text_IO.Put_Line ("========================");

   ------------------------------------------------------------------
   Section ("1. Near / Near_Point");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (R (2.0), R (2.0), R (0.0)), "Near exact Tol=0");
   Check (not Near (R (2.0), R (2.1), R (0.05)), "not Near outside Tol");

   ------------------------------------------------------------------
   Section ("2. Unit square (area 1)");
   ------------------------------------------------------------------
   declare
      Sq : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      C  : Point;
   begin
      Check (Near (Area (Sq), R (1.0)), "unit square Area = 1");
      Check (Near (Signed_Area (Sq), R (1.0)), "unit square Signed_Area = +1");
      Check (Near (Determinant_Sum (Sq), R (2.0)), "unit square det sum = 2");
      Check (Is_CCW (Sq), "unit square Is_CCW");
      Check (not Is_CW (Sq), "unit square not Is_CW");
      C := Centroid (Sq);
      Check (Near_Point (C, P (0.5, 0.5)), "unit square centroid (0.5,0.5)");
   end;

   ------------------------------------------------------------------
   Section ("3. Triangle");
   ------------------------------------------------------------------
   declare
      Tri : constant Polygon :=
        [P (0.0, 0.0), P (2.0, 0.0), P (0.0, 2.0)];
      C   : Point;
   begin
      Check (Near (Area (Tri), R (2.0)), "right triangle Area = 2");
      Check (Near (Signed_Area (Tri), R (2.0)), "triangle Signed_Area = +2");
      Check (Is_CCW (Tri), "triangle Is_CCW");
      C := Centroid (Tri);
      Check (Near_Point (C, P (2.0 / 3.0, 2.0 / 3.0)),
             "triangle centroid (2/3,2/3)");
   end;

   declare
      Equ : constant Polygon :=
        [P (0.0, 0.0), P (2.0, 0.0), P (1.0, Real (Math.Sqrt (3.0)))];
      Expected : constant Real := Real (Math.Sqrt (3.0));
   begin
      Check (Near (Area (Equ), Expected, R (1.0E-6)),
             "equilateral side-2 Area = sqrt(3)");
      Check (Is_CCW (Equ), "equilateral Is_CCW");
   end;

   ------------------------------------------------------------------
   Section ("4. Rectangle");
   ------------------------------------------------------------------
   declare
      Rect : constant Polygon :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 3.0), P (0.0, 3.0)];
      C    : Point;
   begin
      Check (Near (Area (Rect), R (12.0)), "4x3 rectangle Area = 12");
      Check (Near (Signed_Area (Rect), R (12.0)), "rectangle Signed_Area = +12");
      Check (Near (Determinant_Sum (Rect), R (24.0)), "rectangle det = 24");
      Check (Is_CCW (Rect), "rectangle Is_CCW");
      C := Centroid (Rect);
      Check (Near_Point (C, P (2.0, 1.5)), "rectangle centroid (2,1.5)");
   end;

   declare
      Tall : constant Polygon :=
        [P (1.0, 2.0), P (3.0, 2.0), P (3.0, 7.0), P (1.0, 7.0)];
   begin
      Check (Near (Area (Tall), R (10.0)), "2x5 shifted rect Area = 10");
      Check (Near_Point (Centroid (Tall), P (2.0, 4.5)),
             "shifted rect centroid (2,4.5)");
   end;

   ------------------------------------------------------------------
   Section ("5. CW vs CCW");
   ------------------------------------------------------------------
   declare
      CCW_Sq : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      CW_Sq  : constant Polygon :=
        [P (0.0, 0.0), P (0.0, 1.0), P (1.0, 1.0), P (1.0, 0.0)];
   begin
      Check (Signed_Area (CCW_Sq) > 0.0, "CCW square signed > 0");
      Check (Signed_Area (CW_Sq) < 0.0, "CW square signed < 0");
      Check (Near (Area (CCW_Sq), Area (CW_Sq)), "CW/CCW same absolute area");
      Check (Near (Area (CW_Sq), R (1.0)), "CW square Area = 1");
      Check (Is_CCW (CCW_Sq) and not Is_CW (CCW_Sq), "CCW flags");
      Check (Is_CW (CW_Sq) and not Is_CCW (CW_Sq), "CW flags");
      Check (Near (Signed_Area (CW_Sq), R (-1.0)), "CW Signed_Area = -1");
      Check (Near_Point (Centroid (CCW_Sq), Centroid (CW_Sq)),
             "CW/CCW same centroid");
   end;

   declare
      Tri_CW : constant Polygon :=
        [P (0.0, 0.0), P (0.0, 2.0), P (2.0, 0.0)];
   begin
      Check (Near (Signed_Area (Tri_CW), R (-2.0)), "CW triangle Signed = -2");
      Check (Near (Area (Tri_CW), R (2.0)), "CW triangle Area = 2");
      Check (Is_CW (Tri_CW), "CW triangle Is_CW");
   end;

   ------------------------------------------------------------------
   Section ("6. Wikipedia pentagon (A = 16.5)");
   ------------------------------------------------------------------
   declare
      Pent : constant Polygon :=
        [P (1.0, 6.0), P (3.0, 1.0), P (7.0, 2.0),
         P (4.0, 4.0), P (8.0, 5.0)];
      C    : Point;
   begin
      Check (Near (Determinant_Sum (Pent), R (33.0)), "wiki pentagon 2A = 33");
      Check (Near (Signed_Area (Pent), R (16.5)), "wiki pentagon Signed = 16.5");
      Check (Near (Area (Pent), R (16.5)), "wiki pentagon Area = 16.5");
      Check (Is_CCW (Pent), "wiki pentagon Is_CCW");
      C := Centroid (Pent);
      Check (Near (C.X, R (3.888888888888889), R (1.0E-6)),
             "wiki pentagon Cx ≈ 3.889");
      Check (Near (C.Y, R (3.666666666666667), R (1.0E-6)),
             "wiki pentagon Cy ≈ 3.667");
   end;

   ------------------------------------------------------------------
   Section ("7. Regular-ish shapes");
   ------------------------------------------------------------------
   declare
      --  Regular hexagon, side length 1, centered at origin.
      Hex : Polygon (1 .. 6);
      Expected : constant Real :=
        3.0 * Real (Math.Sqrt (3.0)) / 2.0;  --  (3√3)/2
      Two_Pi_Over_6 : constant Long_Float :=
        2.0 * Ada.Numerics.Pi / 6.0;
   begin
      for I in Hex'Range loop
         declare
            Ang : constant Long_Float := Long_Float (I - 1) * Two_Pi_Over_6;
         begin
            Hex (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
         end;
      end loop;
      Check (Near (Area (Hex), Expected, R (1.0E-6)),
             "regular hexagon Area = 3√3/2");
      Check (Is_CCW (Hex), "regular hexagon Is_CCW");
      Check (Near_Point (Centroid (Hex), P (0.0, 0.0), R (1.0E-6)),
             "regular hexagon centroid ≈ origin");
   end;

   declare
      --  Axis-aligned diamond (rhombus / square rotated), CCW.
      Dia : constant Polygon :=
        [P (0.0, 1.0), P (-1.0, 0.0), P (0.0, -1.0), P (1.0, 0.0)];
   begin
      Check (Near (Area (Dia), R (2.0)), "diamond Area = 2");
      Check (Is_CCW (Dia), "diamond Is_CCW");
      Check (Near_Point (Centroid (Dia), P (0.0, 0.0)),
             "diamond centroid origin");
   end;

   declare
      --  Regular octagon approximation from unit circle samples.
      Oct : Polygon (1 .. 8);
      Ang : Long_Float;
   begin
      for I in Oct'Range loop
         Ang := Long_Float (I - 1) * (2.0 * Ada.Numerics.Pi / 8.0);
         Oct (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
      end loop;
      Check (Area (Oct) > R (2.0), "regular octagon Area > 2");
      Check (Area (Oct) < Real (Ada.Numerics.Pi), "regular octagon Area < π");
      Check (Is_CCW (Oct), "regular octagon Is_CCW");
      Check (Near_Point (Centroid (Oct), P (0.0, 0.0), R (1.0E-6)),
             "octagon centroid ≈ origin");
   end;

   ------------------------------------------------------------------
   Section ("8. Translated / scaled polygons");
   ------------------------------------------------------------------
   declare
      Base : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Shifted : constant Polygon :=
        [P (10.0, 20.0), P (11.0, 20.0), P (11.0, 21.0), P (10.0, 21.0)];
      Scaled  : constant Polygon :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 3.0), P (0.0, 3.0)];
   begin
      Check (Near (Area (Base), Area (Shifted)),
             "translation preserves area");
      Check (Near (Area (Scaled), R (9.0)), "3x scale ⇒ area ×9");
      Check (Near_Point (Centroid (Shifted), P (10.5, 20.5)),
             "shifted square centroid");
      Check (Near_Point (Centroid (Scaled), P (1.5, 1.5)),
             "scaled square centroid");
   end;

   ------------------------------------------------------------------
   Section ("9. Determinant_Sum vs Signed_Area");
   ------------------------------------------------------------------
   declare
      Poly : constant Polygon :=
        [P (0.0, 0.0), P (5.0, 0.0), P (5.0, 4.0), P (0.0, 4.0)];
   begin
      Check (Near (Determinant_Sum (Poly), 2.0 * Signed_Area (Poly)),
             "det sum = 2 * Signed_Area");
      Check (Near (Area (Poly), abs (Signed_Area (Poly))),
             "Area = |Signed_Area|");
      Check (Near (Area (Poly), R (20.0)), "5x4 rect Area = 20");
   end;

   ------------------------------------------------------------------
   Section ("10. Invalid_Argument (n < 3, degenerate)");
   ------------------------------------------------------------------
   declare
      One     : constant Polygon := [P (0.0, 0.0)];
      Two     : constant Polygon := [P (0.0, 0.0), P (1.0, 0.0)];
      Collinear : constant Polygon :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)];
   begin
      Check (Raised_Invalid_Area (One), "Area raises on 1 vertex");
      Check (Raised_Invalid_Area (Two), "Area raises on 2 vertices");
      Check (Raised_Invalid_Signed (Two), "Signed_Area raises on 2 verts");
      Check (Raised_Invalid_CCW (One), "Is_CCW raises on 1 vertex");
      Check (Raised_Invalid_Det (Two), "Determinant_Sum raises on 2 verts");
      Check (Raised_Invalid_Centroid (Two), "Centroid raises on 2 verts");
      --  Collinear triangle has zero area: Area ok (0), Centroid raises.
      Check (Near (Area (Collinear), R (0.0)), "collinear Area = 0");
      Check (Raised_Invalid_Centroid (Collinear),
             "Centroid raises on degenerate");
      Check (not Is_CCW (Collinear) and not Is_CW (Collinear),
             "collinear neither CCW nor CW");
   end;

   ------------------------------------------------------------------
   Section ("11. Non-convex simple polygon");
   ------------------------------------------------------------------
   declare
      --  L-shape (concave hexagon), outer 2x2 square with 1x1 notch.
      --  Vertices CCW: (0,0)-(2,0)-(2,1)-(1,1)-(1,2)-(0,2)
      L : constant Polygon :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 1.0),
         P (1.0, 1.0), P (1.0, 2.0), P (0.0, 2.0)];
   begin
      Check (Near (Area (L), R (3.0)), "L-shape Area = 3");
      Check (Is_CCW (L), "L-shape Is_CCW");
      Check (Near (Signed_Area (L), R (3.0)), "L-shape Signed = 3");
   end;

   ------------------------------------------------------------------
   Section ("12. Indexing / non-1-based slices");
   ------------------------------------------------------------------
   declare
      Buf : constant Point_Array (5 .. 8) :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
   begin
      Check (Near (Area (Buf), R (4.0)), "non-1-based square Area = 4");
      Check (Is_CCW (Buf), "non-1-based Is_CCW");
      Check (Near_Point (Centroid (Buf), P (1.0, 1.0)),
             "non-1-based centroid");
   end;

   ------------------------------------------------------------------
   Section ("13. Small / large magnitudes");
   ------------------------------------------------------------------
   declare
      Tiny : constant Polygon :=
        [P (0.0, 0.0), P (1.0E-3, 0.0), P (1.0E-3, 1.0E-3), P (0.0, 1.0E-3)];
      Big  : constant Polygon :=
        [P (0.0, 0.0), P (1.0E3, 0.0), P (1.0E3, 1.0E3), P (0.0, 1.0E3)];
   begin
      Check (Near (Area (Tiny), R (1.0E-6), R (1.0E-12)),
             "tiny square Area = 1e-6");
      Check (Near (Area (Big), R (1.0E6), R (1.0E-3)),
             "big square Area = 1e6");
      Check (Is_CCW (Tiny) and Is_CCW (Big), "tiny/big Is_CCW");
   end;

   ------------------------------------------------------------------
   Section ("14. Consistency: reverse doubles negation");
   ------------------------------------------------------------------
   declare
      Fwd : constant Polygon :=
        [P (1.0, 1.0), P (4.0, 1.0), P (5.0, 3.0), P (2.0, 4.0), P (0.0, 2.0)];
      Rev : constant Polygon :=
        [P (0.0, 2.0), P (2.0, 4.0), P (5.0, 3.0), P (4.0, 1.0), P (1.0, 1.0)];
   begin
      Check (Near (Signed_Area (Fwd), -Signed_Area (Rev)),
             "reverse negates Signed_Area");
      Check (Near (Area (Fwd), Area (Rev)), "reverse preserves Area");
      Check (Near_Point (Centroid (Fwd), Centroid (Rev), R (1.0E-6)),
             "reverse preserves Centroid");
      Check (Is_CCW (Fwd) xor Is_CCW (Rev), "exactly one of Fwd/Rev Is_CCW");
   end;

   ------------------------------------------------------------------
   Section ("15. Max_Vertices capacity note");
   ------------------------------------------------------------------
   declare
      --  Regular 12-gon inscribed in unit circle (well under Max_Vertices).
      Gon : Polygon (1 .. 12);
      Ang : Long_Float;
   begin
      for I in Gon'Range loop
         Ang := Long_Float (I - 1) * (2.0 * Ada.Numerics.Pi / 12.0);
         Gon (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
      end loop;
      Check (Gon'Length <= Max_Vertices, "12-gon within Max_Vertices");
      Check (Area (Gon) > R (2.5), "12-gon Area > 2.5");
      Check (Area (Gon) < Real (Ada.Numerics.Pi), "12-gon Area < π");
      Check (Is_CCW (Gon), "12-gon Is_CCW");
      Check (Near_Point (Centroid (Gon), P (0.0, 0.0), R (1.0E-5)),
             "12-gon centroid ≈ origin");
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
