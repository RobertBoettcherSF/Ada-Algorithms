--  Standalone test suite for A_Star (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Optimality of Dist(Goal) under admissible H is checked here (not proved).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with A_Star; use A_Star;

procedure Tests
  with SPARK_Mode => Off
is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
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

   function Nat (X : Natural) return Natural is (X);

   function Zero_H (N : Vertex_Count_T) return Heuristic_Array is
      H : constant Heuristic_Array (1 .. Vertex_Id (N)) := [others => 0];
   begin
      return H;
   end Zero_H;

   G      : Graph;
   Dist   : Distance_Array (1 .. Max_Vertices);
   Prev   : Prev_Array (1 .. Max_Vertices);
   Path   : Path_Array (1 .. Max_Vertices);
   Len    : Natural;
   Ok     : Boolean;
   Found  : Boolean;
   Exp    : Natural;
   Exp0   : Natural;
   H      : Heuristic_Array (1 .. Max_Vertices);

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Check (Well_Formed (G), "empty well-formed");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   H (1) := 0;
   Search (G, 1, 1, H (1 .. 1), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 1 and then Path (1) = 1, "single path");
   Check (Dist (1) = 0, "single Dist(1)=0");
   Check (Prev (1) = 0, "single Prev(1)=0");
   Check (Exp = 1, "single one expansion");

   Add_Edge (G, 1, 1, 5);
   Check (Edge_Count (G) = 1, "self-loop edge count");
   Search (G, 1, 1, H (1 .. 1), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (1) = 0, "self-loop Dist still 0");

   Add_Edge (G, 1, 1, 0);
   Check (Edge_Count (G) = 2, "zero-weight self-loop");
   Search (G, 1, 1, H (1 .. 1), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (1) = 0, "zero self-loop Dist 0");

   ------------------------------------------------------------------
   Section ("2. Two-vertex digraphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   H (1) := 0; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp);
   Check (not Found and then Len = 0, "2 isolated not found");
   Check (Dist (1) = 0, "2 isolated Dist(1)=0");
   Check (Dist (2) = Infinity, "2 isolated Dist(2)=Inf");

   Add_Edge (G, 1, 2, 7);
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (2) = 7, "2 direct Dist=7");
   Check (Len = 2 and then Path (1) = 1 and then Path (2) = 2,
          "2 direct path");
   Check (Prev (2) = 1, "2 direct Prev");

   H (1) := 5; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (2) = 7, "2 with H Dist still 7");

   Clear (G, 2);
   Add_Edge (G, 2, 1, 3);
   H (1) := 0; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp);
   Check (not Found, "reverse-only unreachable");
   Search (G, 2, 1, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (1) = 3, "reverse source Dist=3");

   ------------------------------------------------------------------
   Section ("3. Multi-hop optimal diamond");
   ------------------------------------------------------------------
   --  Classic diamond: 1→2(1), 1→3(4), 2→3(1), 2→4(5), 3→4(1)
   --  Optimal 1→4 cost 3 via 1-2-3-4
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   H (1) := 0; H (2) := 0; H (3) := 0; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (4) = 3, "diamond Dist=3");
   Check (Dist (2) = 1 and then Dist (3) = 2, "diamond Dist mid");
   Check (Len = 4, "diamond path len 4");
   Check (Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 3 and then Path (4) = 4,
          "diamond via 2-3");

   H (1) := 2; H (2) := 1; H (3) := 1; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (4) = 3, "diamond admissible Dist=3");
   Check (Len = 4, "diamond admissible path len");

   ------------------------------------------------------------------
   Section ("4. Disconnected / unreachable");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 4, 5, 1);
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 5, H (1 .. 5), Dist, Prev, Path, Len, Found, Exp);
   Check (not Found and then Len = 0, "disconnected not found");
   Check (Dist (5) = Infinity, "disconnected Dist Inf");
   Check (Dist (3) = 2, "disconnected reachable Dist3");
   Search (G, 1, 3, H (1 .. 5), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (3) = 2, "connected component ok");

   ------------------------------------------------------------------
   Section ("5. Zero heuristic ≡ Dijkstra");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 5, 10);
   Add_Edge (G, 4, 6, 1);
   Add_Edge (G, 5, 6, 1);
   declare
      HZ : constant Heuristic_Array := Zero_H (6);
   begin
      H (1 .. 6) := HZ;
   end;
   Search (G, 1, 6, H (1 .. 6), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (6) = 9, "zero-H Dist6=9");
   Check (Dist (2) = 3 and then Dist (3) = 2, "zero-H mids");
   Check (Dist (4) = 8 and then Dist (5) = 12, "zero-H 4/5");
   Reconstruct_Path (Prev, 1, 6, 6, Path, Len, Ok);
   Check (Ok and then Len = 5, "zero-H path len 5");
   Check (Path (1) = 1 and then Path (5) = 6, "zero-H ends");

   ------------------------------------------------------------------
   Section ("6. Admissible Manhattan-style grid");
   ------------------------------------------------------------------
   --  3x3 grid, vertices 1..9 row-major. Unit cost 4-neighbour edges.
   Clear (G, 9);
   declare
      procedure Link (A, B : Vertex_Id) is
      begin
         Add_Edge (G, A, B, 1);
         Add_Edge (G, B, A, 1);
      end Link;
   begin
      Link (1, 2); Link (2, 3);
      Link (4, 5); Link (5, 6);
      Link (7, 8); Link (8, 9);
      Link (1, 4); Link (4, 7);
      Link (2, 5); Link (5, 8);
      Link (3, 6); Link (6, 9);
   end;
   H (1) := 4; H (2) := 3; H (3) := 2;
   H (4) := 3; H (5) := 2; H (6) := 1;
   H (7) := 2; H (8) := 1; H (9) := 0;
   Search (G, 1, 9, H (1 .. 9), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (9) = 4, "grid Manhattan Dist=4");
   Check (Len = 5, "grid path 5 vertices");
   Check (Path (1) = 1 and then Path (Len) = 9, "grid ends");

   declare
      Exp_Z   : Natural;
      Dist_Z  : Distance_Array (1 .. Max_Vertices);
      Prev_Z  : Prev_Array (1 .. Max_Vertices);
      Path_Z  : Path_Array (1 .. Max_Vertices);
      Len_Z   : Natural;
      Found_Z : Boolean;
      HZ      : constant Heuristic_Array (1 .. 9) := [others => 0];
   begin
      Search (G, 1, 9, HZ, Dist_Z, Prev_Z, Path_Z, Len_Z, Found_Z, Exp_Z);
      Check (Found_Z and then Dist_Z (9) = 4, "grid zero-H Dist=4");
      Check (Exp <= Exp_Z, "Manhattan expands ≤ zero-H");
      Check (Exp >= 1, "Manhattan expanded something");
   end;

   ------------------------------------------------------------------
   Section ("7. Consistent vs inconsistent admissible");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 5);
   H (1) := 4; H (2) := 2; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (3) = 4, "consistent Dist=4");
   Check (Len = 3 and then Path (2) = 2, "consistent via 2");

   H (1) := 3; H (2) := 0; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (3) = 4, "inconsistent-adm Dist=4");

   ------------------------------------------------------------------
   Section ("8. Parallel edges / zero weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 2, 3, 4);
   H (1) := 0; H (2) := 0; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (2) = 3, "parallel min Dist2");
   Check (Dist (3) = 3, "zero-weight Dist3");
   Check (Len = 3, "parallel path len");

   ------------------------------------------------------------------
   Section ("9. Clear / rebuild / Well_Formed");
   ------------------------------------------------------------------
   Clear (G, 4);
   Check (Vertex_Count (G) = 4, "rebuild N=4");
   Check (Edge_Count (G) = 0, "rebuild E=0");
   Check (Well_Formed (G), "rebuild well-formed");
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Check (Edge_Count (G) = 2, "rebuild E=2");
   Check (Well_Formed (G), "after edges well-formed");
   Clear (G, 2);
   Check (Vertex_Count (G) = 2 and then Edge_Count (G) = 0,
          "Clear resets edges");
   Add_Edge (G, 1, 2, 9);
   H (1) := 0; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (2) = 9, "after rebuild Dist");

   ------------------------------------------------------------------
   Section ("10. Chains and shortcuts");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 1, 5, 100);
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := Heuristic_Value (5 - V);
   end loop;
   H (5) := 0;
   Search (G, 1, 5, H (1 .. 5), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (5) = 4, "chain Dist=4 not 100");
   Check (Len = 5, "chain full path");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, 20);
   H (1) := 0; H (2) := 0; H (3) := 0; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (4) = 3, "shortcut Dist=3");

   ------------------------------------------------------------------
   Section ("11. Stars / wide fan-out");
   ------------------------------------------------------------------
   Clear (G, 21);
   for I in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, I, Weight_Type (I - 1));
   end loop;
   for V in Vertex_Id range 1 .. 21 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 21, H (1 .. 21), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (21) = 20, "star Dist21");
   Check (Dist (11) = 10, "star Dist11");
   Check (Prev (21) = 1 and then Len = 2, "star direct");

   ------------------------------------------------------------------
   Section ("12. Layered DAG");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 2, 5, 9);
   Add_Edge (G, 3, 5, 1);
   Add_Edge (G, 3, 6, 2);
   Add_Edge (G, 4, 7, 4);
   Add_Edge (G, 5, 7, 1);
   Add_Edge (G, 6, 7, 10);
   for V in Vertex_Id range 1 .. 7 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 7, H (1 .. 7), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (7) = 7, "layered Dist7");
   Check (Len = 4, "layered path len");
   Check (Path (1) = 1 and then Path (2) = 3
            and then Path (3) = 5 and then Path (4) = 7,
          "layered via 3-5");

   H (1) := 6; H (2) := 4; H (3) := 2; H (4) := 3;
   H (5) := 1; H (6) := 8; H (7) := 0;
   Search (G, 1, 7, H (1 .. 7), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (7) = 7, "layered guided Dist7");

   ------------------------------------------------------------------
   Section ("13. Reconstruct_Path agreement");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 5, 10);
   Add_Edge (G, 4, 6, 1);
   Add_Edge (G, 5, 6, 1);
   for V in Vertex_Id range 1 .. 6 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 6, H (1 .. 6), Dist, Prev, Path, Len, Found, Exp);
   Check (Found, "recon search found");
   Reconstruct_Path (Prev, 1, 6, 6, Path, Len, Ok);
   Check (Ok and then Path (1) = 1 and then Path (Len) = 6,
          "Recon agrees");
   Reconstruct_Path (Prev, 1, 1, 6, Path, Len, Ok);
   Check (Ok and then Len = 1 and then Path (1) = 1, "Recon source alone");

   ------------------------------------------------------------------
   Section ("14. Early stop: guiding H");
   ------------------------------------------------------------------
   Clear (G, 8);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 1, 5, 1);
   Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 6, 7, 1);
   Add_Edge (G, 7, 8, 1);
   for V in Vertex_Id range 1 .. 8 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 4, H (1 .. 8), Dist, Prev, Path, Len, Found, Exp0);
   Check (Found and then Dist (4) = 3, "early zero-H Dist");

   H (1) := 3; H (2) := 2; H (3) := 1; H (4) := 0;
   H (5) := 100; H (6) := 100; H (7) := 100; H (8) := 100;
   Search (G, 1, 4, H (1 .. 8), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (4) = 3, "early guided Dist");
   Check (Exp <= Exp0, "guiding H expands ≤ zero-H");

   ------------------------------------------------------------------
   Section ("15. Larger chain within Max_Vertices");
   ------------------------------------------------------------------
   Clear (G, 30);
   for I in 1 .. 29 loop
      Add_Edge (G, I, I + 1, 1);
   end loop;
   Add_Edge (G, 1, 10, 20);
   Add_Edge (G, 5, 15, 5);
   Add_Edge (G, 10, 20, 3);
   Add_Edge (G, 15, 30, 50);
   for V in Vertex_Id range 1 .. 30 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 30, H (1 .. 30), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (30) = 22, "chain30 Dist=22 via shortcuts");
   Check (Len = 21, "chain30 path len 21");

   --  Admissible underestimate (never overestimates true remaining).
   --  Chain-distance H would be inadmissible once shortcuts exist.
   for V in Vertex_Id range 1 .. 29 loop
      H (V) := 1;
   end loop;
   H (30) := 0;
   Search (G, 1, 30, H (1 .. 30), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (30) = 22, "chain30 admissible-H Dist=22");

   ------------------------------------------------------------------
   Section ("16. Max_Vertices / Max_Edges classroom bounds");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Clear Max_Vertices");
   for I in 1 .. Max_Vertices - 1 loop
      Add_Edge (G, I, I + 1, 1);
   end loop;
   Check (Edge_Count (G) = Max_Vertices - 1, "chain Max_Vertices edges");
   declare
      HZ : constant Heuristic_Array (1 .. Max_Vertices) := [others => 0];
   begin
      Search (G, 1, Vertex_Id (Max_Vertices), HZ,
              Dist, Prev, Path, Len, Found, Exp);
      Check (Found and then
               Dist (Vertex_Id (Max_Vertices)) =
                 Distance_Value (Max_Vertices - 1),
             "Max_Vertices chain Dist");
      Check (Len = Max_Vertices, "Max_Vertices path len");
   end;

   Clear (G, 2);
   for I in 1 .. Max_Edges loop
      Add_Edge (G, 1, 2, 1);
   end loop;
   Check (Edge_Count (G) = Max_Edges, "filled Max_Edges");
   Check (Well_Formed (G), "Max_Edges well-formed");
   H (1) := 0; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (2) = 1, "parallel Max_Edges Dist=1");

   ------------------------------------------------------------------
   Section ("17. Contract helpers");
   ------------------------------------------------------------------
   Check (Arrays_OK (4, Dist, Prev, Path), "Arrays_OK live");
   Check (not Arrays_OK (0, Dist, Prev, Path), "Arrays_OK rejects N=0");
   Check (Heuristic_OK (4, H (1 .. 4)), "Heuristic_OK live");
   Check (not Heuristic_OK (0, H (1 .. 1)), "Heuristic_OK rejects N=0");
   Check (Nat (Max_Vertices) = 32, "Max_Vertices=32");
   Check (Nat (Max_Edges) = 256, "Max_Edges=256");

   ------------------------------------------------------------------
   Section ("18. Zero-weight path / equal f tie-break");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   H (1) := 0; H (2) := 0; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (3) = 0, "all-zero weights Dist=0");
   Check (Len = 3, "all-zero path len");

   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
