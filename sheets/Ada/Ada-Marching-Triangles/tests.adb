--  Standalone test suite for Marching_Triangles (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Marching_Triangles; use Marching_Triangles;

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
   function P (X, Y, Z : Real) return Point3 is
     ((X => X, Y => Y, Z => Z));

   function Raised_Invalid (Cloud : Point_Array) return Boolean is
      M : Mesh;
   begin
      M := Reconstruct_Mesh (Cloud);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid;

   function Raised_Invalid_Seed (Cloud : Point_Array) return Boolean is
      T : Triangle;
   begin
      T := Find_Seed_Triangle (Cloud);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Seed;

begin
   Ada.Text_IO.Put_Line ("Marching_Triangles tests");
   Ada.Text_IO.Put_Line ("========================");

   ------------------------------------------------------------------
   Section ("1. Near / Dist3 / Dot / Cross / Length");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0, 0.0), P (0.0, 0.0, 0.0)),
          "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0)),
          "not Near_Point");
   Check (Near (Dist3 (P (0.0, 0.0, 0.0), P (3.0, 4.0, 0.0)), R (5.0)),
          "Dist3 3-4-5 planar");
   Check (Near (Dist3 (P (0.0, 0.0, 0.0), P (0.0, 0.0, 0.0)), R (0.0)),
          "Dist3 zero");
   Check (Near (Dist3_Squared (P (1.0, 2.0, 2.0), P (0.0, 0.0, 0.0)),
                R (9.0)),
          "Dist3_Squared 1-2-2");
   Check (Near (Dot (P (1.0, 0.0, 0.0), P (0.0, 1.0, 0.0)), R (0.0)),
          "Dot orthogonal");
   Check (Near (Dot (P (1.0, 2.0, 3.0), P (1.0, 2.0, 3.0)), R (14.0)),
          "Dot self 14");
   declare
      C : constant Point3 := Cross (P (1.0, 0.0, 0.0), P (0.0, 1.0, 0.0));
   begin
      Check (Near_Point (C, P (0.0, 0.0, 1.0)), "Cross i×j = k");
   end;
   Check (Near (Length (P (0.0, 3.0, 4.0)), R (5.0)), "Length 3-4-5");
   declare
      U : constant Point3 := Normalize (P (0.0, 3.0, 4.0));
   begin
      Check (Near (Length (U), R (1.0)), "Normalize unit length");
      Check (Near_Point (U, P (0.0, 0.6, 0.8)), "Normalize 3-4-5 direction");
   end;
   Check (Near_Point (Normalize (P (0.0, 0.0, 0.0)), P (0.0, 0.0, 0.0)),
          "Normalize zero stays zero");

   ------------------------------------------------------------------
   Section ("2. Triangle normal / area / Sub");
   ------------------------------------------------------------------
   declare
      Nrm : constant Point3 :=
        Normal_Of_Triangle
          (P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (0.0, 1.0, 0.0));
   begin
      Check (Near_Point (Nrm, P (0.0, 0.0, 1.0)), "normal +Z for XY triangle");
   end;
   Check (Near (Triangle_Area
                  (P (0.0, 0.0, 0.0), P (2.0, 0.0, 0.0), P (0.0, 2.0, 0.0)),
                R (2.0)),
          "area right triangle base 2");
   Check (Near (Triangle_Area
                  (P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (2.0, 0.0, 0.0)),
                R (0.0)),
          "area collinear ~0");
   Check (Near_Point (Sub (P (3.0, 5.0, 7.0), P (1.0, 1.0, 1.0)),
                      P (2.0, 4.0, 6.0)),
          "Sub vector");

   ------------------------------------------------------------------
   Section ("3. Edge keys / boundary set toggle");
   ------------------------------------------------------------------
   declare
      E1 : constant Edge_Key := Make_Edge_Key (3, 1);
      E2 : constant Edge_Key := Make_Edge_Key (1, 3);
      E3 : constant Edge_Key := Make_Edge_Key (2, 4);
      Set : Boundary_Edge_Set;
   begin
      Check (E1.Lo = 1 and then E1.Hi = 3, "Make_Edge_Key orders Lo<=Hi");
      Check (Same_Edge (E1, E2), "Same_Edge undirected");
      Check (not Same_Edge (E1, E3), "not Same_Edge distinct");
      Check (not Contains_Edge (Set, E1), "empty set no edge");
      Toggle_Boundary_Edge (Set, E1);
      Check (Set.Count = 1, "toggle insert count 1");
      Check (Contains_Edge (Set, E2), "contains after insert");
      Toggle_Boundary_Edge (Set, E3);
      Check (Set.Count = 2, "toggle insert second");
      Toggle_Boundary_Edge (Set, E1);
      Check (Set.Count = 1, "toggle remove first");
      Check (not Contains_Edge (Set, E1), "gone after remove");
      Check (Contains_Edge (Set, E3), "second remains");
   end;

   ------------------------------------------------------------------
   Section ("4. Invalid_Argument / capacity policy");
   ------------------------------------------------------------------
   Check (Raised_Invalid ([P (0.0, 0.0, 0.0)]), "1 point invalid");
   Check (Raised_Invalid
            ([P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0)]),
          "2 points invalid");
   Check (Raised_Invalid_Seed ([P (0.0, 0.0, 0.0)]), "seed 1 pt invalid");
   Check (Raised_Invalid
            ([P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (0.0, 0.0, 0.0)]),
          "near-duplicate invalid");
   Check (Raised_Invalid
            ([P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (2.0, 0.0, 0.0)]),
          "collinear cloud invalid");
   Check (Has_Near_Duplicate
            ([P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (0.0, 0.0, 0.0)]),
          "Has_Near_Duplicate true");
   Check (not Has_Near_Duplicate
            ([P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (0.0, 1.0, 0.0)]),
          "Has_Near_Duplicate false");

   ------------------------------------------------------------------
   Section ("5. Single seed triangle (3 points)");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (0.0, 1.0, 0.0)];
      Seed : constant Triangle := Find_Seed_Triangle (Cloud);
      M : constant Mesh := Reconstruct_Mesh (Cloud);
   begin
      Check (Seed.A = 1 and then Seed.B = 2 and then Seed.C = 3,
             "seed is the only triple");
      Check (Triangle_Count_Of (M) = 1, "3 pts → 1 triangle");
      Check (All_Indices_In_Range (M, 3), "indices in 1..3");
      declare
         T : constant Triangle := Get_Triangle (M, 1);
      begin
         Check (T.A /= T.B and then T.B /= T.C and then T.A /= T.C,
                "triangle vertices distinct");
      end;
   end;

   ------------------------------------------------------------------
   Section ("6. Planar square patch (4 points)");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0),
         P (1.0, 1.0, 0.0), P (0.0, 1.0, 0.0)];
      M : constant Mesh := Reconstruct_Mesh (Cloud);
      TC : constant Triangle_Count := Triangle_Count_Of (M);
   begin
      Check (Natural (TC) >= 2, "square ≥ 2 triangles");
      Check (Natural (TC) <= 2, "square ≤ 2 triangles");
      Check (All_Indices_In_Range (M, 4), "square indices in range");
   end;

   ------------------------------------------------------------------
   Section ("7. Planar 2×3 grid (6 points)");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (2.0, 0.0, 0.0),
         P (0.0, 1.0, 0.0), P (1.0, 1.0, 0.0), P (2.0, 1.0, 0.0)];
      M : constant Mesh := Reconstruct_Mesh (Cloud);
      TC : constant Triangle_Count := Triangle_Count_Of (M);
   begin
      Check (Natural (TC) > 0, "grid triangle count > 0");
      Check (Natural (TC) >= 4, "2×3 grid ≥ 4 triangles");
      Check (All_Indices_In_Range (M, 6), "grid indices in 1..6");
   end;

   ------------------------------------------------------------------
   Section ("8. Planar 3×3 grid (9 points)");
   ------------------------------------------------------------------
   declare
      Cloud : Point_Array (1 .. 9);
      K : Point_Index := 1;
      M : Mesh;
      TC : Triangle_Count;
   begin
      for Y in 0 .. 2 loop
         for X in 0 .. 2 loop
            Cloud (K) := P (Real (X), Real (Y), 0.0);
            if K < 9 then
               K := K + 1;
            end if;
         end loop;
      end loop;
      M := Reconstruct_Mesh (Cloud);
      TC := Triangle_Count_Of (M);
      Check (Natural (TC) > 0, "3×3 count > 0");
      Check (Natural (TC) >= 8, "3×3 ≥ 8 triangles");
      Check (All_Indices_In_Range (M, 9), "3×3 indices in range");
   end;

   ------------------------------------------------------------------
   Section ("9. Mildly non-planar patch (z bump)");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (2.0, 0.0, 0.0),
         P (0.0, 1.0, 0.0), P (1.0, 1.0, 0.3), P (2.0, 1.0, 0.0),
         P (0.0, 2.0, 0.0), P (1.0, 2.0, 0.0), P (2.0, 2.0, 0.0)];
      M : constant Mesh := Reconstruct_Mesh (Cloud);
      TC : constant Triangle_Count := Triangle_Count_Of (M);
   begin
      Check (Natural (TC) > 0, "bump count > 0");
      Check (Natural (TC) >= 6, "bump ≥ 6 triangles");
      Check (All_Indices_In_Range (M, 9), "bump indices in range");
   end;

   ------------------------------------------------------------------
   Section ("10. Tetrahedron vertices (closed-ish small surface)");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0),
         P (0.5, 0.866, 0.0), P (0.5, 0.289, 0.816)];
      M : constant Mesh := Reconstruct_Mesh (Cloud);
      TC : constant Triangle_Count := Triangle_Count_Of (M);
   begin
      Check (Natural (TC) > 0, "tet count > 0");
      Check (Natural (TC) >= 3, "tet ≥ 3 faces grown");
      Check (Natural (TC) <= 4, "tet ≤ 4 faces");
      Check (All_Indices_In_Range (M, 4), "tet indices in range");
   end;

   ------------------------------------------------------------------
   Section ("11. Seed prefers compact perimeter");
   ------------------------------------------------------------------
   declare
      --  Far triangle would be large; nearest three around origin win.
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.0), P (0.0, 1.0, 0.0),
         P (10.0, 10.0, 0.0)];
      Seed : constant Triangle := Find_Seed_Triangle (Cloud);
   begin
      Check (Seed.A = 1 and then Seed.B = 2 and then Seed.C = 3,
             "seed is compact triple near origin");
   end;

   ------------------------------------------------------------------
   Section ("12. Mesh accessors / empty range checks");
   ------------------------------------------------------------------
   declare
      Empty : Mesh;
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 1.0), P (1.0, 0.0, 1.0), P (0.0, 1.0, 1.0)];
      M : constant Mesh := Reconstruct_Mesh (Cloud);
   begin
      Check (Triangle_Count_Of (Empty) = 0, "empty mesh count 0");
      Check (All_Indices_In_Range (Empty, 3), "empty mesh indices ok");
      Check (Triangle_Count_Of (M) = 1, "raised z triangle");
      Check (Get_Triangle (M, 1).A >= 1, "Get_Triangle A ≥ 1");
   end;

   ------------------------------------------------------------------
   Section ("13. Synthetic ridge (two slanted planes)");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (1.0, 0.0, 0.5), P (2.0, 0.0, 0.0),
         P (0.0, 1.0, 0.0), P (1.0, 1.0, 0.5), P (2.0, 1.0, 0.0)];
      M : constant Mesh := Reconstruct_Mesh (Cloud);
      TC : constant Triangle_Count := Triangle_Count_Of (M);
   begin
      Check (Natural (TC) > 0, "ridge count > 0");
      Check (Natural (TC) >= 4, "ridge ≥ 4");
      Check (All_Indices_In_Range (M, 6), "ridge indices");
   end;

   ------------------------------------------------------------------
   Section ("14. Larger planar strip");
   ------------------------------------------------------------------
   declare
      Cloud : Point_Array (1 .. 12);
      Idx : Point_Index := 1;
      M : Mesh;
      TC : Triangle_Count;
   begin
      for Y in 0 .. 2 loop
         for X in 0 .. 3 loop
            Cloud (Idx) := P (Real (X), Real (Y), 0.0);
            if Idx < 12 then
               Idx := Idx + 1;
            end if;
         end loop;
      end loop;
      M := Reconstruct_Mesh (Cloud);
      TC := Triangle_Count_Of (M);
      Check (Natural (TC) > 0, "strip count > 0");
      Check (Natural (TC) >= 10, "4×3 strip ≥ 10 triangles");
      Check (All_Indices_In_Range (M, 12), "strip indices");
   end;

   ------------------------------------------------------------------
   Section ("15. Constants / Max_Points policy");
   ------------------------------------------------------------------
   declare
      function MP return Positive is (Max_Points);
      function MT return Positive is (Max_Triangles);
   begin
      Check (MP = 64, "Max_Points = 64");
      Check (MT >= MP, "Max_Triangles ≥ Max_Points");
   end;
   Check (Candidate_Radius_Factor > R (1.0), "radius factor > 1");
   Check (Area_Tol > R (0.0), "Area_Tol positive");

   ------------------------------------------------------------------
   Section ("16. Extra Dist3 / Cross identities");
   ------------------------------------------------------------------
   Check (Near (Dist3 (P (-1.0, 2.0, 0.0), P (2.0, 6.0, 0.0)), R (5.0)),
          "Dist3 (-1,2)-(2,6)");
   declare
      C : constant Point3 := Cross (P (0.0, 1.0, 0.0), P (0.0, 0.0, 1.0));
   begin
      Check (Near_Point (C, P (1.0, 0.0, 0.0)), "Cross j×k = i");
   end;
   Check (Near (Dot (Cross (P (1.0, 0.0, 0.0), P (0.0, 1.0, 0.0)),
                     P (0.0, 0.0, 1.0)),
                R (1.0)),
          "scalar triple product 1");
   Check (Near_Point (Normal_Of_Triangle
                        (P (0.0, 0.0, 0.0), P (0.0, 1.0, 0.0),
                         P (0.0, 0.0, 1.0)),
                      P (1.0, 0.0, 0.0)),
          "normal +X for YZ triangle");

   ------------------------------------------------------------------
   Section ("17. Distinct triangle faces on square");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0, 0.0), P (2.0, 0.0, 0.0),
         P (2.0, 2.0, 0.0), P (0.0, 2.0, 0.0)];
      M : constant Mesh := Reconstruct_Mesh (Cloud);
      T1, T2 : Triangle;
      Same : Boolean;
   begin
      Check (Triangle_Count_Of (M) = 2, "unit-scaled square 2 tris");
      T1 := Get_Triangle (M, 1);
      T2 := Get_Triangle (M, 2);
      Same := T1.A = T2.A and then T1.B = T2.B and then T1.C = T2.C;
      Check (not Same, "two faces are distinct records");
      Check (All_Indices_In_Range (M, 4), "scaled square indices");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=================================");
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   Ada.Text_IO.Put_Line ("=================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;

   pragma Assert (Fail_Count = 0);
end Tests;
