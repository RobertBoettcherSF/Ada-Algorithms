package Darwin_Godel_Machine is

   -- Strong domain types to prevent bare primitive misuse
   type Fitness_Value is new Float range 0.0 .. 10_000.0;
   type Complexity_Value is new Natural range 0 .. 100_000;
   
   type Environment_State is (Static_Env, Dynamic_Env);
   type Verification_Level is (None, Heuristic, Strict_Proof);

   -- Core genome representing an evolvable agent variant
   type Agent_State is record
      Id         : Positive;
      Fitness    : Fitness_Value;
      Complexity : Complexity_Value;
      Level      : Verification_Level;
   end record;

   type Agent_Array is array (Positive range <>) of Agent_State;

   -- Named exceptions for robust error handling
   Population_Empty_Error : exception;
   Invalid_Threshold      : exception;

   -- Creates a baseline agent code configuration
   function Create_Agent
     (Id   : Positive;
      Fit  : Fitness_Value;
      Comp : Complexity_Value) return Agent_State
     with Global => null,
          Post   => Create_Agent'Result.Id = Id and then
                    Create_Agent'Result.Fitness = Fit;

   -- Evaluates true agent fitness depending on the environment mode.
   function Evaluate (Agent : Agent_State; Env : Environment_State) return Fitness_Value
     with Global => null;

   -- =========================================================================
   -- VARIANT 1: GÖDEL VERIFICATION STEPS
   -- =========================================================================

   -- Strict: Candidate must provably increase fitness with bounded complexity
   function Verify_Strict (Base, Candidate : Agent_State; Env : Environment_State) return Boolean
     with Global => null;

   -- Heuristic: Candidate simply needs higher raw evaluation, unbounded complexity
   function Verify_Heuristic (Base, Candidate : Agent_State; Env : Environment_State) return Boolean
     with Global => null;


   -- =========================================================================
   -- VARIANT 2: DARWINIAN EVOLUTION STEPS
   -- =========================================================================

   -- Exhaustive (Non-preemptive): Assesses the entire variant population, returning 
   -- the absolute optimal agent that passes Strict Gödel verification.
   function Evolve_Exhaustive
     (Base       : Agent_State;
      Candidates : Agent_Array;
      Env        : Environment_State) return Agent_State
     with Global => null,
          Pre    => Candidates'Length >= 0;

   -- Preemptive: Operates dynamically, halting the evolutionary loop and returning 
   -- immediately at the first agent that satisfies Heuristic verification + a Threshold.
   function Evolve_Preemptive
     (Base       : Agent_State;
      Candidates : Agent_Array;
      Env        : Environment_State;
      Threshold  : Fitness_Value) return Agent_State
     with Global => null,
          Pre    => Candidates'Length >= 0;

   -- Helper validation for logical transition
   function Is_Valid_Transition (Base, Next : Agent_State) return Boolean
     with Global => null;

end Darwin_Godel_Machine;
