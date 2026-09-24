--  Standalone test suite for Johnsons_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Johnsons_Algorithm; use Johnsons_Algorithm;

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
   function Int (X : Integer) return Integer is (X);
   function Dist_Val (X : Distance_Value) return Distance_Value is (X);

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

   function AP_Raises_Empty return Boolean is
      G    : Graph;
      Dist : Dist_Matrix (1 .. 1, 1 .. 1);
      St   : Run_Status;
   begin
      Clear (G, 0);
      All_Pairs (G, Dist, St);
      pragma Unreferenced (St);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end AP_Raises_Empty;

   function AP_Raises_Bounds
     (N : Positive; Dist_Last : Positive) return Boolean
   is
      G    : Graph;
      Dist : Dist_Matrix (1 .. Vertex_Id (Dist_Last), 1 .. Vertex_Id (Dist_Last));
      St   : Run_Status;
   begin
      Clear (G, N);
      All_Pairs (G, Dist, St);
      pragma Unreferenced (St);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end AP_Raises_Bounds;

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

   function Dist_Neg_Cycle (G : Graph; S, T : Vertex_Id) return Boolean is
      D : Distance_Value;
   begin
      D := Distance (G, S, T);
      pragma Unreferenced (D);
      return False;
   exception
      when Negative_Cycle_Error =>
         return True;
   end Dist_Neg_Cycle;

   function Raising_AP_Neg (G : Graph) return Boolean is
      N    : constant Natural := Vertex_Count (G);
      Dist : Dist_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
      Prev : Prev_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
   begin
      All_Pairs (G, Dist, Prev);
      return False;
   exception
      when Negative_Cycle_Error =>
         return True;
   end Raising_AP_Neg;

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

   function HNC_Raises_Empty return Boolean is
      G : Graph;
      B : Boolean;
   begin
      Clear (G, 0);
      B := Has_Negative_Cycle (G);
      pragma Unreferenced (B);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end HNC_Raises_Empty;

   G      : Graph;
   Dist   : Dist_Matrix (1 .. 32, 1 .. 32);
   Prev   : Prev_Matrix (1 .. 32, 1 .. 32);
   St     : Run_Status;
   Path   : Path_Array (1 .. 32);
   Len    : Natural;
   Ok     : Boolean;
   D      : Distance_Value;
   Row    : Prev_Array (1 .. 32);

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Check (AP_Raises_Empty, "empty All_Pairs raises");
   Check (HNC_Raises_Empty, "empty Has_Negative_Cycle raises");
   Check (Dist_Raises (G, 1, 1), "empty Distance raises");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "single Success");
   Check (Dist (1, 1) = 0, "single Dist(1,1)=0");
   Check (Prev (1, 1) = 0, "single Prev(1,1)=0");
   Check (Distance (G, 1, 1) = 0, "single Distance 0");
   Check (not Has_Negative_Cycle (G), "single no neg cycle");
   Ok := Reconstruct_Path (Prev, 1, 1, Path, Len);
   Check (Ok and then Len = 1 and then Path (1) = 1, "single recon");

   Add_Edge (G, 1, 1, 5);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "pos self-loop Success");
   Check (Dist (1, 1) = 0, "pos self-loop Dist 0");

   Clear (G, 1);
   Add_Edge (G, 1, 1, -1);
   Check (Has_Negative_Cycle (G), "neg self-loop is cycle");
   All_Pairs (G, Dist, Prev, St);
   Check (St = Negative_Cycle, "neg self-loop status");
   Check (Raising_AP_Neg (G), "neg self-loop raising");
   Check (Dist_Neg_Cycle (G, 1, 1), "neg self-loop Distance raises");

   ------------------------------------------------------------------
   Section ("2. Two-vertex non-negative");
   ------------------------------------------------------------------
   Clear (G, 2);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "2 isolated Success");
   Check (Dist (1, 1) = 0 and then Dist (2, 2) = 0, "2 diag 0");
   Check (Dist (1, 2) = Infinity, "2 isolated 1to2 Inf");
   Check (Dist (2, 1) = Infinity, "2 isolated 2to1 Inf");

   Add_Edge (G, 1, 2, 7);
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 2) = 7, "arc 1to2 = 7");
   Check (Prev (1, 2) = 1, "prev 1,2 = 1");
   Check (Dist (2, 1) = Infinity, "no reverse");
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (Ok and then Len = 2 and then Path (1) = 1 and then Path (2) = 2,
          "recon 1-2");

   Add_Edge (G, 2, 1, 3);
   Check (Distance (G, 2, 1) = 3, "reverse 3");
   Check (Distance (G, 1, 2) = 7, "forward still 7");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 0);
   Check (Distance (G, 1, 2) = 0, "zero-weight arc");

   ------------------------------------------------------------------
   Section ("3. Two-vertex negative edge (no cycle)");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, -5);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "neg edge Success");
   Check (Dist (1, 2) = -5, "neg edge Dist=-5");
   Check (Dist (2, 1) = Infinity, "neg edge no reverse");
   Check (not Has_Negative_Cycle (G), "neg edge not a cycle");

   Add_Edge (G, 2, 1, 6);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "neg+pos Success");
   Check (Dist (1, 2) = -5, "still -5");
   Check (Dist (2, 1) = 6, "back 6");
   Check (Dist (1, 1) = 0, "diag still 0");

   ------------------------------------------------------------------
   Section ("4. Negative cycle detection");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, -3);
   Add_Edge (G, 2, 1, 2);
   Check (Has_Negative_Cycle (G), "2-cycle weight -1");
   All_Pairs (G, Dist, St);
   Check (St = Negative_Cycle, "2-cycle status");
   Check (Raising_AP_Neg (G), "2-cycle raising");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, -4);
   Add_Edge (G, 3, 1, 2);
   Check (Has_Negative_Cycle (G), "3-cycle weight -1");
   Johnson (G, Dist, St);
   Check (St = Negative_Cycle, "3-cycle Johnson status");

   Clear (G, 3);
   Add_Edge (G, 1, 1, 0);
   Add_Edge (G, 2, 3, -2);
   Add_Edge (G, 3, 2, 1);
   Check (Has_Negative_Cycle (G), "cycle via super-source");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 2, -1);
   Check (not Has_Negative_Cycle (G), "zero-weight cycle ok");
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "zero cycle Success");

   ------------------------------------------------------------------
   Section ("5. Chains");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "chain Success");
   Check (Dist (1, 5) = 4, "chain 1to5=4");
   Check (Dist (2, 5) = 3, "chain 2to5=3");
   Check (Dist (5, 1) = Infinity, "chain no back");
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Len);
   Check (Ok and then Len = 5, "chain path len 5");
   Check (Path (1) = 1 and then Path (5) = 5, "chain ends");
   Check (Path (2) = 2 and then Path (3) = 3 and then Path (4) = 4,
          "chain middle");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 2, 3, -3);
   Add_Edge (G, 3, 4, 5);
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 4) = 12, "weighted chain with neg 12");
   Check (Dist (1, 3) = 7, "to mid 7");
   Check (Distance (G, 1, 4) = 12, "Distance agrees 12");

   ------------------------------------------------------------------
   Section ("6. Diamond / shortcuts");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 100);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, 1);
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 4) = 2, "diamond short 2");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Len = 3 and then Path (2) = 2, "diamond via 2");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, -1);
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 4) = 0, "diamond neg short 0");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Path (2) = 3, "via 3 with neg");

   ------------------------------------------------------------------
   Section ("7. CLRS Johnson example");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 3, 8);
   Add_Edge (G, 1, 5, -4);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 2, 5, 7);
   Add_Edge (G, 3, 2, 4);
   Add_Edge (G, 4, 1, 2);
   Add_Edge (G, 4, 3, -5);
   Add_Edge (G, 5, 4, 6);
   Johnson (G, Dist, Prev, St);
   Check (St = Success, "CLRS Success");
   Check (not Has_Negative_Cycle (G), "CLRS no cycle");
   Check (Dist (1, 1) = 0, "CLRS D11");
   Check (Dist (1, 2) = 1, "CLRS D12");
   Check (Dist (1, 3) = -3, "CLRS D13");
   Check (Dist (1, 4) = 2, "CLRS D14");
   Check (Dist (1, 5) = -4, "CLRS D15");
   Check (Dist (2, 1) = 3, "CLRS D21");
   Check (Dist (2, 2) = 0, "CLRS D22");
   Check (Dist (2, 3) = -4, "CLRS D23");
   Check (Dist (2, 4) = 1, "CLRS D24");
   Check (Dist (2, 5) = -1, "CLRS D25");
   Check (Dist (3, 1) = 7, "CLRS D31");
   Check (Dist (3, 2) = 4, "CLRS D32");
   Check (Dist (3, 3) = 0, "CLRS D33");
   Check (Dist (3, 4) = 5, "CLRS D34");
   Check (Dist (3, 5) = 3, "CLRS D35");
   Check (Dist (4, 1) = 2, "CLRS D41");
   Check (Dist (4, 2) = -1, "CLRS D42");
   Check (Dist (4, 3) = -5, "CLRS D43");
   Check (Dist (4, 4) = 0, "CLRS D44");
   Check (Dist (4, 5) = -2, "CLRS D45");
   Check (Dist (5, 1) = 8, "CLRS D51");
   Check (Dist (5, 2) = 5, "CLRS D52");
   Check (Dist (5, 3) = 1, "CLRS D53");
   Check (Dist (5, 4) = 6, "CLRS D54");
   Check (Dist (5, 5) = 0, "CLRS D55");
   Check (Distance (G, 1, 3) = -3, "CLRS Distance 1to3");
   Check (Distance (G, 4, 3) = -5, "CLRS Distance 4to3");

   ------------------------------------------------------------------
   Section ("8. Disconnected components");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 1, -1);
   Add_Edge (G, 4, 5, 3);
   Add_Edge (G, 5, 6, -2);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "disconnect Success");
   Check (Dist (1, 2) = 2, "comp A 1to2");
   Check (Dist (2, 1) = -1, "comp A 2to1");
   Check (Dist (1, 4) = Infinity, "cross Inf");
   Check (Dist (4, 6) = 1, "comp B 4to6");
   Check (Dist (6, 4) = Infinity, "comp B no back");
   Check (Dist (3, 3) = 0, "isolated diag");
   Check (Dist (3, 1) = Infinity, "isolated out Inf");

   ------------------------------------------------------------------
   Section ("9. Non-negative APSP known values");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "nonneg Success");
   Check (Dist (1, 1) = 0, "nn D11");
   Check (Dist (1, 2) = 1, "nn D12");
   Check (Dist (1, 3) = 2, "nn D13");
   Check (Dist (1, 4) = 3, "nn D14");
   Check (Dist (2, 4) = 2, "nn D24");
   Check (Dist (3, 2) = Infinity, "nn D32 Inf");
   for S in Vertex_Id range 1 .. 4 loop
      for T in Vertex_Id range 1 .. 4 loop
         D := Distance (G, S, T);
         Check (D = Dist (S, T),
                "nn agree" & Vertex_Id'Image (S) & Vertex_Id'Image (T));
      end loop;
   end loop;

   ------------------------------------------------------------------
   Section ("10. Parallel edges / self-loops");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 2, 7);
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 2) = 3, "parallel min 3");
   Add_Edge (G, 2, 2, 0);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success and then Dist (2, 2) = 0, "zero self-loop ok");
   Check (Edge_Count (G) = 4, "edge count 4");

   ------------------------------------------------------------------
   Section ("11. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, -2);
   Check (Edge_Count (G) = 1, "before clear edges 1");
   Clear (G, 2);
   Check (Vertex_Count (G) = 2, "rebuild N=2");
   Check (Edge_Count (G) = 0, "rebuild edges 0");
   Add_Edge (G, 1, 2, 9);
   Check (Distance (G, 1, 2) = 9, "rebuild distance");

   ------------------------------------------------------------------
   Section ("12. Invalid_Argument guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow");
   Clear (G, 2);
   Check (Add_Raises (G, 1, 3, 1), "Add To out of range");
   Check (Add_Raises (G, 3, 1, 1), "Add From out of range");
   Check (not Add_Raises (G, 1, 2, Int (-100)), "neg weight allowed");
   Check (AP_Raises_Bounds (4, 3), "Dist too small");
   Clear (G, 3);
   Check (Dist_Raises (G, 4, 1), "Distance Source OOR");
   Check (Dist_Raises (G, 1, 4), "Distance Target OOR");
   declare
      Pbad : constant Prev_Array (1 .. 3) := [0, 1, 2];
   begin
      Check (Recon_Raises (Pbad, 1, 2, 2, 3), "recon Path First /= 1");
      Check (Recon_Raises (Pbad, 1, 2, 1, 2), "recon Path too short");
   end;

   ------------------------------------------------------------------
   Section ("13. Johnson aliases / Prev optional");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, -1);
   Johnson (G, Dist, St);
   Check (St = Success, "Johnson no-Prev Success");
   Check (Dist (1, 3) = 1, "Johnson no-Prev D13");
   Johnson (G, Dist, Prev, St);
   Check (St = Success and then Dist (1, 3) = 1, "Johnson with Prev");
   declare
      Dist2 : Dist_Matrix (1 .. 3, 1 .. 3);
      Prev2 : Prev_Matrix (1 .. 3, 1 .. 3);
   begin
      All_Pairs (G, Dist2, Prev2);
      Check (Dist2 (1, 3) = 1, "raising All_Pairs ok");
      Johnson (G, Dist2, Prev2);
      Check (Dist2 (1, 2) = 2, "raising Johnson ok");
   end;

   ------------------------------------------------------------------
   Section ("14. Path reconstruction edge cases");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   All_Pairs (G, Dist, Prev, St);
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "path 1..4 len");
   for I in 1 .. 4 loop
      Row (Vertex_Id (I)) := Prev (1, Vertex_Id (I));
   end loop;
   Ok := Reconstruct_Path (Row (1 .. 4), 1, 4, Path, Len);
   Check (Ok and then Path (4) = 4, "row recon");
   Ok := Reconstruct_Path (Prev, 1, 1, Path, Len);
   Check (Ok and then Len = 1, "trivial path");
   Ok := Reconstruct_Path (Prev, 4, 1, Path, Len);
   Check (not Ok and then Len = 0, "unreachable recon");
   declare
      P2 : constant Prev_Array (1 .. 4) := [1 => 0, 2 => 0, 3 => 0, 4 => 0];
   begin
      Ok := Reconstruct_Path (P2, 1, 2, Path, Len);
      Check (not Ok, "orphan Prev=0");
   end;

   ------------------------------------------------------------------
   Section ("15. Larger grid / star / DAG");
   ------------------------------------------------------------------
   Clear (G, 9);
   Add_Edge (G, 1, 2, 1); Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 4, 5, 1); Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 7, 8, 1); Add_Edge (G, 8, 9, 1);
   Add_Edge (G, 1, 4, 1); Add_Edge (G, 4, 7, 1);
   Add_Edge (G, 2, 5, 1); Add_Edge (G, 5, 8, 1);
   Add_Edge (G, 3, 6, 1); Add_Edge (G, 6, 9, 1);
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 9) = 4, "grid 1to9=4");
   Check (Dist (1, 5) = 2, "grid 1to5=2");
   Check (Dist (9, 1) = Infinity, "grid no up-left");

   Clear (G, 10);
   for I in Vertex_Id range 2 .. 10 loop
      Add_Edge (G, 1, I, Integer (I) - 5);
   end loop;
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "star Success");
   Check (Dist (1, 2) = -3, "star leaf2");
   Check (Dist (1, 10) = 5, "star leaf10");
   Check (Dist (2, 3) = Infinity, "star no spoke-spoke");

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
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 7) = 4, "layered Dist7=4");
   Ok := Reconstruct_Path (Prev, 1, 7, Path, Len);
   Check (Ok and then Len = 4, "layered path len");
   Check (Path (2) = 3 and then Path (3) = 5, "layered via 3-5");

   ------------------------------------------------------------------
   Section ("16. Complete digraph telescoping weights");
   ------------------------------------------------------------------
   Clear (G, 5);
   for I in Vertex_Id range 1 .. 5 loop
      for J in Vertex_Id range 1 .. 5 loop
         if I /= J then
            Add_Edge (G, I, J, Integer (I) - Integer (J));
         end if;
      end loop;
   end loop;
   Check (not Has_Negative_Cycle (G), "complete no neg cycle");
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "complete Success");
   for I in Vertex_Id range 1 .. 5 loop
      Check (Dist (I, I) = 0, "complete diag" & Vertex_Id'Image (I));
   end loop;
   Check (Dist (1, 5) = -4, "complete 1to5");
   Check (Dist (5, 1) = 4, "complete 5to1");
   Check (Dist (2, 4) = -2, "complete 2to4");

   ------------------------------------------------------------------
   Section ("17. Many sources Distance vs matrix");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 3, 2, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 5, -3);
   Add_Edge (G, 4, 6, 1);
   Add_Edge (G, 5, 6, 2);
   Add_Edge (G, 5, 4, 4);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "agree graph Success");
   for S in Vertex_Id range 1 .. 6 loop
      for T in Vertex_Id range 1 .. 6 loop
         D := Distance (G, S, T);
         Check (D = Dist (S, T),
                "agree" & Vertex_Id'Image (S) & "," & Vertex_Id'Image (T));
      end loop;
   end loop;

   ------------------------------------------------------------------
   Section ("18. Capacity / Max_Vertices boundary");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "max vertices ok");
   Add_Edge (G, 1, Vertex_Id (Max_Vertices), 1);
   Check (Edge_Count (G) = 1, "edge at max id");
   Check (Distance (G, 1, Vertex_Id (Max_Vertices)) = 1, "max id Distance");
   Check (Distance (G, Vertex_Id (Max_Vertices), 1) = Infinity,
          "max id reverse Inf");

   ------------------------------------------------------------------
   Section ("19. Directed triangle weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 1, 3, 12);
   Check (Distance (G, 1, 3) = 10, "triangle prefer path");
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 1, 3, 8);
   Check (Distance (G, 1, 3) = 8, "triangle prefer direct");
   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, -1);
   Add_Edge (G, 1, 3, 5);
   Check (Distance (G, 1, 3) = 4, "triangle prefer neg path");

   ------------------------------------------------------------------
   Section ("20. Wide shallow + long chain");
   ------------------------------------------------------------------
   Clear (G, 21);
   for I in Vertex_Id range 2 .. 21 loop
      Add_Edge (G, 1, I, Integer (I) - 1);
   end loop;
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 21) = 20, "wide Dist21");
   Check (Dist (1, 11) = 10, "wide Dist11");
   Check (Prev (1, 15) = 1, "wide prev15");

   Clear (G, 20);
   for I in Vertex_Id range 1 .. 19 loop
      Add_Edge (G, I, I + 1, 1);
   end loop;
   Check (Distance (G, 1, 20) = 19, "long chain 19");
   Check (Distance (G, 10, 20) = 10, "long from mid");

   ------------------------------------------------------------------
   Section ("21. Negative edges no cycle handcrafted");
   ------------------------------------------------------------------
   Clear (G, 8);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, -2);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 3, 4, 5);
   Add_Edge (G, 4, 5, -1);
   Add_Edge (G, 5, 6, 2);
   Add_Edge (G, 3, 6, 10);
   Add_Edge (G, 6, 7, -3);
   Add_Edge (G, 7, 8, 1);
   Add_Edge (G, 2, 8, 20);
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "handcrafted Success");
   Check (not Has_Negative_Cycle (G), "handcrafted no cycle");
   Check (Dist (1, 8) = 2, "handcrafted 1to8=2");
   Check (Dist (1, 4) = 3, "handcrafted 1to4 via 3");
   Ok := Reconstruct_Path (Prev, 1, 8, Path, Len);
   Check (Ok and then Len = 7, "handcrafted path len 7");

   ------------------------------------------------------------------
   Section ("22. Infinity sentinel");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, -7);
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 2) < 0, "neg stored");
   Check (Dist (2, 3) = Infinity, "Inf sentinel");
   Check (Dist (3, 1) = Infinity, "Inf other");
   Check (Dist_Val (Infinity) > Dist_Val (0), "Infinity positive");
   Check (Dist_Val (Infinity) = Dist_Val (Distance_Value'Last),
          "Infinity is Last");

   ------------------------------------------------------------------
   Section ("23. API counters / parallels");
   ------------------------------------------------------------------
   Clear (G, 5);
   for K in 1 .. 50 loop
      Add_Edge (G, 1, 2, K);
   end loop;
   Check (Edge_Count (G) = 50, "50 parallel edges");
   Check (Distance (G, 1, 2) = 1, "min of parallels = 1");

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
