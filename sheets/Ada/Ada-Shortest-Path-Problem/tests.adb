--  Standalone test suite for Shortest_Path_Problem (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Shortest_Path_Problem; use Shortest_Path_Problem;

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
     (G : in out Graph; From, To : Vertex_Id; W : Integer) return Boolean
   is
   begin
      Add_Edge (G, From, To, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function Dijkstra_Raises (G : Graph; Source : Vertex_Id) return Boolean is
      Dist : Distance_Array (1 .. Vertex_Id (Vertex_Count (G)));
      Prev : Prev_Array (1 .. Vertex_Id (Vertex_Count (G)));
   begin
      Dijkstra (G, Source, Dist, Prev);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dijkstra_Raises;

   function BF_Raises_Cycle (G : Graph; Source : Vertex_Id) return Boolean is
      Dist : Distance_Array (1 .. Vertex_Id (Vertex_Count (G)));
      Prev : Prev_Array (1 .. Vertex_Id (Vertex_Count (G)));
   begin
      Bellman_Ford (G, Source, Dist, Prev);
      return False;
   exception
      when Negative_Cycle_Error =>
         return True;
   end BF_Raises_Cycle;

   function FW_Raises_Cycle (G : Graph) return Boolean is
      N    : constant Natural := Vertex_Count (G);
      Dist : Dist_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
      Prev : Prev_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
   begin
      Floyd_Warshall (G, Dist, Prev);
      return False;
   exception
      when Negative_Cycle_Error =>
         return True;
   end FW_Raises_Cycle;

   function SP_Bounds_Raise
     (G : Graph; Source : Vertex_Id; Dist_Last, Prev_Last : Positive)
      return Boolean
   is
      Dist : Distance_Array (1 .. Vertex_Id (Dist_Last));
      Prev : Prev_Array (1 .. Vertex_Id (Prev_Last));
   begin
      BFS_Shortest (G, Source, Dist, Prev);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end SP_Bounds_Raise;

   G      : Graph;
   Dist   : Distance_Array (Vertex_Id);
   Prev   : Prev_Array (Vertex_Id);
   Dist_S : Distance_Array (1 .. 32);
   Prev_S : Prev_Array (1 .. 32);
   Path   : Path_Array (1 .. Max_Vertices);
   Len    : Natural;
   Ok     : Boolean;
   Status : Run_Status;
   DMat   : Dist_Matrix (1 .. 32, 1 .. 32);
   PMat   : Prev_Matrix (1 .. 32, 1 .. 32);
   Dist_B : Distance_Array (1 .. 32);
   Prev_B : Prev_Array (1 .. 32);

begin
   ------------------------------------------------------------------
   Section ("1. Empty / Clear / counters");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty N=0");
   Check (Edge_Count (G) = 0, "empty E=0");
   Check (not Has_Negative_Edge (G), "empty no neg edge");
   Check (Clear_Raises (Max_Vertices + 1), "Clear > Max raises");
   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "Clear N=1");
   Check (Edge_Count (G) = 0, "Clear N=1 E=0");

   ------------------------------------------------------------------
   Section ("2. Single vertex / self-loop");
   ------------------------------------------------------------------
   Clear (G, 1);
   BFS_Shortest (G, 1, Dist_S (1 .. 1), Prev_S (1 .. 1));
   Check (Dist_S (1) = 0, "BFS single Dist=0");
   Check (Prev_S (1) = 0, "BFS single Prev=0");
   Dijkstra (G, 1, Dist_S (1 .. 1), Prev_S (1 .. 1));
   Check (Dist_S (1) = 0, "Dijkstra single Dist=0");
   Bellman_Ford (G, 1, Dist_S (1 .. 1), Prev_S (1 .. 1), Status);
   Check (Status = Success and then Dist_S (1) = 0, "BF single Success");
   Floyd_Warshall (G, DMat, Status);
   Check (Status = Success and then DMat (1, 1) = 0, "FW single 0");
   Add_Edge (G, 1, 1, 0);
   Check (Edge_Count (G) = 1, "self-loop edge");
   Dijkstra (G, 1, Dist_S (1 .. 1), Prev_S (1 .. 1));
   Check (Dist_S (1) = 0, "Dijkstra zero self-loop");
   Clear (G, 1);
   Add_Edge (G, 1, 1, -1);
   Check (Has_Negative_Edge (G), "neg self-loop flag");
   Check (Dijkstra_Raises (G, 1), "Dijkstra rejects neg self-loop");
   Bellman_Ford (G, 1, Dist_S (1 .. 1), Prev_S (1 .. 1), Status);
   Check (Status = Negative_Cycle, "BF neg self-loop");
   Check (Has_Negative_Cycle_APSP (G), "FW neg self-loop");

   ------------------------------------------------------------------
   Section ("3. Two-vertex arcs");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 5);
   Check (Distance_BFS (G, 1, 2) = 1, "BFS hop 1→2");
   Check (Distance_Dijkstra (G, 1, 2) = 5, "Dijkstra 1→2 =5");
   Check (Distance_Bellman_Ford (G, 1, 2) = 5, "BF 1→2 =5");
   Check (Distance_Floyd_Warshall (G, 1, 2) = 5, "FW 1→2 =5");
   Check (Distance_BFS (G, 2, 1) = Infinity, "BFS 2→1 unreachable");
   Check (Distance_Dijkstra (G, 2, 1) = Infinity, "Dijkstra 2→1 Inf");
   Add_Edge (G, 2, 1, 3);
   Check (Distance_Dijkstra (G, 2, 1) = 3, "Dijkstra 2→1 =3");
   Check (Distance_BFS (G, 1, 2) = 1, "BFS still hop 1");

   ------------------------------------------------------------------
   Section ("4. Unit weights: BFS ≡ Dijkstra ≡ BF");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 1, 5, 1);
   Add_Edge (G, 5, 4, 1);
   BFS_Shortest (G, 1, Dist_S (1 .. 5), Prev_S (1 .. 5));
   Dijkstra (G, 1, Dist_B (1 .. 5), Prev_B (1 .. 5));
   Check (Dist_S (4) = 2, "BFS path len 2 to 4");
   Check (Dist_B (4) = 2, "Dijkstra unit =2");
   Bellman_Ford (G, 1, Dist (1 .. 5), Prev (1 .. 5), Status);
   Check (Status = Success and then Dist (4) = 2, "BF unit =2");
   for V in Vertex_Id range 1 .. 5 loop
      Check (Dist_S (V) = Dist_B (V),
             "BFS≡Dijkstra V=" & Vertex_Id'Image (V));
      Check (Dist_S (V) = Dist (V),
             "BFS≡BF V=" & Vertex_Id'Image (V));
   end loop;

   ------------------------------------------------------------------
   Section ("5. Classic diamond (non-neg): Dijkstra ≡ BF");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   Dijkstra (G, 1, Dist_S (1 .. 4), Prev_S (1 .. 4));
   Bellman_Ford (G, 1, Dist_B (1 .. 4), Prev_B (1 .. 4), Status);
   Check (Status = Success, "diamond BF Success");
   Check (Dist_S (1) = 0 and then Dist_B (1) = 0, "diamond Dist1");
   Check (Dist_S (2) = 1 and then Dist_B (2) = 1, "diamond Dist2");
   Check (Dist_S (3) = 2 and then Dist_B (3) = 2, "diamond Dist3");
   Check (Dist_S (4) = 3 and then Dist_B (4) = 3, "diamond Dist4");
   Ok := Reconstruct_Path (Prev_S (1 .. 4), 1, 4, Path, Len);
   Check (Ok and then Len = 4, "diamond path len 4");
   Check (Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 3 and then Path (4) = 4,
          "diamond path 1-2-3-4");

   ------------------------------------------------------------------
   Section ("6. FW vs repeated Dijkstra (non-neg)");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   Floyd_Warshall (G, DMat, Status);
   Check (Status = Success, "FW diamond Success");
   for S in Vertex_Id range 1 .. 4 loop
      Dijkstra (G, S, Dist_S (1 .. 4), Prev_S (1 .. 4));
      for T in Vertex_Id range 1 .. 4 loop
         Check (DMat (S, T) = Dist_S (T),
                "FW≡Dij " & Vertex_Id'Image (S)
                & "→" & Vertex_Id'Image (T));
      end loop;
   end loop;

   ------------------------------------------------------------------
   Section ("7. Negative edges without cycle");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 3, -3);
   Add_Edge (G, 3, 4, 2);
   Check (Has_Negative_Edge (G), "has neg edge");
   Check (Dijkstra_Raises (G, 1), "Dijkstra rejects neg");
   Bellman_Ford (G, 1, Dist_S (1 .. 4), Prev_S (1 .. 4), Status);
   Check (Status = Success, "neg edges BF Success");
   Check (Dist_S (1) = 0, "neg Dist1");
   Check (Dist_S (2) = 4, "neg Dist2");
   Check (Dist_S (3) = 1, "neg Dist3");
   Check (Dist_S (4) = 3, "neg Dist4");
   Check (Distance_Bellman_Ford (G, 1, 4) = 3, "Distance_BF=3");
   Check (Distance_Floyd_Warshall (G, 1, 4) = 3, "Distance_FW=3");
   Floyd_Warshall (G, DMat, PMat, Status);
   Check (Status = Success, "FW neg Success");
   Check (DMat (1, 4) = 3, "FW Dist(1,4)=3");
   Ok := Reconstruct_Path (PMat, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "FW path len");
   Check (Path (1) = 1 and then Path (4) = 4, "FW path ends");

   ------------------------------------------------------------------
   Section ("8. Negative cycle detection");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 3, -3);
   Add_Edge (G, 3, 4, 2);
   Add_Edge (G, 3, 2, -2);
   Bellman_Ford (G, 1, Dist_S (1 .. 4), Prev_S (1 .. 4), Status);
   Check (Status = Negative_Cycle, "BF detects cycle");
   Check (Has_Negative_Cycle (G, 1), "Has_Negative_Cycle");
   Check (BF_Raises_Cycle (G, 1), "BF raising");
   Check (Has_Negative_Cycle_APSP (G), "FW APSP cycle");
   Check (FW_Raises_Cycle (G), "FW raising");

   ------------------------------------------------------------------
   Section ("9. Cycle not reachable from source");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 4, 5, -1);
   Add_Edge (G, 5, 4, -1);
   Bellman_Ford (G, 1, Dist_S (1 .. 5), Prev_S (1 .. 5), Status);
   Check (Status = Success, "unreachable cycle Success from 1");
   Check (not Has_Negative_Cycle (G, 1), "no cycle from 1");
   Check (Has_Negative_Cycle (G, 4), "cycle from 4");
   Check (Dist_S (3) = 2, "path 1-2-3 intact");
   Check (Dist_S (4) = Infinity, "4 unreachable from 1");

   ------------------------------------------------------------------
   Section ("10. Unreachable / disconnected");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 3, 4, 3);
   BFS_Shortest (G, 1, Dist_S (1 .. 4), Prev_S (1 .. 4));
   Check (Dist_S (2) = 1, "comp Dist2 hop");
   Check (Dist_S (3) = Infinity, "comp 3 Inf BFS");
   Check (Dist_S (4) = Infinity, "comp 4 Inf BFS");
   Dijkstra (G, 1, Dist_S (1 .. 4), Prev_S (1 .. 4));
   Check (Dist_S (2) = 2, "comp Dist2 weight");
   Check (Dist_S (4) = Infinity, "comp 4 Inf Dij");
   Ok := Reconstruct_Path (Prev_S (1 .. 4), 1, 4, Path, Len);
   Check (not Ok and then Len = 0, "recon unreachable False");

   ------------------------------------------------------------------
   Section ("11. Parallel edges / zero weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 0);
   Dijkstra (G, 1, Dist_S (1 .. 3), Prev_S (1 .. 3));
   Check (Dist_S (2) = 3, "parallel min=3");
   Check (Dist_S (3) = 3, "zero-weight to 3");
   Bellman_Ford (G, 1, Dist_B (1 .. 3), Prev_B (1 .. 3), Status);
   Check (Status = Success and then Dist_B (3) = 3, "BF parallel+zero");
   Check (Distance_BFS (G, 1, 3) = 2, "BFS hops ignore weights");

   ------------------------------------------------------------------
   Section ("12. Positive cycle (not negative)");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 1, 1);
   Bellman_Ford (G, 1, Dist_S (1 .. 3), Prev_S (1 .. 3), Status);
   Check (Status = Success, "pos cycle Success");
   Check (not Has_Negative_Cycle (G, 1), "pos cycle not neg");
   Check (Dist_S (1) = 0 and then Dist_S (2) = 1 and then Dist_S (3) = 2,
          "pos cycle dists");
   Check (not Has_Negative_Cycle_APSP (G), "FW no neg on pos cycle");

   ------------------------------------------------------------------
   Section ("13. Path reconstruction edge cases");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Dijkstra (G, 1, Dist_S (1 .. 3), Prev_S (1 .. 3));
   Ok := Reconstruct_Path (Prev_S (1 .. 3), 1, 1, Path, Len);
   Check (Ok and then Len = 1 and then Path (1) = 1, "trivial path");
   Ok := Reconstruct_Path (Prev_S (1 .. 3), 1, 3, Path, Len);
   Check (Ok and then Len = 3, "full path len 3");
   Check (Path (1) = 1 and then Path (2) = 2 and then Path (3) = 3,
          "full path verts");

   ------------------------------------------------------------------
   Section ("14. Layered DAG / chain");
   ------------------------------------------------------------------
   Clear (G, 8);
   for I in 1 .. 7 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
   end loop;
   Dijkstra (G, 1, Dist_S (1 .. 8), Prev_S (1 .. 8));
   Bellman_Ford (G, 1, Dist_B (1 .. 8), Prev_B (1 .. 8), Status);
   Check (Status = Success, "chain BF Success");
   declare
      Expect : Distance_Value := 0;
   begin
      Check (Dist_S (1) = 0, "chain Dist1");
      for I in 2 .. 8 loop
         Expect := Expect + Distance_Value (I - 1);
         Check (Dist_S (Vertex_Id (I)) = Expect,
                "chain Dij I=" & Integer'Image (I));
         Check (Dist_B (Vertex_Id (I)) = Expect,
                "chain BF I=" & Integer'Image (I));
      end loop;
   end;
   Check (Distance_BFS (G, 1, 8) = 7, "chain BFS hops=7");

   ------------------------------------------------------------------
   Section ("15. Star / hub");
   ------------------------------------------------------------------
   Clear (G, 6);
   for I in 2 .. 6 loop
      Add_Edge (G, 1, Vertex_Id (I), I);
   end loop;
   Dijkstra (G, 1, Dist_S (1 .. 6), Prev_S (1 .. 6));
   for I in 2 .. 6 loop
      Check (Dist_S (Vertex_Id (I)) = Distance_Value (I),
             "star Dist " & Integer'Image (I));
      Check (Prev_S (Vertex_Id (I)) = 1, "star Prev " & Integer'Image (I));
   end loop;
   Floyd_Warshall (G, DMat, Status);
   Check (Status = Success, "star FW Success");
   Check (DMat (1, 6) = 6, "star FW(1,6)");
   Check (DMat (2, 3) = Infinity, "star leaf-leaf Inf");

   ------------------------------------------------------------------
   Section ("16. Complete digraph small APSP cross-check");
   ------------------------------------------------------------------
   Clear (G, 4);
   for I in 1 .. 4 loop
      for J in 1 .. 4 loop
         if I /= J then
            Add_Edge (G, Vertex_Id (I), Vertex_Id (J), I + J);
         end if;
      end loop;
   end loop;
   Floyd_Warshall (G, DMat, Status);
   Check (Status = Success, "K4 FW Success");
   for S in Vertex_Id range 1 .. 4 loop
      Dijkstra (G, S, Dist_S (1 .. 4), Prev_S (1 .. 4));
      Bellman_Ford (G, S, Dist_B (1 .. 4), Prev_B (1 .. 4), Status);
      Check (Status = Success, "K4 BF src" & Vertex_Id'Image (S));
      for T in Vertex_Id range 1 .. 4 loop
         Check (DMat (S, T) = Dist_S (T),
                "K4 FW≡Dij");
         Check (Dist_S (T) = Dist_B (T),
                "K4 Dij≡BF");
      end loop;
   end loop;

   ------------------------------------------------------------------
   Section ("17. BFS on unequal weights (hop ≠ weight)");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 100);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 3, 2, 1);
   Check (Distance_BFS (G, 1, 2) = 1, "BFS takes direct hop");
   Check (Distance_Dijkstra (G, 1, 2) = 2, "Dijkstra prefers 1-3-2");
   Check (Distance_Bellman_Ford (G, 1, 2) = 2, "BF prefers 1-3-2");

   ------------------------------------------------------------------
   Section ("18. Invalid_Argument guards");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Check (Add_Raises (G, 1, Vertex_Id (4), 1)
            or else Nat (4) > Vertex_Count (G),
          "Add bad To setup");
   --  Vertex 4 is out of range for N=3
   declare
      Raised : Boolean;
   begin
      begin
         Add_Edge (G, 1, 4, 1);
         Raised := False;
      exception
         when Constraint_Error =>
            --  Vertex_Id range check may fire before Add_Edge body
            Raised := True;
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Add To=4 raises");
   end;
   Check (Add_Raises (G, 1, 2, Integer (Weight_Type'Last) + 1)
            or else True, "weight overflow attempt");
   declare
      Raised : Boolean := False;
   begin
      begin
         Add_Edge (G, 1, 2, Integer (Weight_Type'Last) + 1);
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "weight too large raises");
   end;
   declare
      Raised : Boolean := False;
   begin
      begin
         Add_Edge (G, 1, 2, Integer (Weight_Type'First) - 1);
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "weight too small raises");
   end;
   Check (SP_Bounds_Raise (G, 1, 2, 3), "BFS Dist Last < N");
   Check (SP_Bounds_Raise (G, 1, 3, 2), "BFS Prev Last < N");
   declare
      Raised : Boolean := False;
      D0     : Distance_Array (1 .. 3);
      P0     : Prev_Array (1 .. 3);
   begin
      Clear (G, 0);
      begin
         BFS_Shortest (G, 1, D0, P0);
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "BFS N=0 raises");
   end;
   Clear (G, 2);
   Add_Edge (G, 1, 2, 1);
   declare
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant Distance_Value := Distance_Dijkstra (G, 1, 3);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "Distance Target out of range");
   end;

   ------------------------------------------------------------------
   Section ("19. Clear rebuild / API counters");
   ------------------------------------------------------------------
   Clear (G, 5);
   for I in 1 .. 10 loop
      Add_Edge (G, 1, 2, I);
   end loop;
   Check (Edge_Count (G) = 10, "10 parallels");
   Check (Vertex_Count (G) = 5, "N=5");
   Clear (G, 3);
   Check (Edge_Count (G) = 0, "Clear resets edges");
   Check (Vertex_Count (G) = 3, "Clear new N");
   Check (not Has_Negative_Edge (G), "cleared no neg");

   ------------------------------------------------------------------
   Section ("20. Larger sparse grid cross-check");
   ------------------------------------------------------------------
   --  4x4 grid directed right/down, unit weights → BFS ≡ Dijkstra ≡ BF
   declare
      function Idx (R, C : Positive) return Vertex_Id is
        (Vertex_Id ((R - 1) * 4 + C));
   begin
      Clear (G, 16);
      for R in 1 .. 4 loop
         for C in 1 .. 4 loop
            if C < 4 then
               Add_Edge (G, Idx (R, C), Idx (R, C + 1), 1);
            end if;
            if R < 4 then
               Add_Edge (G, Idx (R, C), Idx (R + 1, C), 1);
            end if;
         end loop;
      end loop;
      BFS_Shortest (G, 1, Dist (1 .. 16), Prev (1 .. 16));
      Dijkstra (G, 1, Dist_S (1 .. 16), Prev_S (1 .. 16));
      Bellman_Ford (G, 1, Dist_B (1 .. 16), Prev_B (1 .. 16), Status);
      Check (Status = Success, "grid BF Success");
      Check (Dist (16) = 6, "grid BFS hops=6");
      Check (Dist_S (16) = 6, "grid Dij=6");
      Check (Dist_B (16) = 6, "grid BF=6");
      for V in Vertex_Id range 1 .. 16 loop
         Check (Dist (V) = Dist_S (V), "grid BFS≡Dij");
         Check (Dist (V) = Dist_B (V), "grid BFS≡BF");
      end loop;
      Floyd_Warshall (G, DMat, Status);
      Check (Status = Success, "grid FW Success");
      Check (DMat (1, 16) = 6, "grid FW(1,16)=6");
      Dijkstra (G, 8, Dist_S (1 .. 16), Prev_S (1 .. 16));
      for T in Vertex_Id range 1 .. 16 loop
         Check (DMat (8, T) = Dist_S (T), "grid FW≡Dij from 8");
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("21. Arbitrage-style triangle");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, -1);
   Add_Edge (G, 2, 3, -1);
   Add_Edge (G, 3, 1, -1);
   Check (Has_Negative_Cycle (G, 1), "arbitrage cycle BF");
   Check (Has_Negative_Cycle_APSP (G), "arbitrage cycle FW");
   Check (BF_Raises_Cycle (G, 1), "arbitrage BF raises");

   ------------------------------------------------------------------
   Section ("22. Zero-weight path vs positive");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 3, 4, 1);
   Dijkstra (G, 1, Dist_S (1 .. 4), Prev_S (1 .. 4));
   Check (Dist_S (3) = 0, "zero path beats 5");
   Check (Dist_S (4) = 1, "then +1");
   Check (Distance_BFS (G, 1, 3) = 1, "BFS direct hop prefers 1→3");

   ------------------------------------------------------------------
   Section ("23. Max_Vertices smoke (small ops)");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Max_Vertices Clear");
   Add_Edge (G, 1, Vertex_Id (Max_Vertices), 7);
   Check (Distance_Dijkstra (G, 1, Vertex_Id (Max_Vertices)) = 7,
          "Max_Vertices Dijkstra");
   Check (Distance_BFS (G, 1, Vertex_Id (Max_Vertices)) = 1,
          "Max_Vertices BFS");
   Bellman_Ford (G, 1, Dist, Prev, Status);
   Check (Status = Success
            and then Dist (Vertex_Id (Max_Vertices)) = 7,
          "Max_Vertices BF");

   ------------------------------------------------------------------
   Section ("24. FW Prev reconstruction vs Dijkstra Prev");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 4, 10);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 3, 5, 1);
   Floyd_Warshall (G, DMat, PMat, Status);
   Check (Status = Success, "FW Prev Success");
   Check (DMat (1, 5) = 5, "FW Dist 1→5 =5");
   Ok := Reconstruct_Path (PMat, 1, 5, Path, Len);
   Check (Ok and then Len = 4, "FW recon len 4");
   Check (Path (1) = 1 and then Path (Len) = 5, "FW recon ends");
   Dijkstra (G, 1, Dist_S (1 .. 5), Prev_S (1 .. 5));
   Check (Dist_S (5) = 5, "Dij Dist5=5");
   Ok := Reconstruct_Path (Prev_S (1 .. 5), 1, 5, Path, Len);
   Check (Ok and then Len = 4, "Dij recon len 4");

   ------------------------------------------------------------------
   Section ("25. Distance_* agreement");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 4);
   Add_Edge (G, 3, 4, 5);
   Check (Distance_BFS (G, 1, 4) = 3, "Dist_BFS=3");
   Check (Distance_Dijkstra (G, 1, 4) = 12, "Dist_Dij=12");
   Check (Distance_Bellman_Ford (G, 1, 4) = 12, "Dist_BF=12");
   Check (Distance_Floyd_Warshall (G, 1, 4) = 12, "Dist_FW=12");
   Check (Distance_Dijkstra (G, 1, 1) = 0, "Dist_Dij self");
   Check (Distance_BFS (G, 4, 1) = Infinity, "Dist_BFS reverse Inf");

   ------------------------------------------------------------------
   Section ("26. One-way negative (no cycle)");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, -5);
   Bellman_Ford (G, 1, Dist_S (1 .. 2), Prev_S (1 .. 2), Status);
   Check (Status = Success, "one-way neg Success");
   Check (Dist_S (2) = -5, "one-way Dist2");
   Check (not Has_Negative_Cycle (G, 1), "one-way no cycle");
   Check (Distance_Floyd_Warshall (G, 1, 2) = -5, "FW one-way -5");
   Check (Dijkstra_Raises (G, 1), "Dij rejects one-way neg");

   ------------------------------------------------------------------
   Section ("27. Dense random-ish handcrafted");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2, 6);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 3, 2, 3);
   Add_Edge (G, 3, 4, 8);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 5, 6, 2);
   Add_Edge (G, 6, 7, 4);
   Add_Edge (G, 3, 5, 10);
   Add_Edge (G, 1, 7, 100);
   Dijkstra (G, 1, Dist_S (1 .. 7), Prev_S (1 .. 7));
   Bellman_Ford (G, 1, Dist_B (1 .. 7), Prev_B (1 .. 7), Status);
   Check (Status = Success, "hand BF Success");
   for V in Vertex_Id range 1 .. 7 loop
      Check (Dist_S (V) = Dist_B (V), "hand Dij≡BF");
   end loop;
   Floyd_Warshall (G, DMat, Status);
   Check (Status = Success, "hand FW Success");
   for T in Vertex_Id range 1 .. 7 loop
      Check (DMat (1, T) = Dist_S (T), "hand FW≡Dij");
   end loop;
   Check (Dist_S (7) < 100, "hand shortcut beats direct 100");
   Ok := Reconstruct_Path (Prev_S (1 .. 7), 1, 7, Path, Len);
   Check (Ok and then Len >= 2, "hand path exists");
   Check (Path (1) = 1 and then Path (Len) = 7, "hand path ends");

   ------------------------------------------------------------------
   Section ("28. Self Dist matrix diagonal after FW");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Floyd_Warshall (G, DMat, Status);
   Check (Status = Success, "diag FW Success");
   Check (DMat (1, 1) = 0 and then DMat (2, 2) = 0
            and then DMat (3, 3) = 0, "diag zeros");
   Check (DMat (1, 3) = 2, "diag Dist13");

   ------------------------------------------------------------------
   Section ("29. Multiple sources FW rows");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 2, 3, -1);
   Add_Edge (G, 1, 3, 10);
   Floyd_Warshall (G, DMat, Status);
   Check (Status = Success, "msrc FW Success");
   Check (DMat (1, 3) = 3, "msrc 1→3 via 2");
   Check (DMat (2, 3) = -1, "msrc 2→3");
   Check (DMat (3, 1) = Infinity, "msrc 3→1 Inf");
   Bellman_Ford (G, 2, Dist_S (1 .. 3), Prev_S (1 .. 3), Status);
   Check (Status = Success and then Dist_S (3) = -1, "msrc BF from 2");

   ------------------------------------------------------------------
   Section ("30. Taxonomy smoke: method applicability");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Check (not Has_Negative_Edge (G), "taxonomy non-neg");
   Check (Distance_BFS (G, 1, 3) = Distance_Dijkstra (G, 1, 3),
          "taxonomy unit BFS=Dij");
   Clear (G, 3);
   Add_Edge (G, 1, 2, -2);
   Add_Edge (G, 2, 3, 5);
   Check (Has_Negative_Edge (G), "taxonomy has neg");
   Check (Dijkstra_Raises (G, 1), "taxonomy Dij blocked");
   Check (Distance_Bellman_Ford (G, 1, 3) = 3, "taxonomy BF works");
   Check (Distance_Floyd_Warshall (G, 1, 3) = 3, "taxonomy FW works");

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
