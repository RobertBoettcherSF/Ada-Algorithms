--  Standalone test suite for Longest_Path_Problem (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Longest_Path_Problem; use Longest_Path_Problem;

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

   function DAG_Raises_Cycle (G : Graph) return Boolean is
      Path   : Path_Array (1 .. Max_Vertices);
      Length : Natural;
      Weight : Distance_Value;
   begin
      DAG_Longest_Path (G, Path, Length, Weight);
      return False;
   exception
      when Cycle_Error =>
         return True;
   end DAG_Raises_Cycle;

   function DAG_Raises_Arg (G : Graph; Path_Last : Positive) return Boolean is
      Path   : Path_Array (1 .. Path_Last);
      Length : Natural;
      Weight : Distance_Value;
      Status : Run_Status;
   begin
      DAG_Longest_Path (G, Path, Length, Weight, Status);
      pragma Unreferenced (Length, Weight, Status);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end DAG_Raises_Arg;

   function Exact_Raises (G : Graph) return Boolean is
      Path   : Path_Array (1 .. Max_Vertices);
      Length : Natural;
      Weight : Distance_Value;
   begin
      Exact_Simple_Path (G, Path, Length, Weight);
      pragma Unreferenced (Length, Weight);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Exact_Raises;

   function Exact_ST_Raises
     (G : Graph; S, T : Vertex_Id) return Boolean
   is
      Path   : Path_Array (1 .. Max_Vertices);
      Length : Natural;
      Weight : Distance_Value;
      Found  : Boolean;
   begin
      Exact_Simple_Path (G, S, T, Path, Length, Weight, Found);
      pragma Unreferenced (Length, Weight, Found);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Exact_ST_Raises;

   function Weight_Raises (G : Graph) return Boolean is
      W : Distance_Value;
   begin
      W := DAG_Longest_Weight (G);
      pragma Unreferenced (W);
      return False;
   exception
      when Cycle_Error =>
         return True;
      when Invalid_Argument =>
         return True;
   end Weight_Raises;

   function From_Raises
     (G : Graph; Source : Vertex_Id;
      Dist_Last, Prev_Last : Positive) return Boolean
   is
      Dist   : Distance_Array (1 .. Vertex_Id (Dist_Last));
      Prev   : Prev_Array (1 .. Vertex_Id (Prev_Last));
      Status : Run_Status;
   begin
      DAG_Longest_From (G, Source, Dist, Prev, Status);
      pragma Unreferenced (Status);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end From_Raises;

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
   Path   : Path_Array (1 .. Max_Vertices);
   Len    : Natural;
   Wgt    : Distance_Value;
   Status : Run_Status;
   Dist   : Distance_Array (Vertex_Id);
   Prev   : Prev_Array (Vertex_Id);
   Ok     : Boolean;
   Found  : Boolean;
   D      : Distance_Value;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / single / self");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty vertex count");
   Check (Edge_Count (G) = 0, "empty edge count");
   Check (Is_Acyclic (G), "empty is acyclic");
   Check (DAG_Raises_Arg (G, Max_Vertices), "empty DAG raises");
   Check (Exact_Raises (G), "empty Exact raises");
   Check (Weight_Raises (G), "empty Weight raises");

   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single vertex count");
   Check (Edge_Count (G) = 0, "single no edges");
   Check (Is_Acyclic (G), "single acyclic");
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Status = Success, "single DAG success");
   Check (Len = 1 and then Path (1) = 1, "single path");
   Check (Wgt = 0, "single weight 0");
   Check (DAG_Longest_Weight (G) = 0, "single Weight fn");

   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Len = 1 and then Path (1) = 1 and then Wgt = 0, "single exact");

   Exact_Simple_Path (G, 1, 1, Path, Len, Wgt, Found);
   Check (Found and then Len = 1 and then Wgt = 0, "exact 1→1");

   Add_Edge (G, 1, 1, 5);
   Check (Edge_Count (G) = 1, "self-loop edge");
   Check (not Is_Acyclic (G), "self-loop cyclic");
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Status = Cycle_Detected, "self-loop Cycle_Detected");
   Check (DAG_Raises_Cycle (G), "self-loop raises Cycle_Error");

   ------------------------------------------------------------------
   Section ("2. Clear / Add_Edge guards");
   ------------------------------------------------------------------
   Check (Clear_Raises (Nat (Max_Vertices + 1)), "Clear overflow");
   Clear (G, 3);
   Check (Add_Raises (G, 1, 2, Int (-1)), "negative weight");
   Check (Add_Raises (G, 4, 1, 1), "From out of range");
   Check (Add_Raises (G, 1, 4, 1), "To out of range");
   Add_Edge (G, 1, 2);
   Check (Edge_Count (G) = 1, "unit Add_Edge");
   Add_Edge (G, 2, 3, 7);
   Check (Edge_Count (G) = 2, "weighted Add_Edge");
   Check (Is_Acyclic (G), "chain acyclic");

   ------------------------------------------------------------------
   Section ("3. DAG chain (hand-checked)");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Status = Success, "chain DAG ok");
   Check (Wgt = 4, "chain weight 4");
   Check (Len = 5, "chain len 5");
   Check (Path (1) = 1 and then Path (5) = 5, "chain ends");
   Check (Path (2) = 2 and then Path (3) = 3 and then Path (4) = 4,
          "chain middle");
   Check (DAG_Longest_Weight (G) = 4, "chain Weight fn");

   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 4 and then Len = 5, "chain exact agrees");

   ------------------------------------------------------------------
   Section ("4. DAG weighted diamond (hand-checked)");
   ------------------------------------------------------------------
   --  1→2→4 weight 1+5=6; 1→3→4 weight 4+1=5; longest = 6 via 2
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Status = Success, "diamond ok");
   Check (Wgt = 6, "diamond weight 6");
   Check (Len = 3, "diamond len 3");
   Check (Path (1) = 1 and then Path (2) = 2 and then Path (3) = 4,
          "diamond via 2");

   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 6, "diamond exact weight");
   Check (Len = 3 and then Path (2) = 2, "diamond exact via 2");

   ------------------------------------------------------------------
   Section ("5. DAG vs hop-count (unit edges)");
   ------------------------------------------------------------------
   --  Longer hop path preferred when all weights = 1
   Clear (G, 4);
   Add_Edge (G, 1, 4);       -- direct hop 1
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 4);       -- 3 hops
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 3, "unit longest hops 3");
   Check (Len = 4, "unit path 4 verts");
   Check (Path (1) = 1 and then Path (4) = 4, "unit ends");

   ------------------------------------------------------------------
   Section ("6. Critical-path style DAG");
   ------------------------------------------------------------------
   --  Milestones 1..6; activities with durations
   Clear (G, 6);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 2, 4, 4);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 3, 5, 5);
   Add_Edge (G, 4, 6, 2);
   Add_Edge (G, 5, 6, 1);
   --  Paths: 1-2-4-6 = 3+4+2=9; 1-3-4-6 = 2+1+2=5; 1-3-5-6 = 2+5+1=8
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 9, "critical path weight 9");
   Check (Len = 4, "critical path len 4");
   Check (Path (1) = 1 and then Path (2) = 2
            and then Path (3) = 4 and then Path (4) = 6,
          "critical 1-2-4-6");

   ------------------------------------------------------------------
   Section ("7. Cycle detection");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 1, 1);
   Check (not Is_Acyclic (G), "triangle cyclic");
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Status = Cycle_Detected, "triangle Cycle_Detected");
   Check (Len = 0 and then Wgt = 0, "triangle cleared outs");
   Check (DAG_Raises_Cycle (G), "triangle Cycle_Error");
   Check (Weight_Raises (G), "triangle Weight raises");

   Clear (G, 4);
   Add_Edge (G, 1, 2);
   Add_Edge (G, 2, 3);
   Add_Edge (G, 3, 2);  -- 2↔3 cycle; 1 feeds in
   Add_Edge (G, 3, 4);
   Check (not Is_Acyclic (G), "mid cycle");
   DAG_Longest_From (G, 1, Dist, Prev, Status);
   Check (Status = Cycle_Detected, "From mid cycle");

   ------------------------------------------------------------------
   Section ("8. DAG_Longest_From");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 3, 4, 10);
   Add_Edge (G, 4, 5, 1);
   DAG_Longest_From (G, 1, Dist, Prev, Status);
   Check (Status = Success, "From success");
   Check (Dist (1) = 0, "From Dist1=0");
   Check (Dist (2) = 2, "From Dist2=2");
   Check (Dist (3) = 1, "From Dist3=1");
   Check (Dist (4) = 11, "From Dist4=11 via 3");
   Check (Dist (5) = 12, "From Dist5=12");
   Ok := Reconstruct_Path (Prev, 1, 5, Path, Len);
   Check (Ok and then Len = 4, "From recon len");
   Check (Path (1) = 1 and then Path (2) = 3
            and then Path (3) = 4 and then Path (4) = 5,
          "From recon verts");

   DAG_Longest_From (G, 2, Dist, Prev, Status);
   Check (Dist (2) = 0, "From2 Dist2");
   Check (Dist (4) = 3, "From2 Dist4");
   Check (Dist (5) = 4, "From2 Dist5");
   Check (Dist (1) = Infinity, "From2 Dist1 Inf");
   Check (Dist (3) = Infinity, "From2 Dist3 Inf");
   Ok := Reconstruct_Path (Prev, 2, 1, Path, Len);
   Check (not Ok, "From2 unreachable 1");

   ------------------------------------------------------------------
   Section ("9. Isolated / disconnected DAG");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 3, 4, 1);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 5, "disc longest 5");
   Check (Len = 2 and then Path (1) = 1 and then Path (2) = 2,
          "disc path 1-2");

   Clear (G, 3);
   --  no edges: any singleton, weight 0
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 0 and then Len = 1, "isolates weight 0");

   ------------------------------------------------------------------
   Section ("10. Exact tiny graphs");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 9);
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 9 and then Len = 2, "exact 1-2");
   Exact_Simple_Path (G, 2, 1, Path, Len, Wgt, Found);
   Check (not Found, "exact no reverse");
   Exact_Simple_Path_From (G, 2, Path, Len, Wgt);
   Check (Len = 1 and then Wgt = 0, "exact from 2 singleton");
   Exact_Simple_Path_From (G, 1, Path, Len, Wgt);
   Check (Len = 2 and then Wgt = 9, "exact from 1");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 1, 3, 10);
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 10, "exact prefers heavy direct");
   --  hop-max would be 1-2-3 weight 2; weight-max is 1-3 = 10
   Exact_Simple_Path (G, 1, 3, Path, Len, Wgt, Found);
   Check (Found and then Wgt = 10, "exact ST heavy");

   ------------------------------------------------------------------
   Section ("11. Exact undirected (both arcs)");
   ------------------------------------------------------------------
   Clear (G, 4);
   --  Path graph undirected: 1—2—3—4
   Add_Edge (G, 1, 2); Add_Edge (G, 2, 1);
   Add_Edge (G, 2, 3); Add_Edge (G, 3, 2);
   Add_Edge (G, 3, 4); Add_Edge (G, 4, 3);
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 3 and then Len = 4, "undirected path hops 3");
   Check ((Path (1) = 1 and then Path (4) = 4)
            or else (Path (1) = 4 and then Path (4) = 1),
          "undirected ends are leaves");

   ------------------------------------------------------------------
   Section ("12. Exact complete K4 unit");
   ------------------------------------------------------------------
   Clear (G, 4);
   for I in Vertex_Id range 1 .. 4 loop
      for J in Vertex_Id range 1 .. 4 loop
         if I /= J then
            Add_Edge (G, I, J);
         end if;
      end loop;
   end loop;
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 3 and then Len = 4, "K4 hamiltonian weight 3");
   --  any permutation of 4 distinct verts
   declare
      Seen : array (1 .. 4) of Boolean := [others => False];
      All_Distinct : Boolean := True;
   begin
      for I in 1 .. 4 loop
         if Natural (Path (I)) > 4 or else Seen (Natural (Path (I))) then
            All_Distinct := False;
         else
            Seen (Natural (Path (I))) := True;
         end if;
      end loop;
      Check (All_Distinct, "K4 path all distinct");
   end;

   ------------------------------------------------------------------
   Section ("13. Exact vs DAG agree on DAGs");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 2, 4, 2);
   Add_Edge (G, 3, 4, 5);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 2, 5, 10);
   --  1-2-5 = 13; 1-3-4-5 = 7; 1-2-4-5 = 6 → best 13
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 13, "agree DAG 13");
   declare
      EW : Distance_Value;
      EL : Natural;
      EP : Path_Array (1 .. Max_Vertices);
   begin
      Exact_Simple_Path (G, EP, EL, EW);
      Check (EW = Wgt, "agree Exact weight");
      Check (EL = Len, "agree Exact len");
   end;

   ------------------------------------------------------------------
   Section ("14. Parallel edges");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 2, 8);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 8, "parallel DAG takes 8");
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 8, "parallel Exact takes 8");

   ------------------------------------------------------------------
   Section ("15. Zero-weight edges");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 0, "zero-weight DAG");
   --  Path of 3 verts still preferred by Exact tie-break on length
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 0 and then Len = 3, "zero-weight Exact long");

   ------------------------------------------------------------------
   Section ("16. Exact Source-Target variants");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 5, 1);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Exact_Simple_Path (G, 1, 5, Path, Len, Wgt, Found);
   Check (Found and then Wgt = 3 and then Len = 4, "ST via 2-3");
   Check (Path (1) = 1 and then Path (4) = 5, "ST ends");
   Exact_Simple_Path (G, 5, 1, Path, Len, Wgt, Found);
   Check (not Found, "ST reverse absent");
   Exact_Simple_Path (G, 2, 4, Path, Len, Wgt, Found);
   Check (not Found, "ST 2→4 absent");

   ------------------------------------------------------------------
   Section ("17. Invalid_Argument battery");
   ------------------------------------------------------------------
   Clear (G, 0);
   Check (From_Raises (G, 1, Max_Vertices, Max_Vertices),
          "From empty raises");
   Clear (G, 3);
   Check (From_Raises (G, 4, Max_Vertices, Max_Vertices),
          "From bad source");
   Check (From_Raises (G, 1, 2, Max_Vertices), "From short Dist");
   Check (From_Raises (G, 1, Max_Vertices, 2), "From short Prev");
   Check (DAG_Raises_Arg (G, 2), "DAG short Path");
   Check (Exact_ST_Raises (G, 4, 1), "Exact bad Source");
   Check (Exact_ST_Raises (G, 1, 4), "Exact bad Target");

   Clear (G, Max_Exact_Vertices + 1);
   for I in 1 .. Max_Exact_Vertices loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1));
   end loop;
   Check (Exact_Raises (G), "Exact over Max_Exact");
   Check (Is_Acyclic (G), "large chain still DAG");
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Status = Success, "DAG ok beyond Exact cap");
   Check (Wgt = Distance_Value (Max_Exact_Vertices),
          "large chain weight");

   Prev (1) := 0;
   Check (Recon_Raises (Prev, 1, 1, 2, Max_Vertices),
          "recon Path First/=1");

   ------------------------------------------------------------------
   Section ("18. Reconstruct edge cases");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   DAG_Longest_From (G, 1, Dist, Prev, Status);
   Ok := Reconstruct_Path (Prev, 1, 1, Path, Len);
   Check (Ok and then Len = 1, "recon trivial");
   Ok := Reconstruct_Path (Prev, 1, 3, Path, Len);
   Check (Ok and then Len = 3, "recon full");
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (Ok and then Path (2) = 2, "recon mid");

   ------------------------------------------------------------------
   Section ("19. Layered DAG (hand-checked)");
   ------------------------------------------------------------------
   Clear (G, 7);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 3, 5, 4);
   Add_Edge (G, 4, 6, 2);
   Add_Edge (G, 5, 6, 1);
   Add_Edge (G, 6, 7, 5);
   --  1-3-5-6-7 = 2+4+1+5 = 12; 1-2-4-6-7 = 1+3+2+5 = 11; 1-3-4-6-7 = 2+1+2+5 = 10
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 12, "layered 12");
   Check (Path (1) = 1 and then Path (2) = 3 and then Path (3) = 5
            and then Path (4) = 6 and then Path (5) = 7,
          "layered path");
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 12, "layered exact");

   ------------------------------------------------------------------
   Section ("20. Star DAG out / in");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 1, 3, 9);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 1, 5, 7);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 9 and then Path (2) = 3, "out-star heaviest");

   Clear (G, 5);
   Add_Edge (G, 2, 1, 4);
   Add_Edge (G, 3, 1, 9);
   Add_Edge (G, 4, 1, 1);
   Add_Edge (G, 5, 1, 7);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 9 and then Path (1) = 3 and then Path (2) = 1,
          "in-star heaviest");

   ------------------------------------------------------------------
   Section ("21. Clear rebuild");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Clear (G, 2);
   Check (Vertex_Count (G) = 2, "rebuild N");
   Check (Edge_Count (G) = 0, "rebuild E=0");
   Add_Edge (G, 1, 2, 5);
   Check (DAG_Longest_Weight (G) = 5, "rebuild weight");

   ------------------------------------------------------------------
   Section ("22. Many unit checks on small DAGs");
   ------------------------------------------------------------------
   for N in 1 .. 8 loop
      Clear (G, N);
      for I in 1 .. N - 1 loop
         Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), I);
      end loop;
      DAG_Longest_Path (G, Path, Len, Wgt, Status);
      declare
         Expect : Distance_Value := 0;
      begin
         for I in 1 .. N - 1 loop
            Expect := Expect + Distance_Value (I);
         end loop;
         Check (Status = Success and then Wgt = Expect,
                "chainN" & Integer'Image (N));
         Check (Len = N, "chainN len" & Integer'Image (N));
      end;
      Exact_Simple_Path (G, Path, Len, Wgt);
      Check (Len = N, "exact chainN" & Integer'Image (N));
   end loop;

   ------------------------------------------------------------------
   Section ("23. Branching DAG hand grid");
   ------------------------------------------------------------------
   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 2, 5, 1);
   Add_Edge (G, 3, 5, 1);
   Add_Edge (G, 3, 6, 1);
   Add_Edge (G, 4, 6, 1);
   Add_Edge (G, 5, 6, 1);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 3, "grid hops 3");
   Check (Len = 4, "grid 4 verts");
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 3 and then Len = 4, "grid exact");

   ------------------------------------------------------------------
   Section ("24. Exact on cyclic (still well-defined)");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 1, 1);
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 2 and then Len = 3, "cycle exact simple len 2 edges");
   --  no vertex repeat ⇒ cannot take all 3 cycle edges
   Exact_Simple_Path (G, 1, 1, Path, Len, Wgt, Found);
   Check (Found and then Len = 1 and then Wgt = 0,
          "exact ST same only singleton (no positive cycle walk)");

   ------------------------------------------------------------------
   Section ("25. DAG_Longest_From Status Success + Infinity");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 3, 4, 5);
   DAG_Longest_From (G, 1, Dist, Prev, Status);
   Check (Status = Success, "comp From ok");
   Check (Dist (2) = 2, "comp Dist2");
   Check (Dist (3) = Infinity, "comp Dist3 Inf");
   Check (Dist (4) = Infinity, "comp Dist4 Inf");

   ------------------------------------------------------------------
   Section ("26. Wikipedia-ish DP ending lengths");
   ------------------------------------------------------------------
   --  Dist ending at v after global DP equals longest path weight to v
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 4);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 2, 4, 5);
   Add_Edge (G, 3, 4, 1);
   DAG_Longest_From (G, 1, Dist, Prev, Status);
   Check (Dist (1) = 0, "wiki Dist1");
   Check (Dist (2) = 1, "wiki Dist2");
   Check (Dist (3) = 4, "wiki Dist3 max(1+1,4)=4");
   Check (Dist (4) = 6, "wiki Dist4 max(1+5,4+1)=6");
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 6, "wiki global 6");

   ------------------------------------------------------------------
   Section ("27. Two-edge choices / lexicographic tie");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 3, 5);
   DAG_Longest_Path (G, Path, Len, Wgt, Status);
   Check (Wgt = 5 and then Len = 2, "tie weight 5");
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 5 and then Path (1) = 1, "tie prefers start 1");

   ------------------------------------------------------------------
   Section ("28. Larger Exact N=8 path");
   ------------------------------------------------------------------
   Clear (G, 8);
   for I in 1 .. 7 loop
      Add_Edge (G, Vertex_Id (I), Vertex_Id (I + 1), 1);
   end loop;
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 7 and then Len = 8, "exact N8 path");
   Exact_Simple_Path (G, 3, 7, Path, Len, Wgt, Found);
   Check (Found and then Wgt = 4 and then Len = 5, "exact 3→7");

   ------------------------------------------------------------------
   Section ("29. Capacity constants");
   ------------------------------------------------------------------
   Check (Nat (Max_Vertices) >= 64, "Max_Vertices >= 64");
   Check (Nat (Max_Exact_Vertices) >= 16
            and then Nat (Max_Exact_Vertices) <= 20, "Exact cap 16..20");
   Check (Nat (Max_Edges) >= 1000, "Max_Edges large");
   Check (Nat (Max_Vertices) = Max_Vertices, "Nat helper");
   Check (Int (0) = 0, "Int helper");

   ------------------------------------------------------------------
   Section ("30. More DAG hand cases");
   ------------------------------------------------------------------
   Clear (G, 1);
   Add_Edge (G, 1, 1, 0);
   Check (not Is_Acyclic (G), "zero self-loop still cycle");

   Clear (G, 5);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 2);
   Add_Edge (G, 1, 4, 1);
   Add_Edge (G, 4, 5, 1);
   Add_Edge (G, 5, 3, 10);
   --  1-2-3 = 4; 1-4-5-3 = 12
   Check (DAG_Longest_Weight (G) = 12, "bypass heavy 12");
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 12 and then Len = 4, "bypass exact");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 3, 4, 1);
   DAG_Longest_From (G, 1, Dist, Prev, Status);
   Check (Dist (3) = 2, "two-hop to 3");
   Check (Dist (4) = 3, "three-hop to 4");

   ------------------------------------------------------------------
   Section ("31. Exact From vs global");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 4, 3, 100);
   Exact_Simple_Path_From (G, 1, Path, Len, Wgt);
   Check (Wgt = 2 and then Path (1) = 1, "From1 ignores 4");
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (Wgt = 100 and then Path (1) = 4, "global uses 4-3");

   ------------------------------------------------------------------
   Section ("32. Agreement matrix small");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 3, 4, 5);
   Add_Edge (G, 1, 4, 1);
   D := DAG_Longest_Weight (G);
   Exact_Simple_Path (G, Path, Len, Wgt);
   Check (D = Wgt and then D = 15, "matrix agree 15");
   Exact_Simple_Path (G, 1, 4, Path, Len, Wgt, Found);
   Check (Found and then Wgt = 15, "ST agree 15");

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
