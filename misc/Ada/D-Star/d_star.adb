--  D_Star body — educational D* Lite (Koenig & Likhachev).

pragma Ada_2022;

package body D_Star
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   function Finite (X : Float) return Boolean is
     (X < Infinity * 0.5);

   function Min_F (A, B : Float) return Float is
     (if A <= B then A else B);

   function Key_Less (A, B : Key_Pair) return Boolean is
     (A.K1 < B.K1 or else (A.K1 = B.K1 and then A.K2 < B.K2));

   function Same_Point (A, B : Point) return Boolean is
     (A.X = B.X and then A.Y = B.Y);

   function Effective_Cost (G : Grid; P : Point) return Float is
     (if G.Blocked (P.X, P.Y) then Infinity else G.Cost (P.X, P.Y));

   --  4-connected offsets: N, E, S, W
   type Offset is record
      DX, DY : Integer;
   end record;
   Neigh_Off : constant array (1 .. 4) of Offset :=
     [(-1, 0), (1, 0), (0, -1), (0, 1)];

   function Neighbour (P : Point; K : Positive) return Point is
     ((Natural (Integer (P.X) + Neigh_Off (K).DX),
       Natural (Integer (P.Y) + Neigh_Off (K).DY)));

   function Neighbour_In_Bounds
     (G : Grid; P : Point; K : Positive) return Boolean
   is
      NX : constant Integer := Integer (P.X) + Neigh_Off (K).DX;
      NY : constant Integer := Integer (P.Y) + Neigh_Off (K).DY;
   begin
      return NX >= 0 and then NY >= 0
        and then NX < G.W and then NY < G.H;
   end Neighbour_In_Bounds;

   --  Edge cost of step From -> Too (enter Too). Infinity if illegal.
   function Step_Cost (G : Grid; From, Too : Point) return Float is
   begin
      if not In_Bounds (G, From) or else not In_Bounds (G, Too) then
         return Infinity;
      end if;
      if abs (Integer (From.X) - Integer (Too.X))
           + abs (Integer (From.Y) - Integer (Too.Y)) /= 1
      then
         return Infinity;
      end if;
      if G.Blocked (Too.X, Too.Y) then
         return Infinity;
      end if;
      --  Destination must be free; From may be Start even if we later
      --  disallow standing on blocked Start/Goal for path existence.
      return G.Cost (Too.X, Too.Y) * Cardinal_Cost;
   end Step_Cost;

   ---------------------------------------------------------------------------
   -- Grid API
   ---------------------------------------------------------------------------

   procedure Clear
     (G      : in out Grid;
      Width  : Positive;
      Height : Positive)
   is
   begin
      if Width > Max_Width or else Height > Max_Height then
         raise Invalid_Argument;
      end if;
      G.W := Width;
      G.H := Height;
      for X in 0 .. Max_Width - 1 loop
         for Y in 0 .. Max_Height - 1 loop
            G.Cost (X, Y) := 1.0;
            G.Blocked (X, Y) := False;
         end loop;
      end loop;
   end Clear;

   procedure Set_Blocked
     (G       : in out Grid;
      P       : Point;
      Blocked : Boolean := True)
   is
   begin
      if not In_Bounds (G, P) then
         raise Invalid_Argument;
      end if;
      G.Blocked (P.X, P.Y) := Blocked;
      if not Blocked and then not Finite (G.Cost (P.X, P.Y)) then
         G.Cost (P.X, P.Y) := 1.0;
      end if;
   end Set_Blocked;

   procedure Set_Cell_Cost
     (G    : in out Grid;
      P    : Point;
      Cost : Float)
   is
   begin
      if not In_Bounds (G, P) then
         raise Invalid_Argument;
      end if;
      if not (Cost > 0.0) or else Cost > Max_Cell_Cost then
         raise Invalid_Argument;
      end if;
      G.Cost (P.X, P.Y) := Cost;
      G.Blocked (P.X, P.Y) := False;
   end Set_Cell_Cost;

   function Is_Blocked (G : Grid; P : Point) return Boolean is
   begin
      if not In_Bounds (G, P) then
         raise Invalid_Argument;
      end if;
      return G.Blocked (P.X, P.Y);
   end Is_Blocked;

   function Get_Cell_Cost (G : Grid; P : Point) return Float is
   begin
      if not In_Bounds (G, P) then
         raise Invalid_Argument;
      end if;
      return Effective_Cost (G, P);
   end Get_Cell_Cost;

   function Width  (G : Grid) return Natural is (G.W);
   function Height (G : Grid) return Natural is (G.H);

   function In_Bounds (G : Grid; P : Point) return Boolean is
     (P.X < G.W and then P.Y < G.H);

   function Manhattan_Heuristic (A, B : Point) return Float is
      DX : constant Natural :=
        (if A.X >= B.X then A.X - B.X else B.X - A.X);
      DY : constant Natural :=
        (if A.Y >= B.Y then A.Y - B.Y else B.Y - A.Y);
   begin
      return Float (DX + DY) * Cardinal_Cost;
   end Manhattan_Heuristic;

   function Path_Cost
     (G : Grid; Path : Path_Array; Length : Natural) return Float
   is
      Total : Float := 0.0;
   begin
      if Length > Path'Length then
         raise Invalid_Argument;
      end if;
      if Length <= 1 then
         return 0.0;
      end if;
      for I in Path'First .. Path'First + Length - 2 loop
         declare
            C : constant Float :=
              Step_Cost (G, Path (I), Path (I + 1));
         begin
            if not Finite (C) then
               raise Invalid_Argument;
            end if;
            Total := Total + C;
         end;
      end loop;
      return Total;
   end Path_Cost;

   ---------------------------------------------------------------------------
   -- D* Lite internals
   ---------------------------------------------------------------------------

   function Calculate_Key (Pl : Planner; U : Point) return Key_Pair is
      Gv  : constant Float := Pl.G_Val (U.X, U.Y);
      Rv  : constant Float := Pl.Rhs (U.X, U.Y);
      M   : constant Float := Min_F (Gv, Rv);
      K   : Key_Pair;
   begin
      if not Finite (M) then
         K.K1 := Infinity;
         K.K2 := Infinity;
      else
         K.K1 := M + Manhattan_Heuristic (Pl.Start, U) + Pl.Km;
         K.K2 := M;
      end if;
      return K;
   end Calculate_Key;

   procedure Heap_Swap (Pl : in out Planner; I, J : Positive) is
      T : constant Heap_Entry := Pl.Heap (I);
   begin
      Pl.Heap (I) := Pl.Heap (J);
      Pl.Heap (J) := T;
   end Heap_Swap;

   procedure Heap_Sift_Up (Pl : in out Planner; Idx : Positive) is
      I : Positive := Idx;
      P : Positive;
   begin
      while I > 1 loop
         P := I / 2;
         if Key_Less (Pl.Heap (I).Key, Pl.Heap (P).Key) then
            Heap_Swap (Pl, I, P);
            I := P;
         else
            exit;
         end if;
      end loop;
   end Heap_Sift_Up;

   procedure Heap_Sift_Down (Pl : in out Planner; Idx : Positive) is
      I     : Positive := Idx;
      Left  : Natural;
      Right : Natural;
      Best  : Positive;
   begin
      loop
         Left  := 2 * I;
         Right := Left + 1;
         Best  := I;
         if Left <= Pl.Heap_Size
           and then Key_Less (Pl.Heap (Left).Key, Pl.Heap (Best).Key)
         then
            Best := Left;
         end if;
         if Right <= Pl.Heap_Size
           and then Key_Less (Pl.Heap (Right).Key, Pl.Heap (Best).Key)
         then
            Best := Right;
         end if;
         exit when Best = I;
         Heap_Swap (Pl, I, Best);
         I := Best;
      end loop;
   end Heap_Sift_Down;

   procedure Heap_Insert (Pl : in out Planner; U : Point; K : Key_Pair) is
   begin
      if Pl.Heap_Size >= Heap_Cap then
         --  Extremely unlikely with lazy duplicates on 64x64; treat as
         --  exhausted open set (path will be reported missing).
         return;
      end if;
      Pl.Heap_Size := Pl.Heap_Size + 1;
      Pl.Heap (Pl.Heap_Size) := (Key => K, P => U);
      Heap_Sift_Up (Pl, Pl.Heap_Size);
   end Heap_Insert;

   function Heap_Top_Key (Pl : Planner) return Key_Pair is
   begin
      if Pl.Heap_Size = 0 then
         return (Infinity, Infinity);
      end if;
      return Pl.Heap (1).Key;
   end Heap_Top_Key;

   procedure Heap_Pop (Pl : in out Planner; U : out Point; K : out Key_Pair) is
   begin
      U := Pl.Heap (1).P;
      K := Pl.Heap (1).Key;
      Pl.Heap (1) := Pl.Heap (Pl.Heap_Size);
      Pl.Heap_Size := Pl.Heap_Size - 1;
      if Pl.Heap_Size > 0 then
         Heap_Sift_Down (Pl, 1);
      end if;
   end Heap_Pop;

   procedure Update_Vertex (Pl : in out Planner; U : Point) is
      Best : Float;
   begin
      if not Same_Point (U, Pl.Goal) then
         Best := Infinity;
         for K in 1 .. 4 loop
            if Neighbour_In_Bounds (Pl.Map, U, K) then
               declare
                  S  : constant Point := Neighbour (U, K);
                  C  : constant Float := Step_Cost (Pl.Map, U, S);
                  Cand : Float;
               begin
                  if Finite (C) and then Finite (Pl.G_Val (S.X, S.Y)) then
                     Cand := C + Pl.G_Val (S.X, S.Y);
                     if Cand < Best then
                        Best := Cand;
                     end if;
                  end if;
               end;
            end if;
         end loop;
         Pl.Rhs (U.X, U.Y) := Best;
      end if;

      --  Lazy open list: insert when inconsistent (duplicates OK).
      if Pl.G_Val (U.X, U.Y) /= Pl.Rhs (U.X, U.Y) then
         Heap_Insert (Pl, U, Calculate_Key (Pl, U));
      end if;
   end Update_Vertex;

   procedure Compute_Shortest_Path (Pl : in out Planner) is
      U       : Point;
      K_Old   : Key_Pair;
      K_New   : Key_Pair;
      Start_K : Key_Pair;
   begin
      Pl.Expansions := 0;
      loop
         Start_K := Calculate_Key (Pl, Pl.Start);
         --  Terminate when the open set is empty, or TopKey >= key(start)
         --  and start is locally consistent (paper condition negated).
         if Pl.Heap_Size = 0 then
            exit;
         end if;
         if not Key_Less (Heap_Top_Key (Pl), Start_K)
           and then Pl.Rhs (Pl.Start.X, Pl.Start.Y)
                  = Pl.G_Val (Pl.Start.X, Pl.Start.Y)
         then
            exit;
         end if;

         Heap_Pop (Pl, U, K_Old);
         K_New := Calculate_Key (Pl, U);

         --  Stale heap entry (lazy duplicate keys)
         if Key_Less (K_Old, K_New) then
            Heap_Insert (Pl, U, K_New);
         elsif Pl.G_Val (U.X, U.Y) > Pl.Rhs (U.X, U.Y) then
            --  Overconsistent: g := rhs; update predecessors
            Pl.G_Val (U.X, U.Y) := Pl.Rhs (U.X, U.Y);
            Pl.Expansions := Pl.Expansions + 1;
            for K in 1 .. 4 loop
               if Neighbour_In_Bounds (Pl.Map, U, K) then
                  Update_Vertex (Pl, Neighbour (U, K));
               end if;
            end loop;
         elsif Pl.G_Val (U.X, U.Y) < Pl.Rhs (U.X, U.Y) then
            --  Underconsistent: g := inf; update u and predecessors
            Pl.G_Val (U.X, U.Y) := Infinity;
            Pl.Expansions := Pl.Expansions + 1;
            Update_Vertex (Pl, U);
            for K in 1 .. 4 loop
               if Neighbour_In_Bounds (Pl.Map, U, K) then
                  Update_Vertex (Pl, Neighbour (U, K));
               end if;
            end loop;
         end if;
         --  else g = rhs: stale consistent duplicate — ignore
      end loop;
   end Compute_Shortest_Path;

   procedure Touch_Cell (Pl : in out Planner; P : Point) is
   begin
      --  Changing cell P affects edges into P, i.e. rhs of predecessors
      --  (neighbours that step into P) and possibly P itself.
      Update_Vertex (Pl, P);
      for K in 1 .. 4 loop
         if Neighbour_In_Bounds (Pl.Map, P, K) then
            Update_Vertex (Pl, Neighbour (P, K));
         end if;
      end loop;
   end Touch_Cell;

   ---------------------------------------------------------------------------
   -- Planner API
   ---------------------------------------------------------------------------

   procedure Require_Init (Pl : Planner) is
   begin
      if not Pl.Initialized then
         raise Invalid_Argument;
      end if;
   end Require_Init;

   procedure Initialize
     (Pl    : in out Planner;
      G     : Grid;
      Start : Point;
      Goal  : Point)
   is
   begin
      if not In_Bounds (G, Start) or else not In_Bounds (G, Goal) then
         raise Invalid_Argument;
      end if;

      Pl.Map := G;
      Pl.Start := Start;
      Pl.Goal := Goal;
      Pl.Km := 0.0;
      Pl.Heap_Size := 0;
      Pl.Expansions := 0;
      Pl.Initialized := True;

      for X in 0 .. Max_Width - 1 loop
         for Y in 0 .. Max_Height - 1 loop
            Pl.G_Val (X, Y) := Infinity;
            Pl.Rhs (X, Y) := Infinity;
         end loop;
      end loop;

      --  Goal is the search "origin": rhs(goal) = 0
      Pl.Rhs (Goal.X, Goal.Y) := 0.0;
      Heap_Insert (Pl, Goal, Calculate_Key (Pl, Goal));
      Compute_Shortest_Path (Pl);
   end Initialize;

   function Path_Exists (Pl : Planner) return Boolean is
   begin
      Require_Init (Pl);
      if Pl.Map.Blocked (Pl.Start.X, Pl.Start.Y)
        or else Pl.Map.Blocked (Pl.Goal.X, Pl.Goal.Y)
      then
         return False;
      end if;
      return Finite (Pl.G_Val (Pl.Start.X, Pl.Start.Y))
        and then Pl.Rhs (Pl.Start.X, Pl.Start.Y)
               = Pl.G_Val (Pl.Start.X, Pl.Start.Y);
   end Path_Exists;

   procedure Get_Path
     (Pl     : Planner;
      Path   : out Path_Array;
      Length : out Natural)
   is
      Cur    : Point;
      Guard  : Natural := 0;
      Limit  : constant Natural := Max_Path_Length;
   begin
      Require_Init (Pl);
      if Path'Length < Max_Path_Length then
         raise Invalid_Argument;
      end if;
      Length := 0;
      if not Path_Exists (Pl) then
         return;
      end if;

      Cur := Pl.Start;
      Path (Path'First) := Cur;
      Length := 1;

      if Same_Point (Pl.Start, Pl.Goal) then
         return;
      end if;

      while not Same_Point (Cur, Pl.Goal) loop
         declare
            Best_S : Point := Cur;
            Best_C : Float := Infinity;
            Found  : Boolean := False;
         begin
            for K in 1 .. 4 loop
               if Neighbour_In_Bounds (Pl.Map, Cur, K) then
                  declare
                     S : constant Point := Neighbour (Cur, K);
                     C : constant Float := Step_Cost (Pl.Map, Cur, S);
                     Cand : Float;
                  begin
                     if Finite (C) and then Finite (Pl.G_Val (S.X, S.Y)) then
                        Cand := C + Pl.G_Val (S.X, S.Y);
                        if (not Found) or else Cand < Best_C then
                           Best_C := Cand;
                           Best_S := S;
                           Found := True;
                        end if;
                     end if;
                  end;
               end if;
            end loop;
            if not Found then
               Length := 0;
               return;
            end if;
            Cur := Best_S;
            Length := Length + 1;
            if Length > Limit then
               Length := 0;
               return;
            end if;
            Path (Path'First + Length - 1) := Cur;
         end;
         Guard := Guard + 1;
         if Guard > Limit then
            Length := 0;
            return;
         end if;
      end loop;
   end Get_Path;

   function Path_Cost (Pl : Planner) return Float is
      Buf : Path_Array (1 .. Max_Path_Length);
      Len : Natural;
   begin
      Require_Init (Pl);
      if not Path_Exists (Pl) then
         return Infinity;
      end if;
      Get_Path (Pl, Buf, Len);
      if Len = 0 then
         return Infinity;
      end if;
      return Path_Cost (Pl.Map, Buf, Len);
   end Path_Cost;

   function Expansion_Count (Pl : Planner) return Natural is
   begin
      Require_Init (Pl);
      return Pl.Expansions;
   end Expansion_Count;

   function Start_Point (Pl : Planner) return Point is
   begin
      Require_Init (Pl);
      return Pl.Start;
   end Start_Point;

   function Goal_Point (Pl : Planner) return Point is
   begin
      Require_Init (Pl);
      return Pl.Goal;
   end Goal_Point;

   procedure Update_Cell_Cost
     (Pl   : in out Planner;
      P    : Point;
      Cost : Float)
   is
   begin
      Require_Init (Pl);
      Set_Cell_Cost (Pl.Map, P, Cost);
      Touch_Cell (Pl, P);
   end Update_Cell_Cost;

   procedure Set_Blocked
     (Pl      : in out Planner;
      P       : Point;
      Blocked : Boolean := True)
   is
   begin
      Require_Init (Pl);
      Set_Blocked (Pl.Map, P, Blocked);
      Touch_Cell (Pl, P);
   end Set_Blocked;

   procedure Replan (Pl : in out Planner) is
   begin
      Require_Init (Pl);
      --  Start fixed → km unchanged (educational fixed-start replan).
      Compute_Shortest_Path (Pl);
   end Replan;

   ---------------------------------------------------------------------------
   -- A* oracle
   ---------------------------------------------------------------------------

   function A_Star_Replan
     (G      : Grid;
      Start  : Point;
      Goal   : Point;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      type Node_State is (Unseen, Open, Closed);
      type State_Matrix is
        array (0 .. Max_Width - 1, 0 .. Max_Height - 1) of Node_State;
      type Parent_Matrix is
        array (0 .. Max_Width - 1, 0 .. Max_Height - 1) of Point;

      G_Score : Val_Matrix := [others => [others => Infinity]];
      F_Score : Val_Matrix := [others => [others => Infinity]];
      State   : State_Matrix := [others => [others => Unseen]];
      Parent  : Parent_Matrix := [others => [others => (0, 0)]];

      --  Simple open list as unsorted array of points
      Open_List : array (1 .. Max_Width * Max_Height) of Point;
      Open_N    : Natural := 0;

      procedure Open_Push (P : Point) is
      begin
         Open_N := Open_N + 1;
         Open_List (Open_N) := P;
         State (P.X, P.Y) := Open;
      end Open_Push;

      function Open_Pop_Best return Point is
         Best_I : Positive := 1;
         Best_F : Float;
         Best_G : Float;
         P      : Point;
      begin
         Best_F := F_Score (Open_List (1).X, Open_List (1).Y);
         Best_G := G_Score (Open_List (1).X, Open_List (1).Y);
         for I in 2 .. Open_N loop
            declare
               Q : constant Point := Open_List (I);
               F : constant Float := F_Score (Q.X, Q.Y);
               Gg : constant Float := G_Score (Q.X, Q.Y);
            begin
               if F < Best_F or else (F = Best_F and then Gg > Best_G) then
                  Best_I := I;
                  Best_F := F;
                  Best_G := Gg;
               end if;
            end;
         end loop;
         P := Open_List (Best_I);
         Open_List (Best_I) := Open_List (Open_N);
         Open_N := Open_N - 1;
         State (P.X, P.Y) := Closed;
         return P;
      end Open_Pop_Best;

      Cur : Point;
   begin
      Length := 0;
      if not In_Bounds (G, Start) or else not In_Bounds (G, Goal) then
         raise Invalid_Argument;
      end if;
      if Path'Length < Max_Path_Length then
         raise Invalid_Argument;
      end if;
      if G.Blocked (Start.X, Start.Y) or else G.Blocked (Goal.X, Goal.Y) then
         return False;
      end if;
      if Same_Point (Start, Goal) then
         Path (Path'First) := Start;
         Length := 1;
         return True;
      end if;

      G_Score (Start.X, Start.Y) := 0.0;
      F_Score (Start.X, Start.Y) := Manhattan_Heuristic (Start, Goal);
      Open_Push (Start);

      while Open_N > 0 loop
         Cur := Open_Pop_Best;
         if Same_Point (Cur, Goal) then
            --  Reconstruct
            declare
               Stack : array (1 .. Max_Path_Length) of Point;
               SN    : Natural := 0;
               C     : Point := Goal;
            begin
               loop
                  SN := SN + 1;
                  Stack (SN) := C;
                  exit when Same_Point (C, Start);
                  C := Parent (C.X, C.Y);
               end loop;
               Length := SN;
               for I in 1 .. SN loop
                  Path (Path'First + I - 1) := Stack (SN - I + 1);
               end loop;
               return True;
            end;
         end if;

         for K in 1 .. 4 loop
            if Neighbour_In_Bounds (G, Cur, K) then
               declare
                  S    : constant Point := Neighbour (Cur, K);
                  Step : constant Float := Step_Cost (G, Cur, S);
                  Tent : Float;
               begin
                  if Finite (Step) and then State (S.X, S.Y) /= Closed then
                     Tent := G_Score (Cur.X, Cur.Y) + Step;
                     if Tent < G_Score (S.X, S.Y) then
                        Parent (S.X, S.Y) := Cur;
                        G_Score (S.X, S.Y) := Tent;
                        F_Score (S.X, S.Y) :=
                          Tent + Manhattan_Heuristic (S, Goal);
                        if State (S.X, S.Y) /= Open then
                           Open_Push (S);
                        end if;
                     end if;
                  end if;
               end;
            end if;
         end loop;
      end loop;

      return False;
   end A_Star_Replan;

end D_Star;
