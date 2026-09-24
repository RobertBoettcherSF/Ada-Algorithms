--  Minimum_Spanning_Tree body — survey: Kruskal, dense Prim (multi-start),
--  Borůvka, and reverse-delete on a shared undirected edge-list Graph.

pragma Ada_2022;

package body Minimum_Spanning_Tree
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
   -- Sorting helpers: index permutation by edge weight
   ---------------------------------------------------------------------------

   type Index_Array is array (Positive range <>) of Positive;

   --  Insertion sort on Index(1 .. M) by G.Edges(Index(I)).Weight.
   --  Ascending => Kruskal; Descending => reverse-delete.
   --  Ties broken by smaller original index (stable educational order).

   procedure Sort_Indices_By_Weight
     (G         : Graph;
      Index     : in out Index_Array;
      M         : Natural;
      Ascending : Boolean)
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
            if Ascending then
               Less :=
                 G.Edges (Index (J)).Weight > Key_W
                 or else
                 (G.Edges (Index (J)).Weight = Key_W
                  and then Index (J) > Key);
            else
               Less :=
                 G.Edges (Index (J)).Weight < Key_W
                 or else
                 (G.Edges (Index (J)).Weight = Key_W
                  and then Index (J) > Key);
            end if;
            exit when not Less;
            Index (J + 1) := Index (J);
            J := J - 1;
         end loop;
         Index (J + 1) := Key;
      end loop;
   end Sort_Indices_By_Weight;

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
   -- Kruskal
   ---------------------------------------------------------------------------

   procedure Kruskal
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

      Sort_Indices_By_Weight (G, Index, M, Ascending => True);
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
   end Kruskal;

   ---------------------------------------------------------------------------
   -- Dense Prim (multi-start / forest; edge-list neighbour scan)
   ---------------------------------------------------------------------------

   Infinity_Key : constant Weight_Sum := Weight_Sum'Last;

   procedure Prim
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      N : constant Natural := G.N;
      M : constant Natural := G.M;

      Key     : array (0 .. Max_Vertices) of Weight_Sum :=
        [others => Infinity_Key];
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

         Remain := N;
         while Remain > 0 loop
            Best   := 0;
            Best_K := Infinity_Key;
            for V in 1 .. N loop
               if not Settled (V) and then Key (V) < Best_K then
                  Best_K := Key (V);
                  Best   := V;
               end if;
            end loop;

            exit when Best = 0 or else Best_K = Infinity_Key;

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
   end Prim;

   ---------------------------------------------------------------------------
   -- Borůvka
   ---------------------------------------------------------------------------

   function Is_Preferred
     (G : Graph; Cand, Incumbent : Positive) return Boolean
   is
      Cu : constant Natural := Natural (G.Edges (Cand).U);
      Cv : constant Natural := Natural (G.Edges (Cand).V);
      Iu : constant Natural := Natural (G.Edges (Incumbent).U);
      Iv : constant Natural := Natural (G.Edges (Incumbent).V);
      Cmin : constant Natural := Natural'Min (Cu, Cv);
      Cmax : constant Natural := Natural'Max (Cu, Cv);
      Imin : constant Natural := Natural'Min (Iu, Iv);
      Imax : constant Natural := Natural'Max (Iu, Iv);
   begin
      if G.Edges (Cand).Weight < G.Edges (Incumbent).Weight then
         return True;
      elsif G.Edges (Cand).Weight > G.Edges (Incumbent).Weight then
         return False;
      elsif Cmin < Imin then
         return True;
      elsif Cmin > Imin then
         return False;
      elsif Cmax < Imax then
         return True;
      elsif Cmax > Imax then
         return False;
      else
         return Cand < Incumbent;
      end if;
   end Is_Preferred;

   procedure Boruvka
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      M : constant Natural := G.M;
      N : constant Natural := G.N;

      Parent : Parent_Array;
      Rank   : Rank_Array;

      Cheapest : array (0 .. Max_Vertices) of Natural := [others => 0];
      Kept     : array (1 .. Max_Edges) of Boolean := [others => False];

      Progress : Boolean;
      U, V, Ru, Rv : Natural;
      E : Natural;
      Phases : Natural;
   begin
      Require_Tree_Buffer (G, Tree_Edges);

      Tree_Count   := 0;
      Total_Weight := 0;

      if N = 0 or else M = 0 then
         return;
      end if;

      UF_Init (Parent, Rank, N);

      Phases := 0;
      loop
         Phases := Phases + 1;
         exit when Phases > N;

         Cheapest := [others => 0];

         for I in 1 .. M loop
            U := Natural (G.Edges (I).U);
            V := Natural (G.Edges (I).V);
            if U /= V then
               Ru := UF_Find (Parent, U);
               Rv := UF_Find (Parent, V);
               if Ru /= Rv then
                  if Cheapest (Ru) = 0
                    or else Is_Preferred (G, I, Cheapest (Ru))
                  then
                     Cheapest (Ru) := I;
                  end if;
                  if Cheapest (Rv) = 0
                    or else Is_Preferred (G, I, Cheapest (Rv))
                  then
                     Cheapest (Rv) := I;
                  end if;
               end if;
            end if;
         end loop;

         Progress := False;
         for Comp in 1 .. N loop
            E := Cheapest (Comp);
            if E /= 0 then
               U := Natural (G.Edges (E).U);
               V := Natural (G.Edges (E).V);
               Ru := UF_Find (Parent, U);
               Rv := UF_Find (Parent, V);
               if Ru /= Rv then
                  UF_Union (Parent, Rank, Ru, Rv);
                  if not Kept (E) then
                     Kept (E) := True;
                     Tree_Count := Tree_Count + 1;
                     Tree_Edges (Tree_Count) := G.Edges (E);
                     Total_Weight :=
                       Total_Weight + Weight_Sum (G.Edges (E).Weight);
                  end if;
                  Progress := True;
               end if;
            end if;
         end loop;

         exit when not Progress;
      end loop;
   end Boruvka;

   ---------------------------------------------------------------------------
   -- Reverse-delete
   ---------------------------------------------------------------------------

   procedure Reverse_Delete
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      M : constant Natural := G.M;
      N : constant Natural := G.N;

      Kept   : array (1 .. Max_Edges) of Boolean := [others => False];
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
         Kept (I)  := True;
         Index (I) := I;
      end loop;

      Sort_Indices_By_Weight (G, Index, M, Ascending => False);

      for K in 1 .. M loop
         E := Index (K);
         Kept (E) := False;

         UF_Init (Parent, Rank, N);
         for J in 1 .. M loop
            if Kept (J) then
               UF_Union
                 (Parent, Rank,
                  Natural (G.Edges (J).U),
                  Natural (G.Edges (J).V));
            end if;
         end loop;

         U := Natural (G.Edges (E).U);
         V := Natural (G.Edges (E).V);
         if UF_Find (Parent, U) /= UF_Find (Parent, V) then
            Kept (E) := True;
         end if;
      end loop;

      for I in 1 .. M loop
         if Kept (I) then
            Tree_Count := Tree_Count + 1;
            Tree_Edges (Tree_Count) := G.Edges (I);
            Total_Weight :=
              Total_Weight + Weight_Sum (G.Edges (I).Weight);
         end if;
      end loop;
   end Reverse_Delete;

end Minimum_Spanning_Tree;
