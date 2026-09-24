--  Odlyzko_Schonhage — Ada 2023 educational package for the
--  Odlyzko–Schönhage algorithm: FFT ideas for fast multipoint evaluation
--  of a finite Dirichlet series. Classroom Long_Float / digits-15 sketches
--  only — NOT a production Riemann-zeta engine.
--  Primary source:
--  https://en.wikipedia.org/wiki/Odlyzko%E2%80%93Sch%C3%B6nhage_algorithm
--  Siblings (README): Ada-Schoenhage-Strassen, Ada-Karatsuba, Ada-Toom-Cook,
--  Ada-Multiplication-Algorithms. Next new work: Tonelli–Shanks.

pragma Ada_2022;

package Odlyzko_Schonhage
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational digits-15 sketches)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   type Complex is record
      Re, Im : Real := 0.0;
   end record;

   --  Truncation / batch caps keep classroom tests fast.
   Max_N : constant Positive := 256;
   Max_M : constant Positive := 256;

   subtype Truncation is Positive range 1 .. Max_N;
   subtype Batch_Count is Positive range 1 .. Max_M;

   Near_Tol : constant Real := 1.0E-9;

   type Real_Array is array (Positive range <>) of Real;
   type Complex_Array is array (Positive range <>) of Complex;

   Invalid_Argument : exception;
   --  Raised for empty / oversized arrays, non power-of-two FFT length,
   --  S <= 1 when absolute convergence is assumed, non-positive step
   --  counts, mismatched batch lengths, etc.

   ---------------------------------------------------------------------------
   -- Complex arithmetic / helpers
   ---------------------------------------------------------------------------

   function "+" (Left, Right : Complex) return Complex
     with Global => null;

   function "-" (Left, Right : Complex) return Complex
     with Global => null;

   function "*" (Left, Right : Complex) return Complex
     with Global => null;

   function Conjugate (Z : Complex) return Complex
     with Global => null;

   function Abs_Value (Z : Complex) return Real
     with Global => null;

   function Near
     (Left, Right : Real; Tol : Real := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near
     (Left, Right : Complex; Tol : Real := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Power_Of_Two (N : Natural) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Naive Dirichlet polynomial (single point / batch)
   ---------------------------------------------------------------------------

   --  P(s) = Σ_{n=1}^{N} n^{-s} for real s > 1 (absolute convergence).
   --  Uses Exp (-S * Log (n)). Raises Invalid_Argument if S <= 1 or
   --  N > Max_N.
   function Naive_Dirichlet_Poly (S : Real; N : Truncation) return Real
     with Global => null;

   --  Evaluate P at each abscissa Abscissae (I); O(M·N).
   --  Raises Invalid_Argument if any S <= 1, N > Max_N, empty Abscissae,
   --  or Values'Length /= Abscissae'Length, or M > Max_M.
   procedure Naive_Batch
     (Abscissae :     Real_Array;
      N         :     Truncation;
      Values    : out Real_Array)
     with Global => null;

   ---------------------------------------------------------------------------
   -- FFT helpers (Cooley–Tukey radix-2) — speeding ingredient
   ---------------------------------------------------------------------------

   --  In-place unitary-unnormalized DFT: X_k ← Σ_j X_j exp(-2πi jk / Len).
   --  Length must be a power of two in 1 .. Max_M (or Max_N). Raises
   --  Invalid_Argument otherwise.
   procedure DFT (X : in out Complex_Array)
     with Global => null;

   --  Inverse DFT (unnormalized forward then divide by Len): round-trip
   --  DFT then IDFT recovers the original vector (within float noise).
   procedure IDFT (X : in out Complex_Array)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Ordinary polynomial multipoint via FFT (classroom FFT idea)
   ---------------------------------------------------------------------------

   --  Q(ω^k) for k = 0 .. Len-1 via DFT of zero-padded coefficient vector.
   --  Coeffs (0 .. Deg) with Deg+1 <= Len, Len power of two.
   --  Raises Invalid_Argument on bad sizes / non power-of-two Len.
   procedure Polynomial_Eval_FFT
     (Coeffs :     Complex_Array;
      Values : out Complex_Array)
     with Global => null;

   --  Same points (Len-th roots of unity) by direct Horner / powering.
   procedure Polynomial_Eval_Naive
     (Coeffs :     Complex_Array;
      Values : out Complex_Array)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Fast geometric batch / Odlyzko–Schönhage educational sketch
   ---------------------------------------------------------------------------

   --  Evaluate P(S0 + j·H) for j = 0 .. M-1 via the geometric rewrite
   --  n^{-(S0+jH)} = n^{-S0} · (n^{-H})^j with incremental multiply.
   --  Still O(M·N) arithmetic but matches Naive_Batch and exhibits the
   --  structure that production OS algorithms accelerate with FFTs.
   --  Requires S0 > 1, H > 0, S0+(M-1)*H > 1, M <= Max_M.
   procedure Fast_Batch_Geometric
     (S0     :     Real;
      H      :     Real;
      M      :     Batch_Count;
      N      :     Truncation;
      Values : out Real_Array)
     with Global => null;

   --  Educational Odlyzko–Schönhage sketch: blocked Taylor expansion of
   --  n^{-s} about block centres, then degree-(D) multipoint evaluation
   --  (Horner per point; FFT helpers available for the poly view).
   --  Asymptotic intent of the real algorithm: O(N^{1+ε}) for O(N)
   --  equally spaced abscissae versus O(N²) naive. Toy sizes only.
   --  On a small grid with modest step H, agrees with Naive_Batch within
   --  ~1e-8. Same preconditions as Fast_Batch_Geometric.
   procedure Odlyzko_Schonhage_Sketch
     (S0     :     Real;
      H      :     Real;
      M      :     Batch_Count;
      N      :     Truncation;
      Values : out Real_Array)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Optional ζ / η partial sums (σ > 1 demos)
   ---------------------------------------------------------------------------

   --  ζ_N(s) = Σ_{n=1}^{N} n^{-s}  (alias of Naive_Dirichlet_Poly).
   function Zeta_Partial (S : Real; N : Truncation) return Real
     with Global => null;

   --  η_N(s) = Σ_{n=1}^{N} (-1)^{n-1} n^{-s}  (alternating; s > 0 ok here).
   --  Raises Invalid_Argument if S <= 0 or N > Max_N.
   function Eta_Partial (S : Real; N : Truncation) return Real
     with Global => null;

   --  Known constant π²/6 for ζ(2) comparisons.
   Pi_Squared_Over_6 : constant Real :=
     1.644_934_066_848_226_4;

end Odlyzko_Schonhage;
