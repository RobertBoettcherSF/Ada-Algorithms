generic
   Dimensions : Positive;
package Cluster_Analysis is
   pragma Preelaborate;

   type Coordinate is new Long_Float;
   type Dimension_Index is new Positive range 1 .. Dimensions;
   type Point is array (Dimension_Index) of Coordinate;
   type Point_Array is array (Positive range <>) of Point;

   type Cluster_ID is new Positive;
   type Cluster_Assignment is array (Positive range <>) of Cluster_ID;

   -- Computes the straight-line distance between two points.
   function Euclidean_Distance (P1, P2 : Point) return Coordinate
     with Post => Euclidean_Distance'Result >= 0.0;

   -- Computes the grid-like (L1) distance between two points.
   function Manhattan_Distance (P1, P2 : Point) return Coordinate
     with Post => Manhattan_Distance'Result >= 0.0;

   -- Computes the sum of distances from each point to its assigned centroid.
   -- Used for validation and measuring cluster compactness (inertia).
   function Calculate_Inertia
     (Data          : Point_Array;
      Assignments   : Cluster_Assignment;
      Centroids     : Point_Array;
      Use_Manhattan : Boolean := False) return Coordinate
   with
     Pre => Data'Length = Assignments'Length
            and then Centroids'Length > 0;

   -- Primary clustering variant: K-Means (Lloyd's Algorithm) with Euclidean distance.
   -- Partitions the Data into K distinct clusters minimizing squared Euclidean distances.
   procedure K_Means
     (Data           : in  Point_Array;
      K              : in  Positive;
      Max_Iterations : in  Positive;
      Assignments    : out Cluster_Assignment;
      Centroids      : out Point_Array)
   with
     Pre => Data'Length > 0
            and then K <= Data'Length
            and then Assignments'Length = Data'Length
            and then Centroids'Length = K;

   -- Secondary clustering variant: K-Medians with Manhattan distance.
   -- Partitions the Data into K distinct clusters minimizing absolute differences.
   procedure K_Medians
     (Data           : in  Point_Array;
      K              : in  Positive;
      Max_Iterations : in  Positive;
      Assignments    : out Cluster_Assignment;
      Centroids      : out Point_Array)
   with
     Pre => Data'Length > 0
            and then K <= Data'Length
            and then Assignments'Length = Data'Length
            and then Centroids'Length = K;

end Cluster_Analysis;
