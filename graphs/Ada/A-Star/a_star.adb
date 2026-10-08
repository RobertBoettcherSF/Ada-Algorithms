--  A_Star body — dense open-set A* (f = g + h), optional reopen.

pragma Ada_2022;

package body A_Star
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

   procedure Validate_Endpoints
     (G : Graph; Source, Goal : Vertex_Id)
   is
   begin
      if G.N = 0
        or else Natural (Source) > G.N
        or else Natural (Goal) > G.N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Endpoints;

   procedure Validate_Arrays
     (N : Natural;
      Dist_First, Dist_Last : Vertex_Id;
      Prev_First, Prev_Last : Vertex_Id;
      Path_First, Path_Last : Positive)
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
      if Path_First /= 1 or else Path_Last < N then
         raise Invalid_Argument;
      end if;
   end Validate_Arrays;

   procedure Validate_Heuristic
     (N : Natural; Heuristic : Heuristic_Array)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Natural (Heuristic'First) > 1
        or else Natural (Heuristic'Last) < N
      then
         raise Invalid_Argument;
      end if;
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if Heuristic (V) < 0 then
            raise Invalid_Argument;
         end if;
      end loop;
   end Validate_Heuristic;

   -------------------------------------------------------------------------
   -- Path reconstruction from Prev
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

   -------------------------------------------------------------------------
   -- Dense A* core
   -------------------------------------------------------------------------

   procedure Run_Search
     (G              : Graph;
      Source         : Vertex_Id;
      Goal           : Vertex_Id;
      Heuristic      : Heuristic_Array;
      Dist           : out Distance_Array;
      Prev           : out Prev_Array;
      Path           : out Path_Array;
      Length         : out Natural;
      Found          : out Boolean;
      Nodes_Expanded : out Natural)
   is
      N : constant Natural := G.N;

      Closed : array (Vertex_Id) of Boolean := [others => False];

      function Safe_Add
        (A : Distance_Value; W : Weight_Type) return Distance_Value
      is
         Wd : constant Distance_Value := Distance_Value (W);
      begin
         if A >= Infinity - Wd then
            return Infinity;
         end if;
         return A + Wd;
      end Safe_Add;

      function F_Score (V : Vertex_Id) return Distance_Value is
         H : Distance_Value;
      begin
         if Dist (V) = Infinity then
            return Infinity;
         end if;
         H := Distance_Value (Heuristic (V));
         if Dist (V) >= Infinity - H then
            return Infinity;
         end if;
         return Dist (V) + H;
      end F_Score;

   begin
      Validate_Endpoints (G, Source, Goal);
      Validate_Arrays
        (N, Dist'First, Dist'Last, Prev'First, Prev'Last,
         Path'First, Path'Last);
      Validate_Heuristic (N, Heuristic);

      Length := 0;
      Found := False;
      Nodes_Expanded := 0;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (V) := Infinity;
         Prev (V) := 0;
         Closed (V) := False;
      end loop;
      Dist (Source) := 0;

      --  Source = Goal: trivial optimal path of cost 0.
      if Source = Goal then
         Found := True;
         Length := 1;
         Path (1) := Source;
         Nodes_Expanded := 1;
         Closed (Source) := True;
         return;
      end if;

      loop
         declare
            U     : Vertex_Id := Source;
            Best  : Distance_Value := Infinity;
            Found_Open : Boolean := False;
            E_Idx : Natural;
            W_Vert : Vertex_Id;
            Alt   : Distance_Value;
            Fv    : Distance_Value;
         begin
            for V in Vertex_Id range 1 .. Vertex_Id (N) loop
               if not Closed (V) and then Dist (V) < Infinity then
                  Fv := F_Score (V);
                  if not Found_Open or else Fv < Best then
                     Best := Fv;
                     U := V;
                     Found_Open := True;
                  elsif Fv = Best and then V < U then
                     --  Tie-break: smaller vertex id (stable, educational).
                     U := V;
                  end if;
               end if;
            end loop;

            if not Found_Open then
               exit;
            end if;

            Closed (U) := True;
            Nodes_Expanded := Nodes_Expanded + 1;

            if U = Goal then
               Found := Reconstruct_Path (Prev, Source, Goal, Path, Length);
               exit;
            end if;

            E_Idx := G.Head (U);
            while E_Idx /= 0 loop
               W_Vert := G.To (E_Idx);
               Alt := Safe_Add (Dist (U), G.Weight (E_Idx));
               if Alt < Dist (W_Vert) then
                  Dist (W_Vert) := Alt;
                  Prev (W_Vert) := Natural (U);
                  --  Reopen if previously closed (admissible-only heuristics).
                  Closed (W_Vert) := False;
               end if;
               E_Idx := G.Next (E_Idx);
            end loop;
         end;
      end loop;

      if not Found then
         Length := 0;
      end if;
   end Run_Search;

   procedure Search
     (G         : Graph;
      Source    : Vertex_Id;
      Goal      : Vertex_Id;
      Heuristic : Heuristic_Array;
      Dist      : out Distance_Array;
      Prev      : out Prev_Array;
      Path      : out Path_Array;
      Length    : out Natural;
      Found     : out Boolean)
   is
      Exp : Natural;
   begin
      Run_Search
        (G, Source, Goal, Heuristic, Dist, Prev, Path, Length, Found, Exp);
   end Search;

   procedure Search
     (G              : Graph;
      Source         : Vertex_Id;
      Goal           : Vertex_Id;
      Heuristic      : Heuristic_Array;
      Dist           : out Distance_Array;
      Prev           : out Prev_Array;
      Path           : out Path_Array;
      Length         : out Natural;
      Found          : out Boolean;
      Nodes_Expanded : out Natural)
   is
   begin
      Run_Search
        (G, Source, Goal, Heuristic, Dist, Prev, Path, Length, Found,
         Nodes_Expanded);
   end Search;

   function Find_Path
     (G         : Graph;
      Source    : Vertex_Id;
      Goal      : Vertex_Id;
      Heuristic : Heuristic_Array;
      Path      : out Path_Array;
      Length    : out Natural) return Distance_Value
   is
      Dist  : Distance_Array (Vertex_Id);
      Prev  : Prev_Array (Vertex_Id);
      Found : Boolean;
      Exp   : Natural;
   begin
      Run_Search
        (G, Source, Goal, Heuristic, Dist, Prev, Path, Length, Found, Exp);
      if Found then
         return Dist (Goal);
      else
         Length := 0;
         return Infinity;
      end if;
   end Find_Path;

   function Distance
     (G         : Graph;
      Source    : Vertex_Id;
      Goal      : Vertex_Id;
      Heuristic : Heuristic_Array) return Distance_Value
   is
      Dist  : Distance_Array (Vertex_Id);
      Prev  : Prev_Array (Vertex_Id);
      Path  : Path_Array (1 .. Max_Vertices);
      Len   : Natural;
      Found : Boolean;
      Exp   : Natural;
   begin
      Run_Search
        (G, Source, Goal, Heuristic, Dist, Prev, Path, Len, Found, Exp);
      if Found then
         return Dist (Goal);
      else
         return Infinity;
      end if;
   end Distance;

end A_Star;
