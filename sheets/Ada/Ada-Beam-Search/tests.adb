--  Standalone test suite for Beam_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Beam_Search; use Beam_Search;

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
      H : Heuristic_Array; Beam : Natural;
      First, Last : Positive) return Boolean
   is
      Path   : Path_Array (First .. Last);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Search (G, Start, Goal, H, Beam, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises_Path;

   function Search_Raises_H
     (G : Graph; Start, Goal : Vertex_Id;
      Beam : Natural; H_First, H_Last : Positive) return Boolean
   is
      H      : constant Heuristic_Array
        (Vertex_Id (H_First) .. Vertex_Id (H_Last)) := [others => 0];
      Path   : Path_Array (1 .. Max_Vertices);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Search (G, Start, Goal, H, Beam, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises_H;

   function Search_Raises_Beam
     (G : Graph; Start, Goal : Vertex_Id;
      H : Heuristic_Array; Beam : Natural) return Boolean
   is
      Path   : Path_Array (1 .. Max_Vertices);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Search (G, Start, Goal, H, Beam, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises_Beam;

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
   Ok2    : Boolean;
   H      : Heuristic_Array (1 .. Vertex_Id (Max_Vertices));

begin
   ------------------------------------------------------------------
   Section ("1. Single vertex / Start = Goal");
   ------------------------------------------------------------------
   Clear (G, 1);
   Fill_Zero (H);
   H (1) := 0;
   Ok := Search (G, 1, 1, H (1 .. 1), 1, Path, Length, Exp);
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
   Ok := Search (G, 1, 1, H (1 .. 1), 1, Path, Length);
   Check (Ok and then Length = 1 and then Path (1) = 1, "self-loop Start=Goal");
   Check (Edge_Count (G) = 1, "self-loop edge count");

   ------------------------------------------------------------------
   Section ("3. Two-vertex arc");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   H (1) := 1;
   H (2) := 0;
   Ok := Search (G, 1, 2, H (1 .. 2), 1, Path, Length, Exp);
   Check (Ok, "2-arc: found");
   Check (Length = 2, "2-arc: length 2");
   Check (Path (1) = 1 and then Path (2) = 2, "2-arc: path 1-2");
   Check (Exp >= 1, "2-arc: expanded start");

   Ok := Search (G, 2, 1, H (1 .. 2), 8, Path, Length);
   Check (not Ok and then Length = 0, "2-arc: reverse unreachable");

   ------------------------------------------------------------------
   Section ("4. Undirected 2-cycle");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   H (1) := 1;
   H (2) := 0;
   Ok := Search (G, 1, 2, H (1 .. 2), 2, Path, Length);
   Check (Ok and then Length = 2, "undirected: 1->2");
   H (1) := 0;
   H (2) := 1;
   Ok := Search (G, 2, 1, H (1 .. 2), 2, Path, Length);
   Check (Ok and then Length = 2 and then Path (1) = 2, "undirected: 2->1");

   ------------------------------------------------------------------
   Section ("5. Directed chain with β=1");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := Natural (5 - V);
   end loop;
   Ok := Search (G, 1, 5, H (1 .. 5), 1, Path, Length, Exp);
   Check (Ok, "chain: found");
   Check (Length = 5, "chain: length 5");
   Check (Path (1) = 1 and then Path (5) = 5, "chain: ends");
   Check (Path (2) = 2 and then Path (3) = 3 and then Path (4) = 4,
          "chain: middle");

   ------------------------------------------------------------------
   Section ("6. Narrow beam prunes; wide beam finds");
   ------------------------------------------------------------------
   --  Path to 5 only via 2: 1->2->5. Attractive distractors 3,4.
   --  H(3)=0, H(4)=1, H(2)=50 so β=2 keeps {3,4} and prunes 2.
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 5);
   H (1) := 10;
   H (2) := 50;
   H (3) := 0;
   H (4) := 1;
   H (5) := 0;
   Ok := Search (G, 1, 5, H (1 .. 5), 2, Path, Length, Exp);
   Check (not Ok, "prune: β=2 fails");
   Check (Length = 0, "prune: length 0");

   Ok := Search (G, 1, 5, H (1 .. 5), 3, Path, Length, Exp2);
   Check (Ok, "prune: β=3 finds");
   Check (Length = 3, "prune: length 3");
   Check (Path (1) = 1 and then Path (2) = 2 and then Path (3) = 5,
          "prune: path via 2");

   ------------------------------------------------------------------
   Section ("7. Goal pruned among high-H siblings");
   ------------------------------------------------------------------
   --  1 -> 2,3,4(=Goal). H(2)=0, H(3)=1, H(4)=100. β=2 keeps 2,3 — Goal
   --  generated but pruned (Wikipedia incompleteness).
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   H (1) := 5;
   H (2) := 0;
   H (3) := 1;
   H (4) := 100;
   Ok := Search (G, 1, 4, H (1 .. 4), 2, Path, Length);
   Check (not Ok, "goal-prune: β=2 drops Goal");
   Ok := Search (G, 1, 4, H (1 .. 4), 3, Path, Length);
   Check (Ok and then Length = 2 and then Path (2) = 4,
          "goal-prune: β=3 keeps Goal");

   ------------------------------------------------------------------
   Section ("8. H=0 + large β ≈ BFS reachability");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 5);
   Add_Edge (G, 4, 6);
   Fill_Zero (H);
   Ok := Search (G, 1, 6, H (1 .. 6), 10, Path, Length);
   Check (Ok, "bfs-like: found");
   Check (Length = 4, "bfs-like: length 4 (fewest arcs)");
   Check (Path (1) = 1 and then Path (Length) = 6, "bfs-like: ends");

   Ok := Search (G, 1, 5, H (1 .. 6), 10, Path, Length);
   Check (Ok and then Length = 3, "bfs-like: to 5");
   Ok := Search (G, 3, 6, H (1 .. 6), 10, Path, Length);
   Check (not Ok, "bfs-like: 3 cannot reach 6");

   ------------------------------------------------------------------
   Section ("9. β=1 hill-climbing along decreasing H");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   H (1) := 3;
   H (2) := 100;
   H (3) := 1;
   H (4) := 0;
   Ok := Search (G, 1, 4, H (1 .. 4), 1, Path, Length, Exp);
   Check (Ok, "hill: found");
   Check (Length = 3, "hill: length 3");
   Check (Path (2) = 3, "hill: via low-H child 3");

   ------------------------------------------------------------------
   Section ("10. Unreachable goal");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Fill_Zero (H);
   Ok := Search (G, 1, 4, H (1 .. 4), 8, Path, Length, Exp);
   Check (not Ok, "unreach: fail");
   Check (Length = 0, "unreach: length 0");
   Check (Exp >= 1, "unreach: expanded something");

   Ok := Search (G, 1, 3, H (1 .. 4), 8, Path, Length);
   Check (not Ok, "unreach: 1 to 3");

   ------------------------------------------------------------------
   Section ("11. Disconnected / isolated");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Fill_Zero (H);
   Ok := Search (G, 5, 1, H (1 .. 5), 5, Path, Length);
   Check (not Ok, "isolated start cannot reach 1");
   Ok := Search (G, 1, 5, H (1 .. 5), 5, Path, Length);
   Check (not Ok, "cannot reach isolated 5");
   Ok := Search (G, 5, 5, H (1 .. 5), 1, Path, Length);
   Check (Ok and then Length = 1, "isolated Start=Goal ok");

   ------------------------------------------------------------------
   Section ("12. Cycle does not loop forever");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   H (1) := 2;
   H (2) := 1;
   H (3) := 0;
   Ok := Search (G, 1, 3, H (1 .. 3), 2, Path, Length, Exp);
   Check (Ok and then Length = 3, "cycle: found 1-2-3");
   Check (Exp <= 3, "cycle: bounded expansions");

   ------------------------------------------------------------------
   Section ("13. Diamond with varying β");
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
   Ok := Search (G, 1, 4, H (1 .. 4), 1, Path, Length);
   Check (Ok and then Length = 3, "diamond β=1: found");
   Ok := Search (G, 1, 4, H (1 .. 4), 2, Path, Length);
   Check (Ok and then Length = 3, "diamond β=2: found");
   Check (Path (1) = 1 and then Path (3) = 4, "diamond: ends");

   ------------------------------------------------------------------
   Section ("14. Star: hub to leaves");
   ------------------------------------------------------------------
   Clear (G, 6);
   for L in Vertex_Id range 2 .. 6 loop
      Add_Edge (G, 1, L);
   end loop;
   Fill_Zero (H);
   H (1) := 1;
   for L in Vertex_Id range 2 .. 6 loop
      H (L) := 0;
      Ok := Search (G, 1, L, H (1 .. 6), 5, Path, Length);
      Check (Ok and then Length = 2 and then Path (2) = L,
             "star: hub to leaf wide");
   end loop;
   --  Narrow β=1 with equal H: FIFO among ties keeps one child; may miss.
   H (2) := 0;
   H (3) := 0;
   H (4) := 0;
   H (5) := 0;
   H (6) := 0;
   Ok := Search (G, 1, 2, H (1 .. 6), 1, Path, Length);
   --  Prepend order: last added (6) scanned first → first candidate seq;
   --  all H=0 so sort keeps earliest Seq = 6. Goal 2 pruned.
   Check (not Ok, "star: β=1 may miss non-first leaf under H=0");
   Ok := Search (G, 1, 6, H (1 .. 6), 1, Path, Length);
   Check (Ok and then Path (2) = 6, "star: β=1 finds first-ranked leaf");

   ------------------------------------------------------------------
   Section ("15. Binary tree toward rightmost leaf");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 3, 7);
   H (1) := 3;
   H (2) := 10;
   H (3) := 1;
   H (4) := 9;
   H (5) := 9;
   H (6) := 5;
   H (7) := 0;
   Ok := Search (G, 1, 7, H (1 .. 7), 1, Path, Length, Exp);
   Check (Ok and then Length = 3, "tree: path len 3 with β=1");
   Check (Path (1) = 1 and then Path (2) = 3 and then Path (3) = 7,
          "tree: via 3");

   Fill_Zero (H);
   Ok := Search (G, 1, 7, H (1 .. 7), 4, Path, Length, Exp2);
   Check (Ok, "tree: zero-H wide still finds");

   ------------------------------------------------------------------
   Section ("16. Grid DAG 3x3 (row-major ids)");
   ------------------------------------------------------------------
   Clear (G, 9);
   Add_Edge (G, 1, 2); Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5); Add_Edge (G, 5, 6);
   Add_Edge (G, 7, 8); Add_Edge (G, 8, 9);
   Add_Edge (G, 1, 4); Add_Edge (G, 4, 7);
   Add_Edge (G, 2, 5); Add_Edge (G, 5, 8);
   Add_Edge (G, 3, 6); Add_Edge (G, 6, 9);
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
   Ok := Search (G, 1, 9, H (1 .. 9), 4, Path, Length, Exp);
   Check (Ok, "grid: found wide");
   Check (Length = 5, "grid: shortest len 5 (4 arcs)");
   Check (Path (1) = 1 and then Path (Length) = 9, "grid: ends");

   Ok2 := Search (G, 1, 9, H (1 .. 9), 1, Path, Length, Exp2);
   Check (Ok2, "grid: β=1 with Manh still finds");
   Check (Length = 5, "grid: β=1 length 5");

   ------------------------------------------------------------------
   Section ("17. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   H (1) := 2;
   H (2) := 1;
   H (3) := 0;
   Ok := Search (G, 1, 3, H (1 .. 3), 2, Path, Length);
   Check (Ok and then Length = 3, "parallel: found");
   Check (Edge_Count (G) = 3, "parallel: 3 edges stored");

   ------------------------------------------------------------------
   Section ("18. Clear / rebuild");
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
   Ok := Search (G, 1, 4, H (1 .. 4), 1, Path, Length);
   Check (Ok and then Length = 2, "rebuild: new graph search");

   ------------------------------------------------------------------
   Section ("19. Long chain N=40");
   ------------------------------------------------------------------
   Clear (G, 40);
   for V in Vertex_Id range 1 .. 39 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
      H (V) := Natural (40 - V);
   end loop;
   H (40) := 0;
   Ok := Search (G, 1, 40, H (1 .. 40), 1, Path, Length, Exp);
   Check (Ok and then Length = 40, "long: length 40");
   Check (Path (1) = 1 and then Path (40) = 40, "long: ends");
   Check (Exp = 39, "long: expanded 39 before Goal in beam");

   ------------------------------------------------------------------
   Section ("20. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "clear: N too large");
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "clear: N=0 allowed");
   Check (Search_Raises_Path
            (G, 1, 1, H (1 .. 1), 1, 1, 1), "search: N=0 raises");

   Clear (G, 3);
   Check (Add_Raises (G, 1, 4), "add: To out of range");
   Check (Add_Raises (G, 4, 1), "add: From out of range");

   Fill_Zero (H);
   Check (Search_Raises_Path
            (G, 1, 2, H (1 .. 3), 2, 1, 2), "search: Path too short");
   Check (Search_Raises_H (G, 1, 2, 2, 2, 3), "search: H starts at 2");
   Check (Search_Raises_H (G, 1, 2, 2, 1, 2), "search: H too short");
   Check (Search_Raises_Beam (G, 1, 2, H (1 .. 3), 0),
          "search: Beam_Width=0");

   declare
      function Start_OOR return Boolean is
         P : Path_Array (1 .. 3);
         L : Natural;
         B : Boolean;
      begin
         B := Search (G, 4, 1, H (1 .. 3), 2, P, L);
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
   Ok := Search (G, 1, 4, H (1 .. 4), 3, Path, Length);
   Check (Ok and then Length = 2, "K4: Goal in first beam after expand");
   Check (Path (1) = 1 and then Path (2) = 4, "K4: 1-4");

   ------------------------------------------------------------------
   Section ("23. Goal with high H still found if β large");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   H (1) := 0;
   H (2) := 0;
   H (3) := 99;
   Ok := Search (G, 1, 3, H (1 .. 3), 2, Path, Length);
   Check (Ok and then Length = 3, "high-H goal still reachable wide");

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
            Ok := Search (G, S, T, H (1 .. 9), 9, Path, Length);
            if S = T then
               Check (Ok and then Length = 1, "comp: self");
            elsif Ok then
               Found := Found + 1;
               Check (Path (1) = S and then Path (Length) = T, "comp: ends");
            end if;
         end loop;
      end loop;
      Check (Found = 7, "comp: 7 reachable pairs");
   end;

   ------------------------------------------------------------------
   Section ("25. Search_With_Order expansion tracking");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   for V in Vertex_Id range 1 .. 5 loop
      H (V) := Natural (5 - V);
   end loop;
   Ok := Search_With_Order
     (G, 1, 5, H (1 .. 5), 1, Path, Length, Order, Count, Exp);
   Check (Ok, "order: found");
   Check (Order (1) = 1, "order: expand start first");
   Check (Exp = Count, "order: expansions match order count");
   Check (Exp = 4, "order: 4 expansions before Goal in beam");
   Check (Path (Length) = 5, "order: goal");

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
      Ok := Search (G, 1, 4, H (1 .. 4), 1, Path, Length);
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
   Add_Edge (G, 3, 2);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   H (1) := 4;
   H (2) := 3;
   H (3) := 2;
   H (4) := 1;
   H (5) := 0;
   Ok := Search (G, 1, 5, H (1 .. 5), 2, Path, Length, Exp);
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
   Ok := Search (G, 1, 3, H (1 .. 5), 5, Path, Length);
   Check (Ok and then Length = 3, "multi-goal: to 3");
   Ok := Search (G, 1, 5, H (1 .. 5), 5, Path, Length);
   Check (Ok and then Length = 4, "multi-goal: to 5");
   Ok := Search (G, 1, 1, H (1 .. 5), 1, Path, Length);
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
   Ok := Search (G, 1, 4, H (1 .. 4), 1, Path, Length);
   Check (Ok and then Length = 4, "plateau: still finds chain");

   ------------------------------------------------------------------
   Section ("30. Max vertices smoke (N=100 chain)");
   ------------------------------------------------------------------
   Clear (G, 100);
   for V in Vertex_Id range 1 .. 99 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
      H (V) := Natural (100 - V);
   end loop;
   H (100) := 0;
   Ok := Search (G, 1, 100, H (1 .. 100), 1, Path, Length);
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
   Ok := Search (G, 1, 3, H (1 .. 3), 1, Path, Length);
   Check (Ok and then Length = 2, "overload: basic Search");

   ------------------------------------------------------------------
   Section ("32. Undirected grid path existence");
   ------------------------------------------------------------------
   Clear (G, 9);
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
   Ok := Search (G, 1, 9, H (1 .. 9), 8, Path, Length);
   Check (Ok, "ugrid: found");
   Check (Length >= 5 and then Length <= 9, "ugrid: reasonable length");
   Check (Path (1) = 1 and then Path (Length) = 9, "ugrid: ends");

   ------------------------------------------------------------------
   Section ("33. Dead-end: narrow beam follows attractive trap");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   H (1) := 5;
   H (2) := 0;
   H (3) := 0;
   H (4) := 2;
   H (5) := 1;
   H (6) := 0;
   Ok := Search (G, 1, 6, H (1 .. 6), 1, Path, Length, Exp);
   Check (not Ok, "deadend: β=1 follows trap, misses goal path");
   Ok := Search (G, 1, 6, H (1 .. 6), 2, Path, Length, Exp2);
   Check (Ok, "deadend: β=2 keeps both branches");
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
   Ok := Search (G, 1, 5, H (1 .. 5), 1, Path, Length, Exp);
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
   Ok := Search (G, 5, 1, H (1 .. 5), 5, Path, Length);
   Check (not Ok, "rev: 5 cannot reach 1");
   Ok := Search (G, 3, 1, H (1 .. 5), 5, Path, Length);
   Check (not Ok, "rev: 3 cannot reach 1");
   Ok := Search (G, 3, 5, H (1 .. 5), 5, Path, Length);
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
   Ok := Search (G, 1, 3, H (1 .. 3), 1, Path, Length);
   Check (Ok and then Length = 3, "large-H: still finds");

   ------------------------------------------------------------------
   Section ("37. Wide vs narrow expansion counts");
   ------------------------------------------------------------------
   Clear (G, 8);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 4, 7);
   Add_Edge (G, 5, 8);
   Fill_Zero (H);
   H (8) := 0;
   Ok := Search (G, 1, 8, H (1 .. 8), 1, Path, Length, Exp);
   --  H=0 + prepend: children of 1 scanned 4,3,2 → Seq order; β=1 keeps
   --  earliest Seq among equal H = first discovered = 4 (last prepended
   --  is scanned first... wait: scan order: head=4 first, then 3, then 2.
   --  Candidates get Seq in scan order: 4 first (smallest Seq), then 3, 2.
   --  Sort equal H by Seq asc → keep 4. Path via 4→7 dead-ends. Fail.
   Check (not Ok, "exp-cmp: β=1 H=0 misses path via 2");
   Ok := Search (G, 1, 8, H (1 .. 8), 3, Path, Length, Exp2);
   Check (Ok and then Length = 4, "exp-cmp: β=3 finds");
   Check (Exp2 >= Exp, "exp-cmp: wider expands at least as many");

   ------------------------------------------------------------------
   Section ("38. Branching factor vs β (BFS mimic)");
   ------------------------------------------------------------------
   --  Full binary tree depth 3; H=0; β >= max frontier ⇒ all reachable.
   Clear (G, 15);
   Add_Edge (G, 1, 2); Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4); Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6); Add_Edge (G, 3, 7);
   Add_Edge (G, 4, 8); Add_Edge (G, 4, 9);
   Add_Edge (G, 5, 10); Add_Edge (G, 5, 11);
   Add_Edge (G, 6, 12); Add_Edge (G, 6, 13);
   Add_Edge (G, 7, 14); Add_Edge (G, 7, 15);
   Fill_Zero (H);
   Ok := Search (G, 1, 15, H (1 .. 15), 8, Path, Length);
   Check (Ok and then Length = 4, "bfactor: wide finds leaf 15");
   --  H=0 + prepend: adding left-then-right makes right spine scanned
   --  first each level, so β=1 hill-climbs 1→3→7→15 and succeeds.
   Ok := Search (G, 1, 15, H (1 .. 15), 1, Path, Length);
   Check (Ok and then Path (2) = 3 and then Path (3) = 7
            and then Path (4) = 15,
          "bfactor: β=1 H=0 follows right spine to 15");
   --  Goal on the left spine is missed by the same β=1 right bias.
   Ok := Search (G, 1, 8, H (1 .. 15), 1, Path, Length);
   Check (not Ok, "bfactor: β=1 H=0 misses left leaf 8");
   Ok := Search (G, 1, 8, H (1 .. 15), 8, Path, Length);
   Check (Ok and then Length = 4, "bfactor: wide finds left leaf 8");

   ------------------------------------------------------------------
   Section ("39. β greater than N is fine");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Fill_Zero (H);
   Ok := Search (G, 1, 4, H (1 .. 4), 1000, Path, Length);
   Check (Ok and then Length = 4, "huge-β: still finds");

   ------------------------------------------------------------------
   Section ("40. Self-loop distractor ignored by visited");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   H (1) := 2;
   H (2) := 1;
   H (3) := 0;
   Ok := Search (G, 1, 3, H (1 .. 3), 2, Path, Length, Exp);
   Check (Ok and then Length = 3, "loop-distractor: found");

   ------------------------------------------------------------------
   Section ("41. Multiple paths; beam may pick either");
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
   Ok := Search (G, 1, 4, H (1 .. 4), 2, Path, Length);
   Check (Ok and then Length = 3, "multipath: found");
   Check (Path (1) = 1 and then Path (3) = 4, "multipath: ends");
   Check (Path (2) = 2 or else Path (2) = 3, "multipath: via 2 or 3");

   ------------------------------------------------------------------
   Section ("42. Guiding H vs flat H on bushy graph");
   ------------------------------------------------------------------
   Clear (G, 10);
   for L in Vertex_Id range 2 .. 9 loop
      Add_Edge (G, 1, L);
   end loop;
   Add_Edge (G, 9, 10);
   for V in Vertex_Id range 1 .. 10 loop
      H (V) := 100;
   end loop;
   H (1) := 50;
   H (9) := 1;
   H (10) := 0;
   Ok := Search (G, 1, 10, H (1 .. 10), 1, Path, Length, Exp);
   Check (Ok and then Path (2) = 9, "guide: β=1 follows H to 9");
   Check (Length = 3, "guide: length 3");

   Fill_Zero (H);
   --  Prepend: last Add_Edge(1,9) is scanned first → β=1 keeps 9 under H=0.
   Ok2 := Search (G, 1, 10, H (1 .. 10), 1, Path, Length, Exp2);
   Check (Ok2 and then Path (2) = 9, "guide: H=0 β=1 keeps prepended 9");
   --  Goal via an early-added leaf (2) is missed when β=1 keeps only 9.
   Clear (G, 10);
   for L in Vertex_Id range 2 .. 9 loop
      Add_Edge (G, 1, L);
   end loop;
   Add_Edge (G, 2, 10);  --  path via first-added leaf 2
   Fill_Zero (H);
   Ok2 := Search (G, 1, 10, H (1 .. 10), 1, Path, Length);
   Check (not Ok2, "guide: H=0 β=1 misses path via early leaf 2");
   Ok2 := Search (G, 1, 10, H (1 .. 10), 8, Path, Length);
   Check (Ok2 and then Length = 3, "guide: H=0 β=8 finds via 2");

   ------------------------------------------------------------------
   Section ("43. Depth-limited feel: long vs short branch");
   ------------------------------------------------------------------
   Clear (G, 7);
   --  Short: 1->7 direct. Long: 1->2->3->4->5->6->7
   Add_Edge (G, 1, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 7);
   H (1) := 10;
   H (2) := 0;
   H (3) := 0;
   H (4) := 0;
   H (5) := 0;
   H (6) := 0;
   H (7) := 50;  --  Goal looks bad at depth 1
   Ok := Search (G, 1, 7, H (1 .. 7), 1, Path, Length);
   Check (not Ok, "depth: β=1 prefers long low-H, Goal pruned at d1");
   Ok := Search (G, 1, 7, H (1 .. 7), 2, Path, Length);
   Check (Ok and then Length = 2, "depth: β=2 keeps Goal sibling");

   ------------------------------------------------------------------
   Section ("44. Nat helper / smoke counts");
   ------------------------------------------------------------------
   Check (Nat (0) = 0, "nat 0");
   Check (Nat (1) = 1, "nat 1");
   Check (Nat (Max_Vertices) = 1000, "Max_Vertices");
   Check (Nat (Max_Edges) = 100_000, "Max_Edges");

   ------------------------------------------------------------------
   Section ("45. Zero-H wide on chain equals length");
   ------------------------------------------------------------------
   Clear (G, 12);
   for V in Vertex_Id range 1 .. 11 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
   end loop;
   Fill_Zero (H);
   Ok := Search (G, 1, 12, H (1 .. 12), 1, Path, Length);
   Check (Ok and then Length = 12, "zchain: β=1 enough on chain");
   Ok := Search (G, 1, 12, H (1 .. 12), 12, Path, Length);
   Check (Ok and then Length = 12, "zchain: wide also");

   ------------------------------------------------------------------
   Section ("46. Fan-in Goal from many parents");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 5);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Fill_Zero (H);
   Ok := Search (G, 1, 6, H (1 .. 6), 3, Path, Length);
   Check (Ok and then Length = 4, "fan-in: found");
   Check (Path (1) = 1 and then Path (4) = 6, "fan-in: ends");

   ------------------------------------------------------------------
   Section ("47. β progressive recovery");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 1, 5);
   Add_Edge (G, 5, 6);
   H (1) := 10;
   H (2) := 0;
   H (3) := 1;
   H (4) := 2;
   H (5) := 3;
   H (6) := 0;
   Ok := Search (G, 1, 6, H (1 .. 6), 1, Path, Length);
   Check (not Ok, "prog: β=1 fail");
   Ok := Search (G, 1, 6, H (1 .. 6), 2, Path, Length);
   Check (not Ok, "prog: β=2 fail");
   Ok := Search (G, 1, 6, H (1 .. 6), 3, Path, Length);
   Check (not Ok, "prog: β=3 fail");
   Ok := Search (G, 1, 6, H (1 .. 6), 4, Path, Length);
   Check (Ok and then Path (2) = 5, "prog: β=4 finds via 5");

   ------------------------------------------------------------------
   Section ("48. Order Count on simple expand");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   H (1) := 2;
   H (2) := 1;
   H (3) := 0;
   Ok := Search_With_Order
     (G, 1, 3, H (1 .. 3), 1, Path, Length, Order, Count, Exp);
   Check (Ok, "ord2: found");
   Check (Count = 2, "ord2: expanded 1 and 2");
   Check (Order (1) = 1 and then Order (2) = 2, "ord2: order 1,2");
   Check (Exp = 2, "ord2: expansions 2");

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
