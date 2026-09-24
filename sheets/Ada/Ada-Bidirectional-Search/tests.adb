--  Standalone test suite for Bidirectional_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bidirectional_Search; use Bidirectional_Search;

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

   function SP_Raises
     (G : Graph; Start, Goal : Vertex_Id; First, Last : Positive)
      return Boolean
   is
      Path   : Order_Array (First .. Last);
      Length : Natural;
      Ok     : Boolean;
   begin
      Ok := Shortest_Path (G, Start, Goal, Path, Length);
      pragma Unreferenced (Ok, Length);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end SP_Raises;

   function Dist_Raises
     (G : Graph; Start, Goal : Vertex_Id) return Boolean
   is
      D : Natural;
   begin
      D := Distance (G, Start, Goal);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Raises;

   function BFS_Raises
     (G : Graph; Start, Goal : Vertex_Id) return Boolean
   is
      D : Natural;
   begin
      D := BFS_Distance (G, Start, Goal);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end BFS_Raises;

   function Reach_Raises
     (G : Graph; Start, Goal : Vertex_Id) return Boolean
   is
      R : Boolean;
   begin
      R := Reachable (G, Start, Goal);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reach_Raises;

   function Path_Edges_Exist
     (G : Graph; Path : Order_Array; Length : Natural) return Boolean
   is
   begin
      if Length < 1 then
         return False;
      end if;
      --  Successive distances from Path(1) must increase by exactly 1
      --  (unit-cost shortest-path property along the reconstructed path).
      for I in 1 .. Length - 1 loop
         if BFS_Distance (G, Path (1), Path (I + 1))
           /= BFS_Distance (G, Path (1), Path (I)) + 1
         then
            return False;
         end if;
      end loop;
      return True;
   end Path_Edges_Exist;

   type Edge_Rec is record
      From, To : Vertex_Id := Vertex_Id'First;
   end record;
   type Edge_List is array (Positive range <>) of Edge_Rec;

   G      : Graph;
   Path   : Order_Array (1 .. Max_Vertices);
   Length : Natural;
   Ok     : Boolean;
   D      : Natural;
   Db     : Natural;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty N=0");
   Check (Edge_Count (G) = 0, "empty E=0");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single N=1");
   Check (Edge_Count (G) = 0, "single E=0");
   Check (Distance (G, 1, 1) = 0, "Distance self=0");
   Check (BFS_Distance (G, 1, 1) = 0, "BFS_Distance self=0");
   Check (Reachable (G, 1, 1), "Reachable self");
   Ok := Shortest_Path (G, 1, 1, Path, Length);
   Check (Ok and then Length = 1 and then Path (1) = 1, "SP self");

   Add_Edge (G, 1, 1);
   Check (Edge_Count (G) = 1, "self-loop edge");
   Check (Distance (G, 1, 1) = 0, "self-loop Distance 0");
   Check (BFS_Distance (G, 1, 1) = 0, "self-loop BFS 0");

   ------------------------------------------------------------------
   Section ("2. Two vertices / arcs / 2-cycle");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2);
   Check (Distance (G, 1, 2) = 1, "1->2 dist 1");
   Check (BFS_Distance (G, 1, 2) = 1, "1->2 BFS 1");
   Check (Distance (G, 2, 1) = Infinity, "2 cannot reach 1");
   Check (BFS_Distance (G, 2, 1) = Infinity, "2 BFS cannot reach 1");
   Check (not Reachable (G, 2, 1), "2 not reach 1");
   Check (Reachable (G, 1, 2), "1 reaches 2");
   Ok := Shortest_Path (G, 1, 2, Path, Length);
   Check (Ok and then Length = 2
            and then Path (1) = 1 and then Path (2) = 2, "SP 1->2");
   Ok := Shortest_Path (G, 2, 1, Path, Length);
   Check (not Ok and then Length = 0, "SP 2->1 fails");

   Add_Edge (G, 2, 1);
   Check (Distance (G, 1, 2) = 1, "2-cycle 1->2");
   Check (Distance (G, 2, 1) = 1, "2-cycle 2->1");
   Check (BFS_Distance (G, 2, 1) = 1, "2-cycle BFS 2->1");
   Ok := Shortest_Path (G, 2, 1, Path, Length);
   Check (Ok and then Length = 2
            and then Path (1) = 2 and then Path (2) = 1, "SP 2->1");

   ------------------------------------------------------------------
   Section ("3. Directed chains");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 5);
   for V in Vertex_Id range 1 .. 5 loop
      Check (Distance (G, 1, V) = Natural (V) - 1,
             "chain dist to" & Vertex_Id'Image (V));
      Check (BFS_Distance (G, 1, V) = Natural (V) - 1,
             "chain BFS to" & Vertex_Id'Image (V));
   end loop;
   Check (Distance (G, 3, 5) = 2, "chain mid dist");
   Check (Distance (G, 5, 1) = Infinity, "chain reverse unreachable");
   Ok := Shortest_Path (G, 1, 5, Path, Length);
   Check (Ok and then Length = 5, "chain path length 5");
   Check (Path (1) = 1 and then Path (2) = 2 and then Path (3) = 3
            and then Path (4) = 4 and then Path (5) = 5, "chain path verts");
   Check (Path_Edges_Exist (G, Path, Length), "chain path successive");

   ------------------------------------------------------------------
   Section ("4. Diamond / shortcuts (shortest path)");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 3, 4);
   Check (Distance (G, 1, 4) = 2, "diamond dist 2");
   Check (BFS_Distance (G, 1, 4) = 2, "diamond BFS 2");
   Ok := Shortest_Path (G, 1, 4, Path, Length);
   Check (Ok and then Length = 3, "diamond path len 3");
   Check (Path (1) = 1 and then Path (3) = 4, "diamond path ends");
   Check (Path_Edges_Exist (G, Path, Length), "diamond successive");

   Add_Edge (G, 1, 4);
   Check (Distance (G, 1, 4) = 1, "shortcut dist 1");
   Check (BFS_Distance (G, 1, 4) = 1, "shortcut BFS 1");
   Ok := Shortest_Path (G, 1, 4, Path, Length);
   Check (Ok and then Length = 2
            and then Path (1) = 1 and then Path (2) = 4, "shortcut path");

   ------------------------------------------------------------------
   Section ("5. Disconnected / unreachable");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   Check (Distance (G, 1, 4) = Infinity, "cross-comp Infinity");
   Check (BFS_Distance (G, 1, 4) = Infinity, "cross-comp BFS Infinity");
   Check (not Reachable (G, 1, 6), "isolated unreachable");
   Check (Distance (G, 6, 6) = 0, "isolated self");
   Ok := Shortest_Path (G, 1, 5, Path, Length);
   Check (not Ok and then Length = 0, "SP fails unreachable");
   Ok := Shortest_Path (G, 4, 5, Path, Length);
   Check (Ok and then Length = 2, "SP within component");

   ------------------------------------------------------------------
   Section ("6. Cycles");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   Add_Edge (G, 4, 1);
   Check (Distance (G, 1, 4) = 3, "cycle reach 4");
   Check (Distance (G, 2, 4) = 2, "from 2 to 4");
   Check (BFS_Distance (G, 1, 4) = 3, "cycle BFS 4");
   for S in Vertex_Id range 1 .. 4 loop
      for T in Vertex_Id range 1 .. 4 loop
         D := Distance (G, S, T);
         Db := BFS_Distance (G, S, T);
         Check (D = Db, "cycle agree" & Vertex_Id'Image (S)
                & "->" & Vertex_Id'Image (T));
      end loop;
   end loop;

   ------------------------------------------------------------------
   Section ("7. Complete digraph K3 / K4");
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
            Check (BFS_Distance (G, U, V) = 1, "K3 BFS 1");
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
   Check (BFS_Distance (G, 1, 4) = 1, "K4 BFS 1");

   ------------------------------------------------------------------
   Section ("8. Undirected via two edges");
   ------------------------------------------------------------------
   Clear (G, 5);
   for V in Vertex_Id range 1 .. 4 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
      Add_Edge (G, Vertex_Id (Natural (V) + 1), V);
   end loop;
   Check (Edge_Count (G) = 8, "undirected path 8 directed");
   Check (Distance (G, 1, 5) = 4, "undirected ends dist 4");
   Check (Distance (G, 5, 1) = 4, "undirected reverse");
   Check (BFS_Distance (G, 5, 1) = 4, "undirected BFS reverse");
   Check (Distance (G, 2, 4) = 2, "undirected mid");
   Ok := Shortest_Path (G, 5, 1, Path, Length);
   Check (Ok and then Length = 5, "undirected SP len");
   Check (Path (1) = 5 and then Path (5) = 1, "undirected SP ends");

   ------------------------------------------------------------------
   Section ("9. Stars / wide frontier");
   ------------------------------------------------------------------
   Clear (G, 21);
   for V in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, V);
   end loop;
   for V in Vertex_Id range 2 .. 21 loop
      Check (Distance (G, 1, V) = 1, "star leaf dist" & Vertex_Id'Image (V));
      Check (BFS_Distance (G, 1, V) = 1, "star BFS" & Vertex_Id'Image (V));
   end loop;
   Check (Distance (G, 2, 3) = Infinity, "leaves not linked");
   Ok := Shortest_Path (G, 1, 21, Path, Length);
   Check (Ok and then Length = 2, "star SP");

   ------------------------------------------------------------------
   Section ("10. Binary tree levels");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 3);
   Add_Edge (G, 2, 4);
   Add_Edge (G, 2, 5);
   Add_Edge (G, 3, 6);
   Add_Edge (G, 3, 7);
   for V in Vertex_Id range 4 .. 7 loop
      Check (Distance (G, 1, V) = 2, "tree depth 2 leaf");
      Check (BFS_Distance (G, 1, V) = 2, "tree BFS leaf");
   end loop;
   Ok := Shortest_Path (G, 1, 7, Path, Length);
   Check (Ok and then Length = 3, "tree SP len 3");
   Check (Path (1) = 1 and then Path (3) = 7, "tree SP ends");

   ------------------------------------------------------------------
   Section ("11. Grid DAG 3x3");
   ------------------------------------------------------------------
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
   Check (BFS_Distance (G, 1, 9) = 4, "grid BFS 4");
   Check (Distance (G, 1, 5) = 2, "grid center");
   Check (Distance (G, 9, 1) = Infinity, "grid no reverse");
   Ok := Shortest_Path (G, 1, 9, Path, Length);
   Check (Ok and then Length = 5, "grid SP len 5");
   Check (Path_Edges_Exist (G, Path, Length), "grid successive");

   ------------------------------------------------------------------
   Section ("12. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Check (Edge_Count (G) = 3, "parallels counted");
   Check (Distance (G, 1, 3) = 2, "parallels same dist");
   Check (BFS_Distance (G, 1, 3) = 2, "parallels BFS");

   ------------------------------------------------------------------
   Section ("13. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2);
   Clear (G, 4);
   Check (Vertex_Count (G) = 4, "rebuild N");
   Check (Edge_Count (G) = 0, "rebuild cleared edges");
   Add_Edge (G, 4, 1);
   Check (Distance (G, 4, 1) = 1, "rebuild edge works");
   Check (Distance (G, 1, 4) = Infinity, "old edges gone");
   Check (BFS_Distance (G, 4, 1) = 1, "rebuild BFS");

   ------------------------------------------------------------------
   Section ("14. Long chains");
   ------------------------------------------------------------------
   Clear (G, 30);
   for V in Vertex_Id range 1 .. 29 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
   end loop;
   Check (Distance (G, 1, 30) = 29, "chain30 dist");
   Check (BFS_Distance (G, 1, 30) = 29, "chain30 BFS");
   Ok := Shortest_Path (G, 1, 30, Path, Length);
   Check (Ok and then Length = 30, "chain30 path");
   Check (Path (1) = 1 and then Path (30) = 30, "chain30 ends");

   Clear (G, 50);
   for V in Vertex_Id range 1 .. 49 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
   end loop;
   Check (Distance (G, 1, 50) = 49, "chain50 dist");
   Check (BFS_Distance (G, 1, 50) = 49, "chain50 BFS");
   Check (Distance (G, 25, 50) = 25, "chain50 mid");
   Check (BFS_Distance (G, 25, 50) = 25, "chain50 mid BFS");
   Ok := Shortest_Path (G, 10, 40, Path, Length);
   Check (Ok and then Length = 31, "chain50 mid SP");

   ------------------------------------------------------------------
   Section ("15. BFS_Distance oracle matrices");
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
      for S in Vertex_Id range 1 .. 4 loop
         for T in Vertex_Id range 1 .. 4 loop
            D := Distance (G, S, T);
            Db := BFS_Distance (G, S, T);
            Check (D = Db, "oracle E1" & Vertex_Id'Image (S)
                   & "->" & Vertex_Id'Image (T));
         end loop;
      end loop;

      Clear (G, 5);
      for I in E2'Range loop
         Add_Edge (G, E2 (I).From, E2 (I).To);
      end loop;
      for S in Vertex_Id range 1 .. 5 loop
         for T in Vertex_Id range 1 .. 5 loop
            D := Distance (G, S, T);
            Db := BFS_Distance (G, S, T);
            Check (D = Db, "oracle E2" & Vertex_Id'Image (S)
                   & "->" & Vertex_Id'Image (T));
         end loop;
      end loop;

      Clear (G, 4);
      for I in E3'Range loop
         Add_Edge (G, E3 (I).From, E3 (I).To);
      end loop;
      for S in Vertex_Id range 1 .. 4 loop
         for T in Vertex_Id range 1 .. 4 loop
            Check (Distance (G, S, T) = BFS_Distance (G, S, T),
                   "oracle E3" & Vertex_Id'Image (S)
                   & "->" & Vertex_Id'Image (T));
         end loop;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("16. Path reconstruction properties");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 1, 4);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 5, 3);
   Ok := Shortest_Path (G, 1, 3, Path, Length);
   Check (Ok, "recon 1->3 ok");
   Check (Length = Distance (G, 1, 3) + 1, "path verts = dist+1");
   Check (Path (1) = 1 and then Path (Length) = 3, "path ends");
   Check (Path_Edges_Exist (G, Path, Length), "path successive dists");
   Check (Length = 3, "shortest via 1-2-3 or equal");

   ------------------------------------------------------------------
   Section ("17. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow N");
   Clear (G, 3);
   Check (Add_Raises (G, 1, 4), "Add To out of range");
   Check (Add_Raises (G, 4, 1), "Add From out of range");
   Check (SP_Raises (G, 1, 2, 2, 10), "SP Path First/=1");
   Check (SP_Raises (G, 1, 2, 1, 2), "SP Path too short");
   Check (SP_Raises (G, 4, 1, 1, 10), "SP Start OOR");
   Check (SP_Raises (G, 1, 4, 1, 10), "SP Goal OOR");
   Check (Dist_Raises (G, 1, 5), "Distance Goal OOR");
   Check (Dist_Raises (G, 5, 1), "Distance Start OOR");
   Check (BFS_Raises (G, 1, 5), "BFS_Distance Goal OOR");
   Check (BFS_Raises (G, 5, 1), "BFS_Distance Start OOR");
   Check (Reach_Raises (G, 1, 5), "Reachable Goal OOR");
   Clear (G, 0);
   Check (Dist_Raises (G, 1, 1), "Distance on empty");
   Check (BFS_Raises (G, 1, 1), "BFS_Distance on empty");
   Check (Reach_Raises (G, 1, 1), "Reachable on empty");
   Check (SP_Raises (G, 1, 1, 1, 1), "SP on empty");

   ------------------------------------------------------------------
   Section ("18. Infinity sentinel / Max capacities smoke");
   ------------------------------------------------------------------
   Check (Nat (Infinity) > Nat (1_000_000), "Infinity large sentinel");
   Clear (G, 2);
   Check (Distance (G, 1, 2) = Infinity, "no edge => Infinity");
   Check (BFS_Distance (G, 1, 2) = Infinity, "no edge BFS Infinity");
   Check (Nat (Max_Vertices) = 1_000, "Max_Vertices");
   Check (Nat (Max_Edges) = 100_000, "Max_Edges");

   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Clear at max N");
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 1, "edge at max N graph");
   Check (Distance (G, 1, 2) = 1, "dist at max N graph");
   Check (BFS_Distance (G, 1, 2) = 1, "BFS at max N graph");
   Check (Distance (G, 1, Vertex_Id (Max_Vertices)) = Infinity,
          "far vertex Infinity");

   ------------------------------------------------------------------
   Section ("19. More oracle cycle digraph");
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
            D := Distance (G, S, T);
            Db := BFS_Distance (G, S, T);
            Check (D = Db, "oracle E4" & Vertex_Id'Image (S)
                   & "->" & Vertex_Id'Image (T));
            if D /= Infinity then
               Ok := Shortest_Path (G, S, T, Path, Length);
               Check (Ok and then Length = D + 1,
                      "SP len E4" & Vertex_Id'Image (S)
                      & "->" & Vertex_Id'Image (T));
               Check (Path (1) = S and then Path (Length) = T,
                      "SP ends E4" & Vertex_Id'Image (S)
                      & "->" & Vertex_Id'Image (T));
            end if;
         end loop;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("20. Meeting in the middle (balanced chain)");
   ------------------------------------------------------------------
   Clear (G, 9);
   for V in Vertex_Id range 1 .. 8 loop
      Add_Edge (G, V, Vertex_Id (Natural (V) + 1));
   end loop;
   Check (Distance (G, 1, 9) = 8, "meet chain dist 8");
   Check (BFS_Distance (G, 1, 9) = 8, "meet chain BFS 8");
   Ok := Shortest_Path (G, 1, 9, Path, Length);
   Check (Ok and then Length = 9, "meet chain SP");
   for I in 1 .. 9 loop
      Check (Path (I) = Vertex_Id (I), "meet chain vert" & Integer'Image (I));
   end loop;

   ------------------------------------------------------------------
   Section ("21. Directed asymmetry (forward vs reverse)");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);
   --  No reverse arcs: backward search uses reverse adj of the digraph.
   Check (Distance (G, 1, 4) = 3, "asym forward");
   Check (Distance (G, 4, 1) = Infinity, "asym reverse unreachable");
   Check (BFS_Distance (G, 4, 1) = Infinity, "asym BFS reverse");
   Ok := Shortest_Path (G, 4, 1, Path, Length);
   Check (not Ok, "asym SP fails");

   ------------------------------------------------------------------
   Section ("22. Multi-component sweep vs BFS oracle");
   ------------------------------------------------------------------
   Clear (G, 9);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 4, 5);
   Add_Edge (G, 7, 8);
   Add_Edge (G, 8, 9);
   declare
      Reachable_Pairs : Natural := 0;
   begin
      for S in Vertex_Id range 1 .. 9 loop
         for T in Vertex_Id range 1 .. 9 loop
            D := Distance (G, S, T);
            Db := BFS_Distance (G, S, T);
            Check (D = Db, "sweep" & Vertex_Id'Image (S)
                   & "->" & Vertex_Id'Image (T));
            if D /= Infinity then
               Reachable_Pairs := Reachable_Pairs + 1;
               Check (Reachable (G, S, T), "reachable flag");
            else
               Check (not Reachable (G, S, T), "unreachable flag");
            end if;
         end loop;
      end loop;
      --  Directed comps: chain3=6, chain2=3, iso=1, chain3=6 → 16
      Check (Reachable_Pairs = 16, "reachable pair count 16");
   end;

   ------------------------------------------------------------------
   Section ("23. Wide then deep (branching intuition)");
   ------------------------------------------------------------------
   --  Hub 1 → leaves 2..6; each leaf → 7 (goal-ish sink via 7→8)
   Clear (G, 8);
   for V in Vertex_Id range 2 .. 6 loop
      Add_Edge (G, 1, V);
      Add_Edge (G, V, 7);
   end loop;
   Add_Edge (G, 7, 8);
   Check (Distance (G, 1, 8) = 3, "wide-deep dist 3");
   Check (BFS_Distance (G, 1, 8) = 3, "wide-deep BFS 3");
   Ok := Shortest_Path (G, 1, 8, Path, Length);
   Check (Ok and then Length = 4, "wide-deep SP");
   Check (Path (1) = 1 and then Path (4) = 8, "wide-deep ends");
   Check (Path (3) = 7, "wide-deep through 7");

   ------------------------------------------------------------------
   Section ("24. Self-loop does not create phantom shortcuts");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 1);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 2);
   Add_Edge (G, 2, 3);
   Check (Distance (G, 1, 3) = 2, "loops no shortcut");
   Check (BFS_Distance (G, 1, 3) = 2, "loops BFS");
   Ok := Shortest_Path (G, 1, 3, Path, Length);
   Check (Ok and then Length = 3, "loops SP");

   ------------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Natural'Image (Pass_Count) & " PASS,"
             & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
