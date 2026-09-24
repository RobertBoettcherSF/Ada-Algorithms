--  Standalone test suite for Best_First_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Best_First_Search; use Best_First_Search;

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
     (G : in out Graph; From, To : Vertex_Id) return Boolean
   is
   begin
      Add_Edge (G, From, To);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Search_Raises_Path
     (G : Graph; Start, Goal : Vertex_Id;
      H : Heuristic_Array; First, Last : Positive) return Boolean
   is
      Path   : Path_Array (First .. Last);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Search (G, Start, Goal, H, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises_Path;

   function Search_Raises_H
     (G : Graph; Start, Goal : Vertex_Id;
      H_First, H_Last : Positive) return Boolean
   is
      H      : constant Heuristic_Array
        (Vertex_Id (H_First) .. Vertex_Id (H_Last)) := [others => 0];
      Path   : Path_Array (1 .. Max_Vertices);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Search (G, Start, Goal, H, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises_H;

   function Path_Ok
     (G : Graph; Path : Path_Array; Length : Natural;
      Start, Goal : Vertex_Id) return Boolean
   is
   begin
      if Length = 0 then
         return False;
      end if;
      if Path (1) /= Start or else Path (Length) /= Goal then
         return False;
      end if;
      for I in 1 .. Length - 1 loop
         if Natural (Path (I)) > Vertex_Count (G)
           or else Natural (Path (I + 1)) > Vertex_Count (G)
         then
            return False;
         end if;
      end loop;
      return True;
   end Path_Ok;

   --  Verify consecutive path vertices are joined by a directed edge by
   --  consulting a caller-supplied adjacency matrix (small graphs).
   type Adj is array (Vertex_Id range <>, Vertex_Id range <>) of Boolean;

   function Path_Edges_Ok
     (A : Adj; Path : Path_Array; Length : Natural) return Boolean
   is
   begin
      if Length = 0 then
         return False;
      end if;
      for I in 1 .. Length - 1 loop
         if not A (Path (I), Path (I + 1)) then
            return False;
         end if;
      end loop;
      return True;
   end Path_Edges_Ok;

   procedure Fill_Zero (H : in out Heuristic_Array) is
   begin
      for V in H'Range loop
         H (V) := 0;
      end loop;
   end Fill_Zero;

   G      : Graph;
   Path   : Path_Array (1 .. Max_Vertices);
   Order  : Order_Array (1 .. Max_Vertices);
   Length : Natural;
   Count  : Natural;
   Exp    : Natural;
   Exp2   : Natural;
   Ok     : Boolean;
   H      : Heuristic_Array (1 .. Vertex_Id (Max_Vertices));

begin
   ------------------------------------------------------------------
   Section ("1. Single vertex / Start = Goal");
   ------------------------------------------------------------------
   Clear (G, 1);
   Fill_Zero (H);
   H (1) := 0;
   Ok := Search (G, 1, 1, H (1 .. 1), Path, Length, Exp);
   Check (Ok, "single: found");
   Check (Length = 1, "single: length 1");
   Check (Path (1) = 1, "single: path is start");
   Check (Exp = 0, "single: no expansions");
   Check (Vertex_Count (G) = 1, "single: N=1");
   Check (Edge_Count (G) = 0, "single: E=0");

   ------------------------------------------------------------------
   Section ("2. Self-loop does not break Start=Goal");
   ------------------------------------------------------------------
   Clear (G, 1);
   Add_Edge (G, 1, 1);
   Ok := Search (G, 1, 1, H (1 .. 1), Path, Length);
   Check (Ok and then Length = 1 and then Path (1) = 1, "self-loop Start=Goal");
   Check (Edge_Count (G) = 1, "self-loop edge count");

   ------------------------------------------------------------------
   Section ("3. Two-vertex arc");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   H (1) := 1;
   H (2) := 0;
   Ok := Search (G, 1, 2, H (1 .. 2), Path, Length, Exp);
   Check (Ok, "2-arc: found");
   Check (Length = 2, "2-arc: length 2");
   Check (Path (1) = 1 and then Path (2) = 2, "2-arc: path 1-2");
   Check (Exp >= 1, "2-arc: expanded start");

   Ok := Search (G, 2, 1, H (1 .. 2), Path, Length);
   Check (not Ok and then Length = 0, "2-arc: reverse unreachable");

   ------------------------------------------------------------------
   Section ("4. Undirected 2-cycle");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   H (1) := 1;
   H (2) := 0;
   Ok := Search (G, 1, 2, H (1 .. 2), Path, Length);
   Check (Ok and then Length = 2, "undirected: 1->2");
   H (1) := 0;
   H (2) := 1;
   Ok := Search (G, 2, 1, H (1 .. 2), Path, Length);
   Check (Ok and then Length = 2 and then Path (1) = 2, "undirected: 2->1");

   ------------------------------------------------------------------
   Section ("5. Directed chain guided by decreasing H");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := Natural (5 - V);
   end loop;
   Ok := Search (G, 1, 5, H (1 .. 5), Path, Length, Exp);
   Check (Ok, "chain: found");
   Check (Length = 5, "chain: length 5");
   Check (Path (1) = 1 and then Path (5) = 5, "chain: ends");
   Check (Path (2) = 2 and then Path (3) = 3 and then Path (4) = 4,
          "chain: middle");

   ------------------------------------------------------------------
   Section ("6. Heuristic guides preferred branch");
   ------------------------------------------------------------------
   --  1 -> 2 -> 4
   --  1 -> 3 -> 4
   --  Prefer 3 via low H.
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   H (1) := 3;
   H (2) := 100;
   H (3) := 1;
   H (4) := 0;
   Ok := Search_With_Order
     (G, 1, 4, H (1 .. 4), Path, Length, Order, Count, Exp);
   Check (Ok, "guide: found");
   Check (Length = 3, "guide: length 3");
   Check (Path (1) = 1 and then Path (2) = 3 and then Path (3) = 4,
          "guide: path via 3");
   Check (Order (1) = 1, "guide: expand start first");

   ------------------------------------------------------------------
   Section ("7. Zero heuristic: FIFO among ties");
   ------------------------------------------------------------------
   Clear (G, 4);
   --  Add 1->2 then 1->3 so prepend makes 3 the head (scanned first).
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Fill_Zero (H);
   Ok := Search_With_Order
     (G, 1, 4, H (1 .. 4), Path, Length, Order, Count, Exp);
   Check (Ok, "zero-H: found");
   Check (Length = 3, "zero-H: length 3");
   --  Neighbours of 1 scanned with 3 first (prepend), then 2; both pushed
   --  with equal H=0; FIFO expands 3 before 2; Goal found from 3.
   Check (Path (2) = 3, "zero-H: prefers first-enqueued neighbour 3");

   ------------------------------------------------------------------
   Section ("8. Non-optimality: greedy takes longer low-h detour");
   ------------------------------------------------------------------
   --  Short path: 1 -> 3 -> 4 (2 arcs)
   --  Long path:  1 -> 2 -> 5 -> 6 -> 4 (4 arcs)
   --  H(2)=0, H(3)=50 so greedy prefers the long branch.
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 4);
   H (1) := 10;
   H (2) := 0;
   H (3) := 50;
   H (4) := 0;
   H (5) := 1;
   H (6) := 1;
   Ok := Search (G, 1, 4, H (1 .. 6), Path, Length);
   Check (Ok, "nonopt: found");
   Check (Length = 5, "nonopt: took long path length 5");
   Check (Path (2) = 2, "nonopt: went via 2");

   --  Flip heuristic: prefer short branch.
   H (2) := 50;
   H (3) := 0;
   Ok := Search (G, 1, 4, H (1 .. 6), Path, Length);
   Check (Ok and then Length = 3 and then Path (2) = 3,
          "nonopt: flipped H takes short path");

   ------------------------------------------------------------------
   Section ("9. Unreachable goal");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Fill_Zero (H);
   Ok := Search (G, 1, 4, H (1 .. 4), Path, Length, Exp);
   Check (not Ok, "unreach: fail");
   Check (Length = 0, "unreach: length 0");
   Check (Exp >= 1, "unreach: expanded something");

   Ok := Search (G, 1, 3, H (1 .. 4), Path, Length);
   Check (not Ok, "unreach: 1 to 3");

   ------------------------------------------------------------------
   Section ("10. Disconnected / isolated");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Fill_Zero (H);
   Ok := Search (G, 5, 1, H (1 .. 5), Path, Length);
   Check (not Ok, "isolated start cannot reach 1");
   Ok := Search (G, 1, 5, H (1 .. 5), Path, Length);
   Check (not Ok, "cannot reach isolated 5");
   Ok := Search (G, 5, 5, H (1 .. 5), Path, Length);
   Check (Ok and then Length = 1, "isolated Start=Goal ok");

   ------------------------------------------------------------------
   Section ("11. Cycle does not loop forever");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   H (1) := 2;
   H (2) := 1;
   H (3) := 0;
   Ok := Search (G, 1, 3, H (1 .. 3), Path, Length, Exp);
   Check (Ok and then Length = 3, "cycle: found 1-2-3");
   Check (Exp <= 3, "cycle: bounded expansions");

   ------------------------------------------------------------------
   Section ("12. Diamond");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   H (1) := 2;
   H (2) := 1;
   H (3) := 1;
   H (4) := 0;
   Ok := Search (G, 1, 4, H (1 .. 4), Path, Length);
   Check (Ok and then Length = 3, "diamond: length 3");
   Check (Path (1) = 1 and then Path (3) = 4, "diamond: ends");

   ------------------------------------------------------------------
   Section ("13. Star: hub to leaves");
   ------------------------------------------------------------------
   Clear (G, 6);
   for L in Vertex_Id range 2 .. 6 loop
      Add_Edge (G, 1, L);
   end loop;
   Fill_Zero (H);
   H (1) := 1;
   for L in Vertex_Id range 2 .. 6 loop
      H (L) := 0;
      Ok := Search (G, 1, L, H (1 .. 6), Path, Length);
      Check (Ok and then Length = 2 and then Path (2) = L,
             "star: hub to leaf");
   end loop;

   ------------------------------------------------------------------
   Section ("14. Binary tree toward rightmost leaf");
   ------------------------------------------------------------------
   --  1
   --  ├── 2
   --  │   ├── 4
   --  │   └── 5
   --  └── 3
   --      ├── 6
   --      └── 7 (goal)
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 3, 7);
   --  Guide toward 3 then 7.
   H (1) := 3;
   H (2) := 10;
   H (3) := 1;
   H (4) := 9;
   H (5) := 9;
   H (6) := 5;
   H (7) := 0;
   Ok := Search (G, 1, 7, H (1 .. 7), Path, Length, Exp);
   Check (Ok and then Length = 3, "tree: path len 3");
   Check (Path (1) = 1 and then Path (2) = 3 and then Path (3) = 7,
          "tree: via 3");

   Fill_Zero (H);
   Ok := Search (G, 1, 7, H (1 .. 7), Path, Length, Exp2);
   Check (Ok, "tree: zero-H still finds");
   Check (Exp <= Exp2, "tree: guiding H expands <= zero-H");

   ------------------------------------------------------------------
   Section ("15. Grid DAG 3x3 (row-major ids)");
   ------------------------------------------------------------------
   --  1 2 3
   --  4 5 6
   --  7 8 9   right and down edges; goal = 9
   Clear (G, 9);
   Add_Edge (G, 1, 2); Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5); Add_Edge (G, 5, 6);
   Add_Edge (G, 7, 8); Add_Edge (G, 8, 9);
   Add_Edge (G, 1, 4); Add_Edge (G, 4, 7);
   Add_Edge (G, 2, 5); Add_Edge (G, 5, 8);
   Add_Edge (G, 3, 6); Add_Edge (G, 6, 9);
   --  Manhattan-like heuristic to 9 (row,col from 0).
   declare
      function Manh (V : Vertex_Id) return Natural is
         R : constant Natural := (Natural (V) - 1) / 3;
         C : constant Natural := (Natural (V) - 1) mod 3;
      begin
         return (2 - R) + (2 - C);
      end Manh;
   begin
      for V in Vertex_Id range 1 .. 9 loop
         H (V) := Manh (V);
      end loop;
   end;
   Ok := Search (G, 1, 9, H (1 .. 9), Path, Length, Exp);
   Check (Ok, "grid: found");
   Check (Length = 5, "grid: shortest len 5 (4 arcs)");
   Check (Path (1) = 1 and then Path (Length) = 9, "grid: ends");

   Fill_Zero (H);
   Ok := Search (G, 1, 9, H (1 .. 9), Path, Length, Exp2);
   Check (Ok and then Length = 5, "grid: zero-H also optimal here");
   Check (Exp <= Exp2, "grid: Manh expands <= zero-H");

   ------------------------------------------------------------------
   Section ("16. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   H (1) := 2;
   H (2) := 1;
   H (3) := 0;
   Ok := Search (G, 1, 3, H (1 .. 3), Path, Length);
   Check (Ok and then Length = 3, "parallel: found");
   Check (Edge_Count (G) = 3, "parallel: 3 edges stored");

   ------------------------------------------------------------------
   Section ("17. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 1, "rebuild: one edge");
   Clear (G, 4);
   Check (Vertex_Count (G) = 4 and then Edge_Count (G) = 0,
          "rebuild: cleared");
   Add_Edge (G, 1, 4);
   Fill_Zero (H);
   H (1) := 1;
   H (4) := 0;
   Ok := Search (G, 1, 4, H (1 .. 4), Path, Length);
   Check (Ok and then Length = 2, "rebuild: new graph search");

   ------------------------------------------------------------------
   Section ("18. Long chain N=40");
   ------------------------------------------------------------------
   Clear (G, 40);
   for V in Vertex_Id range 1 .. 39 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
      H (V) := Natural (40 - V);
   end loop;
   H (40) := 0;
   Ok := Search (G, 1, 40, H (1 .. 40), Path, Length, Exp);
   Check (Ok and then Length = 40, "long: length 40");
   Check (Path (1) = 1 and then Path (40) = 40, "long: ends");
   Check (Exp = 39, "long: expanded 39 before discovering goal as neighbour");

   ------------------------------------------------------------------
   Section ("19. Wide star expansions with guiding H");
   ------------------------------------------------------------------
   Clear (G, 21);
   for L in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, L);
      H (L) := 100;
   end loop;
   H (1) := 50;
   H (21) := 0;  --  only leaf 21 looks good
   Ok := Search_With_Order
     (G, 1, 21, H (1 .. 21), Path, Length, Order, Count, Exp);
   Check (Ok and then Length = 2, "wide: found");
   Check (Path (2) = 21, "wide: goal leaf");
   --  After expanding 1, all leaves enqueued; min-H is 21; discovered as
   --  neighbour of 1 directly... actually Goal is neighbour of 1, so early
   --  exit when scanning neighbours. With prepend, leaves added 2..21 so
   --  head is 21 first — Goal discovered immediately without pushing others?
   --  Visited mark: we scan neighbours; first unscanned is 21 (prepended
   --  last). Yes early exit. Expansions = 1 (only Start popped).
   Check (Exp = 1, "wide: only start expanded (goal is neighbour)");

   ------------------------------------------------------------------
   Section ("20. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "clear: N too large");
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "clear: N=0 allowed");
   Check (Search_Raises_Path
            (G, 1, 1, H (1 .. 1), 1, 1), "search: N=0 raises");

   Clear (G, 3);
   Check (Add_Raises (G, 1, 4), "add: To out of range");
   Check (Add_Raises (G, 4, 1), "add: From out of range");

   Fill_Zero (H);
   Check (Search_Raises_Path
            (G, 1, 2, H (1 .. 3), 1, 2), "search: Path too short");
   Check (Search_Raises_H (G, 1, 2, 2, 3), "search: H starts at 2");
   Check (Search_Raises_H (G, 1, 2, 1, 2), "search: H too short");

   declare
      function Start_OOR return Boolean is
         P : Path_Array (1 .. 3);
         L : Natural;
         B : Boolean;
      begin
         B := Search (G, 4, 1, H (1 .. 3), P, L);
         pragma Unreferenced (B, L);
         return False;
      exception
         when Invalid_Argument =>
            return True;
      end Start_OOR;
   begin
      Check (Start_OOR, "search: Start out of range");
   end;

   ------------------------------------------------------------------
   Section ("21. Empty graph Clear(0)");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0 and then Edge_Count (G) = 0, "empty graph");

   ------------------------------------------------------------------
   Section ("22. Complete digraph K4");
   ------------------------------------------------------------------
   Clear (G, 4);
   for U in Vertex_Id range 1 .. 4 loop
      for V in Vertex_Id range 1 .. 4 loop
         if U /= V then
            Add_Edge (G, U, V);
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 12, "K4: 12 arcs");
   H (1) := 3;
   H (2) := 2;
   H (3) := 1;
   H (4) := 0;
   Ok := Search (G, 1, 4, H (1 .. 4), Path, Length);
   Check (Ok and then Length = 2, "K4: direct edge preferred if scanned");
   --  Goal is neighbour of Start → early exit length 2.
   Check (Path (1) = 1 and then Path (2) = 4, "K4: 1-4");

   ------------------------------------------------------------------
   Section ("23. Goal with high H still found");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   H (1) := 0;
   H (2) := 0;
   H (3) := 99;  --  Goal need not have H=0
   Ok := Search (G, 1, 3, H (1 .. 3), Path, Length);
   Check (Ok and then Length = 3, "high-H goal still reachable");

   ------------------------------------------------------------------
   Section ("24. Many components sweep");
   ------------------------------------------------------------------
   Clear (G, 9);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 7, 8);
   Add_Edge (G, 8, 9);
   Fill_Zero (H);
   declare
      Found : Natural := 0;
   begin
      for S in Vertex_Id range 1 .. 9 loop
         for T in Vertex_Id range 1 .. 9 loop
            Ok := Search (G, S, T, H (1 .. 9), Path, Length);
            if S = T then
               Check (Ok and then Length = 1, "comp: self");
            elsif Ok then
               Found := Found + 1;
               Check (Path (1) = S and then Path (Length) = T, "comp: ends");
            end if;
         end loop;
      end loop;
      --  Reachable pairs (S≠T): (1,2)(1,3)(2,3)(4,5)(7,8)(7,9)(8,9) = 7
      Check (Found = 7, "comp: 7 reachable pairs");
   end;

   ------------------------------------------------------------------
   Section ("25. Expansion order monotonic in H among pushed");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 5);
   H (1) := 10;
   H (2) := 5;
   H (3) := 3;
   H (4) := 1;
   H (5) := 0;
   Ok := Search_With_Order
     (G, 1, 5, H (1 .. 5), Path, Length, Order, Count, Exp);
   Check (Ok, "order: found");
   Check (Order (1) = 1, "order: start first");
   --  After start, neighbours pushed in scan order (prepend: 4,3,2).
   --  Heap pops min H: 4 (h=1), discovers 5 as neighbour → done.
   Check (Order (2) = 4, "order: expand lowest-h neighbour 4 next");
   Check (Path (2) = 4 and then Path (3) = 5, "order: path via 4");

   ------------------------------------------------------------------
   Section ("26. Path_Ok structural checks on chain");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   declare
      A : Adj (1 .. 4, 1 .. 4) := [others => [others => False]];
   begin
      A (1, 2) := True;
      A (2, 3) := True;
      A (3, 4) := True;
      for V in Vertex_Id range 1 .. 4 loop
         H (V) := Natural (4 - V);
      end loop;
      Ok := Search (G, 1, 4, H (1 .. 4), Path, Length);
      Check (Ok, "struct: found");
      Check (Path_Edges_Ok (A, Path, Length), "struct: edges exist");
      Check (Path_Ok (G, Path, Length, 1, 4), "struct: Path_Ok");
   end;

   ------------------------------------------------------------------
   Section ("27. Back-edge cycle with distractors");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 2);  --  back
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   H (1) := 4;
   H (2) := 3;
   H (3) := 2;
   H (4) := 1;
   H (5) := 0;
   Ok := Search (G, 1, 5, H (1 .. 5), Path, Length, Exp);
   Check (Ok and then Length = 5, "back: found");
   Check (Exp <= 5, "back: no runaway");

   ------------------------------------------------------------------
   Section ("28. Same Start different Goals");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 4, 5);
   Fill_Zero (H);
   Ok := Search (G, 1, 3, H (1 .. 5), Path, Length);
   Check (Ok and then Length = 3, "multi-goal: to 3");
   Ok := Search (G, 1, 5, H (1 .. 5), Path, Length);
   Check (Ok and then Length = 4, "multi-goal: to 5");
   Ok := Search (G, 1, 1, H (1 .. 5), Path, Length);
   Check (Ok and then Length = 1, "multi-goal: to self");

   ------------------------------------------------------------------
   Section ("29. Heuristic plateau (all equal nonzero)");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   for V in Vertex_Id range 1 .. 4 loop
      H (V) := 7;
   end loop;
   Ok := Search (G, 1, 4, H (1 .. 4), Path, Length);
   Check (Ok and then Length = 4, "plateau: still finds chain");

   ------------------------------------------------------------------
   Section ("30. Max vertices smoke (N=100 small subgraph)");
   ------------------------------------------------------------------
   Clear (G, 100);
   for V in Vertex_Id range 1 .. 99 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
      H (V) := Natural (100 - V);
   end loop;
   H (100) := 0;
   Ok := Search (G, 1, 100, H (1 .. 100), Path, Length);
   Check (Ok and then Length = 100, "N100: full chain");
   Check (Vertex_Count (G) = 100, "N100: count");

   ------------------------------------------------------------------
   Section ("31. Search without Expansions overload");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 3);
   H (1) := 1;
   H (2) := 9;
   H (3) := 0;
   Ok := Search (G, 1, 3, H (1 .. 3), Path, Length);
   Check (Ok and then Length = 2, "overload: basic Search");

   ------------------------------------------------------------------
   Section ("32. Undirected grid path existence");
   ------------------------------------------------------------------
   Clear (G, 9);
   --  undirected 3x3 grid
   declare
      procedure U (A, B : Vertex_Id) is
      begin
         Add_Edge (G, A, B);
         Add_Edge (G, B, A);
      end U;
   begin
      U (1, 2); U (2, 3);
      U (4, 5); U (5, 6);
      U (7, 8); U (8, 9);
      U (1, 4); U (4, 7);
      U (2, 5); U (5, 8);
      U (3, 6); U (6, 9);
   end;
   declare
      function Manh (V : Vertex_Id) return Natural is
         R : constant Natural := (Natural (V) - 1) / 3;
         C : constant Natural := (Natural (V) - 1) mod 3;
      begin
         return abs (Integer (R) - 2) + abs (Integer (C) - 2);
      end Manh;
   begin
      for V in Vertex_Id range 1 .. 9 loop
         H (V) := Manh (V);
      end loop;
   end;
   Ok := Search (G, 1, 9, H (1 .. 9), Path, Length);
   Check (Ok, "ugrid: found");
   Check (Length >= 5 and then Length <= 9, "ugrid: reasonable length");
   Check (Path (1) = 1 and then Path (Length) = 9, "ugrid: ends");

   ------------------------------------------------------------------
   Section ("33. Dead-end branches pruned by visited");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);  --  goal 6 via 4
   H (1) := 5;
   H (2) := 0;   --  attractive dead end
   H (3) := 0;
   H (4) := 2;
   H (5) := 1;
   H (6) := 0;
   Ok := Search (G, 1, 6, H (1 .. 6), Path, Length, Exp);
   Check (Ok, "deadend: found despite attractive trap");
   Check (Path (Length) = 6, "deadend: goal");
   Check (Length = 4, "deadend: path via 4-5-6");

   ------------------------------------------------------------------
   Section ("34. Prefer closer leaf among siblings");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 5);
   H (1) := 4;
   H (2) := 3;
   H (3) := 2;
   H (4) := 1;
   H (5) := 0;
   Ok := Search (G, 1, 5, H (1 .. 5), Path, Length, Exp);
   Check (Ok and then Path (2) = 4, "siblings: via closest 4");
   Check (Length = 3, "siblings: length 3");

   ------------------------------------------------------------------
   Section ("35. Reverse unreachable on directed chain");
   ------------------------------------------------------------------
   Clear (G, 5);
   for V in Vertex_Id range 1 .. 4 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
   end loop;
   Fill_Zero (H);
   Ok := Search (G, 5, 1, H (1 .. 5), Path, Length);
   Check (not Ok, "rev: 5 cannot reach 1");
   Ok := Search (G, 3, 1, H (1 .. 5), Path, Length);
   Check (not Ok, "rev: 3 cannot reach 1");
   Ok := Search (G, 3, 5, H (1 .. 5), Path, Length);
   Check (Ok and then Length = 3, "fwd: 3 to 5");

   ------------------------------------------------------------------
   Section ("36. Large H values / Natural range");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   H (1) := Natural'Last / 2;
   H (2) := Natural'Last / 4;
   H (3) := 0;
   Ok := Search (G, 1, 3, H (1 .. 3), Path, Length);
   Check (Ok and then Length = 3, "large-H: still finds");

   ------------------------------------------------------------------
   Section ("37. Order Count matches Expansions when no early Goal neighbour");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   H (1) := 3;
   H (2) := 2;
   H (3) := 1;
   H (4) := 0;
   Ok := Search_With_Order
     (G, 1, 4, H (1 .. 4), Path, Length, Order, Count, Exp);
   Check (Ok, "ord-eq: found");
   --  Goal discovered as neighbour of 3: Order includes Goal, Expansions
   --  counts pops only (1,2,3) => Count = Exp + 1
   Check (Exp = 3, "ord-eq: 3 expansions");
   Check (Count = 4, "ord-eq: order includes goal");
   Check (Order (Count) = 4, "ord-eq: last is goal");

   ------------------------------------------------------------------
   Section ("38. Nat helper / smoke counts");
   ------------------------------------------------------------------
   Check (Nat (0) = 0, "nat 0");
   Check (Nat (1) = 1, "nat 1");
   Check (Nat (Max_Vertices) = 1000, "Max_Vertices");
   Check (Nat (Max_Edges) = 100_000, "Max_Edges");

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
