--  Best_Bin_First — package body (k-d tree + Beis/Lowe BBF search).

pragma Ada_2022;

package body Best_Bin_First
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point
     (A, B : Point; Dim : Dim_Index; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for I in 1 .. Dim loop
         if abs (A.C (I) - B.C (I)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Near_Point;

   function Distance2 (A, B : Point; Dim : Dim_Index) return Non_Negative is
      S : Real := 0.0;
      D : Real;
   begin
      for I in 1 .. Dim loop
         D := A.C (I) - B.C (I);
         S := S + D * D;
      end loop;
      return Non_Negative (S);
   end Distance2;

   function Dist2_To_AABB
     (Q : Point; Lo, Hi : Coord_Array; Dim : Dim_Index) return Non_Negative
   is
      S : Real := 0.0;
      D : Real;
   begin
      for I in 1 .. Dim loop
         if Q.C (I) < Lo (I) then
            D := Lo (I) - Q.C (I);
            S := S + D * D;
         elsif Q.C (I) > Hi (I) then
            D := Q.C (I) - Hi (I);
            S := S + D * D;
         end if;
      end loop;
      return Non_Negative (S);
   end Dist2_To_AABB;

   ---------------------------------------------------------------------------
   -- Point / cloud
   ---------------------------------------------------------------------------

   function Make_Point
     (Dim : Dim_Index; Coords : Coord_Array) return Point
   is
      P : Point;
   begin
      for I in 1 .. Dim loop
         P.C (I) := Coords (I);
      end loop;
      for I in Dim + 1 .. Max_Dim loop
         P.C (I) := 0.0;
      end loop;
      return P;
   end Make_Point;

   function Make_Cloud (Dim : Dim_Index) return Point_Cloud is
      C : Point_Cloud;
   begin
      C.Dim   := Dim;
      C.Count := 0;
      return C;
   end Make_Cloud;

   procedure Add_Point (Cloud : in out Point_Cloud; P : Point) is
   begin
      if Cloud.Dim = 0 then
         raise Invalid_Argument with "Add_Point: cloud Dim is 0";
      end if;
      if Cloud.Count = Max_Points then
         raise Capacity_Exceeded with "Add_Point: Max_Points exceeded";
      end if;
      Cloud.Count := Cloud.Count + 1;
      Cloud.Points (Cloud.Count) := P;
   end Add_Point;

   function Cloud_Count (Cloud : Point_Cloud) return Point_Count is
   begin
      return Cloud.Count;
   end Cloud_Count;

   function Cloud_Dim (Cloud : Point_Cloud) return Dim_Count is
   begin
      return Cloud.Dim;
   end Cloud_Dim;

   function Default_Config (E_Max : Positive := 32) return Config is
   begin
      return (E_Max => E_Max, Max_Dim => 8, Max_Points => 256);
   end Default_Config;

   ---------------------------------------------------------------------------
   -- Priority queue (binary min-heap on Dist2)
   ---------------------------------------------------------------------------

   function Empty_Heap return Bin_Heap is
      H : Bin_Heap;
   begin
      H.Count := 0;
      return H;
   end Empty_Heap;

   function Heap_Count (H : Bin_Heap) return Natural is
   begin
      return H.Count;
   end Heap_Count;

   procedure Heap_Push (H : in out Bin_Heap; E : Bin_Entry) is
      I, Parent : Natural;
      Tmp       : Bin_Entry;
   begin
      if H.Count = Max_PQ then
         raise Capacity_Exceeded with "Heap_Push: Max_PQ exceeded";
      end if;
      H.Count := H.Count + 1;
      I := H.Count;
      H.Data (I) := E;
      while I > 1 loop
         Parent := I / 2;
         if H.Data (I).Dist2 < H.Data (Parent).Dist2 then
            Tmp := H.Data (I);
            H.Data (I) := H.Data (Parent);
            H.Data (Parent) := Tmp;
            I := Parent;
         else
            exit;
         end if;
      end loop;
   end Heap_Push;

   function Heap_Peek (H : Bin_Heap) return Bin_Entry is
   begin
      return H.Data (1);
   end Heap_Peek;

   procedure Heap_Pop (H : in out Bin_Heap; E : out Bin_Entry) is
      I, Left, Right, Smallest : Natural;
      Tmp                      : Bin_Entry;
   begin
      E := H.Data (1);
      H.Data (1) := H.Data (H.Count);
      H.Count := H.Count - 1;
      I := 1;
      loop
         Left := 2 * I;
         Right := Left + 1;
         Smallest := I;
         if Left <= H.Count
           and then H.Data (Left).Dist2 < H.Data (Smallest).Dist2
         then
            Smallest := Left;
         end if;
         if Right <= H.Count
           and then H.Data (Right).Dist2 < H.Data (Smallest).Dist2
         then
            Smallest := Right;
         end if;
         exit when Smallest = I;
         Tmp := H.Data (I);
         H.Data (I) := H.Data (Smallest);
         H.Data (Smallest) := Tmp;
         I := Smallest;
      end loop;
   end Heap_Pop;

   ---------------------------------------------------------------------------
   -- Tree accessors
   ---------------------------------------------------------------------------

   function Tree_Empty (Tree : KD_Tree) return Boolean is
   begin
      return Tree.Root = 0 or else Tree.Count = 0;
   end Tree_Empty;

   function Tree_Count (Tree : KD_Tree) return Point_Count is
   begin
      return Tree.Count;
   end Tree_Count;

   function Tree_Dim (Tree : KD_Tree) return Dim_Count is
   begin
      return Tree.Dim;
   end Tree_Dim;

   function Tree_Root (Tree : KD_Tree) return Node_Index is
   begin
      return Tree.Root;
   end Tree_Root;

   function Node_Is_Leaf (Tree : KD_Tree; N : Node_Index) return Boolean is
   begin
      if N = 0 or else N > Tree.Node_Count then
         return False;
      end if;
      return Tree.Nodes (N).Is_Leaf;
   end Node_Is_Leaf;

   function Node_Point_Index (Tree : KD_Tree; N : Node_Index) return Natural is
   begin
      if N = 0 or else N > Tree.Node_Count then
         return 0;
      end if;
      return Tree.Nodes (N).Point_Index;
   end Node_Point_Index;

   ---------------------------------------------------------------------------
   -- Build helpers
   ---------------------------------------------------------------------------

   procedure Compute_AABB
     (Points : Point_Array;
      Idx    : Index_Array;
      First  : Point_Index;
      Last   : Point_Index;
      Dim    : Dim_Index;
      Lo, Hi : out Coord_Array)
   is
      P : Point;
   begin
      Lo := [others => 0.0];
      Hi := [others => 0.0];
      P := Points (Idx (First));
      for D in 1 .. Dim loop
         Lo (D) := P.C (D);
         Hi (D) := P.C (D);
      end loop;
      for I in First + 1 .. Last loop
         P := Points (Idx (I));
         for D in 1 .. Dim loop
            if P.C (D) < Lo (D) then
               Lo (D) := P.C (D);
            end if;
            if P.C (D) > Hi (D) then
               Hi (D) := P.C (D);
            end if;
         end loop;
      end loop;
   end Compute_AABB;

   procedure Partition_Median
     (Points : Point_Array;
      Idx    : in out Index_Array;
      First  : Point_Index;
      Last   : Point_Index;
      Axis   : Dim_Index;
      Mid    : Point_Index)
   is
      --  Simple selection: place the Mid-th element of Idx(First..Last)
      --  by Axis coordinate (Hoare-style partition loop).
      Lo, Hi, Pivot_Pos : Point_Index;
      Pivot_Val         : Real;
      Tmp               : Point_Index;
   begin
      Lo := First;
      Hi := Last;
      while Lo < Hi loop
         Pivot_Pos := (Lo + Hi) / 2;
         Pivot_Val := Points (Idx (Pivot_Pos)).C (Axis);
         --  Move pivot to Hi end temporarily
         Tmp := Idx (Pivot_Pos);
         Idx (Pivot_Pos) := Idx (Hi);
         Idx (Hi) := Tmp;
         Pivot_Pos := Lo;
         for I in Lo .. Hi - 1 loop
            if Points (Idx (I)).C (Axis) <= Pivot_Val then
               Tmp := Idx (Pivot_Pos);
               Idx (Pivot_Pos) := Idx (I);
               Idx (I) := Tmp;
               Pivot_Pos := Pivot_Pos + 1;
            end if;
         end loop;
         Tmp := Idx (Pivot_Pos);
         Idx (Pivot_Pos) := Idx (Hi);
         Idx (Hi) := Tmp;
         if Pivot_Pos = Mid then
            return;
         elsif Pivot_Pos < Mid then
            Lo := Pivot_Pos + 1;
         else
            if Pivot_Pos = First then
               return;
            end if;
            Hi := Pivot_Pos - 1;
         end if;
      end loop;
   end Partition_Median;

   function Alloc_Node (Tree : in out KD_Tree) return Node_Index is
   begin
      if Tree.Node_Count = Max_Nodes then
         raise Capacity_Exceeded with "Build_Tree: Max_Nodes exceeded";
      end if;
      Tree.Node_Count := Tree.Node_Count + 1;
      return Tree.Node_Count;
   end Alloc_Node;

   function Build_Rec
     (Tree  : in out KD_Tree;
      Idx   : in out Index_Array;
      First : Point_Index;
      Last  : Point_Index;
      Depth : Natural;
      Lo, Hi : Coord_Array) return Node_Index
   is
      N     : Node_Index;
      Axis  : Dim_Index;
      Mid   : Point_Index;
      Left_Hi, Right_Lo : Coord_Array;
      Child_Lo, Child_Hi : Coord_Array;
   begin
      N := Alloc_Node (Tree);
      Tree.Nodes (N).Lo := Lo;
      Tree.Nodes (N).Hi := Hi;

      if First = Last then
         Tree.Nodes (N).Is_Leaf := True;
         Tree.Nodes (N).Point_Index := Natural (Idx (First));
         Tree.Nodes (N).Left := 0;
         Tree.Nodes (N).Right := 0;
         return N;
      end if;

      Axis := Dim_Index ((Depth mod Natural (Tree.Dim)) + 1);
      Mid := Point_Index (First + (Last - First) / 2);
      Partition_Median (Tree.Points, Idx, First, Last, Axis, Mid);

      Tree.Nodes (N).Is_Leaf := False;
      Tree.Nodes (N).Split_Dim := Axis;
      Tree.Nodes (N).Split_Val := Tree.Points (Idx (Mid)).C (Axis);
      Tree.Nodes (N).Point_Index := 0;

      Left_Hi := Hi;
      Left_Hi (Axis) := Tree.Nodes (N).Split_Val;
      Right_Lo := Lo;
      Right_Lo (Axis) := Tree.Nodes (N).Split_Val;

      --  Left: First .. Mid (includes median point as leaf-side partition)
      --  Classic: left First..Mid, right Mid+1..Last when Mid < Last
      if Mid < Last then
         Child_Lo := Lo;
         Child_Hi := Left_Hi;
         Tree.Nodes (N).Left :=
           Build_Rec (Tree, Idx, First, Mid, Depth + 1, Child_Lo, Child_Hi);
         Child_Lo := Right_Lo;
         Child_Hi := Hi;
         Tree.Nodes (N).Right :=
           Build_Rec
             (Tree, Idx, Mid + 1, Last, Depth + 1, Child_Lo, Child_Hi);
      else
         --  All remaining on one side (duplicate coords); make leaf of Mid
         Tree.Nodes (N).Is_Leaf := True;
         Tree.Nodes (N).Point_Index := Natural (Idx (Mid));
         Tree.Nodes (N).Left := 0;
         Tree.Nodes (N).Right := 0;
      end if;
      return N;
   end Build_Rec;

   function Build_Tree (Cloud : Point_Cloud) return KD_Tree is
      Tree : KD_Tree;
      Idx  : Index_Array;
      Lo, Hi : Coord_Array;
   begin
      if Cloud.Count > 0 and then Cloud.Dim = 0 then
         raise Invalid_Argument with "Build_Tree: Dim is 0 with points";
      end if;

      Tree.Count := Cloud.Count;
      Tree.Dim := Cloud.Dim;
      Tree.Node_Count := 0;
      Tree.Root := 0;

      if Cloud.Count = 0 then
         return Tree;
      end if;

      for I in 1 .. Cloud.Count loop
         Tree.Points (I) := Cloud.Points (I);
         Idx (I) := I;
      end loop;

      Compute_AABB
        (Tree.Points, Idx, 1, Cloud.Count, Dim_Index (Cloud.Dim), Lo, Hi);
      Tree.Root :=
        Build_Rec
          (Tree, Idx, 1, Cloud.Count, 0, Lo, Hi);
      return Tree;
   end Build_Tree;

   ---------------------------------------------------------------------------
   -- Exact NN
   ---------------------------------------------------------------------------

   function Exact_NN (Cloud : Point_Cloud; Query : Point) return NN_Result is
      R    : NN_Result;
      D2   : Non_Negative;
      Best : Non_Negative;
      Dim  : Dim_Index;
   begin
      if Cloud.Count = 0 or else Cloud.Dim = 0 then
         R.Found := False;
         return R;
      end if;
      Dim := Dim_Index (Cloud.Dim);
      Best := Distance2 (Query, Cloud.Points (1), Dim);
      R.Index := 1;
      R.Found := True;
      R.Distance2 := Best;
      R.Bins_Examined := Cloud.Count;
      for I in 2 .. Cloud.Count loop
         D2 := Distance2 (Query, Cloud.Points (I), Dim);
         if D2 < Best then
            Best := D2;
            R.Index := Natural (I);
            R.Distance2 := Best;
         end if;
      end loop;
      return R;
   end Exact_NN;

   ---------------------------------------------------------------------------
   -- BBF approximate NN / k-NN
   ---------------------------------------------------------------------------

   procedure Consider_Leaf
     (Tree   : KD_Tree;
      Node   : Node_Index;
      Query  : Point;
      Best_I : in out Natural;
      Best_D : in out Non_Negative;
      Found  : in out Boolean)
   is
      PI : Natural;
      D2 : Non_Negative;
      Dim : Dim_Index;
   begin
      if not Tree.Nodes (Node).Is_Leaf then
         return;
      end if;
      PI := Tree.Nodes (Node).Point_Index;
      if PI = 0 or else PI > Natural (Tree.Count) then
         return;
      end if;
      Dim := Dim_Index (Tree.Dim);
      D2 := Distance2 (Query, Tree.Points (Point_Index (PI)), Dim);
      if not Found or else D2 < Best_D then
         Found := True;
         Best_D := D2;
         Best_I := PI;
      end if;
   end Consider_Leaf;

   procedure Insert_Neighbor
     (Items : in out Neighbor_List;
      Count : in out K_Count;
      K     : K_Index;
      Idx   : Natural;
      D2    : Non_Negative)
   is
      Pos : Natural;
   begin
      --  Reject duplicates
      for I in 1 .. Count loop
         if Items (I).Index = Idx then
            return;
         end if;
      end loop;

      if Count < K then
         Count := Count + 1;
         Pos := Natural (Count);
      else
         if D2 >= Items (Count).Distance2 then
            return;
         end if;
         Pos := Natural (Count);
      end if;

      Items (K_Index (Pos)) := (Index => Idx, Distance2 => D2);
      --  Bubble toward front (ascending Distance2)
      while Pos > 1
        and then Items (K_Index (Pos)).Distance2
                 < Items (K_Index (Pos - 1)).Distance2
      loop
         declare
            T : constant Neighbor := Items (K_Index (Pos));
         begin
            Items (K_Index (Pos)) := Items (K_Index (Pos - 1));
            Items (K_Index (Pos - 1)) := T;
         end;
         Pos := Pos - 1;
      end loop;
   end Insert_Neighbor;

   function Approximate_NN
     (Tree  : KD_Tree;
      Query : Point;
      E_Max : Positive) return NN_Result
   is
      R       : NN_Result;
      H       : Bin_Heap := Empty_Heap;
      E       : Bin_Entry;
      N       : Node_Index;
      Examined : Natural := 0;
      Best_I  : Natural := 0;
      Best_D  : Non_Negative := 0.0;
      Found   : Boolean := False;
      Dim     : Dim_Index;
      Child_D : Non_Negative;
   begin
      if Tree_Empty (Tree) or else Tree.Dim = 0 then
         return R;
      end if;
      Dim := Dim_Index (Tree.Dim);

      Heap_Push
        (H,
         (Node  => Tree.Root,
          Dist2 => Dist2_To_AABB
                     (Query,
                      Tree.Nodes (Tree.Root).Lo,
                      Tree.Nodes (Tree.Root).Hi,
                      Dim)));

      while Heap_Count (H) > 0 and then Examined < E_Max loop
         Heap_Pop (H, E);
         N := E.Node;
         if N = 0 or else N > Tree.Node_Count then
            null;
         elsif Tree.Nodes (N).Is_Leaf then
            Examined := Examined + 1;
            Consider_Leaf (Tree, N, Query, Best_I, Best_D, Found);
         else
            --  Internal bin: count toward E_Max optionally; Beis/Lowe
            --  primarily limit leaf examinations. We count leaves only.
            if Tree.Nodes (N).Left /= 0 then
               Child_D := Dist2_To_AABB
                 (Query,
                  Tree.Nodes (Tree.Nodes (N).Left).Lo,
                  Tree.Nodes (Tree.Nodes (N).Left).Hi,
                  Dim);
               Heap_Push (H, (Node => Tree.Nodes (N).Left, Dist2 => Child_D));
            end if;
            if Tree.Nodes (N).Right /= 0 then
               Child_D := Dist2_To_AABB
                 (Query,
                  Tree.Nodes (Tree.Nodes (N).Right).Lo,
                  Tree.Nodes (Tree.Nodes (N).Right).Hi,
                  Dim);
               Heap_Push
                 (H, (Node => Tree.Nodes (N).Right, Dist2 => Child_D));
            end if;
         end if;
      end loop;

      R.Found := Found;
      R.Index := Best_I;
      R.Distance2 := Best_D;
      R.Bins_Examined := Examined;
      return R;
   end Approximate_NN;

   function Query_NN
     (Tree  : KD_Tree;
      Query : Point;
      Cfg   : Config) return NN_Result
   is
   begin
      return Approximate_NN (Tree, Query, Cfg.E_Max);
   end Query_NN;

   function Approximate_KNN
     (Tree  : KD_Tree;
      Query : Point;
      K     : K_Index;
      E_Max : Positive) return KNN_Result
   is
      R        : KNN_Result;
      H        : Bin_Heap := Empty_Heap;
      E        : Bin_Entry;
      N        : Node_Index;
      Examined : Natural := 0;
      Dim      : Dim_Index;
      Child_D  : Non_Negative;
      PI       : Natural;
      D2       : Non_Negative;
   begin
      if Tree_Empty (Tree) or else Tree.Dim = 0 then
         return R;
      end if;
      Dim := Dim_Index (Tree.Dim);

      Heap_Push
        (H,
         (Node  => Tree.Root,
          Dist2 => Dist2_To_AABB
                     (Query,
                      Tree.Nodes (Tree.Root).Lo,
                      Tree.Nodes (Tree.Root).Hi,
                      Dim)));

      while Heap_Count (H) > 0 and then Examined < E_Max loop
         Heap_Pop (H, E);
         N := E.Node;
         if N = 0 or else N > Tree.Node_Count then
            null;
         elsif Tree.Nodes (N).Is_Leaf then
            Examined := Examined + 1;
            PI := Tree.Nodes (N).Point_Index;
            if PI >= 1 and then PI <= Natural (Tree.Count) then
               D2 := Distance2
                 (Query, Tree.Points (Point_Index (PI)), Dim);
               Insert_Neighbor (R.Items, R.Count, K, PI, D2);
            end if;
         else
            if Tree.Nodes (N).Left /= 0 then
               Child_D := Dist2_To_AABB
                 (Query,
                  Tree.Nodes (Tree.Nodes (N).Left).Lo,
                  Tree.Nodes (Tree.Nodes (N).Left).Hi,
                  Dim);
               Heap_Push (H, (Node => Tree.Nodes (N).Left, Dist2 => Child_D));
            end if;
            if Tree.Nodes (N).Right /= 0 then
               Child_D := Dist2_To_AABB
                 (Query,
                  Tree.Nodes (Tree.Nodes (N).Right).Lo,
                  Tree.Nodes (Tree.Nodes (N).Right).Hi,
                  Dim);
               Heap_Push
                 (H, (Node => Tree.Nodes (N).Right, Dist2 => Child_D));
            end if;
         end if;
      end loop;

      R.Bins_Examined := Examined;
      return R;
   end Approximate_KNN;

end Best_Bin_First;
