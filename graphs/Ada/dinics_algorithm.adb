--  Dinics_Algorithm body — level-graph BFS + blocking-flow DFS max-flow
--  on an integer residual graph; min-cut via residual reachability
--  (Dinic / Dinitz).

pragma Ada_2022;

package body Dinics_Algorithm
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Graph construction
   -------------------------------------------------------------------------

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N := Vertex_Count;
      G.M := 0;
      G.Pool := 0;
      for V in Vertex_Id loop
         G.Head (V) := 0;
      end loop;
   end Clear;

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Capacity : Integer)
   is
      Fwd, Bwd : Residual_Index;
   begin
      if Capacity < 0 then
         raise Invalid_Argument;
      end if;
      if G.N = 0
        or else Natural (From) > G.N
        or else Natural (To) > G.N
      then
         raise Invalid_Argument;
      end if;
      if G.M = Max_Edges then
         raise Invalid_Argument;
      end if;

      --  Forward residual arc From → To with residual = Capacity.
      G.Pool := G.Pool + 1;
      Fwd := Residual_Index (G.Pool);
      G.To (Fwd) := To;
      G.Cap (Fwd) := Capacity_Type (Capacity);
      G.Next (Fwd) := G.Head (From);
      G.Head (From) := Natural (Fwd);

      --  Reverse residual arc To → From with residual 0.
      G.Pool := G.Pool + 1;
      Bwd := Residual_Index (G.Pool);
      G.To (Bwd) := From;
      G.Cap (Bwd) := 0;
      G.Next (Bwd) := G.Head (To);
      G.Head (To) := Natural (Bwd);

      G.Rev (Fwd) := Bwd;
      G.Rev (Bwd) := Fwd;

      G.M := G.M + 1;
      G.User_From (G.M) := From;
      G.User_To (G.M) := To;
      G.User_Cap (G.M) := Capacity_Type (Capacity);
      G.User_Fwd (G.M) := Fwd;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.M);
   end Edge_Count;

   -------------------------------------------------------------------------
   -- Shared helpers
   -------------------------------------------------------------------------

   procedure Validate_ST
     (G : Graph; Source, Sink : Vertex_Id)
   is
   begin
      if G.N = 0
        or else Natural (Source) > G.N
        or else Natural (Sink) > G.N
      then
         raise Invalid_Argument;
      end if;
   end Validate_ST;

   procedure Validate_Reach_Bounds
     (N : Natural; First, Last : Vertex_Id)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if First /= 1 or else Natural (Last) < N then
         raise Invalid_Argument;
      end if;
   end Validate_Reach_Bounds;

   procedure Validate_Edge_Index (G : Graph; Index : Positive) is
   begin
      if Index > Natural (G.M) then
         raise Invalid_Argument;
      end if;
   end Validate_Edge_Index;

   --  Restore residual capacities from original user edges (zero flow).
   procedure Reset_Residual (G : in out Graph) is
      Fwd, Bwd : Residual_Index;
   begin
      for I in 1 .. G.M loop
         Fwd := G.User_Fwd (I);
         Bwd := G.Rev (Fwd);
         G.Cap (Fwd) := G.User_Cap (I);
         G.Cap (Bwd) := 0;
      end loop;
   end Reset_Residual;

   function Min_Flow (A, B : Flow_Value) return Flow_Value is
   begin
      if A < B then
         return A;
      else
         return B;
      end if;
   end Min_Flow;

   -------------------------------------------------------------------------
   -- Dinic: BFS level graph + DFS blocking flow
   -------------------------------------------------------------------------

   function Max_Flow
     (G : in out Graph; Source, Sink : Vertex_Id) return Flow_Value
   is
      Total : Flow_Value := 0;

      --  Level(V) = hop distance from Source in residual graph, or -1.
      Level : array (Vertex_Id) of Integer;
      --  Current residual-edge cursor for DFS (0 = exhausted).
      Ptr   : array (Vertex_Id) of Natural;

      Queue : array (1 .. Max_Vertices) of Vertex_Id;
      Q_Head, Q_Tail : Natural;

      function Build_Level_Graph return Boolean is
         U, V : Vertex_Id;
         E    : Natural;
      begin
         for X in 1 .. Vertex_Id (G.N) loop
            Level (X) := -1;
         end loop;
         Level (Source) := 0;
         Q_Head := 1;
         Q_Tail := 1;
         Queue (1) := Source;

         while Q_Head <= Q_Tail loop
            U := Queue (Q_Head);
            Q_Head := Q_Head + 1;
            E := G.Head (U);
            while E /= 0 loop
               V := G.To (Residual_Index (E));
               if Level (V) < 0 and then G.Cap (Residual_Index (E)) > 0 then
                  Level (V) := Level (U) + 1;
                  Q_Tail := Q_Tail + 1;
                  Queue (Q_Tail) := V;
               end if;
               E := G.Next (Residual_Index (E));
            end loop;
         end loop;

         return Level (Sink) >= 0;
      end Build_Level_Graph;

      --  DFS: push along one Source↝Sink level path (current-edge ptrs).
      function Send_Flow
        (U : Vertex_Id; Limit : Flow_Value) return Flow_Value
      is
         E      : Natural;
         V      : Vertex_Id;
         Cap    : Capacity_Type;
         Pushed : Flow_Value;
         Ei, R  : Residual_Index;
      begin
         if U = Sink or else Limit = 0 then
            return Limit;
         end if;

         while Ptr (U) /= 0 loop
            E := Ptr (U);
            Ei := Residual_Index (E);
            V := G.To (Ei);
            Cap := G.Cap (Ei);

            if Cap > 0 and then Level (V) = Level (U) + 1 then
               Pushed := Send_Flow
                 (V, Min_Flow (Limit, Flow_Value (Cap)));
               if Pushed > 0 then
                  R := G.Rev (Ei);
                  G.Cap (Ei) :=
                    Capacity_Type (Flow_Value (G.Cap (Ei)) - Pushed);
                  G.Cap (R) :=
                    Capacity_Type (Flow_Value (G.Cap (R)) + Pushed);
                  return Pushed;
               end if;
            end if;

            --  Dead / saturated / wrong-level edge: advance cursor.
            Ptr (U) := G.Next (Ei);
         end loop;

         return 0;
      end Send_Flow;

      Phase_Push : Flow_Value;
   begin
      Validate_ST (G, Source, Sink);
      if Source = Sink then
         Reset_Residual (G);
         return 0;
      end if;

      Reset_Residual (G);

      loop
         exit when not Build_Level_Graph;

         --  Reset current-edge pointers to adjacency heads.
         for X in 1 .. Vertex_Id (G.N) loop
            Ptr (X) := G.Head (X);
         end loop;

         --  Blocking flow: repeatedly DFS until no more level path.
         loop
            Phase_Push := Send_Flow (Source, Flow_Value'Last);
            exit when Phase_Push = 0;
            Total := Total + Phase_Push;
         end loop;
      end loop;

      return Total;
   end Max_Flow;

   -------------------------------------------------------------------------
   -- Min-cut partition (residual reachability from Source)
   -------------------------------------------------------------------------

   procedure Min_Cut_Partition
     (G      : Graph;
      Source : Vertex_Id;
      In_S   : out Reachability_Array)
   is
      Queue : array (1 .. Max_Vertices) of Vertex_Id;
      Q_Head, Q_Tail : Natural;
      U, V  : Vertex_Id;
      E     : Natural;
   begin
      if G.N = 0 or else Natural (Source) > G.N then
         raise Invalid_Argument;
      end if;
      Validate_Reach_Bounds (G.N, In_S'First, In_S'Last);

      for X in In_S'Range loop
         In_S (X) := False;
      end loop;

      Q_Head := 1;
      Q_Tail := 1;
      Queue (1) := Source;
      In_S (Source) := True;

      while Q_Head <= Q_Tail loop
         U := Queue (Q_Head);
         Q_Head := Q_Head + 1;
         E := G.Head (U);
         while E /= 0 loop
            V := G.To (Residual_Index (E));
            if not In_S (V) and then G.Cap (Residual_Index (E)) > 0 then
               In_S (V) := True;
               Q_Tail := Q_Tail + 1;
               Queue (Q_Tail) := V;
            end if;
            E := G.Next (Residual_Index (E));
         end loop;
      end loop;
   end Min_Cut_Partition;

   -------------------------------------------------------------------------
   -- Edge inspection
   -------------------------------------------------------------------------

   function Edge_From (G : Graph; Index : Positive) return Vertex_Id is
   begin
      Validate_Edge_Index (G, Index);
      return G.User_From (User_Edge_Index (Index));
   end Edge_From;

   function Edge_To (G : Graph; Index : Positive) return Vertex_Id is
   begin
      Validate_Edge_Index (G, Index);
      return G.User_To (User_Edge_Index (Index));
   end Edge_To;

   function Edge_Capacity
     (G : Graph; Index : Positive) return Capacity_Type
   is
   begin
      Validate_Edge_Index (G, Index);
      return G.User_Cap (User_Edge_Index (Index));
   end Edge_Capacity;

   function Edge_Flow (G : Graph; Index : Positive) return Flow_Value is
      Fwd : Residual_Index;
      Orig, Resid : Capacity_Type;
   begin
      Validate_Edge_Index (G, Index);
      Fwd := G.User_Fwd (User_Edge_Index (Index));
      Orig := G.User_Cap (User_Edge_Index (Index));
      Resid := G.Cap (Fwd);
      --  Flow on forward edge = original capacity − residual.
      return Flow_Value (Orig) - Flow_Value (Resid);
   end Edge_Flow;

   function Cut_Capacity
     (G : Graph; In_S : Reachability_Array) return Flow_Value
   is
      Total : Flow_Value := 0;
      F, T  : Vertex_Id;
   begin
      Validate_Reach_Bounds (G.N, In_S'First, In_S'Last);
      for I in 1 .. G.M loop
         F := G.User_From (I);
         T := G.User_To (I);
         if In_S (F) and then not In_S (T) then
            Total := Total + Flow_Value (G.User_Cap (I));
         end if;
      end loop;
      return Total;
   end Cut_Capacity;

end Dinics_Algorithm;
