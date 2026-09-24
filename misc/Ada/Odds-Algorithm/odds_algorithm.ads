--  Odds_Algorithm — Ada 2023 educational package for Wikipedia
--  "Odds algorithm" / Bruss algorithm: optimal stopping for last-success
--  problems by summing odds r_k = p_k/(1-p_k) from the end until R ≥ 1.
--  Output: threshold s, sum R_s, product Q_s, win probability w = Q_s R_s.
--  Related: secretary problem, optimal stopping, Bruss (2000).

pragma Ada_2022;

package Odds_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 12 for stable odds / product arithmetic.
   type Real is digits 12;

   Max_N : constant Positive := 4096;
   subtype Index_Count is Natural range 0 .. Max_N;
   subtype Index is Positive range 1 .. Max_N;

   type Probability_Vector is array (Index range <>) of Real;
   type Boolean_Array is array (Index range <>) of Boolean;

   type Odds_Result is record
      Threshold_S      : Positive := 1;
      R_Sum            : Real := 0.0;
      Q_Product        : Real := 1.0;
      Win_Probability  : Real := 0.0;
      Had_Sure_Success : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers / constants
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Sentinel odds used when p_k = 1 (undefined / infinite odds).
   Huge_Odds   : constant Real := 1.0E12;
   --  1/e lower bound from the odds theorem (when R_s ≥ 1).
   One_Over_E  : constant Real := 0.367_879_441_171;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Core odds formula
   ---------------------------------------------------------------------------

   function Odds (P_K : Real) return Real
     with Pre => P_K >= 0.0 and then P_K < 1.0,
          Global => null,
          Post => Odds'Result >= 0.0;
   --  r = p / (1 − p). Raises Invalid_Argument if p not in [0, 1).
   --  For p = 1 use Huge_Odds via Compute_Threshold (not this function).

   ---------------------------------------------------------------------------
   -- Odds algorithm (Bruss)
   ---------------------------------------------------------------------------

   function Compute_Threshold (P : Probability_Vector) return Odds_Result
     with Pre => P'Length >= 1 and then P'Length <= Max_N,
          Global => null;
   --  Sum odds backward until R ≥ 1; return s, R_s, Q_s, w = Q_s R_s.
   --  If the sum never reaches 1, sets s = 1 (= P'First).
   --  Requires each p_k ∈ [0, 1]; p_k = 1 uses Huge_Odds (sure success).
   --  Raises Invalid_Argument if any p_k ∉ [0, 1] or P empty;
   --  Capacity_Exceeded if Length > Max_N.

   function Should_Stop
     (K                       : Positive;
      Observation_Interesting : Boolean;
      Threshold_S             : Positive) return Boolean
     with Global => null;
   --  True iff K ≥ Threshold_S and the observation is interesting.

   function Apply_Strategy
     (Interesting : Boolean_Array;
      Threshold_S : Positive) return Natural
     with Pre => Interesting'Length >= 1,
          Global => null;
   --  Index of first interesting event at or after Threshold_S, or 0 if none.

   ---------------------------------------------------------------------------
   -- Helpers: uniform probabilities, secretary records, Monte Carlo
   ---------------------------------------------------------------------------

   function Uniform_P (N : Positive; P : Real) return Probability_Vector
     with Pre => N <= Max_N and then P >= 0.0 and then P < 1.0,
          Global => null,
          Post => Uniform_P'Result'Length = N;
   --  Vector of length N with every entry equal to P.

   function Secretary_Record_Probabilities
     (N : Positive) return Probability_Vector
     with Pre => N <= Max_N,
          Global => null,
          Post => Secretary_Record_Probabilities'Result'Length = N;
   --  Classical best-choice: P(kth candidate is a record) = 1/k.
   --  Note p_1 = 1 (sure record); Compute_Threshold treats that specially.

   function Simulate_Win_Rate
     (P           : Probability_Vector;
      Threshold_S : Positive;
      Trials      : Positive;
      Seed        : Natural := 1) return Real
     with Pre => P'Length >= 1
       and then P'Length <= Max_N
       and then Threshold_S >= P'First
       and then Threshold_S <= P'Last
       and then Trials >= 1,
          Global => null,
          Post => Simulate_Win_Rate'Result >= 0.0
            and then Simulate_Win_Rate'Result <= 1.0;
   --  Monte Carlo: draw independent Bernoulli(p_k), apply odds strategy,
   --  estimate P(stop on the last success). Seeded LCG for reproducibility.

end Odds_Algorithm;
