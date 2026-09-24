--  Algorithms_For_Calculating_Variance — Ada 2023 educational package for
--  Wikipedia "Algorithms for calculating variance": naïve Sum/SumSq,
--  shifted-data, two-pass, Welford online (n, mean, M2), Chan parallel merge,
--  West weighted incremental, and online co-moment covariance.
--  Numerically stable online / merge APIs are preferred over the naïve formula.

pragma Ada_2022;

package Algorithms_For_Calculating_Variance
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 15 for double-precision-like educational numerics.
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Samples : constant Positive := 65_536;
   subtype Sample_Count is Natural range 0 .. Max_Samples;
   subtype Sample_Index is Positive range 1 .. Max_Samples;

   type Real_Array is array (Sample_Index range <>) of Real;
   type Weight_Array is array (Sample_Index range <>) of Non_Negative;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   Empty_Sample     : exception;
   Degenerate       : exception;  --  n < 2 for sample variance, etc.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Sqrt_Nonneg (X : Non_Negative) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- Welford online accumulator (n, mean, M2)
   ---------------------------------------------------------------------------

   type Welford_State is record
      Count : Natural := 0;
      Mean  : Real := 0.0;
      M2    : Non_Negative := 0.0;
   end record;

   function Make_Empty return Welford_State
     with Global => null,
          Post => Make_Empty'Result.Count = 0;

   procedure Reset (S : in out Welford_State)
     with Post => S.Count = 0 and then S.Mean = 0.0 and then S.M2 = 0.0;

   procedure Update (S : in out Welford_State; X : Real)
     with Global => null;
   --  One Welford step:
   --    n := n+1
   --    delta := x - mean; mean := mean + delta/n
   --    M2 := M2 + delta * (x - mean)

   procedure Update_Many (S : in out Welford_State; Data : Real_Array)
     with Global => null;
   --  Apply Update for each element of Data.

   function Merge (A, B : Welford_State) return Welford_State
     with Global => null;
   --  Chan et al. parallel combine of two Welford accumulators:
   --    n_AB = n_A + n_B
   --    delta = mean_B - mean_A
   --    mean_AB = (n_A*mean_A + n_B*mean_B) / n_AB
   --    M2_AB = M2_A + M2_B + delta^2 * n_A * n_B / n_AB
   --  Empty operands are handled (identity for merge).

   function Sample_Variance (S : Welford_State) return Non_Negative
     with Global => null;
   --  s^2 = M2 / (n-1). Raises Degenerate if Count < 2.

   function Population_Variance (S : Welford_State) return Non_Negative
     with Global => null;
   --  sigma^2 = M2 / n. Raises Empty_Sample if Count = 0.

   function Std_Dev
     (S : Welford_State; Sample : Boolean := True) return Non_Negative
     with Global => null;
   --  sqrt of sample (default) or population variance.

   function From_Array (Data : Real_Array) return Welford_State
     with Global => null;
   --  Build a Welford_State by online Update over Data.

   ---------------------------------------------------------------------------
   -- Array helpers: naïve / shifted / two-pass
   ---------------------------------------------------------------------------

   function Naive_Sample_Variance (Data : Real_Array) return Non_Negative
     with Global => null;
   --  Numerically UNSTABLE one-pass: (SumSq - Sum^2/n) / (n-1).
   --  Documented educational contrast; do not use in practice.

   function Naive_Population_Variance (Data : Real_Array) return Non_Negative
     with Global => null;
   --  Numerically UNSTABLE: (SumSq - Sum^2/n) / n.

   function Shifted_Sample_Variance
     (Data : Real_Array; K : Real) return Non_Negative
     with Global => null;
   --  Shifted-data sample variance with constant K:
   --    (Ex2 - Ex^2/n) / (n-1) where Ex = sum(x_i-K), Ex2 = sum((x_i-K)^2).

   function Shifted_Population_Variance
     (Data : Real_Array; K : Real) return Non_Negative
     with Global => null;

   function Two_Pass_Sample_Variance (Data : Real_Array) return Non_Negative
     with Global => null;
   --  Compute mean, then sum of squared deviations / (n-1).

   function Two_Pass_Population_Variance (Data : Real_Array) return Non_Negative
     with Global => null;

   function Two_Pass_Mean (Data : Real_Array) return Real
     with Global => null;
   --  Arithmetic mean. Raises Empty_Sample if Data'Length = 0.

   ---------------------------------------------------------------------------
   -- Weighted incremental (West 1979)
   ---------------------------------------------------------------------------

   type Weighted_State is record
      W_Sum  : Non_Negative := 0.0;  --  sum of weights
      W_Sum2 : Non_Negative := 0.0;  --  sum of squared weights
      Mean   : Real := 0.0;
      S      : Non_Negative := 0.0;  --  weighted sum of squares of diffs
      Count  : Natural := 0;         --  number of observations
   end record;

   function Make_Empty_Weighted return Weighted_State
     with Global => null,
          Post => Make_Empty_Weighted'Result.Count = 0;

   procedure Reset_Weighted (S : in out Weighted_State)
     with Post => S.Count = 0;

   procedure Update_Weighted
     (S : in out Weighted_State; X : Real; W : Non_Negative)
     with Global => null;
   --  West incremental update. Weight 0 is a no-op (except Count still
   --  unchanged). Raises Invalid_Argument is not used for W=0; W=0 skipped.

   function Weighted_Population_Variance
     (S : Weighted_State) return Non_Negative
     with Global => null;
   --  S / W_Sum. Raises Empty_Sample if W_Sum = 0.

   function Weighted_Frequency_Sample_Variance
     (S : Weighted_State) return Non_Negative
     with Global => null;
   --  Frequency-weight Bessel: S / (W_Sum - 1). Raises Degenerate if
   --  W_Sum <= 1.

   function Weighted_Reliability_Sample_Variance
     (S : Weighted_State) return Non_Negative
     with Global => null;
   --  Reliability-weight Bessel: S / (W_Sum - W_Sum2/W_Sum).

   function From_Weighted_Arrays
     (Data : Real_Array; Weights : Weight_Array) return Weighted_State
     with Global => null;
   --  Requires Data'Length = Weights'Length; else Invalid_Argument.

   ---------------------------------------------------------------------------
   -- Online covariance (co-moment C_n)
   ---------------------------------------------------------------------------

   type Covariance_State is record
      Count  : Natural := 0;
      Mean_X : Real := 0.0;
      Mean_Y : Real := 0.0;
      C      : Real := 0.0;  --  co-moment sum (x_i - mean_x)(y_i - mean_y)
   end record;

   function Make_Empty_Covariance return Covariance_State
     with Global => null,
          Post => Make_Empty_Covariance'Result.Count = 0;

   procedure Reset_Covariance (S : in out Covariance_State)
     with Post => S.Count = 0;

   procedure Update_Covariance
     (S : in out Covariance_State; X, Y : Real)
     with Global => null;
   --  Online co-moment:
   --    mean_x := mean_x + (x - mean_x)/n
   --    mean_y := mean_y + (y - mean_y)/n
   --    C := C + (x - mean_x_new) * (y - mean_y_old)
   --  (Wikipedia / Pébay form.)

   function Sample_Covariance (S : Covariance_State) return Real
     with Global => null;
   --  C / (n-1). Raises Degenerate if Count < 2.

   function Population_Covariance (S : Covariance_State) return Real
     with Global => null;
   --  C / n. Raises Empty_Sample if Count = 0.

   function Two_Pass_Sample_Covariance
     (X, Y : Real_Array) return Real
     with Global => null;
   --  Reference two-pass covariance. Requires equal lengths; n >= 2.

end Algorithms_For_Calculating_Variance;
