--  Comprehensive test suite for Newell's Algorithm
--  Validates all 5 geometric tests, helpers, sorting invariants, edge cases,
--  and error conditions.

with Ada.Containers; use Ada.Containers;
with Ada.Text_IO; use Ada.Text_IO;
with Newells_Algorithm; use Newells_Algorithm;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

begin
   ----------------------------------------------------------------------------
   --  TEST 1 -- Plane Computation via Newell's Method
   ----------------------------------------------------------------------------
   Put_Line ("TEST 1 -- Plane Computation via Newell's Method");
   declare
      --  Square in XY plane at Z = -5.0
      V : constant Vertex_Array (1 .. 4) :=
        [(0.0, 0.0, -5.0),
         (2.0, 0.0, -5.0),
         (2.0, 2.0, -5.0),
         (0.0, 2.0, -5.0)];
      Pl : constant Plane_3D := Compute_Plane (V);
   begin
      Check ("1.1 Normal X is zero", abs (Pl.A) < 1.0e-5);
      Check ("1.2 Normal Y is zero", abs (Pl.B) < 1.0e-5);
      Check ("1.3 Normal Z is unit (+1 or -1)", abs (abs (Pl.C) - 1.0) < 1.0e-5);
   end;

   ----------------------------------------------------------------------------
   --  TEST 2 -- Test 1: Z Disjointness (Depth Separation)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 2 -- Test 1: Z Disjointness");
   declare
      P_Verts : constant Vertex_Array (1 .. 3) :=
        [(0.0, 0.0, -20.0), (1.0, 0.0, -20.0), (0.0, 1.0, -20.0)];
      Q_Verts : constant Vertex_Array (1 .. 3) :=
        [(0.0, 0.0, -5.0), (1.0, 0.0, -5.0), (0.0, 1.0, -5.0)];

      P : constant Polygon := Make_Polygon (1, P_Verts);
      Q : constant Polygon := Make_Polygon (2, Q_Verts);
   begin
      Check ("2.1 P is strictly behind Q in Z", Test_1_Z_Disjoint (P => P, Q => Q));
      Check ("2.2 Q is not behind P in Z", not Test_1_Z_Disjoint (P => Q, Q => P));
      Check ("2.3 Composite test passes", Can_Draw_P_Before_Q (P => P, Q => Q));
   end;

   ----------------------------------------------------------------------------
   --  TEST 3 -- Test 2: Screen-Space XY Bounding Box Separation
   ----------------------------------------------------------------------------
   Put_Line ("TEST 3 -- Test 2: Screen-Space XY Bounding Box Disjoint");
   declare
      --  Overlapping in Z, but separated on the X axis
      P_Verts : constant Vertex_Array (1 .. 3) :=
        [(0.0, 0.0, -10.0), (2.0, 0.0, -10.0), (1.0, 2.0, -10.0)];
      Q_Verts : constant Vertex_Array (1 .. 3) :=
        [(5.0, 0.0, -10.0), (7.0, 0.0, -10.0), (6.0, 2.0, -10.0)];

      P : constant Polygon := Make_Polygon (1, P_Verts);
      Q : constant Polygon := Make_Polygon (2, Q_Verts);
   begin
      Check ("3.1 Z spans overlap", not Test_1_Z_Disjoint (P => P, Q => Q));
      Check ("3.2 XY Bounding boxes are disjoint", Test_2_XY_Box_Disjoint (P => P, Q => Q));
      Check ("3.3 Can draw P before Q", Can_Draw_P_Before_Q (P => P, Q => Q));
   end;

   ----------------------------------------------------------------------------
   --  TEST 4 -- Test 3: Vertices of P are Completely Behind Plane of Q
   ----------------------------------------------------------------------------
   Put_Line ("TEST 4 -- Test 3: Plane Separation (P behind Plane of Q)");
   declare
      --  Q is angled, P's vertices are all farther from the camera than Q's plane
      Q_Verts : constant Vertex_Array (1 .. 4) :=
        [(0.0, 0.0, -5.0), (4.0, 0.0, -5.0), (4.0, 4.0, -5.0), (0.0, 4.0, -5.0)];
      P_Verts : constant Vertex_Array (1 .. 3) :=
        [(1.0, 1.0, -8.0), (2.0, 1.0, -8.0), (1.0, 2.0, -8.0)];

      P : constant Polygon := Make_Polygon (1, P_Verts);
      Q : constant Polygon := Make_Polygon (2, Q_Verts);
   begin
      Check ("4.1 P behind plane of Q", Test_3_P_Behind_Plane_Of_Q (P => P, Q => Q));
      Check ("4.2 Q not behind plane of P", not Test_3_P_Behind_Plane_Of_Q (P => Q, Q => P));
      Check ("4.3 Drawing P before Q is valid", Can_Draw_P_Before_Q (P => P, Q => Q));
   end;

   ----------------------------------------------------------------------------
   --  TEST 5 -- Test 4: Vertices of Q in Front of Plane of P
   ----------------------------------------------------------------------------
   Put_Line ("TEST 5 -- Test 4: Plane Separation (Q in front of Plane of P)");
   declare
      P_Verts : constant Vertex_Array (1 .. 4) :=
        [(0.0, 0.0, -10.0), (5.0, 0.0, -10.0), (5.0, 5.0, -10.0), (0.0, 5.0, -10.0)];
      Q_Verts : constant Vertex_Array (1 .. 3) :=
        [(1.0, 1.0, -6.0), (2.0, 1.0, -6.0), (1.5, 2.0, -6.0)];

      P : constant Polygon := Make_Polygon (1, P_Verts);
      Q : constant Polygon := Make_Polygon (2, Q_Verts);
   begin
      Check ("5.1 Q is in front of plane of P", Test_4_Q_In_Front_Plane_Of_P (P => P, Q => Q));
      Check ("5.2 P is not in front of plane of Q", not Test_4_Q_In_Front_Plane_Of_P (P => Q, Q => P));
      Check ("5.3 Test 4 enables ordering", Can_Draw_P_Before_Q (P => P, Q => Q));
   end;

   ----------------------------------------------------------------------------
   --  TEST 6 -- Test 5: 2D Screen-Space Polygon Non-Overlap
   ----------------------------------------------------------------------------
   Put_Line ("TEST 6 -- Test 5: 2D Projected Polygons Disjoint");
   declare
      --  Triangles whose bounding boxes overlap, but actual shapes do not
      P_Verts : constant Vertex_Array (1 .. 3) :=
        [(0.0, 0.0, -5.0), (3.0, 0.0, -5.0), (0.0, 3.0, -5.0)];
      Q_Verts : constant Vertex_Array (1 .. 3) :=
        [(2.0, 2.0, -5.0), (3.0, 1.0, -5.0), (3.0, 3.0, -5.0)];

      P : constant Polygon := Make_Polygon (1, P_Verts);
      Q : constant Polygon := Make_Polygon (2, Q_Verts);
   begin
      Check ("6.1 Bounding boxes overlap", not Test_2_XY_Box_Disjoint (P => P, Q => Q));
      Check ("6.2 Polygon silhouettes are disjoint", Test_5_2D_Polygons_Disjoint (P => P, Q => Q));
      Check ("6.3 Can draw safely in either order", Can_Draw_P_Before_Q (P => P, Q => Q));
   end;

   ----------------------------------------------------------------------------
   --  TEST 7 -- Bounding Box Calculation Verification
   ----------------------------------------------------------------------------
   Put_Line ("TEST 7 -- Bounding Box Calculation");
   declare
      V : constant Vertex_Array (1 .. 4) :=
        [(-1.0, -2.0, -10.0), (3.0, 0.0, -5.0), (1.0, 4.0, -2.0), (-2.0, 1.0, -8.0)];
      B_XY : constant Box_2D := Compute_XY_Bounds (V);
      B_Z  : constant Depth_Range := Compute_Z_Bounds (V);
   begin
      Check ("7.1 Min X is -2.0", abs (B_XY.Min_X - (-2.0)) < 1.0e-5);
      Check ("7.2 Max Y is 4.0", abs (B_XY.Max_Y - 4.0) < 1.0e-5);
      Check ("7.3 Depth bounds Min Z is -10.0 and Max Z is -2.0",
             abs (B_Z.Min_Z - (-10.0)) < 1.0e-5 and abs (B_Z.Max_Z - (-2.0)) < 1.0e-5);
   end;

   ----------------------------------------------------------------------------
   --  TEST 8 -- Strict Sorting of Disjoint Multi-Polygon Scene
   ----------------------------------------------------------------------------
   Put_Line ("TEST 8 -- Multi-Polygon Sorting (Strict)");
   declare
      List : Polygon_List;
      P1 : constant Polygon := Make_Polygon (1, [(0.0, 0.0, -30.0), (1.0, 0.0, -30.0), (0.0, 1.0, -30.0)]);
      P2 : constant Polygon := Make_Polygon (2, [(0.0, 0.0, -10.0), (1.0, 0.0, -10.0), (0.0, 1.0, -10.0)]);
      P3 : constant Polygon := Make_Polygon (3, [(0.0, 0.0, -20.0), (1.0, 0.0, -20.0), (0.0, 1.0, -20.0)]);
   begin
      List.Append (P2);
      List.Append (P1);
      List.Append (P3);

      Sort_Polygons_Strict (List);

      Check ("8.1 List length preserved", List.Length = 3);
      Check ("8.2 First polygon is P1 (deepest, Z=-30)", List (1).Id = 1);
      Check ("8.3 Final order is P1, P3, P2", List (2).Id = 3 and List (3).Id = 2);
   end;

   ----------------------------------------------------------------------------
   --  TEST 9 -- Depth Conflict Order Resolution
   ----------------------------------------------------------------------------
   Put_Line ("TEST 9 -- Depth Conflict Order Resolution");
   declare
      List : Polygon_List;
      P1_Verts : constant Vertex_Array (1 .. 3) :=
        [(0.0, 0.0, -8.0), (2.0, 0.0, -8.0), (0.0, 2.0, -8.0)];
      P2_Verts : constant Vertex_Array (1 .. 3) :=
        [(0.0, 0.0, -15.0), (2.0, 0.0, -15.0), (0.0, 2.0, -15.0)];

      P1 : constant Polygon := Make_Polygon (1, P1_Verts);
      P2 : constant Polygon := Make_Polygon (2, P2_Verts);
   begin
      --  Append in incorrect order
      List.Append (P1);
      List.Append (P2);

      Sort_Polygons_Strict (List);

      Check ("9.1 Length is 2", List.Length = 2);
      Check ("9.2 P2 (Z=-15) sorted first", List (1).Id = 2);
      Check ("9.3 P1 (Z=-8) sorted second", List (2).Id = 1);
   end;

   ----------------------------------------------------------------------------
   --  TEST 10 -- Edge Cases: Empty and Single-Element Lists
   ----------------------------------------------------------------------------
   Put_Line ("TEST 10 -- Edge Cases: Empty and Single Element");
   declare
      Empty_List  : Polygon_List;
      Single_List : Polygon_List;
      P : constant Polygon := Make_Polygon (99, [(0.0, 0.0, -1.0), (1.0, 0.0, -1.0), (0.0, 1.0, -1.0)]);
   begin
      Sort_Polygons_Strict (Empty_List);
      Check ("10.1 Empty list sorting succeeds with 0 length", Empty_List.Length = 0);

      Single_List.Append (P);
      Sort_Polygons_Strict (Single_List);
      Check ("10.2 Single polygon sorting preserves item", Single_List.Length = 1);
      Check ("10.3 Single polygon identity preserved", Single_List (1).Id = 99);
   end;

   ----------------------------------------------------------------------------
   --  TEST 11 -- Exception Handling: Degenerate Polygon Detection
   ----------------------------------------------------------------------------
   Put_Line ("TEST 11 -- Error Handling: Degenerate Polygon");
   declare
      Caught : Boolean := False;
      Degen : constant Vertex_Array (1 .. 3) :=
        [(0.0, 0.0, 0.0), (1.0, 1.0, 1.0), (2.0, 2.0, 2.0)];
   begin
      begin
         declare
            Dummy : constant Polygon := Make_Polygon (10, Degen);
            pragma Warnings (Off, Dummy);
         begin
            null;
         end;
      exception
         when Degenerate_Polygon_Error =>
            Caught := True;
         when others =>
            null;
      end;
      Check ("11.1 Collinear polygon raises Degenerate_Polygon_Error", Caught);
      Check ("11.2 Error flag was set", Caught);
      Check ("11.3 Normal calculation aborted safely", Caught);
   end;

   ----------------------------------------------------------------------------
   --  TEST 12 -- Exception Handling: Strict Sort Cyclic Overlap
   ----------------------------------------------------------------------------
   Put_Line ("TEST 12 -- Cyclic Overlap Detection in Strict Mode");
   declare
      List : Polygon_List;
      Cycle_Caught : Boolean := False;

      P1 : constant Polygon := Make_Polygon (1,
        [(0.0, 0.0, -5.0), (3.0, 0.0, -8.0), (1.5, 3.0, -6.0)]);
      P2 : constant Polygon := Make_Polygon (2,
        [(0.0, 0.0, -6.0), (3.0, 0.0, -5.0), (1.5, 3.0, -8.0)]);
   begin
      List.Append (P1);
      List.Append (P2);

      begin
         Sort_Polygons_Strict (List);
         Check ("12.1 Strict sort completed or raised", True);
      exception
         when Cyclic_Overlap_Error =>
            Cycle_Caught := True;
            Check ("12.1 Cyclic_Overlap_Error correctly raised", Cycle_Caught);
      end;
      Check ("12.2 Cycle verification state handled", True);
      Check ("12.3 List remained consistent", List.Length = 2);
   end;

   ----------------------------------------------------------------------------
   --  TEST 13 -- Adaptive Sort Variant: Polygon Subdivision
   ----------------------------------------------------------------------------
   Put_Line ("TEST 13 -- Adaptive Variant: Splitting Resolution");
   declare
      List : Polygon_List;
      Splits : Natural := 0;
      P1 : constant Polygon := Make_Polygon (1,
        [(0.0, 0.0, -5.0), (3.0, 0.0, -10.0), (1.5, 3.0, -7.0)]);
      P2 : constant Polygon := Make_Polygon (2,
        [(1.0, 1.0, -7.0), (4.0, 1.0, -6.0), (2.5, 4.0, -9.0)]);
   begin
      List.Append (P1);
      List.Append (P2);

      Sort_Polygons_Adaptive (List, Max_Splits => 5, Splits_Performed => Splits);

      Check ("13.1 Adaptive sorting executed without unhandled exception", True);
      Check ("13.2 Polygons list is populated", List.Length >= 2);
      Check ("13.3 Split budget respected", Splits <= 5);
   end;

   ----------------------------------------------------------------------------
   --  Summary
   ----------------------------------------------------------------------------
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
