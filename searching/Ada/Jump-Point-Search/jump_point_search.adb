--  Jump_Point_Search body — JPS + A* on a fixed-capacity occupancy grid.

pragma Ada_2022;

package body Jump_Point_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   function Abs_I (V : Integer) return Natural is
     (if V >= 0 then Natural (V) else Natural (-V));

   function Same_Point (A, B : Point) return Boolean is
     (A.X = B.X and then A.Y = B.Y);

   function Cell_Free (G : Grid; X, Y : Integer) return Boolean is
   begin
      if X < 0 or else Y < 0
        or else X >= Integer (G.W) or else Y >= Integer (G.H)
      then
         return False;
      end if;
      return not G.Blocked (X, Y);
   end Cell_Free;

   --  Single step from (X,Y) by (Dx,Dy) under no-corner-cutting.
   function Step_Ok
     (G : Grid; X, Y, Dx, Dy : Integer) return Boolean
   is
      Nx : constant Integer := X + Dx;
      Ny : constant Integer := Y + Dy;
   begin
      if not Cell_Free (G, Nx, Ny) then
         return False;
      end if;
      if Dx /= 0 and then Dy /= 0 then
         --  Both orthogonal side cells must be free (no corner cut).
         if not Cell_Free (G, X + Dx, Y) then
            return False;
         end if;
         if not Cell_Free (G, X, Y + Dy) then
            return False;
         end if;
      end if;
      return True;
   end Step_Ok;

   function Step_Cost (Dx, Dy : Integer) return Float is
     (if Dx /= 0 and then Dy /= 0 then Diagonal_Cost else Cardinal_Cost);

   function Octile_Dist (Ax, Ay, Bx, By : Integer) return Float is
      Dx : constant Natural := Abs_I (Ax - Bx);
      Dy : constant Natural := Abs_I (Ay - By);
      Mn : constant Natural := Natural'Min (Dx, Dy);
      Mx : constant Natural := Natural'Max (Dx, Dy);
   begin
      return Float (Mx) * Cardinal_Cost
        + Float (Mn) * (Diagonal_Cost - Cardinal_Cost);
   end Octile_Dist;

   ---------------------------------------------------------------------------
   -- Public grid API
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
      for X in 0 .. Width - 1 loop
         for Y in 0 .. Height - 1 loop
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
      G.Blocked (Integer (P.X), Integer (P.Y)) := Blocked;
   end Set_Blocked;

   function Is_Blocked (G : Grid; P : Point) return Boolean is
   begin
      if not In_Bounds (G, P) then
         raise Invalid_Argument;
      end if;
      return G.Blocked (Integer (P.X), Integer (P.Y));
   end Is_Blocked;

   function Width (G : Grid) return Natural is (G.W);

   function Height (G : Grid) return Natural is (G.H);

   function In_Bounds (G : Grid; P : Point) return Boolean is
     (G.W > 0 and then G.H > 0
      and then P.X < G.W and then P.Y < G.H);

   function Can_Step
     (G : Grid; From, Too : Point) return Boolean
   is
      Dx, Dy : Integer;
   begin
      if not In_Bounds (G, From) then
         raise Invalid_Argument;
      end if;
      if not In_Bounds (G, Too) then
         return False;
      end if;
      Dx := Integer (Too.X) - Integer (From.X);
      Dy := Integer (Too.Y) - Integer (From.Y);
      if Abs_I (Dx) > 1 or else Abs_I (Dy) > 1 then
         return False;
      end if;
      if Dx = 0 and then Dy = 0 then
         return False;
      end if;
      return Step_Ok
        (G, Integer (From.X), Integer (From.Y), Dx, Dy);
   end Can_Step;

   function Octile_Heuristic (A, B : Point) return Float is
     (Octile_Dist
        (Integer (A.X), Integer (A.Y),
         Integer (B.X), Integer (B.Y)));

   function Path_Cost
     (G : Grid; Path : Path_Array; Length : Natural) return Float
   is
      Total : Float := 0.0;
      A, B  : Point;
      Dx, Dy : Integer;
   begin
      if Length > Path'Length then
         raise Invalid_Argument;
      end if;
      if Length <= 1 then
         return 0.0;
      end if;
      for I in Path'First .. Path'First + Length - 2 loop
         A := Path (I);
         B := Path (I + 1);
         if not Can_Step (G, A, B) then
            raise Invalid_Argument;
         end if;
         Dx := Integer (B.X) - Integer (A.X);
         Dy := Integer (B.Y) - Integer (A.Y);
         Total := Total + Step_Cost (Dx, Dy);
      end loop;
      return Total;
   end Path_Cost;

   ---------------------------------------------------------------------------
   -- Shared search state (stack-local, sized to Max_Width * Max_Height)
   ---------------------------------------------------------------------------

   subtype Cell_X is Integer range 0 .. Max_Width - 1;
   subtype Cell_Y is Integer range 0 .. Max_Height - 1;

   type Parent_Matrix is array (Cell_X, Cell_Y) of Point;
   type Cost_Matrix   is array (Cell_X, Cell_Y) of Float;
   type Flag_Matrix   is array (Cell_X, Cell_Y) of Boolean;
   type Dir_Matrix    is array (Cell_X, Cell_Y) of Integer;
   --  Incoming direction index 0 .. 7, or -1 for start / unset.

   type Open_Node is record
      P : Point  := (0, 0);
      F : Float  := 0.0;
      G : Float  := 0.0;
   end record;

   type Open_Array is array (1 .. Max_Path_Length) of Open_Node;

   --  Eight directions: E, SE, S, SW, W, NW, N, NE
   type Dir8 is record
      Dx, Dy : Integer;
   end record;

   Dirs : constant array (0 .. 7) of Dir8 :=
     [0 => (1, 0),  1 => (1, 1),  2 => (0, 1),  3 => (-1, 1),
      4 => (-1, 0), 5 => (-1, -1), 6 => (0, -1), 7 => (1, -1)];

   function Dir_Index (Dx, Dy : Integer) return Integer is
   begin
      for K in Dirs'Range loop
         if Dirs (K).Dx = Dx and then Dirs (K).Dy = Dy then
            return K;
         end if;
      end loop;
      return -1;
   end Dir_Index;

   ---------------------------------------------------------------------------
   -- Reconstruct cell-by-cell path from parent jump-point chain
   ---------------------------------------------------------------------------

   procedure Reconstruct
     (Parents : Parent_Matrix;
      Start   : Point;
      Goal    : Point;
      Path    : out Path_Array;
      Length  : out Natural)
   is
      --  Collect jump points Goal .. Start, then expand segments.
      type JP_List is array (1 .. Max_Path_Length) of Point;
      JPs    : JP_List;
      JP_N   : Natural := 0;
      Cur    : Point := Goal;
      Rev    : Path_Array (1 .. Max_Path_Length);
      Rev_N  : Natural := 0;
      A, B   : Point;
      Dx, Dy : Integer;
      Steps  : Natural;
      T      : Point;
   begin
      loop
         JP_N := JP_N + 1;
         JPs (JP_N) := Cur;
         exit when Same_Point (Cur, Start);
         Cur := Parents (Integer (Cur.X), Integer (Cur.Y));
      end loop;

      --  Expand each segment from Start toward Goal (JPs stored reversed).
      for S in reverse 2 .. JP_N loop
         A := JPs (S);
         B := JPs (S - 1);
         Dx := Integer (B.X) - Integer (A.X);
         Dy := Integer (B.Y) - Integer (A.Y);
         Steps := Natural'Max (Abs_I (Dx), Abs_I (Dy));
         if Steps = 0 then
            null;
         else
            Dx := Dx / Integer (Steps);
            Dy := Dy / Integer (Steps);
            --  Emit A, then intermediate cells (not B yet if more segments).
            Rev_N := Rev_N + 1;
            Rev (Rev_N) := A;
            for K in 1 .. Steps - 1 loop
               T :=
                 (X => Natural (Integer (A.X) + Dx * K),
                  Y => Natural (Integer (A.Y) + Dy * K));
               Rev_N := Rev_N + 1;
               Rev (Rev_N) := T;
            end loop;
         end if;
      end loop;
      --  Final goal cell.
      Rev_N := Rev_N + 1;
      Rev (Rev_N) := Goal;

      Length := Rev_N;
      for I in 1 .. Length loop
         Path (Path'First + I - 1) := Rev (I);
      end loop;
   end Reconstruct;

   ---------------------------------------------------------------------------
   -- JPS: forced neighbours + jump (no corner-cutting rules)
   ---------------------------------------------------------------------------

   --  Forward declaration via nested package-level mutual recursion using
   --  a single recursive Jump function.

   --  Jump (no corner-cutting): step in (Dx,Dy) until a jump point, the
   --  goal, or a blocked cell. Diagonal forced-neighbour early-outs are
   --  omitted (2012 / OnlyWhenNoObstacles); diagonal progress requires
   --  both orthogonal side cells free (enforced by Step_Ok).
   procedure Do_Jump
     (G              : Grid;
      X, Y           : Integer;
      Dx, Dy         : Integer;
      Goal_X, Goal_Y : Integer;
      Found          : out Boolean;
      JX, JY         : out Integer)
   is
      Cx : Integer := X;
      Cy : Integer := Y;
      Nx, Ny : Integer;
      Forced : Boolean;
      F1, F2 : Boolean;
      Ux, Uy, Vx, Vy : Integer;
   begin
      Found := False;
      JX := 0;
      JY := 0;

      loop
         Nx := Cx + Dx;
         Ny := Cy + Dy;
         if not Step_Ok (G, Cx, Cy, Dx, Dy) then
            return;
         end if;
         Cx := Nx;
         Cy := Ny;

         if Cx = Goal_X and then Cy = Goal_Y then
            Found := True;
            JX := Cx;
            JY := Cy;
            return;
         end if;

         if Dx /= 0 and then Dy /= 0 then
            --  Diagonal: look for horizontal / vertical jump points.
            Do_Jump (G, Cx, Cy, Dx, 0, Goal_X, Goal_Y, F1, Ux, Uy);
            if F1 then
               Found := True;
               JX := Cx;
               JY := Cy;
               return;
            end if;
            Do_Jump (G, Cx, Cy, 0, Dy, Goal_X, Goal_Y, F2, Vx, Vy);
            if F2 then
               Found := True;
               JX := Cx;
               JY := Cy;
               return;
            end if;
         else
            --  Cardinal forced-neighbour tests.
            if Dy = 0 then
               Forced :=
                 (Cell_Free (G, Cx, Cy + 1)
                  and then not Cell_Free (G, Cx - Dx, Cy + 1))
                 or else
                 (Cell_Free (G, Cx, Cy - 1)
                  and then not Cell_Free (G, Cx - Dx, Cy - 1));
            else
               Forced :=
                 (Cell_Free (G, Cx + 1, Cy)
                  and then not Cell_Free (G, Cx + 1, Cy - Dy))
                 or else
                 (Cell_Free (G, Cx - 1, Cy)
                  and then not Cell_Free (G, Cx - 1, Cy - Dy));
            end if;
            if Forced then
               Found := True;
               JX := Cx;
               JY := Cy;
               return;
            end if;
         end if;
      end loop;
   end Do_Jump;

   type Dir_Buf is array (0 .. 7) of Integer;

   --  Neighbour directions after arriving via (PDx,PDy). No-corner-cutting
   --  rules (Harabor & Grastien 2012 / OnlyWhenNoObstacles): diagonal
   --  arrivals keep natural components only; cardinal arrivals also keep
   --  orthogonal side steps (up to four extra neighbours).
   procedure Collect_Neighbours
     (G        : Grid;
      X, Y     : Integer;
      PDx, PDy : Integer;
      N        : out Natural;
      Dxs, Dys : out Dir_Buf)
   is
      procedure Add (Dx, Dy : Integer) is
      begin
         if N < 8 then
            Dxs (N) := Dx;
            Dys (N) := Dy;
            N := N + 1;
         end if;
      end Add;
   begin
      N := 0;
      Dxs := [others => 0];
      Dys := [others => 0];

      if PDx = 0 and then PDy = 0 then
         for K in Dirs'Range loop
            if Step_Ok (G, X, Y, Dirs (K).Dx, Dirs (K).Dy) then
               Add (Dirs (K).Dx, Dirs (K).Dy);
            end if;
         end loop;
         return;
      end if;

      if PDx /= 0 and then PDy /= 0 then
         --  Diagonal arrival: natural cardinals + diagonal if both free.
         if Cell_Free (G, X, Y + PDy) then
            Add (0, PDy);
         end if;
         if Cell_Free (G, X + PDx, Y) then
            Add (PDx, 0);
         end if;
         if Cell_Free (G, X, Y + PDy)
           and then Cell_Free (G, X + PDx, Y)
         then
            Add (PDx, PDy);
         end if;
      elsif PDy = 0 then
         --  Horizontal arrival.
         if Cell_Free (G, X + PDx, Y) then
            Add (PDx, 0);
            if Cell_Free (G, X, Y + 1) then
               Add (PDx, 1);
            end if;
            if Cell_Free (G, X, Y - 1) then
               Add (PDx, -1);
            end if;
         end if;
         if Cell_Free (G, X, Y + 1) then
            Add (0, 1);
         end if;
         if Cell_Free (G, X, Y - 1) then
            Add (0, -1);
         end if;
      else
         --  Vertical arrival.
         if Cell_Free (G, X, Y + PDy) then
            Add (0, PDy);
            if Cell_Free (G, X + 1, Y) then
               Add (1, PDy);
            end if;
            if Cell_Free (G, X - 1, Y) then
               Add (-1, PDy);
            end if;
         end if;
         if Cell_Free (G, X + 1, Y) then
            Add (1, 0);
         end if;
         if Cell_Free (G, X - 1, Y) then
            Add (-1, 0);
         end if;
      end if;
   end Collect_Neighbours;

   ---------------------------------------------------------------------------
   -- Shared open-set helpers
   ---------------------------------------------------------------------------

   procedure Open_Push
     (Open  : in out Open_Array;
      Count : in out Natural;
      P     : Point;
      G_Cost, F_Cost : Float)
   is
   begin
      Count := Count + 1;
      Open (Count) := (P => P, F => F_Cost, G => G_Cost);
   end Open_Push;

   procedure Open_Pop_Min
     (Open  : in out Open_Array;
      Count : in out Natural;
      Node  : out Open_Node)
   is
      Best : Positive := 1;
   begin
      for I in 2 .. Count loop
         if Open (I).F < Open (Best).F
           or else
             (Open (I).F = Open (Best).F
              and then Open (I).G > Open (Best).G)
         then
            Best := I;
         end if;
      end loop;
      Node := Open (Best);
      Open (Best) := Open (Count);
      Count := Count - 1;
   end Open_Pop_Min;

   ---------------------------------------------------------------------------
   -- Find_Path (JPS)
   ---------------------------------------------------------------------------

   function Find_Path
     (G      : Grid;
      Start  : Point;
      Goal   : Point;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      Parents : Parent_Matrix := [others => [others => (0, 0)]];
      G_Cost  : Cost_Matrix := [others => [others => Float'Last]];
      Closed  : Flag_Matrix := [others => [others => False]];
      In_Dir  : Dir_Matrix  := [others => [others => -1]];
      Open    : Open_Array;
      O_Count : Natural := 0;
      Node    : Open_Node;
      Sx, Sy  : Integer;
      Gx, Gy  : Integer;
      Cx, Cy  : Integer;
      PDx, PDy : Integer;
      N_Dirs  : Natural;
      Dxs, Dys : Dir_Buf;
      Found_J : Boolean;
      JX, JY  : Integer;
      Ng      : Float;
      H       : Float;
      JP      : Point;
      Idx     : Integer;
   begin
      Length := 0;
      if Path'Length < Max_Path_Length then
         raise Invalid_Argument;
      end if;
      if not In_Bounds (G, Start) or else not In_Bounds (G, Goal) then
         raise Invalid_Argument;
      end if;
      if Is_Blocked (G, Start) or else Is_Blocked (G, Goal) then
         Length := 0;
         return False;
      end if;

      if Same_Point (Start, Goal) then
         Path (Path'First) := Start;
         Length := 1;
         return True;
      end if;

      Sx := Integer (Start.X);
      Sy := Integer (Start.Y);
      Gx := Integer (Goal.X);
      Gy := Integer (Goal.Y);

      G_Cost (Sx, Sy) := 0.0;
      In_Dir (Sx, Sy) := -1;
      Parents (Sx, Sy) := Start;
      Open_Push
        (Open, O_Count, Start, 0.0, Octile_Dist (Sx, Sy, Gx, Gy));

      while O_Count > 0 loop
         Open_Pop_Min (Open, O_Count, Node);
         Cx := Integer (Node.P.X);
         Cy := Integer (Node.P.Y);

         if Closed (Cx, Cy) then
            goto Continue_JPS;
         end if;
         Closed (Cx, Cy) := True;

         if Cx = Gx and then Cy = Gy then
            Reconstruct (Parents, Start, Goal, Path, Length);
            return True;
         end if;

         Idx := In_Dir (Cx, Cy);
         if Idx < 0 then
            PDx := 0;
            PDy := 0;
         else
            PDx := Dirs (Idx).Dx;
            PDy := Dirs (Idx).Dy;
         end if;

         Collect_Neighbours (G, Cx, Cy, PDx, PDy, N_Dirs, Dxs, Dys);

         for K in 0 .. Integer (N_Dirs) - 1 loop
            Do_Jump
              (G, Cx, Cy, Dxs (K), Dys (K), Gx, Gy, Found_J, JX, JY);
            if Found_J then
               Ng := G_Cost (Cx, Cy)
                 + Octile_Dist (Cx, Cy, JX, JY);
               if Ng < G_Cost (JX, JY) then
                  G_Cost (JX, JY) := Ng;
                  Parents (JX, JY) := Node.P;
                  In_Dir (JX, JY) := Dir_Index (Dxs (K), Dys (K));
                  H := Octile_Dist (JX, JY, Gx, Gy);
                  JP := (X => Natural (JX), Y => Natural (JY));
                  if not Closed (JX, JY) then
                     Open_Push (Open, O_Count, JP, Ng, Ng + H);
                  end if;
               end if;
            end if;
         end loop;

         <<Continue_JPS>>
      end loop;

      Length := 0;
      return False;
   end Find_Path;

   ---------------------------------------------------------------------------
   -- A_Star_Grid oracle
   ---------------------------------------------------------------------------

   function A_Star_Grid
     (G      : Grid;
      Start  : Point;
      Goal   : Point;
      Path   : out Path_Array;
      Length : out Natural) return Boolean
   is
      Parents : Parent_Matrix := [others => [others => (0, 0)]];
      G_Cost  : Cost_Matrix := [others => [others => Float'Last]];
      Closed  : Flag_Matrix := [others => [others => False]];
      Open    : Open_Array;
      O_Count : Natural := 0;
      Node    : Open_Node;
      Sx, Sy, Gx, Gy, Cx, Cy, Nx, Ny : Integer;
      Ng, H : Float;
      NP : Point;
      --  Full path via parents (adjacent cells only).
      Cur : Point;
      Rev : Path_Array (1 .. Max_Path_Length);
      Rev_N : Natural;
   begin
      Length := 0;
      if Path'Length < Max_Path_Length then
         raise Invalid_Argument;
      end if;
      if not In_Bounds (G, Start) or else not In_Bounds (G, Goal) then
         raise Invalid_Argument;
      end if;
      if Is_Blocked (G, Start) or else Is_Blocked (G, Goal) then
         Length := 0;
         return False;
      end if;

      if Same_Point (Start, Goal) then
         Path (Path'First) := Start;
         Length := 1;
         return True;
      end if;

      Sx := Integer (Start.X);
      Sy := Integer (Start.Y);
      Gx := Integer (Goal.X);
      Gy := Integer (Goal.Y);

      G_Cost (Sx, Sy) := 0.0;
      Parents (Sx, Sy) := Start;
      Open_Push
        (Open, O_Count, Start, 0.0, Octile_Dist (Sx, Sy, Gx, Gy));

      while O_Count > 0 loop
         Open_Pop_Min (Open, O_Count, Node);
         Cx := Integer (Node.P.X);
         Cy := Integer (Node.P.Y);

         if Closed (Cx, Cy) then
            goto Continue_AS;
         end if;
         Closed (Cx, Cy) := True;

         if Cx = Gx and then Cy = Gy then
            --  Reconstruct adjacent parent chain.
            Cur := Goal;
            Rev_N := 0;
            loop
               Rev_N := Rev_N + 1;
               Rev (Rev_N) := Cur;
               exit when Same_Point (Cur, Start);
               Cur := Parents (Integer (Cur.X), Integer (Cur.Y));
            end loop;
            Length := Rev_N;
            for I in 1 .. Length loop
               Path (Path'First + I - 1) := Rev (Length - I + 1);
            end loop;
            return True;
         end if;

         for K in Dirs'Range loop
            Nx := Cx + Dirs (K).Dx;
            Ny := Cy + Dirs (K).Dy;
            if Step_Ok (G, Cx, Cy, Dirs (K).Dx, Dirs (K).Dy) then
               if not Closed (Nx, Ny) then
                  Ng := G_Cost (Cx, Cy)
                    + Step_Cost (Dirs (K).Dx, Dirs (K).Dy);
                  if Ng < G_Cost (Nx, Ny) then
                     G_Cost (Nx, Ny) := Ng;
                     Parents (Nx, Ny) := Node.P;
                     H := Octile_Dist (Nx, Ny, Gx, Gy);
                     NP := (X => Natural (Nx), Y => Natural (Ny));
                     Open_Push (Open, O_Count, NP, Ng, Ng + H);
                  end if;
               end if;
            end if;
         end loop;

         <<Continue_AS>>
      end loop;

      Length := 0;
      return False;
   end A_Star_Grid;

end Jump_Point_Search;
