--  Standalone test suite for Iterative_Deepening_DFS (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Iterative_Deepening_DFS; use Iterative_Deepening_DFS;

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

   function Search_Raises
     (G : Graph; Start, Goal : Vertex_Id; First, Last : Positive)
      return Boolean
   is
      Path   : Path_Array (First .. Last);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Search (G, Start, Goal, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Search_Raises;

   function DLS_Raises
     (G : Graph; Start, Goal : Vertex_Id; Limit : Natural;
      First, Last : Positive) return Boolean
   is
      Path   : Path_Array (First .. Last);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Depth_Limited_Search (G, Start, Goal, Limit, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end DLS_Raises;

   function Paths_Equal_length
     (A_Len, B_Len : Natural) return Boolean is
     (A_Len = B_Len);

   procedure Agree_BFS
     (G : Graph; Start, Goal : Vertex_Id; Label : String)
   is
      P1, P2 : Path_Array (1 .. Max_Vertices);
      L1, L2 : Natural;
      Ok1, Ok2 : Boolean;
   begin
      Ok1 := Search (G, Start, Goal, P1, L1);
      Ok2 := BFS_Shortest_Path (G, Start, Goal, P2, L2);
      Check (Ok1 = Ok2, Label & " found-agree");
      if Ok1 and Ok2 then
         Check (L1 = L2, Label & " len-agree");
         Check (P1 (1) = Start and then P2 (1) = Start, Label & " start");
         Check (P1 (L1) = Goal and then P2 (L2) = Goal, Label & " goal");
      else
         Check (L1 = 0 and then L2 = 0, Label & " both-empty");
      end if;
   end Agree_BFS;

   G    : Graph;
   Path : Path_Array (1 .. Max_Vertices);
   Len  : Natural;
   Ok   : Boolean;
   P2   : Path_Array (1 .. Max_Vertices);
   L2   : Natural;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Ok := Search (G, 1, 1, Path, Len);
   Check (not Ok and then Len = 0, "empty search false");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Ok := Search (G, 1, 1, Path, Len);
   Check (Ok and then Len = 1 and then Path (1) = 1, "single Start=Goal");
   Ok := Depth_Limited_Search (G, 1, 1, 0, Path, Len);
   Check (Ok and then Len = 1, "DLS limit 0 Start=Goal");
   Ok := BFS_Shortest_Path (G, 1, 1, Path, Len);
   Check (Ok and then Len = 1, "BFS Start=Goal");

   Add_Edge (G, 1, 1);
   Check (Edge_Count (G) = 1, "self-loop edge count");
   Ok := Search (G, 1, 1, Path, Len);
   Check (Ok and then Len = 1, "self-loop still Start=Goal at depth 0");

   ------------------------------------------------------------------
   Section ("2. Two-vertex digraphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   Ok := Search (G, 1, 2, Path, Len);
   Check (not Ok, "2 isolated: no path 1→2");
   Ok := Search (G, 2, 1, Path, Len);
   Check (not Ok, "2 isolated: no path 2→1");
   Ok := Search (G, 1, 1, Path, Len);
   Check (Ok and then Len = 1, "2 isolated: 1→1");

   Add_Edge (G, 1, 2);
   Ok := Search (G, 1, 2, Path, Len);
   Check (Ok and then Len = 2, "arc 1→2 length 2");
   Check (Path (1) = 1 and then Path (2) = 2, "arc 1→2 vertices");
   Ok := Search (G, 2, 1, Path, Len);
   Check (not Ok, "arc 1→2 no reverse");
   Ok := Depth_Limited_Search (G, 1, 2, 0, Path, Len);
   Check (not Ok, "DLS limit 0 misses 1→2");
   Ok := Depth_Limited_Search (G, 1, 2, 1, Path, Len);
   Check (Ok and then Len = 2, "DLS limit 1 finds 1→2");
   Agree_BFS (G, 1, 2, "arc agree");

   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Ok := Search (G, 1, 2, Path, Len);
   Check (Ok and then Len = 2, "2-cycle 1→2");
   Ok := Search (G, 2, 1, Path, Len);
   Check (Ok and then Len = 2, "2-cycle 2→1");
   Agree_BFS (G, 1, 2, "2-cycle agree");

   ------------------------------------------------------------------
   Section ("3. Directed chains");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Ok := Search (G, 1, 5, Path, Len);
   Check (Ok and then Len = 5, "chain 1..5 length");
   Check (Path (1) = 1 and then Path (5) = 5, "chain ends");
   Check (Path (2) = 2 and then Path (3) = 3 and then Path (4) = 4,
          "chain middle");
   Ok := Search (G, 1, 3, Path, Len);
   Check (Ok and then Len = 3, "chain 1→3");
   Ok := Search (G, 3, 1, Path, Len);
   Check (not Ok, "chain no reverse 3→1");
   Ok := Depth_Limited_Search (G, 1, 5, 3, Path, Len);
   Check (not Ok, "DLS limit 3 misses depth-4 goal");
   Ok := Depth_Limited_Search (G, 1, 5, 4, Path, Len);
   Check (Ok and then Len = 5, "DLS limit 4 finds chain");
   Agree_BFS (G, 1, 5, "chain agree");
   Agree_BFS (G, 2, 4, "chain mid agree");
   Agree_BFS (G, 5, 1, "chain reverse agree");

   ------------------------------------------------------------------
   Section ("4. Shortest vs longer alternate");
   ------------------------------------------------------------------
   --  1→2→3→4 and shortcut 1→4; also long detour 1→5→6→7→4
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 1, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 6, 7);
   Add_Edge (G, 7, 4);
   Ok := Search (G, 1, 4, Path, Len);
   Check (Ok and then Len = 2, "shortcut 1→4 is shortest");
   Check (Path (1) = 1 and then Path (2) = 4, "shortcut vertices");
   Agree_BFS (G, 1, 4, "shortcut agree");
   Ok := Depth_Limited_Search (G, 1, 4, 1, Path, Len);
   Check (Ok and then Len = 2, "DLS at 1 gets shortcut");
   Ok := Depth_Limited_Search (G, 1, 4, 0, Path, Len);
   Check (not Ok, "DLS at 0 misses 1→4");

   ------------------------------------------------------------------
   Section ("5. Branching / diamond");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Ok := Search (G, 1, 4, Path, Len);
   Check (Ok and then Len = 3, "diamond length 3");
   Check (Path (1) = 1 and then Path (3) = 4, "diamond ends");
   Check (Path (2) = 2 or else Path (2) = 3, "diamond via 2 or 3");
   Agree_BFS (G, 1, 4, "diamond agree");
   Agree_BFS (G, 2, 3, "diamond no 2→3");
   Ok := Search (G, 2, 3, Path, Len);
   Check (not Ok, "diamond no lateral 2→3");

   ------------------------------------------------------------------
   Section ("6. Unreachable / disconnected");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Ok := Search (G, 1, 6, Path, Len);
   Check (not Ok, "two components 1↛6");
   Ok := Search (G, 1, 3, Path, Len);
   Check (Ok and then Len = 3, "comp A 1→3");
   Ok := Search (G, 4, 6, Path, Len);
   Check (Ok and then Len = 3, "comp B 4→6");
   Agree_BFS (G, 1, 6, "disc agree absent");
   Agree_BFS (G, 4, 5, "disc agree present");

   ------------------------------------------------------------------
   Section ("7. Cycles do not prevent shallowest");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 2);
   Add_Edge (G, 3, 4);
   Ok := Search (G, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "cycle graph 1→4 len 4");
   Agree_BFS (G, 1, 4, "cycle agree");
   Ok := Search (G, 1, 3, Path, Len);
   Check (Ok and then Len = 3, "cycle graph 1→3");

   ------------------------------------------------------------------
   Section ("8. Complete digraph K_n (tournament-ish)");
   ------------------------------------------------------------------
   Clear (G, 4);
   for U in Vertex_Id range 1 .. 4 loop
      for V in Vertex_Id range 1 .. 4 loop
         if U /= V then
            Add_Edge (G, U, V);
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 12, "K4 digraph edges");
   Ok := Search (G, 1, 4, Path, Len);
   Check (Ok and then Len = 2, "K4 direct edge");
   Agree_BFS (G, 1, 4, "K4 agree");
   Agree_BFS (G, 3, 2, "K4 3→2");
   for U in Vertex_Id range 1 .. 4 loop
      Ok := Search (G, U, U, Path, Len);
      Check (Ok and then Len = 1, "K4 self" & Vertex_Id'Image (U));
   end loop;

   ------------------------------------------------------------------
   Section ("9. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Check (Edge_Count (G) = 3, "parallels counted");
   Ok := Search (G, 1, 3, Path, Len);
   Check (Ok and then Len = 3, "parallels still reach");
   Agree_BFS (G, 1, 3, "parallels agree");

   ------------------------------------------------------------------
   Section ("10. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Clear (G, 2);
   Check (Vertex_Count (G) = 2, "clear resize N");
   Check (Edge_Count (G) = 0, "clear drops edges");
   Ok := Search (G, 1, 2, Path, Len);
   Check (not Ok, "after clear no edge");
   Add_Edge (G, 2, 1);
   Ok := Search (G, 2, 1, Path, Len);
   Check (Ok and then Len = 2, "rebuild edge");

   ------------------------------------------------------------------
   Section ("11. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices) + 1), "Clear N too big");
   Clear (G, 3);
   Check (Add_Raises (G, 1, 4), "Add_Edge To out of range");
   Check (Add_Raises (G, 4, 1), "Add_Edge From out of range");
   Check (Search_Raises (G, 1, 2, 1, 2), "Search Path too short");
   Check (Search_Raises (G, 1, 2, 2, 10), "Search Path'First /= 1");
   Check (Search_Raises (G, 5, 1, 1, 10), "Search Start OOR");
   Check (Search_Raises (G, 1, 5, 1, 10), "Search Goal OOR");
   Check (DLS_Raises (G, 1, 2, 1, 1, 2), "DLS Path too short");
   Check (DLS_Raises (G, 1, 2, Max_Vertices + 1, 1, 10),
          "DLS Limit > Max_Vertices");

   ------------------------------------------------------------------
   Section ("12. Star out / star in");
   ------------------------------------------------------------------
   Clear (G, 6);
   for V in Vertex_Id range 2 .. 6 loop
      Add_Edge (G, 1, V);
   end loop;
   Ok := Search (G, 1, 6, Path, Len);
   Check (Ok and then Len = 2, "out-star 1→6");
   Ok := Search (G, 2, 3, Path, Len);
   Check (not Ok, "out-star leaf↛leaf");
   Agree_BFS (G, 1, 4, "out-star agree");

   Clear (G, 6);
   for V in Vertex_Id range 2 .. 6 loop
      Add_Edge (G, V, 1);
   end loop;
   Ok := Search (G, 3, 1, Path, Len);
   Check (Ok and then Len = 2, "in-star 3→1");
   Ok := Search (G, 1, 3, Path, Len);
   Check (not Ok, "in-star hub↛leaf");
   Agree_BFS (G, 5, 1, "in-star agree");

   ------------------------------------------------------------------
   Section ("13. Binary tree (directed down)");
   ------------------------------------------------------------------
   --  1→2,1→3; 2→4,2→5; 3→6,3→7
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 3, 7);
   Ok := Search (G, 1, 7, Path, Len);
   Check (Ok and then Len = 3, "btree 1→7 depth 2");
   Check (Path (2) = 3, "btree via right");
   Ok := Search (G, 1, 5, Path, Len);
   Check (Ok and then Len = 3 and then Path (2) = 2, "btree 1→5");
   Ok := Depth_Limited_Search (G, 1, 7, 1, Path, Len);
   Check (not Ok, "btree DLS depth 1 misses leaf");
   Ok := Depth_Limited_Search (G, 1, 7, 2, Path, Len);
   Check (Ok, "btree DLS depth 2 finds leaf");
   Agree_BFS (G, 1, 4, "btree agree");
   Agree_BFS (G, 2, 7, "btree cross absent");

   ------------------------------------------------------------------
   Section ("14. Long chain (N=30)");
   ------------------------------------------------------------------
   Clear (G, 30);
   for I in 1 .. 29 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   Ok := Search (G, 1, 30, Path, Len);
   Check (Ok and then Len = 30, "long chain length");
   Check (Path (15) = 15, "long chain mid");
   Agree_BFS (G, 1, 30, "long chain agree");
   Agree_BFS (G, 10, 20, "long chain mid agree");
   Ok := Search (G, 30, 1, Path, Len);
   Check (not Ok, "long chain reverse absent");
   Ok := Depth_Limited_Search (G, 1, 30, 28, Path, Len);
   Check (not Ok, "long chain DLS under");
   Ok := Depth_Limited_Search (G, 1, 30, 29, Path, Len);
   Check (Ok and then Len = 30, "long chain DLS exact");

   ------------------------------------------------------------------
   Section ("15. Grid-like DAG 3x3");
   ------------------------------------------------------------------
   --  vertices 1..9 row-major; edges right and down
   Clear (G, 9);
   for R in 0 .. 2 loop
      for C in 0 .. 2 loop
         declare
            V : constant Vertex_Id := Vertex_Id (R * 3 + C + 1);
         begin
            if C < 2 then
               Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
            end if;
            if R < 2 then
               Add_Edge (G, V, Vertex_Id (Natural (V) + 3));
            end if;
         end;
      end loop;
   end loop;
   Ok := Search (G, 1, 9, Path, Len);
   Check (Ok and then Len = 5, "3x3 grid shortest 4 arcs");
   Agree_BFS (G, 1, 9, "grid agree");
   Agree_BFS (G, 1, 5, "grid to center");
   Agree_BFS (G, 9, 1, "grid reverse absent");
   Ok := Search (G, 3, 7, Path, Len);
   Check (not Ok, "grid 3↛7 (no left/up)");

   ------------------------------------------------------------------
   Section ("16. Many pairwise BFS agreements");
   ------------------------------------------------------------------
   Clear (G, 8);
   --  sparse random-ish digraph
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 3, 5);
   Add_Edge (G, 4, 6);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 5, 7);
   Add_Edge (G, 6, 8);
   Add_Edge (G, 7, 8);
   Add_Edge (G, 2, 5);
   for S in Vertex_Id range 1 .. 8 loop
      for T in Vertex_Id range 1 .. 8 loop
         Agree_BFS (G, S, T,
                    "pair" & Vertex_Id'Image (S) & "->"
                    & Vertex_Id'Image (T));
      end loop;
   end loop;

   ------------------------------------------------------------------
   Section ("17. DLS progressive discovery");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   for L in 0 .. 4 loop
      Ok := Depth_Limited_Search (G, 1, 5, L, Path, Len);
      if L < 4 then
         Check (not Ok, "progressive miss L=" & Natural'Image (L));
      else
         Check (Ok and then Len = 5, "progressive hit L=4");
      end if;
   end loop;
   --  Intermediate goals appear earlier
   Ok := Depth_Limited_Search (G, 1, 3, 1, Path, Len);
   Check (not Ok, "goal3 miss L=1");
   Ok := Depth_Limited_Search (G, 1, 3, 2, Path, Len);
   Check (Ok and then Len = 3, "goal3 hit L=2");

   ------------------------------------------------------------------
   Section ("18. Sink / source only");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Ok := Search (G, 1, 4, Path, Len);
   Check (Ok and then Len = 2, "to sink");
   Ok := Search (G, 4, 1, Path, Len);
   Check (not Ok, "from sink");
   Agree_BFS (G, 2, 4, "sink agree");

   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   Ok := Search (G, 1, 3, Path, Len);
   Check (Ok and then Len = 2, "from source");
   Ok := Search (G, 2, 3, Path, Len);
   Check (not Ok, "between sinks");

   ------------------------------------------------------------------
   Section ("19. Larger N=50 line vs shortcut");
   ------------------------------------------------------------------
   Clear (G, 50);
   for I in 1 .. 49 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   Add_Edge (G, 1, 50);
   Ok := Search (G, 1, 50, Path, Len);
   Check (Ok and then Len = 2, "N=50 shortcut wins");
   Agree_BFS (G, 1, 50, "N=50 shortcut agree");
   Ok := Search (G, 25, 50, Path, Len);
   Check (Ok and then Len = 26, "N=50 mid→end");
   Agree_BFS (G, 25, 40, "N=50 mid agree");

   ------------------------------------------------------------------
   Section ("20. API counters");
   ------------------------------------------------------------------
   Clear (G, 10);
   Check (Vertex_Count (G) = 10, "API N=10");
   Check (Edge_Count (G) = 0, "API E=0");
   for I in 1 .. 9 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   Check (Edge_Count (G) = 9, "API E=9");
   Clear (G, 0);
   Check (Vertex_Count (G) = 0 and then Edge_Count (G) = 0, "API empty");

   ------------------------------------------------------------------
   Section ("21. Path validity vs BFS length on random-ish");
   ------------------------------------------------------------------
   Clear (G, 12);
   Add_Edge (G, 1, 2); Add_Edge (G, 1, 5); Add_Edge (G, 2, 3);
   Add_Edge (G, 2, 6); Add_Edge (G, 3, 4); Add_Edge (G, 5, 6);
   Add_Edge (G, 5, 9); Add_Edge (G, 6, 7); Add_Edge (G, 6, 10);
   Add_Edge (G, 7, 8); Add_Edge (G, 9, 10); Add_Edge (G, 10, 11);
   Add_Edge (G, 11, 12); Add_Edge (G, 4, 8); Add_Edge (G, 8, 12);
   for S in Vertex_Id range 1 .. 12 loop
      for T in Vertex_Id range 1 .. 12 loop
         Ok := Search (G, S, T, Path, Len);
         declare
            OkB : constant Boolean :=
              BFS_Shortest_Path (G, S, T, P2, L2);
         begin
            Check (Ok = OkB and then Paths_Equal_length (Len, L2),
                   "rand" & Vertex_Id'Image (S) & "->"
                   & Vertex_Id'Image (T));
         end;
      end loop;
   end loop;

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
