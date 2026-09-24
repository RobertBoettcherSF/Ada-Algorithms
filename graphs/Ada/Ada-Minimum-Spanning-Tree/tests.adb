--  Standalone test suite for Minimum_Spanning_Tree survey (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Minimum_Spanning_Tree; use Minimum_Spanning_Tree;

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

   function Method_Raises
     (G : Graph; Buf_Last : Natural; Which : Character) return Boolean
   is
      Tree : Edge_List (1 .. Positive'Max (1, Buf_Last));
      C    : Natural;
      W    : Weight_Sum;
   begin
      if Buf_Last = 0 then
         declare
            Empty_Buf : Edge_List (1 .. 0);
         begin
            case Which is
               when 'K' => Kruskal (G, Empty_Buf, C, W);
               when 'P' => Prim (G, Empty_Buf, C, W);
               when 'B' => Boruvka (G, Empty_Buf, C, W);
               when others => Reverse_Delete (G, Empty_Buf, C, W);
            end case;
         end;
      else
         case Which is
            when 'K' => Kruskal (G, Tree (1 .. Buf_Last), C, W);
            when 'P' => Prim (G, Tree (1 .. Buf_Last), C, W);
            when 'B' => Boruvka (G, Tree (1 .. Buf_Last), C, W);
            when others => Reverse_Delete (G, Tree (1 .. Buf_Last), C, W);
         end case;
      end if;
      pragma Unreferenced (C, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Method_Raises;

   function Method_Raises_Bad_First
     (G : Graph; Which : Character) return Boolean
   is
      Tree : Edge_List (2 .. Max_Edges + 1);
      C    : Natural;
      W    : Weight_Sum;
   begin
      case Which is
         when 'K' => Kruskal (G, Tree, C, W);
         when 'P' => Prim (G, Tree, C, W);
         when 'B' => Boruvka (G, Tree, C, W);
         when others => Reverse_Delete (G, Tree, C, W);
      end case;
      pragma Unreferenced (C, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Method_Raises_Bad_First;

   G : Graph;
   TK, TP, TB, TR : Edge_List (1 .. Max_Edges);
   CK, CP, CB, CR : Natural;
   WK, WP, WB, WR : Weight_Sum;

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

   procedure Run_All is
   begin
      Kruskal (G, TK, CK, WK);
      Prim (G, TP, CP, WP);
      Boruvka (G, TB, CB, WB);
      Reverse_Delete (G, TR, CR, WR);
   end Run_All;

   procedure Agree4 (Label : String) is
   begin
      Run_All;
      Check (CK = CP and then CK = CB and then CK = CR,
             Label & " count agree");
      Check (WK = WP and then WK = WB and then WK = WR,
             Label & " weight agree");
   end Agree4;

begin
   ---------------------------------------------------------------------------
   Section ("1. Empty / single / edgeless");
   ---------------------------------------------------------------------------
   Clear (G, Nat (0));
   Check (Vertex_Count (G) = 0, "empty N=0");
   Check (Edge_Count (G) = 0, "empty M=0");
   Agree4 ("empty");
   Check (CK = 0 and then WK = 0, "empty zero result");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex N");
   Agree4 ("single");
   Check (CK = 0 and then WK = 0, "single zero edges");

   Clear (G, 5);
   Agree4 ("edgeless-5");
   Check (CK = 0 and then WK = 0, "edgeless MSF empty");

   ---------------------------------------------------------------------------
   Section ("2. Unique MST textbook example");
   ---------------------------------------------------------------------------
   --  {1,2}:1, {1,3}:4, {2,3}:2, {2,4}:5, {3,4}:3 ⇒ MST weight 6, 3 edges
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 3);
   Agree4 ("textbook");
   Check (CK = 3 and then WK = 6, "textbook weight 6");
   Check (Edge_In_Tree (TK, CK, 1, 2, 1), "textbook has 1-2");
   Check (Edge_In_Tree (TK, CK, 2, 3, 2), "textbook has 2-3");
   Check (Edge_In_Tree (TK, CK, 3, 4, 3), "textbook has 3-4");

   ---------------------------------------------------------------------------
   Section ("3. Two vertices");
   ---------------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 7);
   Agree4 ("two-vert");
   Check (CK = 1 and then WK = 7, "two-vert weight 7");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 0);
   Agree4 ("two-zero");
   Check (CK = 1 and then WK = 0, "zero-weight edge kept");

   ---------------------------------------------------------------------------
   Section ("4. Self-loops ignored");
   ---------------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 1, 9);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 2, 8);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 3, 7);
   Agree4 ("self-loops");
   Check (CK = 2 and then WK = 3, "self-loops ignored weight 3");
   Check (not Edge_In_Tree (TK, CK, 1, 1, 9), "no self-loop in tree");

   ---------------------------------------------------------------------------
   Section ("5. Parallel edges");
   ---------------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 4);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 10);
   Agree4 ("parallels");
   Check (CK = 2 and then WK = 3, "parallels keep lightest");

   ---------------------------------------------------------------------------
   Section ("6. Forests / disconnected");
   ---------------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 9);
   Add_Edge (G, 4, 5, 3);
   Add_Edge (G, 5, 6, 4);
   Add_Edge (G, 4, 6, 8);
   Agree4 ("forest-2comp");
   Check (CK = 4 and then WK = 10, "forest weight 1+2+3+4");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   --  vertices 3,4 isolated
   Agree4 ("forest-isolates");
   Check (CK = 1 and then WK = 1, "one edge + isolates");

   ---------------------------------------------------------------------------
   Section ("7. Path graphs");
   ---------------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 4, 3);
   Add_Edge (G, 4, 5, 4);
   Agree4 ("path-5");
   Check (CK = 4 and then WK = 10, "path weight 10");

   Clear (G, 6);
   for I in 1 .. 5 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
   end loop;
   Agree4 ("path-6");
   Check (CK = 5 and then WK = 15, "path-6 weight 15");

   ---------------------------------------------------------------------------
   Section ("8. Cycles");
   ---------------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 1, 1);
   Agree4 ("C4-equal");
   Check (CK = 3 and then WK = 3, "C4 equal weights");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 1, 100);
   Agree4 ("triangle");
   Check (CK = 2 and then WK = 3, "triangle drops heavy");
   Check (not Edge_In_Tree (TK, CK, 3, 1, 100), "heavy chord out");

   ---------------------------------------------------------------------------
   Section ("9. Stars");
   ---------------------------------------------------------------------------
   Clear (G, 6);
   for I in 2 .. 6 loop
      Add_Edge (G, 1, Vertex_Id (I), I);
   end loop;
   Agree4 ("star-6");
   Check (CK = 5 and then WK = 2 + 3 + 4 + 5 + 6, "star weight");

   Clear (G, 5);
   Add_Edge (G, 3, 1, 4);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 3, 4, 2);
   Add_Edge (G, 3, 5, 3);
   Agree4 ("star-center-3");
   Check (CK = 4 and then WK = 10, "star center 3");

   ---------------------------------------------------------------------------
   Section ("10. Complete K3 / K4");
   ---------------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 2, 3, 3);
   Agree4 ("K3");
   Check (CK = 2 and then WK = 3, "K3 weight 3");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 1, 4, 3);
   Add_Edge (G, 2, 3, 4);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 6);
   Agree4 ("K4");
   Check (CK = 3 and then WK = 6, "K4 weight 1+2+3");

   ---------------------------------------------------------------------------
   Section ("11. Clear / rebuild");
   ---------------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Agree4 ("rebuild-a");
   Clear (G, 2);
   Add_Edge (G, 1, 2, 9);
   Agree4 ("rebuild-b");
   Check (CK = 1 and then WK = 9, "rebuild result");
   Check (Vertex_Count (G) = 2 and then Edge_Count (G) = 1, "rebuild counters");

   ---------------------------------------------------------------------------
   Section ("12. Invalid_Argument guards");
   ---------------------------------------------------------------------------
   Check (Clear_Raises (Max_Vertices + 1), "Clear overflow");
   Clear (G, 3);
   Check (Add_Raises (G, 1, 4, 1), "Add bad vertex");
   Check (Add_Raises (G, 1, 2, Int (-1)), "Add negative");
   Check (Add_Raises (G, 1, 2, Int (-100)), "Add more negative");

   Clear (G, 0);
   Check (Add_Raises (G, 1, 1, 0), "Add on N=0");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 1);
   Check (Method_Raises (G, 0, 'K'), "Kruskal tiny buf");
   Check (Method_Raises (G, 0, 'P'), "Prim tiny buf");
   Check (Method_Raises (G, 0, 'B'), "Boruvka tiny buf");
   Check (Method_Raises (G, 0, 'R'), "RevDel tiny buf");
   Check (Method_Raises_Bad_First (G, 'K'), "Kruskal bad First");
   Check (Method_Raises_Bad_First (G, 'P'), "Prim bad First");
   Check (Method_Raises_Bad_First (G, 'B'), "Boruvka bad First");
   Check (Method_Raises_Bad_First (G, 'R'), "RevDel bad First");

   ---------------------------------------------------------------------------
   Section ("13. Larger path + chord");
   ---------------------------------------------------------------------------
   Clear (G, 8);
   for I in 1 .. 7 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
   end loop;
   Add_Edge (G, 1, 8, 100);
   Agree4 ("path+chord");
   Check (CK = 7 and then WK = 28, "path+chord weight 28");
   Check (not Edge_In_Tree (TK, CK, 1, 8, 100), "heavy chord rejected");

   ---------------------------------------------------------------------------
   Section ("14. Grid-like 3x3 vertices");
   ---------------------------------------------------------------------------
   --  1-2-3 / 4-5-6 / 7-8-9 with row and column edges
   Clear (G, 9);
   Add_Edge (G, 1, 2, 1); Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 4, 5, 1); Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 7, 8, 1); Add_Edge (G, 8, 9, 1);
   Add_Edge (G, 1, 4, 2); Add_Edge (G, 4, 7, 2);
   Add_Edge (G, 2, 5, 2); Add_Edge (G, 5, 8, 2);
   Add_Edge (G, 3, 6, 2); Add_Edge (G, 6, 9, 2);
   Agree4 ("grid-3x3");
   Check (CK = 8, "grid tree 8 edges");
   Check (WK = 10, "grid weight 6*1 + 2*2 = 10");

   ---------------------------------------------------------------------------
   Section ("15. Many small agreement cases");
   ---------------------------------------------------------------------------
   for N in 1 .. 10 loop
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
      end loop;
      Agree4 ("chain-N=" & Natural'Image (N));
   end loop;

   ---------------------------------------------------------------------------
   Section ("16. Duplicate weights alternate optima");
   ---------------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 1, 3, 1);
   Agree4 ("all-equal-K4-minus");
   Check (CK = 3 and then WK = 3, "all-equal weight 3");

   ---------------------------------------------------------------------------
   Section ("17. Component mix");
   ---------------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 4, 5, 1);
   --  6,7 isolated
   Agree4 ("mix-comps");
   Check (CK = 3 and then WK = 4, "mix weight 4");

   ---------------------------------------------------------------------------
   Section ("18. API counters and Max bounds smoke");
   ---------------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Max_Vertices Clear");
   Check (Edge_Count (G) = 0, "Max_Vertices empty edges");
   Add_Edge (G, 1, 2, 1);
   Check (Edge_Count (G) = 1, "one edge on max verts");
   Agree4 ("max-verts-smoke");
   Check (CK = 1 and then WK = 1, "max-verts one edge");

   Clear (G, 2);
   declare
      Filled : Natural := 0;
   begin
      for I in 1 .. 50 loop
         Add_Edge (G, 1, 2, I);
         Filled := Filled + 1;
      end loop;
      Check (Edge_Count (G) = Filled, "50 parallels counted");
      Agree4 ("50-parallels");
      Check (CK = 1 and then WK = 1, "50 parallels keep lightest");
   end;

   ---------------------------------------------------------------------------
   Section ("19. More unique MST identities");
   ---------------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 1, 3, 3);
   Add_Edge (G, 1, 4, 4);
   Add_Edge (G, 1, 5, 5);
   Add_Edge (G, 2, 3, 10);
   Add_Edge (G, 3, 4, 10);
   Add_Edge (G, 4, 5, 10);
   Agree4 ("star-beats-rim");
   Check (CK = 4 and then WK = 14, "star beats rim");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 2, 3, 10);
   Add_Edge (G, 3, 4, 10);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 2, 4, 1);
   Agree4 ("light-diagonals");
   Check (CK = 3 and then WK = 3, "three light edges");

   ---------------------------------------------------------------------------
   Section ("20. Zero-weight spanning");
   ---------------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 3, 4, 0);
   Add_Edge (G, 1, 4, 5);
   Agree4 ("zero-span");
   Check (CK = 3 and then WK = 0, "zero spanning weight");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 1, 3, 0);
   Agree4 ("zero-K3");
   Check (CK = 2 and then WK = 0, "zero K3");

   ---------------------------------------------------------------------------
   Section ("21. Two-component with internals");
   ---------------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 5, 6, 2);
   Add_Edge (G, 4, 6, 4);
   Agree4 ("two-tri");
   Check (CK = 4 and then WK = 6, "two triangles MSF");

   ---------------------------------------------------------------------------
   Section ("22. Edge buffer exact size");
   ---------------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   declare
      Exact : Edge_List (1 .. 2);
      C : Natural;
      W : Weight_Sum;
   begin
      Kruskal (G, Exact, C, W);
      Check (C = 2 and then W = 3, "exact buf Kruskal");
      Prim (G, Exact, C, W);
      Check (C = 2 and then W = 3, "exact buf Prim");
      Boruvka (G, Exact, C, W);
      Check (C = 2 and then W = 3, "exact buf Boruvka");
      Reverse_Delete (G, Exact, C, W);
      Check (C = 2 and then W = 3, "exact buf RevDel");
   end;

   ---------------------------------------------------------------------------
   Section ("23. More path/cycle/star micro-cases");
   ---------------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 5);
   Agree4 ("path-equal");
   Check (WK = 10, "path-equal weight");

   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 5, 1, 1);
   Agree4 ("C5");
   Check (CK = 4 and then WK = 4, "C5 MST");

   Clear (G, 7);
   for I in 2 .. 7 loop
      Add_Edge (G, 1, Vertex_Id (I), 1);
   end loop;
   Agree4 ("star-unit");
   Check (CK = 6 and then WK = 6, "unit star");

   ---------------------------------------------------------------------------
   Section ("24. Negative and overflow edge cases");
   ---------------------------------------------------------------------------
   Clear (G, 2);
   Check (Add_Raises (G, 1, 2, Int (-1)), "neg again");
   Check (not Add_Raises (G, 1, 2, Int (0)), "zero ok");
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "overflow again");

   ---------------------------------------------------------------------------
   Section ("25. Agreement battery (handcrafted)");
   ---------------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 8);
   Add_Edge (G, 3, 5, 10);
   Add_Edge (G, 4, 5, 2);
   Agree4 ("battery-A");
   Check (WK = 10, "battery-A weight 1+2+2+5=10");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 4, 2);
   Agree4 ("battery-B");
   Check (WK = 3, "battery-B star");

   Clear (G, 6);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 1, 2);
   Add_Edge (G, 4, 5, 3);
   Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 6, 4, 2);
   Agree4 ("battery-C");
   Check (WK = 6, "battery-C two triangles");

   ---------------------------------------------------------------------------
   Section ("26. Single edge components many");
   ---------------------------------------------------------------------------
   Clear (G, 10);
   for I in 1 .. 5 loop
      Add_Edge (G, Vertex_Id (2 * I - 1), Vertex_Id (2 * I), I);
   end loop;
   Agree4 ("five-pairs");
   Check (CK = 5 and then WK = 15, "five pairs weight");

   ---------------------------------------------------------------------------
   Section ("27. Dense small complete");
   ---------------------------------------------------------------------------
   Clear (G, 5);
   declare
      Wgt : Integer := 1;
   begin
      for I in 1 .. 5 loop
         for J in I + 1 .. 5 loop
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J), Wgt);
            Wgt := Wgt + 1;
         end loop;
      end loop;
   end;
   Agree4 ("K5-unique");
   Check (CK = 4, "K5 tree edges");
   --  lightest star-ish: edges 1-2:1,1-3:2,1-4:3,1-5:4 = 10
   Check (WK = 10, "K5 unique weight 10");

   ---------------------------------------------------------------------------
   Section ("28. Bridged components");
   ---------------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 3, 4, 10);  -- bridge
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 4, 6, 5);
   Agree4 ("bridged");
   Check (CK = 5 and then WK = 14, "bridged weight 1+1+10+1+1");
   Check (Edge_In_Tree (TK, CK, 3, 4, 10), "bridge kept");

   ---------------------------------------------------------------------------
   Section ("29. Taxonomy / method smoke");
   ---------------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 4, 3);
   Add_Edge (G, 1, 4, 100);
   Run_All;
   Check (CK = CP, "taxonomy K=P count");
   Check (CK = CB, "taxonomy K=B count");
   Check (CK = CR, "taxonomy K=R count");
   Check (WK = WP and then WK = WB and then WK = WR,
          "taxonomy all weights");
   Check (WK = 6, "taxonomy weight 6");
   Check (Edge_Count (G) = 4, "taxonomy M=4");
   Check (Vertex_Count (G) = 4, "taxonomy N=4");

   ---------------------------------------------------------------------------
   Section ("30. Final cross-checks");
   ---------------------------------------------------------------------------
   Clear (G, 1);
   Agree4 ("final-single");
   Clear (G, 0);
   Agree4 ("final-empty");
   Clear (G, 3);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 3, 2);
   Agree4 ("final-equal-tri");
   Check (CK = 2 and then WK = 4, "final equal triangle");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 4, 3);
   Add_Edge (G, 4, 1, 4);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 4, 6);
   Agree4 ("final-diamond");
   Check (CK = 3 and then WK = 6, "final diamond 1+2+3");


   ---------------------------------------------------------------------------
   Section ("31. Extra agreement pad");
   ---------------------------------------------------------------------------
   Clear (G, 8);
   for I in 1 .. 7 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
   end loop;
   Add_Edge (G, 1, 5, 10);
   Add_Edge (G, 2, 6, 10);
   Agree4 ("pad-path");
   Check (CK = 7 and then WK = 7, "pad-path weight 7");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 3);
   Add_Edge (G, 3, 4, 3);
   Add_Edge (G, 4, 1, 1);
   Add_Edge (G, 1, 3, 1);
   Agree4 ("pad-light-cycle");
   Check (CK = 3 and then WK = 5, "pad-light 1+1+3");

   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 1, 5, 1);
   Add_Edge (G, 2, 3, 9);
   Agree4 ("pad-star");
   Check (CK = 4 and then WK = 4, "pad-star unit");

   Clear (G, 3);
   Agree4 ("pad-edgeless3");
   Check (CK = 0 and then WK = 0, "pad edgeless");

   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
