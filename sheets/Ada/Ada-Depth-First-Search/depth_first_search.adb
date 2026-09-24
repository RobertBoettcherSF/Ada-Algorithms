--  Depth_First_Search body — iterative DFS matching recursive discovery
--  / finish order via an explicit stack of adjacency iterators.

pragma Ada_2022;

package body Depth_First_Search
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

   procedure Validate_Times
     (N : Natural;
      D_First, D_Last : Vertex_Id;
      F_First, F_Last : Vertex_Id)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if D_First /= 1
        or else Natural (D_Last) < N
        or else F_First /= 1
        or else Natural (F_Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Times;

   -------------------------------------------------------------------------
   -- Core DFS from Start (iterator stack = recursive discovery/finish)
   -------------------------------------------------------------------------

   procedure Run_DFS_From
     (G           : Graph;
      Start       : Vertex_Id;
      Visited     : in out Visited_Array;
      Order       : in out Order_Array;
      Count       : in out Natural;
      Track_Times : Boolean;
      Discover    : in out Time_Array;
      Finish      : in out Time_Array;
      Clock       : in out Natural)
   is
      type Frame is record
         V   : Vertex_Id := Vertex_Id'First;
         Cur : Natural := 0;
      end record;

      Stack : array (1 .. Max_Vertices) of Frame;
      Top   : Natural := 0;

      procedure Push (V : Vertex_Id) is
      begin
         Top := Top + 1;
         Stack (Top).V := V;
         Stack (Top).Cur := G.Head (V);
      end Push;

      U, W  : Vertex_Id;
      E_Idx : Natural;
   begin
      if Visited (Start) then
         return;
      end if;

      Visited (Start) := True;
      Count := Count + 1;
      Order (Count) := Start;
      if Track_Times then
         Clock := Clock + 1;
         Discover (Start) := Clock;
      end if;
      Push (Start);

      while Top > 0 loop
         U := Stack (Top).V;
         E_Idx := Stack (Top).Cur;
         if E_Idx = 0 then
            if Track_Times then
               Clock := Clock + 1;
               Finish (U) := Clock;
            end if;
            Top := Top - 1;
         else
            W := G.To (E_Idx);
            Stack (Top).Cur := G.Next (E_Idx);
            if not Visited (W) then
               Visited (W) := True;
               Count := Count + 1;
               Order (Count) := W;
               if Track_Times then
                  Clock := Clock + 1;
                  Discover (W) := Clock;
               end if;
               Push (W);
            end if;
         end if;
      end loop;
   end Run_DFS_From;

   -------------------------------------------------------------------------
   -- Public DFS
   -------------------------------------------------------------------------

   procedure DFS
     (G     : Graph;
      Start : Vertex_Id;
      Order : out Order_Array;
      Count : out Natural)
   is
      N       : constant Natural := G.N;
      Visited : Visited_Array := [others => False];
      Clock   : Natural := 0;
      D_Dummy : Time_Array (1 .. 1) := [others => 0];
      F_Dummy : Time_Array (1 .. 1) := [others => 0];
   begin
      Count := 0;
      Validate_Order (N, Order'First, Order'Last);

      if N = 0 then
         return;
      end if;

      Validate_Vertex (G, Start);
      Run_DFS_From
        (G, Start, Visited, Order, Count,
         False, D_Dummy, F_Dummy, Clock);
   end DFS;

   -------------------------------------------------------------------------
   -- Public DFS_Forest
   -------------------------------------------------------------------------

   procedure DFS_Forest
     (G     : Graph;
      Order : out Order_Array;
      Count : out Natural)
   is
      N       : constant Natural := G.N;
      Visited : Visited_Array := [others => False];
      Clock   : Natural := 0;
      D_Dummy : Time_Array (1 .. 1) := [others => 0];
      F_Dummy : Time_Array (1 .. 1) := [others => 0];
   begin
      Count := 0;
      Validate_Order (N, Order'First, Order'Last);

      if N = 0 then
         return;
      end if;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if not Visited (V) then
            Run_DFS_From
              (G, V, Visited, Order, Count,
               False, D_Dummy, F_Dummy, Clock);
         end if;
      end loop;
   end DFS_Forest;

   -------------------------------------------------------------------------
   -- Reachable
   -------------------------------------------------------------------------

   function Reachable
     (G : Graph; Start, Target : Vertex_Id) return Boolean
   is
      Order   : Order_Array (1 .. Max_Vertices);
      Count   : Natural := 0;
      Visited : Visited_Array := [others => False];
      Clock   : Natural := 0;
      D_Dummy : Time_Array (1 .. 1) := [others => 0];
      F_Dummy : Time_Array (1 .. 1) := [others => 0];
   begin
      Validate_Vertex (G, Start);
      Validate_Vertex (G, Target);

      if Start = Target then
         return True;
      end if;

      Run_DFS_From
        (G, Start, Visited, Order, Count,
         False, D_Dummy, F_Dummy, Clock);
      return Visited (Target);
   end Reachable;

   -------------------------------------------------------------------------
   -- DFS_Timestamps
   -------------------------------------------------------------------------

   procedure DFS_Timestamps
     (G        : Graph;
      Discover : out Time_Array;
      Finish   : out Time_Array)
   is
      N       : constant Natural := G.N;
      Visited : Visited_Array := [others => False];
      Order   : Order_Array (1 .. Max_Vertices);
      Count   : Natural := 0;
      Clock   : Natural := 0;
   begin
      Validate_Times
        (N, Discover'First, Discover'Last, Finish'First, Finish'Last);

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         Discover (V) := 0;
         Finish (V) := 0;
      end loop;

      for V in Vertex_Id range 1 .. Vertex_Id (N) loop
         if not Visited (V) then
            Run_DFS_From
              (G, V, Visited, Order, Count,
               True, Discover, Finish, Clock);
         end if;
      end loop;
   end DFS_Timestamps;

end Depth_First_Search;
