--  Nearest_Neighbor_Search — package body (distances, linear / radius,
--  k-d tree exact NN, k-NN majority vote, taxonomy).

pragma Ada_2022;

package body Nearest_Neighbor_Search
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

   ---------------------------------------------------------------------------
   -- Distances
   ---------------------------------------------------------------------------

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

   function Manhattan (A, B : Point; Dim : Dim_Index) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in 1 .. Dim loop
         S := S + abs (A.C (I) - B.C (I));
      end loop;
      return Non_Negative (S);
   end Manhattan;

   function Chebyshev (A, B : Point; Dim : Dim_Index) return Non_Negative is
      M : Real := 0.0;
      D : Real;
   begin
      for I in 1 .. Dim loop
         D := abs (A.C (I) - B.C (I));
         if D > M then
            M := D;
         end if;
      end loop;
      return Non_Negative (M);
   end Chebyshev;

   function Distance
     (A, B : Point; Dim : Dim_Index; Kind : Distance_Kind) return Non_Negative
   is
   begin
      case Kind is
         when Euclidean_Squared =>
            return Distance2 (A, B, Dim);
         when Manhattan =>
            return Manhattan (A, B, Dim);
         when Chebyshev =>
            return Chebyshev (A, B, Dim);
      end case;
   end Distance;

   function Is_Metric (Kind : Distance_Kind) return Boolean is
   begin
      case Kind is
         when Euclidean_Squared =>
            return False;
         when Manhattan | Chebyshev =>
            return True;
      end case;
   end Is_Metric;

   function Check_Nonnegativity
     (A, B : Point; Dim : Dim_Index; Kind : Distance_Kind) return Boolean
   is
   begin
      return Distance (A, B, Dim, Kind) >= 0.0;
   end Check_Nonnegativity;

   function Check_Symmetry
     (A, B : Point; Dim : Dim_Index; Kind : Distance_Kind) return Boolean
   is
      D_AB : constant Non_Negative :=
        Distance (A => A, B => B, Dim => Dim, Kind => Kind);
      D_BA : constant Non_Negative :=
        Distance (A => B, B => A, Dim => Dim, Kind => Kind);
   begin
      return Near (D_AB, D_BA);
   end Check_Symmetry;

   function Check_Identity_Of_Indiscernibles
     (A : Point; Dim : Dim_Index; Kind : Distance_Kind) return Boolean
   is
   begin
      return Near (Distance (A, A, Dim, Kind), 0.0);
   end Check_Identity_Of_Indiscernibles;

   function Check_Triangle
     (A, B, C : Point; Dim : Dim_Index; Kind : Distance_Kind) return Boolean
   is
      D_AC : constant Non_Negative := Distance (A, C, Dim, Kind);
      D_AB : constant Non_Negative := Distance (A, B, Dim, Kind);
      D_BC : constant Non_Negative := Distance (B, C, Dim, Kind);
   begin
      return D_AC <= D_AB + D_BC + Epsilon_Tol;
   end Check_Triangle;

   ---------------------------------------------------------------------------
   -- Point / cloud / labels / config
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

   function Make_Cloud (Dim : Dim_Index) return Cloud is
      C : Cloud;
   begin
      C.Dim   := Dim;
      C.Count := 0;
      return C;
   end Make_Cloud;

   procedure Add_Point (C : in out Cloud; P : Point) is
   begin
      if C.Dim = 0 then
         raise Invalid_Argument with "Add_Point: cloud Dim is 0";
      end if;
      if C.Count = Max_Points then
         raise Capacity_Exceeded with "Add_Point: Max_Points exceeded";
      end if;
      C.Count := C.Count + 1;
      C.Points (C.Count) := P;
   end Add_Point;

   function Cloud_Count (C : Cloud) return Point_Count is
   begin
      return C.Count;
   end Cloud_Count;

   function Cloud_Dim (C : Cloud) return Dim_Count is
   begin
      return C.Dim;
   end Cloud_Dim;

   function Make_Labels (Count : Point_Count) return Labels is
      L : Labels;
   begin
      L.Count := Count;
      for I in 1 .. Count loop
         L.Values (I) := 0;
      end loop;
      return L;
   end Make_Labels;

   procedure Set_Label
     (L : in out Labels; Index : Point_Index; Value : Label_Id)
   is
   begin
      if Index > L.Count then
         raise Invalid_Argument with "Set_Label: index out of range";
      end if;
      L.Values (Index) := Value;
   end Set_Label;

   function Get_Label (L : Labels; Index : Point_Index) return Label_Id is
   begin
      if Index > L.Count then
         raise Invalid_Argument with "Get_Label: index out of range";
      end if;
      return L.Values (Index);
   end Get_Label;

   function Default_Config
     (Metric : Distance_Kind := Euclidean_Squared;
      K      : K_Index := 1) return Config
   is
   begin
      return
        (Metric     => Metric,
         Default_K  => K,
         Max_Dim    => 8,
         Max_Points => 256);
   end Default_Config;

   ---------------------------------------------------------------------------
   -- Linear 1-NN / k-NN
   ---------------------------------------------------------------------------

   function Linear_NN
     (C     : Cloud;
      Query : Point;
      Kind  : Distance_Kind := Euclidean_Squared) return NN_Result
   is
      R    : NN_Result;
      D    : Non_Negative;
      Best : Non_Negative;
      Dim  : Dim_Index;
   begin
      if C.Count = 0 or else C.Dim = 0 then
         R.Found := False;
         return R;
      end if;
      Dim := Dim_Index (C.Dim);
      Best := Distance (Query, C.Points (1), Dim, Kind);
      R.Index := 1;
      R.Found := True;
      R.Distance := Best;
      R.Examined := Natural (C.Count);
      for I in 2 .. C.Count loop
         D := Distance (Query, C.Points (I), Dim, Kind);
         if D < Best then
            Best := D;
            R.Index := Natural (I);
            R.Distance := Best;
         end if;
      end loop;
      return R;
   end Linear_NN;

   procedure Insert_Neighbor
     (Items : in out Neighbor_List;
      Count : in out K_Count;
      K_Max : K_Index;
      Ix    : Natural;
      Dist  : Non_Negative)
   is
      Pos : Natural;
   begin
      if Count < K_Count (K_Max) then
         Count := Count + 1;
         Pos := Natural (Count);
      elsif Dist >= Items (K_Index (Count)).Distance then
         return;
      else
         Pos := Natural (Count);
      end if;
      --  Shift larger distances right; insert at Pos bubbling left.
      while Pos > 1
        and then Dist < Items (K_Index (Pos - 1)).Distance
      loop
         Items (K_Index (Pos)) := Items (K_Index (Pos - 1));
         Pos := Pos - 1;
      end loop;
      Items (K_Index (Pos)) := (Index => Ix, Distance => Dist);
   end Insert_Neighbor;

   function Linear_KNN
     (C     : Cloud;
      Query : Point;
      K     : K_Index;
      Kind  : Distance_Kind := Euclidean_Squared) return KNN_Result
   is
      R   : KNN_Result;
      Dim : Dim_Index;
      D   : Non_Negative;
   begin
      if C.Count = 0 or else C.Dim = 0 then
         return R;
      end if;
      Dim := Dim_Index (C.Dim);
      R.Examined := Natural (C.Count);
      for I in 1 .. C.Count loop
         D := Distance (Query, C.Points (I), Dim, Kind);
         Insert_Neighbor (R.Items, R.Count, K, Natural (I), D);
      end loop;
      return R;
   end Linear_KNN;

   ---------------------------------------------------------------------------
   -- Radius search
   ---------------------------------------------------------------------------

   function Radius_Search
     (C      : Cloud;
      Query  : Point;
      Radius : Non_Negative;
      Kind   : Distance_Kind := Euclidean_Squared) return Radius_Result
   is
      R   : Radius_Result;
      Dim : Dim_Index;
      D   : Non_Negative;
   begin
      if C.Count = 0 or else C.Dim = 0 then
         return R;
      end if;
      Dim := Dim_Index (C.Dim);
      R.Examined := Natural (C.Count);
      for I in 1 .. C.Count loop
         D := Distance (Query, C.Points (I), Dim, Kind);
         if D <= Radius then
            if R.Count = Max_Radius_Hits then
               raise Capacity_Exceeded
                 with "Radius_Search: Max_Radius_Hits exceeded";
            end if;
            R.Count := R.Count + 1;
            R.Indices (R.Count) := Natural (I);
         end if;
      end loop;
      return R;
   end Radius_Search;

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

   procedure Partition_Median
     (Points : Point_Array;
      Idx    : in out Index_Array;
      First  : Point_Index;
      Last   : Point_Index;
      Axis   : Dim_Index;
      Mid    : Point_Index)
   is
      Lo, Hi, Pivot_Pos : Point_Index;
      Pivot_Val         : Real;
      Tmp               : Point_Index;
   begin
      Lo := First;
      Hi := Last;
      while Lo < Hi loop
         Pivot_Pos := (Lo + Hi) / 2;
         Pivot_Val := Points (Idx (Pivot_Pos)).C (Axis);
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
      Depth : Natural) return Node_Index
   is
      N   : Node_Index;
      Axis : Dim_Index;
      Mid  : Point_Index;
   begin
      N := Alloc_Node (Tree);

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

      if Mid < Last then
         Tree.Nodes (N).Left :=
           Build_Rec (Tree, Idx, First, Mid, Depth + 1);
         Tree.Nodes (N).Right :=
           Build_Rec (Tree, Idx, Mid + 1, Last, Depth + 1);
      else
         Tree.Nodes (N).Is_Leaf := True;
         Tree.Nodes (N).Point_Index := Natural (Idx (Mid));
         Tree.Nodes (N).Left := 0;
         Tree.Nodes (N).Right := 0;
      end if;
      return N;
   end Build_Rec;

   function Build_Tree (C : Cloud) return KD_Tree is
      Tree : KD_Tree;
      Idx  : Index_Array;
   begin
      if C.Count > 0 and then C.Dim = 0 then
         raise Invalid_Argument with "Build_Tree: Dim is 0 with points";
      end if;

      Tree.Count := C.Count;
      Tree.Dim := C.Dim;
      Tree.Node_Count := 0;
      Tree.Root := 0;

      if C.Count = 0 then
         return Tree;
      end if;

      for I in 1 .. C.Count loop
         Tree.Points (I) := C.Points (I);
         Idx (I) := I;
      end loop;

      Tree.Root := Build_Rec (Tree, Idx, 1, C.Count, 0);
      return Tree;
   end Build_Tree;

   ---------------------------------------------------------------------------
   -- Exact k-d tree NN (splitting-plane prune)
   ---------------------------------------------------------------------------

   procedure Search_Rec
     (Tree   : KD_Tree;
      Node   : Node_Index;
      Query  : Point;
      Best_I : in out Natural;
      Best_D : in out Non_Negative;
      Found  : in out Boolean;
      Exam   : in out Natural)
   is
      Axis     : Dim_Index;
      Diff     : Real;
      Diff2    : Non_Negative;
      Near_N   : Node_Index;
      Far_N    : Node_Index;
      PI       : Natural;
      D2       : Non_Negative;
      Dim      : Dim_Index;
   begin
      if Node = 0 then
         return;
      end if;

      if Tree.Nodes (Node).Is_Leaf then
         PI := Tree.Nodes (Node).Point_Index;
         if PI = 0 or else PI > Natural (Tree.Count) then
            return;
         end if;
         Dim := Dim_Index (Tree.Dim);
         Exam := Exam + 1;
         D2 := Distance2 (Query, Tree.Points (Point_Index (PI)), Dim);
         if not Found or else D2 < Best_D then
            Found := True;
            Best_D := D2;
            Best_I := PI;
         end if;
         return;
      end if;

      Axis := Tree.Nodes (Node).Split_Dim;
      Diff := Query.C (Axis) - Tree.Nodes (Node).Split_Val;
      if Diff <= 0.0 then
         Near_N := Tree.Nodes (Node).Left;
         Far_N  := Tree.Nodes (Node).Right;
      else
         Near_N := Tree.Nodes (Node).Right;
         Far_N  := Tree.Nodes (Node).Left;
      end if;

      Search_Rec (Tree, Near_N, Query, Best_I, Best_D, Found, Exam);

      Diff2 := Non_Negative (Diff * Diff);
      if not Found or else Diff2 < Best_D then
         Search_Rec (Tree, Far_N, Query, Best_I, Best_D, Found, Exam);
      end if;
   end Search_Rec;

   function Tree_NN (Tree : KD_Tree; Query : Point) return NN_Result is
      R      : NN_Result;
      Best_I : Natural := 0;
      Best_D : Non_Negative := 0.0;
      Found  : Boolean := False;
      Exam   : Natural := 0;
   begin
      if Tree_Empty (Tree) or else Tree.Dim = 0 then
         return R;
      end if;
      Search_Rec (Tree, Tree.Root, Query, Best_I, Best_D, Found, Exam);
      R.Found := Found;
      R.Index := Best_I;
      R.Distance := Best_D;
      R.Examined := Exam;
      return R;
   end Tree_NN;

   ---------------------------------------------------------------------------
   -- Majority vote / Classify_KNN
   ---------------------------------------------------------------------------

   function Majority_Vote
     (L           : Labels;
      Neighbor_Ix : Index_List;
      Neighbor_N  : Natural) return Classify_Result
   is
      Votes : array (Label_Id) of Natural := [others => 0];
      Lab   : Label_Id;
      Best  : Label_Id := 0;
      Best_V : Natural := 0;
      R     : Classify_Result;
      Ix    : Natural;
   begin
      if Neighbor_N = 0 then
         return R;
      end if;
      for I in 1 .. Neighbor_N loop
         Ix := Neighbor_Ix (I);
         if Ix = 0 or else Ix > Natural (L.Count) then
            raise Invalid_Argument with "Majority_Vote: bad neighbor index";
         end if;
         Lab := L.Values (Point_Index (Ix));
         Votes (Lab) := Votes (Lab) + 1;
      end loop;
      --  Prefer positive labels over 0 on ties of equal count by scanning
      --  ascending Label_Id; first max wins (smallest id among tied).
      for Lab in Label_Id loop
         if Votes (Lab) > Best_V then
            Best_V := Votes (Lab);
            Best := Lab;
         end if;
      end loop;
      R.Found := True;
      R.Predicted := Best;
      R.Vote_Count := Best_V;
      R.Neighbor_K :=
        (if Neighbor_N <= Natural (Max_K) then K_Count (Neighbor_N)
         else Max_K);
      return R;
   end Majority_Vote;

   function Classify_KNN
     (C     : Cloud;
      L     : Labels;
      Query : Point;
      K     : K_Index;
      Kind  : Distance_Kind := Euclidean_Squared) return Classify_Result
   is
      Kn : KNN_Result;
      Ix : Index_List := [others => 0];
      N  : Natural;
   begin
      if C.Count = 0 then
         return (Found => False, Predicted => 0, Vote_Count => 0,
                 Neighbor_K => 0);
      end if;
      if L.Count /= C.Count then
         raise Invalid_Argument
           with "Classify_KNN: Labels.Count must equal Cloud.Count";
      end if;
      Kn := Linear_KNN (C, Query, K, Kind);
      N := Natural (Kn.Count);
      for I in 1 .. Kn.Count loop
         Ix (Natural (I)) := Kn.Items (I).Index;
      end loop;
      return Majority_Vote (L, Ix, N);
   end Classify_KNN;

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Classify_Method (K : Method_Kind) return Method_Info is
   begin
      case K is
         when Linear =>
            return
              (Kind => Linear, Exact => True, Implemented => True,
               Approximate => False);
         when Exact_KD_Tree =>
            return
              (Kind => Exact_KD_Tree, Exact => True, Implemented => True,
               Approximate => False);
         when Best_Bin_First =>
            return
              (Kind => Best_Bin_First, Exact => False, Implemented => False,
               Approximate => True);
         when LSH =>
            return
              (Kind => LSH, Exact => False, Implemented => False,
               Approximate => True);
      end case;
   end Classify_Method;

   function Method_Name (K : Method_Kind) return String is
   begin
      case K is
         when Linear =>
            return "Linear";
         when Exact_KD_Tree =>
            return "KD_Tree";
         when Best_Bin_First =>
            return "Best_Bin_First";
         when LSH =>
            return "LSH";
      end case;
   end Method_Name;

   function Method_Count return Positive is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
        - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

end Nearest_Neighbor_Search;
