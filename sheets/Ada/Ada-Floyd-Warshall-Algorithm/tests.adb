--  Standalone test suite for Floyd_Warshall_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Floyd_Warshall_Algorithm; use Floyd_Warshall_Algorithm;

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

   function Raising_Next_Neg (G : Graph) return Boolean is
      N    : constant Natural := Vertex_Count (G);
      Dist : Dist_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
      Next : Next_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
   begin
      All_Pairs (G, Dist, Next);
      return False;
   exception
      when Negative_Cycle_Error =>
         return True;
   end Raising_Next_Neg;

   function Raising_Prev_Neg (G : Graph) return Boolean is
      N    : constant Natural := Vertex_Count (G);
      Dist : Dist_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
      Prev : Prev_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
   begin
      All_Pairs (G, Dist, Prev);
      return False;
   exception
      when Negative_Cycle_Error =>
         return True;
   end Raising_Prev_Neg;

   function Init_Dist_Raises (N : Natural) return Boolean is
      Dist : Dist_Matrix (1 .. 2, 1 .. 2);
   begin
      Init_Dist (Dist, N);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Init_Dist_Raises;

   function Put_Edge_Raises
     (Dist : in out Dist_Matrix; F, T : Vertex_Id; W : Integer)
      return Boolean
   is
   begin
      Put_Edge (Dist, F, T, W);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Put_Edge_Raises;

   function Path_Next_Raises
     (Next : Next_Matrix; S, T : Vertex_Id) return Boolean
   is
      Path : Path_Array (1 .. Max_Vertices);
      Len  : Natural;
      Ok   : Boolean;
   begin
      Ok := Reconstruct_Path (Next, S, T, Path, Len);
      pragma Unreferenced (Ok, Len);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Path_Next_Raises;

   G     : Graph;
   Dist  : Dist_Matrix (1 .. 16, 1 .. 16);
   Next  : Next_Matrix (1 .. 16, 1 .. 16);
   Prev  : Prev_Matrix (1 .. 16, 1 .. 16);
   Path  : Path_Array (1 .. 16);
   Len   : Natural;
   St    : Run_Status;
   Ok    : Boolean;
   D     : Distance_Value;

begin
   ------------------------------------------------------------------
   Section ("1. Empty / capacity / Invalid_Argument");
   ------------------------------------------------------------------
   Check (Clear_Raises (Max_Vertices + 1), "Clear > Max_Vertices");
   Clear (G, 0);
   Check (Vertex_Count (G) = 0, "empty Vertex_Count");
   Check (Edge_Count (G) = 0, "empty Edge_Count");
   Check (AP_Raises_Empty, "All_Pairs empty raises");
   Check (Init_Dist_Raises (0), "Init_Dist N=0 raises");
   Clear (G, 3);
   Check (Add_Raises (G, 4, 1, 1), "Add_Edge From out of range");
   Check (Add_Raises (G, 1, 4, 1), "Add_Edge To out of range");
   Check (Add_Raises (G, 1, 2, Integer (Weight_Type'Last) + 1),
          "Add_Edge weight too large");
   Check (Add_Raises (G, 1, 2, Integer (Weight_Type'First) - 1),
          "Add_Edge weight too small");
   Check (AP_Raises_Bounds (3, 2), "Dist too small raises");
   Clear (G, 2);
   Check (Dist_Raises (G, 3, 1), "Distance Source OOR");
   Check (Dist_Raises (G, 1, 3), "Distance Target OOR");

   ------------------------------------------------------------------
   Section ("2. Single vertex");
   ------------------------------------------------------------------
   Clear (G, 1);
   Check (Vertex_Count (G) = 1, "single N=1");
   Check (Edge_Count (G) = 0, "single no edges");
   All_Pairs (G, Dist, St);
   Check (St = Success, "single Success");
   Check (Dist (1, 1) = 0, "single Dist(1,1)=0");
   Check (not Has_Negative_Cycle (G), "single no neg cycle");
   Check (Distance (G, 1, 1) = 0, "Distance self 0");
   All_Pairs (G, Dist, Next, St);
   Check (Next (1, 1) = 1, "Next(1,1)=1");
   Ok := Reconstruct_Path (Next, 1, 1, Path, Len);
   Check (Ok and then Len = 1 and then Path (1) = 1, "path self Next");

   ------------------------------------------------------------------
   Section ("3. Positive self-loop / negative self-loop");
   ------------------------------------------------------------------
   Clear (G, 1);
   Add_Edge (G, 1, 1, 5);
   All_Pairs (G, Dist, St);
   Check (St = Success, "pos self-loop Success");
   Check (Dist (1, 1) = 0, "pos self-loop diagonal stays 0");
   Clear (G, 1);
   Add_Edge (G, 1, 1, -1);
   All_Pairs (G, Dist, St);
   Check (St = Negative_Cycle, "neg self-loop detected");
   Check (Has_Negative_Cycle (G), "Has_Negative_Cycle self-loop");
   Check (Has_Negative_Cycle (Dist, 1), "Has_Negative_Cycle on Dist");
   Check (Dist_Neg_Cycle (G, 1, 1), "Distance raises on neg self-loop");

   ------------------------------------------------------------------
   Section ("4. Two vertices");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 7);
   Floyd_Warshall (G, Dist, St);
   Check (St = Success, "two-vertex Success");
   Check (Dist (1, 2) = 7, "1→2 = 7");
   Check (Dist (2, 1) = Infinity, "2→1 unreachable");
   Check (Dist (1, 1) = 0 and then Dist (2, 2) = 0, "diagonals 0");
   Check (Distance (G, 1, 2) = 7, "Distance 1→2");
   Check (Distance (G, 2, 1) = Infinity, "Distance 2→1 Inf");
   Clear (G, 2);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 2, 1, 4);
   All_Pairs (G, Dist, St);
   Check (Dist (1, 2) = 3 and then Dist (2, 1) = 4, "bidirected");
   Check (Dist (1, 1) = 0, "no cycle through positive");

   ------------------------------------------------------------------
   Section ("5. Zero weights");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   All_Pairs (G, Dist, St);
   Check (St = Success, "zero Success");
   Check (Dist (1, 2) = 0, "zero 1→2");
   Check (Dist (1, 3) = 0, "zero 1→3");
   Check (Dist (2, 3) = 0, "zero 2→3");

   ------------------------------------------------------------------
   Section ("6. Negative edges without cycle");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, -2);
   Add_Edge (G, 2, 3, -3);
   Add_Edge (G, 1, 3, 10);
   All_Pairs (G, Dist, St);
   Check (St = Success, "neg edges Success");
   Check (Dist (1, 3) = -5, "bypass 10 via -2+-3");
   Check (Dist (1, 2) = -2, "1→2 = -2");
   Check (not Has_Negative_Cycle (G), "no cycle with neg edges");

   ------------------------------------------------------------------
   Section ("7. Negative 2-cycle / 3-cycle");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 1, -2);
   All_Pairs (G, Dist, St);
   Check (St = Negative_Cycle, "2-cycle neg Status");
   Check (Has_Negative_Cycle (G), "2-cycle Has_Negative_Cycle");
   Check (Raising_Next_Neg (G), "raising Next on 2-cycle");
   Check (Raising_Prev_Neg (G), "raising Prev on 2-cycle");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 1, -3);
   All_Pairs (G, Dist, St);
   Check (St = Negative_Cycle, "3-cycle neg Status");
   Check (Has_Negative_Cycle (G), "3-cycle Has");
   Check (Dist_Neg_Cycle (G, 1, 2), "Distance raises on 3-cycle");

   ------------------------------------------------------------------
   Section ("8. Unreachable = Infinity");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 3, 4, 2);
   All_Pairs (G, Dist, St);
   Check (St = Success, "disconnected Success");
   Check (Dist (1, 2) = 1, "comp A");
   Check (Dist (3, 4) = 2, "comp B");
   Check (Dist (1, 3) = Infinity, "1→3 Inf");
   Check (Dist (1, 4) = Infinity, "1→4 Inf");
   Check (Dist (2, 1) = Infinity, "2→1 Inf");
   Check (Dist (4, 3) = Infinity, "4→3 Inf");
   Check (Dist_Val (Infinity) = Dist_Val (Distance_Value'Last),
          "Infinity is Last");

   ------------------------------------------------------------------
   Section ("9. Classic Wikipedia / CLRS-style example");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 3, -2);
   Add_Edge (G, 3, 4, 2);
   Add_Edge (G, 4, 2, -1);
   Add_Edge (G, 2, 1, 4);
   Add_Edge (G, 2, 3, 3);
   All_Pairs (G, Dist, Next, Prev, St);
   Check (St = Success, "wiki Success");
   Check (Dist (1, 1) = 0, "wiki d11");
   Check (Dist (1, 2) = -1, "wiki d12");
   Check (Dist (1, 3) = -2, "wiki d13");
   Check (Dist (1, 4) = 0, "wiki d14");
   Check (Dist (2, 1) = 4, "wiki d21");
   Check (Dist (2, 2) = 0, "wiki d22");
   Check (Dist (2, 3) = 2, "wiki d23");
   Check (Dist (2, 4) = 4, "wiki d24");
   Check (Dist (3, 1) = 5, "wiki d31");
   Check (Dist (3, 2) = 1, "wiki d32");
   Check (Dist (3, 3) = 0, "wiki d33");
   Check (Dist (3, 4) = 2, "wiki d34");
   Check (Dist (4, 1) = 3, "wiki d41");
   Check (Dist (4, 2) = -1, "wiki d42");
   Check (Dist (4, 3) = 1, "wiki d43");
   Check (Dist (4, 4) = 0, "wiki d44");

   ------------------------------------------------------------------
   Section ("10. Path reconstruction (Next and Prev)");
   ------------------------------------------------------------------
   Ok := Reconstruct_Path (Next, 1, 2, Path, Len);
   Check (Ok, "Next path 1→2 exists");
   Check (Len >= 2 and then Path (1) = 1 and then Path (Len) = 2,
          "Next path ends");
   Check (Len = 4, "Next path 1→2 length 4");
   if Len = 4 then
      Check (Path (2) = 3 and then Path (3) = 4, "Next path 1-3-4-2");
   else
      Check (False, "Next path 1-3-4-2");
   end if;

   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (Ok and then Len = 4, "Prev path 1→2 length 4");
   if Len = 4 then
      Check (Path (1) = 1 and then Path (2) = 3
             and then Path (3) = 4 and then Path (4) = 2,
             "Prev path 1-3-4-2");
   else
      Check (False, "Prev path 1-3-4-2");
   end if;

   Ok := Reconstruct_Path (Next, 2, 4, Path, Len);
   Check (Ok and then Path (1) = 2 and then Path (Len) = 4,
          "Next 2→4");
   Check (Dist (2, 4) = 4, "dist agrees 2→4");

   Ok := Reconstruct_Path (Next, 1, 1, Path, Len);
   Check (Ok and then Len = 1, "Next trivial self");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   All_Pairs (G, Dist, Next, St);
   Ok := Reconstruct_Path (Next, 1, 3, Path, Len);
   Check (not Ok and then Len = 0, "Next unreachable False");

   ------------------------------------------------------------------
   Section ("11. Direct Dist matrix init (no Graph edges API)");
   ------------------------------------------------------------------
   Init_Dist (Dist, 3);
   Check (Dist (1, 1) = 0 and then Dist (2, 3) = Infinity,
          "Init_Dist diagonal/Inf");
   Put_Edge (Dist, 1, 2, 5);
   Put_Edge (Dist, 2, 3, -1);
   Put_Edge (Dist, 1, 3, 100);
   Init_Next_From_Dist (Dist, Next, 3);
   Floyd_Warshall (Dist, Next, 3, St);
   Check (St = Success, "in-place Success");
   Check (Dist (1, 3) = 4, "in-place 1→3 via 2 = 4");
   Ok := Reconstruct_Path (Next, 1, 3, Path, Len);
   Check (Ok and then Len = 3 and then Path (2) = 2, "in-place Next path");

   Init_Dist (Dist, 3);
   Put_Edge (Dist, 1, 2, 2);
   Put_Edge (Dist, 2, 3, 2);
   Init_Prev_From_Dist (Dist, Prev, 3);
   Floyd_Warshall (Dist, Prev, 3, St);
   Check (Dist (1, 3) = 4, "in-place Prev Dist");
   Ok := Reconstruct_Path (Prev, 1, 3, Path, Len);
   Check (Ok and then Len = 3, "in-place Prev path");

   Init_Dist (Dist, 2);
   Put_Edge (Dist, 1, 2, 1);
   Put_Edge (Dist, 2, 1, -2);
   Floyd_Warshall (Dist, 2, St);
   Check (St = Negative_Cycle, "in-place detects cycle");

   Check (Put_Edge_Raises (Dist, 1, 2, Integer (Weight_Type'Last) + 1),
          "Put_Edge bad weight");

   ------------------------------------------------------------------
   Section ("12. Init_Dist from Graph");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 9);
   Add_Edge (G, 2, 3, 1);
   Init_Dist (G, Dist);
   Check (Dist (1, 2) = 9, "Init from G edge");
   Check (Dist (1, 3) = Infinity, "Init from G no transitive yet");
   Check (Dist (2, 2) = 0, "Init from G diagonal");
   Check (Has_Edge (G, 1, 2), "Has_Edge true");
   Check (not Has_Edge (G, 1, 3), "Has_Edge false");
   Check (Edge_Weight (G, 1, 2) = 9, "Edge_Weight");
   Check (Edge_Weight (G, 1, 3) = Infinity, "Edge_Weight absent");

   ------------------------------------------------------------------
   Section ("13. Parallel edges keep minimum");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 2, 7);
   Check (Edge_Count (G) = 1, "parallels: one distinct pair");
   Check (Edge_Weight (G, 1, 2) = 3, "parallels: min weight 3");
   Check (Distance (G, 1, 2) = 3, "parallels Distance");

   ------------------------------------------------------------------
   Section ("14. Chain / diamond / shortcut");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 4, 5, 1);
   All_Pairs (G, Dist, St);
   Check (Dist (1, 5) = 4, "chain 1→5 = 4");
   Check (Dist (2, 4) = 2, "chain 2→4 = 2");

   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 5);
   Add_Edge (G, 2, 4, 1);
   Add_Edge (G, 3, 4, 1);
   Add_Edge (G, 1, 4, 100);
   All_Pairs (G, Dist, St);
   Check (Dist (1, 4) = 2, "diamond shortcut 1→4 = 2");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 10);
   Add_Edge (G, 1, 3, 1);
   Add_Edge (G, 3, 2, 1);
   All_Pairs (G, Dist, Prev, St);
   Check (Dist (1, 2) = 2, "shortcut via 3");
   Ok := Reconstruct_Path (Prev, 1, 2, Path, Len);
   Check (Ok and then Len = 3 and then Path (2) = 3, "shortcut path");

   ------------------------------------------------------------------
   Section ("15. Complete digraph / star / layered");
   ------------------------------------------------------------------
   Clear (G, 4);
   for I in Vertex_Id range 1 .. 4 loop
      for J in Vertex_Id range 1 .. 4 loop
         if I /= J then
            Add_Edge (G, I, J, Integer (I) + Integer (J));
         end if;
      end loop;
   end loop;
   Check (Edge_Count (G) = 12, "K4 directed edges");
   All_Pairs (G, Dist, St);
   Check (St = Success, "complete Success");
   Check (Dist (1, 2) = 3, "complete direct 1→2");
   Check (Dist (1, 4) = 5, "complete 1→4");

   Clear (G, 5);
   for J in Vertex_Id range 2 .. 5 loop
      Add_Edge (G, 1, J, Integer (J));
   end loop;
   All_Pairs (G, Dist, St);
   Check (Dist (1, 5) = 5, "star 1→5");
   Check (Dist (2, 3) = Infinity, "star leaves disconnected");

   Clear (G, 6);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 3, 2);
   Add_Edge (G, 2, 4, 3);
   Add_Edge (G, 2, 5, 4);
   Add_Edge (G, 3, 5, 1);
   Add_Edge (G, 3, 6, 7);
   Add_Edge (G, 5, 6, 1);
   All_Pairs (G, Dist, St);
   Check (Dist (1, 6) = 4, "layered 1→6 = 4");
   Check (Dist (1, 4) = 4, "layered 1→4 = 4");

   ------------------------------------------------------------------
   Section ("16. Aliases Floyd_Warshall = All_Pairs");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 2);
   Add_Edge (G, 2, 3, 3);
   Floyd_Warshall (G, Dist, St);
   Check (Dist (1, 3) = 5, "FW alias Dist");
   Floyd_Warshall (G, Dist, Next, St);
   Check (St = Success, "FW Next alias");
   Floyd_Warshall (G, Dist, Prev, St);
   Check (St = Success, "FW Prev alias");
   declare
      Dn : Dist_Matrix (1 .. 3, 1 .. 3);
      Nn : Next_Matrix (1 .. 3, 1 .. 3);
      Pn : Prev_Matrix (1 .. 3, 1 .. 3);
   begin
      Floyd_Warshall (G, Dn, Nn);
      Check (Dn (1, 3) = 5, "raising FW Next ok");
      Floyd_Warshall (G, Dn, Pn);
      Check (Dn (1, 3) = 5, "raising FW Prev ok");
   end;

   ------------------------------------------------------------------
   Section ("17. Clear / rebuild");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Clear (G, 2);
   Check (Vertex_Count (G) = 2, "rebuild N");
   Check (Edge_Count (G) = 0, "rebuild cleared edges");
   Add_Edge (G, 2, 1, -5);
   Check (Distance (G, 2, 1) = -5, "rebuild Distance");

   ------------------------------------------------------------------
   Section ("18. Max_Vertices boundary");
   ------------------------------------------------------------------
   Clear (G, Max_Vertices);
   Check (Vertex_Count (G) = Max_Vertices, "Max_Vertices Clear");
   Add_Edge (G, 1, Vertex_Id (Max_Vertices), 42);
   Check (Edge_Count (G) = 1, "Max_Vertices one edge");
   Check (Has_Edge (G, 1, Vertex_Id (Max_Vertices)), "Max_Vertices Has");
   declare
      Big : Dist_Matrix (1 .. Vertex_Id (Max_Vertices),
                         1 .. Vertex_Id (Max_Vertices));
      Stb : Run_Status;
   begin
      All_Pairs (G, Big, Stb);
      Check (Stb = Success, "Max_Vertices APSP Success");
      Check (Big (1, Vertex_Id (Max_Vertices)) = 42, "Max_Vertices dist");
      Check (Big (1, 1) = 0, "Max_Vertices diagonal");
      Check (Big (2, 3) = Infinity, "Max_Vertices Inf interior");
   end;

   ------------------------------------------------------------------
   Section ("19. Path Invalid_Argument / Prev_Array");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   declare
      Dn : Dist_Matrix (1 .. 3, 1 .. 3);
      Nn : Next_Matrix (1 .. 3, 1 .. 3);
      Pn : Prev_Matrix (1 .. 3, 1 .. 3);
      St3 : Run_Status;
   begin
      All_Pairs (G, Dn, Nn, Pn, St3);
      pragma Unreferenced (St3, Pn);
      Check (Path_Next_Raises (Nn, 4, 1), "Reconstruct Next Source OOR");
      --  Also fill outer Next/Prev for subsequent Prev_Array checks.
      All_Pairs (G, Dist, Next, Prev, St);
   end;
   declare
      Row : Prev_Array (1 .. 16);
      P2  : Path_Array (1 .. 16);
      L2  : Natural;
      Ok2 : Boolean;
   begin
      for V in Vertex_Id range 1 .. 16 loop
         Row (V) := Prev (1, V);
      end loop;
      Ok2 := Reconstruct_Path (Row, 1, 3, P2, L2);
      Check (Ok2 and then L2 = 3, "Prev_Array path 1→3");
      Check (P2 (1) = 1 and then P2 (2) = 2 and then P2 (3) = 3,
             "Prev_Array vertices");
   end;

   ------------------------------------------------------------------
   Section ("20. Mixed signs DAG");
   ------------------------------------------------------------------
   Clear (G, 5);
   Add_Edge (G, 1, 2, 3);
   Add_Edge (G, 1, 3, -1);
   Add_Edge (G, 2, 4, 2);
   Add_Edge (G, 3, 4, 4);
   Add_Edge (G, 4, 5, -2);
   Add_Edge (G, 3, 5, 10);
   All_Pairs (G, Dist, St);
   Check (St = Success, "DAG Success");
   Check (Dist (1, 4) = 3, "DAG 1→4 = 3");
   Check (Dist (1, 5) = 1, "DAG 1→5 = 1");
   Check (Dist (2, 5) = 0, "DAG 2→5 = 0");

   ------------------------------------------------------------------
   Section ("21. Grid 3x3 (row-major ids 1..9)");
   ------------------------------------------------------------------
   Clear (G, 9);
   for R in 0 .. 2 loop
      for C in 0 .. 1 loop
         declare
            U : constant Vertex_Id := Vertex_Id (R * 3 + C + 1);
            V : constant Vertex_Id := Vertex_Id (R * 3 + C + 2);
         begin
            Add_Edge (G, U, V, 1);
         end;
      end loop;
   end loop;
   for R in 0 .. 1 loop
      for C in 0 .. 2 loop
         declare
            U : constant Vertex_Id := Vertex_Id (R * 3 + C + 1);
            V : constant Vertex_Id := Vertex_Id ((R + 1) * 3 + C + 1);
         begin
            Add_Edge (G, U, V, 1);
         end;
      end loop;
   end loop;
   All_Pairs (G, Dist, Next, St);
   Check (St = Success, "grid Success");
   Check (Dist (1, 9) = 4, "grid corner 1→9 = 4");
   Check (Dist (1, 3) = 2, "grid row");
   Check (Dist (1, 7) = 2, "grid col");
   Ok := Reconstruct_Path (Next, 1, 9, Path, Len);
   Check (Ok and then Len = 5, "grid path len 5");

   ------------------------------------------------------------------
   Section ("22. Hand cases: known APSP matrix");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 4, 10);
   Add_Edge (G, 2, 3, 3);
   Add_Edge (G, 2, 4, 2);
   Add_Edge (G, 3, 4, 1);
   All_Pairs (G, Dist, St);
   Check (Dist (1, 2) = 5, "hand 12");
   Check (Dist (1, 3) = 8, "hand 13");
   Check (Dist (1, 4) = 7, "hand 14 via 2");
   Check (Dist (2, 3) = 3, "hand 23");
   Check (Dist (2, 4) = 2, "hand 24");
   Check (Dist (3, 4) = 1, "hand 34");
   Check (Dist (4, 1) = Infinity, "hand 41 Inf");

   ------------------------------------------------------------------
   Section ("23. Status vs raising agreement");
   ------------------------------------------------------------------
   Clear (G, 2);
   Add_Edge (G, 1, 2, -1);
   Add_Edge (G, 2, 1, -1);
   All_Pairs (G, Dist, Next, St);
   Check (St = Negative_Cycle, "status cycle");
   Check (Raising_Next_Neg (G), "raising agrees");
   Check (Has_Negative_Cycle (Dist, 2), "post-run diagonal probe");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 1);
   All_Pairs (G, Dist, Prev);
   Check (Dist (1, 2) = 1, "raising Prev success path");

   ------------------------------------------------------------------
   Section ("24. More Invalid_Argument / Infinity sentinel");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, -7);
   All_Pairs (G, Dist, St);
   Check (Dist (1, 2) < 0, "neg stored");
   Check (Dist (2, 3) = Infinity, "Inf sentinel");
   Check (Dist (3, 1) = Infinity, "Inf other");
   Check (Dist_Val (Infinity) > Dist_Val (0), "Infinity > 0");
   Check (Init_Dist_Raises (0), "Init_Dist 0 again");
   declare
      Tiny : Dist_Matrix (1 .. 1, 1 .. 1);
   begin
      Clear (G, 2);
      begin
         All_Pairs (G, Tiny, St);
         Check (False, "bounds Tiny should raise");
      exception
         when Invalid_Argument =>
            Check (True, "bounds Tiny raises");
      end;
   end;

   ------------------------------------------------------------------
   Section ("25. Telescoping / long chain distances");
   ------------------------------------------------------------------
   Clear (G, 10);
   for I in Vertex_Id range 1 .. 9 loop
      Add_Edge (G, I, Vertex_Id (Natural (I) + 1), Integer (I));
   end loop;
   All_Pairs (G, Dist, Prev, St);
   Check (St = Success, "long chain Success");
   Check (Dist (1, 10) = 45, "sum 1..9 = 45");
   Check (Dist (5, 8) = 5 + 6 + 7, "partial sum");
   Ok := Reconstruct_Path (Prev, 1, 10, Path, Len);
   Check (Ok and then Len = 10, "long path 10 verts");
   Check (Path (1) = 1 and then Path (10) = 10, "long path ends");

   ------------------------------------------------------------------
   Section ("26. Floyd_Warshall Graph+Next/Prev status overloads");
   ------------------------------------------------------------------
   Clear (G, 3);
   Add_Edge (G, 1, 2, 4);
   Add_Edge (G, 2, 3, -1);
   Floyd_Warshall (G, Dist, Next, St);
   Check (Dist (1, 3) = 3, "FW Next status dist");
   Floyd_Warshall (G, Dist, Prev, St);
   Check (Dist (1, 3) = 3, "FW Prev status dist");
   D := Distance (G, 1, 3);
   Check (D = 3, "Distance agrees");

   ------------------------------------------------------------------
   Section ("27. Extra hand cases for coverage");
   ------------------------------------------------------------------
   Clear (G, 1);
   Check (Edge_Count (G) = 0, "extra empty edges");
   Clear (G, 4);
   Add_Edge (G, 4, 1, 0);
   Add_Edge (G, 1, 2, 0);
   Add_Edge (G, 2, 3, 0);
   All_Pairs (G, Dist, St);
   Check (Dist (4, 3) = 0, "zero chain 4→3");
   Check (Dist (3, 4) = Infinity, "zero chain reverse Inf");

   Clear (G, 3);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 2, 1, 5);
   Add_Edge (G, 2, 3, 5);
   Add_Edge (G, 3, 2, 5);
   All_Pairs (G, Dist, St);
   Check (St = Success, "pos biclique Success");
   Check (Dist (1, 3) = 10, "pos biclique 1→3");

   Clear (G, 3);
   Add_Edge (G, 1, 2, -5);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 1, 3, -1);
   All_Pairs (G, Dist, St);
   Check (Dist (1, 3) = -4, "neg+pos min");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 1, 2, 5);
   Check (Edge_Weight (G, 1, 2) = 1, "looser parallel ignored");

   Clear (G, 2);
   Add_Edge (G, 1, 2, 5);
   Add_Edge (G, 1, 2, 1);
   Check (Edge_Weight (G, 1, 2) = 1, "tighter parallel wins");

   ------------------------------------------------------------------
   Section ("28. All_Pairs both Next and Prev");
   ------------------------------------------------------------------
   Clear (G, 4);
   Add_Edge (G, 1, 2, 1);
   Add_Edge (G, 2, 3, 1);
   Add_Edge (G, 3, 4, 1);
   All_Pairs (G, Dist, Next, Prev, St);
   Check (St = Success, "both matrices Success");
   Ok := Reconstruct_Path (Next, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "both Next path");
   Ok := Reconstruct_Path (Prev, 1, 4, Path, Len);
   Check (Ok and then Len = 4, "both Prev path");
   Check (Dist (1, 4) = 3, "both Dist");

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
