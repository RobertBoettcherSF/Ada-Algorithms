--  Shortest_Path_Problem body — survey: BFS, Dijkstra, Bellman–Ford,
--  Floyd–Warshall on a shared signed digraph.

pragma Ada_2022;

package body Shortest_Path_Problem
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
      G.E := 0;
      for V in Vertex_Id loop
         G.Head (V) := 0;
      end loop;
   end Clear;

   procedure Add_Edge
     (G : in out Graph; From, To : Vertex_Id; Weight : Integer)
   is
   begin
      if Weight < Integer (Weight_Type'First)
        or else Weight > Integer (Weight_Type'Last)
      then
         raise Invalid_Argument;
      end if;
      if G.N = 0
        or else Natural (From) > G.N
        or else Natural (To) > G.N
      then
         raise Invalid_Argument;
      end if;
      if G.E = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.E := G.E + 1;
      G.To (G.E) := To;
      G.Weight (G.E) := Weight_Type (Weight);
      G.Next (G.E) := G.Head (From);
      G.Head (From) := G.E;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.E);
   end Edge_Count;

   function Has_Negative_Edge (G : Graph) return Boolean is
   begin
      if G.E = 0 then
         return False;
      end if;
      for E in Edge_Index range 1 .. Edge_Index (G.E) loop
         if G.Weight (E) < 0 then
            return True;
         end if;
      end loop;
      return False;
   end Has_Negative_Edge;

   -------------------------------------------------------------------------
   -- Shared validation / arithmetic
   -------------------------------------------------------------------------

   procedure Validate_Source (G : Graph; Source : Vertex_Id) is
   begin
      if G.N = 0 or else Natural (Source) > G.N then
         raise Invalid_Argument;
      end if;
   end Validate_Source;

   procedure Validate_Arrays
     (N : Natural;
      Dist_First, Dist_Last : Vertex_Id;
      Prev_First, Prev_Last : Vertex_Id)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Dist_First /= 1
        or else Natural (Dist_Last) < N
        or else Prev_First /= 1
        or else Natural (Prev_Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Arrays;

   procedure Validate_Matrix
     (N : Natural;
      Dist_First1, Dist_Last1 : Vertex_Id;
      Dist_First2, Dist_Last2 : Vertex_Id)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Dist_First1 /= 1
        or else Natural (Dist_Last1) < N
        or else Dist_First2 /= 1
        or else Natural (Dist_Last2) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Matrix;

   function Safe_Add
     (A : Distance_Value; W : Weight_Type) return Distance_Value
   is
      B : constant Distance_Value := Distance_Value (W);
   begin
      if A = Infinity then
         return Infinity;
      end if;
      if B > 0 and then A > Infinity - B then
         return Infinity;
      end if;
      if B < 0 and then A < Distance_Value'First - B then
         return Distance_Value'First;
      end if;
      return A + B;
   end Safe_Add;

   function Safe_Add_Dist
     (A, B : Distance_Value) return Distance_Value
   is
   begin
      if A = Infinity or else B = Infinity then
         return Infinity;
      end if;
      if B > 0 and then A > Infinity - B then
         return Infinity;
      end if;
      if B < 0 and then A < Distance_Value'First - B then
         return Distance_Value'First;
      end if;
      return A + B;
   end Safe_Add_Dist;

   -------------------------------------------------------------------------
   -- BFS_Shortest (unit / unweighted)
   -------------------------------------------------------------------------

   procedure BFS_Shortest
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
   is
      N : constant Natural := G.N;

      Queue : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Head  : Natural := 1;
      Tail  : Natural := 0;

      procedure Enqueue (V : Vertex_Id) is
      begin
         Tail := Tail + 1;
         Queue (Tail) := V;
      end Enqueue;

      function Dequeue return Vertex_Id is
         V : Vertex_Id;
      begin
         V := Queue (Head);
         Head := Head + 1;
         return V;
      end Dequeue;

      function Empty return Boolean is (Head > Tail);

      U, W : Vertex_Id;
      E_Idx : Natural;
   begin
      Validate_Source (G, Source);
      Validate_Arrays
        (N, Dist'First, Dist'Last, Prev'First, Prev'Last);

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (V) := Infinity;
         Prev (V) := 0;
      end loop;
      Dist (Source) := 0;
      Enqueue (Source);

      while not Empty loop
         U := Dequeue;
         E_Idx := G.Head (U);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            if Dist (W) = Infinity then
               Dist (W) := Dist (U) + 1;
               Prev (W) := Natural (U);
               Enqueue (W);
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;
   end BFS_Shortest;

   function Distance_BFS
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
   is
      N    : constant Natural := G.N;
      Dist : Distance_Array (1 .. Vertex_Id (N));
      Prev : Prev_Array (1 .. Vertex_Id (N));
   begin
      Validate_Source (G, Source);
      if Natural (Target) > N then
         raise Invalid_Argument;
      end if;
      BFS_Shortest (G, Source, Dist, Prev);
      return Dist (Target);
   end Distance_BFS;

   -------------------------------------------------------------------------
   -- Dijkstra (dense, non-negative)
   -------------------------------------------------------------------------

   procedure Dijkstra
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
   is
      N : constant Natural := G.N;

      Settled : array (1 .. Max_Vertices) of Boolean := [others => False];

   begin
      Validate_Source (G, Source);
      Validate_Arrays
        (N, Dist'First, Dist'Last, Prev'First, Prev'Last);

      if Has_Negative_Edge (G) then
         raise Invalid_Argument;
      end if;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (V) := Infinity;
         Prev (V) := 0;
         Settled (Natural (V)) := False;
      end loop;
      Dist (Source) := 0;

      for Step in 1 .. N loop
         declare
            U      : Vertex_Id := Source;
            Best   : Distance_Value := Infinity;
            Found  : Boolean := False;
            E_Idx  : Natural;
            W_Vert : Vertex_Id;
            Alt    : Distance_Value;
         begin
            for V in Vertex_Id range 1 .. Vertex_Id (N) loop
               if not Settled (Natural (V)) and then Dist (V) < Best then
                  Best := Dist (V);
                  U := V;
                  Found := True;
               elsif not Settled (Natural (V))
                 and then Dist (V) = Best
                 and then not Found
               then
                  U := V;
                  Found := True;
               end if;
            end loop;

            if not Found or else Best = Infinity then
               exit;
            end if;

            Settled (Natural (U)) := True;

            E_Idx := G.Head (U);
            while E_Idx /= 0 loop
               W_Vert := G.To (E_Idx);
               if not Settled (Natural (W_Vert)) then
                  Alt := Safe_Add (Dist (U), G.Weight (E_Idx));
                  if Alt < Dist (W_Vert) then
                     Dist (W_Vert) := Alt;
                     Prev (W_Vert) := Natural (U);
                  end if;
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end;
      end loop;
   end Dijkstra;

   function Distance_Dijkstra
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
   is
      N    : constant Natural := G.N;
      Dist : Distance_Array (1 .. Vertex_Id (N));
      Prev : Prev_Array (1 .. Vertex_Id (N));
   begin
      Validate_Source (G, Source);
      if Natural (Target) > N then
         raise Invalid_Argument;
      end if;
      Dijkstra (G, Source, Dist, Prev);
      return Dist (Target);
   end Distance_Dijkstra;

   -------------------------------------------------------------------------
   -- Bellman–Ford
   -------------------------------------------------------------------------

   procedure Run_Bellman_Ford
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status)
   is
      N     : constant Natural := G.N;
      E_Idx : Natural;
      V     : Vertex_Id;
      W     : Weight_Type;
      Cand  : Distance_Value;
   begin
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (I) := Infinity;
         Prev (I) := 0;
      end loop;
      Dist (Source) := 0;

      if N >= 2 then
         for Pass in 1 .. N - 1 loop
            declare
               Changed : Boolean := False;
            begin
               for U_Id in Vertex_Id range 1 .. Vertex_Id (N) loop
                  if Dist (U_Id) /= Infinity then
                     E_Idx := G.Head (U_Id);
                     while E_Idx /= 0 loop
                        V := G.To (E_Idx);
                        W := G.Weight (E_Idx);
                        Cand := Safe_Add (Dist (U_Id), W);
                        if Cand < Dist (V) then
                           Dist (V) := Cand;
                           Prev (V) := Natural (U_Id);
                           Changed := True;
                        end if;
                        E_Idx := G.Next (E_Idx);
                     end loop;
                  end if;
               end loop;
               exit when not Changed;
            end;
         end loop;
      end if;

      Status := Success;
      for U_Id in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Dist (U_Id) /= Infinity then
            E_Idx := G.Head (U_Id);
            while E_Idx /= 0 loop
               V := G.To (E_Idx);
               W := G.Weight (E_Idx);
               Cand := Safe_Add (Dist (U_Id), W);
               if Cand < Dist (V) then
                  Status := Negative_Cycle;
                  return;
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end if;
      end loop;
   end Run_Bellman_Ford;

   procedure Bellman_Ford
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array;
      Status : out Run_Status)
   is
      N : constant Natural := G.N;
   begin
      Validate_Source (G, Source);
      Validate_Arrays
        (N, Dist'First, Dist'Last, Prev'First, Prev'Last);
      Run_Bellman_Ford (G, Source, Dist, Prev, Status);
   end Bellman_Ford;

   procedure Bellman_Ford
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
   is
      Status : Run_Status;
   begin
      Bellman_Ford (G, Source, Dist, Prev, Status);
      if Status = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
   end Bellman_Ford;

   function Has_Negative_Cycle
     (G : Graph; Source : Vertex_Id) return Boolean
   is
      N      : constant Natural := G.N;
      Dist   : Distance_Array (1 .. Vertex_Id (N));
      Prev   : Prev_Array (1 .. Vertex_Id (N));
      Status : Run_Status;
   begin
      Validate_Source (G, Source);
      Run_Bellman_Ford (G, Source, Dist, Prev, Status);
      return Status = Negative_Cycle;
   end Has_Negative_Cycle;

   function Distance_Bellman_Ford
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
   is
      N      : constant Natural := G.N;
      Dist   : Distance_Array (1 .. Vertex_Id (N));
      Prev   : Prev_Array (1 .. Vertex_Id (N));
      Status : Run_Status;
   begin
      Validate_Source (G, Source);
      if Natural (Target) > N then
         raise Invalid_Argument;
      end if;
      Run_Bellman_Ford (G, Source, Dist, Prev, Status);
      if Status = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
      return Dist (Target);
   end Distance_Bellman_Ford;

   -------------------------------------------------------------------------
   -- Floyd–Warshall APSP
   -------------------------------------------------------------------------

   procedure Init_Dist_From_Graph (G : Graph; Dist : out Dist_Matrix) is
      N     : constant Natural := G.N;
      E_Idx : Natural;
      V     : Vertex_Id;
      W     : Weight_Type;
      Cand  : Distance_Value;
   begin
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         for J in Vertex_Id range 1 .. Vertex_Id (N) loop
            if I = J then
               Dist (I, J) := 0;
            else
               Dist (I, J) := Infinity;
            end if;
         end loop;
      end loop;

      for U in Vertex_Id range 1 .. Vertex_Id (N) loop
         E_Idx := G.Head (U);
         while E_Idx /= 0 loop
            V := G.To (E_Idx);
            W := G.Weight (E_Idx);
            Cand := Distance_Value (W);
            --  Parallel edges: keep minimum; self-loop may make Dist(U,U)<0.
            if Cand < Dist (U, V) then
               Dist (U, V) := Cand;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;
   end Init_Dist_From_Graph;

   procedure Run_Floyd_Warshall
     (Dist   : in out Dist_Matrix;
      N      : Natural;
      Status : out Run_Status)
   is
      Cand : Distance_Value;
   begin
      for K in Vertex_Id range 1 .. Vertex_Id (N) loop
         for I in Vertex_Id range 1 .. Vertex_Id (N) loop
            for J in Vertex_Id range 1 .. Vertex_Id (N) loop
               Cand := Safe_Add_Dist (Dist (I, K), Dist (K, J));
               if Cand < Dist (I, J) then
                  Dist (I, J) := Cand;
               end if;
            end loop;
         end loop;
      end loop;

      Status := Success;
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Dist (V, V) < 0 then
            Status := Negative_Cycle;
            return;
         end if;
      end loop;
   end Run_Floyd_Warshall;

   procedure Run_Floyd_Warshall_Prev
     (Dist   : in out Dist_Matrix;
      Prev   : in out Prev_Matrix;
      N      : Natural;
      Status : out Run_Status)
   is
      Cand : Distance_Value;
   begin
      --  Init Prev from direct edges: Prev(I,J)=I when finite edge I≠J.
      for I in Vertex_Id range 1 .. Vertex_Id (N) loop
         for J in Vertex_Id range 1 .. Vertex_Id (N) loop
            if I = J then
               Prev (I, J) := 0;
            elsif Dist (I, J) /= Infinity then
               Prev (I, J) := Natural (I);
            else
               Prev (I, J) := 0;
            end if;
         end loop;
      end loop;

      for K in Vertex_Id range 1 .. Vertex_Id (N) loop
         for I in Vertex_Id range 1 .. Vertex_Id (N) loop
            for J in Vertex_Id range 1 .. Vertex_Id (N) loop
               Cand := Safe_Add_Dist (Dist (I, K), Dist (K, J));
               if Cand < Dist (I, J) then
                  Dist (I, J) := Cand;
                  Prev (I, J) := Prev (K, J);
               end if;
            end loop;
         end loop;
      end loop;

      Status := Success;
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Dist (V, V) < 0 then
            Status := Negative_Cycle;
            return;
         end if;
      end loop;
   end Run_Floyd_Warshall_Prev;

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Status : out Run_Status)
   is
      N : constant Natural := G.N;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      Validate_Matrix
        (N, Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));
      Init_Dist_From_Graph (G, Dist);
      Run_Floyd_Warshall (Dist, N, Status);
   end Floyd_Warshall;

   procedure Floyd_Warshall
     (G      : Graph;
      Dist   : out Dist_Matrix;
      Prev   : out Prev_Matrix;
      Status : out Run_Status)
   is
      N : constant Natural := G.N;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      Validate_Matrix
        (N, Dist'First (1), Dist'Last (1), Dist'First (2), Dist'Last (2));
      if Prev'First (1) /= 1
        or else Natural (Prev'Last (1)) < N
        or else Prev'First (2) /= 1
        or else Natural (Prev'Last (2)) < N
      then
         raise Invalid_Argument;
      end if;
      Init_Dist_From_Graph (G, Dist);
      Run_Floyd_Warshall_Prev (Dist, Prev, N, Status);
   end Floyd_Warshall;

   procedure Floyd_Warshall
     (G    : Graph;
      Dist : out Dist_Matrix;
      Prev : out Prev_Matrix)
   is
      Status : Run_Status;
   begin
      Floyd_Warshall (G, Dist, Prev, Status);
      if Status = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
   end Floyd_Warshall;

   function Has_Negative_Cycle_APSP (G : Graph) return Boolean is
      N      : constant Natural := G.N;
      Dist   : Dist_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
      Status : Run_Status;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      Init_Dist_From_Graph (G, Dist);
      Run_Floyd_Warshall (Dist, N, Status);
      return Status = Negative_Cycle;
   end Has_Negative_Cycle_APSP;

   function Distance_Floyd_Warshall
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
   is
      N      : constant Natural := G.N;
      Dist   : Dist_Matrix (1 .. Vertex_Id (N), 1 .. Vertex_Id (N));
      Status : Run_Status;
   begin
      Validate_Source (G, Source);
      if Natural (Target) > N then
         raise Invalid_Argument;
      end if;
      Init_Dist_From_Graph (G, Dist);
      Run_Floyd_Warshall (Dist, N, Status);
      if Status = Negative_Cycle then
         raise Negative_Cycle_Error;
      end if;
      return Dist (Source, Target);
   end Distance_Floyd_Warshall;

   -------------------------------------------------------------------------
   -- Reconstruct_Path
   -------------------------------------------------------------------------

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      Stack     : array (1 .. Max_Vertices + 1) of Vertex_Id :=
        [others => Vertex_Id'First];
      Stack_Top : Natural := 0;
      U         : Natural;
      Guard     : Natural := 0;
   begin
      Length := 0;

      if Source not in Prev'Range or else Target not in Prev'Range then
         raise Invalid_Argument;
      end if;
      if Path'First /= 1
        or else Natural (Path'Last) < Natural (Prev'Last)
      then
         raise Invalid_Argument;
      end if;

      if Source = Target then
         if Prev (Source) /= 0 then
            return False;
         end if;
         Path (1) := Source;
         Length := 1;
         return True;
      end if;

      U := Natural (Target);
      while U /= 0 loop
         Guard := Guard + 1;
         if Guard > Max_Vertices + 1 then
            Length := 0;
            return False;
         end if;
         Stack_Top := Stack_Top + 1;
         Stack (Stack_Top) := Vertex_Id (U);
         if Vertex_Id (U) = Source then
            exit;
         end if;
         if U not in Natural (Prev'First) .. Natural (Prev'Last) then
            Length := 0;
            return False;
         end if;
         U := Prev (Vertex_Id (U));
      end loop;

      if Stack_Top = 0 or else Stack (Stack_Top) /= Source then
         Length := 0;
         return False;
      end if;

      Length := Stack_Top;
      for I in 1 .. Stack_Top loop
         Path (I) := Stack (Stack_Top - I + 1);
      end loop;
      return True;
   end Reconstruct_Path;

   function Reconstruct_Path
     (Prev   : Prev_Matrix;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      --  Extract the Source-row of Prev into a temporary Prev_Array and
      --  reuse the single-source walker.
      Row : Prev_Array (Prev'Range (2));
   begin
      if Source not in Prev'Range (1)
        or else Target not in Prev'Range (2)
      then
         raise Invalid_Argument;
      end if;
      for V in Prev'Range (2) loop
         Row (V) := Prev (Source, V);
      end loop;
      return Reconstruct_Path (Row, Source, Target, Path, Length);
   end Reconstruct_Path;

end Shortest_Path_Problem;
