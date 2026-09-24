--  Queuing_Theory — Ada 2023 educational survey package for Wikipedia
--  "Queueing theory": classic single-node formulas (Little's law,
--  Kendall notation helpers, M/M/1, M/M/c, M/M/1/K, M/M/∞, birth–death
--  balance sketches). Self-contained; does not depend on sibling
--  Ada-Buzens-Algorithm (closed networks / convolution).
--  Origins: Erlang (1909+); Kendall notation (1953); Kleinrock.

pragma Ada_2022;

package Queuing_Theory
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 12: adequate for classic queue formulas and factorial products.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Servers  : constant Positive := 128;
   Max_Capacity : constant Positive := 4096;
   Max_State_N  : constant Natural  := 4096;

   subtype Server_Count   is Positive range 1 .. Max_Servers;
   subtype Capacity_Count is Positive range 1 .. Max_Capacity;
   subtype State_Index    is Natural  range 0 .. Max_State_N;

   --  Bundled steady-state metrics for common models.
   type MM1_Result is record
      Rho          : Real := 0.0;
      P0           : Real := 0.0;
      L            : Real := 0.0;
      Lq           : Real := 0.0;
      W            : Real := 0.0;
      Wq           : Real := 0.0;
      Utilization  : Real := 0.0;
   end record;

   type MMc_Result is record
      Rho           : Real := 0.0;  -- λ/(c μ)
      A             : Real := 0.0;  -- offered load λ/μ
      P0            : Real := 0.0;
      Erlang_C      : Real := 0.0;  -- P(wait > 0)
      L             : Real := 0.0;
      Lq            : Real := 0.0;
      W             : Real := 0.0;
      Wq            : Real := 0.0;
      Utilization   : Real := 0.0;  -- = Rho
      Servers       : Server_Count := 1;
   end record;

   type MM1K_Result is record
      Rho            : Real := 0.0;  -- λ/μ (may be ≥ 1)
      P0             : Real := 0.0;
      P_Block        : Real := 0.0;  -- P_K
      Lambda_Eff     : Real := 0.0;  -- λ (1 − P_K)
      L              : Real := 0.0;
      Lq             : Real := 0.0;
      W              : Real := 0.0;  -- L / λ_eff
      Wq             : Real := 0.0;
      Utilization    : Real := 0.0;  -- 1 − P0
      Capacity       : Capacity_Count := 1;
   end record;

   type MM_Inf_Result is record
      Rho : Real := 0.0;  -- λ/μ
      L   : Real := 0.0;  -- = Rho
      W   : Real := 0.0;  -- = 1/μ
   end record;

   --  Kendall A/S tokens (educational; Markov / Deterministic / General / Ek).
   type Arrival_Kind is (M, D, G, Ek);
   type Service_Kind is (M, D, G, Ek);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;  -- unstable ρ ≥ 1 (infinite buffers)
   Capacity_Exceeded   : exception;
   Empty_Sample        : exception;  -- unused; style parity with siblings

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Power (Base : Real; Exp : Natural) return Real
     with Global => null;
   --  Base^Exp via iterative multiply (Exp = 0 => 1).

   function Factorial_Real (N : Natural) return Real
     with Global => null,
          Pre => N <= Max_Servers + 8;
   --  N! as Real via iterative product (educational; avoids huge Integer).

   function Is_Stable_MM1 (Lambda, Mu : Real) return Boolean
     with Global => null;
   --  True iff Lambda > 0, Mu > 0, and Lambda < Mu.

   function Is_Stable_MMc
     (Lambda : Real; Mu : Real; C : Server_Count) return Boolean
     with Global => null;
   --  True iff Lambda > 0, Mu > 0, and Lambda < Real (C) * Mu.

   ---------------------------------------------------------------------------
   -- Little's law: L = λ W  (and rearrangements)
   ---------------------------------------------------------------------------

   function Littles_L (Lambda, W : Real) return Real
     with Pre => Lambda > 0.0 and then W >= 0.0,
          Global => null,
          Post => Littles_L'Result >= 0.0;
   --  L = λ W. Raises Invalid_Argument if Lambda ≤ 0 or W < 0.

   function Littles_W (L, Lambda : Real) return Real
     with Pre => L >= 0.0 and then Lambda > 0.0,
          Global => null,
          Post => Littles_W'Result >= 0.0;
   --  W = L / λ.

   function Littles_Lambda (L, W : Real) return Real
     with Pre => L >= 0.0 and then W > 0.0,
          Global => null,
          Post => Littles_Lambda'Result >= 0.0;
   --  λ = L / W.

   ---------------------------------------------------------------------------
   -- Kendall notation (educational helper)
   ---------------------------------------------------------------------------

   function Format_Kendall
     (A : String;
      S : String;
      C : Positive;
      K : Natural := 0;
      N : Natural := 0;
      D : String  := "") return String
     with Pre => A'Length >= 1 and then S'Length >= 1 and then C >= 1,
          Global => null;
   --  Build "A/S/c", "A/S/c/K", "A/S/c/K/N", or "A/S/c/K/N/D".
   --  K=0 means omit capacity (∞); N=0 omit population; empty D omit discipline.
   --  Raises Invalid_Argument on empty A or S.

   function Format_Kendall
     (Arr : Arrival_Kind;
      Srv : Service_Kind;
      C   : Positive;
      K   : Natural := 0;
      N   : Natural := 0) return String
     with Pre => C >= 1, Global => null;
   --  Enum-based builder (Ek prints as "Ek").

   function Parse_Kendall_Servers (Notation : String) return Natural
     with Global => null;
   --  Lite parse: extract c from "A/S/c..." (third slash-field). Returns 0
   --  on failure; does not raise.

   ---------------------------------------------------------------------------
   -- Traffic intensity
   ---------------------------------------------------------------------------

   function Rho
     (Lambda : Real;
      Mu     : Real;
      C      : Server_Count := 1) return Real
     with Pre => Lambda >= 0.0 and then Mu > 0.0,
          Global => null,
          Post => Rho'Result >= 0.0;
   --  ρ = λ / (c μ). Raises Invalid_Argument if Mu ≤ 0 or Lambda < 0.

   ---------------------------------------------------------------------------
   -- M/M/1  (ρ = λ/μ < 1)
   ---------------------------------------------------------------------------

   function MM1_P0 (Lambda, Mu : Real) return Real
     with Global => null;
   --  P0 = 1 − ρ. Raises Degenerate_Geometry if ρ ≥ 1;
   --  Invalid_Argument if rates invalid.

   function MM1_Pn (Lambda, Mu : Real; N : Natural) return Real
     with Global => null;
   --  Pn = (1 − ρ) ρ^n.

   function MM1_L (Lambda, Mu : Real) return Real
     with Global => null;
   --  L = ρ / (1 − ρ).

   function MM1_Lq (Lambda, Mu : Real) return Real
     with Global => null;
   --  Lq = ρ² / (1 − ρ).

   function MM1_W (Lambda, Mu : Real) return Real
     with Global => null;
   --  W = 1 / (μ − λ).

   function MM1_Wq (Lambda, Mu : Real) return Real
     with Global => null;
   --  Wq = λ / (μ (μ − λ)).

   function MM1_Utilization (Lambda, Mu : Real) return Real
     with Global => null;
   --  Utilization = ρ = λ/μ.

   function Analyze_MM1 (Lambda, Mu : Real) return MM1_Result
     with Global => null;
   --  Bundle all M/M/1 metrics. Same exception contract as MM1_*.

   ---------------------------------------------------------------------------
   -- M/M/c  (c servers, ρ = λ/(c μ) < 1)
   ---------------------------------------------------------------------------

   function MMc_P0 (Lambda, Mu : Real; C : Server_Count) return Real
     with Global => null;
   --  Idle probability via finite Erlang sum. Raises Degenerate_Geometry
   --  if ρ ≥ 1; Capacity_Exceeded if C too large for Factorial_Real.

   function MMc_Erlang_C (Lambda, Mu : Real; C : Server_Count) return Real
     with Global => null;
   --  Erlang-C: P(wait > 0).

   function MMc_Lq (Lambda, Mu : Real; C : Server_Count) return Real
     with Global => null;

   function MMc_Wq (Lambda, Mu : Real; C : Server_Count) return Real
     with Global => null;

   function MMc_L (Lambda, Mu : Real; C : Server_Count) return Real
     with Global => null;

   function MMc_W (Lambda, Mu : Real; C : Server_Count) return Real
     with Global => null;

   function Analyze_MMc
     (Lambda : Real; Mu : Real; C : Server_Count) return MMc_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- M/M/1/K  (finite capacity K; always "stable")
   ---------------------------------------------------------------------------

   function MM1K_Pn
     (Lambda : Real; Mu : Real; K : Capacity_Count; N : Natural) return Real
     with Global => null;
   --  Truncated geometric. Raises Invalid_Argument if N > K or rates bad.

   function MM1K_P_Block
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
     with Global => null;
   --  Blocking probability P_K.

   function MM1K_Lambda_Eff
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
     with Global => null;

   function MM1K_L
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
     with Global => null;

   function MM1K_Lq
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
     with Global => null;

   function MM1K_W
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
     with Global => null;

   function MM1K_Wq
     (Lambda : Real; Mu : Real; K : Capacity_Count) return Real
     with Global => null;

   function Analyze_MM1K
     (Lambda : Real; Mu : Real; K : Capacity_Count) return MM1K_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- M/M/∞  (infinite servers)
   ---------------------------------------------------------------------------

   function MM_Inf_L (Lambda, Mu : Real) return Real
     with Global => null;
   --  L = λ/μ. Raises Invalid_Argument if Mu ≤ 0 or Lambda < 0.

   function MM_Inf_Pn (Lambda, Mu : Real; N : Natural) return Real
     with Global => null;
   --  Poisson: Pn = e^{−ρ} ρ^n / n!.

   function MM_Inf_W (Lambda, Mu : Real) return Real
     with Global => null;
   --  W = 1/μ (no queueing).

   function Analyze_MM_Inf (Lambda, Mu : Real) return MM_Inf_Result
     with Global => null;

   ---------------------------------------------------------------------------
   -- Birth–death / local balance (educational)
   ---------------------------------------------------------------------------

   function MM1_Local_Balance_Holds
     (Lambda, Mu : Real;
      N          : Positive;
      Tol        : Real := Epsilon_Tol) return Boolean
     with Pre => N >= 1 and then Tol >= 0.0,
          Global => null;
   --  Verify μ P_n ≈ λ P_{n−1} for M/M/1 computed Pn (local balance).
   --  Returns False (does not raise) if the system is unstable.

   function Birth_Death_Pn_Product
     (Lambda, Mu : Real; N : Natural) return Real
     with Global => null;
   --  Educational: P_n / P_0 = (λ/μ)^n for constant-rate birth–death M/M/1.

end Queuing_Theory;
