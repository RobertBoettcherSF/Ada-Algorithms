--  Flow_Networks body — network model + inline Edmonds–Karp (BFS) and
--  Dinic (level graph + blocking flow); min-cut via residual reachability.

pragma Ada_2022;

package body Flow_Networks
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Network construction
   -------------------------------------------------------------------------

   procedure Clear (N : in out Network; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      N.V := Vertex_Count;
      N.M := 0;
      N.Pool := 0;
      N.Src_Set := False;
      N.Snk_Set := False;
      for X in Vertex_Id loop
         N.Head (X) := 0;
      end loop;
   end Clear;

   procedure Add_Edge
     (N : in out Network; From, To : Vertex_Id; Capacity : Integer)
   is
      Fwd, Bwd : Residual_Index;
   begin
      if Capacity < 0 then
         raise Invalid_Argument;
      end if;
      if N.V = 0
        or else Natural (From) > N.V
        or else Natural (To) > N.V
      then
         raise Invalid_Argument;
      end if;
      if N.M = Max_Edges then
         raise Invalid_Argument;
      end if;

      --  Forward residual arc From → To with residual = Capacity.
      N.Pool := N.Pool + 1;
      Fwd := Residual_Index (N.Pool);
      N.To (Fwd) := To;
      N.Cap (Fwd) := Capacity_Type (Capacity);
      N.Next (Fwd) := N.Head (From);
      N.Head (From) := Natural (Fwd);

      --  Reverse residual arc To → From with residual 0.
      N.Pool := N.Pool + 1;
      Bwd := Residual_Index (N.Pool);
      N.To (Bwd) := From;
      N.Cap (Bwd) := 0;
      N.Next (Bwd) := N.Head (To);
      N.Head (To) := Natural (Bwd);

      N.Rev (Fwd) := Bwd;
      N.Rev (Bwd) := Fwd;

      N.M := N.M + 1;
      N.User_From (N.M) := From;
      N.User_To (N.M) := To;
      N.User_Cap (N.M) := Capacity_Type (Capacity);
      N.User_Fwd (N.M) := Fwd;
   end Add_Edge;

   function Vertex_Count (N : Network) return Natural is
   begin
      return N.V;
   end Vertex_Count;

   function Edge_Count (N : Network) return Natural is
   begin
      return Natural (N.M);
   end Edge_Count;

   -------------------------------------------------------------------------
   -- Source / Sink helpers
   -------------------------------------------------------------------------

   procedure Set_Source (N : in out Network; Source : Vertex_Id) is
   begin
      if N.V = 0 or else Natural (Source) > N.V then
         raise Invalid_Argument;
      end if;
      N.Src := Source;
      N.Src_Set := True;
   end Set_Source;

   procedure Set_Sink (N : in out Network; Sink : Vertex_Id) is
   begin
      if N.V = 0 or else Natural (Sink) > N.V then
         raise Invalid_Argument;
      end if;
      N.Snk := Sink;
      N.Snk_Set := True;
   end Set_Sink;

   function Has_Source (N : Network) return Boolean is
   begin
      return N.Src_Set;
   end Has_Source;

   function Has_Sink (N : Network) return Boolean is
   begin
      return N.Snk_Set;
   end Has_Sink;

   function Source (N : Network) return Vertex_Id is
   begin
      if not N.Src_Set then
         raise Invalid_Argument;
      end if;
      return N.Src;
   end Source;

   function Sink (N : Network) return Vertex_Id is
   begin
      if not N.Snk_Set then
         raise Invalid_Argument;
      end if;
      return N.Snk;
   end Sink;

   -------------------------------------------------------------------------
   -- Shared helpers
   -------------------------------------------------------------------------

   procedure Validate_ST
     (N : Network; Source, Sink : Vertex_Id)
   is
   begin
      if N.V = 0
        or else Natural (Source) > N.V
        or else Natural (Sink) > N.V
      then
         raise Invalid_Argument;
      end if;
   end Validate_ST;

   procedure Validate_Reach_Bounds
     (V_Count : Natural; First, Last : Vertex_Id)
   is
   begin
      if V_Count = 0 then
         raise Invalid_Argument;
      end if;
      if First /= 1 or else Natural (Last) < V_Count then
         raise Invalid_Argument;
      end if;
   end Validate_Reach_Bounds;

   procedure Validate_Edge_Index (N : Network; Index : Positive) is
   begin
      if Index > Natural (N.M) then
         raise Invalid_Argument;
      end if;
   end Validate_Edge_Index;

   --  Restore residual capacities from original user edges (zero flow).
   procedure Reset_Residual (N : in out Network) is
      Fwd, Bwd : Residual_Index;
   begin
      for I in 1 .. N.M loop
         Fwd := N.User_Fwd (I);
         Bwd := N.Rev (Fwd);
         N.Cap (Fwd) := N.User_Cap (I);
         N.Cap (Bwd) := 0;
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

   procedure Store_Terminals
     (N : in out Network; Source, Sink : Vertex_Id)
   is
   begin
      N.Src := Source;
      N.Snk := Sink;
      N.Src_Set := True;
      N.Snk_Set := True;
   end Store_Terminals;

   -------------------------------------------------------------------------
   -- Edmonds–Karp: BFS shortest augmenting paths
   -------------------------------------------------------------------------

   function Max_Flow_Edmonds_Karp
     (N : in out Network; Source, Sink : Vertex_Id) return Flow_Value
   is
      Total : Flow_Value := 0;
      Parent_Edge : array (Vertex_Id) of Natural;
      Queue       : array (1 .. Max_Vertices) of Vertex_Id;
      Q_Head, Q_Tail : Natural;
      U, V        : Vertex_Id;
      E           : Natural;
      Cap         : Capacity_Type;
      Bottleneck  : Flow_Value;
      Reach_Sink  : Boolean;
   begin
      if Source = Sink then
         Reset_Residual (N);
         return 0;
      end if;

      Reset_Residual (N);

      loop
         for X in 1 .. Vertex_Id (N.V) loop
            Parent_Edge (X) := 0;
         end loop;

         Q_Head := 1;
         Q_Tail := 1;
         Queue (1) := Source;
         Parent_Edge (Source) := Natural'Last;
         Reach_Sink := False;

         while Q_Head <= Q_Tail loop
            U := Queue (Q_Head);
            Q_Head := Q_Head + 1;
            if U = Sink then
               Reach_Sink := True;
               exit;
            end if;
            E := N.Head (U);
            while E /= 0 loop
               V := N.To (Residual_Index (E));
               Cap := N.Cap (Residual_Index (E));
               if Parent_Edge (V) = 0 and then Cap > 0 then
                  Parent_Edge (V) := E;
                  Q_Tail := Q_Tail + 1;
                  Queue (Q_Tail) := V;
               end if;
               E := N.Next (Residual_Index (E));
            end loop;
         end loop;

         exit when not Reach_Sink;

         Bottleneck := Flow_Value'Last;
         V := Sink;
         while V /= Source loop
            E := Parent_Edge (V);
            Cap := N.Cap (Residual_Index (E));
            Bottleneck := Min_Flow (Bottleneck, Flow_Value (Cap));
            V := N.To (N.Rev (Residual_Index (E)));
         end loop;

         V := Sink;
         while V /= Source loop
            E := Parent_Edge (V);
            declare
               Ei : constant Residual_Index := Residual_Index (E);
               R  : constant Residual_Index := N.Rev (Ei);
            begin
               N.Cap (Ei) :=
                 Capacity_Type (Flow_Value (N.Cap (Ei)) - Bottleneck);
               N.Cap (R) :=
                 Capacity_Type (Flow_Value (N.Cap (R)) + Bottleneck);
               V := N.To (R);
            end;
         end loop;

         Total := Total + Bottleneck;
      end loop;
      return Total;
   end Max_Flow_Edmonds_Karp;

   -------------------------------------------------------------------------
   -- Dinic: BFS level graph + DFS blocking flow
   -------------------------------------------------------------------------

   function Max_Flow_Dinic
     (N : in out Network; Source, Sink : Vertex_Id) return Flow_Value
   is
      Total : Flow_Value := 0;

      Level : array (Vertex_Id) of Integer;
      Ptr   : array (Vertex_Id) of Natural;

      Queue : array (1 .. Max_Vertices) of Vertex_Id;
      Q_Head, Q_Tail : Natural;

      function Build_Level_Graph return Boolean is
         U, V : Vertex_Id;
         E    : Natural;
      begin
         for X in 1 .. Vertex_Id (N.V) loop
            Level (X) := -1;
         end loop;
         Level (Source) := 0;
         Q_Head := 1;
         Q_Tail := 1;
         Queue (1) := Source;

         while Q_Head <= Q_Tail loop
            U := Queue (Q_Head);
            Q_Head := Q_Head + 1;
            E := N.Head (U);
            while E /= 0 loop
               V := N.To (Residual_Index (E));
               if Level (V) < 0 and then N.Cap (Residual_Index (E)) > 0 then
                  Level (V) := Level (U) + 1;
                  Q_Tail := Q_Tail + 1;
                  Queue (Q_Tail) := V;
               end if;
               E := N.Next (Residual_Index (E));
            end loop;
         end loop;

         return Level (Sink) >= 0;
      end Build_Level_Graph;

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
            V := N.To (Ei);
            Cap := N.Cap (Ei);

            if Cap > 0 and then Level (V) = Level (U) + 1 then
               Pushed := Send_Flow
                 (V, Min_Flow (Limit, Flow_Value (Cap)));
               if Pushed > 0 then
                  R := N.Rev (Ei);
                  N.Cap (Ei) :=
                    Capacity_Type (Flow_Value (N.Cap (Ei)) - Pushed);
                  N.Cap (R) :=
                    Capacity_Type (Flow_Value (N.Cap (R)) + Pushed);
                  return Pushed;
               end if;
            end if;

            Ptr (U) := N.Next (Ei);
         end loop;

         return 0;
      end Send_Flow;

      Phase_Push : Flow_Value;
   begin
      if Source = Sink then
         Reset_Residual (N);
         return 0;
      end if;

      Reset_Residual (N);

      loop
         exit when not Build_Level_Graph;

         for X in 1 .. Vertex_Id (N.V) loop
            Ptr (X) := N.Head (X);
         end loop;

         loop
            Phase_Push := Send_Flow (Source, Flow_Value'Last);
            exit when Phase_Push = 0;
            Total := Total + Phase_Push;
         end loop;
      end loop;

      return Total;
   end Max_Flow_Dinic;

   -------------------------------------------------------------------------
   -- Public Max_Flow dispatch
   -------------------------------------------------------------------------

   function Max_Flow
     (N      : in out Network;
      Source : Vertex_Id;
      Sink   : Vertex_Id;
      Algo   : Method := Edmonds_Karp) return Flow_Value
   is
      Result : Flow_Value;
   begin
      Validate_ST (N, Source, Sink);
      Store_Terminals (N, Source, Sink);
      case Algo is
         when Edmonds_Karp =>
            Result := Max_Flow_Edmonds_Karp (N, Source, Sink);
         when Dinic =>
            Result := Max_Flow_Dinic (N, Source, Sink);
      end case;
      return Result;
   end Max_Flow;

   function Max_Flow
     (N    : in out Network;
      Algo : Method := Edmonds_Karp) return Flow_Value
   is
   begin
      if not N.Src_Set or else not N.Snk_Set then
         raise Invalid_Argument;
      end if;
      return Max_Flow (N, N.Src, N.Snk, Algo);
   end Max_Flow;

   -------------------------------------------------------------------------
   -- Min-cut partition (residual reachability from Source)
   -------------------------------------------------------------------------

   procedure Min_Cut_Partition
     (N      : Network;
      Source : Vertex_Id;
      In_S   : out Reachability_Array)
   is
      Queue : array (1 .. Max_Vertices) of Vertex_Id;
      Q_Head, Q_Tail : Natural;
      U, V  : Vertex_Id;
      E     : Natural;
   begin
      if N.V = 0 or else Natural (Source) > N.V then
         raise Invalid_Argument;
      end if;
      Validate_Reach_Bounds (N.V, In_S'First, In_S'Last);

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
         E := N.Head (U);
         while E /= 0 loop
            V := N.To (Residual_Index (E));
            if not In_S (V) and then N.Cap (Residual_Index (E)) > 0 then
               In_S (V) := True;
               Q_Tail := Q_Tail + 1;
               Queue (Q_Tail) := V;
            end if;
            E := N.Next (Residual_Index (E));
         end loop;
      end loop;
   end Min_Cut_Partition;

   -------------------------------------------------------------------------
   -- Edge inspection
   -------------------------------------------------------------------------

   function Edge_From (N : Network; Index : Positive) return Vertex_Id is
   begin
      Validate_Edge_Index (N, Index);
      return N.User_From (User_Edge_Index (Index));
   end Edge_From;

   function Edge_To (N : Network; Index : Positive) return Vertex_Id is
   begin
      Validate_Edge_Index (N, Index);
      return N.User_To (User_Edge_Index (Index));
   end Edge_To;

   function Edge_Capacity
     (N : Network; Index : Positive) return Capacity_Type
   is
   begin
      Validate_Edge_Index (N, Index);
      return N.User_Cap (User_Edge_Index (Index));
   end Edge_Capacity;

   function Edge_Flow (N : Network; Index : Positive) return Flow_Value is
      Fwd : Residual_Index;
      Orig, Resid : Capacity_Type;
   begin
      Validate_Edge_Index (N, Index);
      Fwd := N.User_Fwd (User_Edge_Index (Index));
      Orig := N.User_Cap (User_Edge_Index (Index));
      Resid := N.Cap (Fwd);
      return Flow_Value (Orig) - Flow_Value (Resid);
   end Edge_Flow;

   function Cut_Capacity
     (N : Network; In_S : Reachability_Array) return Flow_Value
   is
      Total : Flow_Value := 0;
      F, T  : Vertex_Id;
   begin
      Validate_Reach_Bounds (N.V, In_S'First, In_S'Last);
      for I in 1 .. N.M loop
         F := N.User_From (I);
         T := N.User_To (I);
         if In_S (F) and then not In_S (T) then
            Total := Total + Flow_Value (N.User_Cap (I));
         end if;
      end loop;
      return Total;
   end Cut_Capacity;

end Flow_Networks;
