package Pulse_Coupled_Networks is

   --  Strong typing for all algorithm parameters and values
   type Real is new Long_Float;
   type Dimension is new Positive;
   
   type Real_Matrix is array (Dimension range <>, Dimension range <>) of Real;
   type Binary_Matrix is array (Dimension range <>, Dimension range <>) of Boolean;

   --  Offset used for 3x3 convolution kernels (center is 0,0)
   type Offset is range -1 .. 1;
   type Kernel_Matrix is array (Offset, Offset) of Real;

   --  Parameters controlling the Pulse-Coupled Neural Network dynamics
   type PCNN_Parameters is record
      Decay_F     : Real; -- corresponds to e^(-Alpha_F), decay factor for feeding
      Decay_L     : Real; -- corresponds to e^(-Alpha_L), decay factor for linking
      Decay_Theta : Real; -- corresponds to e^(-Alpha_Theta), decay factor for threshold
      V_F         : Real; -- Amplitude constant for feeding from neighbors
      V_L         : Real; -- Amplitude constant for linking from neighbors
      V_Theta     : Real; -- Threshold step constant when neuron fires
      Beta        : Real; -- Linking strength on internal activity
   end record;

   --  State of the neural network
   type PCNN_State (Rows, Cols : Dimension) is record
      F     : Real_Matrix (1 .. Rows, 1 .. Cols); -- Feeding compartment
      L     : Real_Matrix (1 .. Rows, 1 .. Cols); -- Linking compartment
      U     : Real_Matrix (1 .. Rows, 1 .. Cols); -- Internal activity
      Theta : Real_Matrix (1 .. Rows, 1 .. Cols); -- Dynamic threshold
      Y     : Binary_Matrix (1 .. Rows, 1 .. Cols); -- Output pulses
   end record;

   --  Exception raised when the stimulus dimensions do not match the state
   Dimension_Mismatch : exception;

   --  Initialize the PCNN state with zeros and a given initial threshold
   function Create_State (Rows, Cols : Dimension; Init_Theta : Real) return PCNN_State
     with Post => Create_State'Result.Rows = Rows and
                  Create_State'Result.Cols = Cols;

   --  Iterate the standard PCNN model by one step.
   --  This variant includes temporal decay for the feeding compartment F, 
   --  and incorporates neighboring pulses via the feeding kernel M.
   procedure Iterate_Standard
     (State    : in out PCNN_State;
      Stimulus : in     Real_Matrix;
      Params   : in     PCNN_Parameters;
      M        : in     Kernel_Matrix;
      W        : in     Kernel_Matrix)
     with Pre => Stimulus'First (1) = 1 and Stimulus'Last (1) = State.Rows and
                 Stimulus'First (2) = 1 and Stimulus'Last (2) = State.Cols;

   --  Iterate the simplified Unit-Linking PCNN model by one step.
   --  In this variant (often used for image processing to save computation), 
   --  F is strictly equal to the stimulus (no decay, no neighbor feeding).
   procedure Iterate_Simplified
     (State    : in out PCNN_State;
      Stimulus : in     Real_Matrix;
      Params   : in     PCNN_Parameters;
      W        : in     Kernel_Matrix)
     with Pre => Stimulus'First (1) = 1 and Stimulus'Last (1) = State.Rows and
                 Stimulus'First (2) = 1 and Stimulus'Last (2) = State.Cols;

   --  Helper: Compute the sum of a kernel applied to a binary matrix at a specific location
   function Convolve
     (Y : in Binary_Matrix;
      K : in Kernel_Matrix;
      R : in Dimension;
      C : in Dimension) return Real;

end Pulse_Coupled_Networks;
