--  Standalone test suite for A_Star (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with A_Star; use A_Star;

procedure Tests is

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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function Int (X : Integer) return Integer is (X);

   function Zero_H (N : Natural) return Heuristic_Array is
      H : constant Heuristic_Array (1 .. Vertex_Id (N)) := [others => 0];
   begin
      return H;
   end Zero_H;

   function Clear_Raises (Vertex_Count : Natural) return Boolean is
      G : Graph;
   begin
      Clear (G, Vertex_Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Clear_Raises;

   function Add_Raises
     (G : in out Graph; From, To : Vertex_Id; W : Integer) return Boolean
   is
   begin
      Add_Edge (G, From, To, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Search_Raises
     (G : Graph; Source, Goal : Vertex_Id; H : Heuristic_Array;
      Dist_Last, Prev_Last, Path_Last : Positive) return Boolean
   is
      Dist   : Distance_Array (1 .. Vertex_Id (Dist_Last));
      Prev   : Prev_Array (1 .. Vertex_Id (Prev_Last));
      Path   : Path_Array (1 .. Path_Last);
      Length : Natural;
      Found  : Boolean;
   begin
      Search (G, Source, Goal, H, Dist, Prev, Path, Length, Found);
      pragma Unreferenced (Length, Found);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises;

   function Dist_Raises
     (G : Graph; Source, Goal : Vertex_Id; H : Heuristic_Array)
      return Boolean
   is
      D : Distance_Value;
   begin
      D := Distance (G, Source, Goal, H);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Raises;

   function Recon_Raises
     (Prev : Prev_Array; Source, Target : Vertex_Id;
      Path_First, Path_Last : Positive) return Boolean
   is
      Path   : Path_Array (Path_First .. Path_Last);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Reconstruct_Path (Prev, Source, Target, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Recon_Raises;

   G      : Graph;
   Dist   : Distance_Array (Vertex_Id);
   Prev   : Prev_Array (Vertex_Id);
   Path   : Path_Array (1 .. Max_Vertices);
   Len    : Natural;
   Ok     : Boolean;
   Found  : Boolean;
   D      : Distance_Value;
   Exp    : Natural;
   Exp0   : Natural;
   H      : Heuristic_Array (Vertex_Id);

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Check (Search_Raises (G, 1, 1, Zero_H (1),
                         Max_Vertices, Max_Vertices, Max_Vertices),
          "empty Search raises");
   Check (Dist_Raises (G, 1, 1, Zero_H (1)), "empty Distance raises");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   H (1) := 0;
   Search (G, 1, 1, H (1 .. 1), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Len = 1 and then Path (1) = 1, "single path");
   Check (Dist (1) = 0, "single Dist(1)=0");
   Check (Prev (1) = 0, "single Prev(1)=0");
   Check (Distance (G, 1, 1, H (1 .. 1)) = 0, "single Distance 0");
   Check (Exp = 1, "single one expansion");

   Add_Edge (G, 1, 1, 5);
   Check (Edge_Count (G) = 1, "self-loop edge count");
   Search (G, 1, 1, H (1 .. 1), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (1) = 0, "self-loop Dist still 0");

   Add_Edge (G, 1, 1, 0);
   Check (Edge_Count (G) = 2, "zero-weight self-loop");
   Search (G, 1, 1, H (1 .. 1), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (1) = 0, "zero self-loop Dist 0");

   ------------------------------------------------------------------
   Section ("2. Two-vertex digraphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   H (1) := 0; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found);
   Check (not Found and then Len = 0, "2 isolated not found");
   Check (Dist (1) = 0, "2 isolated Dist(1)=0");
   Check (Dist (2) = Infinity, "2 isolated Dist(2)=Inf");
   Check (Distance (G, 1, 2, H (1 .. 2)) = Infinity, "2 isolated Dist Inf");

   Add_Edge (G, 1, 2, 7);
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (2) = 7, "2 direct Dist=7");
   Check (Len = 2 and then Path (1) = 1 and then Path (2) = 2,
          "2 direct path");
   Check (Prev (2) = 1, "2 direct Prev");
   D := Find_Path (G, 1, 2, H (1 .. 2), Path, Len);
   Check (D = 7 and then Len = 2, "2 Find_Path");

   --  Zero heuristic ≡ Dijkstra
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp0);
   H (1) := 5; H (2) := 0;  -- admissible if true remaining ≤ 5 from 1
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (2) = 7, "2 with H Dist still 7");

   Clear (G, 2);
   Add_Edge (G, 2, 1, 3);
   H (1) := 0; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found);
   Check (not Found, "reverse-only unreachable");
   Search (G, 2, 1, H (1 .. 2), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (1) = 3, "reverse source Dist=3");

   ------------------------------------------------------------------
   Section ("3. Multi-hop optimal");
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
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (4) = 3, "diamond Dist=3");
   Check (Dist (2) = 1 and then Dist (3) = 2, "diamond Dist mid");
   Check (Len = 4, "diamond path len 4");
   Check (Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 3 and then Path (4) = 4,
          "diamond via 2-3");

   --  Admissible underestimates
   H (1) := 2; H (2) := 1; H (3) := 1; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found);
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
   Search (G, 1, 5, H (1 .. 5), Dist, Prev, Path, Len, Found);
   Check (not Found and then Len = 0, "disconnected not found");
   Check (Dist (5) = Infinity, "disconnected Dist Inf");
   Check (Dist (3) = 2, "disconnected reachable Dist3");
   Search (G, 1, 3, H (1 .. 5), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (3) = 2, "connected component ok");
   Check (Distance (G, 4, 1, H (1 .. 5)) = Infinity, "no reverse path");

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
   for V in Vertex_Id range 1 .. 6 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 6, H (1 .. 6), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (6) = 9, "zero-H Dist6=9");
   --  1→3→2→4→6 = 2+1+5+1 = 9
   Check (Dist (2) = 3 and then Dist (3) = 2, "zero-H mids");
   Check (Dist (4) = 8 and then Dist (5) = 12, "zero-H 4/5");
   Ok := Reconstruct_Path (Prev, 1, 6, Path, Len);
   Check (Ok and then Len = 5, "zero-H path len 5");
   Check (Path (1) = 1 and then Path (5) = 6, "zero-H ends");

   ------------------------------------------------------------------
   Section ("6. Admissible Manhattan-style grid");
   ------------------------------------------------------------------
   --  3x3 grid, vertices 1..9 row-major. Unit cost 4-neighbour edges.
   --  Goal = 9 (bottom-right). Manhattan H from (r,c) to (3,3):
   --  |r-3|+|c-3|. Consistent on unit grid ⇒ optimal.
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
   --  Row-major: 1=(1,1) 2=(1,2) 3=(1,3)
   --             4=(2,1) 5=(2,2) 6=(2,3)
   --             7=(3,1) 8=(3,2) 9=(3,3)
   H (1) := 4; H (2) := 3; H (3) := 2;
   H (4) := 3; H (5) := 2; H (6) := 1;
   H (7) := 2; H (8) := 1; H (9) := 0;
   Search (G, 1, 9, H (1 .. 9), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (9) = 4, "grid Manhattan Dist=4");
   Check (Len = 5, "grid path 5 vertices");
   Check (Path (1) = 1 and then Path (Len) = 9, "grid ends");

   --  Same cost with zero H (Dijkstra); Manhattan should expand ≤ zero-H
   declare
      Exp_Z : Natural;
      Dist_Z : Distance_Array (Vertex_Id);
      Prev_Z : Prev_Array (Vertex_Id);
      Path_Z : Path_Array (1 .. Max_Vertices);
      Len_Z  : Natural;
      Found_Z : Boolean;
      HZ : constant Heuristic_Array (1 .. 9) := [others => 0];
   begin
      Search (G, 1, 9, HZ, Dist_Z, Prev_Z, Path_Z, Len_Z, Found_Z, Exp_Z);
      Check (Found_Z and then Dist_Z (9) = 4, "grid zero-H Dist=4");
      Check (Exp <= Exp_Z, "Manhattan expands ≤ zero-H");
      Check (Exp >= 1, "Manhattan expanded something");
   end;

   ------------------------------------------------------------------
   Section ("7. Consistent vs inconsistent (comments + behaviour)");
   ------------------------------------------------------------------
   --  Consistent: H(U) ≤ c(U,W) + H(W) for every edge.
   --  Admissible but inconsistent can still be optimal with reopen.
   --  Graph: 1→2(1), 1→3(100), 2→3(100), Goal=3.
   --  Consistent H: H(1)=2, H(2)=1, H(3)=0  (true costs: 1→3 via 2 is 101? wait)
   --  Better: 1→2(2), 2→3(2), 1→3(5). Optimal = 4 via 1-2-3.
   Clear (G, 3);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 5);
   --  Consistent admissible: H(1)=4, H(2)=2, H(3)=0
   H (1) := 4; H (2) := 2; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (3) = 4, "consistent Dist=4");
   Check (Len = 3 and then Path (2) = 2, "consistent via 2");

   --  Inconsistent but admissible: H(1)=0, H(2)=3, H(3)=0
   --  (H(2)=3 > true remaining 2 — wait that's NOT admissible)
   --  Admissible: H ≤ true. True remaining: from1=4, from2=2, from3=0.
   --  Inconsistent admissible: H(1)=3, H(2)=0, H(3)=0
   --  Check: H(1)=3 ≰? c(1,2)+H(2)=2+0=2, so 3 > 2 ⇒ inconsistent.
   --  Still admissible (3≤4, 0≤2, 0≤0).
   H (1) := 3; H (2) := 0; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (3) = 4, "inconsistent-adm Dist=4");

   ------------------------------------------------------------------
   Section ("8. Parallel edges / zero weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 2, 3);   -- parallel cheaper
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 2, 3, 4);   -- parallel worse
   H (1) := 0; H (2) := 0; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (2) = 3, "parallel min Dist2");
   Check (Dist (3) = 3, "zero-weight Dist3");
   Check (Len = 3, "parallel path len");

   ------------------------------------------------------------------
   Section ("9. Invalid_Argument cases");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow");
   Check (not Clear_Raises (Nat (Max_Vertices)), "Clear Max_Vertices ok");

   Clear (G, 3);
   Check (Add_Raises (G, 1, 2, Int (-1)), "negative weight");
   Check (Add_Raises (G, 1, 4, 1), "To out of range");
   Check (Add_Raises (G, 4, 1, 1), "From out of range");
   Clear (G, 0);
   Check (Add_Raises (G, 1, 1, 0), "Add on empty graph");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 1);
   H (1) := 0; H (2) := 0;
   Check (Search_Raises (G, 3, 1, H (1 .. 2), 2, 2, 2),
          "Source out of range");
   Check (Search_Raises (G, 1, 3, H (1 .. 2), 2, 2, 2),
          "Goal out of range");
   Check (Search_Raises (G, 1, 2, H (1 .. 2), 1, 2, 2),
          "Dist Last too small");
   Check (Search_Raises (G, 1, 2, H (1 .. 2), 2, 1, 2),
          "Prev Last too small");
   Check (Search_Raises (G, 1, 2, H (1 .. 2), 2, 2, 1),
          "Path Last too small");

   --  Negative heuristic
   H (1) := 0; H (2) := -1;
   Check (Search_Raises (G, 1, 2, H (1 .. 2), 2, 2, 2),
          "negative heuristic");
   Check (Dist_Raises (G, 1, 2, H (1 .. 2)), "Dist neg H raises");

   --  Heuristic range too short
   declare
      H1 : constant Heuristic_Array (1 .. 1) := [1 => 0];
   begin
      Check (Search_Raises (G, 1, 2, H1, 2, 2, 2), "H range too short");
   end;

   Clear (G, 2);
   H (1) := 0; H (2) := 0;
   Search (G, 1, 1, H (1 .. 2), Dist, Prev, Path, Len, Found);
   Check (Recon_Raises (Prev, 1, 2, 2, Max_Vertices),
          "Recon Path First /= 1");
   Check (Recon_Raises (Prev (1 .. 2), 1, 1, 1, 1),
          "Recon Path Last < Prev Last");

   ------------------------------------------------------------------
   Section ("10. Clear / rebuild / API counters");
   ------------------------------------------------------------------
   Clear (G, 4);
   Check (Vertex_Count (G) = 4, "rebuild N=4");
   Check (Edge_Count (G) = 0, "rebuild E=0");
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Check (Edge_Count (G) = 2, "rebuild E=2");
   Clear (G, 2);
   Check (Vertex_Count (G) = 2 and then Edge_Count (G) = 0,
          "Clear resets edges");
   Add_Edge (G, 1, 2, 9);
   H (1) := 0; H (2) := 0;
   Check (Distance (G, 1, 2, H (1 .. 2)) = 9, "after rebuild Dist");

   ------------------------------------------------------------------
   Section ("11. Chains and shortcuts");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 1, 5, 100);  -- expensive shortcut
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := Integer (5 - Natural (V));  -- admissible on unit chain
   end loop;
   H (5) := 0;
   Search (G, 1, 5, H (1 .. 5), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (5) = 4, "chain Dist=4 not 100");
   Check (Len = 5, "chain full path");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, 20);
   H (1) := 0; H (2) := 0; H (3) := 0; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (4) = 3, "shortcut Dist=3");
   --  1→3→2→4 = 1+1+1 = 3

   ------------------------------------------------------------------
   Section ("12. Stars / wide fan-out");
   ------------------------------------------------------------------
   Clear (G, 21);
   for I in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, I, Integer (I) - 1);
   end loop;
   for V in Vertex_Id range 1 .. 21 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 21, H (1 .. 21), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (21) = 20, "star Dist21");
   Check (Dist (11) = 10, "star Dist11");
   Check (Prev (21) = 1 and then Len = 2, "star direct");

   ------------------------------------------------------------------
   Section ("13. Layered DAG");
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
   Search (G, 1, 7, H (1 .. 7), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (7) = 7, "layered Dist7");
   Check (Len = 4, "layered path len");
   Check (Path (1) = 1 and then Path (2) = 3
            and then Path (3) = 5 and then Path (4) = 7,
          "layered via 3-5");

   --  Guiding H toward 7
   H (1) := 6; H (2) := 4; H (3) := 2; H (4) := 3;
   H (5) := 1; H (6) := 8; H (7) := 0;
   Search (G, 1, 7, H (1 .. 7), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (7) = 7, "layered guided Dist7");

   ------------------------------------------------------------------
   Section ("14. Find_Path / Distance / Reconstruct agree");
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
   Search (G, 1, 6, H (1 .. 6), Dist, Prev, Path, Len, Found);
   for T in Vertex_Id range 1 .. 6 loop
      D := Distance (G, 1, T, H (1 .. 6));
      if T = 1 or else Dist (T) < Infinity then
         Check (D = Dist (T), "agree Dist" & Vertex_Id'Image (T));
      end if;
   end loop;
   D := Find_Path (G, 1, 6, H (1 .. 6), Path, Len);
   Check (D = Dist (6) and then Len >= 2, "Find_Path agrees");
   Ok := Reconstruct_Path (Prev, 1, 6, Path, Len);
   Check (Ok and then Path (1) = 1 and then Path (Len) = 6,
          "Recon agrees");

   ------------------------------------------------------------------
   Section ("15. Early stop: Goal settled before full tree");
   ------------------------------------------------------------------
   --  With good H, A* need not explore the whole graph.
   Clear (G, 8);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);  -- goal path
   Add_Edge (G, 1, 5, 1);
   Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 6, 7, 1);
   Add_Edge (G, 7, 8, 1);  -- long distractor
   --  Goal = 4. Perfect H along goal path; large H on distractor.
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
   Check (Dist (8) = Infinity or else Exp < Exp0,
          "distractor often unexpanded");

   ------------------------------------------------------------------
   Section ("16. Larger random-ish digraph");
   ------------------------------------------------------------------
   Clear (G, 30);
   --  Forward chain with some cross edges and a long spur
   for I in 1 .. 29 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
   end loop;
   Add_Edge (G, 1, 10, 20);
   Add_Edge (G, 5, 15, 5);
   Add_Edge (G, 10, 20, 3);
   Add_Edge (G, 15, 30, 50);
   for V in Vertex_Id range 1 .. 30 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 30, H (1 .. 30), Dist, Prev, Path, Len, Found, Exp0);
   --  Optimal uses shortcuts: 1..10 (9) + 10→20 (3) + 20..30 (10) = 22
   Check (Found and then Dist (30) = 22, "chain30 Dist=22");

   --  Admissible under-estimate (half remaining chain hops)
   for V in Vertex_Id range 1 .. 30 loop
      H (V) := Integer (30 - Natural (V)) / 2;
   end loop;
   Search (G, 1, 30, H (1 .. 30), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (30) = 22, "chain30 guided Dist");
   Check (Exp <= Exp0, "chain30 guided expands ≤");

   ------------------------------------------------------------------
   Section ("17. Source=Goal variants / zero-weight graph");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 3, 4, 0);
   H (1) := 0; H (2) := 0; H (3) := 0; H (4) := 0;
   Search (G, 2, 2, H (1 .. 4), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (2) = 0 and then Len = 1, "mid Source=Goal");
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (4) = 0, "all-zero weights Dist");
   Check (Len = 4, "all-zero path len");

   ------------------------------------------------------------------
   Section ("18. Multiple goals-style / pick nearer");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 10);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   H (1) := 3; H (2) := 2; H (3) := 2; H (4) := 1; H (5) := 0;
   Search (G, 1, 5, H (1 .. 5), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (5) = 3, "nearer branch Dist=3");
   Check (Path (2) = 2, "nearer via 2");

   ------------------------------------------------------------------
   Section ("19. Self-loop does not poison path");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 1, 0);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 2, 1);
   Add_Edge (G, 2, 3, 5);
   H (1) := 0; H (2) := 0; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (3) = 10, "self-loop path Dist");
   Check (Len = 3, "self-loop path len");

   ------------------------------------------------------------------
   Section ("20. Heuristic H(Goal) nonzero still works if admissible");
   ------------------------------------------------------------------
   --  H(Goal) should be 0 for admissibility; if H(Goal)>0 then NOT
   --  admissible. We still run; cost may be wrong only if inadmissible.
   --  Document: package does not force H(Goal)=0.
   Clear (G, 2);
   Add_Edge (G, 1, 2, 4);
   H (1) := 0; H (2) := 0;
   Search (G, 1, 2, H (1 .. 2), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (2) = 4, "H(Goal)=0 Dist");

   ------------------------------------------------------------------
   Section ("21. Dense expansions vs guiding H on grid 4x4");
   ------------------------------------------------------------------
   Clear (G, 16);
   declare
      function Id (R, C : Positive) return Vertex_Id is
        (Vertex_Id ((R - 1) * 4 + C));
      procedure Link (A, B : Vertex_Id) is
      begin
         Add_Edge (G, A, B, 1);
         Add_Edge (G, B, A, 1);
      end Link;
   begin
      for R in 1 .. 4 loop
         for C in 1 .. 3 loop
            Link (Id (R, C), Id (R, C + 1));
         end loop;
      end loop;
      for C in 1 .. 4 loop
         for R in 1 .. 3 loop
            Link (Id (R, C), Id (R + 1, C));
         end loop;
      end loop;
      --  Manhattan to (4,4)=16
      for R in 1 .. 4 loop
         for C in 1 .. 4 loop
            H (Id (R, C)) := (4 - R) + (4 - C);
         end loop;
      end loop;
   end;
   Search (G, 1, 16, H (1 .. 16), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (16) = 6, "4x4 Dist=6");
   Check (Len = 7, "4x4 path len 7");
   declare
      HZ : constant Heuristic_Array (1 .. 16) := [others => 0];
      Exp_Z : Natural;
      D2 : Distance_Array (Vertex_Id);
      P2 : Prev_Array (Vertex_Id);
      Pa : Path_Array (1 .. Max_Vertices);
      L2 : Natural;
      F2 : Boolean;
   begin
      Search (G, 1, 16, HZ, D2, P2, Pa, L2, F2, Exp_Z);
      Check (F2 and then D2 (16) = 6, "4x4 zero-H Dist");
      Check (Exp <= Exp_Z, "4x4 Manhattan ≤ zero-H expansions");
   end;

   ------------------------------------------------------------------
   Section ("22. Bidirectional edges / undirected modelling");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 1, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 2, 2);
   Add_Edge (G, 3, 4, 2);
   Add_Edge (G, 4, 3, 2);
   H (1) := 6; H (2) := 4; H (3) := 2; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (4) = 6, "undirected-model Dist");
   Search (G, 4, 1, H (1 .. 4), Dist, Prev, Path, Len, Found);
   --  H was for goal 4; for goal 1 use zeros
   H (1) := 0; H (2) := 0; H (3) := 0; H (4) := 0;
   Search (G, 4, 1, H (1 .. 4), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (1) = 6, "undirected reverse Dist");

   ------------------------------------------------------------------
   Section ("23. Capacity Max_Vertices boundary");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Max_Vertices clear");
   Add_Edge (G, 1, Vertex_Id (Max_Vertices), 1);
   Check (Edge_Count (G) = 1, "Max_Vertices one edge");
   declare
      HH : constant Heuristic_Array (1 .. Vertex_Id (Max_Vertices)) :=
        [others => 0];
   begin
      Search (G, 1, Vertex_Id (Max_Vertices), HH, Dist, Prev, Path, Len,
              Found);
      Check (Found and then Dist (Vertex_Id (Max_Vertices)) = 1,
             "Max_Vertices path");
      Search (G, Vertex_Id (Max_Vertices), 1, HH, Dist, Prev, Path, Len,
              Found);
      Check (not Found, "Max_Vertices reverse missing");
   end;

   ------------------------------------------------------------------
   Section ("24. Overlapping parallel + chain optimality");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 5);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 5);
   Add_Edge (G, 4, 5, 1);
   H (1) := 4; H (2) := 3; H (3) := 2; H (4) := 1; H (5) := 0;
   Search (G, 1, 5, H (1 .. 5), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (5) = 4, "parallel chain Dist=4");
   Check (Len = 5, "parallel chain len");

   ------------------------------------------------------------------
   Section ("25. Distance Infinity sentinel");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   H (1) := 0; H (2) := 0; H (3) := 0;
   D := Distance (G, 1, 3, H (1 .. 3));
   Check (D = Infinity, "Infinity sentinel");
   declare
      function DV (X : Distance_Value) return Distance_Value is (X);
   begin
      Check (DV (Infinity) = Distance_Value'Last, "Infinity is Last");
   end;

   ------------------------------------------------------------------
   Section ("26. Many small graphs batch");
   ------------------------------------------------------------------
   for N in 2 .. 12 loop
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 2);
      end loop;
      declare
         HH : Heuristic_Array (1 .. Vertex_Id (N));
      begin
         for V in Vertex_Id range 1 .. Vertex_Id (N) loop
            HH (V) := 2 * Integer (N - Natural (V));
         end loop;
         Search (G, 1, Vertex_Id (N), HH, Dist, Prev, Path, Len, Found);
         Check (Found and then Dist (Vertex_Id (N)) =
                  Distance_Value (2 * (N - 1)),
                "batch N=" & Natural'Image (N));
      end;
   end loop;

   ------------------------------------------------------------------
   Section ("27. Reconstruct edge cases");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   H (1) := 0; H (2) := 0; H (3) := 0;
   Search (G, 1, 3, H (1 .. 3), Dist, Prev, Path, Len, Found);
   Ok := Reconstruct_Path (Prev, 1, 1, Path, Len);
   Check (Ok and then Len = 1, "recon Source=Target");
   Ok := Reconstruct_Path (Prev, 1, 3, Path, Len);
   Check (Ok and then Len = 3, "recon full");
   --  Unreachable target with Prev=0
   declare
      P0 : constant Prev_Array (1 .. 3) := [others => 0];
   begin
      Ok := Reconstruct_Path (P0, 1, 3, Path, Len);
      Check (not Ok and then Len = 0, "recon unreachable");
   end;

   ------------------------------------------------------------------
   Section ("28. Expansions reported & Search overload");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   H (1) := 0; H (2) := 0; H (3) := 0; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Exp >= 4, "expansions >= path nodes");
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (4) = 3, "overload without Exp");


   ------------------------------------------------------------------
   Section ("29. Extra diamonds and forks");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, 4);
   Add_Edge (G, 4, 5, 2);
   Add_Edge (G, 3, 5, 10);
   H (1) := 5; H (2) := 3; H (3) := 4; H (4) := 2; H (5) := 0;
   Search (G, 1, 5, H (1 .. 5), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (5) = 6, "fork Dist=6");
   --  1→2→4→5 = 3+1+2 = 6; 1→3→4→5 = 1+4+2 = 7; 1→3→5 = 11
   Check (Path (2) = 2, "fork via 2");

   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 4, 6, 10);
   Add_Edge (G, 5, 6, 1);
   for V in Vertex_Id range 1 .. 6 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 6, H (1 .. 6), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (6) = 4, "fork2 Dist=4");
   Check (Len = 5, "fork2 path len");

   ------------------------------------------------------------------
   Section ("30. Zero-weight mesh");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 1, 3, 0);
   Add_Edge (G, 2, 4, 0);
   Add_Edge (G, 3, 4, 0);
   H (1) := 0; H (2) := 0; H (3) := 0; H (4) := 0;
   Search (G, 1, 4, H (1 .. 4), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (4) = 0, "zero mesh Dist");
   Check (Len = 3, "zero mesh len");

   ------------------------------------------------------------------
   Section ("31. Long unit chain N=40");
   ------------------------------------------------------------------
   Clear (G, 40);
   for I in 1 .. 39 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
   end loop;
   for V in Vertex_Id range 1 .. 40 loop
      H (V) := Integer (40 - Natural (V));
   end loop;
   Search (G, 1, 40, H (1 .. 40), Dist, Prev, Path, Len, Found, Exp);
   Check (Found and then Dist (40) = 39, "chain40 Dist");
   Check (Len = 40, "chain40 len");
   declare
      HZ : constant Heuristic_Array (1 .. 40) := [others => 0];
      E0 : Natural;
      D2 : Distance_Array (Vertex_Id);
      P2 : Prev_Array (Vertex_Id);
      Pa : Path_Array (1 .. Max_Vertices);
      L2 : Natural;
      F2 : Boolean;
   begin
      Search (G, 1, 40, HZ, D2, P2, Pa, L2, F2, E0);
      Check (F2 and then D2 (40) = 39, "chain40 zero-H");
      Check (Exp <= E0, "chain40 H expands ≤");
   end;

   ------------------------------------------------------------------
   Section ("32. Complete small tournament");
   ------------------------------------------------------------------
   Clear (G, 5);
   for I in Vertex_Id range 1 .. 5 loop
      for J in Vertex_Id range 1 .. 5 loop
         if I /= J then
            Add_Edge (G, I, J, Integer (I) + Integer (J));
         end if;
      end loop;
   end loop;
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := 0;
   end loop;
   Search (G, 1, 5, H (1 .. 5), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (5) = 6, "tournament direct 1→5");
   --  direct edge weight 1+5=6
   Check (Len = 2, "tournament direct path");
   Search (G, 5, 1, H (1 .. 5), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (1) = 6, "tournament reverse");

   ------------------------------------------------------------------
   Section ("33. Find_Path unreachable / trivial");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 2);
   H (1) := 0; H (2) := 0; H (3) := 0;
   D := Find_Path (G, 1, 3, H (1 .. 3), Path, Len);
   Check (D = Infinity and then Len = 0, "Find_Path unreachable");
   D := Find_Path (G, 2, 2, H (1 .. 3), Path, Len);
   Check (D = 0 and then Len = 1 and then Path (1) = 2, "Find_Path trivial");
   D := Find_Path (G, 1, 2, H (1 .. 3), Path, Len);
   Check (D = 2 and then Len = 2, "Find_Path direct");

   ------------------------------------------------------------------
   Section ("34. Recon after Search path matches");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 6, 7, 1);
   Add_Edge (G, 1, 7, 100);
   for V in Vertex_Id range 1 .. 7 loop
      H (V) := Integer (7 - Natural (V));
   end loop;
   Search (G, 1, 7, H (1 .. 7), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (7) = 6, "recon-match Dist");
   declare
      Path2 : Path_Array (1 .. Max_Vertices);
      Len2  : Natural;
      Ok2   : Boolean;
   begin
      Ok2 := Reconstruct_Path (Prev, 1, 7, Path2, Len2);
      Check (Ok2 and then Len2 = Len, "recon-match len");
      Check (Path2 (1) = Path (1) and then Path2 (Len2) = Path (Len),
             "recon-match ends");
      for I in 1 .. Len loop
         Check (Path2 (I) = Path (I), "recon-match idx" & Natural'Image (I));
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("35. Weighted grid 2x3");
   ------------------------------------------------------------------
   --  1-2-3
   --  | | |
   --  4-5-6   goal=6; horizontal weight 2, vertical weight 3
   Clear (G, 6);
   declare
      procedure U (A, B : Vertex_Id; W : Integer) is
      begin
         Add_Edge (G, A, B, W);
         Add_Edge (G, B, A, W);
      end U;
   begin
      U (1, 2, 2); U (2, 3, 2);
      U (4, 5, 2); U (5, 6, 2);
      U (1, 4, 3); U (2, 5, 3); U (3, 6, 3);
   end;
   --  Manhattan-like under-estimate using min edge 2
   H (1) := 6; H (2) := 4; H (3) := 2;
   H (4) := 4; H (5) := 2; H (6) := 0;
   Search (G, 1, 6, H (1 .. 6), Dist, Prev, Path, Len, Found);
   Check (Found and then Dist (6) = 7, "wgrid Dist=7");
   --  1→2→3→6 = 2+2+3 = 7; 1→4→5→6 = 3+2+2 = 7

   ------------------------------------------------------------------
   Section ("36. API Vertex/Edge after many adds");
   ------------------------------------------------------------------
   Clear (G, 10);
   Check (Vertex_Count (G) = 10, "api N=10");
   for I in 1 .. 9 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
   end loop;
   Check (Edge_Count (G) = 9, "api E=9");
   H (1 .. 10) := [others => 0];
   Check (Distance (G, 1, 10, H (1 .. 10)) = 45, "api sum 1..9=45");
   Check (Distance (G, 5, 5, H (1 .. 10)) = 0, "api self dist");
   Check (Distance (G, 10, 1, H (1 .. 10)) = Infinity, "api back Inf");

   ------------------------------------------------------------------
   Section ("37. Negative weight siblings");
   ------------------------------------------------------------------
   Clear (G, 3);
   Check (Add_Raises (G, 1, 2, Int (-100)), "neg weight -100");
   Check (Add_Raises (G, 2, 3, Int (-1)), "neg weight -1");
   Add_Edge (G, 1, 2, 0);
   Check (Edge_Count (G) = 1, "zero weight allowed");
   Add_Edge (G, 2, 3, Nat (0));
   --  Nat returns Natural; Add_Edge wants Integer — use Int
   Clear (G, 3);
   Add_Edge (G, 1, 2, Int (0));
   Add_Edge (G, 2, 3, Int (0));
   H (1) := 0; H (2) := -5; H (3) := 0;
   Check (Search_Raises (G, 1, 3, H (1 .. 3), 3, 3, 3),
          "neg H mid");
   H (2) := 0; H (1) := -1;
   Check (Search_Raises (G, 1, 3, H (1 .. 3), 3, 3, 3),
          "neg H source");


   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
