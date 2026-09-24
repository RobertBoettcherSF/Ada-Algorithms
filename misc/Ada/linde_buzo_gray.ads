--  Linde_Buzo_Gray — Ada 2023 educational package for Wikipedia
--  "Linde–Buzo–Gray algorithm" (Yoseph Linde, Andrés Buzo, Robert M. Gray,
--  IEEE Transactions on Communications, 1980).  Iterative vector quantization
--  that combines Lloyd iteration with codebook splitting so larger codebooks
--  grow from smaller ones.  Euclidean L2 / squared-error distortion.
--  Empty cells: keep previous codevector (documented).
--  Sibling: Ada-Lloyds-Algorithm (RobertBoettcherSF series).

pragma Ada_2022;

package Linde_Buzo_Gray
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable centroid / distortion arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points    : constant Positive := 256;
   Max_Dims      : constant Positive := 16;
   Max_Codewords : constant Positive := 64;

   subtype Point_Count    is Natural  range 0 .. Max_Points;
   subtype Point_Index    is Positive range 1 .. Max_Points;
   subtype Dim_Count      is Natural  range 0 .. Max_Dims;
   subtype Dim_Index      is Positive range 1 .. Max_Dims;
   subtype Codeword_Count is Natural  range 0 .. Max_Codewords;
   subtype Codeword_Index is Positive range 1 .. Max_Codewords;

   --  Coordinate vector of one observation / codevector.
   type Point is array (Dim_Index range <>) of Real;

   --  Training set / dataset: Data(P, D) = coordinate D of point P.
   type Dataset is array
     (Point_Index range <>, Dim_Index range <>) of Real;

   subtype Training_Set is Dataset;

   --  Codebook(K, D) = coordinate D of codeword K.
   type Codebook is array
     (Codeword_Index range <>, Dim_Index range <>) of Real;

   --  Cluster / codeword label per training point (1 .. M); 0 = unset.
   type Labels is array (Point_Index range <>) of Natural;

   --  Per-codeword emptiness after a centroid update.
   type Empty_Flags is array (Codeword_Index range <>) of Boolean;

   --  Design / Lloyd controls.
   --  Target_Size = desired final codebook size M (typically a power of 2).
   --  Split_Epsilon = scalar ε: each split inserts y and y+ε·e₁
   --  (first coordinate only; ε as a small perturbation vector).
   --  Stop_Epsilon = relative distortion change threshold for Lloyd.
   --  Max_Lloyd_Iters = cap on Lloyd iterations per refinement.
   type Parameters is record
      Target_Size     : Codeword_Count := 4;
      Split_Epsilon   : Positive_Real := 1.0E-2;
      Stop_Epsilon    : Non_Negative := 1.0E-6;
      Max_Lloyd_Iters : Positive := 100;
   end record;

   Default_Parameters : constant Parameters := (others => <>);

   --  Full LBG / Lloyd outcome (discriminants fix storage extents).
   type LBG_Result
     (N : Point_Count; M : Codeword_Count; D : Dim_Count)
   is record
      Book           : Codebook (1 .. M, 1 .. D);
      Lab            : Labels (1 .. N);
      Empty          : Empty_Flags (1 .. M);
      Distortion     : Non_Negative := 0.0;  -- total SSE
      Avg_Distortion : Non_Negative := 0.0;  -- SSE / N
      Iters          : Natural := 0;         -- Lloyd iters (last stage or total)
      Num_Codewords  : Codeword_Count := 0; -- active codewords (= M on success)
      Converged      : Boolean := False;
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

   ---------------------------------------------------------------------------
   -- Geometry
   ---------------------------------------------------------------------------

   function Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Distance'Result >= 0.0;
   --  Euclidean L2 ||A − B||.

   function Squared_Distance (A, B : Point) return Non_Negative
     with Pre => A'First = B'First
       and then A'Last = B'Last
       and then A'Length >= 1
       and then A'Length <= Max_Dims,
          Global => null,
          Post => Squared_Distance'Result >= 0.0;
   --  ||A − B||² (preferred for nearest-codeword comparisons).

   function Extract_Point
     (Data : Dataset; P : Point_Index) return Point
     with Pre => P in Data'Range (1)
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Point'Result'Length = Data'Length (2);

   function Extract_Codeword
     (Book : Codebook; K : Codeword_Index) return Point
     with Pre => K in Book'Range (1)
       and then Book'Length (2) >= 1
       and then Book'Length (2) <= Max_Dims,
          Global => null,
          Post => Extract_Codeword'Result'Length = Book'Length (2);

   ---------------------------------------------------------------------------
   -- Assignment / centroids / quality
   ---------------------------------------------------------------------------

   function Nearest_Codeword
     (Query : Point; Book : Codebook) return Codeword_Index
     with Pre => Query'Length = Book'Length (2)
       and then Query'Length >= 1
       and then Query'Length <= Max_Dims
       and then Book'Length (1) >= 1
       and then Book'Length (1) <= Max_Codewords,
          Global => null,
          Post => Nearest_Codeword'Result in Book'Range (1);
   --  Argmin_k ||Query − y_k||² (ties → lowest codeword index).

   function Assign
     (Data : Dataset; Book : Codebook) return Labels
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Book'Length (1) >= 1
       and then Book'Length (1) <= Max_Codewords
       and then Book'Length (2) = Data'Length (2),
          Global => null,
          Post => Assign'Result'Length = Data'Length (1);
   --  Partition training by nearest codevector.

   procedure Update_Centroids
     (Data  : Dataset;
      Lab   : Labels;
      Book  : in out Codebook;
      Empty : out Empty_Flags)
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then Lab'First = Data'First (1)
       and then Book'Length (1) >= 1
       and then Book'Length (2) = Data'Length (2)
       and then Empty'Length = Book'Length (1)
       and then Empty'First = Book'First (1),
          Global => null;
   --  Codevector ← centroid of its cell.  Empty cell: keep previous
   --  codevector and set Empty(k) := True.

   function Centroid
     (Data : Dataset; Lab : Labels; K : Codeword_Index) return Point
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then K >= 1
       and then K <= Max_Codewords,
          Global => null,
          Post => Centroid'Result'Length = Data'Length (2);
   --  Mean of points labeled K.  Raises Invalid_Argument if the cell is empty.

   function Mean_Point (Data : Dataset) return Point
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims,
          Global => null,
          Post => Mean_Point'Result'Length = Data'Length (2);
   --  Global centroid of the training set (initial 1-word codebook).

   function Distortion
     (Data : Dataset; Book : Codebook; Lab : Labels) return Non_Negative
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then Book'Length (1) >= 1
       and then Book'Length (2) = Data'Length (2),
          Global => null,
          Post => Distortion'Result >= 0.0;
   --  Total SSE = Σ_i ||x_i − y_{lab(i)}||².

   function Average_Distortion
     (Data : Dataset; Book : Codebook; Lab : Labels) return Non_Negative
     with Pre => Data'Length (1) >= 1
       and then Lab'Length = Data'Length (1)
       and then Book'Length (1) >= 1
       and then Book'Length (2) = Data'Length (2),
          Global => null,
          Post => Average_Distortion'Result >= 0.0;
   --  SSE / N.

   ---------------------------------------------------------------------------
   -- Split / Lloyd / full LBG design
   ---------------------------------------------------------------------------

   function Split_Codebook
     (Book : Codebook; Epsilon : Positive_Real) return Codebook
     with Pre => Book'Length (1) >= 1
       and then Book'Length (1) <= Max_Codewords / 2
       and then Book'Length (2) >= 1
       and then Book'Length (2) <= Max_Dims
       and then Epsilon > 0.0,
          Global => null,
          Post => Split_Codebook'Result'Length (1) = 2 * Book'Length (1)
            and then Split_Codebook'Result'Length (2) = Book'Length (2);
   --  For each y: insert y and (y₁+ε, y₂, …, y_d).  Doubles size.
   --  Raises Capacity_Exceeded if 2·|Book| > Max_Codewords.

   function Run_Lloyd
     (Data   : Dataset;
      Init   : Codebook;
      Params : Parameters := Default_Parameters) return LBG_Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Init'Length (1) >= 1
       and then Init'Length (1) <= Max_Codewords
       and then Init'Length (2) = Data'Length (2)
       and then Params.Stop_Epsilon >= 0.0,
          Global => null;
   --  Fixed-size Lloyd refinement (Wikipedia lloyd): assign → centroid
   --  until |D_prev − D| / max(D_prev, ε_floor) ≤ Stop_Epsilon or
   --  Max_Lloyd_Iters.  Empty cells keep previous codevector.

   function Run_LBG
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return LBG_Result
     with Pre => Data'Length (1) >= 1
       and then Data'Length (1) <= Max_Points
       and then Data'Length (2) >= 1
       and then Data'Length (2) <= Max_Dims
       and then Params.Target_Size >= 1
       and then Params.Target_Size <= Max_Codewords
       and then Params.Split_Epsilon > 0.0
       and then Params.Stop_Epsilon >= 0.0,
          Global => null;
   --  Full design: c0 = mean(training); while |book| < M split + Lloyd.
   --  Target_Size need not be a power of 2: final split is truncated to M.
   --  Raises Invalid_Argument / Capacity_Exceeded on bad inputs.

   function Design_Codebook
     (Data   : Dataset;
      Params : Parameters := Default_Parameters) return LBG_Result
     renames Run_LBG;
   --  Alias for Run_LBG.

end Linde_Buzo_Gray;
