--  Standalone test suite for Boruvkas_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Boruvkas_Algorithm; use Boruvkas_Algorithm;

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
     (G : in out Graph; U, V : Vertex_Id; W : Integer) return Boolean
   is
   begin
      Add_Edge (G, U, V, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function MST_Raises
     (G : Graph; Buf_Last : Natural) return Boolean
   is
      Tree : Edge_List (1 .. Positive'Max (1, Buf_Last));
      C    : Natural;
      W    : Weight_Sum;
   begin
      if Buf_Last = 0 then
         declare
            Empty_Buf : Edge_List (1 .. 0);
         begin
            Minimum_Spanning_Tree (G, Empty_Buf, C, W);
         end;
      else
         Minimum_Spanning_Tree (G, Tree (1 .. Buf_Last), C, W);
      end if;
      pragma Unreferenced (C, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end MST_Raises;

   function MST_Raises_Bad_First (G : Graph) return Boolean is
      Tree : Edge_List (2 .. Max_Edges + 1);
      C    : Natural;
      W    : Weight_Sum;
   begin
      Minimum_Spanning_Tree (G, Tree, C, W);
      pragma Unreferenced (C, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end MST_Raises_Bad_First;

   G, G2          : Graph;
   Tree, Tree_K   : Edge_List (1 .. Max_Edges);
   C, CK          : Natural;
   W, WK          : Weight_Sum;
   Has            : Boolean;

   function Edge_In_Tree
     (Tree : Edge_List; Count : Natural;
      A, B : Vertex_Id; Wt : Weight_Type) return Boolean
   is
   begin
      for I in 1 .. Count loop
         if Tree (I).Weight = Wt
           and then
             ((Tree (I).U = A and then Tree (I).V = B)
              or else (Tree (I).U = B and then Tree (I).V = A))
         then
            return True;
         end if;
      end loop;
      return False;
   end Edge_In_Tree;

   procedure Agree_With_Kruskal (Label : String) is
   begin
      Minimum_Spanning_Tree (G, Tree, C, W);
      Kruskal_Reference (G, Tree_K, CK, WK);
      Check (C = CK, Label & " count agree");
      Check (W = WK, Label & " weight agree");
   end Agree_With_Kruskal;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / edgeless");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 0 and then W = 0, "empty MST empty");
   Boruvka (G, Tree, C, W);
   Check (C = 0 and then W = 0, "empty Boruvka empty");
   Kruskal_Reference (G, Tree_K, CK, WK);
   Check (CK = 0 and then WK = 0, "empty Kruskal empty");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 0 and then W = 0, "single MST empty");
   Agree_With_Kruskal ("single");

   Clear (G, 5);
   Check (Vertex_Count (G) = 5, "edgeless N=5");
   Check (Edge_Count (G) = 0, "edgeless M=0");
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 0 and then W = 0, "edgeless MSF empty");
   Agree_With_Kruskal ("edgeless");

   ------------------------------------------------------------------
   Section ("2. Unique MST textbook example");
   ------------------------------------------------------------------
   --  Edges: 12:1, 13:4, 23:2, 24:5, 34:3 → MST weight 6, 3 edges
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 3);
   Check (Edge_Count (G) = 5, "textbook M=5");
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 3, "textbook Tree_Count=3");
   Check (W = 6, "textbook Total=6");
   Check (Edge_In_Tree (Tree, C, 1, 2, 1), "textbook keeps 1-2");
   Check (Edge_In_Tree (Tree, C, 2, 3, 2), "textbook keeps 2-3");
   Check (Edge_In_Tree (Tree, C, 3, 4, 3), "textbook keeps 3-4");
   Check (not Edge_In_Tree (Tree, C, 1, 3, 4), "textbook drops 1-3");
   Check (not Edge_In_Tree (Tree, C, 2, 4, 5), "textbook drops 2-4");
   Agree_With_Kruskal ("textbook");
   Boruvka (G, Tree, C, W);
   Check (C = 3 and then W = 6, "alias Boruvka same");

   ------------------------------------------------------------------
   Section ("3. Two vertices");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 7);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 1, "two-vert count");
   Check (W = 7, "two-vert weight");
   Check (Edge_In_Tree (Tree, C, 1, 2, 7), "two-vert edge");
   Agree_With_Kruskal ("two-vert");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 0);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 1 and then W = 0, "zero-weight edge kept");
   Agree_With_Kruskal ("zero-wt");

   ------------------------------------------------------------------
   Section ("4. Self-loops ignored");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 1, 9);
   Add_Edge (G, 2, 2, 8);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 4);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 2, "self-loop forest count");
   Check (W = 7, "self-loop forest weight");
   Check (not Edge_In_Tree (Tree, C, 1, 1, 9), "self-loop 1 dropped");
   Check (not Edge_In_Tree (Tree, C, 2, 2, 8), "self-loop 2 dropped");
   Agree_With_Kruskal ("self-loops");

   Clear (G, 1);
   Add_Edge (G, 1, 1, 5);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 0 and then W = 0, "only self-loop → empty tree");
   Agree_With_Kruskal ("only-loop");

   ------------------------------------------------------------------
   Section ("5. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 2, 7);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 1, "parallel count");
   Check (W = 3, "parallel keeps lightest");
   Agree_With_Kruskal ("parallel");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 4);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 9);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 2, "parallel triangle count");
   Check (W = 3, "parallel triangle weight 1+2");
   Agree_With_Kruskal ("parallel-tri");

   ------------------------------------------------------------------
   Section ("6. Forests / disconnected");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 3, 4, 2);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 2, "two components count");
   Check (W = 3, "two components weight");
   Agree_With_Kruskal ("two-comp");

   Clear (G, 6);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 4);
   Add_Edge (G, 1, 3, 10);  -- cycle in component A
   Add_Edge (G, 4, 5, 1);
   --  vertex 6 isolated
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 3, "forest count (drop 10)");
   Check (W = 8, "forest weight 3+4+1");
   Check (not Edge_In_Tree (Tree, C, 1, 3, 10), "forest drops heavy");
   Agree_With_Kruskal ("forest");

   Clear (G, 3);
   --  three isolated
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 0 and then W = 0, "three isolated");
   Agree_With_Kruskal ("isolated3");

   ------------------------------------------------------------------
   Section ("7. Path graphs");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 4, 3);
   Add_Edge (G, 4, 5, 4);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 4, "path P5 count");
   Check (W = 10, "path P5 weight");
   Agree_With_Kruskal ("path5");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 4, 2);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 3 and then W = 6, "equal-weight path");
   Agree_With_Kruskal ("eq-path");

   ------------------------------------------------------------------
   Section ("8. Cycles");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 1, 3);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 2, "C3 count");
   Check (W = 3, "C3 weight drops 3");
   Check (not Edge_In_Tree (Tree, C, 3, 1, 3), "C3 drops heaviest");
   Agree_With_Kruskal ("C3");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 1, 1);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 3, "C4 equal count");
   Check (W = 3, "C4 equal weight");
   Agree_With_Kruskal ("C4");

   Clear (G, 5);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 3);
   Add_Edge (G, 3, 4, 4);
   Add_Edge (G, 4, 5, 5);
   Add_Edge (G, 5, 1, 10);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 4 and then W = 14, "C5 drops 10");
   Agree_With_Kruskal ("C5");

   ------------------------------------------------------------------
   Section ("9. Equal-weight triangle (tie-break)");
   ------------------------------------------------------------------
   --  Wikipedia cycle hazard: all weight 1; deterministic ties ⇒ forest
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 1, 1);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 2, "eq-tri count 2 (no cycle)");
   Check (W = 2, "eq-tri weight 2");
   Agree_With_Kruskal ("eq-tri");

   ------------------------------------------------------------------
   Section ("10. Stars");
   ------------------------------------------------------------------
   Clear (G, 6);
   for V in Vertex_Id range 2 .. 6 loop
      Add_Edge (G, 1, V, Integer (V));
   end loop;
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 5, "star count");
   Check (W = 2 + 3 + 4 + 5 + 6, "star weight");
   Agree_With_Kruskal ("star");

   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 1, 5, 1);
   Add_Edge (G, 2, 3, 100);  -- chord — should be rejected
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 4 and then W = 4, "star+chord");
   Check (not Edge_In_Tree (Tree, C, 2, 3, 100), "star drops chord");
   Agree_With_Kruskal ("star-chord");

   ------------------------------------------------------------------
   Section ("11. Complete K3 / K4");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 3, 6);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 2 and then W = 9, "K3 unique");
   Agree_With_Kruskal ("K3");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 1, 4, 3);
   Add_Edge (G, 2, 3, 4);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 6);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 3 and then W = 6, "K4 unique 1+2+3");
   Agree_With_Kruskal ("K4");

   ------------------------------------------------------------------
   Section ("12. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Check (Edge_Count (G) = 2, "before clear M");
   Clear (G, 2);
   Check (Vertex_Count (G) = 2, "after clear N=2");
   Check (Edge_Count (G) = 0, "after clear M=0");
   Add_Edge (G, 1, 2, 9);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 1 and then W = 9, "rebuild MST");
   Agree_With_Kruskal ("rebuild");

   ------------------------------------------------------------------
   Section ("13. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear N too large");
   Check (not Clear_Raises (Nat (Max_Vertices)), "Clear N=Max ok");
   Check (not Clear_Raises (Nat (0)), "Clear N=0 ok");

   Clear (G, 3);
   Check (Add_Raises (G, 1, 2, Int (-1)), "neg weight");
   Check (Add_Raises (G, 1, 2, Int (-100)), "neg weight 2");
   Check (Add_Raises (G, 4, 1, 1), "U out of range");
   Check (Add_Raises (G, 1, 4, 1), "V out of range");
   Check (Add_Raises (G, Vertex_Id (Max_Vertices), 1, 1),
          "U far out of range");

   Clear (G, 0);
   Check (Add_Raises (G, 1, 1, 0), "Add on empty graph");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 1);
   Check (MST_Raises (G, 0), "MST buffer Last<M (0)");
   Check (MST_Raises_Bad_First (G), "MST First/=1");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Check (MST_Raises (G, 1), "MST buffer too small Last=1<M=2");

   ------------------------------------------------------------------
   Section ("14. Alias Boruvka == MST");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 3);
   Add_Edge (G, 3, 4, 4);
   Add_Edge (G, 4, 1, 10);
   Add_Edge (G, 1, 3, 5);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Boruvka (G, Tree_K, CK, WK);
   Check (C = CK and then W = WK, "alias totals");
   Check (C = 3, "alias count 3");

   ------------------------------------------------------------------
   Section ("15. Larger path + chord");
   ------------------------------------------------------------------
   Clear (G, 10);
   for I in 1 .. 9 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
   end loop;
   Add_Edge (G, 1, 10, 100);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 9, "P10+chord count");
   Check (W = 45, "P10+chord weight 1..9");
   Check (not Edge_In_Tree (Tree, C, 1, 10, 100), "P10 drops chord");
   Agree_With_Kruskal ("P10");

   ------------------------------------------------------------------
   Section ("16. Grid-like 3x3 vertices");
   ------------------------------------------------------------------
   Clear (G, 9);
   Add_Edge (G, 1, 2, 1); Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 4, 5, 1); Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 7, 8, 1); Add_Edge (G, 8, 9, 1);
   Add_Edge (G, 1, 4, 1); Add_Edge (G, 4, 7, 1);
   Add_Edge (G, 2, 5, 1); Add_Edge (G, 5, 8, 1);
   Add_Edge (G, 3, 6, 1); Add_Edge (G, 6, 9, 1);
   Add_Edge (G, 1, 9, 50);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 8, "grid MST edges = N-1");
   Check (W = 8, "grid all unit");
   Check (not Edge_In_Tree (Tree, C, 1, 9, 50), "grid drops diag");
   Agree_With_Kruskal ("grid");

   ------------------------------------------------------------------
   Section ("17. Many small agreement cases");
   ------------------------------------------------------------------
   for N in 2 .. 8 loop
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I * 3);
      end loop;
      Agree_With_Kruskal ("path-N" & Integer'Image (N));
   end loop;

   for N in 3 .. 7 loop
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
      end loop;
      Add_Edge (G, Vertex_Id (N), 1, N + 5);
      Agree_With_Kruskal ("cyc-N" & Integer'Image (N));
   end loop;

   ------------------------------------------------------------------
   Section ("18. Duplicate weights alternate optima");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 1, 1);
   Add_Edge (G, 1, 3, 1);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Kruskal_Reference (G, Tree_K, CK, WK);
   Check (C = 3 and then CK = 3, "dup count 3");
   Check (W = 3 and then WK = 3, "dup weight 3");
   Check (W = WK, "dup totals match");

   ------------------------------------------------------------------
   Section ("19. Light-first stress");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 100);
   Add_Edge (G, 2, 3, 90);
   Add_Edge (G, 3, 4, 80);
   Add_Edge (G, 4, 5, 70);
   Add_Edge (G, 1, 5, 1);
   Add_Edge (G, 2, 4, 2);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 4, "stress count");
   Check (W = 153, "stress weight 1+2+70+80");
   Check (Edge_In_Tree (Tree, C, 1, 5, 1), "stress keeps 1-5");
   Check (Edge_In_Tree (Tree, C, 2, 4, 2), "stress keeps 2-4");
   Agree_With_Kruskal ("stress");

   ------------------------------------------------------------------
   Section ("20. Component mix");
   ------------------------------------------------------------------
   Clear (G, 8);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 1, 9);
   Add_Edge (G, 4, 5, 3);
   Add_Edge (G, 5, 6, 4);
   Add_Edge (G, 7, 8, 5);
   Add_Edge (G, 7, 7, 99);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 5, "mix forest count");
   Check (W = 1 + 2 + 3 + 4 + 5, "mix weight");
   Check (not Edge_In_Tree (Tree, C, 3, 1, 9), "mix drops 9");
   Check (not Edge_In_Tree (Tree, C, 7, 7, 99), "mix drops loop");
   Agree_With_Kruskal ("mix");

   ------------------------------------------------------------------
   Section ("21. API counters and Max bounds smoke");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Max_Vertices Clear");
   Check (Edge_Count (G) = 0, "Max_Vertices no edges");
   Add_Edge (G, 1, Vertex_Id (Max_Vertices), 0);
   Check (Edge_Count (G) = 1, "edge across max span");
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 1 and then W = 0, "max-span MST");
   Agree_With_Kruskal ("max-span");

   Clear (G, 2);
   for I in 1 .. 50 loop
      Add_Edge (G, 1, 2, 100 - (I mod 50));
   end loop;
   Check (Edge_Count (G) = 50, "50 parallels");
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 1, "50par count");
   Check (W = 51, "50par lightest is 51");
   Agree_With_Kruskal ("50par");

   ------------------------------------------------------------------
   Section ("22. More unique MST identities");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 1, 4, 3);
   Add_Edge (G, 2, 3, 4);
   Add_Edge (G, 2, 5, 5);
   Add_Edge (G, 3, 6, 6);
   Add_Edge (G, 4, 5, 7);
   Add_Edge (G, 5, 6, 8);
   Add_Edge (G, 4, 6, 9);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 5, "tree6 count");
   Agree_With_Kruskal ("tree6");
   Check (Edge_In_Tree (Tree, C, 1, 2, 1), "tree6 has 1-2");
   Check (Edge_In_Tree (Tree, C, 1, 3, 2), "tree6 has 1-3");
   Check (Edge_In_Tree (Tree, C, 1, 4, 3), "tree6 has 1-4");

   Clear (G, 7);
   for I in 1 .. 6 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
   end loop;
   Add_Edge (G, 1, 4, 100);
   Add_Edge (G, 2, 6, 100);
   Add_Edge (G, 3, 7, 100);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 6 and then W = 21, "path7+heavies");
   Agree_With_Kruskal ("path7h");

   ------------------------------------------------------------------
   Section ("23. Zero-weight spanning");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 3, 4, 0);
   Add_Edge (G, 1, 4, 0);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 3 and then W = 0, "all-zero MST");
   Agree_With_Kruskal ("all-zero");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 1, 3, 5);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 2, "zero+ties count");
   Check (W = 5, "zero+ties weight");
   Agree_With_Kruskal ("zero-ties");

   ------------------------------------------------------------------
   Section ("24. Kruskal alone smoke");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 3);
   Add_Edge (G, 1, 4, 2);
   Kruskal_Reference (G, Tree_K, CK, WK);
   Check (CK = 3, "Kruskal alone count");
   Check (WK = 6, "Kruskal alone weight 1+2+3");
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (W = WK and then C = CK, "Boruvka matches Kruskal alone");

   ------------------------------------------------------------------
   Section ("25. Two-component with internals");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 3);
   Add_Edge (G, 4, 5, 4);
   Add_Edge (G, 5, 6, 5);
   Add_Edge (G, 4, 6, 6);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 4, "2comp internal count");
   Check (W = 1 + 2 + 4 + 5, "2comp internal weight");
   Agree_With_Kruskal ("2comp-int");

   ------------------------------------------------------------------
   Section ("26. Edge buffer exact size");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   declare
      Exact : Edge_List (1 .. 2);
      Ce    : Natural;
      We    : Weight_Sum;
   begin
      Minimum_Spanning_Tree (G, Exact, Ce, We);
      Check (Ce = 2 and then We = 3, "exact buffer OK");
   end;

   ------------------------------------------------------------------
   Section ("27. More path/cycle/star micro-cases");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 2, 1, 42);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 1 and then W = 42, "reversed endpoints");
   Agree_With_Kruskal ("rev-ep");

   Clear (G, 8);
   for I in 1 .. 7 loop
      Add_Edge (G, 1, Vertex_Id (I + 1), I);
   end loop;
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 7 and then W = 28, "star8");
   Agree_With_Kruskal ("star8");

   Clear (G, 5);
   Add_Edge (G, 1, 2, 9);
   Add_Edge (G, 1, 3, 8);
   Add_Edge (G, 1, 4, 7);
   Add_Edge (G, 1, 5, 6);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 4, "hub+path count");
   Check (W = 9, "hub+path weight");
   Agree_With_Kruskal ("hub-path");

   ------------------------------------------------------------------
   Section ("28. Negative and overflow edge cases");
   ------------------------------------------------------------------
   Clear (G, 2);
   Check (Add_Raises (G, 1, 2, Int (Integer'First)), "Integer'First neg");
   Check (not Add_Raises (G, 1, 2, Int (0)), "zero ok");
   Check (Edge_Count (G) = 1, "after zero add");

   Clear (G2, Max_Vertices);
   Check (Vertex_Count (G2) = Max_Vertices, "G2 max N");
   Check (Clear_Raises (Nat (Max_Vertices + 10)), "Clear far over");

   ------------------------------------------------------------------
   Section ("29. Agreement battery (handcrafted)");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 6);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 1, 4, 5);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 2, 5, 3);
   Add_Edge (G, 3, 4, 5);
   Add_Edge (G, 3, 5, 6);
   Add_Edge (G, 4, 5, 4);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 4, "classic5 count");
   Check (W = 13, "classic5 weight");
   Agree_With_Kruskal ("classic5");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, 10);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 3 and then W = 3, "almost-bipartite");
   Agree_With_Kruskal ("almost-bi");

   ------------------------------------------------------------------
   Section ("30. Single edge components many");
   ------------------------------------------------------------------
   Clear (G, 10);
   for I in 1 .. 5 loop
      Add_Edge
        (G, Vertex_Id (2 * I - 1), Vertex_Id (2 * I), I);
   end loop;
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 5 and then W = 15, "five disjoint edges");
   Agree_With_Kruskal ("five-disj");

   ------------------------------------------------------------------
   Section ("31. Multi-phase merges");
   ------------------------------------------------------------------
   --  Dense enough that Borůvka needs >1 phase
   Clear (G, 8);
   for I in 1 .. 7 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
   end loop;
   Add_Edge (G, 1, 5, 50);
   Add_Edge (G, 2, 6, 50);
   Add_Edge (G, 3, 7, 50);
   Add_Edge (G, 4, 8, 50);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 7 and then W = 28, "multi-phase path");
   Agree_With_Kruskal ("multi-phase");

   Clear (G, 16);
   for I in 1 .. 15 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
   end loop;
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 15 and then W = 15, "P16 unit");
   Agree_With_Kruskal ("P16");

   ------------------------------------------------------------------
   Section ("32. Final cross-checks");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 1, 2);
   Add_Edge (G, 4, 5, 2);
   Add_Edge (G, 5, 6, 2);
   Add_Edge (G, 6, 4, 2);
   Add_Edge (G, 3, 4, 1);
   Minimum_Spanning_Tree (G, Tree, C, W);
   Check (C = 5, "bridged triangles count");
   Check (W = 9, "bridged triangles weight");
   Check (Edge_In_Tree (Tree, C, 3, 4, 1), "keeps bridge");
   Agree_With_Kruskal ("bridged-tri");

   Boruvka (G, Tree, C, W);
   Kruskal_Reference (G, Tree_K, CK, WK);
   Check (C = CK and then W = WK, "final alias=Kruskal");

   Has := Edge_In_Tree (Tree, C, 1, 2, 2)
     or else Edge_In_Tree (Tree, C, 2, 3, 2)
     or else Edge_In_Tree (Tree, C, 3, 1, 2);
   Check (Has, "triangle remnant present");

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
