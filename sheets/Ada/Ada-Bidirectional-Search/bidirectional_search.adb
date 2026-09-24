--  Bidirectional_Search body — dual-frontier BFS meeting in the middle.

pragma Ada_2022;

package body Bidirectional_Search
  with SPARK_Mode => Off
is

   type Visited_Array is array (Vertex_Id) of Boolean;
   type Dist_Work is array (Vertex_Id) of Natural;
   type Prev_Work is array (Vertex_Id) of Natural;

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
         G.Head_F (V) := 0;
         G.Head_R (V) := 0;
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
      --  Forward: From → To
      G.To_F (G.E) := To;
      G.Next_F (G.E) := G.Head_F (From);
      G.Head_F (From) := G.E;
      --  Reverse: To ← From (backward frontier walks To → From)
      G.To_R (G.E) := From;
      G.Next_R (G.E) := G.Head_R (To);
      G.Head_R (To) := G.E;
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

   procedure Validate_Vertex (G : Graph; V : Vertex_Id) is
   begin
      if G.N = 0 or else Natural (V) > G.N then
         raise Invalid_Argument;
      end if;
   end Validate_Vertex;

   procedure Validate_Path (N : Natural; First, Last : Positive) is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if First /= 1 or else Natural (Last) < N then
         raise Invalid_Argument;
      end if;
   end Validate_Path;

   -------------------------------------------------------------------------
   -- Unidirectional BFS distance (oracle)
   -------------------------------------------------------------------------

   function Run_BFS_Distance
     (G : Graph; Start, Goal : Vertex_Id) return Natural
   is
      N       : constant Natural := G.N;
      Visited : Visited_Array := [others => False];
      Dist    : Dist_Work := [others => Infinity];
      Queue   : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Q_Head  : Natural := 1;
      Q_Tail  : Natural := 0;
      U, W    : Vertex_Id;
      E_Idx   : Natural;

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

      function Queue_Empty return Boolean is (Q_Head > Q_Tail);
   begin
      if Start = Goal then
         return 0;
      end if;

      Dist (Start) := 0;
      Visited (Start) := True;
      Enqueue (Start);

      while not Queue_Empty loop
         U := Dequeue;
         if U = Goal then
            return Dist (Goal);
         end if;
         E_Idx := G.Head_F (U);
         while E_Idx /= 0 loop
            W := G.To_F (E_Idx);
            if not Visited (W) then
               Visited (W) := True;
               Dist (W) := Dist (U) + 1;
               Enqueue (W);
            end if;
            E_Idx := G.Next_F (E_Idx);
         end loop;
      end loop;

      pragma Unreferenced (N);
      return Infinity;
   end Run_BFS_Distance;

   -------------------------------------------------------------------------
   -- Bidirectional BFS core
   -------------------------------------------------------------------------

   procedure Run_Bidirectional
     (G        : Graph;
      Start    : Vertex_Id;
      Goal     : Vertex_Id;
      Path     : in out Order_Array;
      Length   : out Natural;
      Dist_Out : out Natural;
      Found    : out Boolean)
   is
      N : constant Natural := G.N;

      Visited_F : Visited_Array := [others => False];
      Visited_B : Visited_Array := [others => False];
      Dist_F    : Dist_Work := [others => Infinity];
      Dist_B    : Dist_Work := [others => Infinity];
      Prev_F    : Prev_Work := [others => 0];
      Prev_B    : Prev_Work := [others => 0];

      Queue_F : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Queue_B : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      Head_F  : Natural := 1;
      Tail_F  : Natural := 0;
      Head_B  : Natural := 1;
      Tail_B  : Natural := 0;

      Best     : Natural := Infinity;
      Meeting  : Natural := 0;

      procedure Enqueue_F (V : Vertex_Id) is
      begin
         Tail_F := Tail_F + 1;
         Queue_F (Tail_F) := V;
      end Enqueue_F;

      procedure Enqueue_B (V : Vertex_Id) is
      begin
         Tail_B := Tail_B + 1;
         Queue_B (Tail_B) := V;
      end Enqueue_B;

      function Dequeue_F return Vertex_Id is
         V : Vertex_Id;
      begin
         V := Queue_F (Head_F);
         Head_F := Head_F + 1;
         return V;
      end Dequeue_F;

      function Dequeue_B return Vertex_Id is
         V : Vertex_Id;
      begin
         V := Queue_B (Head_B);
         Head_B := Head_B + 1;
         return V;
      end Dequeue_B;

      function Empty_F return Boolean is (Head_F > Tail_F);
      function Empty_B return Boolean is (Head_B > Tail_B);

      function Frontier_F return Natural is
        (if Empty_F then 0 else Tail_F - Head_F + 1);

      function Frontier_B return Natural is
        (if Empty_B then 0 else Tail_B - Head_B + 1);

      procedure Consider (V : Vertex_Id) is
         Cand : Natural;
      begin
         if Visited_F (V) and then Visited_B (V) then
            if Dist_F (V) /= Infinity and then Dist_B (V) /= Infinity then
               Cand := Dist_F (V) + Dist_B (V);
               if Cand < Best then
                  Best := Cand;
                  Meeting := Natural (V);
               end if;
            end if;
         end if;
      end Consider;

      procedure Expand_Forward is
         U, W  : Vertex_Id;
         E_Idx : Natural;
      begin
         U := Dequeue_F;
         --  Optional prune: nothing better possible through deeper U
         if Best /= Infinity and then Dist_F (U) >= Best then
            return;
         end if;
         E_Idx := G.Head_F (U);
         while E_Idx /= 0 loop
            W := G.To_F (E_Idx);
            if not Visited_F (W) then
               Visited_F (W) := True;
               Dist_F (W) := Dist_F (U) + 1;
               Prev_F (W) := Natural (U);
               Enqueue_F (W);
               Consider (W);
            end if;
            E_Idx := G.Next_F (E_Idx);
         end loop;
      end Expand_Forward;

      procedure Expand_Backward is
         U, W  : Vertex_Id;
         E_Idx : Natural;
      begin
         U := Dequeue_B;
         if Best /= Infinity and then Dist_B (U) >= Best then
            return;
         end if;
         E_Idx := G.Head_R (U);
         while E_Idx /= 0 loop
            W := G.To_R (E_Idx);
            if not Visited_B (W) then
               Visited_B (W) := True;
               Dist_B (W) := Dist_B (U) + 1;
               Prev_B (W) := Natural (U);
               Enqueue_B (W);
               Consider (W);
            end if;
            E_Idx := G.Next_R (E_Idx);
         end loop;
      end Expand_Backward;

      --  Reconstruction scratch
      Tmp   : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      L     : Natural;
      Cur   : Vertex_Id;
      P     : Natural;
      Meet  : Vertex_Id;
      Guard : Natural;
   begin
      Length := 0;
      Dist_Out := Infinity;
      Found := False;

      if Start = Goal then
         Length := 1;
         Path (1) := Start;
         Dist_Out := 0;
         Found := True;
         return;
      end if;

      Dist_F (Start) := 0;
      Visited_F (Start) := True;
      Prev_F (Start) := 0;
      Enqueue_F (Start);

      Dist_B (Goal) := 0;
      Visited_B (Goal) := True;
      Prev_B (Goal) := 0;
      Enqueue_B (Goal);

      --  Start and Goal may already meet if equal (handled) or if somehow
      --  same — also consider immediate overlap after init (distinct).
      Consider (Start);
      Consider (Goal);

      while not Empty_F or else not Empty_B loop
         --  Expand the smaller frontier (balanced bidirectional BFS).
         if Empty_B or else
           (not Empty_F and then Frontier_F <= Frontier_B)
         then
            if not Empty_F then
               Expand_Forward;
            end if;
         else
            if not Empty_B then
               Expand_Backward;
            end if;
         end if;
      end loop;

      if Best = Infinity or else Meeting = 0 then
         return;
      end if;

      Meet := Vertex_Id (Meeting);

      --  Walk Prev_F from Meet back to Start into Tmp (reversed later).
      L := 0;
      Cur := Meet;
      Guard := 0;
      loop
         L := L + 1;
         if L > Max_Vertices then
            return;
         end if;
         Tmp (L) := Cur;
         exit when Cur = Start;
         P := Prev_F (Cur);
         if P = 0 then
            return;
         end if;
         Cur := Vertex_Id (P);
         Guard := Guard + 1;
         if Guard > Max_Vertices then
            return;
         end if;
      end loop;

      --  Reverse Start..Meet into Path
      Length := 0;
      for I in reverse 1 .. L loop
         Length := Length + 1;
         Path (Length) := Tmp (I);
      end loop;

      --  Append Meet+1 .. Goal via Prev_B (Prev_B points toward Goal).
      Cur := Meet;
      Guard := 0;
      loop
         P := Prev_B (Cur);
         exit when P = 0;
         Cur := Vertex_Id (P);
         Length := Length + 1;
         if Length > N then
            Length := 0;
            return;
         end if;
         Path (Length) := Cur;
         Guard := Guard + 1;
         if Guard > Max_Vertices then
            Length := 0;
            return;
         end if;
      end loop;

      if Path (1) /= Start or else Path (Length) /= Goal then
         Length := 0;
         return;
      end if;

      if Length /= Best + 1 then
         Length := 0;
         return;
      end if;

      Dist_Out := Best;
      Found := True;
      pragma Unreferenced (N);
   end Run_Bidirectional;

   -------------------------------------------------------------------------
   -- Public Shortest_Path
   -------------------------------------------------------------------------

   function Shortest_Path
     (G      : Graph;
      Start  : Vertex_Id;
      Goal   : Vertex_Id;
      Path   : out Order_Array;
      Length : out Natural) return Boolean
   is
      Dist_Out : Natural;
      Found    : Boolean;
   begin
      Length := 0;
      Validate_Path (G.N, Path'First, Path'Last);
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      Run_Bidirectional
        (G, Start, Goal, Path, Length, Dist_Out, Found);
      pragma Unreferenced (Dist_Out);
      return Found;
   end Shortest_Path;

   -------------------------------------------------------------------------
   -- Distance
   -------------------------------------------------------------------------

   function Distance
     (G : Graph; Start, Goal : Vertex_Id) return Natural
   is
      Path     : Order_Array (1 .. Max_Vertices);
      Length   : Natural;
      Dist_Out : Natural;
      Found    : Boolean;
   begin
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      if Start = Goal then
         return 0;
      end if;
      Run_Bidirectional
        (G, Start, Goal, Path, Length, Dist_Out, Found);
      pragma Unreferenced (Length);
      if Found then
         return Dist_Out;
      else
         return Infinity;
      end if;
   end Distance;

   -------------------------------------------------------------------------
   -- BFS_Distance oracle
   -------------------------------------------------------------------------

   function BFS_Distance
     (G : Graph; Start, Goal : Vertex_Id) return Natural
   is
   begin
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Goal);
      return Run_BFS_Distance (G, Start, Goal);
   end BFS_Distance;

   -------------------------------------------------------------------------
   -- Reachable
   -------------------------------------------------------------------------

   function Reachable
     (G : Graph; Start, Goal : Vertex_Id) return Boolean
   is
   begin
      return Distance (G, Start, Goal) /= Infinity;
   end Reachable;

end Bidirectional_Search;
