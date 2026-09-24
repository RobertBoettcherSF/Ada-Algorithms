--  Dijkstras_Algorithm body — dense O(V^2) single-source shortest paths.

pragma Ada_2022;

package body Dijkstras_Algorithm
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
      if Weight < 0 then
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

   -------------------------------------------------------------------------
   -- Shared validation
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

   -------------------------------------------------------------------------
   -- Dense Dijkstra O(V^2)
   -------------------------------------------------------------------------

   procedure Shortest_Paths
     (G      : Graph;
      Source : Vertex_Id;
      Dist   : out Distance_Array;
      Prev   : out Prev_Array)
   is
      N : constant Natural := G.N;

      Settled : array (Vertex_Id) of Boolean := [others => False];

      function Safe_Add
        (A : Distance_Value; W : Weight_Type) return Distance_Value
      is
         Wd : constant Distance_Value := Distance_Value (W);
      begin
         --  Avoid wrap past Infinity; treat overflow as Infinity.
         if A >= Infinity - Wd then
            return Infinity;
         end if;
         return A + Wd;
      end Safe_Add;

   begin
      Validate_Source (G, Source);
      Validate_Arrays
        (N, Dist'First, Dist'Last, Prev'First, Prev'Last);

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (V) := Infinity;
         Prev (V) := 0;
         Settled (V) := False;
      end loop;
      Dist (Source) := 0;

      for Step in 1 .. N loop
         declare
            U        : Vertex_Id := Source;
            Best     : Distance_Value := Infinity;
            Found    : Boolean := False;
            E_Idx    : Natural;
            W_Vert   : Vertex_Id;
            Alt      : Distance_Value;
         begin
            for V in Vertex_Id range 1 .. Vertex_Id (N) loop
               if not Settled (V) and then Dist (V) < Best then
                  Best := Dist (V);
                  U := V;
                  Found := True;
               elsif not Settled (V)
                 and then Dist (V) = Best
                 and then not Found
               then
                  --  Tie-break: first unsettled with this distance.
                  U := V;
                  Found := True;
               end if;
            end loop;

            if not Found or else Best = Infinity then
               exit;
            end if;

            Settled (U) := True;

            E_Idx := G.Head (U);
            while E_Idx /= 0 loop
               W_Vert := G.To (E_Idx);
               if not Settled (W_Vert) then
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
   end Shortest_Paths;

   function Distance
     (G : Graph; Source, Target : Vertex_Id) return Distance_Value
   is
      N    : constant Natural := G.N;
      Dist : Distance_Array (Vertex_Id);
      Prev : Prev_Array (Vertex_Id);
   begin
      Validate_Source (G, Source);
      if Natural (Target) > N then
         raise Invalid_Argument;
      end if;
      Shortest_Paths (G, Source, Dist, Prev);
      return Dist (Target);
   end Distance;

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Source : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      --  Walk Target → … → Source via Prev into a reverse buffer, then
      --  copy forward into Path.
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
         --  Source is always its own trivial path when Prev(Source) = 0
         --  (as written by Shortest_Paths). If Prev(Source) ≠ 0 the tree
         --  is inconsistent — treat as failure.
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
            --  Cycle in Prev (corrupt input) — fail safely.
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

      if Stack_Top = 0
        or else Stack (Stack_Top) /= Source
      then
         Length := 0;
         return False;
      end if;

      Length := Stack_Top;
      for I in 1 .. Stack_Top loop
         Path (I) := Stack (Stack_Top - I + 1);
      end loop;
      return True;
   end Reconstruct_Path;

end Dijkstras_Algorithm;
