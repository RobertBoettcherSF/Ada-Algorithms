package Amplitude_Amplification is

   -- Domain types to ensure strong typing
   type State_Index is new Integer;
   type Amplitude is new Long_Float;

   -- A quantum state vector represented classically as an array of probability amplitudes
   type State_Vector is array (State_Index range <>) of Amplitude;

   -- Oracle function type: returns True if the given state index is a target/solution
   type Oracle_Function is access function (Index : State_Index) return Boolean;

   -- Exceptions for invalid inputs and search failures
   Invalid_State_Error : exception;
   No_Solution_Error   : exception;

   -- Verifies if the state vector is normalized (sum of squared amplitudes = 1.0)
   function Is_Normalized (State : State_Vector) return Boolean
     with Global => null;

   -- Computes the inner product (dot product) between two state vectors
   function Inner_Product (Left, Right : State_Vector) return Amplitude
     with Global => null,
          Pre    => Left'Length = Right'Length and then Left'First = Right'First;

   -- Applies the Oracle phase flip to states that evaluate to True via the oracle
   procedure Apply_Oracle (State : in out State_Vector; Oracle : not null access function (Index : State_Index) return Boolean)
     with Post => Is_Normalized (State);

   -- Applies the Diffusion operator (inversion about the mean/initial state)
   procedure Apply_Diffusion (State : in out State_Vector; Initial_State : State_Vector)
     with Pre  => State'Length = Initial_State'Length and then State'First = Initial_State'First,
          Post => Is_Normalized (State);

   -- Variant 1: Standard Amplitude Amplification (Grover-like)
   -- Applies a predetermined, fixed number of amplification iterations.
   function Standard_Amplification
     (Initial_State : State_Vector;
      Oracle        : not null access function (Index : State_Index) return Boolean;
      Iterations    : Natural) return State_Vector
     with Pre  => Is_Normalized (Initial_State),
          Post => Is_Normalized (Standard_Amplification'Result);

   -- Calculates the mathematically optimal number of iterations given an initial success probability
   function Optimal_Iterations (Success_Probability : Amplitude) return Natural
     with Global => null,
          Pre    => Success_Probability > 0.0 and then Success_Probability <= 1.0;

   -- Variant 2: Amplitude Amplification with Unknown Success Probability (Exponential Search)
   -- Dynamically schedules iterations to find a solution when the number of target states is unknown.
   function Exponential_Search
     (Initial_State : State_Vector;
      Oracle        : not null access function (Index : State_Index) return Boolean;
      Max_Steps     : Natural := 1000) return State_Index
     with Pre => Is_Normalized (Initial_State);

   -- Helper: Creates a uniform superposition state over a given range
   function Uniform_Superposition (First, Last : State_Index) return State_Vector
     with Global => null,
          Pre    => First <= Last,
          Post   => Is_Normalized (Uniform_Superposition'Result);

   -- Helper: Simulates quantum measurement by finding the state index with the highest amplitude
   function Measure_Most_Likely (State : State_Vector) return State_Index
     with Global => null,
          Pre    => State'Length > 0;

end Amplitude_Amplification;
