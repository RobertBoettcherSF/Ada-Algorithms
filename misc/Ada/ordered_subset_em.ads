--  Ordered_Subset_EM — Ada 2023 educational package for Wikipedia
--  "Ordered subset expectation maximization" (OSEM): Hudson & Larkin 1994
--  accelerate MLEM image reconstruction by updating on ordered subsets of
--  projection data. Emission tomography / Poisson MLEM (Shepp–Vardi), with
--  classic Hudson subset-normalized form. Dense educational system matrix.
--  Related sibling survey (upcoming): Expectation maximization.

pragma Ada_2022;

package Ordered_Subset_EM
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable reconstruction / NLL arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Pixels  : constant Positive := 64;
   Max_Bins    : constant Positive := 128;
   Max_Subsets : constant Positive := 32;

   subtype Pixel_Count  is Natural range 0 .. Max_Pixels;
   subtype Bin_Count    is Natural range 0 .. Max_Bins;
   subtype Subset_Count is Natural range 0 .. Max_Subsets;

   subtype Pixel_Index  is Positive range 1 .. Max_Pixels;
   subtype Bin_Index    is Positive range 1 .. Max_Bins;
   subtype Subset_Index is Positive range 1 .. Max_Subsets;

   --  Image x_j (j = 1 .. J), projection y_i (i = 1 .. I).
   type Image      is array (Pixel_Index range <>) of Real;
   type Projection is array (Bin_Index range <>) of Real;

   --  Dense system matrix A(i, j) = a_{ij} ≥ 0 (bins × pixels).
   type System_Matrix is
     array (Bin_Index range <>, Pixel_Index range <>) of Real;

   --  Subset membership: Subset_Of (i) = m means bin i ∈ S_m.
   type Subset_Map is array (Bin_Index range <>) of Subset_Index;

   type Subset_Kind is (Contiguous, Interleaved);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Absolute forward projection below which y_i / ŷ_i is treated carefully.
   Zero_Proj_Tol : constant Real := 1.0E-30;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   procedure Enforce_Nonnegative (X : in out Image)
     with Global => null;
   --  Clamp negative components to 0 (numerical safeguard).

   function Zero_Image (J : Positive) return Image
     with Global => null;
   --  Raises Capacity_Exceeded if J > Max_Pixels.

   function Zero_Projection (I : Positive) return Projection
     with Global => null;
   --  Raises Capacity_Exceeded if I > Max_Bins.

   function Zero_Matrix (I, J : Positive) return System_Matrix
     with Global => null;
   --  Raises Capacity_Exceeded if dims exceed Max_*.

   function Ones_Image (J : Positive; Value : Real := 1.0) return Image
     with Global => null;
   --  Raises Capacity_Exceeded if J > Max_Pixels.

   ---------------------------------------------------------------------------
   -- Forward / back projection and sensitivity
   ---------------------------------------------------------------------------

   function Forward_Project
     (A : System_Matrix;
      X : Image) return Projection
     with Pre => A'Length (1) >= 1
       and then A'Length (2) = X'Length
       and then A'First (2) = X'First,
          Global => null;
   --  ŷ_i = Σ_j a_{ij} x_j.

   function Back_Project
     (A : System_Matrix;
      Y : Projection) return Image
     with Pre => A'Length (1) = Y'Length
       and then A'First (1) = Y'First
       and then A'Length (2) >= 1,
          Global => null;
   --  b_j = Σ_i a_{ij} y_i  (full-bin backprojection).

   function Back_Project_Subset
     (A         : System_Matrix;
      Y         : Projection;
      Subsets   : Subset_Map;
      Subset_Id : Subset_Index) return Image
     with Pre => A'Length (1) = Y'Length
       and then A'First (1) = Y'First
       and then Y'Length = Subsets'Length
       and then Y'First = Subsets'First
       and then A'Length (2) >= 1,
          Global => null;
   --  b_j = Σ_{i ∈ S_m} a_{ij} y_i.

   function Sensitivity (A : System_Matrix) return Image
     with Pre => A'Length (1) >= 1 and then A'Length (2) >= 1,
          Global => null;
   --  s_j = Σ_i a_{ij}  (full sensitivity).

   function Sensitivity_Subset
     (A         : System_Matrix;
      Subsets   : Subset_Map;
      Subset_Id : Subset_Index) return Image
     with Pre => A'Length (1) = Subsets'Length
       and then A'First (1) = Subsets'First
       and then A'Length (2) >= 1,
          Global => null;
   --  s_j^{(m)} = Σ_{i ∈ S_m} a_{ij}.

   ---------------------------------------------------------------------------
   -- Convergence monitors
   ---------------------------------------------------------------------------

   function Poisson_NLL
     (Y_Obs : Projection;
      Y_Hat : Projection) return Real
     with Pre => Y_Obs'First = Y_Hat'First
       and then Y_Obs'Last = Y_Hat'Last
       and then Y_Obs'Length >= 1,
          Global => null;
   --  Σ_i (ŷ_i − y_i log ŷ_i)  (up to additive const independent of x).
   --  Bins with ŷ_i ≈ 0: if y_i ≈ 0 contribute 0; else large penalty.

   function KL_Divergence
     (Y_Obs : Projection;
      Y_Hat : Projection) return Real
     with Pre => Y_Obs'First = Y_Hat'First
       and then Y_Obs'Last = Y_Hat'Last
       and then Y_Obs'Length >= 1,
          Global => null;
   --  Σ_i y_i log(y_i / ŷ_i) − y_i + ŷ_i  (Kullback–Leibler; ≥ 0).

   function RMSE (X, Truth : Image) return Real
     with Pre => X'First = Truth'First
       and then X'Last = Truth'Last
       and then X'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- MLEM (Shepp–Vardi; one subset = all bins)
   ---------------------------------------------------------------------------

   procedure MLEM_Step
     (X : in out Image;
      A : System_Matrix;
      Y : Projection)
     with Pre => A'Length (2) = X'Length
       and then A'First (2) = X'First
       and then A'Length (1) = Y'Length
       and then A'First (1) = Y'First
       and then X'Length >= 1
       and then Y'Length >= 1,
          Global => null;
   --  x_j ← x_j / s_j * Σ_i a_{ij} (y_i / ŷ_i),  s_j = Σ_i a_{ij}.
   --  Pixels with s_j = 0 are left unchanged. Enforces nonnegativity.
   --  Raises Degenerate_Geometry if all sensitivities are zero.

   procedure MLEM_Iterate
     (X          : in out Image;
      A          : System_Matrix;
      Y          : Projection;
      Iterations : Positive)
     with Pre => A'Length (2) = X'Length
       and then A'First (2) = X'First
       and then A'Length (1) = Y'Length
       and then A'First (1) = Y'First
       and then X'Length >= 1
       and then Y'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Ordered subsets (Hudson & Larkin 1994)
   ---------------------------------------------------------------------------

   function Make_Ordered_Subsets
     (I_Bins : Positive;
      M      : Positive;
      Kind   : Subset_Kind := Contiguous) return Subset_Map
     with Global => null;
   --  Partition {1..I} into M nonempty disjoint subsets covering all bins.
   --  Contiguous: consecutive blocks (sizes differ by at most 1).
   --  Interleaved: bin i → subset 1 + ((i-1) mod M).
   --  Raises Invalid_Argument if M > I_Bins;
   --  Capacity_Exceeded if I_Bins > Max_Bins or M > Max_Subsets.

   function Subset_Covers_Exactly_Once
     (Subsets : Subset_Map;
      M       : Subset_Count) return Boolean
     with Pre => Subsets'Length >= 1 and then M >= 1,
          Global => null;
   --  True iff every bin maps to 1..M and each subset is nonempty.

   procedure OSEM_Step_Subset
     (X         : in out Image;
      A         : System_Matrix;
      Y         : Projection;
      Subsets   : Subset_Map;
      Subset_Id : Subset_Index)
     with Pre => A'Length (2) = X'Length
       and then A'First (2) = X'First
       and then A'Length (1) = Y'Length
       and then A'First (1) = Y'First
       and then Y'Length = Subsets'Length
       and then Y'First = Subsets'First
       and then X'Length >= 1,
          Global => null;
   --  Classic Hudson form (subset-normalized sensitivity):
   --    x_j ← x_j / (Σ_{i∈S_m} a_{ij}) * Σ_{i∈S_m} a_{ij} (y_i / ŷ_i)
   --  where ŷ = A x uses the full current image (all pixels).
   --  Zero subset-sensitivity pixels are left unchanged.

   procedure OSEM_Iterate
     (X          : in out Image;
      A          : System_Matrix;
      Y          : Projection;
      Subsets    : Subset_Map;
      M          : Subset_Count;
      Iterations : Positive)
     with Pre => A'Length (2) = X'Length
       and then A'First (2) = X'First
       and then A'Length (1) = Y'Length
       and then A'First (1) = Y'First
       and then Y'Length = Subsets'Length
       and then Y'First = Subsets'First
       and then X'Length >= 1
       and then M >= 1,
          Global => null;
   --  One iteration = one ordered pass through subsets 1 .. M.
   --  Raises Invalid_Argument if partition is invalid.

   ---------------------------------------------------------------------------
   -- Toy geometry (educational parallel-beam / strip integrals)
   ---------------------------------------------------------------------------

   function Make_1D_Strip_Matrix
     (J_Pixels : Positive;
      I_Bins   : Positive) return System_Matrix
     with Global => null;
   --  Simple 1-D nonnegative strip-integral geometry: each bin integrates a
   --  contiguous window of pixels (overlapping windows). Educational A ≥ 0.
   --  Raises Capacity_Exceeded if dims exceed Max_*; Invalid_Argument if
   --  I_Bins < 1 or J_Pixels < 1 (also via Pre).

   function Make_2D_Parallel_Beam_Matrix
     (N_Side : Positive;
      N_Angles : Positive;
      N_Rays   : Positive) return System_Matrix
     with Pre => N_Side >= 2
       and then N_Angles >= 1
       and then N_Rays >= 1,
          Global => null;
   --  Flattened N_Side×N_Side pixel grid; parallel-beam strip weights.
   --  I = N_Angles * N_Rays bins, J = N_Side² pixels.
   --  Raises Capacity_Exceeded if I > Max_Bins or J > Max_Pixels.

   function Make_Box_Phantom_1D (J_Pixels : Positive) return Image
     with Pre => J_Pixels >= 2, Global => null;
   --  Nonnegative 1-D phantom: low background + central hot region.

   function Make_Box_Phantom_2D (N_Side : Positive) return Image
     with Pre => N_Side >= 2, Global => null;
   --  Flattened 2-D box phantom (row-major).

end Ordered_Subset_EM;
