--  Breadth_First_Search body — FIFO queue BFS with unit-cost distances.

pragma Ada_2022;

package body Breadth_First_Search
  with SPARK_Mode => Off
is

   type Visited_Array is array (Vertex_Id) of Boolean;

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

   procedure Validate_Vertex (G : Graph; V : Vertex_Id) is
   begin
      if G.N = 0 or else Natural (V) > G.N then
         raise Invalid_Argument;
      end if;
   end Validate_Vertex;

   procedure Validate_Order (N : Natural; First, Last : Positive) is
   begin
      if N = 0 then
         return;
      end if;
      if First /= 1 or else Natural (Last) < N then
         raise Invalid_Argument;
      end if;
   end Validate_Order;

   procedure Validate_SP_Arrays
     (N : Natural;
      D_First, D_Last : Vertex_Id;
      P_First, P_Last : Vertex_Id)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if D_First /= 1
        or else Natural (D_Last) < N
        or else P_First /= 1
        or else Natural (P_Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_SP_Arrays;

   -------------------------------------------------------------------------
   -- Core BFS: fill Dist / Prev / optional Order
   -------------------------------------------------------------------------

   procedure Run_BFS
     (G          : Graph;
      Start      : Vertex_Id;
      Dist       : in out Distance_Array;
      Prev       : in out Prev_Array;
      Order      : in out Order_Array;
      Count      : in out Natural;
      Track_Order : Boolean)
   is
      N : constant Natural := G.N;

      Visited : Visited_Array := [others => False];

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
   begin
      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Dist (V) := Infinity;
         Prev (V) := 0;
      end loop;

      Dist (Start) := 0;
      Prev (Start) := 0;
      Visited (Start) := True;
      Enqueue (Start);

      if Track_Order then
         Count := 1;
         Order (1) := Start;
      end if;

      while not Queue_Empty loop
         U := Dequeue;
         E_Idx := G.Head (U);
         while E_Idx /= 0 loop
            W := G.To (E_Idx);
            if not Visited (W) then
               Visited (W) := True;
               Dist (W) := Dist (U) + 1;
               Prev (W) := Natural (U);
               Enqueue (W);
               if Track_Order then
                  Count := Count + 1;
                  Order (Count) := W;
               end if;
            end if;
            E_Idx := G.Next (E_Idx);
         end loop;
      end loop;
   end Run_BFS;

   -------------------------------------------------------------------------
   -- Public BFS
   -------------------------------------------------------------------------

   procedure BFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array;
      Count : out Natural)
   is
      N    : constant Natural := G.N;
      Dist : Distance_Array (1 .. Vertex_Id (Max_Vertices)) := [others => Infinity];
      Prev : Prev_Array (1 .. Vertex_Id (Max_Vertices)) := [others => 0];
   begin
      Count := 0;
      Validate_Order (N, Order'First, Order'Last);

      if N = 0 then
         return;
      end if;

      Validate_Vertex (G, Start);
      Run_BFS (G, Start, Dist, Prev, Order, Count, True);
   end BFS;

   -------------------------------------------------------------------------
   -- Public Shortest_Paths
   -------------------------------------------------------------------------

   procedure Shortest_Paths
     (G     : Graph;
      Start : Vertex_Id;
      Dist  : out Distance_Array;
      Prev  : out Prev_Array)
   is
      N     : constant Natural := G.N;
      Order : Order_Array (1 .. Max_Vertices);
      Count : Natural := 0;
   begin
      Validate_SP_Arrays
        (N, Dist'First, Dist'Last, Prev'First, Prev'Last);
      Validate_Vertex (G, Start);
      Run_BFS (G, Start, Dist, Prev, Order, Count, False);
      pragma Unreferenced (Count);
   end Shortest_Paths;

   -------------------------------------------------------------------------
   -- Distance
   -------------------------------------------------------------------------

   function Distance
     (G : Graph; Start, Target : Vertex_Id) return Natural
   is
      Dist  : Distance_Array (1 .. Vertex_Id (Max_Vertices)) :=
        [others => Infinity];
      Prev  : Prev_Array (1 .. Vertex_Id (Max_Vertices)) := [others => 0];
      Order : Order_Array (1 .. Max_Vertices);
      Count : Natural := 0;
   begin
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Target);

      if Start = Target then
         return 0;
      end if;

      Run_BFS (G, Start, Dist, Prev, Order, Count, False);
      pragma Unreferenced (Count);
      return Dist (Target);
   end Distance;

   -------------------------------------------------------------------------
   -- Reconstruct_Path
   -------------------------------------------------------------------------

   function Reconstruct_Path
     (Prev   : Prev_Array;
      Start  : Vertex_Id;
      Target : Vertex_Id;
      Path   : out Order_Array;
      Length : out Natural) return Boolean
   is
      Tmp : array (1 .. Max_Vertices) of Vertex_Id :=
        [others => Vertex_Id'First];
      L   : Natural := 0;
      Cur : Vertex_Id;
      P   : Natural;
      Guard : Natural := 0;
   begin
      Length := 0;

      if Start < Prev'First
        or else Start > Prev'Last
        or else Target < Prev'First
        or else Target > Prev'Last
      then
         raise Invalid_Argument;
      end if;

      if Path'First /= 1
        or else Natural (Path'Last) < Natural (Prev'Last - Prev'First + 1)
      then
         raise Invalid_Argument;
      end if;

      if Start = Target then
         Length := 1;
         Path (1) := Start;
         return True;
      end if;

      if Prev (Target) = 0 then
         return False;
      end if;

      Cur := Target;
      loop
         L := L + 1;
         if L > Max_Vertices then
            Length := 0;
            return False;
         end if;
         Tmp (L) := Cur;
         exit when Cur = Start;
         P := Prev (Cur);
         if P = 0 then
            Length := 0;
            return False;
         end if;
         if P < Natural (Prev'First) or else P > Natural (Prev'Last) then
            Length := 0;
            return False;
         end if;
         Cur := Vertex_Id (P);
         Guard := Guard + 1;
         if Guard > Max_Vertices then
            Length := 0;
            return False;
         end if;
      end loop;

      Length := L;
      for I in 1 .. L loop
         Path (I) := Tmp (L + 1 - I);
      end loop;
      return True;
   end Reconstruct_Path;

   -------------------------------------------------------------------------
   -- Reachable
   -------------------------------------------------------------------------

   function Reachable
     (G : Graph; Start, Target : Vertex_Id) return Boolean
   is
   begin
      return Distance (G, Start, Target) /= Infinity;
   end Reachable;

end Breadth_First_Search;
