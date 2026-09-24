--  Coloring_Algorithm body — greedy, BFS 2-colour, exact backtracking.

pragma Ada_2022;

package body Coloring_Algorithm
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
      G.M := 0;
      G.A := 0;
      for V in Vertex_Id loop
         G.Head (V) := 0;
      end loop;
   end Clear;

   procedure Append_Arc (G : in out Graph; From, To : Vertex_Id) is
   begin
      G.A := G.A + 1;
      G.To (G.A) := To;
      G.Next (G.A) := G.Head (From);
      G.Head (From) := G.A;
   end Append_Arc;

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id) is
   begin
      if G.N = 0
        or else Natural (U) > G.N
        or else Natural (V) > G.N
      then
         raise Invalid_Argument;
      end if;
      if U = V then
         raise Invalid_Argument;
      end if;
      if G.M = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.M := G.M + 1;
      Append_Arc (G, U, V);
      Append_Arc (G, V, U);
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.M);
   end Edge_Count;

   function Degree (G : Graph; V : Vertex_Id) return Natural is
      E   : Natural;
      Deg : Natural := 0;
   begin
      if G.N = 0 or else Natural (V) > G.N then
         raise Invalid_Argument;
      end if;
      E := G.Head (V);
      while E /= 0 loop
         Deg := Deg + 1;
         E := G.Next (E);
      end loop;
      return Deg;
   end Degree;

   -------------------------------------------------------------------------
   -- Shared validation
   -------------------------------------------------------------------------

   procedure Validate_Color_Bounds
     (N : Natural; First : Vertex_Id; Last : Vertex_Id)
   is
   begin
      if N = 0 then
         return;
      end if;
      if First /= 1 or else Natural (Last) < N then
         raise Invalid_Argument;
      end if;
   end Validate_Color_Bounds;

   -------------------------------------------------------------------------
   -- Neighbour colour conflict helpers
   -------------------------------------------------------------------------

   function Neighbour_Uses
     (G : Graph; V : Vertex_Id; Color : Positive; Colors : Color_Array)
      return Boolean
   is
      E : Natural := G.Head (V);
      W : Vertex_Id;
   begin
      while E /= 0 loop
         W := G.To (E);
         if W <= Colors'Last
           and then Colors (W) = Natural (Color)
         then
            return True;
         end if;
         E := G.Next (E);
      end loop;
      return False;
   end Neighbour_Uses;

   -------------------------------------------------------------------------
   -- Greedy colouring
   -------------------------------------------------------------------------

   procedure Build_Order
     (G     : Graph;
      Order : Order_Kind;
      Seq   : out Color_Array;
      N     : Natural)
   is
      --  Seq stores Vertex_Id values as Natural codes in 1 .. N slots.
      Deg : array (1 .. Max_Vertices) of Natural := [others => 0];
      Tmp : Natural;
   begin
      for I in 1 .. N loop
         Seq (Vertex_Id (I)) := I;
         Deg (I) := Degree (G, Vertex_Id (I));
      end loop;

      if Order = Degree_Descending then
         --  Stable-ish selection sort: higher degree first; ties → smaller id.
         for I in 1 .. N - 1 loop
            declare
               Best : Natural := I;
            begin
               for J in I + 1 .. N loop
                  if Deg (Seq (Vertex_Id (J))) > Deg (Seq (Vertex_Id (Best)))
                    or else
                      (Deg (Seq (Vertex_Id (J))) = Deg (Seq (Vertex_Id (Best)))
                         and then Seq (Vertex_Id (J)) < Seq (Vertex_Id (Best)))
                  then
                     Best := J;
                  end if;
               end loop;
               if Best /= I then
                  Tmp := Seq (Vertex_Id (I));
                  Seq (Vertex_Id (I)) := Seq (Vertex_Id (Best));
                  Seq (Vertex_Id (Best)) := Tmp;
               end if;
            end;
         end loop;
      end if;
   end Build_Order;

   procedure Greedy_Color
     (G          : Graph;
      Colors     : out Color_Array;
      Num_Colors : out Natural;
      Order      : Order_Kind := Natural_Order)
   is
      N   : constant Natural := G.N;
      Seq : Color_Array (1 .. Vertex_Id'Last);
      V   : Vertex_Id;
      C   : Positive;
   begin
      Validate_Color_Bounds (N, Colors'First, Colors'Last);
      Num_Colors := 0;

      if N = 0 then
         return;
      end if;

      for I in 1 .. N loop
         Colors (Vertex_Id (I)) := 0;
      end loop;

      Build_Order (G, Order, Seq, N);

      for Pos in 1 .. N loop
         V := Vertex_Id (Seq (Vertex_Id (Pos)));
         C := 1;
         while Neighbour_Uses (G, V, C, Colors) loop
            C := C + 1;
         end loop;
         Colors (V) := Natural (C);
         if Natural (C) > Num_Colors then
            Num_Colors := Natural (C);
         end if;
      end loop;
   end Greedy_Color;

   -------------------------------------------------------------------------
   -- Bipartite / 2-colour (BFS)
   -------------------------------------------------------------------------

   procedure Two_Color
     (G       : Graph;
      Colors  : out Color_Array;
      Success : out Boolean)
   is
      N : constant Natural := G.N;

      Queue : array (1 .. Max_Vertices) of Vertex_Id;
      Q_Lo  : Natural := 1;
      Q_Hi  : Natural := 0;

      procedure Enqueue (X : Vertex_Id) is
      begin
         Q_Hi := Q_Hi + 1;
         Queue (Q_Hi) := X;
      end Enqueue;

      function Dequeue return Vertex_Id is
         X : Vertex_Id;
      begin
         X := Queue (Q_Lo);
         Q_Lo := Q_Lo + 1;
         return X;
      end Dequeue;

      U, W : Vertex_Id;
      E    : Natural;
      Alt  : Natural;
   begin
      Validate_Color_Bounds (N, Colors'First, Colors'Last);
      Success := True;

      if N = 0 then
         return;
      end if;

      for I in 1 .. N loop
         Colors (Vertex_Id (I)) := 0;
      end loop;

      for Start in 1 .. N loop
         if Colors (Vertex_Id (Start)) = 0 then
            Colors (Vertex_Id (Start)) := 1;
            Q_Lo := 1;
            Q_Hi := 0;
            Enqueue (Vertex_Id (Start));

            while Q_Lo <= Q_Hi loop
               U := Dequeue;
               E := G.Head (U);
               while E /= 0 loop
                  W := G.To (E);
                  if Colors (W) = 0 then
                     Alt := 3 - Colors (U);  -- flip 1 ↔ 2
                     Colors (W) := Alt;
                     Enqueue (W);
                  elsif Colors (W) = Colors (U) then
                     Success := False;
                     return;
                  end if;
                  E := G.Next (E);
               end loop;
            end loop;
         end if;
      end loop;
   end Two_Color;

   function Is_Bipartite (G : Graph) return Boolean is
      Colors  : Color_Array (1 .. Vertex_Id'Last);
      Success : Boolean;
   begin
      if G.N = 0 then
         return True;
      end if;
      Two_Color (G, Colors (1 .. Vertex_Id (G.N)), Success);
      return Success;
   end Is_Bipartite;

   -------------------------------------------------------------------------
   -- Exact chromatic number (backtracking)
   -------------------------------------------------------------------------

   function Chromatic_Number_Exact (G : Graph) return Natural is
      N : constant Natural := G.N;

      Colors : array (1 .. Max_Exact) of Natural := [others => 0];
      Found  : Boolean := False;

      function Feasible (V : Positive; Color : Positive) return Boolean is
         E : Natural;
         W : Vertex_Id;
      begin
         E := G.Head (Vertex_Id (V));
         while E /= 0 loop
            W := G.To (E);
            if Natural (W) < V and then Colors (Natural (W)) = Color then
               return False;
            end if;
            E := G.Next (E);
         end loop;
         return True;
      end Feasible;

      procedure Search (V : Positive; K : Positive; Used : Natural) is
      begin
         if Found then
            return;
         end if;
         if V > N then
            Found := True;
            return;
         end if;

         --  Try existing colours 1 .. Used, then one fresh colour if Used < K.
         for C in 1 .. Used loop
            if Feasible (V, C) then
               Colors (V) := C;
               Search (V + 1, K, Used);
               if Found then
                  return;
               end if;
               Colors (V) := 0;
            end if;
         end loop;

         if Used < Natural (K) then
            Colors (V) := Used + 1;
            Search (V + 1, K, Used + 1);
            if Found then
               return;
            end if;
            Colors (V) := 0;
         end if;
      end Search;

      Greedy_Colors : Color_Array (1 .. Vertex_Id (Max_Exact));
      Upper         : Natural;
   begin
      if N > Max_Exact then
         raise Invalid_Argument;
      end if;
      if N = 0 then
         return 0;
      end if;
      if G.M = 0 then
         return 1;
      end if;

      --  Upper bound from greedy (natural order).
      Greedy_Color
        (G, Greedy_Colors (1 .. Vertex_Id (N)), Upper, Natural_Order);

      for K in 1 .. Upper loop
         Found := False;
         for I in 1 .. N loop
            Colors (I) := 0;
         end loop;
         Search (1, Positive (K), 0);
         if Found then
            return K;
         end if;
      end loop;

      --  Fallback (should be unreachable if greedy upper bound is valid).
      return Upper;
   end Chromatic_Number_Exact;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Is_Proper_Coloring
     (G : Graph; Colors : Color_Array) return Boolean
   is
      N : constant Natural := G.N;
      E : Natural;
      W : Vertex_Id;
   begin
      if N = 0 then
         return True;
      end if;
      if Colors'First /= 1 or else Natural (Colors'Last) < N then
         return False;
      end if;

      for V in 1 .. N loop
         if Colors (Vertex_Id (V)) = 0 then
            return False;
         end if;
      end loop;

      for V in 1 .. N loop
         E := G.Head (Vertex_Id (V));
         while E /= 0 loop
            W := G.To (E);
            if Colors (Vertex_Id (V)) = Colors (W) then
               return False;
            end if;
            E := G.Next (E);
         end loop;
      end loop;
      return True;
   end Is_Proper_Coloring;

   function Colors_Used
     (Colors : Color_Array; N : Natural) return Natural
   is
      Seen  : array (0 .. Max_Vertices) of Boolean := [others => False];
      Count : Natural := 0;
      C     : Natural;
   begin
      if N = 0 then
         return 0;
      end if;
      if Colors'First /= 1 or else Natural (Colors'Last) < N then
         raise Invalid_Argument;
      end if;

      for V in 1 .. N loop
         C := Colors (Vertex_Id (V));
         if C > 0 and then C <= Max_Vertices and then not Seen (C) then
            Seen (C) := True;
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Colors_Used;

end Coloring_Algorithm;
