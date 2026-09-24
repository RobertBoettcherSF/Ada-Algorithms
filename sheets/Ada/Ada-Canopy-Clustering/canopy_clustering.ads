--  Canopy_Clustering — Ada 2023 educational package for Wikipedia
--  "Canopy clustering algorithm" (Andrew McCallum, Kamal Nigam, Lyle Ungar,
--  KDD 2000). Unsupervised pre-clustering with loose T1 and tight T2
--  thresholds (T1 > T2 > 0). Cheap canopies may overlap; often used as
--  preprocessing for k-means or hierarchical clustering. Euclidean L2
--  distance (cheap and accurate metrics coincide here). Remaining points are
--  scanned in stable ascending index order for determinism.

pragma Ada_2022;

package Canopy_Clustering
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable L2 / threshold arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points   : constant Positive := 256;
   Max_Dims     : constant Positive := 16;
   Max_Canopies : constant Positive := 256;

   subtype Point_Count   is Natural  range 0 .. Max_Points;
   subtype Point_Index   is Positive range 1 .. Max_Points;
   subtype Dim_Count     is Natural  range 0 .. Max_Dims;
   subtype Dim_Index     is Positive range 1 .. Max_Dims;
   subtype Canopy_Count  is Natural  range 0 .. Max_Canopies;
   subtype Canopy_Index  is Positive range 1 .. Max_Canopies;

   --  Coordinate vector of one observation / center.
   type Point is array (Dim_Index range <>) of Real;

   --  Data(P, D) = coordinate D of point P.  Rows = observations.
   type Dataset is array
     (Point_Index range <>, Dim_Index range <>) of Real;

   --  Canopy center coordinates (row = canopy id, column = dimension).
   type Canopy_Centers is array
     (Canopy_Index range <>, Dim_Index range <>) of Real;

   --  Original dataset row index of each canopy center.
   type Center_Point_Ids is array (Canopy_Index range <>) of Point_Index;

   --  Memb(P, C) = True iff point P belongs to canopy C.
   type Membership is array
     (Point_Index range <>, Canopy_Index range <>) of Boolean;

   --  Optional exclusive hard label per point (canopy id, or 0 = none).
   type Hard_Labels is array (Point_Index range <>) of Natural;

   --  Per-point list of canopy ids (dense pack in 1 .. Count).
   type Canopy_Id_List is array (Canopy_Index range <>) of Canopy_Index;

   type Canopy_Membership_List is record
      Count : Canopy_Count := 0;
      Ids   : Canopy_Id_List (1 .. Max_Canopies) := [others => 1];
   end record;

   type Membership_Lists is array
     (Point_Index range <>) of Canopy_Membership_List;

   --  Run controls: loose T1 and tight T2 with T1 > T2 > 0.
   type Parameters is record
      T1 : Positive_Real := 1.0;
      T2 : Positive_Real := 0.5;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  Full canopy outcome (discriminants fix storage extents).
   type Result
     (N : Point_Count; C : Canopy_Count; D : Dim_Count)
   is record
      Centers     : Canopy_Centers (1 .. C, 1 .. D);
      Center_Ids  : Center_Point_Ids (1 .. C);
      Memb        : Membership (1 .. N, 1 .. C);
      Lists       : Membership_Lists (1 .. N);
      Num_Canopies : Canopy_Count := 0;  -- equals C when C matches run
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Make_Parameters (T1, T2 : Real) return Parameters
     with Global => null;
   --  Raises Invalid_Argument unless T1 > T2 > 0.

   ---------------------------------------------------------------------------
   -- Distance (Euclidean L2 over all dimensions)
   ---------------------------------------------------------------------------

   function Distance
     (Data : Dataset;
      P, Q : Point_Index) return Non_Negative
     with Pre => P in Data'Range (1) and then Q in Data'Range (1),
          Global => null;
   --  Euclidean L2 between rows P and Q.
   --  Raises Invalid_Argument if P or Q outside Data'Range (1).

   function Distance_To_Center
     (Data    : Dataset;
      P       : Point_Index;
      Centers : Canopy_Centers;
      C       : Canopy_Index) return Non_Negative
     with Pre => P in Data'Range (1)
       and then C in Centers'Range (1)
       and then Data'First (2) = Centers'First (2)
       and then Data'Last (2) = Centers'Last (2),
          Global => null;
   --  Euclidean L2 between data point P and canopy center row C.

   ---------------------------------------------------------------------------
   -- Canopy clustering (McCallum, Nigam, Ungar / Wikipedia)
   ---------------------------------------------------------------------------

   function Run_Canopy
     (Data   : Dataset;
      Params : Parameters) return Result
     with Pre => Data'Length (1) >= 0 and then Data'Length (2) >= 1,
          Global => null;
   --  Canopy pre-clustering with thresholds T1 (loose) and T2 (tight).
   --  Next center = lowest remaining pool index (stable ascending order).
   --  Points with dist < T1 join the canopy (multi-membership allowed).
   --  Points with dist < T2 are removed from the pool (cannot center later).
   --  Empty dataset → Result with N=0, C=0.
   --  Raises Invalid_Argument if T1 ≤ T2, T2 ≤ 0, or dims = 0.
   --  Raises Capacity_Exceeded if N > Max_Points, D > Max_Dims, or the
   --  number of canopies would exceed Max_Canopies.

   function Canopy_Count_Of (R : Result) return Canopy_Count
     with Global => null;
   --  Number of canopies produced (R.Num_Canopies / R.C).

   function Point_In_Canopy
     (R : Result;
      P : Point_Index;
      C : Canopy_Index) return Boolean
     with Pre => P in 1 .. R.N and then C in 1 .. R.C,
          Global => null;
   --  True iff Memb(P, C).  Raises Invalid_Argument if P/C out of range.

   function Canopies_Of
     (R : Result;
      P : Point_Index) return Canopy_Membership_List
     with Pre => P in 1 .. R.N,
          Global => null;
   --  Dense list of canopy ids containing P (from R.Lists).

   ---------------------------------------------------------------------------
   -- Optional exclusive hard labels
   ---------------------------------------------------------------------------

   function Hard_Labels_Nearest_Center (R : Result; Data : Dataset)
     return Hard_Labels
     with Pre => Data'Length (1) = R.N
       and then Data'Length (2) = R.D
       and then Data'First (1) = 1
       and then Data'First (2) = 1,
          Global => null;
   --  For each point, among canopies covering it, choose the canopy whose
   --  center is nearest (Euclidean L2).  Ties → lowest canopy id.
   --  Uncovered points (should not occur after a normal run) get label 0.

   function Hard_Labels_First_Canopy (R : Result) return Hard_Labels
     with Global => null;
   --  Exclusive label = first (lowest id) canopy covering each point,
   --  or 0 if none.

end Canopy_Clustering;
