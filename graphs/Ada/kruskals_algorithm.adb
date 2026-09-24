--  Kruskals_Algorithm body — Kruskal MST / MSF (sort + Union–Find) plus
--  in-package Prim_Reference (dense multi-start over the edge list).

pragma Ada_2022;

package body Kruskals_Algorithm
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
      G.N := Vertex_Count;
      G.M := 0;
   end Clear;

   procedure Add_Edge
     (G : in out Graph; U, V : Vertex_Id; Weight : Integer)
   is
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
      if G.M >= Max_Edges then
         raise Invalid_Argument;
      end if;
      G.M := G.M + 1;
      G.Edges (G.M) :=
        (U => U, V => V, Weight => Weight_Type (Weight));
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is (G.N);

   function Edge_Count (G : Graph) return Natural is (G.M);

   ---------------------------------------------------------------------------
   -- Union–Find (1 .. N); Parent(0) unused — package-body private
   ---------------------------------------------------------------------------

   type Parent_Array is array (0 .. Max_Vertices) of Natural;
   type Rank_Array   is array (0 .. Max_Vertices) of Natural;

   procedure UF_Init
     (Parent : out Parent_Array;
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
     (Parent : in out Parent_Array; X : Natural) return Natural
   is
      R    : Natural := X;
      Y    : Natural;
      Next : Natural;
   begin
      while Parent (R) /= R loop
         R := Parent (R);
      end loop;
      --  Path compression
      Y := X;
      while Parent (Y) /= Y loop
         Next := Parent (Y);
         Parent (Y) := R;
         Y := Next;
      end loop;
      return R;
   end UF_Find;

   procedure UF_Union
     (Parent : in out Parent_Array;
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

   ---------------------------------------------------------------------------
   -- Sorting helpers: index permutation by edge weight ascending
   ---------------------------------------------------------------------------

   type Index_Array is array (Positive range <>) of Positive;

   --  Insertion sort on Index(1 .. M) by G.Edges(Index(I)).Weight
   --  ascending. Ties broken by smaller original index.

   procedure Sort_Indices_Ascending
     (G     : Graph;
      Index : in out Index_Array;
      M     : Natural)
   is
      J     : Natural;
      Key   : Positive;
      Key_W : Weight_Type;
      Less  : Boolean;
   begin
      for I in 2 .. M loop
         Key   := Index (I);
         Key_W := G.Edges (Key).Weight;
         J     := I - 1;
         while J >= 1 loop
            Less :=
              G.Edges (Index (J)).Weight > Key_W
              or else
              (G.Edges (Index (J)).Weight = Key_W
               and then Index (J) > Key);
            exit when not Less;
            Index (J + 1) := Index (J);
            J := J - 1;
         end loop;
         Index (J + 1) := Key;
      end loop;
   end Sort_Indices_Ascending;

   procedure Require_Tree_Buffer (G : Graph; Tree_Edges : Edge_List) is
   begin
      if G.M = 0 then
         if Tree_Edges'First /= 1 then
            raise Invalid_Argument;
         end if;
         return;
      end if;
      if Tree_Edges'First /= 1 or else Tree_Edges'Last < G.M then
         raise Invalid_Argument;
      end if;
   end Require_Tree_Buffer;

   ---------------------------------------------------------------------------
   -- Kruskal / MST
   ---------------------------------------------------------------------------

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      M : constant Natural := G.M;
      N : constant Natural := G.N;

      Index  : Index_Array (1 .. Max_Edges);
      Parent : Parent_Array;
      Rank   : Rank_Array;
      E      : Positive;
      U, V   : Natural;
   begin
      Require_Tree_Buffer (G, Tree_Edges);

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
         U := Natural (G.Edges (E).U);
         V := Natural (G.Edges (E).V);
         if UF_Find (Parent, U) /= UF_Find (Parent, V) then
            UF_Union (Parent, Rank, U, V);
            Tree_Count := Tree_Count + 1;
            Tree_Edges (Tree_Count) := G.Edges (E);
            Total_Weight :=
              Total_Weight + Weight_Sum (G.Edges (E).Weight);
         end if;
      end loop;
   end Minimum_Spanning_Tree;

   procedure Kruskal
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
   begin
      Minimum_Spanning_Tree (G, Tree_Edges, Tree_Count, Total_Weight);
   end Kruskal;

   ---------------------------------------------------------------------------
   -- Prim reference (dense multi-start; edge-list neighbour scan)
   ---------------------------------------------------------------------------

   Infinity : constant Weight_Sum := Weight_Sum'Last;

   procedure Prim_Reference
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      N : constant Natural := G.N;
      M : constant Natural := G.M;

      --  Key(v) = lightest cut edge into v; Parent(v) = other endpoint
      --  (0 = unset / root). Settled marks vertices already in some tree.
      Key     : array (0 .. Max_Vertices) of Weight_Sum := [others => Infinity];
      Parent  : array (0 .. Max_Vertices) of Natural := [others => 0];
      Settled : array (0 .. Max_Vertices) of Boolean := [others => False];

      procedure Grow_From (Seed : Natural) is
         U, Best : Natural;
         Best_K  : Weight_Sum;
         A, B    : Natural;
         W       : Weight_Sum;
         Remain  : Natural;
      begin
         Key (Seed)    := 0;
         Parent (Seed) := 0;

         --  At most N settlement steps; stop early when no finite key left
         Remain := N;
         while Remain > 0 loop
            Best   := 0;
            Best_K := Infinity;
            for V in 1 .. N loop
               if not Settled (V) and then Key (V) < Best_K then
                  Best_K := Key (V);
                  Best   := V;
               end if;
            end loop;

            exit when Best = 0 or else Best_K = Infinity;

            U := Best;
            Settled (U) := True;
            Remain := Remain - 1;

            if Parent (U) /= 0 then
               Tree_Count := Tree_Count + 1;
               Tree_Edges (Tree_Count) :=
                 (U      => Vertex_Id (Parent (U)),
                  V      => Vertex_Id (U),
                  Weight => Weight_Type (Key (U)));
               Total_Weight := Total_Weight + Key (U);
            end if;

            --  Scan undirected edge list for neighbours of U
            for I in 1 .. M loop
               A := Natural (G.Edges (I).U);
               B := Natural (G.Edges (I).V);
               W := Weight_Sum (G.Edges (I).Weight);
               if A = U and then not Settled (B) and then W < Key (B) then
                  Key (B)    := W;
                  Parent (B) := U;
               elsif B = U and then not Settled (A) and then W < Key (A)
               then
                  Key (A)    := W;
                  Parent (A) := U;
               end if;
            end loop;
         end loop;
      end Grow_From;

   begin
      Require_Tree_Buffer (G, Tree_Edges);

      Tree_Count   := 0;
      Total_Weight := 0;

      if N = 0 then
         return;
      end if;

      for Seed in 1 .. N loop
         if not Settled (Seed) then
            Grow_From (Seed);
         end if;
      end loop;
   end Prim_Reference;

end Kruskals_Algorithm;
