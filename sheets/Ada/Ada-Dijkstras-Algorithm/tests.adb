--  Standalone test suite for Dijkstras_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Dijkstras_Algorithm; use Dijkstras_Algorithm;

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
      Dist : Distance_Array (1 .. Vertex_Id (Dist_Last));
      Prev : Prev_Array (1 .. Vertex_Id (Prev_Last));
   begin
      Shortest_Paths (G, Source, Dist, Prev);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end SP_Raises;

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

   G      : Graph;
   Dist   : Distance_Array (Vertex_Id);
   Prev   : Prev_Array (Vertex_Id);
   Path   : Path_Array (1 .. Max_Vertices);
   Len    : Natural;
   Ok     : Boolean;
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
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "single Dist(1)=0");
   Check (Prev (1) = 0, "single Prev(1)=0");
   Check (Distance (G, 1, 1) = 0, "single Distance 1→1 = 0");
   Ok := Reconstruct_Path (Prev, 1, 1, Path, Len);
   Check (Ok and then Len = 1 and then Path (1) = 1, "single recon");

   Add_Edge (G, 1, 1, 5);
   Check (Edge_Count (G) = 1, "self-loop edge count");
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "self-loop Dist still 0");
   Check (Distance (G, 1, 1) = 0, "self-loop Distance 0");

   Add_Edge (G, 1, 1, 0);
   Check (Edge_Count (G) = 2, "zero-weight self-loop");
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "zero self-loop Dist 0");

   ------------------------------------------------------------------
   Section ("2. Two-vertex digraphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "2 isolated Dist(1)=0");
   Check (Dist (2) = Infinity, "2 isolated Dist(2)=Inf");
   Check (Distance (G, 1, 2) = Infinity, "2 isolated Distance Inf");
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (not Ok and then Len = 0, "2 isolated recon fail");

   Add_Edge (G, 1, 2, 7);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (2) = 7, "arc 1→2 weight 7");
   Check (Prev (2) = 1, "prev of 2 is 1");
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (Ok and then Len = 2 and then Path (1) = 1 and then Path (2) = 2,
          "recon 1-2");
   Check (Distance (G, 2, 1) = Infinity, "no reverse arc");

   Add_Edge (G, 2, 1, 3);
   Check (Distance (G, 2, 1) = 3, "reverse arc 2→1");
   Check (Distance (G, 1, 2) = 7, "forward still 7");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 0);
   Check (Distance (G, 1, 2) = 0, "zero-weight arc");

   ------------------------------------------------------------------
   Section ("3. Chains");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "chain Dist1");
   Check (Dist (2) = 1, "chain Dist2");
   Check (Dist (3) = 2, "chain Dist3");
   Check (Dist (4) = 3, "chain Dist4");
   Check (Dist (5) = 4, "chain Dist5");
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Len);
   Check (Ok and then Len = 5, "chain path len 5");
   Check (Path (1) = 1 and then Path (5) = 5, "chain path ends");
   Check (Path (2) = 2 and then Path (3) = 3 and then Path (4) = 4,
          "chain path middle");

   --  Weighted chain
   Clear (G, 4);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 2, 3, 20);
   Add_Edge (G, 3, 4, 30);
   Check (Distance (G, 1, 4) = 60, "weighted chain 60");
   Check (Distance (G, 2, 4) = 50, "from mid 50");
   Check (Distance (G, 4, 1) = Infinity, "chain no back");

   ------------------------------------------------------------------
   Section ("4. Diamond / shortcuts");
   ------------------------------------------------------------------
   --  Classic diamond: 1→2→4 and 1→3→4 with different weights
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (4) = 5, "diamond best 1-3-4 = 5");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Len = 3, "diamond path len 3");
   Check (Path (1) = 1 and then Path (2) = 3 and then Path (3) = 4,
          "diamond via 3");

   --  Wikipedia-ish example
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "wiki Dist1");
   Check (Dist (2) = 1, "wiki Dist2");
   Check (Dist (3) = 2, "wiki Dist3");
   Check (Dist (4) = 3, "wiki Dist4");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "wiki path 1-2-3-4");
   Check (Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 3 and then Path (4) = 4,
          "wiki path vertices");

   ------------------------------------------------------------------
   Section ("5. Unreachable / disconnected");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 3, 4, 2);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (2) = 1, "comp Dist2");
   Check (Dist (3) = Infinity, "comp Dist3 Inf");
   Check (Dist (4) = Infinity, "comp Dist4 Inf");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (not Ok, "comp recon 1→4 fail");
   Shortest_Paths (G, 3, Dist, Prev);
   Check (Dist (4) = 2, "from 3 Dist4=2");
   Check (Dist (1) = Infinity, "from 3 Dist1 Inf");

   Clear (G, 3);
   Add_Edge (G, 2, 3, 9);
   Check (Distance (G, 1, 3) = Infinity, "source isolated");
   Check (Distance (G, 1, 1) = 0, "isolated source self");

   ------------------------------------------------------------------
   Section ("6. Zero-weight and parallel edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   Check (Distance (G, 1, 3) = 0, "all-zero path");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 2, 7);
   Check (Distance (G, 1, 2) = 3, "parallel min 3");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 2, 100);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 1, 3, 50);
   Check (Distance (G, 1, 3) = 6, "parallel then hop = 6");

   ------------------------------------------------------------------
   Section ("7. Stars / trees");
   ------------------------------------------------------------------
   Clear (G, 6);
   for I in Vertex_Id range 2 .. 6 loop
      Add_Edge (G, 1, I, Integer (I));
   end loop;
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (2) = 2, "star Dist2");
   Check (Dist (6) = 6, "star Dist6");
   Check (Prev (4) = 1, "star prev");
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Len);
   Check (Ok and then Len = 2, "star leaf path");

   --  In-star (all point to hub) — from leaf only self
   Clear (G, 5);
   for I in Vertex_Id range 2 .. 5 loop
      Add_Edge (G, I, 1, 1);
   end loop;
   Check (Distance (G, 2, 1) = 1, "in-star 2→1");
   Check (Distance (G, 2, 3) = Infinity, "in-star 2→3 Inf");

   ------------------------------------------------------------------
   Section ("8. Grid DAG");
   ------------------------------------------------------------------
   --  3x3 grid directed right and down, unit weights; id (r,c)=3*(r-1)+c
   Clear (G, 9);
   declare
      function Id (R, C : Positive) return Vertex_Id is
        (Vertex_Id (3 * (R - 1) + C));
   begin
      for R in 1 .. 3 loop
         for C in 1 .. 3 loop
            if C < 3 then
               Add_Edge (G, Id (R, C), Id (R, C + 1), 1);
            end if;
            if R < 3 then
               Add_Edge (G, Id (R, C), Id (R + 1, C), 1);
            end if;
         end loop;
      end loop;
      Check (Distance (G, Id (1, 1), Id (3, 3)) = 4, "grid 1,1→3,3 = 4");
      Check (Distance (G, Id (1, 1), Id (1, 3)) = 2, "grid row");
      Check (Distance (G, Id (1, 1), Id (3, 1)) = 2, "grid col");
      Check (Distance (G, Id (3, 3), Id (1, 1)) = Infinity, "grid back Inf");
      Shortest_Paths (G, Id (1, 1), Dist, Prev);
      Ok := Reconstruct_Path (Prev, Id (1, 1), Id (3, 3), Path, Len);
      Check (Ok and then Len = 5, "grid path 5 verts");
   end;

   ------------------------------------------------------------------
   Section ("9. Longer chain N=30 / N=50");
   ------------------------------------------------------------------
   Clear (G, 30);
   for I in 1 .. 29 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
   end loop;
   Check (Distance (G, 1, 30) = 29, "chain30 dist");
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 30, Path, Len);
   Check (Ok and then Len = 30, "chain30 path len");
   Check (Path (15) = 15, "chain30 mid");

   Clear (G, 50);
   for I in 1 .. 49 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 2);
   end loop;
   Check (Distance (G, 1, 50) = 98, "chain50 dist 98");
   Check (Distance (G, 25, 50) = 50, "chain50 from 25");

   ------------------------------------------------------------------
   Section ("10. Clear / rebuild / counters");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Check (Vertex_Count (G) = 3, "vc 3");
   Check (Edge_Count (G) = 2, "ec 2");
   Clear (G, 2);
   Check (Vertex_Count (G) = 2, "after clear vc 2");
   Check (Edge_Count (G) = 0, "after clear ec 0");
   Check (Distance (G, 1, 2) = Infinity, "rebuild empty Inf");
   Add_Edge (G, 1, 2, 4);
   Check (Distance (G, 1, 2) = 4, "rebuild arc 4");
   Clear (G, 0);
   Check (Vertex_Count (G) = Nat (0), "clear to empty");

   ------------------------------------------------------------------
   Section ("11. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Max_Vertices + 1), "Clear N too large");
   Check (Clear_Raises (Nat (2_000)), "Clear 2000");

   Clear (G, 2);
   Check (Add_Raises (G, 1, 2, Int (-1)), "negative weight");
   Check (Add_Raises (G, 1, 2, Int (-100)), "negative weight -100");
   Check (not Add_Raises (G, 1, 2, Int (0)), "zero weight ok");
   Check (Add_Raises (G, 3, 1, 1), "From out of range");
   Check (Add_Raises (G, 1, 3, 1), "To out of range");

   Clear (G, 0);
   Check (Add_Raises (G, 1, 1, 1), "Add on empty graph");

   Clear (G, 3);
   Check (SP_Raises (G, 4, Max_Vertices, Max_Vertices),
          "Source out of range");
   Check (SP_Raises (G, 1, 2, Max_Vertices), "Dist too short");
   Check (SP_Raises (G, 1, Max_Vertices, 2), "Prev too short");
   Check (Dist_Raises (G, 4, 1), "Distance Source OOR");
   Check (Dist_Raises (G, 1, 4), "Distance Target OOR");

   Shortest_Paths (G, 1, Dist, Prev);
   Check (Recon_Raises (Prev, 1, 1, 2, Max_Vertices),
          "Path First /= 1");
   declare
      Small_Prev : constant Prev_Array (1 .. 3) := [others => 0];
   begin
      Check (Recon_Raises (Small_Prev, 1, 2, 1, 2),
             "Path Last < Prev Last");
   end;

   ------------------------------------------------------------------
   Section ("12. Cycles with non-negative weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 1, 1);
   Add_Edge (G, 3, 2, 5);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "cycle Dist1");
   Check (Dist (2) = 1, "cycle Dist2");
   Check (Dist (3) = 2, "cycle Dist3");
   --  From 2: 2→3→1
   Check (Distance (G, 2, 1) = 2, "cycle 2→1 = 2");

   ------------------------------------------------------------------
   Section ("13. Many equal distances / ties");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 2, 5, 1);
   Add_Edge (G, 3, 5, 1);
   Add_Edge (G, 4, 5, 1);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (5) = 2, "ties Dist5=2");
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Len);
   Check (Ok and then Len = 3, "ties path len 3");
   Check (Path (1) = 1 and then Path (3) = 5, "ties path ends");

   ------------------------------------------------------------------
   Section ("14. Large weights / overflow-safe Infinity");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1_000_000);
   Add_Edge (G, 2, 3, 2_000_000);
   Check (Distance (G, 1, 3) = 3_000_000, "large weights sum");
   Clear (G, 2);
   Add_Edge (G, 1, 2, Integer (Weight_Type'Last));
   Check (Distance (G, 1, 2) = Distance_Value (Weight_Type'Last),
          "max weight edge");

   ------------------------------------------------------------------
   Section ("15. Complete digraph small");
   ------------------------------------------------------------------
   Clear (G, 4);
   for I in Vertex_Id range 1 .. 4 loop
      for J in Vertex_Id range 1 .. 4 loop
         if I /= J then
            Add_Edge (G, I, J, Integer (I) + Integer (J));
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 12, "K4 directed edges 12");
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (1) = 0, "K4 Dist1");
   Check (Dist (2) = 3, "K4 Dist2 = 1+2");
   Check (Dist (3) = 4, "K4 Dist3 = 1+3");
   Check (Dist (4) = 5, "K4 Dist4 = 1+4");
   --  From 4 to 1 direct weight 5
   Check (Distance (G, 4, 1) = 5, "K4 4→1");

   ------------------------------------------------------------------
   Section ("16. Path consistency checks");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 3, 4, 2);
   Add_Edge (G, 1, 5, 10);
   Add_Edge (G, 5, 4, 1);
   Add_Edge (G, 4, 6, 3);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (4) = 6, "pathc Dist4 via chain");
   Check (Dist (6) = 9, "pathc Dist6");
   Ok := Reconstruct_Path (Prev, 1, 6, Path, Len);
   Check (Ok, "pathc recon ok");
   Check (Len >= 2, "pathc len>=2");
   for I in 2 .. Len loop
      Check (Prev (Path (I)) = Natural (Path (I - 1)),
             "pathc prev link" & Integer'Image (I));
   end loop;
   Check (Dist (6) = 9, "pathc Dist6 again");

   ------------------------------------------------------------------
   Section ("17. Bidirectional corridor");
   ------------------------------------------------------------------
   Clear (G, 8);
   for I in 1 .. 7 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
      Add_Edge (G, Vertex_Id (I + 1), Vertex_Id (I), 1);
   end loop;
   Check (Distance (G, 1, 8) = 7, "corridor 1→8");
   Check (Distance (G, 8, 1) = 7, "corridor 8→1");
   Check (Distance (G, 3, 6) = 3, "corridor 3→6");
   Shortest_Paths (G, 4, Dist, Prev);
   Check (Dist (1) = 3 and then Dist (8) = 4, "corridor from mid");

   ------------------------------------------------------------------
   Section ("18. Sparse vs dense choice");
   ------------------------------------------------------------------
   --  Prefer cheap long path over expensive shortcut
   Clear (G, 5);
   Add_Edge (G, 1, 5, 100);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Check (Distance (G, 1, 5) = 4, "prefer long cheap");
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Len);
   Check (Ok and then Len = 5, "cheap path 5 verts");

   ------------------------------------------------------------------
   Section ("19. Multiple sources sweep");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 3, 3);
   Add_Edge (G, 3, 4, 3);
   Add_Edge (G, 4, 5, 3);
   Add_Edge (G, 1, 5, 20);
   for S in Vertex_Id range 1 .. 5 loop
      Shortest_Paths (G, S, Dist, Prev);
      Check (Dist (S) = 0, "sweep Dist(S)=0");
      Check (Prev (S) = 0, "sweep Prev(S)=0");
      Ok := Reconstruct_Path (Prev, S, S, Path, Len);
      Check (Ok and then Len = 1, "sweep recon self");
   end loop;
   Check (Distance (G, 1, 5) = 12, "sweep 1→5 chain");
   Check (Distance (G, 2, 5) = 9, "sweep 2→5");
   Check (Distance (G, 5, 1) = Infinity, "sweep 5→1 Inf");

   ------------------------------------------------------------------
   Section ("20. Edge capacity smoke");
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
   Section ("21. Reconstruct edge cases");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Shortest_Paths (G, 1, Dist, Prev);
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (not Ok and then Len = 0, "recon unreachable");
   Ok := Reconstruct_Path (Prev, 1, 3, Path, Len);
   Check (Ok and then Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 3, "recon 1-2-3");
   --  Manual Prev corruption: Target with Prev=0 and Target/=Source
   declare
      P2 : constant Prev_Array (1 .. 4) := [1 => 0, 2 => 0, 3 => 0, 4 => 0];
   begin
      Ok := Reconstruct_Path (P2, 1, 2, Path, Len);
      Check (not Ok, "recon orphan Prev=0");
   end;

   ------------------------------------------------------------------
   Section ("22. Directed triangle weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 1, 3, 12);
   Check (Distance (G, 1, 3) = 10, "triangle prefer 1-2-3");
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 1, 3, 8);
   Check (Distance (G, 1, 3) = 8, "triangle prefer direct");

   ------------------------------------------------------------------
   Section ("23. Wide shallow tree");
   ------------------------------------------------------------------
   Clear (G, 21);
   for I in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, I, Integer (I) - 1);
   end loop;
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (21) = 20, "wide Dist21");
   Check (Dist (11) = 10, "wide Dist11");
   for I in Vertex_Id range 2 .. 21 loop
      Check (Prev (I) = 1, "wide prev" & Vertex_Id'Image (I));
   end loop;

   ------------------------------------------------------------------
   Section ("24. Layered DAG");
   ------------------------------------------------------------------
   --  Layers 1 | 2,3 | 4,5,6 | 7 with mixed weights
   Clear (G, 7);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 2, 5, 9);
   Add_Edge (G, 3, 5, 1);
   Add_Edge (G, 3, 6, 2);
   Add_Edge (G, 4, 7, 4);
   Add_Edge (G, 5, 7, 1);
   Add_Edge (G, 6, 7, 10);
   Shortest_Paths (G, 1, Dist, Prev);
   Check (Dist (7) = 7, "layered Dist7");
   --  1→2→4→7 = 9; 1→3→5→7 = 7; 1→2→5→7 = 12
   Ok := Reconstruct_Path (Prev, 1, 7, Path, Len);
   Check (Ok and then Len = 4, "layered path len");
   Check (Path (1) = 1 and then Path (2) = 3
            and then Path (3) = 5 and then Path (4) = 7,
          "layered via 3-5");

   ------------------------------------------------------------------
   Section ("25. Distance vs Shortest_Paths agree");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 5, 10);
   Add_Edge (G, 4, 6, 1);
   Add_Edge (G, 5, 6, 1);
   Shortest_Paths (G, 1, Dist, Prev);
   for T in Vertex_Id range 1 .. 6 loop
      D := Distance (G, 1, T);
      Check (D = Dist (T), "agree Dist" & Vertex_Id'Image (T));
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
