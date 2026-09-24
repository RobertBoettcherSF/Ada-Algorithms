--  Nearest_Neighbor_Search — Ada 2023 educational survey package for
--  Wikipedia "Nearest neighbor search": distances (Euclidean², Manhattan,
--  Chebyshev), exact linear 1-NN / k-NN, brute-force radius search, compact
--  k-d tree exact NN (recursive splitting-plane prune), and a tiny k-NN
--  majority-vote classifier. Taxonomy flags cover Linear / KD_Tree /
--  Best_Bin_First / LSH (BBF and LSH are metadata only — see sibling
--  Ada-Best-Bin-First for approximate priority-bin search).
--  Educational limits: d ≤ 8, n ≤ 256.

pragma Ada_2022;

package Nearest_Neighbor_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / domain
   ---------------------------------------------------------------------------

   Max_Dim         : constant Positive := 8;
   Max_Points      : constant Positive := 256;
   Max_Nodes       : constant Positive := 512;
   Max_K           : constant Positive := 16;
   Max_Radius_Hits : constant Positive := 256;
   Max_Labels      : constant Positive := 16;

   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Dim_Count    is Natural  range 0 .. Max_Dim;
   subtype Dim_Index    is Positive range 1 .. Max_Dim;
   subtype Point_Count  is Natural  range 0 .. Max_Points;
   subtype Point_Index  is Positive range 1 .. Max_Points;
   subtype Node_Index   is Natural  range 0 .. Max_Nodes;
   --  0 denotes null / empty.
   subtype K_Count      is Natural  range 0 .. Max_K;
   subtype K_Index      is Positive range 1 .. Max_K;
   subtype Label_Id     is Natural  range 0 .. Max_Labels;
   --  0 = unlabeled / unknown.

   type Coord_Array is array (Dim_Index) of Real;

   type Point is record
      C : Coord_Array := [others => 0.0];
   end record;

   type Point_Array is array (Point_Index) of Point;

   --  Named Cloud per survey API (point set + dim + count).
   type Cloud is record
      Points : Point_Array := [others => (C => [others => 0.0])];
      Count  : Point_Count := 0;
      Dim    : Dim_Count   := 0;
   end record;

   type Label_Array is array (Point_Index) of Label_Id;

   type Labels is record
      Values : Label_Array := [others => 0];
      Count  : Point_Count := 0;
   end record;

   type Distance_Kind is (Euclidean_Squared, Manhattan, Chebyshev);

   type Method_Kind is (Linear, Exact_KD_Tree, Best_Bin_First, LSH);

   type Method_Info is record
      Kind          : Method_Kind;
      Exact         : Boolean;
      Implemented   : Boolean;
      Approximate   : Boolean;
   end record;

   type Config is record
      Metric     : Distance_Kind := Euclidean_Squared;
      Default_K  : K_Index       := 1;
      Max_Dim    : Dim_Index     := 8;
      Max_Points : Positive      := 256;
   end record;

   type NN_Result is record
      Found     : Boolean      := False;
      Index     : Natural      := 0;
      Distance  : Non_Negative := 0.0;
      Examined  : Natural      := 0;
   end record;

   type Neighbor is record
      Index    : Natural      := 0;
      Distance : Non_Negative := 0.0;
   end record;

   type Neighbor_List is array (K_Index) of Neighbor;

   type KNN_Result is record
      Count    : K_Count       := 0;
      Items    : Neighbor_List :=
        [others => (Index => 0, Distance => 0.0)];
      Examined : Natural       := 0;
   end record;

   type Index_List is array (1 .. Max_Radius_Hits) of Natural;

   type Radius_Result is record
      Count    : Natural    := 0;
      Indices  : Index_List := [others => 0];
      Examined : Natural    := 0;
   end record;

   type Classify_Result is record
      Found        : Boolean  := False;
      Predicted    : Label_Id := 0;
      Vote_Count   : Natural  := 0;
      Neighbor_K   : K_Count  := 0;
   end record;

   type KD_Tree is private;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Empty_Cloud       : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point
     (A, B : Point; Dim : Dim_Index; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Distances
   ---------------------------------------------------------------------------

   function Distance2 (A, B : Point; Dim : Dim_Index) return Non_Negative
     with Global => null;
   --  Squared Euclidean  Σ (a_i − b_i)²  (preferred for comparisons).

   function Manhattan (A, B : Point; Dim : Dim_Index) return Non_Negative
     with Global => null;
   --  L1: Σ |a_i − b_i|.

   function Chebyshev (A, B : Point; Dim : Dim_Index) return Non_Negative
     with Global => null;
   --  L∞: max_i |a_i − b_i|.

   function Distance
     (A, B : Point; Dim : Dim_Index; Kind : Distance_Kind) return Non_Negative
     with Global => null;
   --  Dispatch on Kind.

   --  Metric property checks (pedagogy). Euclidean_Squared is NOT a metric
   --  (triangle can fail); Manhattan and Chebyshev are.

   function Is_Metric (Kind : Distance_Kind) return Boolean
     with Global => null;

   function Check_Nonnegativity
     (A, B : Point; Dim : Dim_Index; Kind : Distance_Kind) return Boolean
     with Global => null;
   --  d(A,B) ≥ 0 (always True for our implementations).

   function Check_Symmetry
     (A, B : Point; Dim : Dim_Index; Kind : Distance_Kind) return Boolean
     with Global => null;
   --  d(A,B) = d(B,A).

   function Check_Identity_Of_Indiscernibles
     (A : Point; Dim : Dim_Index; Kind : Distance_Kind) return Boolean
     with Global => null;
   --  d(A,A) = 0.

   function Check_Triangle
     (A, B, C : Point; Dim : Dim_Index; Kind : Distance_Kind) return Boolean
     with Global => null;
   --  d(A,C) ≤ d(A,B) + d(B,C)  (may fail for Euclidean_Squared).

   ---------------------------------------------------------------------------
   -- Point / cloud / labels / config
   ---------------------------------------------------------------------------

   function Make_Point
     (Dim : Dim_Index; Coords : Coord_Array) return Point
     with Global => null;

   function Make_Cloud (Dim : Dim_Index) return Cloud
     with Post => Make_Cloud'Result.Dim = Dim
                  and then Make_Cloud'Result.Count = 0,
          Global => null;

   procedure Add_Point (C : in out Cloud; P : Point)
     with Pre => C.Dim >= 1, Global => null;
   --  Raises Capacity_Exceeded when Count = Max_Points.

   function Cloud_Count (C : Cloud) return Point_Count
     with Global => null;

   function Cloud_Dim (C : Cloud) return Dim_Count
     with Global => null;

   function Make_Labels (Count : Point_Count) return Labels
     with Post => Make_Labels'Result.Count = Count, Global => null;

   procedure Set_Label
     (L : in out Labels; Index : Point_Index; Value : Label_Id)
     with Pre => Index <= L.Count, Global => null;

   function Get_Label (L : Labels; Index : Point_Index) return Label_Id
     with Pre => Index <= L.Count, Global => null;

   function Default_Config
     (Metric : Distance_Kind := Euclidean_Squared;
      K      : K_Index := 1) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Exact linear scan: 1-NN and k-NN
   ---------------------------------------------------------------------------

   function Linear_NN
     (C     : Cloud;
      Query : Point;
      Kind  : Distance_Kind := Euclidean_Squared) return NN_Result
     with Global => null;
   --  Brute-force 1-NN. Found=False when Count = 0.

   function Linear_KNN
     (C     : Cloud;
      Query : Point;
      K     : K_Index;
      Kind  : Distance_Kind := Euclidean_Squared) return KNN_Result
     with Global => null;
   --  Brute-force k-NN with sorted partial list (ascending distance).

   ---------------------------------------------------------------------------
   -- Brute-force radius search
   ---------------------------------------------------------------------------

   function Radius_Search
     (C      : Cloud;
      Query  : Point;
      Radius : Non_Negative;
      Kind   : Distance_Kind := Euclidean_Squared) return Radius_Result
     with Global => null;
   --  All indices with Distance ≤ Radius (order = scan order).
   --  Raises Capacity_Exceeded if more than Max_Radius_Hits hits.

   ---------------------------------------------------------------------------
   -- Compact k-d tree (exact NN via splitting-plane prune)
   ---------------------------------------------------------------------------

   function Build_Tree (C : Cloud) return KD_Tree
     with Global => null;
   --  Median-split k-d tree, axes cycle 1 .. Dim. Empty cloud => empty tree.

   function Tree_Empty (Tree : KD_Tree) return Boolean
     with Global => null;

   function Tree_Count (Tree : KD_Tree) return Point_Count
     with Global => null;

   function Tree_Dim (Tree : KD_Tree) return Dim_Count
     with Global => null;

   function Tree_Root (Tree : KD_Tree) return Node_Index
     with Global => null;

   function Node_Is_Leaf (Tree : KD_Tree; N : Node_Index) return Boolean
     with Pre => N <= Max_Nodes, Global => null;

   function Node_Point_Index (Tree : KD_Tree; N : Node_Index) return Natural
     with Pre => N <= Max_Nodes, Global => null;

   function Tree_NN (Tree : KD_Tree; Query : Point) return NN_Result
     with Global => null;
   --  Exact 1-NN using recursive near-child first + pruning when
   --  (q[axis] − split)² ≥ best Distance2. Uses Euclidean² only
   --  (standard geometric prune). Not Best-Bin-First — see sibling
   --  Ada-Best-Bin-First for approximate priority-bin search.

   ---------------------------------------------------------------------------
   -- k-NN majority-vote classification (tiny educational sketch)
   ---------------------------------------------------------------------------

   function Majority_Vote
     (L           : Labels;
      Neighbor_Ix : Index_List;
      Neighbor_N  : Natural) return Classify_Result
     with Pre => Neighbor_N <= Max_Radius_Hits, Global => null;
   --  Mode of labels at Neighbor_Ix (1 .. Neighbor_N). Ties → smallest
   --  Label_Id among tied winners.

   function Classify_KNN
     (C     : Cloud;
      L     : Labels;
      Query : Point;
      K     : K_Index;
      Kind  : Distance_Kind := Euclidean_Squared) return Classify_Result
     with Global => null;
   --  Linear_KNN then Majority_Vote. Requires L.Count = C.Count.

   ---------------------------------------------------------------------------
   -- Method taxonomy (metadata; BBF/LSH not implemented here)
   ---------------------------------------------------------------------------

   function Classify_Method (K : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (K : Method_Kind) return String
     with Global => null;

   function Method_Count return Positive
     with Global => null;
   --  Number of Method_Kind values (= 4).

private

   type KD_Node is record
      Left        : Node_Index  := 0;
      Right       : Node_Index  := 0;
      Split_Dim   : Dim_Index   := 1;
      Split_Val   : Real        := 0.0;
      Point_Index : Natural     := 0;
      Is_Leaf     : Boolean     := False;
   end record;

   type Node_Array is array (1 .. Max_Nodes) of KD_Node;

   type Index_Array is array (Point_Index) of Point_Index;

   type KD_Tree is record
      Nodes      : Node_Array;
      Node_Count : Node_Index  := 0;
      Root       : Node_Index  := 0;
      Points     : Point_Array := [others => (C => [others => 0.0])];
      Count      : Point_Count := 0;
      Dim        : Dim_Count   := 0;
   end record;

end Nearest_Neighbor_Search;
