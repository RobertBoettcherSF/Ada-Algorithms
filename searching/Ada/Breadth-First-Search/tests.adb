--  Standalone test suite for Breadth_First_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Breadth_First_Search; use Breadth_First_Search;

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

   function BFS_Raises
     (G : Graph; Start : Vertex_Id; First, Last : Positive) return Boolean
   is
      Order : Order_Array (First .. Last);
      Count : Natural;
   begin
      BFS (G, Start, Order, Count);
      pragma Unreferenced (Count);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end BFS_Raises;

   function SP_Raises
     (G : Graph; Start : Vertex_Id; D_Last, P_Last : Positive) return Boolean
   is
      Dist : Distance_Array (1 .. Vertex_Id (D_Last));
      Prev : Prev_Array (1 .. Vertex_Id (P_Last));
   begin
      Shortest_Paths (G, Start, Dist, Prev);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end SP_Raises;

   function Dist_Raises
     (G : Graph; Start, Target : Vertex_Id) return Boolean
   is
      D : Natural;
   begin
      D := Distance (G, Start, Target);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Raises;

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

   function Recon_Raises
     (Prev : Prev_Array; Start, Target : Vertex_Id;
      First, Last : Positive) return Boolean
   is
      Path   : Order_Array (First .. Last);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Reconstruct_Path (Prev, Start, Target, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Recon_Raises;

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

   type Edge_Rec is record
      From, To : Vertex_Id := Vertex_Id'First;
   end record;
   type Edge_List is array (Positive range <>) of Edge_Rec;

   function Oracle_Dist_Edges
     (Edges : Edge_List; N : Natural;
      Start, Target : Vertex_Id) return Natural
   is
      --  Iterative deepening over explicit edge list (IDDFS oracle).
      function DLS (U : Vertex_Id; Limit : Natural) return Boolean is
      begin
         if U = Target then
            return True;
         end if;
         if Limit = 0 then
            return False;
         end if;
         for I in Edges'Range loop
            if Edges (I).From = U then
               if DLS (Edges (I).To, Limit - 1) then
                  return True;
               end if;
            end if;
         end loop;
         return False;
      end DLS;
   begin
      if Start = Target then
         return 0;
      end if;
      if N = 0 then
         return Infinity;
      end if;
      for Limit in 1 .. N - 1 loop
         if DLS (Start, Limit) then
            return Limit;
         end if;
      end loop;
      return Infinity;
   end Oracle_Dist_Edges;

   G       : Graph;
   Order   : Order_Array (1 .. Max_Vertices);
   Count   : Natural;
   Dist    : Distance_Array (Vertex_Id);
   Prev    : Prev_Array (Vertex_Id);
   Path    : Order_Array (1 .. Max_Vertices);
   Length  : Natural;
   Ok      : Boolean;
   D       : Natural;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty N=0");
   Check (Edge_Count (G) = 0, "empty E=0");
   BFS (G, 1, Order, Count);
   Check (Count = 0, "BFS on empty yields Count=0");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single N=1");
   Check (Edge_Count (G) = 0, "single E=0");
   BFS (G, 1, Order, Count);
   Check (Count = 1 and then Order (1) = 1, "BFS single visit");
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "single Dist=0");
   Check (Prev (1) = 0, "single Prev=0");
   Check (Distance (G, 1, 1) = 0, "Distance self=0");
   Check (Reachable (G, 1, 1), "Reachable self");
   Ok := Reconstruct_Path (Prev, 1, 1, Path, Length);
   Check (Ok and then Length = 1 and then Path (1) = 1, "recon self");

   Add_Edge (G, 1, 1);
   Check (Edge_Count (G) = 1, "self-loop edge");
   BFS (G, 1, Order, Count);
   Check (Count = 1, "self-loop still one visit");
   Check (Distance (G, 1, 1) = 0, "self-loop Distance 0");

   ------------------------------------------------------------------
   Section ("2. Two vertices / arcs / 2-cycle");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   BFS (G, 1, Order, Count);
   Check (Count = 2, "1->2 visits both");
   Check (Order (1) = 1 and then Order (2) = 2, "1->2 order");
   Check (Distance (G, 1, 2) = 1, "1->2 dist 1");
   Check (Distance (G, 2, 1) = Infinity, "2 cannot reach 1");
   Check (not Reachable (G, 2, 1), "2 not reach 1");
   Check (Reachable (G, 1, 2), "1 reaches 2");

   BFS (G, 2, Order, Count);
   Check (Count = 1 and then Order (1) = 2, "BFS from 2 alone");

   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 1);
   Check (Distance (G, 1, 2) = 1, "2-cycle 1->2");
   Check (Distance (G, 2, 1) = 1, "2-cycle 2->1");
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Length);
   Check (Ok and then Length = 2
            and then Path (1) = 1 and then Path (2) = 2,
          "2-cycle recon 1->2");

   ------------------------------------------------------------------
   Section ("3. Directed chains");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   BFS (G, 1, Order, Count);
   Check (Count = 5, "chain visits all");
   Check (Order (1) = 1 and then Order (5) = 5, "chain ends");
   for V in Vertex_Id range 1 .. 5 loop
      Check (Distance (G, 1, V) = Natural (V) - 1,
             "chain dist from 1 to" & Vertex_Id'Image (V));
   end loop;
   Check (Distance (G, 3, 5) = 2, "chain mid dist");
   Check (Distance (G, 5, 1) = Infinity, "chain reverse unreachable");
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Length);
   Check (Ok and then Length = 5, "chain path length 5");
   Check (Path (1) = 1 and then Path (2) = 2 and then Path (3) = 3
            and then Path (4) = 4 and then Path (5) = 5,
          "chain path vertices");

   ------------------------------------------------------------------
   Section ("4. Prepend / neighbour order");
   ------------------------------------------------------------------
   --  Edges prepended: last Add_Edge is explored first among neighbours.
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 1, 4);
   BFS (G, 1, Order, Count);
   Check (Count = 4, "star visits 4");
   Check (Order (1) = 1, "star root first");
   Check (Order (2) = 4 and then Order (3) = 3 and then Order (4) = 2,
          "star prepend order 4,3,2");

   ------------------------------------------------------------------
   Section ("5. Diamond / shortcuts (shortest path)");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Check (Distance (G, 1, 4) = 2, "diamond dist 2");
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (2) = 1 and then Dist (3) = 1 and then Dist (4) = 2,
          "diamond distances");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Length);
   Check (Ok and then Length = 3, "diamond path len 3");
   Check (Path (1) = 1 and then Path (3) = 4, "diamond path ends");

   --  Shortcut makes shallowest path length 1.
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 1, 4);
   Check (Distance (G, 1, 4) = 1, "shortcut dist 1");
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Length);
   Check (Ok and then Length = 2
            and then Path (1) = 1 and then Path (2) = 4,
          "shortcut path direct");

   ------------------------------------------------------------------
   Section ("6. Disconnected / unreachable");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   BFS (G, 1, Order, Count);
   Check (Count = 3, "comp1 size 3");
   Check (not In_Order (Order, Count, 4), "4 not from 1");
   Check (not In_Order (Order, Count, 6), "6 isolated not from 1");
   Check (Distance (G, 1, 4) = Infinity, "cross-comp Infinity");
   Check (not Reachable (G, 1, 6), "isolated unreachable");
   BFS (G, 4, Order, Count);
   Check (Count = 2, "comp2 size 2");
   BFS (G, 6, Order, Count);
   Check (Count = 1, "isolated alone");
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Length);
   Check (not Ok and then Length = 0, "recon fails unreachable");

   ------------------------------------------------------------------
   Section ("7. Cycles");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 2);
   Check (Distance (G, 1, 4) = 3, "cycle reach 4");
   Check (Distance (G, 2, 4) = 2, "from 2 to 4");
   BFS (G, 1, Order, Count);
   Check (Count = 4, "cycle visits all once");
   declare
      Seen : array (Vertex_Id range 1 .. 4) of Boolean := [others => False];
      Dup  : Boolean := False;
   begin
      for I in 1 .. Count loop
         if Seen (Order (I)) then
            Dup := True;
         end if;
         Seen (Order (I)) := True;
      end loop;
      Check (not Dup, "no duplicate visits in cycle");
   end;

   ------------------------------------------------------------------
   Section ("8. Complete digraph K3 / K4");
   ------------------------------------------------------------------
   Clear (G, 3);
   for U in Vertex_Id range 1 .. 3 loop
      for V in Vertex_Id range 1 .. 3 loop
         if U /= V then
            Add_Edge (G, U, V);
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 6, "K3 has 6 arcs");
   for U in Vertex_Id range 1 .. 3 loop
      for V in Vertex_Id range 1 .. 3 loop
         if U = V then
            Check (Distance (G, U, V) = 0, "K3 self");
         else
            Check (Distance (G, U, V) = 1, "K3 edge dist 1");
         end if;
      end loop;
   end loop;

   Clear (G, 4);
   for U in Vertex_Id range 1 .. 4 loop
      for V in Vertex_Id range 1 .. 4 loop
         if U /= V then
            Add_Edge (G, U, V);
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 12, "K4 has 12 arcs");
   Check (Distance (G, 1, 4) = 1, "K4 dist 1");
   BFS (G, 1, Order, Count);
   Check (Count = 4, "K4 BFS all");

   ------------------------------------------------------------------
   Section ("9. Undirected via two edges");
   ------------------------------------------------------------------
   Clear (G, 5);
   --  Path graph 1-2-3-4-5 undirected
   for V in Vertex_Id range 1 .. 4 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
      Add_Edge (G, Vertex_Id (Natural (V) + 1), V);
   end loop;
   Check (Edge_Count (G) = 8, "undirected path 8 directed");
   Check (Distance (G, 1, 5) = 4, "undirected ends dist 4");
   Check (Distance (G, 5, 1) = 4, "undirected reverse");
   Check (Distance (G, 2, 4) = 2, "undirected mid");
   Shortest_Paths (G, 3, Dist, Prev);
   Check (Dist (1) = 2 and then Dist (5) = 2, "from center");

   ------------------------------------------------------------------
   Section ("10. Stars / wide frontier");
   ------------------------------------------------------------------
   Clear (G, 21);
   for V in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, V);
   end loop;
   BFS (G, 1, Order, Count);
   Check (Count = 21, "star 20 leaves");
   Check (Order (1) = 1, "star hub first");
   for V in Vertex_Id range 2 .. 21 loop
      Check (Distance (G, 1, V) = 1, "star leaf dist" & Vertex_Id'Image (V));
   end loop;
   Check (Distance (G, 2, 3) = Infinity, "leaves not linked");

   ------------------------------------------------------------------
   Section ("11. Binary tree levels");
   ------------------------------------------------------------------
   --  1 -> 2,3; 2 -> 4,5; 3 -> 6,7
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 3, 7);
   BFS (G, 1, Order, Count);
   Check (Count = 7, "tree all");
   Check (Order_Index (Order, Count, 1) = 1, "level0");
   Check (Order_Index (Order, Count, 2) <= 3
            and then Order_Index (Order, Count, 3) <= 3,
          "level1 before deeper");
   Check (Order_Index (Order, Count, 4) > Order_Index (Order, Count, 2),
          "child after parent 2");
   for V in Vertex_Id range 4 .. 7 loop
      Check (Distance (G, 1, V) = 2, "tree depth 2 leaf");
   end loop;

   ------------------------------------------------------------------
   Section ("12. Grid DAG 3x3");
   ------------------------------------------------------------------
   --  Vertices 1..9 row-major; edges right and down.
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
   Check (Distance (G, 1, 9) = 4, "grid corner dist 4");
   Check (Distance (G, 1, 5) = 2, "grid center");
   Check (Distance (G, 9, 1) = Infinity, "grid no reverse");
   BFS (G, 1, Order, Count);
   Check (Count = 9, "grid all reachable from 1");

   ------------------------------------------------------------------
   Section ("13. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Check (Edge_Count (G) = 3, "parallels counted");
   Check (Distance (G, 1, 3) = 2, "parallels same dist");
   BFS (G, 1, Order, Count);
   Check (Count = 3, "parallels visit once each");

   ------------------------------------------------------------------
   Section ("14. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Clear (G, 4);
   Check (Vertex_Count (G) = 4, "rebuild N");
   Check (Edge_Count (G) = 0, "rebuild cleared edges");
   Add_Edge (G, 4, 1);
   Check (Distance (G, 4, 1) = 1, "rebuild edge works");
   Check (Distance (G, 1, 4) = Infinity, "old edges gone");

   ------------------------------------------------------------------
   Section ("15. Long chains");
   ------------------------------------------------------------------
   Clear (G, 30);
   for V in Vertex_Id range 1 .. 29 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
   end loop;
   Check (Distance (G, 1, 30) = 29, "chain30 dist");
   BFS (G, 1, Order, Count);
   Check (Count = 30, "chain30 all");
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 30, Path, Length);
   Check (Ok and then Length = 30, "chain30 path");

   Clear (G, 50);
   for V in Vertex_Id range 1 .. 49 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
   end loop;
   Check (Distance (G, 1, 50) = 49, "chain50 dist");
   Check (Distance (G, 25, 50) = 25, "chain50 mid");
   BFS (G, 10, Order, Count);
   Check (Count = 41, "chain50 from 10");

   ------------------------------------------------------------------
   Section ("16. IDDFS oracle distances on small digraphs");
   ------------------------------------------------------------------
   declare
      E1 : constant Edge_List :=
        [(1, 2), (2, 3), (3, 4), (1, 4)];
      E2 : constant Edge_List :=
        [(1, 2), (1, 3), (2, 4), (3, 4), (4, 5)];
      E3 : constant Edge_List :=
        [(1, 2), (2, 1), (2, 3), (3, 4)];
   begin
      Clear (G, 4);
      for I in E1'Range loop
         Add_Edge (G, E1 (I).From, E1 (I).To);
      end loop;
      Check (Distance (G, 1, 4) = Oracle_Dist_Edges (E1, 4, 1, 4),
             "oracle shortcut");
      Check (Distance (G, 1, 3) = Oracle_Dist_Edges (E1, 4, 1, 3),
             "oracle 1->3");
      Check (Distance (G, 2, 4) = Oracle_Dist_Edges (E1, 4, 2, 4),
             "oracle 2->4");

      Clear (G, 5);
      for I in E2'Range loop
         Add_Edge (G, E2 (I).From, E2 (I).To);
      end loop;
      for S in Vertex_Id range 1 .. 5 loop
         for T in Vertex_Id range 1 .. 5 loop
            D := Oracle_Dist_Edges (E2, 5, S, T);
            Check (Distance (G, S, T) = D,
                   "oracle E2" & Vertex_Id'Image (S) & "->"
                   & Vertex_Id'Image (T));
         end loop;
      end loop;

      Clear (G, 4);
      for I in E3'Range loop
         Add_Edge (G, E3 (I).From, E3 (I).To);
      end loop;
      Check (Distance (G, 1, 4) = Oracle_Dist_Edges (E3, 4, 1, 4),
             "oracle with 2-cycle");
      Check (Distance (G, 3, 1) = Oracle_Dist_Edges (E3, 4, 3, 1),
             "oracle unreachable matches");
   end;

   ------------------------------------------------------------------
   Section ("17. Level-order monotonic distances");
   ------------------------------------------------------------------
   Clear (G, 8);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 5, 7);
   Add_Edge (G, 6, 8);
   BFS (G, 1, Order, Count);
   Shortest_Paths (G, 1, Dist, Prev);
   declare
      Nondec : Boolean := True;
   begin
      for I in 1 .. Count - 1 loop
         if Dist (Order (I + 1)) < Dist (Order (I)) then
            Nondec := False;
         end if;
      end loop;
      Check (Nondec, "BFS order nondecreasing Dist");
   end;
   Check (Dist (Order (Count)) >= Dist (Order (1)), "last >= first dist");

   ------------------------------------------------------------------
   Section ("18. Path reconstruction properties");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 3);
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 3, Path, Length);
   Check (Ok, "recon 1->3 ok");
   Check (Length = Dist (3) + 1, "path verts = dist+1");
   Check (Path (1) = 1 and then Path (Length) = 3, "path ends");
   --  Consecutive Path edges must exist as Prev links
   declare
      Good : Boolean := True;
   begin
      for I in 2 .. Length loop
         if Prev (Path (I)) /= Natural (Path (I - 1)) then
            Good := False;
         end if;
      end loop;
      Check (Good, "path follows Prev");
   end;

   ------------------------------------------------------------------
   Section ("19. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow N");
   Clear (G, 3);
   Check (Add_Raises (G, 1, 4), "Add To out of range");
   Check (Add_Raises (G, 4, 1), "Add From out of range");
   Check (BFS_Raises (G, 1, 2, 10), "BFS Order First/=1");
   Check (BFS_Raises (G, 1, 1, 2), "BFS Order too short");
   Check (BFS_Raises (G, 4, 1, 10), "BFS Start out of range");
   Check (SP_Raises (G, 1, 2, 3), "SP Dist too short");
   Check (SP_Raises (G, 1, 3, 2), "SP Prev too short");
   Check (SP_Raises (G, 5, 3, 3), "SP Start OOR");
   Check (Dist_Raises (G, 1, 5), "Distance Target OOR");
   Check (Dist_Raises (G, 5, 1), "Distance Start OOR");
   Check (Reach_Raises (G, 1, 5), "Reachable Target OOR");
   Clear (G, 0);
   Check (Dist_Raises (G, 1, 1), "Distance on empty");
   Check (Reach_Raises (G, 1, 1), "Reachable on empty");
   Check (SP_Raises (G, 1, 1, 1), "SP on empty");

   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Recon_Raises (Prev, 1, 2, 2, 10), "Recon Path First/=1");
   Check (Recon_Raises (Prev, 1, 2, 1, 1), "Recon Path too short");

   ------------------------------------------------------------------
   Section ("20. Infinity sentinel / Max capacities smoke");
   ------------------------------------------------------------------
   Check (Nat (Infinity) > Nat (1_000_000), "Infinity large sentinel");
   Clear (G, 2);
   Check (Distance (G, 1, 2) = Infinity, "no edge => Infinity");
   Check (Nat (Max_Vertices) = 1_000, "Max_Vertices");
   Check (Nat (Max_Edges) = 100_000, "Max_Edges");

   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Clear at max N");
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 1, "edge at max N graph");
   Check (Distance (G, 1, 2) = 1, "dist at max N graph");
   Check (Distance (G, 1, Vertex_Id (Max_Vertices)) = Infinity,
          "far vertex Infinity");

   ------------------------------------------------------------------
   Section ("21. BFS vs Shortest_Paths agreement");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 6);
   Add_Edge (G, 3, 7);
   BFS (G, 1, Order, Count);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Count >= 1, "agree nonempty");
   for I in 1 .. Count loop
      Check (Dist (Order (I)) /= Infinity,
             "visited has finite dist" & Vertex_Id'Image (Order (I)));
      Check (Reachable (G, 1, Order (I)),
             "visited reachable" & Vertex_Id'Image (Order (I)));
   end loop;
   for V in Vertex_Id range 1 .. 7 loop
      if Dist (V) = Infinity then
         Check (not In_Order (Order, Count, V),
                "unreach not in order" & Vertex_Id'Image (V));
      else
         Check (In_Order (Order, Count, V),
                "reach in order" & Vertex_Id'Image (V));
         Check (Distance (G, 1, V) = Dist (V),
                "Distance fn matches" & Vertex_Id'Image (V));
      end if;
   end loop;

   ------------------------------------------------------------------
   Section ("22. More IDDFS oracle matrices");
   ------------------------------------------------------------------
   declare
      E4 : constant Edge_List :=
        [(1, 2), (2, 3), (3, 1), (3, 4), (4, 5), (5, 3)];
   begin
      Clear (G, 5);
      for I in E4'Range loop
         Add_Edge (G, E4 (I).From, E4 (I).To);
      end loop;
      for S in Vertex_Id range 1 .. 5 loop
         for T in Vertex_Id range 1 .. 5 loop
            D := Oracle_Dist_Edges (E4, 5, S, T);
            Check (Distance (G, S, T) = D,
                   "oracle E4" & Vertex_Id'Image (S) & "->"
                   & Vertex_Id'Image (T));
         end loop;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("23. Forest-like multi-component sweep");
   ------------------------------------------------------------------
   Clear (G, 9);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 7, 8);
   Add_Edge (G, 8, 9);
   declare
      Total : Natural := 0;
   begin
      for S in Vertex_Id range 1 .. 9 loop
         BFS (G, S, Order, Count);
         Total := Total + Count;
         Check (Count >= 1, "each start visits self");
         Check (Order (1) = S, "start is first");
      end loop;
      --  sizes: from1=3,2=2,3=1,4=2,5=1,6=1,7=3,8=2,9=1 => 16
      Check (Total = 16, "sum reachable sizes = 16");
   end;

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
