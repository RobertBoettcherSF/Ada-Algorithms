--  Prims_Algorithm body — dense Prim MST / MSF plus in-package
--  Kruskal_Reference. Array-scan cut selection; Union–Find for Kruskal.

pragma Ada_2022;

package body Prims_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Graph mutators / queries
   ---------------------------------------------------------------------------

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N     := Vertex_Count;
      G.M     := 0;
      G.Dir_E := 0;
      G.Head  := [others => 0];
   end Clear;

   procedure Push_Directed
     (G : in out Graph; From, To : Vertex_Id; W : Weight_Type)
   is
      E : Dir_Index;
   begin
      G.Dir_E := G.Dir_E + 1;
      E := G.Dir_E;
      G.To (E)     := To;
      G.Weight (E) := W;
      G.Next (E)   := G.Head (From);
      G.Head (From) := E;
   end Push_Directed;

   procedure Add_Edge
     (G : in out Graph; U, V : Vertex_Id; Weight : Integer)
   is
      W : Weight_Type;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      if Natural (U) > G.N or else Natural (V) > G.N then
         raise Invalid_Argument;
      end if;
      if Weight < 0 then
         raise Invalid_Argument;
      end if;
      if G.M = Max_Edges then
         raise Invalid_Argument;
      end if;

      W := Weight_Type (Weight);
      G.M := G.M + 1;
      G.Undirected (G.M) := (U => U, V => V, Weight => W);

      Push_Directed (G, U, V, W);
      if U /= V then
         Push_Directed (G, V, U, W);
      end if;
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is (G.N);

   function Edge_Count (G : Graph) return Natural is (Natural (G.M));

   ---------------------------------------------------------------------------
   -- Bound checks
   ---------------------------------------------------------------------------

   procedure Validate_Parent_Key
     (N : Natural;
      Parent_First, Parent_Last : Vertex_Id;
      Key_First, Key_Last       : Vertex_Id)
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Parent_First /= 1
        or else Natural (Parent_Last) < N
        or else Key_First /= 1
        or else Natural (Key_Last) < N
      then
         raise Invalid_Argument;
      end if;
   end Validate_Parent_Key;

   procedure Require_Tree_Buffer_Seeded
     (G : Graph; Tree_Edges : Edge_List)
   is
      Need : Natural;
   begin
      if G.N = 0 then
         raise Invalid_Argument;
      end if;
      if Tree_Edges'First /= 1 then
         raise Invalid_Argument;
      end if;
      if G.N <= 1 then
         return;
      end if;
      Need := G.N - 1;
      if Tree_Edges'Last < Need then
         raise Invalid_Argument;
      end if;
   end Require_Tree_Buffer_Seeded;

   procedure Require_Tree_Buffer_Forest
     (G : Graph; Tree_Edges : Edge_List)
   is
      Need : Natural;
   begin
      if Tree_Edges'First /= 1 then
         raise Invalid_Argument;
      end if;
      if G.N = 0 then
         return;
      end if;
      if G.N <= 1 then
         return;
      end if;
      --  Forest has at most N-1 edges; Kruskal worst case also ≤ M.
      --  Require room for N-1 (Prim forest) and for Kruskal when M > N-1
      --  use Max(N-1, M) for the Kruskal path — forest Prim only needs
      --  N-1. Kruskal_Reference uses its own check requiring Last >= M
      --  when M > 0 (see below). Here MSF Prim needs Last >= N-1.
      Need := G.N - 1;
      if Tree_Edges'Last < Need then
         raise Invalid_Argument;
      end if;
   end Require_Tree_Buffer_Forest;

   procedure Require_Kruskal_Buffer
     (G : Graph; Tree_Edges : Edge_List)
   is
   begin
      if Tree_Edges'First /= 1 then
         raise Invalid_Argument;
      end if;
      if G.M = 0 then
         return;
      end if;
      if Tree_Edges'Last < Natural (G.M) then
         raise Invalid_Argument;
      end if;
   end Require_Kruskal_Buffer;

   ---------------------------------------------------------------------------
   -- Dense Prim core
   ---------------------------------------------------------------------------

   type Settled_Array is array (0 .. Max_Vertices) of Boolean;

   --  Grow from a single seed. Stop when the next unsettled min key is
   --  Infinity (rest of graph is outside this component). Does not clear
   --  Parent/Key for vertices already set by a previous forest pass —
   --  caller initialises.

   procedure Prim_Grow
     (G            : Graph;
      Start        : Natural;
      Parent       : in out Parent_Array;
      Key          : in out Key_Array;
      Settled      : in out Settled_Array;
      Total_Weight : in out Weight_Sum)
   is
      N     : constant Natural := G.N;
      U     : Natural;
      Best  : Key_Value;
      Cand  : Key_Value;
      E     : Natural;
      Wgt   : Key_Value;
      Dest  : Natural;
   begin
      Key (Vertex_Id (Start)) := 0;
      Parent (Vertex_Id (Start)) := 0;

      for Step in 1 .. N loop
         U    := 0;
         Best := Infinity;
         for V in 1 .. N loop
            if not Settled (V) then
               Cand := Key (Vertex_Id (V));
               if Cand < Best then
                  Best := Cand;
                  U    := V;
               end if;
            end if;
         end loop;

         exit when U = 0 or else Best = Infinity;

         Settled (U) := True;
         if Parent (Vertex_Id (U)) /= 0 then
            Total_Weight := Total_Weight + Weight_Sum (Best);
         end if;

         E := G.Head (Vertex_Id (U));
         while E /= 0 loop
            Dest := Natural (G.To (Dir_Index (E)));
            if not Settled (Dest) then
               Wgt := Key_Value (G.Weight (Dir_Index (E)));
               if Wgt < Key (Vertex_Id (Dest)) then
                  Key (Vertex_Id (Dest))    := Wgt;
                  Parent (Vertex_Id (Dest)) := U;
               end if;
            end if;
            E := G.Next (Dir_Index (E));
         end loop;
      end loop;
   end Prim_Grow;

   procedure Init_Parent_Key
     (G : Graph; Parent : out Parent_Array; Key : out Key_Array)
   is
   begin
      for V in 1 .. G.N loop
         Parent (Vertex_Id (V)) := 0;
         Key (Vertex_Id (V))    := Infinity;
      end loop;
   end Init_Parent_Key;

   ---------------------------------------------------------------------------
   -- Seeded Prim (Parent / Key)
   ---------------------------------------------------------------------------

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Start        : Vertex_Id;
      Parent       : out Parent_Array;
      Key          : out Key_Array;
      Total_Weight : out Weight_Sum)
   is
      Settled : Settled_Array := [others => False];
   begin
      Validate_Parent_Key
        (G.N, Parent'First, Parent'Last, Key'First, Key'Last);
      if Natural (Start) > G.N then
         raise Invalid_Argument;
      end if;

      Init_Parent_Key (G, Parent, Key);
      Total_Weight := 0;
      Prim_Grow
        (G, Natural (Start), Parent, Key, Settled, Total_Weight);
   end Minimum_Spanning_Tree;

   procedure Prim
     (G            : Graph;
      Start        : Vertex_Id;
      Parent       : out Parent_Array;
      Key          : out Key_Array;
      Total_Weight : out Weight_Sum)
   is
   begin
      Minimum_Spanning_Tree (G, Start, Parent, Key, Total_Weight);
   end Prim;

   ---------------------------------------------------------------------------
   -- Seeded Prim (edge list)
   ---------------------------------------------------------------------------

   procedure Emit_Edges_From_Parent
     (G            : Graph;
      Parent       : Parent_Array;
      Key          : Key_Array;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      P : Natural;
   begin
      Tree_Count   := 0;
      Total_Weight := 0;
      for V in 1 .. G.N loop
         P := Parent (Vertex_Id (V));
         if P /= 0 then
            Tree_Count := Tree_Count + 1;
            Tree_Edges (Tree_Count) :=
              (U      => Vertex_Id (P),
               V      => Vertex_Id (V),
               Weight => Weight_Type (Key (Vertex_Id (V))));
            Total_Weight :=
              Total_Weight + Weight_Sum (Key (Vertex_Id (V)));
         end if;
      end loop;
   end Emit_Edges_From_Parent;

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Start        : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      Parent : Parent_Array (Vertex_Id);
      Key    : Key_Array (Vertex_Id);
      Tw     : Weight_Sum;
   begin
      Require_Tree_Buffer_Seeded (G, Tree_Edges);
      Minimum_Spanning_Tree (G, Start, Parent, Key, Tw);
      pragma Unreferenced (Tw);
      Emit_Edges_From_Parent
        (G, Parent, Key, Tree_Edges, Tree_Count, Total_Weight);
   end Minimum_Spanning_Tree;

   procedure Prim
     (G            : Graph;
      Start        : Vertex_Id;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
   begin
      Minimum_Spanning_Tree
        (G, Start, Tree_Edges, Tree_Count, Total_Weight);
   end Prim;

   ---------------------------------------------------------------------------
   -- Forest (multi-start)
   ---------------------------------------------------------------------------

   procedure Minimum_Spanning_Forest
     (G            : Graph;
      Parent       : out Parent_Array;
      Key          : out Key_Array;
      Total_Weight : out Weight_Sum)
   is
      Settled : Settled_Array := [others => False];
   begin
      Total_Weight := 0;
      if G.N = 0 then
         return;
      end if;
      Validate_Parent_Key
        (G.N, Parent'First, Parent'Last, Key'First, Key'Last);
      Init_Parent_Key (G, Parent, Key);

      for Seed in 1 .. G.N loop
         if not Settled (Seed) then
            Prim_Grow
              (G, Seed, Parent, Key, Settled, Total_Weight);
         end if;
      end loop;
   end Minimum_Spanning_Forest;

   procedure Minimum_Spanning_Forest
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      Parent : Parent_Array (Vertex_Id);
      Key    : Key_Array (Vertex_Id);
      Tw     : Weight_Sum;
   begin
      Require_Tree_Buffer_Forest (G, Tree_Edges);
      if G.N = 0 then
         Tree_Count   := 0;
         Total_Weight := 0;
         return;
      end if;
      Minimum_Spanning_Forest (G, Parent, Key, Tw);
      pragma Unreferenced (Tw);
      Emit_Edges_From_Parent
        (G, Parent, Key, Tree_Edges, Tree_Count, Total_Weight);
   end Minimum_Spanning_Forest;

   ---------------------------------------------------------------------------
   -- Kruskal reference (Union–Find)
   ---------------------------------------------------------------------------

   type UF_Parent_Array is array (0 .. Max_Vertices) of Natural;
   type Rank_Array is array (0 .. Max_Vertices) of Natural;

   procedure UF_Init
     (Parent : out UF_Parent_Array;
      Rank   : out Rank_Array;
      N      : Natural)
   is
   begin
      Parent := [others => 0];
      Rank   := [others => 0];
      for I in 1 .. N loop
         Parent (I) := I;
         Rank (I)   := 0;
      end loop;
   end UF_Init;

   function UF_Find
     (Parent : in out UF_Parent_Array; X : Natural) return Natural
   is
      R    : Natural := X;
      Y    : Natural;
      Next : Natural;
   begin
      while Parent (R) /= R loop
         R := Parent (R);
      end loop;
      Y := X;
      while Parent (Y) /= Y loop
         Next := Parent (Y);
         Parent (Y) := R;
         Y := Next;
      end loop;
      return R;
   end UF_Find;

   procedure UF_Union
     (Parent : in out UF_Parent_Array;
      Rank   : in out Rank_Array;
      A, B   : Natural)
   is
      RA : constant Natural := UF_Find (Parent, A);
      RB : constant Natural := UF_Find (Parent, B);
   begin
      if RA = RB then
         return;
      end if;
      if Rank (RA) < Rank (RB) then
         Parent (RA) := RB;
      elsif Rank (RA) > Rank (RB) then
         Parent (RB) := RA;
      else
         Parent (RB) := RA;
         Rank (RA)   := Rank (RA) + 1;
      end if;
   end UF_Union;

   type Index_Array is array (Positive range <>) of Positive;

   procedure Sort_Indices_Ascending
     (G : Graph; Index : in out Index_Array; M : Natural)
   is
      J     : Natural;
      Key_I : Positive;
      Key_W : Weight_Type;
      Less  : Boolean;
   begin
      for I in 2 .. M loop
         Key_I := Index (I);
         Key_W := G.Undirected (Key_I).Weight;
         J     := I - 1;
         while J >= 1 loop
            Less :=
              G.Undirected (Index (J)).Weight > Key_W
              or else
              (G.Undirected (Index (J)).Weight = Key_W
               and then Index (J) > Key_I);
            exit when not Less;
            Index (J + 1) := Index (J);
            J := J - 1;
         end loop;
         Index (J + 1) := Key_I;
      end loop;
   end Sort_Indices_Ascending;

   procedure Kruskal_Reference
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      M      : constant Natural := Natural (G.M);
      N      : constant Natural := G.N;
      Index  : Index_Array (1 .. Max_Edges);
      Parent : UF_Parent_Array;
      Rank   : Rank_Array;
      E      : Positive;
      U, V   : Natural;
   begin
      Require_Kruskal_Buffer (G, Tree_Edges);

      Tree_Count   := 0;
      Total_Weight := 0;

      if N = 0 or else M = 0 then
         return;
      end if;

      for I in 1 .. M loop
         Index (I) := I;
      end loop;

      Sort_Indices_Ascending (G, Index, M);
      UF_Init (Parent, Rank, N);

      for K in 1 .. M loop
         E := Index (K);
         U := Natural (G.Undirected (E).U);
         V := Natural (G.Undirected (E).V);
         if UF_Find (Parent, U) /= UF_Find (Parent, V) then
            UF_Union (Parent, Rank, U, V);
            Tree_Count := Tree_Count + 1;
            Tree_Edges (Tree_Count) := G.Undirected (E);
            Total_Weight :=
              Total_Weight + Weight_Sum (G.Undirected (E).Weight);
         end if;
      end loop;
   end Kruskal_Reference;

end Prims_Algorithm;
