--  Forward_Backward — Ada 2023 educational package for Wikipedia
--  "Forward–backward algorithm": HMM smoothing posteriors
--  γ_t(i) = P(X_t = i | o_1:T), forward α, backward β, and observation
--  likelihood. Unscaled product form for tiny examples; Rabiner-style
--  scaled forward–backward (c_t) preferred for longer sequences.
--  Related siblings (not dependencies): Viterbi, Baum–Welch.

pragma Ada_2022;

package Forward_Backward
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable probability / log-sum-exp arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Probability is Non_Negative;  -- typically in [0,1]; may be unnormalized
   subtype Log_Probability is Real;  -- typically <= 0; Log_Zero sentinel

   Max_States  : constant Positive := 64;
   Max_Symbols : constant Positive := 64;
   Max_Time    : constant Positive := 1024;

   subtype State_Count  is Natural  range 0 .. Max_States;
   subtype Symbol_Count is Natural  range 0 .. Max_Symbols;
   subtype Time_Count   is Natural  range 0 .. Max_Time;

   subtype State_Index  is Positive range 1 .. Max_States;
   subtype Symbol_Index is Positive range 1 .. Max_Symbols;
   subtype Time_Index   is Positive range 1 .. Max_Time;

   --  π_s — initial state distribution (length = N_States).
   type Initial_Vector is array (State_Index range <>) of Probability;

   --  Log-domain vector (may hold Log_Zero / negative logs).
   type Log_Vector is array (State_Index range <>) of Log_Probability;

   --  a_{r,s} — Trans (From, To); rows sum ≈ 1 when normalized.
   type Transition_Matrix is
     array (State_Index range <>, State_Index range <>) of Probability;

   --  b_{s,o} — Emit (State, Symbol); rows sum ≈ 1 when normalized.
   type Emission_Matrix is
     array (State_Index range <>, Symbol_Index range <>) of Probability;

   type Observation_Sequence is array (Time_Index range <>) of Symbol_Index;
   type State_Sequence       is array (Time_Index range <>) of State_Index;

   --  α / β / γ tables: (t, state)
   type Alpha_Table is
     array (Time_Index range <>, State_Index range <>) of Real;
   type Beta_Table is
     array (Time_Index range <>, State_Index range <>) of Real;
   type Posterior_Table is
     array (Time_Index range <>, State_Index range <>) of Real;

   --  ξ_t(i,j): time index 1 .. T-1, from-state, to-state
   type Xi_Table is
     array (Time_Index range <>,
            State_Index range <>,
            State_Index range <>) of Real;

   --  Per-time scaling factors c_t (Rabiner): P(o) = Π_t c_t.
   type Scale_Vector is array (Time_Index range <>) of Real;

   type HMM (N_States : State_Count; N_Symbols : Symbol_Count) is record
      Init  : Initial_Vector (1 .. N_States);
      Trans : Transition_Matrix (1 .. N_States, 1 .. N_States);
      Emit  : Emission_Matrix (1 .. N_States, 1 .. N_Symbols);
   end record;

   --  Discriminant Xi_Last = Length - 1 when Fill_Xi, else 0.
   type FB_Result
     (Length   : Time_Count;
      N_States : State_Count;
      Xi_Last  : Time_Count)
   is record
      Alpha          : Alpha_Table (1 .. Length, 1 .. N_States) :=
        [others => [others => 0.0]];
      Beta           : Beta_Table (1 .. Length, 1 .. N_States) :=
        [others => [others => 0.0]];
      Gamma          : Posterior_Table (1 .. Length, 1 .. N_States) :=
        [others => [others => 0.0]];
      Likelihood     : Real := 0.0;
      Log_Likelihood : Log_Probability := 0.0;
      Scaled         : Boolean := False;
      Has_Xi         : Boolean := False;
      Scales         : Scale_Vector (1 .. Length) := [others => 1.0];
      Xi             : Xi_Table
        (1 .. Xi_Last, 1 .. N_States, 1 .. N_States) :=
        [others => [others => [others => 0.0]]];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;  -- zero likelihood / all mass lost
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Sentinel for log(0); well below any finite log of a Probability.
   Log_Zero    : constant Log_Probability := -1.0E30;
   --  Absolute tolerance for row-sum / probability checks.
   Prob_Tol    : constant Real := 1.0E-6;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Log (X : Real) return Log_Probability
     with Global => null;
   --  Natural log; Log(X) for X <= 0 yields Log_Zero (no exception).

   function Exp (X : Log_Probability) return Real
     with Global => null;
   --  e^X; clamps huge negative to 0.0; overflow -> Real'Last.

   function Log_Sum_Exp (A, B : Log_Probability) return Log_Probability
     with Global => null;
   --  log(e^A + e^B) with Log_Zero absorbing and overflow-safe.

   function Log_Sum_Exp_Row
     (Values : Initial_Vector) return Log_Probability
     with Pre => Values'Length >= 1, Global => null;
   --  Log of the sum of ordinary (non-log) positive Values entries.

   function Log_Sum_Exp_Logs
     (Logs : Log_Vector) return Log_Probability
     with Pre => Logs'Length >= 1, Global => null;
   --  log Σ_i exp(Logs(i)); entries may be Log_Zero.

   ---------------------------------------------------------------------------
   -- HMM validation / normalization
   ---------------------------------------------------------------------------

   function Is_Valid_HMM
     (Model              : HMM;
      Tol                : Real := Prob_Tol;
      Require_Stochastic : Boolean := True) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Checks dimensions, non-negative entries, and (optionally) that Init
   --  and each Trans/Emit row sum to 1 within Tol.

   procedure Normalize_Rows (Model : in out HMM)
     with Global => null;
   --  Renormalize Init and every Trans / Emit row to sum 1. Rows that
   --  sum to 0 are left unchanged (degenerate). Raises Invalid_Argument
   --  if N_States = 0 or N_Symbols = 0.

   ---------------------------------------------------------------------------
   -- Forward / Backward / Smooth
   ---------------------------------------------------------------------------

   function Forward
     (Model : HMM;
      Obs   : Observation_Sequence) return Alpha_Table
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  Unscaled α_t(i). Raises Invalid_Argument / Capacity_Exceeded /
   --  Degenerate_Geometry (likelihood zero at some step).

   function Likelihood_From_Alpha
     (Alpha : Alpha_Table) return Real
     with Pre => Alpha'Length (1) >= 1 and then Alpha'Length (2) >= 1,
          Global => null;
   --  P(o) = Σ_i α_T(i).

   function Backward
     (Model : HMM;
      Obs   : Observation_Sequence) return Beta_Table
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  Unscaled β_t(i) with β_T(i) = 1.

   function Smooth
     (Model : HMM;
      Obs   : Observation_Sequence) return Posterior_Table
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  γ_t(i) = α_t(i) β_t(i) / P(o) (unscaled path).

   function Forward_Backward
     (Model   : HMM;
      Obs     : Observation_Sequence;
      Fill_Xi : Boolean := True) return FB_Result
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  Bundles α, β, γ, P(o), optional ξ. Unscaled; for short sequences.

   function Forward_Backward_Scaled
     (Model   : HMM;
      Obs     : Observation_Sequence;
      Fill_Xi : Boolean := True) return FB_Result
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  Rabiner-style c_t scaling. Preferred for longer T. Alpha/Beta are
   --  scaled; Gamma/Xi are true posteriors; Likelihood = Π_t c_t.

   function Posterior_Mode_Path
     (Gamma : Posterior_Table) return State_Sequence
     with Pre => Gamma'Length (1) >= 1 and then Gamma'Length (2) >= 1,
          Global => null;
   --  argmax_i γ_t(i) at each t (MAP marginal path; may differ from Viterbi).

   ---------------------------------------------------------------------------
   -- Wikipedia doctor / fever fixture
   ---------------------------------------------------------------------------

   --  States: 1 = Healthy, 2 = Fever.
   --  Symbols: 1 = normal, 2 = cold, 3 = dizzy.
   Healthy : constant State_Index  := 1;
   Fever   : constant State_Index  := 2;
   Normal  : constant Symbol_Index := 1;
   Cold    : constant Symbol_Index := 2;
   Dizzy   : constant Symbol_Index := 3;

   function Make_Doctor_Fever_HMM return HMM
     with Global => null,
          Post => Make_Doctor_Fever_HMM'Result.N_States = 2
            and then Make_Doctor_Fever_HMM'Result.N_Symbols = 3;
   --  Exact Wikipedia / Viterbi Example tables (init / trans / emit).

end Forward_Backward;
