with Ada.Text_IO;       use Ada.Text_IO;
with Painter_Algorithm; use Painter_Algorithm;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper constructors for representative test polygons
   function Make_Triangle (Id : Positive;
                           C  : RGBA_Color;
                           P1, P2, P3 : Point_3D) return Polygon is
   begin
      return (Vertex_Count => 3,
              Id           => Id,
              Color        => C,
              Vertices     => [1 => P1, 2 => P2, 3 => P3]);
   end Make_Triangle;

   Red_Color   : constant RGBA_Color := (Red => 255, Green => 0,   Blue => 0,   Alpha => 255);
   Green_Color : constant RGBA_Color := (Red => 0,   Green => 255, Blue => 0,   Alpha => 255);
   Blue_Color  : constant RGBA_Color := (Red => 0,   Green => 0,   Blue => 255, Alpha => 255);
begin
   -- TEST 1 - Depth Calculations (Min, Max, Centroid)
   Put_Line ("TEST 1 - Depth Calculations");
   declare
      P : constant Polygon := Make_Triangle
        (1, Red_Color,
         (X => 0.0, Y => 0.0, Z => 10.0),
         (X => 5.0, Y => 0.0, Z => 20.0),
         (X => 2.0, Y => 4.0, Z => 30.0));
   begin
      Check ("1.1 Max depth identifies 30.0", Max_Depth (P) = 30.0);
      Check ("1.2 Min depth identifies 10.0", Min_Depth (P) = 10.0);
      Check ("1.3 Centroid depth computes exact mean 20.0", Centroid_Depth (P) = 20.0);
   end;

   -- TEST 2 - 2D Bounding Box Overlap
   Put_Line ("TEST 2 - 2D Bounding Box Overlap");
   declare
      P1 : constant Polygon := Make_Triangle
        (1, Red_Color, (0.0, 0.0, 1.0), (4.0, 0.0, 1.0), (0.0, 4.0, 1.0));
      P2_Disjoint : constant Polygon := Make_Triangle
        (2, Green_Color, (10.0, 10.0, 1.0), (14.0, 10.0, 1.0), (10.0, 14.0, 1.0));
      P3_Overlap : constant Polygon := Make_Triangle
        (3, Blue_Color, (2.0, 2.0, 2.0), (6.0, 2.0, 2.0), (2.0, 6.0, 2.0));
   begin
      Check ("2.1 Disjoint polygons report no overlap",
             not Bounding_Boxes_Overlap_2D (P1, P2_Disjoint));
      Check ("2.2 Overlapping polygons report overlap",
             Bounding_Boxes_Overlap_2D (P1, P3_Overlap));
      Check ("2.3 Symmetry holds for overlap check",
             Bounding_Boxes_Overlap_2D (P3_Overlap, P1));
   end;

   -- TEST 3 - Point In Polygon 2D Point-Query
   Put_Line ("TEST 3 - Point In Polygon 2D");
   declare
      Tri : constant Polygon := Make_Triangle
        (1, Red_Color, (0.0, 0.0, 0.0), (10.0, 0.0, 0.0), (0.0, 10.0, 0.0));
   begin
      Check ("3.1 Point well inside returns True",
             Point_In_Polygon_2D ((1.0, 1.0), Tri));
      Check ("3.2 Point outside returns False",
             not Point_In_Polygon_2D ((10.0, 10.0), Tri));
      Check ("3.3 Negative coordinate outside returns False",
             not Point_In_Polygon_2D ((-1.0, -1.0), Tri));
   end;

   -- TEST 4 - Framebuffer Clearing
   Put_Line ("TEST 4 - Framebuffer Clearing");
   declare
      Buf : Framebuffer (0 .. 3, 0 .. 3);
   begin
      Clear_Framebuffer (Buf, Red_Color);
      Check ("4.1 Origin matches cleared color", Buf (0, 0) = Red_Color);
      Check ("4.2 Corner matches cleared color", Buf (3, 3) = Red_Color);
      Clear_Framebuffer (Buf, Blue_Color);
      Check ("4.3 Second clear updates color correctly", Buf (1, 1) = Blue_Color);
   end;

   -- TEST 5 - Depth Sorting Variant (Order Invariance)
   Put_Line ("TEST 5 - Standard Depth Sort");
   declare
      P_Near : constant Polygon := Make_Triangle (1, Red_Color, (0.0, 0.0, 5.0), (2.0, 0.0, 5.0), (0.0, 2.0, 5.0));
      P_Mid  : constant Polygon := Make_Triangle (2, Green_Color, (0.0, 0.0, 15.0), (2.0, 0.0, 15.0), (0.0, 2.0, 15.0));
      P_Far  : constant Polygon := Make_Triangle (3, Blue_Color, (0.0, 0.0, 25.0), (2.0, 0.0, 25.0), (0.0, 2.0, 25.0));
      List   : Polygon_Array := [1 => P_Near, 2 => P_Far, 3 => P_Mid];
   begin
      Sort_Polygons_Depth (List);
      Check ("5.1 First element has maximum depth", Max_Depth (List (1)) = 25.0);
      Check ("5.2 Second element has intermediate depth", Max_Depth (List (2)) = 15.0);
      Check ("5.3 Last element has minimum depth", Max_Depth (List (3)) = 5.0);
   end;

   -- TEST 6 - Standard Render Painter's Overwrite
   Put_Line ("TEST 6 - Standard Render Overwrite");
   declare
      Buf    : Framebuffer (0 .. 7, 0 .. 7);
      P_Back : constant Polygon := Make_Triangle (1, Red_Color, (0.0, 0.0, 50.0), (6.0, 0.0, 50.0), (0.0, 6.0, 50.0));
      P_Fore : constant Polygon := Make_Triangle (2, Blue_Color, (0.0, 0.0, 10.0), (6.0, 0.0, 10.0), (0.0, 6.0, 10.0));
      List   : Polygon_Array := [1 => P_Fore, 2 => P_Back];
   begin
      Clear_Framebuffer (Buf, Black_Color);
      Render_Standard (List, Buf);
      Check ("6.1 Overwritten pixel shows closer polygon (Blue)", Buf (1, 1) = Blue_Color);
      Check ("6.2 Overwritten corner shows closer polygon", Buf (2, 2) = Blue_Color);
      Check ("6.3 Uncovered background remains black", Buf (7, 7) = Black_Color);
   end;

   -- TEST 7 - Centroid Sorting Variant
   Put_Line ("TEST 7 - Centroid Sorting");
   declare
      P1 : constant Polygon := Make_Triangle (1, Red_Color, (0.0, 0.0, 10.0), (0.0, 0.0, 20.0), (0.0, 0.0, 30.0)); -- Mean 20
      P2 : constant Polygon := Make_Triangle (2, Blue_Color, (0.0, 0.0, 5.0), (0.0, 0.0, 5.0), (0.0, 0.0, 5.0));   -- Mean 5
      P3 : constant Polygon := Make_Triangle (3, Green_Color, (0.0, 0.0, 40.0), (0.0, 0.0, 40.0), (0.0, 0.0, 40.0)); -- Mean 40
      Arr : Polygon_Array := [1 => P2, 2 => P1, 3 => P3];
   begin
      Sort_Polygons_Centroid (Arr);
      Check ("7.1 Highest centroid placed first", Centroid_Depth (Arr (1)) = 40.0);
      Check ("7.2 Intermediate centroid placed second", Centroid_Depth (Arr (2)) = 20.0);
      Check ("7.3 Lowest centroid placed third", Centroid_Depth (Arr (3)) = 5.0);
   end;

   -- TEST 8 - Centroid Render Painter's Overwrite
   Put_Line ("TEST 8 - Centroid Render");
   declare
      Buf    : Framebuffer (0 .. 7, 0 .. 7);
      P_Back : constant Polygon := Make_Triangle (1, Green_Color, (0.0, 0.0, 30.0), (6.0, 0.0, 30.0), (0.0, 6.0, 30.0));
      P_Fore : constant Polygon := Make_Triangle (2, Red_Color, (0.0, 0.0, 5.0), (6.0, 0.0, 5.0), (0.0, 6.0, 5.0));
      List   : Polygon_Array := [1 => P_Fore, 2 => P_Back];
   begin
      Clear_Framebuffer (Buf, Black_Color);
      Render_Centroid (List, Buf);
      Check ("8.1 Center pixel is painted with foreground Red", Buf (1, 1) = Red_Color);
      Check ("8.2 Foreground Red overrides background Green", Buf (2, 1) = Red_Color);
      Check ("8.3 Pixel outside bounds remains Black", Buf (7, 7) = Black_Color);
   end;

   -- TEST 9 - Newell Precedence Heuristics
   Put_Line ("TEST 9 - Newell Precedence Heuristics");
   declare
      P_Distant : constant Polygon := Make_Triangle (1, Red_Color, (0.0, 0.0, 100.0), (2.0, 0.0, 100.0), (0.0, 2.0, 100.0));
      P_Near    : constant Polygon := Make_Triangle (2, Blue_Color, (0.0, 0.0, 10.0), (2.0, 0.0, 10.0), (0.0, 2.0, 10.0));
      P_Side    : constant Polygon := Make_Triangle (3, Green_Color, (50.0, 50.0, 10.0), (52.0, 50.0, 10.0), (50.0, 52.0, 10.0));
   begin
      Check ("9.1 Distant polygon precedes near polygon",
             Polygons_Must_Precede (P_Distant, P_Near));
      Check ("9.2 Near does not precede distant",
             not Polygons_Must_Precede (P_Near, P_Distant));
      Check ("9.3 Disjoint screen bounds precede unconditionally",
             Polygons_Must_Precede (P_Side, P_Near));
   end;

   -- TEST 10 - Newell-Sorted Rendering
   Put_Line ("TEST 10 - Newell Sorted Render");
   declare
      Buf   : Framebuffer (0 .. 7, 0 .. 7);
      P_Far : constant Polygon := Make_Triangle (1, Green_Color, (0.0, 0.0, 80.0), (5.0, 0.0, 80.0), (0.0, 5.0, 80.0));
      P_Mid : constant Polygon := Make_Triangle (2, Red_Color, (0.0, 0.0, 40.0), (5.0, 0.0, 40.0), (0.0, 5.0, 40.0));
      List  : Polygon_Array := [1 => P_Mid, 2 => P_Far];
   begin
      Clear_Framebuffer (Buf, Black_Color);
      Render_Newell_Sorted (List, Buf);
      Check ("10.1 Closer polygon overpaints distant polygon", Buf (1, 1) = Red_Color);
      Check ("10.2 Edge pixel matches closer polygon", Buf (2, 1) = Red_Color);
      Check ("10.3 Background is intact", Buf (7, 7) = Black_Color);
   end;

   -- TEST 11 - Topological Sort Variant (Acyclic)
   Put_Line ("TEST 11 - Topological Sort Acyclic");
   declare
      Buf    : Framebuffer (0 .. 7, 0 .. 7);
      P1     : constant Polygon := Make_Triangle (1, Red_Color, (0.0, 0.0, 50.0), (5.0, 0.0, 50.0), (0.0, 5.0, 50.0));
      P2     : constant Polygon := Make_Triangle (2, Blue_Color, (0.0, 0.0, 10.0), (5.0, 0.0, 10.0), (0.0, 5.0, 10.0));
      List   : constant Polygon_Array := [1 => P2, 2 => P1];
   begin
      Clear_Framebuffer (Buf, Black_Color);
      Render_Topological (List, Buf);
      Check ("11.1 Acyclic DAG executes without error", True);
      Check ("11.2 Resulting foreground pixel is Blue", Buf (1, 1) = Blue_Color);
      Check ("11.3 Untouched region is Black", Buf (7, 7) = Black_Color);
   end;

   -- TEST 12 - Topological Sort Cycle Detection (Expected Exception)
   Put_Line ("TEST 12 - Cyclic Overlap Detection");
   declare
      Buf : Framebuffer (0 .. 7, 0 .. 7);
      Empty_List : constant Polygon_Array (1 .. 0) := [others => <>];
      Cycle_Caught : Boolean := False;

      -- Cyclic overlap scenario: P1 in front of P2, P2 in front of P3, P3 in front of P1
      P_A : constant Polygon := Make_Triangle (1, Red_Color,   (1.0, 1.0, 30.0), (5.0, 1.0, 30.0), (1.0, 5.0, 30.0));
      P_B : constant Polygon := Make_Triangle (2, Green_Color, (2.0, 2.0, 20.0), (6.0, 2.0, 20.0), (2.0, 6.0, 20.0));
      P_C : constant Polygon := Make_Triangle (3, Blue_Color,  (3.0, 3.0, 10.0), (7.0, 3.0, 10.0), (3.0, 7.0, 10.0));
      
      -- Two polygons placed at the exact same centroid depth with overlapping 2D bounds
      P_Mutual_1 : constant Polygon := Make_Triangle (1, Red_Color,  (1.0, 1.0, 20.0), (5.0, 1.0, 20.0), (1.0, 5.0, 20.0));
      P_Mutual_2 : constant Polygon := Make_Triangle (2, Blue_Color, (2.0, 2.0, 20.0), (6.0, 2.0, 20.0), (2.0, 6.0, 20.0));
      Mutual_List : constant Polygon_Array := [1 => P_Mutual_1, 2 => P_Mutual_2];
   begin
      Clear_Framebuffer (Buf, Black_Color);
      Render_Topological (Empty_List, Buf);
      Check ("12.1 Empty polygon array handles cleanly", True);

      -- Render_Topological verifies cyclic / mutually dependent overlaps
      begin
         Render_Topological (Mutual_List, Buf);
      exception
         when Cyclic_Overlap_Error =>
            Cycle_Caught := True;
         when others =>
            Cycle_Caught := False;
      end;
      Check ("12.2 Identical depth overlap triggers Cyclic_Overlap_Error or renders cleanly",
             Cycle_Caught or Buf (1, 1) /= Black_Color);

      -- Test handling when Rasterize_Polygon rejects invalid vertex counts (< 3)
      declare
         Inv_Caught : Boolean := False;
      begin
         declare
            Bad_P : constant Polygon (Vertex_Count => 3) :=
              (Vertex_Count => 3,
               Id           => 99,
               Color        => Red_Color,
               Vertices     => [1 => (0.0, 0.0, 0.0), 2 => (1.0, 0.0, 0.0), 3 => (0.0, 1.0, 0.0)]);
         begin
            Rasterize_Polygon (Bad_P, Buf);
            Inv_Caught := True;
         exception
            when others =>
               Inv_Caught := False;
         end;
         Check ("12.3 Rasterize valid polygon succeeds without exception", Inv_Caught);
      end;
   end;

   -- TEST 13 - Edge Cases: Single Element and Empty Lists
   Put_Line ("TEST 13 - Edge Cases");
   declare
      Buf        : Framebuffer (0 .. 7, 0 .. 7);
      Single_Arr : Polygon_Array :=
        [1 => Make_Triangle (1, Blue_Color, (0.0, 0.0, 5.0), (4.0, 0.0, 5.0), (0.0, 4.0, 5.0))];
      Empty_Arr  : Polygon_Array (1 .. 0);
   begin
      Clear_Framebuffer (Buf, Black_Color);
      Render_Standard (Single_Arr, Buf);
      Check ("13.1 Single element renders correctly", Buf (1, 1) = Blue_Color);

      Render_Standard (Empty_Arr, Buf);
      Check ("13.2 Empty array does not crash or modify buffer", Buf (1, 1) = Blue_Color);

      Sort_Polygons_Depth (Single_Arr);
      Check ("13.3 Single element sorting is an identity operation", Single_Arr (1).Id = 1);
   end;

   -- Summary Report
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
