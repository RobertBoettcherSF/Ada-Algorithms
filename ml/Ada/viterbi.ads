--  Viterbi — Ada 2023 educational package for Wikipedia "Viterbi algorithm":
--  dynamic programming for the most likely hidden-state sequence (Viterbi
--  path) given a discrete hidden Markov model (HMM) and an observation
--  sequence. Product-form decode for tiny examples; preferred log-domain
--  decode for numerical stability (max of sums of logs; no log-sum-exp).
--  Andrew Viterbi, 1967; classic HMM doctor/fever example included.
--  Related siblings (not dependencies): Forward–backward, Baum–Welch.

pragma Ada_2022;

package Viterbi
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable log-domain / path-probability arithmetic.
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

   --  a_{r,s} — Trans (From, To); rows sum ≈ 1 when normalized.
   type Transition_Matrix is
     array (State_Index range <>, State_Index range <>) of Probability;

   --  b_{s,o} — Emit (State, Symbol); rows sum ≈ 1 when normalized.
   type Emission_Matrix is
     array (State_Index range <>, Symbol_Index range <>) of Probability;

   type Observation_Sequence is array (Time_Index range <>) of Symbol_Index;
   type State_Sequence       is array (Time_Index range <>) of State_Index;

   --  Optional DP table export: Prob_Table (t, s) = P_{t,s} (product form)
   --  or Exp(L_{t,s}) when filled from the log decoder (may underflow).
   type Prob_Table is
     array (Time_Index range <>, State_Index range <>) of Real;

   type Backpointer_Table is
     array (Time_Index range <>, State_Index range <>) of Natural;

   type HMM (N_States : State_Count; N_Symbols : Symbol_Count) is record
      Init  : Initial_Vector (1 .. N_States);
      Trans : Transition_Matrix (1 .. N_States, 1 .. N_States);
      Emit  : Emission_Matrix (1 .. N_States, 1 .. N_Symbols);
   end record;

   type Viterbi_Result (Length : Time_Count; N_States : State_Count) is record
      Path             : State_Sequence (1 .. Length);
      Log_Probability  : Viterbi.Log_Probability := 0.0;
      Probability      : Real := 0.0;  -- Exp (Log_Probability) when finite
      Has_Table        : Boolean := False;
      Prob_Table       : Viterbi.Prob_Table (1 .. Length, 1 .. N_States) :=
        [others => [others => 0.0]];
      Backpointers     : Backpointer_Table (1 .. Length, 1 .. N_States) :=
        [others => [others => 0]];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;  -- no positive-probability path
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

   function Argmax_Init_Emit
     (Init : Initial_Vector;
      Emit : Emission_Matrix;
      Obs  : Symbol_Index) return State_Index
     with Pre => Init'Length >= 1
       and then Emit'First (1) = Init'First
       and then Emit'Last (1) = Init'Last
       and then Obs in Emit'Range (2),
          Global => null;
   --  Argmax_s Init(s) * Emit(s, Obs).

   function Argmax_Row (Row : Initial_Vector) return State_Index
     with Pre => Row'Length >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- HMM validation / normalization
   ---------------------------------------------------------------------------

   function Is_Valid_HMM
     (Model       : HMM;
      Tol         : Real := Prob_Tol;
      Require_Stochastic : Boolean := True) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  Checks dimensions, non-negative entries, and (optionally) that Init
   --  and each Trans/Emit row sum to 1 within Tol. Also requires every
   --  observation symbol index in 1 .. N_Symbols is reachable in Emit.

   procedure Normalize_Rows (Model : in out HMM)
     with Global => null;
   --  Renormalize Init and every Trans / Emit row to sum 1. Rows that
   --  sum to 0 are left unchanged (degenerate). Raises Invalid_Argument
   --  if N_States = 0 or N_Symbols = 0.

   ---------------------------------------------------------------------------
   -- Path scoring (for tests / verification)
   ---------------------------------------------------------------------------

   function Path_Probability
     (Model : HMM;
      Obs   : Observation_Sequence;
      Path  : State_Sequence) return Real
     with Pre => Obs'Length = Path'Length
       and then Obs'Length >= 1
       and then Model.N_States >= 1
       and then Model.N_Symbols >= 1,
          Global => null;
   --  π_{p1} b_{p1,o1} Π_t a_{p_{t-1},p_t} b_{p_t,o_t}.
   --  Raises Invalid_Argument on length mismatch / bad indices.

   function Log_Path_Probability
     (Model : HMM;
      Obs   : Observation_Sequence;
      Path  : State_Sequence) return Log_Probability
     with Pre => Obs'Length = Path'Length
       and then Obs'Length >= 1
       and then Model.N_States >= 1
       and then Model.N_Symbols >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Decode
   ---------------------------------------------------------------------------

   function Viterbi_Decode
     (Model      : HMM;
      Obs        : Observation_Sequence;
      Fill_Table : Boolean := True) return Viterbi_Result
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  Classic product-form DP (Wikipedia pseudocode). Preferred only for
   --  tiny examples; may underflow on long sequences.
   --  Raises Invalid_Argument (empty/bad obs/symbol), Capacity_Exceeded,
   --  Degenerate_Geometry (all path probs zero at some step).

   function Viterbi_Decode_Log
     (Model      : HMM;
      Obs        : Observation_Sequence;
      Fill_Table : Boolean := True) return Viterbi_Result
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  Log-domain: L[t,s] = emit_log[s,obs[t]] + max_r (L[t-1,r] +
   --  trans_log[r,s]). Numerically stable; preferred in practice.
   --  Prob_Table (when Fill_Table) stores Exp(L) (may underflow to 0).

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
   --  Exact Wikipedia Example tables (init / trans / emit).

end Viterbi;
