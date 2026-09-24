--  Standalone test suite for Graham_Scan (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Graham_Scan; use Graham_Scan;

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

   function Raised_Invalid_Andrew (Pts : Point_Set) return Boolean is
   begin
      declare
         H : constant Point_Array := Andrew_Monotone_Chain (Pts);
      begin
         pragma Unreferenced (H);
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Andrew;

   function Raised_Invalid_Area (Pts : Point_Array) return Boolean is
      A : Real;
   begin
      A := Signed_Area (Pts);
      pragma Unreferenced (A);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Area;

   function Empty_Set return Point_Set is
      Z : Point_Array (1 .. 0);
   begin
      return Z;
   end Empty_Set;

   function Too_Many return Point_Set is
      Z : Point_Array (1 .. Max_Points + 1) :=
            [others => (X => 0.0, Y => 0.0)];
   begin
      for I in Z'Range loop
         Z (I) := P (Real (I), Real (I));
      end loop;
      return Z;
   end Too_Many;

   --  True if every vertex of A appears (near) in B and |A|=|B|.
   function Same_Vertex_Set (A, B : Point_Array) return Boolean is
      Found : Boolean;
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         Found := False;
         for J in B'Range loop
            if Near_Point (A (I), B (J)) then
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            return False;
         end if;
      end loop;
      return True;
   end Same_Vertex_Set;

   function Contains_Point
     (Hull : Point_Array; Q : Point) return Boolean
   is
   begin
      for V of Hull loop
         if Near_Point (V, Q) then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Point;

   --  All hull edges turn left (strict CCW convex), wrapping around.
   function Is_Strictly_Convex_CCW (Hull : Point_Array) return Boolean is
      N : constant Natural := Hull'Length;
      Dense : Point_Array (1 .. N);
      K : Positive := 1;
      I2, I3 : Positive;
   begin
      if N < 3 then
         return N >= 1;
      end if;
      for V of Hull loop
         Dense (K) := V;
         K := K + 1;
      end loop;
      if not Is_CCW (Dense) then
         return False;
      end if;
      for I in 1 .. N loop
         I2 := (if I = N then 1 else I + 1);
         I3 := (if I2 = N then 1 else I2 + 1);
         if Orient2D (Dense (I), Dense (I2), Dense (I3)) <= Epsilon then
            return False;
         end if;
      end loop;
      return True;
   end Is_Strictly_Convex_CCW;

begin
   Ada.Text_IO.Put_Line ("Graham_Scan tests");
   Ada.Text_IO.Put_Line ("=================");

   ------------------------------------------------------------------
   Section ("1. Near / Dist2 / Dist / Cross / Dot / Orient2D / Polar");
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
   --  Polar: around (0,0), (1,0) before (0,1) before (−1,0); closer before
   --  farther on same ray.
   Check (Polar_Less (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)),
          "Polar_Less (1,0) before (0,1)");
   Check (Polar_Less (P (0.0, 0.0), P (0.0, 1.0), P (-1.0, 0.0)),
          "Polar_Less (0,1) before (−1,0)");
   Check (not Polar_Less (P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)),
          "not Polar_Less (0,1) before (1,0)");
   Check (Polar_Less (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)),
          "Polar_Less closer before farther same ray");
   Check (not Polar_Less (P (0.0, 0.0), P (2.0, 0.0), P (1.0, 0.0)),
          "not Polar_Less farther before closer");

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument: empty / oversized");
   ------------------------------------------------------------------
   Check (Raised_Invalid_Hull (Empty_Set), "Hull empty raises");
   Check (Raised_Invalid_Andrew (Empty_Set), "Andrew empty raises");
   Check (Raised_Invalid_Hull (Too_Many), "Hull oversized raises");
   Check (Raised_Invalid_Andrew (Too_Many), "Andrew oversized raises");
   Check (Raised_Invalid_Area (Empty_Set), "Signed_Area empty raises");
   declare
      Two : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
   begin
      Check (Raised_Invalid_Area (Two), "Signed_Area n=2 raises");
   end;

   ------------------------------------------------------------------
   Section ("3. Single point / two points / duplicates");
   ------------------------------------------------------------------
   declare
      One : constant Point_Set := [P (2.0, 3.0)];
      Two : constant Point_Set := [P (0.0, 0.0), P (4.0, 0.0)];
      Dup : constant Point_Set :=
        [P (1.0, 1.0), P (1.0, 1.0), P (1.0 + 1.0E-12, 1.0)];
      H1, H2, HD, A1, A2, AD : Point_Array (1 .. Max_Points);
      N1, N2, ND : Point_Count;
   begin
      declare
         T : constant Point_Array := Convex_Hull (One);
      begin
         N1 := T'Length;
         for I in T'Range loop
            H1 (I) := T (I);
         end loop;
      end;
      Check (N1 = 1, "single hull count 1");
      Check (Near_Point (H1 (1), P (2.0, 3.0)), "single hull point");
      Check (Hull_Vertex_Count (One) = 1, "Hull_Vertex_Count single");

      declare
         T : constant Point_Array := Convex_Hull (Two);
      begin
         N2 := T'Length;
         for I in T'Range loop
            H2 (I) := T (I);
         end loop;
      end;
      Check (N2 = 2, "two-point hull count 2");
      Check (Contains_Point (H2 (1 .. N2), P (0.0, 0.0)), "two contains 0");
      Check (Contains_Point (H2 (1 .. N2), P (4.0, 0.0)), "two contains 4");

      declare
         T : constant Point_Array := Convex_Hull (Dup);
      begin
         ND := T'Length;
         for I in T'Range loop
            HD (I) := T (I);
         end loop;
      end;
      Check (ND = 1, "near-duplicates collapse to 1");

      declare
         T : constant Point_Array := Andrew_Monotone_Chain (One);
      begin
         for I in T'Range loop
            A1 (I) := T (I);
         end loop;
         Check (Same_Vertex_Set (H1 (1 .. N1), T), "Andrew matches single");
      end;
      declare
         T : constant Point_Array := Andrew_Monotone_Chain (Two);
      begin
         for I in T'Range loop
            A2 (I) := T (I);
         end loop;
         Check (Same_Vertex_Set (H2 (1 .. N2), T), "Andrew matches two");
      end;
      declare
         T : constant Point_Array := Andrew_Monotone_Chain (Dup);
      begin
         for I in T'Range loop
            AD (I) := T (I);
         end loop;
         Check (Same_Vertex_Set (HD (1 .. ND), T), "Andrew matches dups");
      end;
      pragma Unreferenced (A1, A2, AD);
   end;

   ------------------------------------------------------------------
   Section ("4. Triangle");
   ------------------------------------------------------------------
   declare
      Tri : constant Point_Set :=
        [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0)];
      H : constant Point_Array := Convex_Hull (Tri);
      A : constant Point_Array := Andrew_Monotone_Chain (Tri);
   begin
      Check (H'Length = 3, "triangle hull 3");
      Check (Is_CCW (H), "triangle hull CCW");
      Check (Is_Strictly_Convex_CCW (H), "triangle strictly convex CCW");
      Check (Same_Vertex_Set (H, A), "triangle matches Andrew");
      Check (Near (Signed_Area (H), R (6.0)), "triangle area 6");
      Check (Contains_Point (H, P (0.0, 0.0)), "triangle has (0,0)");
      Check (Contains_Point (H, P (4.0, 0.0)), "triangle has (4,0)");
      Check (Contains_Point (H, P (1.0, 3.0)), "triangle has (1,3)");
   end;

   ------------------------------------------------------------------
   Section ("5. Square / rectangle");
   ------------------------------------------------------------------
   declare
      Sq : constant Point_Set :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Rect : constant Point_Set :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 1.0), P (0.0, 1.0)];
      HS : constant Point_Array := Convex_Hull (Sq);
      HR : constant Point_Array := Convex_Hull (Rect);
      AS : constant Point_Array := Andrew_Monotone_Chain (Sq);
      AR : constant Point_Array := Andrew_Monotone_Chain (Rect);
   begin
      Check (HS'Length = 4, "square hull 4");
      Check (Is_CCW (HS), "square CCW");
      Check (Is_Strictly_Convex_CCW (HS), "square strictly convex");
      Check (Same_Vertex_Set (HS, AS), "square matches Andrew");
      Check (Near (Signed_Area (HS), R (1.0)), "square area 1");
      Check (HR'Length = 4, "rect hull 4");
      Check (Is_CCW (HR), "rect CCW");
      Check (Same_Vertex_Set (HR, AR), "rect matches Andrew");
      Check (Near (Signed_Area (HR), R (3.0)), "rect area 3");
   end;

   ------------------------------------------------------------------
   Section ("6. Interior points ignored (cloud)");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Set :=
        [P (0.0, 0.0), P (5.0, 0.0), P (5.0, 4.0), P (0.0, 4.0),
         P (1.0, 1.0), P (2.0, 2.0), P (3.0, 1.5), P (2.5, 3.0),
         P (1.5, 2.5), P (4.0, 2.0)];
      H : constant Point_Array := Convex_Hull (Cloud);
      A : constant Point_Array := Andrew_Monotone_Chain (Cloud);
   begin
      Check (H'Length = 4, "cloud hull is rectangle 4");
      Check (not Contains_Point (H, P (2.0, 2.0)), "interior (2,2) dropped");
      Check (not Contains_Point (H, P (1.0, 1.0)), "interior (1,1) dropped");
      Check (Contains_Point (H, P (0.0, 0.0)), "corner (0,0) kept");
      Check (Contains_Point (H, P (5.0, 4.0)), "corner (5,4) kept");
      Check (Is_CCW (H), "cloud hull CCW");
      Check (Same_Vertex_Set (H, A), "cloud matches Andrew");
      Check (Near (Signed_Area (H), R (20.0)), "cloud area 20");
   end;

   ------------------------------------------------------------------
   Section ("7. Points already in convex position");
   ------------------------------------------------------------------
   declare
      --  Regular pentagon-ish (convex position).
      Pent : constant Point_Set :=
        [P (1.0, 0.0),
         P (0.309, 0.951),
         P (-0.809, 0.588),
         P (-0.809, -0.588),
         P (0.309, -0.951)];
      H : constant Point_Array := Convex_Hull (Pent);
      A : constant Point_Array := Andrew_Monotone_Chain (Pent);
   begin
      Check (H'Length = 5, "pentagon hull 5");
      Check (Is_CCW (H), "pentagon CCW");
      Check (Is_Strictly_Convex_CCW (H), "pentagon strictly convex");
      Check (Same_Vertex_Set (H, A), "pentagon matches Andrew");
      Check (Hull_Vertex_Count (Pent) = 5, "Hull_Vertex_Count pent");
   end;

   ------------------------------------------------------------------
   Section ("8. Regular-ish octagon + jitter interior");
   ------------------------------------------------------------------
   declare
      Oct : constant Point_Set :=
        [P (1.0, 0.0), P (0.707, 0.707), P (0.0, 1.0), P (-0.707, 0.707),
         P (-1.0, 0.0), P (-0.707, -0.707), P (0.0, -1.0), P (0.707, -0.707),
         P (0.1, 0.1), P (-0.2, 0.3), P (0.0, 0.0)];
      H : constant Point_Array := Convex_Hull (Oct);
      A : constant Point_Array := Andrew_Monotone_Chain (Oct);
   begin
      Check (H'Length = 8, "octagon+interior → 8");
      Check (Is_CCW (H), "octagon CCW");
      Check (not Contains_Point (H, P (0.0, 0.0)), "origin interior dropped");
      Check (Same_Vertex_Set (H, A), "octagon matches Andrew");
      Check (Is_Strictly_Convex_CCW (H), "octagon strictly convex");
   end;

   ------------------------------------------------------------------
   Section ("9. Collinear educational cases");
   ------------------------------------------------------------------
   declare
      Horz : constant Point_Set :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0), P (3.0, 0.0)];
      Vert : constant Point_Set :=
        [P (1.0, 0.0), P (1.0, 2.0), P (1.0, 5.0), P (1.0, 1.0)];
      Diag : constant Point_Set :=
        [P (0.0, 0.0), P (1.0, 1.0), P (2.0, 2.0), P (3.0, 3.0)];
      Edge : constant Point_Set :=
        [P (0.0, 0.0), P (2.0, 0.0), P (1.0, 0.0), P (0.0, 2.0),
         P (2.0, 2.0)];
      HH : constant Point_Array := Convex_Hull (Horz);
      HV : constant Point_Array := Convex_Hull (Vert);
      HD : constant Point_Array := Convex_Hull (Diag);
      HE : constant Point_Array := Convex_Hull (Edge);
      AH : constant Point_Array := Andrew_Monotone_Chain (Horz);
      AV : constant Point_Array := Andrew_Monotone_Chain (Vert);
      AD : constant Point_Array := Andrew_Monotone_Chain (Diag);
      AE : constant Point_Array := Andrew_Monotone_Chain (Edge);
   begin
      Check (HH'Length = 2, "horizontal collinear → 2");
      Check (Contains_Point (HH, P (0.0, 0.0)), "horz left end");
      Check (Contains_Point (HH, P (3.0, 0.0)), "horz right end");
      Check (Same_Vertex_Set (HH, AH), "horz matches Andrew");

      Check (HV'Length = 2, "vertical collinear → 2");
      Check (Contains_Point (HV, P (1.0, 0.0)), "vert bottom");
      Check (Contains_Point (HV, P (1.0, 5.0)), "vert top");
      Check (Same_Vertex_Set (HV, AV), "vert matches Andrew");

      Check (HD'Length = 2, "diagonal collinear → 2");
      Check (Contains_Point (HD, P (0.0, 0.0)), "diag start");
      Check (Contains_Point (HD, P (3.0, 3.0)), "diag end");
      Check (Same_Vertex_Set (HD, AD), "diag matches Andrew");

      --  Midpoint on bottom edge dropped; hull is the rectangle corners.
      Check (HE'Length = 4, "edge-collinear midpoint → 4");
      Check (not Contains_Point (HE, P (1.0, 0.0)), "edge midpoint dropped");
      Check (Same_Vertex_Set (HE, AE), "edge matches Andrew");
      Check (Is_CCW (HE), "edge hull CCW");
   end;

   ------------------------------------------------------------------
   Section ("10. Diamond / rotated square");
   ------------------------------------------------------------------
   declare
      Dia : constant Point_Set :=
        [P (0.0, 1.0), P (1.0, 0.0), P (0.0, -1.0), P (-1.0, 0.0),
         P (0.0, 0.0)];
      H : constant Point_Array := Convex_Hull (Dia);
      A : constant Point_Array := Andrew_Monotone_Chain (Dia);
   begin
      Check (H'Length = 4, "diamond hull 4");
      Check (not Contains_Point (H, P (0.0, 0.0)), "diamond center dropped");
      Check (Is_CCW (H), "diamond CCW");
      Check (Same_Vertex_Set (H, A), "diamond matches Andrew");
      Check (Near (Signed_Area (H), R (2.0)), "diamond area 2");
   end;

   ------------------------------------------------------------------
   Section ("11. Random-ish classroom cloud vs Andrew");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Set :=
        [P (2.1, 3.4), P (0.5, 0.2), P (4.0, 1.0), P (3.3, 3.9),
         P (1.0, 2.0), P (2.0, 1.0), P (3.0, 2.5), P (0.0, 4.0),
         P (4.5, 0.5), P (1.5, 3.5), P (2.8, 0.8), P (0.2, 1.8)];
      H : constant Point_Array := Convex_Hull (Cloud);
      A : constant Point_Array := Andrew_Monotone_Chain (Cloud);
   begin
      Check (H'Length >= 3, "cloud hull ≥ 3");
      Check (H'Length = A'Length, "cloud same count as Andrew");
      Check (Same_Vertex_Set (H, A), "cloud vertex set = Andrew");
      Check (Is_CCW (H), "cloud CCW");
      Check (Is_Strictly_Convex_CCW (H), "cloud strictly convex");
      Check (Hull_Vertex_Count (Cloud) = H'Length, "Hull_Vertex_Count cloud");
   end;

   ------------------------------------------------------------------
   Section ("12. Max_Points capacity / shuffled square");
   ------------------------------------------------------------------
   declare
      Big : Point_Array (1 .. Max_Points);
      H : Point_Array (1 .. Max_Points);
      HN : Point_Count;
      Shuffle : constant Point_Set :=
        [P (1.0, 1.0), P (0.0, 0.0), P (0.5, 0.5), P (1.0, 0.0),
         P (0.0, 1.0), P (0.25, 0.25), P (0.75, 0.25)];
      HS : constant Point_Array := Convex_Hull (Shuffle);
   begin
      for I in Big'Range loop
         --  Points on a circle-ish ring plus some interior.
         if I <= 16 then
            declare
               Ang : constant Long_Float :=
                 2.0 * Ada.Numerics.Pi * Long_Float (I - 1) / 16.0;
            begin
               Big (I) := P (Real (Math.Cos (Ang)), Real (Math.Sin (Ang)));
            end;
         else
            Big (I) := P (0.01 * Real (I mod 7), 0.01 * Real (I mod 5));
         end if;
      end loop;
      declare
         T : constant Point_Array := Convex_Hull (Big);
         TA : constant Point_Array := Andrew_Monotone_Chain (Big);
      begin
         HN := T'Length;
         for I in T'Range loop
            H (I) := T (I);
         end loop;
         Check (HN = 16, "Max_Points ring → 16 hull");
         Check (Same_Vertex_Set (T, TA), "Max_Points matches Andrew");
         Check (Is_CCW (T), "Max_Points hull CCW");
      end;
      Check (HS'Length = 4, "shuffled square+interior → 4");
      Check (Is_CCW (HS), "shuffled square CCW");
      Check (Contains_Point (HS, P (0.0, 0.0)), "shuffled has (0,0)");
      Check (Contains_Point (HS, P (1.0, 1.0)), "shuffled has (1,1)");
      pragma Unreferenced (H);
   end;

   ------------------------------------------------------------------
   Section ("13. Signed_Area / Is_CCW helpers");
   ------------------------------------------------------------------
   declare
      CCW : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      CW : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)];
   begin
      Check (Is_CCW (CCW), "Is_CCW true for CCW triangle");
      Check (not Is_CCW (CW), "Is_CCW false for CW triangle");
      Check (Signed_Area (CCW) > 0.0, "Signed_Area positive CCW");
      Check (Signed_Area (CW) < 0.0, "Signed_Area negative CW");
      Check (Near (Signed_Area (CCW), R (0.5)), "Signed_Area = 1/2");
   end;

   ------------------------------------------------------------------
   Section ("14. Pivot is lowest-then-leftmost on hull");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Set :=
        [P (3.0, 1.0), P (1.0, 0.0), P (2.0, 0.0), P (0.0, 2.0),
         P (4.0, 2.0), P (2.0, 3.0)];
      H : constant Point_Array := Convex_Hull (Pts);
   begin
      --  Lowest y is y=0; leftmost of those is (1,0).
      Check (H'Length >= 3, "pivot case hull ≥ 3");
      Check (Near_Point (H (H'First), P (1.0, 0.0)),
             "hull starts at lowest-left pivot (1,0)");
      Check (Is_CCW (H), "pivot case CCW");
      Check (Is_Strictly_Convex_CCW (H), "pivot case strictly convex");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image & " FAIL");
   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
