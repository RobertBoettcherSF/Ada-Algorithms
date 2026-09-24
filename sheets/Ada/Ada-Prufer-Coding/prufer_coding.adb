--  Prufer_Coding body — Encode / Decode Prüfer sequences of labeled trees.

pragma Ada_2022;

package body Prufer_Coding
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Clear / Add_Edge / inspectors
   ---------------------------------------------------------------------------

   procedure Clear (T : in out Tree; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      T.N := Vertex_Count;
      T.M := 0;
   end Clear;

   procedure Add_Edge (T : in out Tree; U, V : Vertex_Id) is
   begin
      if Natural (U) > T.N or else Natural (V) > T.N then
         raise Invalid_Argument;
      end if;
      if U = V then
         raise Invalid_Argument;
      end if;
      if T.M >= Max_Edges then
         raise Invalid_Argument;
      end if;
      T.M := T.M + 1;
      T.Edges (T.M) := (U => U, V => V);
   end Add_Edge;

   function Vertex_Count (T : Tree) return Natural is
   begin
      return T.N;
   end Vertex_Count;

   function Edge_Count (T : Tree) return Natural is
   begin
      return T.M;
   end Edge_Count;

   procedure Get_Edges
     (T          : Tree;
      Edges      : out Edge_List;
      Edge_Count : out Natural)
   is
   begin
      if Edges'First /= 1 then
         raise Invalid_Argument;
      end if;
      if T.M > 0 and then Edges'Last < T.M then
         raise Invalid_Argument;
      end if;
      Edge_Count := T.M;
      for I in 1 .. T.M loop
         Edges (I) := T.Edges (I);
      end loop;
   end Get_Edges;

   ---------------------------------------------------------------------------
   -- Local helpers for Encode (adjacency + connectivity)
   ---------------------------------------------------------------------------

   --  Half-edge capacity: each undirected edge yields two directed links.
   Half_Max : constant Positive := 2 * Max_Edges;

   type Degree_Array is array (1 .. Max_Vertices) of Natural;
   type Bool_Array   is array (1 .. Max_Vertices) of Boolean;
   type Head_Array   is array (1 .. Max_Vertices) of Natural;
   type To_Array     is array (1 .. Half_Max) of Vertex_Id;
   type Next_Array   is array (1 .. Half_Max) of Natural;
   type Parent_Arr   is array (1 .. Max_Vertices) of Natural;

   procedure Build_Adj
     (T        : Tree;
      Head     : out Head_Array;
      To       : out To_Array;
      Next_Lnk : out Next_Array;
      Degree   : out Degree_Array;
      Half     : out Natural)
   is
      procedure Link (From, Dest : Vertex_Id) is
      begin
         Half := Half + 1;
         To (Half) := Dest;
         Next_Lnk (Half) := Head (Natural (From));
         Head (Natural (From)) := Half;
         Degree (Natural (From)) := Degree (Natural (From)) + 1;
      end Link;
   begin
      Head := [others => 0];
      Degree := [others => 0];
      To := [others => 1];
      Next_Lnk := [others => 0];
      Half := 0;
      for I in 1 .. T.M loop
         Link (T.Edges (I).U, T.Edges (I).V);
         Link (T.Edges (I).V, T.Edges (I).U);
      end loop;
   end Build_Adj;

   function Is_Tree (T : Tree) return Boolean is
      Head     : Head_Array;
      To       : To_Array;
      Next_Lnk : Next_Array;
      Degree   : Degree_Array;
      Half     : Natural;
      Seen     : Bool_Array := [others => False];
      Parent   : Parent_Arr := [others => 0];
      Queue    : array (1 .. Max_Vertices) of Vertex_Id := [others => 1];
      Q_Lo, Q_Hi : Natural := 0;
      Visited  : Natural := 0;
      U, V     : Vertex_Id;
      E        : Natural;
   begin
      if T.N = 0 then
         return T.M = 0;
      end if;
      if T.N = 1 then
         return T.M = 0;
      end if;
      --  N ≥ 2: a tree has exactly N − 1 edges and is connected / acyclic.
      if T.M /= T.N - 1 then
         return False;
      end if;

      Build_Adj (T, Head, To, Next_Lnk, Degree, Half);

      --  BFS from vertex 1; reject back-edges that are not the parent link.
      Q_Hi := 1;
      Queue (1) := 1;
      Seen (1) := True;
      Visited := 1;
      Q_Lo := 1;
      while Q_Lo <= Q_Hi loop
         U := Queue (Q_Lo);
         Q_Lo := Q_Lo + 1;
         E := Head (Natural (U));
         while E /= 0 loop
            V := To (E);
            if not Seen (Natural (V)) then
               Seen (Natural (V)) := True;
               Parent (Natural (V)) := Natural (U);
               Visited := Visited + 1;
               Q_Hi := Q_Hi + 1;
               Queue (Q_Hi) := V;
            elsif Parent (Natural (U)) /= Natural (V) then
               --  Edge to an already-seen non-parent ⇒ cycle.
               return False;
            end if;
            E := Next_Lnk (E);
         end loop;
      end loop;

      return Visited = T.N;
   end Is_Tree;

   ---------------------------------------------------------------------------
   -- Encode
   ---------------------------------------------------------------------------

   procedure Encode
     (T      : Tree;
      Code   : out Code_Array;
      Length : out Natural)
   is
      Head     : Head_Array;
      To       : To_Array;
      Next_Lnk : Next_Array;
      Degree   : Degree_Array;
      Half     : Natural;
      Alive    : Bool_Array;
      Need     : Natural;
      Leaf     : Vertex_Id;
      Found    : Boolean;
      Neigh    : Vertex_Id;
      E        : Natural;
   begin
      if Code'First /= 1 then
         raise Invalid_Argument;
      end if;

      if T.N <= 1 then
         --  Vacuous / single-vertex: empty Prüfer sequence.
         if not Is_Tree (T) then
            raise Invalid_Argument;
         end if;
         Length := 0;
         return;
      end if;

      if not Is_Tree (T) then
         raise Invalid_Argument;
      end if;

      Need := T.N - 2;
      Length := Need;
      if Need > 0 and then Code'Last < Need then
         raise Invalid_Argument;
      end if;

      if Need = 0 then
         --  N = 2: empty sequence.
         return;
      end if;

      Build_Adj (T, Head, To, Next_Lnk, Degree, Half);
      Alive := [others => False];
      for I in 1 .. T.N loop
         Alive (I) := True;
      end loop;

      for Step in 1 .. Need loop
         --  Smallest alive leaf (degree 1).
         Found := False;
         Leaf := 1;
         for V in 1 .. T.N loop
            if Alive (V) and then Degree (V) = 1 then
               Leaf := Vertex_Id (V);
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            raise Invalid_Argument;
         end if;

         --  Unique alive neighbour.
         Neigh := Leaf;
         E := Head (Natural (Leaf));
         while E /= 0 loop
            if Alive (Natural (To (E))) then
               Neigh := To (E);
               exit;
            end if;
            E := Next_Lnk (E);
         end loop;

         Code (Step) := Neigh;

         --  Remove Leaf; decrement neighbour degree.
         Alive (Natural (Leaf)) := False;
         Degree (Natural (Leaf)) := 0;
         Degree (Natural (Neigh)) := Degree (Natural (Neigh)) - 1;
      end loop;
   end Encode;

   ---------------------------------------------------------------------------
   -- Decode helpers
   ---------------------------------------------------------------------------

   procedure Validate_Code
     (Code : Code_Array; N : out Natural)
   is
   begin
      if Code'First /= 1 then
         raise Invalid_Argument;
      end if;
      N := Code'Length + 2;
      if N > Max_Vertices then
         raise Invalid_Argument;
      end if;
      for I in Code'Range loop
         if Natural (Code (I)) > N then
            raise Invalid_Argument;
         end if;
      end loop;
   end Validate_Code;

   procedure Reconstruct
     (Code  : Code_Array;
      N     : Natural;
      Edges : out Edge_Store;
      Count : out Natural)
   is
      Degree : Degree_Array := [others => 0];
      J      : Natural;
      U, V   : Vertex_Id;
      Left   : Natural;
   begin
      for I in 1 .. N loop
         Degree (I) := 1;
      end loop;
      for I in Code'Range loop
         Degree (Natural (Code (I))) := Degree (Natural (Code (I))) + 1;
      end loop;

      Count := 0;
      for I in Code'Range loop
         J := 0;
         for Cand in 1 .. N loop
            if Degree (Cand) = 1 then
               J := Cand;
               exit;
            end if;
         end loop;
         if J = 0 then
            raise Invalid_Argument;
         end if;
         U := Vertex_Id (J);
         V := Code (I);
         Count := Count + 1;
         Edges (Count) := (U => U, V => V);
         Degree (J) := Degree (J) - 1;
         Degree (Natural (V)) := Degree (Natural (V)) - 1;
      end loop;

      --  Two remaining degree-1 vertices.
      Left := 0;
      U := 1;
      V := 1;
      for Cand in 1 .. N loop
         if Degree (Cand) = 1 then
            if Left = 0 then
               U := Vertex_Id (Cand);
               Left := 1;
            else
               V := Vertex_Id (Cand);
               Left := 2;
               exit;
            end if;
         end if;
      end loop;
      if Left /= 2 then
         raise Invalid_Argument;
      end if;
      Count := Count + 1;
      Edges (Count) := (U => U, V => V);
   end Reconstruct;

   ---------------------------------------------------------------------------
   -- Decode / Decode_Edges
   ---------------------------------------------------------------------------

   procedure Decode
     (Code : Code_Array;
      T    : out Tree)
   is
      N     : Natural;
      Edges : Edge_Store;
      Count : Natural;
   begin
      Validate_Code (Code, N);
      Reconstruct (Code, N, Edges, Count);
      T.N := N;
      T.M := Count;
      for I in 1 .. Count loop
         T.Edges (I) := Edges (I);
      end loop;
   end Decode;

   procedure Decode_Edges
     (Code       : Code_Array;
      Edges      : out Edge_List;
      Edge_Count : out Natural;
      N          : out Natural)
   is
      Store : Edge_Store;
      Count : Natural;
   begin
      Validate_Code (Code, N);
      if Edges'First /= 1 then
         raise Invalid_Argument;
      end if;
      if N < 2 then
         --  Unreachable: N = Code'Length + 2 ≥ 2.
         raise Invalid_Argument;
      end if;
      if Edges'Last < N - 1 then
         raise Invalid_Argument;
      end if;
      Reconstruct (Code, N, Store, Count);
      Edge_Count := Count;
      for I in 1 .. Count loop
         Edges (I) := Store (I);
      end loop;
   end Decode_Edges;

   ---------------------------------------------------------------------------
   -- Cayley_Count
   ---------------------------------------------------------------------------

   function Cayley_Count (N : Natural) return Natural is
      Result : Natural;
   begin
      if N > 8 then
         raise Invalid_Argument;
      end if;
      if N = 0 then
         return 0;
      end if;
      if N = 1 or else N = 2 then
         return 1;
      end if;
      --  N^(N−2) for 3 .. 8.
      Result := 1;
      for I in 1 .. N - 2 loop
         Result := Result * N;
      end loop;
      return Result;
   end Cayley_Count;

end Prufer_Coding;
