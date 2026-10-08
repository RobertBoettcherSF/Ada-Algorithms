package Hopfield_Network is
   pragma Pure;

   -- Domain types for strong typing
   type Node_Index is new Positive;
   type Pattern_Index is new Positive;

   -- Core weight matrix type
   type Weight_Matrix is array (Node_Index range <>, Node_Index range <>) of Float;

   -----------------------------------------------------------------------------
   -- DISCRETE HOPFIELD NETWORK
   -----------------------------------------------------------------------------
   
   -- Discrete state vector and pattern matrix (expected to be -1 or 1)
   type Discrete_Vector is array (Node_Index range <>) of Integer;
   type Discrete_Pattern_Matrix is array (Pattern_Index range <>, Node_Index range <>) of Integer;

   -- Validation Helpers for Discrete Preconditions
   function Is_Valid_Bipolar (V : Discrete_Vector) return Boolean;
   function Is_Valid_Bipolar_Matrix (M : Discrete_Pattern_Matrix) return Boolean;
   function Is_Square (W : Weight_Matrix) return Boolean;

   -- Train the Discrete Hopfield Network using Hebbian Learning
   -- Weight w_ij = (1/N) * sum_p (x_i^p * x_j^p), w_ii = 0
   function Train_Discrete (Patterns : Discrete_Pattern_Matrix) return Weight_Matrix
     with Pre => Patterns'Length (1) > 0 and 
                 Patterns'Length (2) > 0 and 
                 Is_Valid_Bipolar_Matrix (Patterns),
          Post => Is_Square (Train_Discrete'Result) and 
                  Train_Discrete'Result'Length (1) = Patterns'Length (2);

   -- Synchronous Update: all nodes update their state simultaneously
   procedure Update_Discrete_Synchronous
     (Weights : in Weight_Matrix;
      State   : in out Discrete_Vector)
     with Pre => Is_Square (Weights) and 
                 Weights'Length (1) = State'Length and 
                 Is_Valid_Bipolar (State),
          Post => Is_Valid_Bipolar (State);

   -- Asynchronous Update: a single selected node updates its state
   procedure Update_Discrete_Asynchronous
     (Weights : in Weight_Matrix;
      State   : in out Discrete_Vector;
      Node    : in Node_Index)
     with Pre => Is_Square (Weights) and 
                 Weights'Length (1) = State'Length and 
                 Is_Valid_Bipolar (State) and 
                 Node in State'Range,
          Post => Is_Valid_Bipolar (State);

   -- Computes the Energy function for the discrete network
   -- E = -0.5 * sum_i sum_j (w_ij * s_i * s_j)
   function Energy_Discrete (Weights : Weight_Matrix; State : Discrete_Vector) return Float
     with Pre => Is_Square (Weights) and 
                 Weights'Length (1) = State'Length and 
                 Is_Valid_Bipolar (State);

   -----------------------------------------------------------------------------
   -- CONTINUOUS HOPFIELD NETWORK
   -----------------------------------------------------------------------------

   -- Continuous pattern matrix for training continuous weights
   type Continuous_Vector is array (Node_Index range <>) of Float;
   type Continuous_Pattern_Matrix is array (Pattern_Index range <>, Node_Index range <>) of Float;

   -- Node representation for Continuous dynamics
   type Continuous_Node is record
      U : Float := 0.0; -- Internal state (membrane potential)
      V : Float := 0.0; -- Output state (Activation: tanh(beta * U))
   end record;

   type Continuous_State is array (Node_Index range <>) of Continuous_Node;

   -- Train the Continuous Hopfield Network
   function Train_Continuous (Patterns : Continuous_Pattern_Matrix) return Weight_Matrix
     with Pre => Patterns'Length (1) > 0 and 
                 Patterns'Length (2) > 0,
          Post => Is_Square (Train_Continuous'Result) and 
                  Train_Continuous'Result'Length (1) = Patterns'Length (2);

   -- Synchronous Update using an Euler integration step for the continuous equations
   procedure Update_Continuous_Synchronous
     (Weights : in Weight_Matrix;
      State   : in out Continuous_State;
      Dt      : in Float;
      Beta    : in Float := 1.0)
     with Pre => Is_Square (Weights) and 
                 Weights'Length (1) = State'Length and 
                 Dt > 0.0;

   -- Computes the simplified Energy function for the continuous network
   -- (Ignoring the integral term which is negligible at high Beta)
   function Energy_Continuous (Weights : Weight_Matrix; State : Continuous_State) return Float
     with Pre => Is_Square (Weights) and 
                 Weights'Length (1) = State'Length;

end Hopfield_Network;
