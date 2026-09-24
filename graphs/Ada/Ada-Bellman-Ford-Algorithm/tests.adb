--  Standalone test suite for Bellman_Ford_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bellman_Ford_Algorithm; use Bellman_Ford_Algorithm;

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
     (G : in out Graph; From, To : Vertex_Id; W : Integer) return Boolean
   is
   begin
      Add_Edge (G, From, To, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Raises;

   function SP_Raises
     (G : Graph; Source : Vertex_Id;
      Dist_Last, Prev_Last : Positive) return Boolean
   is
      Dist   : Distance_Array (1 .. Vertex_Id (Dist_Last));
      Prev   : Prev_Array (1 .. Vertex_Id (Prev_Last));
      Status : Run_Status;
   begin
      Shortest_Paths (G, Source, Dist, Prev, Status);
      pragma Unreferenced (Status);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end SP_Raises;

   function SP_Raises_Cycle
     (G : Graph; Source : Vertex_Id) return Boolean
   is
      Dist : Distance_Array (Vertex_Id);
      Prev : Prev_Array (Vertex_Id);
   begin
      Shortest_Paths (G, Source, Dist, Prev);
      return False;
   exception
      when Negative_Cycle_Error =>
         return True;
   end SP_Raises_Cycle;

   function Dist_Raises
     (G : Graph; Source, Target : Vertex_Id) return Boolean
   is
      D : Distance_Value;
   begin
      D := Distance (G, Source, Target);
      pragma Unreferenced (D);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Dist_Raises;

   function Dist_Neg_Cycle
     (G : Graph; Source, Target : Vertex_Id) return Boolean
   is
      D : Distance_Value;
   begin
      D := Distance (G, Source, Target);
      pragma Unreferenced (D);
      return False;
   exception
      when Negative_Cycle_Error =>
         return True;
   end Dist_Neg_Cycle;

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

   function Aff_Raises
     (G : Graph; Source : Vertex_Id; Aff_Last : Positive) return Boolean
   is
      Aff   : Flag_Array (1 .. Vertex_Id (Aff_Last));
      Found : Boolean;
   begin
      Affected_By_Negative_Cycle (G, Source, Aff, Found);
      pragma Unreferenced (Found);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Aff_Raises;

   G      : Graph;
   Dist   : Distance_Array (Vertex_Id);
   Prev   : Prev_Array (Vertex_Id);
   Path   : Path_Array (1 .. Max_Vertices);
   Aff    : Flag_Array (Vertex_Id);
   Len    : Natural;
   Ok     : Boolean;
   Found  : Boolean;
   Status : Run_Status;
   D      : Distance_Value;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Check (SP_Raises (G, 1, Max_Vertices, Max_Vertices),
          "empty Shortest_Paths raises");
   Check (Dist_Raises (G, 1, 1), "empty Distance raises");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "single status Success");
   Check (Dist (1) = 0, "single Dist(1)=0");
   Check (Prev (1) = 0, "single Prev(1)=0");
   Check (Distance (G, 1, 1) = 0, "single Distance 1→1 = 0");
   Check (not Has_Negative_Cycle (G, 1), "single no neg cycle");
   Ok := Reconstruct_Path (Prev, 1, 1, Path, Len);
   Check (Ok and then Len = 1 and then Path (1) = 1, "single recon");

   Add_Edge (G, 1, 1, 5);
   Check (Edge_Count (G) = 1, "self-loop edge count");
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "pos self-loop Success");
   Check (Dist (1) = 0, "pos self-loop Dist still 0");

   Clear (G, 1);
   Add_Edge (G, 1, 1, 0);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "zero self-loop Success");
   Check (Dist (1) = 0, "zero self-loop Dist 0");

   Clear (G, 1);
   Add_Edge (G, 1, 1, -1);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Negative_Cycle, "neg self-loop cycle");
   Check (Has_Negative_Cycle (G, 1), "neg self-loop Has_Neg");
   Check (SP_Raises_Cycle (G, 1), "neg self-loop raising SP");
   Check (Dist_Neg_Cycle (G, 1, 1), "neg self-loop Distance raises");

   ------------------------------------------------------------------
   Section ("2. Two-vertex digraphs (non-neg)");
   ------------------------------------------------------------------
   Clear (G, 2);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "2 isolated Success");
   Check (Dist (1) = 0, "2 isolated Dist(1)=0");
   Check (Dist (2) = Infinity, "2 isolated Dist(2)=Inf");
   Check (Distance (G, 1, 2) = Infinity, "2 isolated Distance Inf");
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (not Ok and then Len = 0, "2 isolated recon fail");

   Add_Edge (G, 1, 2, 7);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "2 arc Success");
   Check (Dist (2) = 7, "2 arc Dist(2)=7");
   Check (Prev (2) = 1, "2 arc Prev(2)=1");
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (Ok and then Len = 2 and then Path (1) = 1
            and then Path (2) = 2, "2 arc recon");

   Shortest_Paths (G, 2, Dist, Prev, Status);
   Check (Dist (2) = 0, "from 2 Dist(2)=0");
   Check (Dist (1) = Infinity, "from 2 Dist(1)=Inf");

   ------------------------------------------------------------------
   Section ("3. Negative edges without cycle");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 3, -3);
   Add_Edge (G, 3, 4, 2);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "neg edges Success");
   Check (Dist (1) = 0, "neg Dist(1)=0");
   Check (Dist (2) = 4, "neg Dist(2)=4");
   Check (Dist (3) = 1, "neg Dist(3)=1 via 2");
   Check (Dist (4) = 3, "neg Dist(4)=3");
   Check (Prev (3) = 2, "neg Prev(3)=2");
   Check (Prev (4) = 3, "neg Prev(4)=3");
   Check (Distance (G, 1, 4) = 3, "neg Distance 1→4");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "neg path len 4");
   Check (Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 3 and then Path (4) = 4,
          "neg path 1-2-3-4");
   Check (not Has_Negative_Cycle (G, 1), "neg edges no cycle");

   ------------------------------------------------------------------
   Section ("4. Classic negative cycle");
   ------------------------------------------------------------------
   --  1→2 (1), 2→3 (-2), 3→2 (-2) cycle; 3→4 (1)
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, -2);
   Add_Edge (G, 3, 2, -2);
   Add_Edge (G, 3, 4, 1);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Negative_Cycle, "classic cycle status");
   Check (Has_Negative_Cycle (G, 1), "classic Has_Neg");
   Check (SP_Raises_Cycle (G, 1), "classic raising SP");
   Check (Dist_Neg_Cycle (G, 1, 4), "classic Distance raises");

   Affected_By_Negative_Cycle (G, 1, Aff, Found);
   Check (Found, "classic Affected Found");
   Check (Aff (2), "classic Aff(2)");
   Check (Aff (3), "classic Aff(3)");
   Check (Aff (4), "classic Aff(4) reachable from cycle");
   Check (not Aff (1), "classic Aff(1) source not on cycle");

   --  Cycle not reachable from source 4
   Shortest_Paths (G, 4, Dist, Prev, Status);
   Check (Status = Success, "from 4 no cycle reachable");
   Check (not Has_Negative_Cycle (G, 4), "from 4 Has_Neg false");
   Check (Dist (4) = 0, "from 4 Dist(4)=0");
   Check (Dist (1) = Infinity, "from 4 Dist(1)=Inf");

   ------------------------------------------------------------------
   Section ("5. Unreachable Infinity / disconnected");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, -1);
   Add_Edge (G, 4, 5, 2);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "disc Success");
   Check (Dist (3) = 2, "disc Dist(3)=2");
   Check (Dist (4) = Infinity, "disc Dist(4)=Inf");
   Check (Dist (5) = Infinity, "disc Dist(5)=Inf");
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Len);
   Check (not Ok, "disc recon 5 fail");
   Shortest_Paths (G, 4, Dist, Prev, Status);
   Check (Dist (5) = 2, "from 4 Dist(5)=2");
   Check (Dist (1) = Infinity, "from 4 Dist(1)=Inf");

   ------------------------------------------------------------------
   Section ("6. Dijkstra-compatible non-negative diamond");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "diamond Success");
   Check (Dist (1) = 0, "diamond Dist1");
   Check (Dist (2) = 1, "diamond Dist2");
   Check (Dist (3) = 2, "diamond Dist3");
   Check (Dist (4) = 3, "diamond Dist4");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "diamond path len");
   Check (Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 3 and then Path (4) = 4,
          "diamond via 2-3");

   ------------------------------------------------------------------
   Section ("7. Parallel edges / zero weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 2, 7);
   Add_Edge (G, 2, 3, 0);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "parallel Success");
   Check (Dist (2) = 3, "parallel min 3");
   Check (Dist (3) = 3, "zero weight Dist3");
   Check (Edge_Count (G) = 4, "parallel edge count");

   ------------------------------------------------------------------
   Section ("8. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices) + 1), "Clear > Max_Vertices");
   Clear (G, 2);
   Check (Add_Raises (G, 1, 2, Integer (Weight_Type'Last) + 1),
          "Add weight too large");
   Check (Add_Raises (G, 1, 2, Integer (Weight_Type'First) - 1),
          "Add weight too small");
   Check (Add_Raises (G, 3, 1, 1), "Add From out of range");
   Check (Add_Raises (G, 1, 3, 1), "Add To out of range");
   Clear (G, 0);
   Check (Add_Raises (G, 1, 1, 0), "Add on empty graph");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Check (SP_Raises (G, 4, 3, 3), "SP Source out of range");
   Check (SP_Raises (G, 1, 2, 3), "SP Dist too short");
   Check (SP_Raises (G, 1, 3, 2), "SP Prev too short");
   Check (Dist_Raises (G, 1, 4), "Distance Target OOR");
   Check (Dist_Raises (G, 4, 1), "Distance Source OOR");
   Check (Aff_Raises (G, 1, 2), "Affected Aff too short");
   Check (Aff_Raises (G, 4, Max_Vertices), "Affected Source OOR");

   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Recon_Raises (Prev, 1, 2, 2, Max_Vertices),
          "Recon Path'First /= 1");
   declare
      Tiny : constant Prev_Array (1 .. 3) := [0, 1, 2];
   begin
      Check (Recon_Raises (Tiny, 1, 2, 1, 2),
             "Recon Path too short vs Prev");
   end;

   ------------------------------------------------------------------
   Section ("9. Chain with mixed signs");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, -2);
   Add_Edge (G, 3, 4, 4);
   Add_Edge (G, 4, 5, -1);
   Add_Edge (G, 5, 6, 3);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "chain Success");
   Check (Dist (2) = 5, "chain Dist2");
   Check (Dist (3) = 3, "chain Dist3");
   Check (Dist (4) = 7, "chain Dist4");
   Check (Dist (5) = 6, "chain Dist5");
   Check (Dist (6) = 9, "chain Dist6");
   Ok := Reconstruct_Path (Prev, 1, 6, Path, Len);
   Check (Ok and then Len = 6, "chain recon len");
   for I in 1 .. 6 loop
      Check (Path (I) = Vertex_Id (I), "chain path step");
   end loop;

   ------------------------------------------------------------------
   Section ("10. Shortcut vs longer negative path");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 4, 10);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, -1);
   Add_Edge (G, 3, 4, 2);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "shortcut Success");
   Check (Dist (4) = 4, "prefer 1-2-3-4 = 4 over direct 10");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "shortcut path len");

   ------------------------------------------------------------------
   Section ("11. Triangle cycle not reachable / reachable");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 3, 4, -2);
   Add_Edge (G, 4, 5, -2);
   Add_Edge (G, 5, 3, -2);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "unreachable cycle Success");
   Check (not Has_Negative_Cycle (G, 1), "unreachable cycle Has_Neg F");
   Check (Dist (2) = 1, "unreachable cycle Dist2");
   Check (Dist (3) = Infinity, "unreachable cycle Dist3 Inf");

   Shortest_Paths (G, 3, Dist, Prev, Status);
   Check (Status = Negative_Cycle, "from 3 cycle");
   Check (Has_Negative_Cycle (G, 3), "from 3 Has_Neg");

   ------------------------------------------------------------------
   Section ("12. Affected propagation");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, -5);
   Add_Edge (G, 4, 3, -5);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 5, 6, 1);
   Affected_By_Negative_Cycle (G, 1, Aff, Found);
   Check (Found, "prop Found");
   Check (Aff (3) and then Aff (4), "prop cycle verts");
   Check (Aff (5) and then Aff (6), "prop downstream");
   Check (not Aff (1), "prop not Aff1");
   Check (not Aff (2), "prop not Aff2");

   ------------------------------------------------------------------
   Section ("13. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Check (Edge_Count (G) = 1, "rebuild before Clear");
   Clear (G, 4);
   Check (Vertex_Count (G) = 4, "rebuild N=4");
   Check (Edge_Count (G) = 0, "rebuild edges cleared");
   Add_Edge (G, 1, 4, -3);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success and then Dist (4) = -3, "rebuild Dist4");

   ------------------------------------------------------------------
   Section ("14. Multiple sources sweep");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, -1);
   Add_Edge (G, 3, 4, 3);
   Add_Edge (G, 4, 5, 3);
   Add_Edge (G, 1, 5, 20);
   for S in Vertex_Id range 1 .. 5 loop
      Shortest_Paths (G, S, Dist, Prev, Status);
      Check (Status = Success, "sweep Success");
      Check (Dist (S) = 0, "sweep Dist(S)=0");
      Check (Prev (S) = 0, "sweep Prev(S)=0");
      Ok := Reconstruct_Path (Prev, S, S, Path, Len);
      Check (Ok and then Len = 1, "sweep recon self");
   end loop;
   Check (Distance (G, 1, 5) = 8, "sweep 1→5 = 3-1+3+3");
   Check (Distance (G, 2, 5) = 5, "sweep 2→5");
   Check (Distance (G, 5, 1) = Infinity, "sweep 5→1 Inf");

   ------------------------------------------------------------------
   Section ("15. Raising vs status overload agree");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, -1);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "agree status Success");
   declare
      Dist2 : Distance_Array (Vertex_Id);
      Prev2 : Prev_Array (Vertex_Id);
   begin
      Shortest_Paths (G, 1, Dist2, Prev2);
      Check (Dist2 (3) = Dist (3), "agree Dist3");
      Check (Prev2 (3) = Prev (3), "agree Prev3");
   end;

   Clear (G, 2);
   Add_Edge (G, 1, 2, -1);
   Add_Edge (G, 2, 1, -1);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Negative_Cycle, "agree cycle status");
   Check (SP_Raises_Cycle (G, 1), "agree cycle raising");

   ------------------------------------------------------------------
   Section ("16. Wide star / shallow");
   ------------------------------------------------------------------
   Clear (G, 21);
   for I in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, I, Integer (I) - 1);
   end loop;
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "wide Success");
   Check (Dist (21) = 20, "wide Dist21");
   Check (Dist (11) = 10, "wide Dist11");
   for I in Vertex_Id range 2 .. 21 loop
      Check (Prev (I) = 1, "wide prev");
   end loop;

   ------------------------------------------------------------------
   Section ("17. Layered DAG with negatives");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 2, 5, 9);
   Add_Edge (G, 3, 5, -2);
   Add_Edge (G, 3, 6, 2);
   Add_Edge (G, 4, 7, 4);
   Add_Edge (G, 5, 7, 1);
   Add_Edge (G, 6, 7, 10);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "layered Success");
   --  1→3→5→7 = 5-2+1 = 4; 1→2→4→7 = 9
   Check (Dist (7) = 4, "layered Dist7");
   Ok := Reconstruct_Path (Prev, 1, 7, Path, Len);
   Check (Ok and then Len = 4, "layered path len");
   Check (Path (1) = 1 and then Path (2) = 3
            and then Path (3) = 5 and then Path (4) = 7,
          "layered via 3-5");

   ------------------------------------------------------------------
   Section ("18. Distance vs Shortest_Paths agree");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 3, 2, -1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 5, 10);
   Add_Edge (G, 4, 6, 1);
   Add_Edge (G, 5, 6, -2);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "agree2 Success");
   for T in Vertex_Id range 1 .. 6 loop
      D := Distance (G, 1, T);
      Check (D = Dist (T), "agree2 Dist");
   end loop;

   ------------------------------------------------------------------
   Section ("19. Currency-style arbitrage cycle");
   ------------------------------------------------------------------
   --  1→2 (-1), 2→3 (-1), 3→1 (-1): classic arbitrage triangle
   Clear (G, 3);
   Add_Edge (G, 1, 2, -1);
   Add_Edge (G, 2, 3, -1);
   Add_Edge (G, 3, 1, -1);
   Check (Has_Negative_Cycle (G, 1), "arbitrage Has_Neg");
   Affected_By_Negative_Cycle (G, 1, Aff, Found);
   Check (Found, "arbitrage Found");
   Check (Aff (1) and then Aff (2) and then Aff (3),
          "arbitrage all affected");

   ------------------------------------------------------------------
   Section ("20. Positive cycle is fine");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 1, 2);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "pos cycle Success");
   Check (Dist (2) = 2, "pos cycle Dist2");
   Check (Dist (3) = 4, "pos cycle Dist3");
   Check (not Has_Negative_Cycle (G, 1), "pos cycle no neg");

   ------------------------------------------------------------------
   Section ("21. Zero-weight cycle is fine");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   Add_Edge (G, 3, 1, 0);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "zero cycle Success");
   Check (Dist (2) = 0 and then Dist (3) = 0, "zero cycle dists");
   Check (not Has_Negative_Cycle (G, 1), "zero cycle no neg");

   ------------------------------------------------------------------
   Section ("22. Reconstruct edge cases");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, -1);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (not Ok and then Len = 0, "recon unreachable");
   Ok := Reconstruct_Path (Prev, 1, 3, Path, Len);
   Check (Ok and then Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 3, "recon 1-2-3");
   declare
      P2 : constant Prev_Array (1 .. 4) := [1 => 0, 2 => 0, 3 => 0, 4 => 0];
   begin
      Ok := Reconstruct_Path (P2, 1, 2, Path, Len);
      Check (not Ok, "recon orphan Prev=0");
   end;

   ------------------------------------------------------------------
   Section ("23. Large sparse chain");
   ------------------------------------------------------------------
   Clear (G, 100);
   for I in 1 .. 99 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1),
                (if I mod 2 = 0 then -1 else 2));
   end loop;
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "sparse100 Success");
   Check (Dist (1) = 0, "sparse100 Dist1");
   Check (Prev (100) = 99, "sparse100 Prev100");
   Ok := Reconstruct_Path (Prev, 1, 100, Path, Len);
   Check (Ok and then Len = 100, "sparse100 path len");
   Check (not Has_Negative_Cycle (G, 1), "sparse100 no cycle");

   ------------------------------------------------------------------
   Section ("24. Edge capacity smoke");
   ------------------------------------------------------------------
   Clear (G, 2);
   declare
      Added : Natural := 0;
   begin
      for K in 1 .. 100 loop
         Add_Edge (G, 1, 2, K);
         Added := Added + 1;
      end loop;
      Check (Edge_Count (G) = Added, "100 parallel edges");
      Check (Distance (G, 1, 2) = 1, "min of 1..100 is 1");
   end;

   ------------------------------------------------------------------
   Section ("25. Wikipedia-style example");
   ------------------------------------------------------------------
   --  s=1, edges: 1→2(6), 1→3(5), 1→4(5), 2→5(-1), 3→2(-2),
   --  3→5(1), 4→3(-2), 4→6(-1), 5→7(3), 6→7(3)
   Clear (G, 7);
   Add_Edge (G, 1, 2, 6);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 1, 4, 5);
   Add_Edge (G, 2, 5, -1);
   Add_Edge (G, 3, 2, -2);
   Add_Edge (G, 3, 5, 1);
   Add_Edge (G, 4, 3, -2);
   Add_Edge (G, 4, 6, -1);
   Add_Edge (G, 5, 7, 3);
   Add_Edge (G, 6, 7, 3);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "wiki Success");
   Check (Dist (1) = 0, "wiki Dist1");
   Check (Dist (2) = 1, "wiki Dist2 via 4-3");
   Check (Dist (3) = 3, "wiki Dist3 via 4");
   Check (Dist (4) = 5, "wiki Dist4");
   Check (Dist (5) = 0, "wiki Dist5");
   Check (Dist (6) = 4, "wiki Dist6");
   Check (Dist (7) = 3, "wiki Dist7");
   Check (not Has_Negative_Cycle (G, 1), "wiki no cycle");

   ------------------------------------------------------------------
   Section ("26. API counters / Max bounds smoke");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Max_Vertices Clear");
   Check (Edge_Count (G) = 0, "Max_Vertices no edges");
   Add_Edge (G, 1, Vertex_Id (Max_Vertices), 0);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "Max_V Success");
   Check (Dist (Vertex_Id (Max_Vertices)) = 0, "Max_V Dist last");
   Check (Dist (2) = Infinity, "Max_V Dist2 Inf");

   ------------------------------------------------------------------
   Section ("27. Negative edge into unreachable component");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 3, 4, -10);
   Add_Edge (G, 4, 3, 1);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "neg elsewhere Success");
   Check (not Has_Negative_Cycle (G, 1), "neg elsewhere no from 1");
   Check (Has_Negative_Cycle (G, 3), "neg elsewhere from 3");

   ------------------------------------------------------------------
   Section ("28. Trivial N=2 negative one-way");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, -5);
   Shortest_Paths (G, 1, Dist, Prev, Status);
   Check (Status = Success, "one-way neg Success");
   Check (Dist (2) = -5, "one-way Dist2");
   Check (Prev (2) = 1, "one-way Prev2");
   Check (not Has_Negative_Cycle (G, 1), "one-way no cycle");
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (Ok and then Len = 2, "one-way recon");

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
