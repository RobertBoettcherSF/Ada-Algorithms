--  Standalone test suite for Convex_Hull_Algorithms (survey main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Text_IO;
with Convex_Hull_Algorithms; use Convex_Hull_Algorithms;

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

   function Raised_Invalid
     (Pts : Point_Set; Method : Hull_Method) return Boolean
   is
   begin
      declare
         H : constant Point_Array := Convex_Hull (Pts, Method);
      begin
         pragma Unreferenced (H);
         return False;
      end;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid;

   function Raised_Invalid_Named
     (Pts : Point_Set; Which : Character) return Boolean
   is
   begin
      case Which is
         when 'G' =>
            declare
               T : constant Point_Array := Gift_Wrapping (Pts);
            begin
               pragma Unreferenced (T);
               return False;
            end;
         when 'S' =>
            declare
               T : constant Point_Array := Graham_Scan (Pts);
            begin
               pragma Unreferenced (T);
               return False;
            end;
         when 'A' =>
            declare
               T : constant Point_Array := Andrew_Monotone_Chain (Pts);
            begin
               pragma Unreferenced (T);
               return False;
            end;
         when 'Q' =>
            declare
               T : constant Point_Array := Quickhull (Pts);
            begin
               pragma Unreferenced (T);
               return False;
            end;
         when 'J' =>
            declare
               T : constant Point_Array := Jarvis_March (Pts);
            begin
               pragma Unreferenced (T);
               return False;
            end;
         when others =>
            return False;
      end case;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Named;

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

   function Is_Strictly_Convex_CCW (Hull : Point_Array) return Boolean is
      N     : constant Natural := Hull'Length;
      Dense : Point_Array (1 .. N);
      K     : Positive := 1;
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

   --  Cross-check every method against Andrew oracle on Pts.
   procedure Agree_All (Pts : Point_Set; Label : String) is
      A  : constant Point_Array := Andrew_Monotone_Chain (Pts);
      G  : constant Point_Array := Gift_Wrapping (Pts);
      S  : constant Point_Array := Graham_Scan (Pts);
      Q  : constant Point_Array := Quickhull (Pts);
      J  : constant Point_Array := Jarvis_March (Pts);
      DG : constant Point_Array :=
             Convex_Hull (Pts, Gift_Wrapping_Method);
      DS : constant Point_Array :=
             Convex_Hull (Pts, Graham_Scan_Method);
      DA : constant Point_Array :=
             Convex_Hull (Pts, Andrew_Method);
      DQ : constant Point_Array :=
             Convex_Hull (Pts, Quickhull_Method);
   begin
      Check (Same_Vertex_Set (G, A), Label & ": Gift ≡ Andrew");
      Check (Same_Vertex_Set (S, A), Label & ": Graham ≡ Andrew");
      Check (Same_Vertex_Set (Q, A), Label & ": Quickhull ≡ Andrew");
      Check (Same_Vertex_Set (J, G), Label & ": Jarvis ≡ Gift");
      Check (Same_Vertex_Set (DG, G), Label & ": dispatch Gift");
      Check (Same_Vertex_Set (DS, S), Label & ": dispatch Graham");
      Check (Same_Vertex_Set (DA, A), Label & ": dispatch Andrew");
      Check (Same_Vertex_Set (DQ, Q), Label & ": dispatch Quickhull");
      if A'Length >= 3 then
         Check (Is_CCW (A), Label & ": Andrew CCW");
         Check (Is_CCW (G), Label & ": Gift CCW");
         Check (Is_CCW (S), Label & ": Graham CCW");
         Check (Is_CCW (Q), Label & ": Quickhull CCW");
         Check (Near (Signed_Area (G), Signed_Area (A)),
                Label & ": Gift area ≡ Andrew");
         Check (Near (Signed_Area (S), Signed_Area (A)),
                Label & ": Graham area ≡ Andrew");
         Check (Near (Signed_Area (Q), Signed_Area (A)),
                Label & ": Quickhull area ≡ Andrew");
      end if;
      Check (Hull_Vertex_Count (Pts) = A'Length,
             Label & ": Hull_Vertex_Count default");
      Check (Hull_Vertex_Count (Pts, Quickhull_Method) = Q'Length,
             Label & ": Hull_Vertex_Count Quickhull");
   end Agree_All;

begin
   Ada.Text_IO.Put_Line ("Convex_Hull_Algorithms survey tests");
   Ada.Text_IO.Put_Line ("===================================");

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
   Check (Polar_Less (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)),
          "Polar_Less (1,0) before (0,1)");
   Check (Polar_Less (P (0.0, 0.0), P (0.0, 1.0), P (-1.0, 0.0)),
          "Polar_Less (0,1) before (−1,0)");
   Check (not Polar_Less (P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)),
          "not Polar_Less (0,1) before (1,0)");
   Check (Polar_Less (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)),
          "Polar_Less closer before farther same ray");
   Check (Near (Distance_To_Line (P (0.0, 1.0), P (0.0, 0.0), P (1.0, 0.0)),
                R (1.0)),
          "Distance_To_Line unit");

   ------------------------------------------------------------------
   Section ("2. Invalid_Argument: empty / oversized");
   ------------------------------------------------------------------
   Check (Raised_Invalid (Empty_Set, Andrew_Method), "Andrew empty");
   Check (Raised_Invalid (Empty_Set, Gift_Wrapping_Method), "Gift empty");
   Check (Raised_Invalid (Empty_Set, Graham_Scan_Method), "Graham empty");
   Check (Raised_Invalid (Empty_Set, Quickhull_Method), "Quickhull empty");
   Check (Raised_Invalid (Too_Many, Andrew_Method), "Andrew oversized");
   Check (Raised_Invalid (Too_Many, Gift_Wrapping_Method), "Gift oversized");
   Check (Raised_Invalid (Too_Many, Graham_Scan_Method), "Graham oversized");
   Check (Raised_Invalid (Too_Many, Quickhull_Method), "Quickhull oversized");
   Check (Raised_Invalid_Named (Empty_Set, 'J'), "Jarvis empty");
   Check (Raised_Invalid_Named (Too_Many, 'A'), "Andrew named oversized");
   Check (Raised_Invalid_Area (Empty_Set), "Signed_Area empty");
   declare
      Two : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
   begin
      Check (Raised_Invalid_Area (Two), "Signed_Area n=2");
   end;

   ------------------------------------------------------------------
   Section ("3. Single / two points / duplicates");
   ------------------------------------------------------------------
   declare
      One : constant Point_Set := [P (2.0, 3.0)];
      Two : constant Point_Set := [P (0.0, 0.0), P (4.0, 0.0)];
      Dup : constant Point_Set :=
        [P (1.0, 1.0), P (1.0, 1.0), P (1.0 + 1.0E-12, 1.0)];
   begin
      Check (Andrew_Monotone_Chain (One)'Length = 1, "Andrew single → 1");
      Check (Gift_Wrapping (One)'Length = 1, "Gift single → 1");
      Check (Graham_Scan (One)'Length = 1, "Graham single → 1");
      Check (Quickhull (One)'Length = 1, "Quickhull single → 1");
      Check (Andrew_Monotone_Chain (Two)'Length = 2, "Andrew two → 2");
      Check (Gift_Wrapping (Two)'Length = 2, "Gift two → 2");
      Check (Graham_Scan (Two)'Length = 2, "Graham two → 2");
      Check (Quickhull (Two)'Length = 2, "Quickhull two → 2");
      Check (Andrew_Monotone_Chain (Dup)'Length = 1, "Andrew dups → 1");
      Check (Gift_Wrapping (Dup)'Length = 1, "Gift dups → 1");
      Check (Graham_Scan (Dup)'Length = 1, "Graham dups → 1");
      Check (Quickhull (Dup)'Length = 1, "Quickhull dups → 1");
      Agree_All (One, "single");
      Agree_All (Two, "two");
      Agree_All (Dup, "dups");
   end;

   ------------------------------------------------------------------
   Section ("4. Triangle");
   ------------------------------------------------------------------
   declare
      Tri : constant Point_Set :=
        [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0)];
      A : constant Point_Array := Andrew_Monotone_Chain (Tri);
   begin
      Check (A'Length = 3, "triangle hull 3");
      Check (Is_Strictly_Convex_CCW (A), "triangle strictly convex");
      Check (Near (Signed_Area (A), R (6.0)), "triangle area 6");
      Agree_All (Tri, "triangle");
   end;

   ------------------------------------------------------------------
   Section ("5. Square / rectangle");
   ------------------------------------------------------------------
   declare
      Sq : constant Point_Set :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Rect : constant Point_Set :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 1.0), P (0.0, 1.0)];
      HS : constant Point_Array := Andrew_Monotone_Chain (Sq);
      HR : constant Point_Array := Andrew_Monotone_Chain (Rect);
   begin
      Check (HS'Length = 4, "square hull 4");
      Check (Near (Signed_Area (HS), R (1.0)), "square area 1");
      Check (HR'Length = 4, "rect hull 4");
      Check (Near (Signed_Area (HR), R (3.0)), "rect area 3");
      Agree_All (Sq, "square");
      Agree_All (Rect, "rect");
   end;

   ------------------------------------------------------------------
   Section ("6. Interior cloud");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Set :=
        [P (0.0, 0.0), P (5.0, 0.0), P (5.0, 4.0), P (0.0, 4.0),
         P (1.0, 1.0), P (2.0, 2.0), P (3.0, 1.5), P (2.5, 3.0),
         P (1.5, 2.5), P (4.0, 2.0)];
      H : constant Point_Array := Andrew_Monotone_Chain (Cloud);
   begin
      Check (H'Length = 4, "cloud hull rectangle 4");
      Check (not Contains_Point (H, P (2.0, 2.0)), "interior dropped");
      Check (Near (Signed_Area (H), R (20.0)), "cloud area 20");
      Agree_All (Cloud, "cloud");
   end;

   ------------------------------------------------------------------
   Section ("7. Convex position / regular-ish");
   ------------------------------------------------------------------
   declare
      Pent : constant Point_Set :=
        [P (1.0, 0.0),
         P (0.309, 0.951),
         P (-0.809, 0.588),
         P (-0.809, -0.588),
         P (0.309, -0.951)];
      Oct : constant Point_Set :=
        [P (1.0, 0.0), P (0.707, 0.707), P (0.0, 1.0), P (-0.707, 0.707),
         P (-1.0, 0.0), P (-0.707, -0.707), P (0.0, -1.0), P (0.707, -0.707),
         P (0.1, 0.1), P (-0.2, 0.3), P (0.0, 0.0)];
   begin
      Check (Andrew_Monotone_Chain (Pent)'Length = 5, "pentagon → 5");
      Check (Andrew_Monotone_Chain (Oct)'Length = 8, "octagon+int → 8");
      Agree_All (Pent, "pentagon");
      Agree_All (Oct, "octagon");
   end;

   ------------------------------------------------------------------
   Section ("8. Collinear educational cases");
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
      HH : constant Point_Array := Andrew_Monotone_Chain (Horz);
      HV : constant Point_Array := Andrew_Monotone_Chain (Vert);
      HD : constant Point_Array := Andrew_Monotone_Chain (Diag);
      HE : constant Point_Array := Andrew_Monotone_Chain (Edge);
   begin
      Check (HH'Length = 2, "horizontal → 2");
      Check (Contains_Point (HH, P (0.0, 0.0))
               and then Contains_Point (HH, P (3.0, 0.0)),
             "horz extremes");
      Check (HV'Length = 2, "vertical → 2");
      Check (HD'Length = 2, "diagonal → 2");
      Check (HE'Length = 4, "edge-collinear → 4");
      Check (not Contains_Point (HE, P (1.0, 0.0)), "edge midpoint dropped");
      Agree_All (Horz, "horz");
      Agree_All (Vert, "vert");
      Agree_All (Diag, "diag");
      Agree_All (Edge, "edge");
   end;

   ------------------------------------------------------------------
   Section ("9. Diamond / random-ish / shuffled");
   ------------------------------------------------------------------
   declare
      Dia : constant Point_Set :=
        [P (0.0, 1.0), P (1.0, 0.0), P (0.0, -1.0), P (-1.0, 0.0),
         P (0.0, 0.0)];
      Cloud : constant Point_Set :=
        [P (2.1, 3.4), P (0.5, 0.2), P (4.0, 1.0), P (3.3, 3.9),
         P (1.0, 2.0), P (2.0, 1.0), P (3.0, 2.5), P (0.0, 4.0),
         P (4.5, 0.5), P (1.5, 3.5), P (2.8, 0.8), P (0.2, 1.8)];
      Shuffle : constant Point_Set :=
        [P (1.0, 1.0), P (0.0, 0.0), P (0.5, 0.5), P (1.0, 0.0),
         P (0.0, 1.0), P (0.25, 0.25), P (0.75, 0.25)];
      HD : constant Point_Array := Andrew_Monotone_Chain (Dia);
   begin
      Check (HD'Length = 4, "diamond → 4");
      Check (Near (Signed_Area (HD), R (2.0)), "diamond area 2");
      Check (Andrew_Monotone_Chain (Cloud)'Length >= 3, "random cloud ≥ 3");
      Check (Andrew_Monotone_Chain (Shuffle)'Length = 4, "shuffled → 4");
      Agree_All (Dia, "diamond");
      Agree_All (Cloud, "random");
      Agree_All (Shuffle, "shuffled");
   end;

   ------------------------------------------------------------------
   Section ("10. Max_Points regular 16-gon + interiors");
   ------------------------------------------------------------------
   declare
      Big : Point_Array (1 .. Max_Points);
   begin
      for I in Big'Range loop
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
         A : constant Point_Array := Andrew_Monotone_Chain (Big);
      begin
         Check (A'Length = 16, "Max_Points ring → 16");
         Check (Is_CCW (A), "Max_Points CCW");
         Check (Is_Strictly_Convex_CCW (A), "Max_Points strictly convex");
      end;
      Agree_All (Big, "Max_Points");
   end;

   ------------------------------------------------------------------
   Section ("11. Signed_Area / Is_CCW helpers");
   ------------------------------------------------------------------
   declare
      CCW_Tri : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      CW_Tri : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)];
   begin
      Check (Is_CCW (CCW_Tri), "Is_CCW true");
      Check (not Is_CCW (CW_Tri), "Is_CCW false");
      Check (Signed_Area (CCW_Tri) > 0.0, "Signed_Area positive");
      Check (Signed_Area (CW_Tri) < 0.0, "Signed_Area negative");
      Check (Near (Signed_Area (CCW_Tri), R (0.5)), "Signed_Area = 1/2");
   end;

   ------------------------------------------------------------------
   Section ("12. Default Convex_Hull uses Andrew");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Set :=
        [P (0.0, 0.0), P (2.0, 0.0), P (1.0, 1.0), P (0.5, 0.25)];
      D : constant Point_Array := Convex_Hull (Pts);
      A : constant Point_Array := Andrew_Monotone_Chain (Pts);
   begin
      Check (Same_Vertex_Set (D, A), "default Convex_Hull ≡ Andrew");
      Check (D'Length = 3, "default triangle hull 3");
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
