--  Boruvkas_Algorithm body — Borůvka MST / MSF (phased cheapest-outgoing
--  merges) plus in-package Kruskal_Reference (sort + Union–Find).

pragma Ada_2022;

package body Boruvkas_Algorithm
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
   -- Sorting helpers (Kruskal reference): index permutation by weight
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
   -- Deterministic edge preference (Borůvka tie-break)
   ---------------------------------------------------------------------------
   --  Prefer smaller Weight; then smaller min(U,V); then smaller max(U,V);
   --  then smaller insertion index. Ensures equal-weight graphs remain
   --  forests (no accidental cycles from simultaneous selections).

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

   ---------------------------------------------------------------------------
   -- Borůvka / MST
   ---------------------------------------------------------------------------

   procedure Minimum_Spanning_Tree
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
      M : constant Natural := G.M;
      N : constant Natural := G.N;

      Parent : Parent_Array;
      Rank   : Rank_Array;

      --  Cheapest outgoing edge index per component root (0 = None).
      Cheapest : array (0 .. Max_Vertices) of Natural := [others => 0];

      --  Mark edges already kept in the forest (avoid duplicates).
      Kept : array (1 .. Max_Edges) of Boolean := [others => False];

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

      --  At most N-1 merges; each productive phase merges ≥ 1 edge and
      --  halves components in the worst case ⇒ O(log N) typical phases.
      Phases := 0;
      loop
         Phases := Phases + 1;
         exit when Phases > N;  --  safety (should never hit)

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
   end Minimum_Spanning_Tree;

   procedure Boruvka
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
   begin
      Minimum_Spanning_Tree (G, Tree_Edges, Tree_Count, Total_Weight);
   end Boruvka;

   ---------------------------------------------------------------------------
   -- Kruskal reference
   ---------------------------------------------------------------------------

   procedure Kruskal_Reference
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
   end Kruskal_Reference;

end Boruvkas_Algorithm;
