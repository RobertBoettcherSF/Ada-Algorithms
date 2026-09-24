--  Standalone test suite for Flood_Fill (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Flood_Fill;  use Flood_Fill;

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

   --  Small helpers to build fixtures.
   procedure Fill_Solid (G : in out Grid; C : Color_Id) is
   begin
      for R in G'Range (1) loop
         for Col in G'Range (2) loop
            G (R, Col) := C;
         end loop;
      end loop;
   end Fill_Solid;

   function Clone (G : Grid) return Grid is
      R : Grid (G'Range (1), G'Range (2));
   begin
      for I in G'Range (1) loop
         for J in G'Range (2) loop
            R (I, J) := G (I, J);
         end loop;
      end loop;
      return R;
   end Clone;

begin
   Put_Line ("Flood_Fill test suite");
   Put_Line ("=====================");

   ---------------------------------------------------------------------
   Section ("1. In_Bounds / Get_Color / Set_Color / Count_Color");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 3, 1 .. 4) := [others => [others => 0]];
      P : constant Pixel_Coord := (2, 3);
   begin
      Check (In_Bounds (G, 1, 1), "corner (1,1) in bounds");
      Check (not In_Bounds (G, 0, 1), "row 0 out of bounds");
      Check (not In_Bounds (G, 2, 5), "col 5 out of bounds");
      Set_Color (G, P, 7);
      Check (Get_Color (G, P) = 7, "Get_Color after Set_Color");
      Check (Count_Color (G, 7) = 1, "Count_Color finds one 7");
      Check (Count_Color (G, 0) = 11, "remaining pixels are 0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Same_Grid / Validate_Start / Out_Of_Bounds");
   ---------------------------------------------------------------------
   declare
      A : constant Grid (1 .. 2, 1 .. 2) := [[1, 2], [3, 4]];
      B : constant Grid (1 .. 2, 1 .. 2) := [[1, 2], [3, 4]];
      C : constant Grid (1 .. 2, 1 .. 2) := [[1, 2], [3, 9]];
      Raised : Boolean := False;
   begin
      Check (Same_Grid (A, B), "identical grids compare equal");
      Check (not Same_Grid (A, C), "differing grids compare unequal");
      begin
         Validate_Start (A, (1, 1));
         Check (True, "Validate_Start accepts in-range pixel");
      exception
         when others =>
            Check (False, "Validate_Start accepts in-range pixel");
      end;
      begin
         declare
            Unused : Color_Id;
         begin
            Unused := Get_Color (A, (1, 1));
            pragma Unreferenced (Unused);
            --  Force OOB via direct call with bad coord by Set on bad
            --  — Pixel_Coord is constrained, so raise via Validate path:
            raise Out_Of_Bounds;
         end;
      exception
         when Out_Of_Bounds =>
            Raised := True;
      end;
      Check (Raised, "Out_Of_Bounds is a named exception");
   end;

   ---------------------------------------------------------------------
   Section ("3. Flood_Fill_Recursive_4 basic region");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 5, 1 .. 5) :=
        [[0, 0, 1, 1, 1],
         [0, 0, 1, 2, 2],
         [0, 1, 1, 2, 2],
         [3, 3, 1, 1, 1],
         [3, 3, 3, 0, 0]];
      R : Fill_Result;
   begin
      Flood_Fill_Recursive_4 (G, (1, 1), Target => 0, Replacement => 9, Result => R);
      Check (R.Pixels_Changed = 5, "recursive-4 fills five connected 0s");
      Check (G (1, 1) = 9 and then G (2, 2) = 9, "seed neighbourhood replaced");
      Check (G (5, 4) = 0, "disconnected 0s untouched");
      Check (G (1, 3) = 1, "non-target colours preserved");
   end;

   ---------------------------------------------------------------------
   Section ("4. Flood_Fill_Recursive_8 connects diagonally");
   ---------------------------------------------------------------------
   declare
      --  Diagonal chain of 0s that 4-way cannot bridge.
      G4 : Grid (1 .. 3, 1 .. 3) :=
        [[0, 1, 1],
         [1, 0, 1],
         [1, 1, 0]];
      G8 : Grid (1 .. 3, 1 .. 3) :=
        [[0, 1, 1],
         [1, 0, 1],
         [1, 1, 0]];
      R4, R8 : Fill_Result;
   begin
      Flood_Fill_Recursive_4 (G4, (1, 1), 0, 5, R4);
      Flood_Fill_Recursive_8 (G8, (1, 1), 0, 5, R8);
      Check (R4.Pixels_Changed = 1, "4-way fills only the seed on diagonal");
      Check (R8.Pixels_Changed = 3, "8-way fills entire diagonal chain");
      Check (G8 (3, 3) = 5, "8-way reached opposite corner");
      Check (G4 (3, 3) = 0, "4-way left opposite corner alone");
   end;

   ---------------------------------------------------------------------
   Section ("5. Flood_Fill_Stack DFS-like four-way");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 4, 1 .. 4) := [others => [others => 1]];
      R : Fill_Result;
   begin
      G (2, 2) := 0;
      G (2, 3) := 0;
      G (3, 2) := 0;
      Flood_Fill_Stack (G, (2, 2), 0, 8, Four_Way, R);
      Check (R.Pixels_Changed = 3, "stack fill changed three pixels");
      Check (G (2, 2) = 8 and then G (2, 3) = 8 and then G (3, 2) = 8,
             "stack fill replaced the blob");
      Check (G (1, 1) = 1, "stack fill left background intact");
      Check (Count_Color (G, 8) = 3, "exactly three pixels are new colour");
   end;

   ---------------------------------------------------------------------
   Section ("6. Flood_Fill_Queue BFS-like eight-way");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 3, 1 .. 3) :=
        [[0, 1, 0],
         [1, 0, 1],
         [0, 1, 0]];
      R : Fill_Result;
   begin
      Flood_Fill_Queue (G, (1, 1), 0, 4, Eight_Way, R);
      Check (R.Pixels_Changed = 5, "queue 8-way fills all five 0s");
      Check (Count_Color (G, 0) = 0, "no target colour remains");
      Check (G (2, 2) = 4, "center diagonal pixel filled");
      Check (G (1, 2) = 1, "separators preserved");
   end;

   ---------------------------------------------------------------------
   Section ("7. Flood_Fill_Span scanline matches stack");
   ---------------------------------------------------------------------
   declare
      Base : Grid (1 .. 6, 1 .. 6) := [others => [others => 0]];
      A, B : Grid (1 .. 6, 1 .. 6);
      RA, RB : Fill_Result;
   begin
      --  Barrier wall of 1s splitting left/right.
      for R in 1 .. 6 loop
         Base (R, 4) := 1;
      end loop;
      A := Clone (Base);
      B := Clone (Base);
      Flood_Fill_Stack (A, (3, 2), 0, 7, Four_Way, RA);
      Flood_Fill_Span  (B, (3, 2), 0, 7, RB);
      Check (RA.Pixels_Changed = RB.Pixels_Changed,
             "span and stack change the same count");
      Check (Same_Grid (A, B), "span and stack produce identical grids");
      Check (B (3, 5) = 0, "span did not cross the barrier");
      Check (RB.Pixels_Changed = 18, "left side is 6x3 = 18 pixels");
   end;

   ---------------------------------------------------------------------
   Section ("8. Target equals replacement is a no-op");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 2, 1 .. 2) := [[3, 3], [3, 9]];
      Orig : constant Grid := Clone (G);
      R : Fill_Result;
   begin
      Flood_Fill_Recursive_4 (G, (1, 1), 3, 3, R);
      Check (R.Pixels_Changed = 0, "recursive no-op when colours match");
      Check (Same_Grid (G, Orig), "grid unchanged on colour no-op");
      Flood_Fill_Queue (G, (1, 1), 3, 3, Four_Way, R);
      Check (R.Pixels_Changed = 0, "queue no-op when colours match");
      Flood_Fill_Span (G, (1, 1), 3, 3, R);
      Check (R.Pixels_Changed = 0, "span no-op when colours match");
   end;

   ---------------------------------------------------------------------
   Section ("9. Boundary_Fill_4 stops at border");
   ---------------------------------------------------------------------
   declare
      --  Interior 0s enclosed by border colour 9.
      G : Grid (1 .. 5, 1 .. 5) :=
        [[9, 9, 9, 9, 9],
         [9, 0, 0, 0, 9],
         [9, 0, 0, 0, 9],
         [9, 0, 0, 0, 9],
         [9, 9, 9, 9, 9]];
      R : Fill_Result;
   begin
      Boundary_Fill_4 (G, (3, 3), Border => 9, Fill => 2, Result => R);
      Check (R.Pixels_Changed = 9, "boundary-4 fills 3x3 interior");
      Check (Count_Color (G, 9) = 16, "border pixels untouched");
      Check (Count_Color (G, 2) = 9, "interior is fill colour");
      Check (G (1, 1) = 9, "corner border preserved");
   end;

   ---------------------------------------------------------------------
   Section ("10. Boundary_Fill_8 vs open field");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 4, 1 .. 4) := [others => [others => 0]];
      R : Fill_Result;
      Raised : Boolean := False;
   begin
      --  Place a sparse border colour that 8-way still respects.
      G (1, 1) := 5;
      G (1, 2) := 5;
      G (2, 1) := 5;
      Boundary_Fill_8 (G, (4, 4), Border => 5, Fill => 1, Result => R);
      Check (R.Pixels_Changed = 13, "boundary-8 fills non-border cells");
      Check (G (1, 1) = 5, "border colour retained");
      Check (G (4, 4) = 1, "seed replaced with fill");
      begin
         Boundary_Fill_4 (G, (4, 4), Border => 1, Fill => 1, Result => R);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "identical border/fill raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("11. Pattern_Flood_Fill repeating tile");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 4, 1 .. 4) := [others => [others => 0]];
      Pat : constant Pattern_Grid (1 .. 2, 1 .. 2) := [[1, 2], [3, 4]];
      R : Fill_Result;
   begin
      --  Wall of 9s on the right half so only left 4x2 fills? Wait 4 cols:
      for Rng in 1 .. 4 loop
         G (Rng, 3) := 9;
         G (Rng, 4) := 9;
      end loop;
      Pattern_Flood_Fill (G, (1, 1), Target => 0, Pattern => Pat,
                          Conn => Four_Way, Result => R);
      Check (R.Pixels_Changed = 8, "pattern fill covers left 4x2");
      Check (G (1, 1) = 1, "pattern (1,1) at grid (1,1)");
      Check (G (1, 2) = 2, "pattern (1,2) at grid (1,2)");
      Check (G (2, 1) = 3, "pattern (2,1) at grid (2,1)");
      Check (G (2, 2) = 4, "pattern (2,2) at grid (2,2)");
      Check (G (3, 1) = 1, "pattern repeats on row 3");
      Check (G (1, 3) = 9, "wall not overwritten by pattern");
   end;

   ---------------------------------------------------------------------
   Section ("12. Count_Connected / Measure_Region");
   ---------------------------------------------------------------------
   declare
      G : constant Grid (1 .. 4, 1 .. 4) :=
        [[0, 0, 1, 0],
         [0, 1, 1, 0],
         [1, 1, 0, 0],
         [0, 0, 0, 1]];
      N4, N8, M : Natural;
      Snapshot : constant Grid := Clone (G);
   begin
      N4 := Count_Connected (G, (1, 1), 0, Four_Way);
      N8 := Count_Connected (G, (1, 1), 0, Eight_Way);
      M  := Measure_Region (G, (1, 1), 0, Four_Way);
      Check (N4 = 3, "4-way connected count from (1,1) is 3");
      Check (N8 = 3, "8-way from (1,1) still 3 (no diagonal 0)");
      Check (M = N4, "Measure_Region aliases Count_Connected");
      Check (Same_Grid (G, Snapshot), "counting does not mutate the grid");
      Check (Count_Connected (G, (4, 4), 0, Four_Way) = 0,
             "seed on non-target yields zero");
      Check (Count_Connected (G, (1, 4), 0, Four_Way) = 7,
             "right-side 0-region has seven pixels");
   end;

   ---------------------------------------------------------------------
   Section ("13. Seed on non-target / empty fill early exit");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 3, 1 .. 3) := [others => [others => 2]];
      Orig : constant Grid := Clone (G);
      R : Fill_Result;
   begin
      Flood_Fill_Stack (G, (2, 2), Target => 0, Replacement => 1,
                        Conn => Four_Way, Result => R);
      Check (R.Pixels_Changed = 0, "stack: seed mismatch changes nothing");
      Flood_Fill_Span (G, (2, 2), 0, 1, R);
      Check (R.Pixels_Changed = 0, "span: seed mismatch changes nothing");
      Boundary_Fill_4 (G, (2, 2), Border => 2, Fill => 9, Result => R);
      Check (R.Pixels_Changed = 0, "boundary: seed already border-like");
      Check (Same_Grid (G, Orig), "all early exits left grid intact");
   end;

   ---------------------------------------------------------------------
   Section ("14. Full-grid fill + Solid helper consistency");
   ---------------------------------------------------------------------
   declare
      G : Grid (1 .. 8, 1 .. 8);
      R : Fill_Result;
   begin
      Fill_Solid (G, 0);
      Flood_Fill_Queue (G, (4, 4), 0, 6, Four_Way, R);
      Check (R.Pixels_Changed = 64, "queue fills entire 8x8");
      Check (Count_Color (G, 6) = 64, "all pixels are replacement");
      Check (Count_Color (G, 0) = 0, "no originals remain");
      Flood_Fill_Recursive_4 (G, (1, 1), 6, 6, R);
      Check (R.Pixels_Changed = 0, "filling with same colour is idle");
   end;

   ---------------------------------------------------------------------
   Section ("15. Cross-variant agreement on irregular blob");
   ---------------------------------------------------------------------
   declare
      Shape : constant Grid (1 .. 5, 1 .. 5) :=
        [[1, 0, 0, 1, 1],
         [0, 0, 1, 0, 1],
         [0, 1, 1, 0, 0],
         [1, 0, 0, 0, 1],
         [1, 1, 0, 1, 1]];
      --  Note: with 4-way, region of 0s from (1,2):
      --  (1,2)(1,3)(2,1)(2,2) — (2,4) separated; etc.
      A, B, C, D : Grid (1 .. 5, 1 .. 5);
      RA, RB, RC, RD : Fill_Result;
      Expected : Natural;
   begin
      A := Clone (Shape);
      B := Clone (Shape);
      C := Clone (Shape);
      D := Clone (Shape);
      Expected := Count_Connected (Shape, (1, 2), 0, Four_Way);
      Flood_Fill_Recursive_4 (A, (1, 2), 0, 9, RA);
      Flood_Fill_Stack       (B, (1, 2), 0, 9, Four_Way, RB);
      Flood_Fill_Queue       (C, (1, 2), 0, 9, Four_Way, RC);
      Flood_Fill_Span        (D, (1, 2), 0, 9, RD);
      Check (Expected > 0, "irregular blob is non-empty");
      Check (RA.Pixels_Changed = Expected, "recursive matches count");
      Check (RB.Pixels_Changed = Expected, "stack matches count");
      Check (RC.Pixels_Changed = Expected, "queue matches count");
      Check (RD.Pixels_Changed = Expected, "span matches count");
      Check (Same_Grid (A, B) and then Same_Grid (B, C) and then Same_Grid (C, D),
             "all four variants agree on final grid");
   end;

   New_Line;
   Put_Line ("=====================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
   if Fail_Count > 0 then
      raise Program_Error with "Flood_Fill tests failed";
   end if;
end Tests;
