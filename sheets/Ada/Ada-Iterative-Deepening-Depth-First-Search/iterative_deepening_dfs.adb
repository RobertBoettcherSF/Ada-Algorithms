--  Iterative_Deepening_DFS body — IDDFS / DLS + BFS oracle.

pragma Ada_2022;

package body Iterative_Deepening_DFS
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

   procedure Add_Edge (G : in out Graph; From, To : Vertex_Id) is
   begin
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

   procedure Validate_Search
     (G : Graph; Start, Goal : Vertex_Id;
      Path_First, Path_Last : Positive)
   is
      N : constant Natural := G.N;
   begin
      if N = 0 then
         return;
      end if;
      if Natural (Start) > N or else Natural (Goal) > N then
         raise Invalid_Argument;
      end if;
      if Path_First /= 1 or else Natural (Path_Last) < N then
         raise Invalid_Argument;
      end if;
   end Validate_Search;

   -------------------------------------------------------------------------
   -- Depth-limited DFS (Wikipedia directed-graph DLS)
   -------------------------------------------------------------------------

   function Depth_Limited_Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Limit  : Natural;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      N : constant Natural := G.N;

      --  Current root→node walk (vertices); arc depth = Stack_Top − 1.
      Stack     : array (1 .. Max_Vertices + 1) of Vertex_Id :=
        [others => Vertex_Id'First];
      Stack_Top : Natural := 0;

      procedure Copy_Path is
      begin
         Length := Stack_Top;
         for I in 1 .. Stack_Top loop
            Path (I) := Stack (I);
         end loop;
      end Copy_Path;

      --  Recursive DLS. Cutoff means the depth budget hit zero on a
      --  non-goal (a deeper IDDFS iteration may still find Goal).
      procedure DLS
        (Node      : Vertex_Id;
         Depth     : Natural;
         Found     : out Boolean;
         Remaining : out Boolean)
      is
         E_Idx        : Natural;
         W            : Vertex_Id;
         Child_Found  : Boolean;
         Child_Remain : Boolean;
         Local_Remain : Boolean := False;
      begin
         Stack_Top := Stack_Top + 1;
         Stack (Stack_Top) := Node;

         if Depth = 0 then
            if Node = Goal then
               Found := True;
               Remaining := True;
               Copy_Path;
            else
               Found := False;
               Remaining := True;
            end if;
            Stack_Top := Stack_Top - 1;
            return;
         end if;

         Found := False;
         E_Idx := G.Head (Node);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            DLS (W, Depth - 1, Child_Found, Child_Remain);
            if Child_Found then
               Found := True;
               Remaining := True;
               return;
            end if;
            if Child_Remain then
               Local_Remain := True;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;

         Remaining := Local_Remain;
         Stack_Top := Stack_Top - 1;
      end DLS;

      F : Boolean;
      R : Boolean;
   begin
      Length := 0;
      Validate_Search (G, Start, Goal, Path'First, Path'Last);

      if N = 0 then
         return False;
      end if;

      if Limit > Max_Vertices then
         raise Invalid_Argument;
      end if;

      Stack_Top := 0;
      DLS (Start, Limit, F, R);
      if F then
         return True;
      end if;
      Length := 0;
      pragma Unreferenced (R);
      return False;
   end Depth_Limited_Search;

   -------------------------------------------------------------------------
   -- Iterative deepening
   -------------------------------------------------------------------------

   function Search
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      N         : constant Natural := G.N;
      Max_Depth : Natural;
      Ok        : Boolean;
   begin
      Length := 0;
      Validate_Search (G, Start, Goal, Path'First, Path'Last);

      if N = 0 then
         return False;
      end if;

      --  A simple shortest path uses at most N − 1 arcs.
      if N = 1 then
         Max_Depth := 0;
      else
         Max_Depth := N - 1;
      end if;

      for Limit in 0 .. Max_Depth loop
         Ok := Depth_Limited_Search (G, Start, Goal, Limit, Path, Length);
         if Ok then
            return True;
         end if;
      end loop;

      Length := 0;
      return False;
   end Search;

   -------------------------------------------------------------------------
   -- BFS oracle (shortest path reconstruction)
   -------------------------------------------------------------------------

   function BFS_Shortest_Path
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      N : constant Natural := G.N;

      Visited : array (Vertex_Id) of Boolean := [others => False];
      Parent  : array (Vertex_Id) of Natural := [others => 0];

      Queue  : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Q_Head : Natural := 1;
      Q_Tail : Natural := 0;

      procedure Enqueue (V : Vertex_Id) is
      begin
         Q_Tail := Q_Tail + 1;
         Queue (Q_Tail) := V;
      end Enqueue;

      function Dequeue return Vertex_Id is
         V : Vertex_Id;
      begin
         V := Queue (Q_Head);
         Q_Head := Q_Head + 1;
         return V;
      end Dequeue;

      function Queue_Empty return Boolean is
        (Q_Head > Q_Tail);

      U, W  : Vertex_Id;
      E_Idx : Natural;
      Cur   : Vertex_Id;
      Tmp   : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      L     : Natural;
   begin
      Length := 0;
      Validate_Search (G, Start, Goal, Path'First, Path'Last);

      if N = 0 then
         return False;
      end if;

      if Start = Goal then
         Length := 1;
         Path (1) := Start;
         return True;
      end if;

      Visited (Start) := True;
      Enqueue (Start);

      while not Queue_Empty loop
         U := Dequeue;
         E_Idx := G.Head (U);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            if not Visited (W) then
               Visited (W) := True;
               Parent (W) := Natural (U);
               if W = Goal then
                  L := 0;
                  Cur := Goal;
                  loop
                     L := L + 1;
                     Tmp (L) := Cur;
                     exit when Cur = Start;
                     Cur := Vertex_Id (Parent (Cur));
                  end loop;
                  Length := L;
                  for I in 1 .. L loop
                     Path (I) := Tmp (L + 1 - I);
                  end loop;
                  return True;
               end if;
               Enqueue (W);
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;

      Length := 0;
      return False;
   end BFS_Shortest_Path;

end Iterative_Deepening_DFS;
