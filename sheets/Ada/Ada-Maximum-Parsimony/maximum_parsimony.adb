--  Maximum_Parsimony body — Fitch (1971) scoring and exhaustive MP search.

pragma Ada_2022;

package body Maximum_Parsimony is

   type State_Bits is mod 2 ** Max_States;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Taxon_Count_Of (M : Character_Matrix) return Taxon_Count is
   begin
      return Taxon_Count (M'Length (1));
   end Taxon_Count_Of;

   function Site_Count_Of (M : Character_Matrix) return Site_Count is
   begin
      return Site_Count (M'Length (2));
   end Site_Count_Of;

   function Make_Matrix
     (N_Taxa  : Taxon_Count;
      N_Sites : Site_Count;
      Fill    : State_Value := 0) return Character_Matrix
   is
   begin
      if N_Taxa = 0 or else N_Sites = 0 then
         raise Invalid_Argument with "Make_Matrix: empty dimensions";
      end if;
      declare
         M : constant Character_Matrix (1 .. N_Taxa, 1 .. N_Sites) :=
           [others => [others => Fill]];
      begin
         return M;
      end;
   end Make_Matrix;

   procedure Set_State
     (M     : in out Character_Matrix;
      Taxon : Taxon_Index;
      Site  : Site_Index;
      Value : State_Value)
   is
   begin
      if Taxon < M'First (1) or else Taxon > M'Last (1)
        or else Site < M'First (2) or else Site > M'Last (2)
      then
         raise Invalid_Argument with "Set_State: index out of range";
      end if;
      M (Taxon, Site) := Value;
   end Set_State;

   function Get_State
     (M     : Character_Matrix;
      Taxon : Taxon_Index;
      Site  : Site_Index) return State_Value
   is
   begin
      if Taxon < M'First (1) or else Taxon > M'Last (1)
        or else Site < M'First (2) or else Site > M'Last (2)
      then
         raise Invalid_Argument with "Get_State: index out of range";
      end if;
      return M (Taxon, Site);
   end Get_State;

   function Hamming_Distance
     (M : Character_Matrix; A, B : Taxon_Index) return Natural
   is
      D : Natural := 0;
   begin
      if A < M'First (1) or else A > M'Last (1)
        or else B < M'First (1) or else B > M'Last (1)
      then
         raise Invalid_Argument with "Hamming_Distance: taxon out of range";
      end if;
      for Site in M'Range (2) loop
         if M (A, Site) /= M (B, Site) then
            D := D + 1;
         end if;
      end loop;
      return D;
   end Hamming_Distance;

   ---------------------------------------------------------------------------
   -- Tree construction
   ---------------------------------------------------------------------------

   function Is_Leaf (T : Tree; N : Node_Id) return Boolean is
   begin
      if N = 0 then
         return False;
      end if;
      return T.Nodes (N).Left = 0 and then T.Nodes (N).Right = 0
        and then T.Nodes (N).Taxon /= 0;
   end Is_Leaf;

   function Node_Count (T : Tree) return Natural is
   begin
      if T.N = 0 then
         return 0;
      end if;
      return Natural (2 * T.N - 1);
   end Node_Count;

   function Leaf_Tree (Taxon : Taxon_Index) return Tree is
      T : Tree;
   begin
      T.N := 1;
      T.Root := Node_Id (Taxon);
      T.Nodes (Taxon).Taxon  := Taxon;
      T.Nodes (Taxon).Left   := 0;
      T.Nodes (Taxon).Right  := 0;
      T.Nodes (Taxon).Parent := 0;
      return T;
   end Leaf_Tree;

   procedure Graft
     (Dst      : in out Tree;
      Src      : Tree;
      Src_Node : Node_Id;
      New_Root : out Node_Id;
      Next_Id  : in out Natural)
   is
      L, R : Node_Id;
   begin
      if Src_Node = 0 then
         raise Invalid_Argument with "Graft: null node";
      end if;
      if Is_Leaf (Src, Src_Node) then
         declare
            Tid : constant Taxon_Index :=
              Taxon_Index (Src.Nodes (Src_Node).Taxon);
         begin
            Dst.Nodes (Tid).Taxon  := Tid;
            Dst.Nodes (Tid).Left   := 0;
            Dst.Nodes (Tid).Right  := 0;
            Dst.Nodes (Tid).Parent := 0;
            New_Root := Node_Id (Tid);
         end;
      else
         Graft (Dst, Src, Src.Nodes (Src_Node).Left, L, Next_Id);
         Graft (Dst, Src, Src.Nodes (Src_Node).Right, R, Next_Id);
         if Next_Id > Max_Nodes then
            raise Capacity_Exceeded with "Graft: out of node ids";
         end if;
         New_Root := Node_Id (Next_Id);
         Next_Id  := Next_Id + 1;
         Dst.Nodes (New_Root).Left   := L;
         Dst.Nodes (New_Root).Right  := R;
         Dst.Nodes (New_Root).Taxon  := 0;
         Dst.Nodes (New_Root).Parent := 0;
         Dst.Nodes (L).Parent := New_Root;
         Dst.Nodes (R).Parent := New_Root;
      end if;
   end Graft;

   function Join (Left, Right : Tree) return Tree is
      Result  : Tree;
      Next_Id : Natural;
      LR, RR  : Node_Id;
      Used    : array (Taxon_Index) of Boolean := [others => False];
      Total   : Natural := 0;
   begin
      if Left.N = 0 or else Right.N = 0 then
         raise Invalid_Argument with "Join: empty child tree";
      end if;

      for I in Taxon_Index loop
         if Left.Nodes (I).Taxon = I
           and then Left.Nodes (I).Left = 0
           and then Left.Nodes (I).Right = 0
         then
            Used (I) := True;
            Total := Total + 1;
         end if;
      end loop;
      for I in Taxon_Index loop
         if Right.Nodes (I).Taxon = I
           and then Right.Nodes (I).Left = 0
           and then Right.Nodes (I).Right = 0
         then
            if Used (I) then
               raise Invalid_Argument with "Join: overlapping leaf labels";
            end if;
            Used (I) := True;
            Total := Total + 1;
         end if;
      end loop;

      if Total = 0 then
         raise Invalid_Argument with "Join: no leaves found";
      end if;

      Result.N := Taxon_Count (Total);
      --  Leaves occupy ids 1 .. Max_Taxa; internals use Max_Taxa+1 .. Max_Nodes.
      Next_Id  := Max_Taxa + 1;

      Graft (Result, Left, Left.Root, LR, Next_Id);
      Graft (Result, Right, Right.Root, RR, Next_Id);

      if Next_Id > Max_Nodes then
         raise Capacity_Exceeded with "Join: cannot allocate root";
      end if;

      Result.Root := Node_Id (Next_Id);
      Result.Nodes (Result.Root).Left   := LR;
      Result.Nodes (Result.Root).Right  := RR;
      Result.Nodes (Result.Root).Taxon  := 0;
      Result.Nodes (Result.Root).Parent := 0;
      Result.Nodes (LR).Parent := Result.Root;
      Result.Nodes (RR).Parent := Result.Root;
      return Result;
   end Join;

   function Triplet_Tree (A, B, C : Taxon_Index) return Tree is
   begin
      return Join (Join (Leaf_Tree (A), Leaf_Tree (B)), Leaf_Tree (C));
   end Triplet_Tree;

   function Quartet_Tree (A, B, C, D : Taxon_Index) return Tree is
   begin
      return Join
        (Join (Join (Leaf_Tree (A), Leaf_Tree (B)), Leaf_Tree (C)),
         Leaf_Tree (D));
   end Quartet_Tree;

   function Balanced_Quartet (A, B, C, D : Taxon_Index) return Tree is
   begin
      return Join
        (Join (Leaf_Tree (A), Leaf_Tree (B)),
         Join (Leaf_Tree (C), Leaf_Tree (D)));
   end Balanced_Quartet;

   ---------------------------------------------------------------------------
   -- Fitch (1971)
   ---------------------------------------------------------------------------

   function Singleton (St : State_Value; S : State_Count) return State_Bits is
   begin
      if Natural (St) >= Natural (S) then
         raise Invalid_Argument with "Fitch: state out of alphabet";
      end if;
      return State_Bits (2 ** Natural (St));
   end Singleton;

   function Fitch_Recurse
     (T    : Tree;
      M    : Character_Matrix;
      Site : Site_Index;
      S    : State_Count;
      N    : Node_Id;
      Cost : in out Natural) return State_Bits
   is
      Left_Set, Right_Set, Inter : State_Bits;
   begin
      if N = 0 then
         raise Invalid_Argument with "Fitch: null node";
      end if;
      if Is_Leaf (T, N) then
         declare
            Tid : constant Taxon_Count := T.Nodes (N).Taxon;
         begin
            if Tid = 0
              or else Taxon_Index (Tid) < M'First (1)
              or else Taxon_Index (Tid) > M'Last (1)
            then
               raise Invalid_Argument with "Fitch: taxon not in matrix";
            end if;
            return Singleton (M (Taxon_Index (Tid), Site), S);
         end;
      end if;

      Left_Set  := Fitch_Recurse (T, M, Site, S, T.Nodes (N).Left, Cost);
      Right_Set := Fitch_Recurse (T, M, Site, S, T.Nodes (N).Right, Cost);
      Inter     := Left_Set and Right_Set;
      if Inter /= 0 then
         return Inter;
      else
         Cost := Cost + 1;
         return Left_Set or Right_Set;
      end if;
   end Fitch_Recurse;

   function Fitch_Score_Site
     (T    : Tree;
      M    : Character_Matrix;
      Site : Site_Index;
      S    : State_Count := 4) return Natural
   is
      Cost   : Natural := 0;
      Unused : State_Bits;
      pragma Unreferenced (Unused);
   begin
      if T.N = 0 or else T.Root = 0 then
         raise Invalid_Argument with "Fitch_Score_Site: empty tree";
      end if;
      if Site < M'First (2) or else Site > M'Last (2) then
         raise Invalid_Argument with "Fitch_Score_Site: site out of range";
      end if;
      if Natural (T.N) > M'Length (1) then
         raise Invalid_Argument with "Fitch_Score_Site: tree/matrix mismatch";
      end if;
      Unused := Fitch_Recurse (T, M, Site, S, T.Root, Cost);
      return Cost;
   end Fitch_Score_Site;

   function Fitch_Score_Tree
     (T : Tree;
      M : Character_Matrix;
      S : State_Count := 4) return Natural
   is
      Total : Natural := 0;
   begin
      if T.N = 0 then
         raise Invalid_Argument with "Fitch_Score_Tree: empty tree";
      end if;
      for Site in M'Range (2) loop
         Total := Total + Fitch_Score_Site (T, M, Site, S);
      end loop;
      return Total;
   end Fitch_Score_Tree;

   ---------------------------------------------------------------------------
   -- Exhaustive enumeration
   ---------------------------------------------------------------------------

   function Count_Rooted_Topologies (N : Taxon_Count) return Natural is
      Acc : Natural := 1;
      K   : Natural;
   begin
      if N <= 1 then
         return 1;
      end if;
      K := 1;
      while K <= Natural (2 * N - 3) loop
         Acc := Acc * K;
         K   := K + 2;
      end loop;
      return Acc;
   end Count_Rooted_Topologies;

   type Leaf_List is array (1 .. Max_Taxa) of Taxon_Index;
   type Leaf_Set is record
      Count : Taxon_Count := 0;
      Items : Leaf_List;
   end record;

   function Make_Set (N : Taxon_Count) return Leaf_Set is
      S : Leaf_Set;
   begin
      S.Count := N;
      for I in 1 .. N loop
         S.Items (I) := I;
      end loop;
      return S;
   end Make_Set;

   Max_Topo : constant := 945;
   type Tree_Vec is array (1 .. Max_Topo) of Tree;

   procedure Generate
     (Leaves : Leaf_Set;
      Store  : in out Tree_Vec;
      Count  : in out Natural)
   is
   begin
      if Leaves.Count = 0 then
         raise Invalid_Argument with "Generate: empty leaf set";
      elsif Leaves.Count = 1 then
         Count := Count + 1;
         Store (Count) := Leaf_Tree (Leaves.Items (1));
      elsif Leaves.Count = 2 then
         Count := Count + 1;
         Store (Count) :=
           Join (Leaf_Tree (Leaves.Items (1)), Leaf_Tree (Leaves.Items (2)));
      else
         declare
            Pivot  : constant Taxon_Index := Leaves.Items (1);
            Rest_N : constant Natural := Natural (Leaves.Count) - 1;
            Max_Sub : constant Natural := 2 ** Rest_N;
         begin
            for Sub in 0 .. Max_Sub - 1 loop
               declare
                  Left_S, Right_S : Leaf_Set;
                  Lstore, Rstore  : Tree_Vec;
                  LC, RC          : Natural := 0;
                  Bit             : Natural;
               begin
                  Left_S.Count := 1;
                  Left_S.Items (1) := Pivot;
                  Right_S.Count := 0;
                  for K in 1 .. Rest_N loop
                     Bit := (Sub / (2 ** (K - 1))) mod 2;
                     if Bit = 1 then
                        Left_S.Count := Left_S.Count + 1;
                        Left_S.Items (Left_S.Count) := Leaves.Items (K + 1);
                     else
                        Right_S.Count := Right_S.Count + 1;
                        Right_S.Items (Right_S.Count) := Leaves.Items (K + 1);
                     end if;
                  end loop;
                  if Right_S.Count > 0 then
                     Generate (Left_S, Lstore, LC);
                     Generate (Right_S, Rstore, RC);
                     for Li in 1 .. LC loop
                        for Ri in 1 .. RC loop
                           Count := Count + 1;
                           if Count > Max_Topo then
                              raise Capacity_Exceeded
                                with "Generate: topology overflow";
                           end if;
                           Store (Count) := Join (Lstore (Li), Rstore (Ri));
                        end loop;
                     end loop;
                  end if;
               end;
            end loop;
         end;
      end if;
   end Generate;

   function Exhaustive_Search
     (M : Character_Matrix;
      S : State_Count := 4) return Search_Result
   is
      N     : constant Taxon_Count := Taxon_Count_Of (M);
      Best  : Search_Result;
      Store : Tree_Vec;
      Count : Natural := 0;
      Len   : Natural;
   begin
      if N = 0 then
         raise Invalid_Argument with "Exhaustive_Search: empty matrix";
      end if;
      if Site_Count_Of (M) = 0 then
         raise Invalid_Argument with "Exhaustive_Search: no sites";
      end if;

      Best.Best_Length := Natural'Last;
      Best.Trees_Tried := 0;

      if N = 1 then
         Best.Best_Tree   := Leaf_Tree (1);
         Best.Best_Length := 0;
         Best.Trees_Tried := 1;
         return Best;
      end if;

      Generate (Make_Set (N), Store, Count);

      for I in 1 .. Count loop
         Len := Fitch_Score_Tree (Store (I), M, S);
         Best.Trees_Tried := Best.Trees_Tried + 1;
         if I = 1 or else Len < Best.Best_Length then
            Best.Best_Length := Len;
            Best.Best_Tree   := Store (I);
         end if;
      end loop;
      return Best;
   end Exhaustive_Search;

end Maximum_Parsimony;
