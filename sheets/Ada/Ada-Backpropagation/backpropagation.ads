package Backpropagation
  with SPARK_Mode => On
is

   -- Using a custom floating-point type for strict typing and domain specificity
   type Real is digits 6;
   subtype Dimension is Positive;

   type Vector is array (Dimension range <>) of Real;
   type Matrix is array (Dimension range <>, Dimension range <>) of Real;

   type Activation_Function is (Sigmoid, ReLU, Tanh, Linear);

   -- A feed-forward Neural Network with 1 hidden layer
   type Neural_Network (Inputs, Hiddens, Outputs : Dimension) is record
      W1  : Matrix (1 .. Hiddens, 1 .. Inputs);
      B1  : Vector (1 .. Hiddens);
      W2  : Matrix (1 .. Outputs, 1 .. Hiddens);
      B2  : Vector (1 .. Outputs);
      Act : Activation_Function := Sigmoid;
   end record;

   -- Intermediate state computed during the forward pass, needed for backpropagation
   type Network_State (Inputs, Hiddens, Outputs : Dimension) is record
      A0 : Vector (1 .. Inputs);
      Z1 : Vector (1 .. Hiddens);
      A1 : Vector (1 .. Hiddens);
      Z2 : Vector (1 .. Outputs);
      A2 : Vector (1 .. Outputs);
   end record;

   -- Gradients computed during the backward pass
   type Network_Gradients (Inputs, Hiddens, Outputs : Dimension) is record
      DW1 : Matrix (1 .. Hiddens, 1 .. Inputs);
      DB1 : Vector (1 .. Hiddens);
      DW2 : Matrix (1 .. Outputs, 1 .. Hiddens);
      DB2 : Vector (1 .. Outputs);
   end record;

   -- Exception raised when vectors/matrices do not match network dimensions
   Dimension_Error : exception;

   -- Initializes the network with small random weights (Xavier-like initialization)
   function Create_Network
     (Inputs, Hiddens, Outputs : Dimension;
      Act                      : Activation_Function) return Neural_Network
     with SPARK_Mode => Off,
          Post => Create_Network'Result.Inputs = Inputs
                  and Create_Network'Result.Hiddens = Hiddens
                  and Create_Network'Result.Outputs = Outputs;

   -- Performs the forward pass, outputting the intermediate state
   procedure Forward
     (Net   : Neural_Network;
      Input : Vector;
      State : out Network_State)
     with SPARK_Mode => Off,
          Pre => Input'Length = Net.Inputs
                 and Input'First = 1
                 and State.Inputs = Net.Inputs
                 and State.Hiddens = Net.Hiddens
                 and State.Outputs = Net.Outputs;

   -- Calculates Mean Squared Error loss between prediction and target
   function Compute_Loss (Prediction, Target : Vector) return Real
     with SPARK_Mode => Off,
          Pre => Prediction'Length = Target'Length
                 and Prediction'First = 1
                 and Target'First = 1;

   -- Performs the backward pass (backpropagation) to calculate gradients
   procedure Backward
     (Net    : Neural_Network;
      State  : Network_State;
      Target : Vector;
      Grads  : out Network_Gradients)
     with SPARK_Mode => Off,
          Pre => Target'Length = Net.Outputs
                 and Target'First = 1
                 and State.Inputs = Net.Inputs
                 and Grads.Inputs = Net.Inputs;

   -- Zeros out all gradients
   procedure Zero_Gradients (Grads : out Network_Gradients);

   -- Accumulates gradients for mini-batch or batch gradient descent
   procedure Accumulate_Gradients
     (Total_Grads : in out Network_Gradients;
      New_Grads   : Network_Gradients)
     with SPARK_Mode => Off,
          Pre => Total_Grads.Inputs = New_Grads.Inputs
                 and Total_Grads.Hiddens = New_Grads.Hiddens
                 and Total_Grads.Outputs = New_Grads.Outputs;

   -- Standard Stochastic Gradient Descent (SGD) weight update
   procedure Update_Weights
     (Net           : in out Neural_Network;
      Grads         : Network_Gradients;
      Learning_Rate : Real)
     with SPARK_Mode => Off,
          Pre => Net.Inputs = Grads.Inputs
                 and Net.Hiddens = Grads.Hiddens
                 and Net.Outputs = Grads.Outputs;

   -- Momentum-based Gradient Descent weight update
   procedure Update_Weights_Momentum
     (Net           : in out Neural_Network;
      Grads         : Network_Gradients;
      Velocity      : in out Network_Gradients;
      Learning_Rate : Real;
      Momentum      : Real)
     with SPARK_Mode => Off,
          Pre => Net.Inputs = Grads.Inputs
                 and Net.Inputs = Velocity.Inputs
                 and Net.Hiddens = Grads.Hiddens
                 and Net.Hiddens = Velocity.Hiddens
                 and Net.Outputs = Grads.Outputs
                 and Net.Outputs = Velocity.Outputs;

end Backpropagation;
