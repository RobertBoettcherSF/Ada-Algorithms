--  Hidden_Markov_Model — Ada 2023 educational survey / umbrella for
--  Wikipedia "Hidden Markov model": discrete HMM definition, sampling,
--  likelihood (scaled forward), filtering / smoothing (forward–backward),
--  most likely path (Viterbi), and parameter learning (Baum–Welch EM).
--  Compact self-contained embeddings; deeper siblings are Ada-Viterbi,
--  Ada-Forward-Backward, Ada-Baum-Welch (not dependencies).

pragma Ada_2022;

package Hidden_Markov_Model
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Probability is Non_Negative;
   subtype Log_Probability is Real;

   Max_States  : constant Positive := 64;
   Max_Symbols : constant Positive := 64;
   Max_Time    : constant Positive := 1024;
   Max_History : constant Positive := 256;

   subtype State_Count  is Natural  range 0 .. Max_States;
   subtype Symbol_Count is Natural  range 0 .. Max_Symbols;
   subtype Time_Count   is Natural  range 0 .. Max_Time;

   subtype State_Index  is Positive range 1 .. Max_States;
   subtype Symbol_Index is Positive range 1 .. Max_Symbols;
   subtype Time_Index   is Positive range 1 .. Max_Time;

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

   type Prob_Table is
     array (Time_Index range <>, State_Index range <>) of Real;

   type Backpointer_Table is
     array (Time_Index range <>, State_Index range <>) of Natural;

   type HMM (N_States : State_Count; N_Symbols : Symbol_Count) is record
      Init  : Initial_Vector (1 .. N_States);
      Trans : Transition_Matrix (1 .. N_States, 1 .. N_States);
      Emit  : Emission_Matrix (1 .. N_States, 1 .. N_Symbols);
   end record;

   --  Scaled forward–backward bundle (smoothing / E-step core).
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
      Scales         : Scale_Vector (1 .. Length) := [others => 1.0];
      Xi             : Xi_Table
        (1 .. Xi_Last, 1 .. N_States, 1 .. N_States) :=
        [others => [others => [others => 0.0]]];
      Has_Xi         : Boolean := False;
   end record;

   type Viterbi_Result (Length : Time_Count; N_States : State_Count) is record
      Path             : State_Sequence (1 .. Length);
      Log_Probability  : Hidden_Markov_Model.Log_Probability := 0.0;
      Probability      : Real := 0.0;
      Has_Table        : Boolean := False;
      Prob_Table       : Hidden_Markov_Model.Prob_Table
        (1 .. Length, 1 .. N_States) :=
        [others => [others => 0.0]];
      Backpointers     : Backpointer_Table (1 .. Length, 1 .. N_States) :=
        [others => [others => 0]];
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
   -- Model validation / fixtures
   ---------------------------------------------------------------------------

   function Is_Valid_HMM
     (Model              : HMM;
      Tol                : Real := Prob_Tol;
      Require_Stochastic : Boolean := True) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   procedure Normalize_Rows (Model : in out HMM)
     with Global => null;

   Healthy : constant State_Index  := 1;
   Fever   : constant State_Index  := 2;
   Normal  : constant Symbol_Index := 1;
   Cold    : constant Symbol_Index := 2;
   Dizzy   : constant Symbol_Index := 3;

   function Make_Doctor_Fever_HMM return HMM
     with Global => null,
          Post => Make_Doctor_Fever_HMM'Result.N_States = 2
            and then Make_Doctor_Fever_HMM'Result.N_Symbols = 3;

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

   ---------------------------------------------------------------------------
   -- Generation
   ---------------------------------------------------------------------------

   function Sample_Path
     (Model : HMM;
      T     : Time_Count;
      Seed  : Natural) return State_Sequence
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then T >= 1
       and then T <= Max_Time,
          Post => Sample_Path'Result'Length = T,
          Global => null;

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

   ---------------------------------------------------------------------------
   -- Likelihood / filtering
   ---------------------------------------------------------------------------

   function Log_Likelihood
     (Model : HMM;
      Obs   : Observation_Sequence) return Log_Probability
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;

   function Likelihood
     (Model : HMM;
      Obs   : Observation_Sequence) return Real
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;

   function Filter
     (Model : HMM;
      Obs   : Observation_Sequence) return Posterior_Table
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  Filtered P(X_t | o_1:t) = scaled α_t (Rabiner c_t).

   ---------------------------------------------------------------------------
   -- Smoothing
   ---------------------------------------------------------------------------

   function Smooth
     (Model : HMM;
      Obs   : Observation_Sequence) return Posterior_Table
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;

   function Forward_Backward
     (Model   : HMM;
      Obs     : Observation_Sequence;
      Fill_Xi : Boolean := True) return FB_Result
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;
   --  Scaled forward–backward; Gamma rows are true posteriors.

   function Posterior_Mode_Path
     (Gamma : Posterior_Table) return State_Sequence
     with Pre => Gamma'Length (1) >= 1 and then Gamma'Length (2) >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Most likely explanation (Viterbi)
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

   function Log_Path_Probability
     (Model : HMM;
      Obs   : Observation_Sequence;
      Path  : State_Sequence) return Log_Probability
     with Pre => Obs'Length = Path'Length
       and then Obs'Length >= 1
       and then Model.N_States >= 1
       and then Model.N_Symbols >= 1,
          Global => null;

   function Viterbi_Decode
     (Model      : HMM;
      Obs        : Observation_Sequence;
      Fill_Table : Boolean := True) return Viterbi_Result
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;

   function Viterbi_Decode_Log
     (Model      : HMM;
      Obs        : Observation_Sequence;
      Fill_Table : Boolean := True) return Viterbi_Result
     with Pre => Model.N_States >= 1
       and then Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time,
          Global => null;

   ---------------------------------------------------------------------------
   -- Learning (Baum–Welch EM)
   ---------------------------------------------------------------------------

   function Baum_Welch_Fit
     (Init_Model       : HMM;
      Obs              : Observation_Sequence;
      Max_Iter         : Positive := 100;
      Tol              : Real := 1.0E-6;
      Keep_History     : Boolean := True;
      Raise_On_No_Conv : Boolean := False) return Fit_Result
     with Pre => Init_Model.N_States >= 1
       and then Init_Model.N_Symbols >= 1
       and then Obs'Length >= 1
       and then Obs'Length <= Max_Time
       and then Tol >= 0.0
       and then Max_Iter <= Max_History,
          Global => null;

end Hidden_Markov_Model;
