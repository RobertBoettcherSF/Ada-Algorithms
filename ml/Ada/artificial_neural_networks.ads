with Ada.Containers.Indefinite_Vectors;

package Artificial_Neural_Networks is

   -- Domain-specific strong typing
   type Real is digits 15;
   
   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;

   type Activation_Function is (Sigmoid, Tanh, ReLU, Linear);

   -- Exceptions for error handling and invariants
   Dimension_Mismatch : exception;
   Empty_Network      : exception;

   -----------------------------------------------------------------------------
   -- Layer Definition
   -----------------------------------------------------------------------------
   
   type Layer (Inputs, Outputs : Positive) is private;

   -- Creates a new hidden or output layer. 
   -- Weights and biases are initialized to zero by default.
   function Create_Layer
     (Inputs     : Positive;
      Outputs    : Positive;
      Activation : Activation_Function := Sigmoid) return Layer
     with Post => Create_Layer'Result.Inputs = Inputs and 
                  Create_Layer'Result.Outputs = Outputs;

   -- Manually overrides the weights and biases of a layer.
   procedure Set_Weights (L : in out Layer; W : Matrix; B : Vector)
     with Pre => W'Length (1) = L.Inputs and 
                 W'Length (2) = L.Outputs and 
                 B'Length = L.Outputs;

   -- Accessors for layer properties
   function Get_Weight (L : Layer; Row, Col : Positive) return Real
     with Pre => Row <= L.Inputs and Col <= L.Outputs;
     
   function Get_Bias (L : Layer; Index : Positive) return Real
     with Pre => Index <= L.Outputs;

   -----------------------------------------------------------------------------
   -- Network Definition
   -----------------------------------------------------------------------------

   type Network is private;

   -- Appends a layer sequentially to the network.
   -- Enforces that L.Inputs matches the Outputs of the previously added layer.
   procedure Add_Layer (Net : in out Network; L : Layer);

   -- Randomizes all weights and biases in the network (critical before training).
   procedure Initialize_Random (Net : in out Network);

   -- Returns the number of layers in the network.
   function Layer_Count (Net : Network) return Natural
     with Global => null;

   -- Inspect a specific layer (Index: 1 to Layer_Count)
   function Get_Layer (Net : Network; Index : Positive) return Layer
     with Pre => Index <= Layer_Count (Net);

   -----------------------------------------------------------------------------
   -- Inference & Training Variants
   -----------------------------------------------------------------------------

   -- Variant 1: Feedforward Neural Network (Inference)
   function Predict (Net : Network; Input : Vector) return Vector;

   -- Variant 2: Backpropagation with Stochastic Gradient Descent (Training)
   procedure Train_Single
     (Net           : in out Network;
      Input         : Vector;
      Target        : Vector;
      Learning_Rate : Real)
     with Pre => Learning_Rate > 0.0;

   -----------------------------------------------------------------------------
   -- Loss & Activation Helper Functions (Exposed for isolated testing)
   -----------------------------------------------------------------------------
   
   -- Mean Squared Error logic
   function Mean_Squared_Error (Prediction, Target : Vector) return Real;

   -- Activation application variant logic
   function Apply_Activation (X : Real; Act : Activation_Function) return Real
     with Global => null;
     
   function Apply_Derivative (Z : Real; Act : Activation_Function) return Real
     with Global => null;

private
   type Layer (Inputs, Outputs : Positive) is record
      Weights    : Matrix (1 .. Inputs, 1 .. Outputs) := [others => [others => 0.0]];
      Biases     : Vector (1 .. Outputs) := [others => 0.0];
      Activation : Activation_Function := Sigmoid;
   end record;

   package Layer_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type => Positive, Element_Type => Layer);

   type Network is record
      Layers : Layer_Vectors.Vector;
   end record;

end Artificial_Neural_Networks;
