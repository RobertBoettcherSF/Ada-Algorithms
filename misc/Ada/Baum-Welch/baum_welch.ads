--  Baum_Welch — Ada 2023 educational package for Wikipedia
--  "Baum–Welch algorithm": EM training of discrete HMMs using
--  forward–backward (γ, ξ) and Rabiner-style parameter updates.
--  Self-contained: embeds compact scaled forward–backward for the E-step.
--  Related siblings (not dependencies): Forward–backward, Viterbi, HMM.

pragma Ada_2022;

package Baum_Welch
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable probability / log-sum-exp arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Probability is Non_Negative;
   subtype Log_Probability is Real;

   Max_States    : constant Positive := 64;
   Max_Symbols   : constant Positive := 64;
   Max_Time      : constant Positive := 1024;
   Max_Sequences : constant Positive := 32;
   Max_History   : constant Positive := 256;

   subtype State_Count  is Natural  range 0 .. Max_States;
   subtype Symbol_Count is Natural  range 0 .. Max_Symbols;
   subtype Time_Count   is Natural  range 0 .. Max_Time;
   subtype Seq_Count    is Natural  range 0 .. Max_Sequences;

   subtype State_Index  is Positive range 1 .. Max_States;
   subtype Symbol_Index is Positive range 1 .. Max_Symbols;
   subtype Time_Index   is Positive range 1 .. Max_Time;
   subtype Seq_Index    is Positive range 1 .. Max_Sequences;

   type Initial_Vector is array (State_Index range <>) of Probability;
   type Log_Vector     is array (State_Index range <>) of Log_Probability;

   type Transition_Matrix is
     array (State_Index range <>, State_Index range <>) of Probability;

   type Emission_Matrix is
     array (State_Index range <>, Symbol_Index range <>) of Probability;

   type Observation_Sequence is array (Time_Index range <>) of Symbol_Index;
   type State_Sequence       is array (Time_Index range <>) of State_Index;

   type Alpha_Table is
     array (Time_Index range <>, State_Index range <>) of Real;
   type Beta_Table is
     array (Time_Index range <>, State_Index range <>) of Real;
   type Posterior_Table is
     array (Time_Index range <>, State_Index range <>) of Real;

   type Xi_Table is
     array (Time_Index range <>,
            State_Index range <>,
            State_Index range <>) of Real;

   type Scale_Vector is array (Time_Index range <>) of Real;

   type HMM (N_States : State_Count; N_Symbols : Symbol_Count) is record
      Init  : Initial_Vector (1 .. N_States);
      Trans : Transition_Matrix (1 .. N_States, 1 .. N_States);
      Emit  : Emission_Matrix (1 .. N_States, 1 .. N_Symbols);
   end record;

   --  E-step bundle (scaled forward–backward).
   type E_Step_Result
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
      Scales         : Scale_Vector (1 .. Length) := [others => 1.0];
      Xi             : Xi_Table
        (1 .. Xi_Last, 1 .. N_States, 1 .. N_States) :=
        [others => [others => [others => 0.0]]];
      Has_Xi         : Boolean := False;
   end record;

   type Log_History is array (Positive range <>) of Log_Probability;

   type Fit_Result
     (N_States    : State_Count;
      N_Symbols   : Symbol_Count;
      History_Len : Natural)
   is record
      Model          : HMM (N_States, N_Symbols);
      Iterations     : Natural := 0;
      Log_Likelihood : Log_Probability := 0.0;
      Converged      : Boolean := False;
      History        : Log_History (1 .. History_Len) := [others => 0.0];
   end record;

   --  Multiple observation sequences (Wikipedia pooling).
   type Sequence_Lengths is array (Seq_Index range <>) of Time_Count;
   type Sequence_Data is
     array (Seq_Index range <>, Time_Index range <>) of Symbol_Index;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;
   Did_Not_Converge    : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   Log_Zero    : constant Log_Probability := -1.0E30;
   Prob_Tol    : constant Real := 1.0E-6;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Log (X : Real) return Log_Probability
     with Global => null;

   function Exp (X : Log_Probability) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- HMM validation / normalization
   ---------------------------------------------------------------------------

   function Row_Stochastic
     (Row : Initial_Vector; Tol : Real := Prob_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Valid_HMM
     (Model              : HMM;
      Tol                : Real := Prob_Tol;
      Require_Stochastic : Boolean := True) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   procedure Normalize_Rows (Model : in out HMM)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Likelihood (scaled forward)
   ---------------------------------------------------------------------------

   function Likelihood
     (Model : HMM;
      Obs   : Observation_Sequence) return Real
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;

   function Log_Likelihood
     (Model : HMM;
      Obs   : Observation_Sequence) return Log_Probability
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;

   ---------------------------------------------------------------------------
   -- E-step (scaled forward–backward → γ, ξ)
   ---------------------------------------------------------------------------

   function E_Step
     (Model   : HMM;
      Obs     : Observation_Sequence;
      Fill_Xi : Boolean := True) return E_Step_Result
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;

   ---------------------------------------------------------------------------
   -- M-step / EM
   ---------------------------------------------------------------------------

   function Baum_Welch_Step
     (Model : HMM;
      Obs   : Observation_Sequence) return HMM
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Post => Baum_Welch_Step'Result.N_States = Model.N_States
            and then Baum_Welch_Step'Result.N_Symbols = Model.N_Symbols,
          Global => null;
   --  One EM iteration (E-step + Rabiner / Wikipedia M-step updates).

   function Baum_Welch_Fit
     (Init_Model         : HMM;
      Obs                : Observation_Sequence;
      Max_Iter           : Positive := 100;
      Tol                : Real := 1.0E-6;
      Keep_History       : Boolean := True;
      Raise_On_No_Conv   : Boolean := False) return Fit_Result
     with Pre => Init_Model.N_States >= 1
       and then Init_Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time
       and then Tol >= 0.0
       and then Max_Iter <= Max_History,
          Global => null;
   --  Iterate until |Δ log L| < Tol or Max_Iter. Converged flag set
   --  accordingly; optionally raise Did_Not_Converge.

   function Baum_Welch_Fit_Multi
     (Init_Model         : HMM;
      Data               : Sequence_Data;
      Lengths            : Sequence_Lengths;
      Max_Iter           : Positive := 100;
      Tol                : Real := 1.0E-6;
      Keep_History       : Boolean := True;
      Raise_On_No_Conv   : Boolean := False) return Fit_Result
     with Pre => Init_Model.N_States >= 1
       and then Init_Model.N_Symbols >= 1
       and then Lengths'Length >= 1
       and then Lengths'Length <= Max_Sequences
       and then Data'Length (1) = Lengths'Length
       and then Tol >= 0.0
       and then Max_Iter <= Max_History,
          Global => null;
   --  Wikipedia multi-sequence pooling of γ / ξ across sequences.

   ---------------------------------------------------------------------------
   -- Initialization / sampling / fixtures
   ---------------------------------------------------------------------------

   function Random_Init_HMM
     (N_States  : State_Count;
      N_Symbols : Symbol_Count;
      Seed      : Natural) return HMM
     with Pre => N_States >= 1
       and then N_Symbols >= 1
       and then N_States <= Max_States
       and then N_Symbols <= Max_Symbols,
          Post => Random_Init_HMM'Result.N_States = N_States
            and then Random_Init_HMM'Result.N_Symbols = N_Symbols,
          Global => null;
   --  Seeded RNG → reproducible random row-stochastic π, A, B.

   function Sample_Observations
     (Model : HMM;
      T     : Time_Count;
      Seed  : Natural) return Observation_Sequence
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then T >= 1
       and then T <= Max_Time,
          Post => Sample_Observations'Result'Length = T,
          Global => null;
   --  Sample a length-T observation sequence from Model (seeded).

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

   ---------------------------------------------------------------------------
   -- Distance helpers (tests / diagnostics)
   ---------------------------------------------------------------------------

   function Frobenius_Trans (A, B : Transition_Matrix) return Real
     with Pre => A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Frobenius_Emit (A, B : Emission_Matrix) return Real
     with Pre => A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Max_Abs_Trans (A, B : Transition_Matrix) return Real
     with Pre => A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Max_Abs_Emit (A, B : Emission_Matrix) return Real
     with Pre => A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

end Baum_Welch;
