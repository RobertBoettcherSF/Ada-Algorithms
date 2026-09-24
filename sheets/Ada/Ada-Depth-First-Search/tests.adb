--  Standalone test suite for Depth_First_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Depth_First_Search; use Depth_First_Search;

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

   function DFS_Raises
     (G : Graph; Start : Vertex_Id; First, Last : Positive) return Boolean
   is
      Order : Order_Array (First .. Last);
      Count : Natural;
   begin
      DFS (G, Start, Order, Count);
      pragma Unreferenced (Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end DFS_Raises;

   function Forest_Raises
     (G : Graph; First, Last : Positive) return Boolean
   is
      Order : Order_Array (First .. Last);
      Count : Natural;
   begin
      DFS_Forest (G, Order, Count);
      pragma Unreferenced (Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Forest_Raises;

   function Reach_Raises
     (G : Graph; Start, Target : Vertex_Id) return Boolean
   is
      R : Boolean;
   begin
      R := Reachable (G, Start, Target);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reach_Raises;

   function Times_Raises
     (G : Graph; D_Last, F_Last : Positive) return Boolean
   is
      Discover : Time_Array (1 .. Vertex_Id (D_Last));
      Finish   : Time_Array (1 .. Vertex_Id (F_Last));
   begin
      DFS_Timestamps (G, Discover, Finish);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Times_Raises;

   function In_Order
     (Order : Order_Array; Count : Natural; V : Vertex_Id) return Boolean
   is
   begin
      for I in 1 .. Count loop
         if Order (I) = V then
            return True;
         end if;
      end loop;
      return False;
   end In_Order;

   function Order_Index
     (Order : Order_Array; Count : Natural; V : Vertex_Id) return Natural
   is
   begin
      for I in 1 .. Count loop
         if Order (I) = V then
            return I;
         end if;
      end loop;
      return 0;
   end Order_Index;

   function Parenthesis_OK
     (Discover, Finish : Time_Array; N : Natural) return Boolean
   is
      --  For every pair, intervals nest or are disjoint.
   begin
      for U in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Discover (U) = 0 or else Finish (U) = 0 then
            return False;
         end if;
         if Discover (U) >= Finish (U) then
            return False;
         end if;
      end loop;
      for U in Vertex_Id range 1 .. Vertex_Id (N) loop
         for W in Vertex_Id range 1 .. Vertex_Id (N) loop
            if U < W then
               declare
                  Du : constant Natural := Discover (U);
                  Fu : constant Natural := Finish (U);
                  Dw : constant Natural := Discover (W);
                  Fw : constant Natural := Finish (W);
                  Nest_UW : constant Boolean := Du < Dw and then Fw < Fu;
                  Nest_WU : constant Boolean := Dw < Du and then Fu < Fw;
                  Disjoint : constant Boolean :=
                    Fu < Dw or else Fw < Du;
               begin
                  if not (Nest_UW or else Nest_WU or else Disjoint) then
                     return False;
                  end if;
               end;
            end if;
         end loop;
      end loop;
      return True;
   end Parenthesis_OK;

   procedure Check_Topo_Edges
     (G : Graph; Finish : Time_Array; N : Natural; Label : String)
   is
      --  Build edge list by probing: for each From, we cannot read Head
      --  privately, so check via known construction in callers — here we
      --  only verify Finish times are a permutation of a valid schedule:
      --  all Finish in 1..2N and distinct from Discover handled elsewhere.
      Seen : array (1 .. 2 * Max_Vertices) of Boolean := [others => False];
      F    : Natural;
   begin
      pragma Unreferenced (G);
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         F := Finish (V);
         Check (F >= 1 and then F <= 2 * N, Label & " finish range " &
                  Vertex_Id'Image (V));
         if F >= 1 and then F <= 2 * Max_Vertices then
            Check (not Seen (F), Label & " finish unique " &
                     Vertex_Id'Image (V));
            Seen (F) := True;
         end if;
      end loop;
   end Check_Topo_Edges;

   G       : Graph;
   Order   : Order_Array (1 .. Max_Vertices);
   Count   : Natural;
   Discover : Time_Array (Vertex_Id);
   Finish   : Time_Array (Vertex_Id);

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   DFS (G, 1, Order, Count);
   Check (Count = 0, "empty DFS count 0");
   DFS_Forest (G, Order, Count);
   Check (Count = 0, "empty forest count 0");
   Check (Reach_Raises (G, 1, 1), "empty Reachable raises");
   Check (Times_Raises (G, Max_Vertices, Max_Vertices),
          "empty Timestamps raises");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   DFS (G, 1, Order, Count);
   Check (Count = 1 and then Order (1) = 1, "single DFS");
   DFS_Forest (G, Order, Count);
   Check (Count = 1 and then Order (1) = 1, "single forest");
   Check (Reachable (G, 1, 1), "single reachable self");
   DFS_Timestamps (G, Discover, Finish);
   Check (Discover (1) = 1 and then Finish (1) = 2, "single times 1,2");
   Check (Parenthesis_OK (Discover, Finish, 1), "single parenthesis");

   Add_Edge (G, 1, 1);
   Check (Edge_Count (G) = 1, "self-loop edge count");
   DFS (G, 1, Order, Count);
   Check (Count = 1 and then Order (1) = 1, "self-loop DFS once");
   Check (Reachable (G, 1, 1), "self-loop reachable");

   ------------------------------------------------------------------
   Section ("2. Two-vertex digraphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   DFS (G, 1, Order, Count);
   Check (Count = 1 and then Order (1) = 1, "2 isolated DFS from 1");
   DFS (G, 2, Order, Count);
   Check (Count = 1 and then Order (1) = 2, "2 isolated DFS from 2");
   DFS_Forest (G, Order, Count);
   Check (Count = 2, "2 isolated forest count");
   Check (Order (1) = 1 and then Order (2) = 2, "2 isolated forest order");
   Check (not Reachable (G, 1, 2), "2 isolated 1↛2");
   Check (not Reachable (G, 2, 1), "2 isolated 2↛1");
   Check (Reachable (G, 1, 1), "2 isolated 1→1");

   Add_Edge (G, 1, 2);
   DFS (G, 1, Order, Count);
   Check (Count = 2, "arc 1→2 count");
   Check (Order (1) = 1 and then Order (2) = 2, "arc 1→2 order");
   DFS (G, 2, Order, Count);
   Check (Count = 1 and then Order (1) = 2, "arc from 2 only self");
   Check (Reachable (G, 1, 2), "arc reachable");
   Check (not Reachable (G, 2, 1), "arc no reverse");
   DFS_Timestamps (G, Discover, Finish);
   Check (Discover (1) < Discover (2), "arc disc 1 before 2");
   Check (Finish (2) < Finish (1), "arc finish 2 before 1");
   Check (Parenthesis_OK (Discover, Finish, 2), "arc parenthesis");

   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   DFS (G, 1, Order, Count);
   Check (Count = 2, "2-cycle from 1 visits both");
   Check (Reachable (G, 1, 2) and then Reachable (G, 2, 1), "2-cycle both ways");
   DFS_Forest (G, Order, Count);
   Check (Count = 2, "2-cycle forest");

   ------------------------------------------------------------------
   Section ("3. Directed chains");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   DFS (G, 1, Order, Count);
   Check (Count = 5, "chain count 5");
   Check (Order (1) = 1 and then Order (5) = 5, "chain ends");
   Check (Order (2) = 2 and then Order (3) = 3 and then Order (4) = 4,
          "chain middle");
   DFS (G, 3, Order, Count);
   Check (Count = 3 and then Order (1) = 3 and then Order (3) = 5,
          "chain from mid");
   Check (Reachable (G, 1, 5), "chain 1→5");
   Check (not Reachable (G, 5, 1), "chain no back");
   Check (not Reachable (G, 4, 2), "chain no up");
   DFS_Timestamps (G, Discover, Finish);
   Check (Discover (1) = 1, "chain disc root");
   Check (Discover (5) = 5 and then Finish (5) = 6, "chain leaf times");
   Check (Finish (1) = 10, "chain root finishes last");
   Check (Parenthesis_OK (Discover, Finish, 5), "chain parenthesis");
   --  Reverse finish topo: 1,2,3,4,5
   Check (Finish (1) > Finish (2) and then Finish (2) > Finish (3)
            and then Finish (3) > Finish (4) and then Finish (4) > Finish (5),
          "chain reverse-finish topo");

   ------------------------------------------------------------------
   Section ("4. Neighbour order (prepend)");
   ------------------------------------------------------------------
   --  Add 1→2 then 1→3: head is 3 then 2, so DFS explores 3 before 2.
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   DFS (G, 1, Order, Count);
   Check (Count = 3, "star count");
   Check (Order (1) = 1, "star root first");
   Check (Order (2) = 3 and then Order (3) = 2, "star explores 3 then 2");

   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   DFS (G, 1, Order, Count);
   Check (Count = 4, "diamond count");
   Check (Order (1) = 1, "diamond root");
   --  Head of 1 is 3 (added last), then 2. So order: 1,3,4,2
   Check (Order (2) = 3 and then Order (3) = 4 and then Order (4) = 2,
          "diamond order 1,3,4,2");
   Check (Reachable (G, 1, 4), "diamond reach 4");
   Check (not Reachable (G, 2, 3), "diamond no 2→3");

   ------------------------------------------------------------------
   Section ("5. Disconnected / forest");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   DFS (G, 1, Order, Count);
   Check (Count = 3, "comp A size");
   Check (In_Order (Order, Count, 1) and then In_Order (Order, Count, 3),
          "comp A members");
   Check (not In_Order (Order, Count, 4), "comp A no 4");
   DFS_Forest (G, Order, Count);
   Check (Count = 6, "forest all 6");
   Check (Order (1) = 1 and then Order (4) = 4, "forest roots 1 then 4");
   Check (not Reachable (G, 1, 6), "cross-comp unreachable");
   Check (Reachable (G, 4, 6), "comp B reachable");
   DFS_Timestamps (G, Discover, Finish);
   Check (Parenthesis_OK (Discover, Finish, 6), "disc forest parenthesis");
   Check (Finish (3) < Finish (1), "comp A finish nest");
   Check (Finish (6) < Finish (4), "comp B finish nest");

   ------------------------------------------------------------------
   Section ("6. Cycles");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 3, 4);
   DFS (G, 1, Order, Count);
   Check (Count = 4, "cycle+tail visits all");
   Check (Reachable (G, 1, 4), "cycle reach tail");
   Check (Reachable (G, 2, 1), "cycle wrap");
   DFS_Timestamps (G, Discover, Finish);
   Check (Parenthesis_OK (Discover, Finish, 4), "cycle parenthesis");
   Check (Discover (1) < Discover (2), "cycle disc order start");

   --  Complete digraph K3
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 1);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 1);
   Add_Edge (G, 3, 2);
   DFS (G, 1, Order, Count);
   Check (Count = 3, "K3 from 1");
   Check (Reachable (G, 2, 3), "K3 all reachable");
   DFS_Forest (G, Order, Count);
   Check (Count = 3, "K3 forest");

   ------------------------------------------------------------------
   Section ("7. DAG timestamps / topo");
   ------------------------------------------------------------------
   --  1→2→4, 1→3→4
   Clear (G, 4);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 1, 3);
   DFS_Timestamps (G, Discover, Finish);
   Check (Parenthesis_OK (Discover, Finish, 4), "DAG diamond paren");
   Check (Finish (1) > Finish (2) and then Finish (1) > Finish (3),
          "DAG root finishes after children");
   Check (Finish (2) > Finish (4) or else Finish (3) > Finish (4),
          "DAG pred finishes after 4");
   Check_Topo_Edges (G, Finish, 4, "DAG");

   --  Linear DAG topo uniqueness of reverse finish
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   DFS_Timestamps (G, Discover, Finish);
   Check (Finish (1) > Finish (2) and then Finish (2) > Finish (3),
          "line topo finish");
   Check (Discover (1) < Discover (2) and then Discover (2) < Discover (3),
          "line disc order");

   ------------------------------------------------------------------
   Section ("8. Stars / trees / grids");
   ------------------------------------------------------------------
   Clear (G, 6);
   --  Out-star: add leaves 2..6 onto 1 in order 2..6 ⇒ head explores 6 first
   for V in Vertex_Id range 2 .. 6 loop
      Add_Edge (G, 1, V);
   end loop;
   DFS (G, 1, Order, Count);
   Check (Count = 6, "out-star count");
   Check (Order (1) = 1 and then Order (2) = 6, "out-star first leaf 6");
   Check (Order (6) = 2, "out-star last leaf 2");

   Clear (G, 7);
   --  Binary tree: 1→2,1→3, 2→4,2→5, 3→6,3→7 (add left then right ⇒ right first)
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 3, 7);
   DFS (G, 1, Order, Count);
   Check (Count = 7, "btree count");
   Check (Order (1) = 1 and then Order (2) = 3, "btree right-first");
   Check (In_Order (Order, Count, 4) and then In_Order (Order, Count, 7),
          "btree leaves present");
   DFS_Timestamps (G, Discover, Finish);
   Check (Parenthesis_OK (Discover, Finish, 7), "btree parenthesis");

   --  2x3 grid DAG (right and down)
   Clear (G, 6);
   --  1 2 3
   --  4 5 6
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Check (Reachable (G, 1, 6), "grid 1→6");
   Check (not Reachable (G, 6, 1), "grid no back");
   DFS (G, 1, Order, Count);
   Check (Count = 6, "grid from 1 all");
   DFS_Timestamps (G, Discover, Finish);
   Check (Parenthesis_OK (Discover, Finish, 6), "grid parenthesis");
   Check (Finish (1) > Finish (6), "grid root after sink");

   ------------------------------------------------------------------
   Section ("9. Parallel edges / clear rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 3, "parallel edge count");
   DFS (G, 1, Order, Count);
   Check (Count = 2, "parallels still visit 2 once");
   Clear (G, 2);
   Check (Edge_Count (G) = 0 and then Vertex_Count (G) = 2, "clear rebuild");
   Add_Edge (G, 2, 1);
   Check (Reachable (G, 2, 1) and then not Reachable (G, 1, 2),
          "rebuild direction");

   ------------------------------------------------------------------
   Section ("10. Long chains");
   ------------------------------------------------------------------
   Clear (G, 30);
   for I in 1 .. 29 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   DFS (G, 1, Order, Count);
   Check (Count = 30, "N=30 chain count");
   Check (Order (1) = 1 and then Order (30) = 30, "N=30 ends");
   Check (Reachable (G, 1, 30), "N=30 reachable");
   Check (not Reachable (G, 30, 1), "N=30 no back");
   DFS_Timestamps (G, Discover, Finish);
   Check (Discover (1) = 1 and then Finish (1) = 60, "N=30 root times");
   Check (Discover (30) = 30 and then Finish (30) = 31, "N=30 leaf times");
   Check (Parenthesis_OK (Discover, Finish, 30), "N=30 parenthesis");

   Clear (G, 50);
   for I in 1 .. 49 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   DFS (G, 1, Order, Count);
   Check (Count = 50, "N=50 chain");
   DFS_Forest (G, Order, Count);
   Check (Count = 50, "N=50 forest");
   Check (Reachable (G, 10, 50) and then not Reachable (G, 50, 10),
          "N=50 mid reach");

   ------------------------------------------------------------------
   Section ("11. Forest order / multi-root");
   ------------------------------------------------------------------
   Clear (G, 5);
   --  Components: {1}, {2→3}, {4}, {5}  — wait N=5 with edges 2→3 only
   Add_Edge (G, 2, 3);
   DFS_Forest (G, Order, Count);
   Check (Count = 5, "multi-root forest count");
   Check (Order (1) = 1, "forest root 1 alone");
   Check (Order (2) = 2 and then Order (3) = 3, "forest tree 2-3");
   Check (Order (4) = 4 and then Order (5) = 5, "forest tails");
   DFS (G, 2, Order, Count);
   Check (Count = 2, "from 2 only 2,3");
   Check (not In_Order (Order, Count, 1), "from 2 no 1");

   ------------------------------------------------------------------
   Section ("12. Invalid_Argument");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear N too large");
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Clear Max_Vertices ok");

   Clear (G, 3);
   Check (Add_Raises (G, 1, 4), "Add_Edge To out of range");
   Check (Add_Raises (G, 4, 1), "Add_Edge From out of range");
   Clear (G, 0);
   Check (Add_Raises (G, 1, 1), "Add_Edge on empty");

   Clear (G, 3);
   Check (DFS_Raises (G, 4, 1, Max_Vertices), "DFS Start out of range");
   Check (DFS_Raises (G, 1, 2, Max_Vertices), "DFS Order First /= 1");
   Check (DFS_Raises (G, 1, 1, 2), "DFS Order too short");
   Check (Forest_Raises (G, 2, Max_Vertices), "Forest First /= 1");
   Check (Forest_Raises (G, 1, 2), "Forest too short");
   Check (Reach_Raises (G, 4, 1), "Reachable Start bad");
   Check (Reach_Raises (G, 1, 4), "Reachable Target bad");
   Check (Times_Raises (G, 2, Max_Vertices), "Timestamps Discover short");
   Check (Times_Raises (G, Max_Vertices, 2), "Timestamps Finish short");

   Clear (G, 0);
   Check (Reach_Raises (G, 1, 1), "Reachable N=0");
   Check (Times_Raises (G, Max_Vertices, Max_Vertices), "Timestamps N=0");

   ------------------------------------------------------------------
   Section ("13. Edge capacity");
   ------------------------------------------------------------------
   Clear (G, 2);
   --  Fill many parallel edges up to a modest batch (not full Max_Edges)
   for I in 1 .. 100 loop
      Add_Edge (G, 1, 2);
   end loop;
   Check (Edge_Count (G) = 100, "100 parallel edges");
   DFS (G, 1, Order, Count);
   Check (Count = 2, "still two vertices after parallels");

   ------------------------------------------------------------------
   Section ("14. Reachability matrix small");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 4);
   Check (Reachable (G, 1, 1), "R 1→1");
   Check (Reachable (G, 1, 2), "R 1→2");
   Check (Reachable (G, 1, 3), "R 1→3");
   Check (Reachable (G, 1, 4), "R 1→4");
   Check (Reachable (G, 2, 3), "R 2→3");
   Check (not Reachable (G, 2, 4), "R 2↛4");
   Check (not Reachable (G, 3, 1), "R 3↛1");
   Check (not Reachable (G, 4, 2), "R 4↛2");
   Check (Reachable (G, 4, 4), "R 4→4");
   Check (not Reachable (G, 3, 2), "R 3↛2");

   ------------------------------------------------------------------
   Section ("15. Discovery vs finish indices");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 3, 4);
   DFS (G, 1, Order, Count);
   DFS_Timestamps (G, Discover, Finish);
   --  Discovery order matches Order from DFS (same Start, one component)
   Check (Count = 4, "disc-finish graph size");
   Check (Order_Index (Order, Count, 1) = 1, "disc idx root");
   --  Finish times: deeper nodes finish earlier
   Check (Finish (4) < Finish (3) and then Finish (3) < Finish (1),
          "nested finish 4<3<1");
   Check (Finish (2) < Finish (1), "leaf 2 before root");
   Check (Discover (Order (1)) < Discover (Order (2)), "order vs disc");
   Check (Discover (Order (2)) < Discover (Order (3)), "order vs disc 2");
   Check (Discover (Order (3)) < Discover (Order (4)), "order vs disc 3");

   ------------------------------------------------------------------
   Section ("16. Isolated mix + API counters");
   ------------------------------------------------------------------
   Clear (G, 8);
   Add_Edge (G, 3, 5);
   Add_Edge (G, 5, 7);
   Check (Vertex_Count (G) = 8, "mix V=8");
   Check (Edge_Count (G) = 2, "mix E=2");
   DFS_Forest (G, Order, Count);
   Check (Count = 8, "mix forest 8");
   Check (Order_Index (Order, Count, 3) < Order_Index (Order, Count, 5),
          "mix 3 before 5");
   Check (Order_Index (Order, Count, 5) < Order_Index (Order, Count, 7),
          "mix 5 before 7");
   Check (Reachable (G, 3, 7), "mix 3→7");
   Check (not Reachable (G, 7, 3), "mix 7↛3");
   Check (not Reachable (G, 1, 3), "mix 1↛3");
   DFS (G, 1, Order, Count);
   Check (Count = 1, "mix isolated start");

   ------------------------------------------------------------------
   Section ("17. Clock covers 1 .. 2N");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 3, 4);
   DFS_Timestamps (G, Discover, Finish);
   declare
      Seen : array (1 .. 10) of Boolean := [others => False];
      T    : Natural;
      Ok   : Boolean := True;
   begin
      for V in Vertex_Id range 1 .. 5 loop
         T := Discover (V);
         if T < 1 or else T > 10 or else Seen (T) then
            Ok := False;
         else
            Seen (T) := True;
         end if;
         T := Finish (V);
         if T < 1 or else T > 10 or else Seen (T) then
            Ok := False;
         else
            Seen (T) := True;
         end if;
      end loop;
      for I in 1 .. 10 loop
         if not Seen (I) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "clock permutation 1..10");
   end;
   Check (Parenthesis_OK (Discover, Finish, 5), "clock paren");

   ------------------------------------------------------------------
   Section ("18. Wide shallow / deep narrow");
   ------------------------------------------------------------------
   Clear (G, 21);
   for V in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, V);
   end loop;
   DFS (G, 1, Order, Count);
   Check (Count = 21, "wide star");
   Check (Order (2) = 21 and then Order (21) = 2, "wide reverse leaves");

   Clear (G, 21);
   for I in 1 .. 20 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   DFS (G, 1, Order, Count);
   Check (Count = 21, "deep chain 21");
   DFS_Timestamps (G, Discover, Finish);
   Check (Finish (1) = 42 and then Discover (21) = 21, "deep times");

   ------------------------------------------------------------------
   Section ("19. Back edge does not re-visit");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 2);  -- back
   Add_Edge (G, 3, 1);  -- back
   DFS (G, 1, Order, Count);
   Check (Count = 3, "back-edges still 3");
   Check (Order (1) = 1 and then Order (2) = 2 and then Order (3) = 3,
          "back-edge chain order");

   ------------------------------------------------------------------
   Section ("20. Cross-check forest vs union of DFS");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   DFS_Forest (G, Order, Count);
   Check (Count = 7, "union forest size");
   declare
      O2 : Order_Array (1 .. Max_Vertices);
      C2 : Natural;
      All_Ok : Boolean := True;
   begin
      for V in Vertex_Id range 1 .. 7 loop
         DFS (G, V, O2, C2);
         for I in 1 .. C2 loop
            if not In_Order (Order, Count, O2 (I)) then
               All_Ok := False;
            end if;
         end loop;
      end loop;
      Check (All_Ok, "each DFS subset of forest");
   end;

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
