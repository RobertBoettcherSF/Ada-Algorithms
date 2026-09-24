--  Euclidean_Minimum_Spanning_Tree body — complete geometric graph plus
--  self-contained dense Prim and Kruskal on rounded Euclidean lengths.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Euclidean_Minimum_Spanning_Tree
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Point set mutators / queries
   ---------------------------------------------------------------------------

   procedure Clear (S : in out Point_Set) is
   begin
      S.N := 0;
   end Clear;

   procedure Add_Point (S : in out Point_Set; P : Point) is
   begin
      if S.N >= Max_Points then
         raise Invalid_Argument;
      end if;
      S.N := S.N + 1;
      S.Points (S.N) := P;
   end Add_Point;

   function Point_Count (S : Point_Set) return Natural is (S.N);

   function Get_Point (S : Point_Set; Index : Point_Index) return Point is
   begin
      if Natural (Index) > S.N then
         raise Invalid_Argument;
      end if;
      return S.Points (Natural (Index));
   end Get_Point;

   function Rounded_Euclidean (A, B : Point) return Length_Type is
      use Ada.Numerics.Long_Elementary_Functions;
      DX : constant Long_Integer :=
        Long_Integer (A.X) - Long_Integer (B.X);
      DY : constant Long_Integer :=
        Long_Integer (A.Y) - Long_Integer (B.Y);
      Sq : constant Long_Integer := DX * DX + DY * DY;
      R  : constant Long_Float :=
        Long_Float'Rounding (Sqrt (Long_Float (Sq)));
   begin
      if R < 0.0 then
         return 0;
      elsif R > Long_Float (Length_Type'Last) then
         raise Invalid_Argument;
      else
         return Length_Type (R);
      end if;
   end Rounded_Euclidean;

   ---------------------------------------------------------------------------
   -- Internal complete-graph edge table
   ---------------------------------------------------------------------------

   type CG_Edge is record
      U, V   : Point_Index;
      Length : Length_Type;
   end record;

   type CG_Edge_Array is array (1 .. Max_Edges) of CG_Edge;

   procedure Build_Complete_Graph
     (S : Point_Set; Edges : out CG_Edge_Array; M : out Natural)
   is
      N : constant Natural := S.N;
      K : Natural := 0;
   begin
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            K := K + 1;
            Edges (K) :=
              (U      => Point_Index (I),
               V      => Point_Index (J),
               Length =>
                 Rounded_Euclidean (S.Points (I), S.Points (J)));
         end loop;
      end loop;
      M := K;
   end Build_Complete_Graph;

   procedure Require_Tree_Buffer (N : Natural; Tree_Edges : Edge_List) is
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if Tree_Edges'First /= 1 or else Tree_Edges'Last < N - 1 then
         raise Invalid_Argument;
      end if;
   end Require_Tree_Buffer;

   ---------------------------------------------------------------------------
   -- Union–Find (1 .. N)
   ---------------------------------------------------------------------------

   type Parent_Array is array (0 .. Max_Points) of Natural;
   type Rank_Array   is array (0 .. Max_Points) of Natural;

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
   -- Dense Prim on the complete geometric graph (O(N^2))
   ---------------------------------------------------------------------------

   Infinity_Key : constant Length_Sum := Length_Sum'Last;

   procedure Prim
     (S            : Point_Set;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Length : out Length_Sum)
   is
      N : constant Natural := S.N;

      Key     : array (0 .. Max_Points) of Length_Sum :=
        [others => Infinity_Key];
      Parent  : array (0 .. Max_Points) of Natural := [others => 0];
      Settled : array (0 .. Max_Points) of Boolean := [others => False];

      U, Best : Natural;
      Best_K  : Length_Sum;
      W       : Length_Sum;
      Remain  : Natural;
   begin
      Require_Tree_Buffer (N, Tree_Edges);

      Tree_Count   := 0;
      Total_Length := 0;

      --  Seed at point 1 (connected complete graph ⇒ one tree).
      Key (1)    := 0;
      Parent (1) := 0;
      Remain     := N;

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
              (U      => Point_Index (Parent (U)),
               V      => Point_Index (U),
               Length => Length_Type (Key (U)));
            Total_Length := Total_Length + Key (U);
         end if;

         for V in 1 .. N loop
            if not Settled (V) then
               W := Length_Sum
                 (Rounded_Euclidean (S.Points (U), S.Points (V)));
               if W < Key (V) then
                  Key (V)    := W;
                  Parent (V) := U;
               end if;
            end if;
         end loop;
      end loop;
   end Prim;

   ---------------------------------------------------------------------------
   -- Kruskal on the complete geometric graph
   ---------------------------------------------------------------------------

   type Index_Array is array (Positive range <>) of Positive;

   procedure Sort_Indices_By_Length
     (Edges : CG_Edge_Array;
      Index : in out Index_Array;
      M     : Natural)
   is
      J     : Natural;
      Key   : Positive;
      Key_L : Length_Type;
      Less  : Boolean;
   begin
      for I in 2 .. M loop
         Key   := Index (I);
         Key_L := Edges (Key).Length;
         J     := I - 1;
         while J >= 1 loop
            Less :=
              Edges (Index (J)).Length > Key_L
              or else
              (Edges (Index (J)).Length = Key_L
               and then Index (J) > Key);
            exit when not Less;
            Index (J + 1) := Index (J);
            J := J - 1;
         end loop;
         Index (J + 1) := Key;
      end loop;
   end Sort_Indices_By_Length;

   procedure Kruskal
     (S            : Point_Set;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Length : out Length_Sum)
   is
      N : constant Natural := S.N;

      Edges  : CG_Edge_Array;
      M      : Natural;
      Index  : Index_Array (1 .. Max_Edges);
      Parent : Parent_Array;
      Rank   : Rank_Array;
      E      : Positive;
      U, V   : Natural;
   begin
      Require_Tree_Buffer (N, Tree_Edges);

      Tree_Count   := 0;
      Total_Length := 0;

      Build_Complete_Graph (S, Edges, M);

      for I in 1 .. M loop
         Index (I) := I;
      end loop;

      Sort_Indices_By_Length (Edges, Index, M);
      UF_Init (Parent, Rank, N);

      for K in 1 .. M loop
         exit when Tree_Count = N - 1;
         E := Index (K);
         U := Natural (Edges (E).U);
         V := Natural (Edges (E).V);
         if UF_Find (Parent, U) /= UF_Find (Parent, V) then
            UF_Union (Parent, Rank, U, V);
            Tree_Count := Tree_Count + 1;
            Tree_Edges (Tree_Count) :=
              (U      => Edges (E).U,
               V      => Edges (E).V,
               Length => Edges (E).Length);
            Total_Length :=
              Total_Length + Length_Sum (Edges (E).Length);
         end if;
      end loop;
   end Kruskal;

   ---------------------------------------------------------------------------
   -- Public synonyms
   ---------------------------------------------------------------------------

   procedure Compute
     (S            : Point_Set;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Length : out Length_Sum)
   is
   begin
      Prim (S, Tree_Edges, Tree_Count, Total_Length);
   end Compute;

   procedure EMST
     (S            : Point_Set;
      Tree_Edges   : in out Edge_List;
      Tree_Count   : out Natural;
      Total_Length : out Length_Sum)
   is
   begin
      Compute (S, Tree_Edges, Tree_Count, Total_Length);
   end EMST;

end Euclidean_Minimum_Spanning_Tree;
