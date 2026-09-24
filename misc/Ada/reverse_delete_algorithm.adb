--  Reverse_Delete_Algorithm body — reverse-delete MST / MSF plus
--  in-package Kruskal_Reference. Union–Find for connectivity / merge.

pragma Ada_2022;

package body Reverse_Delete_Algorithm
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
   -- Union–Find (1 .. N); Parent(0) unused
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
      R : Natural := X;
   begin
      while Parent (R) /= R loop
         R := Parent (R);
      end loop;
      --  Path compression
      declare
         Y : Natural := X;
         Next : Natural;
      begin
         while Parent (Y) /= Y loop
            Next := Parent (Y);
            Parent (Y) := R;
            Y := Next;
         end loop;
      end;
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
     (G          : Graph;
      Index      : in out Index_Array;
      M          : Natural;
      Ascending  : Boolean)
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
               --  Descending: place heavier first; on tie prefer smaller index
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
   -- Reverse-delete / MST
   ---------------------------------------------------------------------------

   procedure Minimum_Spanning_Tree
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
         --  Tentatively delete
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
         --  Self-loop: U = V ⇒ always same component ⇒ stays deleted.
         if UF_Find (Parent, U) /= UF_Find (Parent, V) then
            --  Bridge of the current kept graph — must keep
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
   end Minimum_Spanning_Tree;

   procedure Reverse_Delete
     (G            : Graph;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Weight : out Weight_Sum)
   is
   begin
      Minimum_Spanning_Tree (G, Tree_Edges, Tree_Count, Total_Weight);
   end Reverse_Delete;

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
   end Kruskal_Reference;

end Reverse_Delete_Algorithm;
