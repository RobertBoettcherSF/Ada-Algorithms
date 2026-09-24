with Ada.Numerics.Float_Random;
with Ada.Numerics.Generic_Elementary_Functions;

package body Backpropagation
  with SPARK_Mode => On
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   -- Random generator for weight initialization
   Gen : Ada.Numerics.Float_Random.Generator;

   -----------------------------------------------------------------------------
   -- Helper: Applies the chosen activation function to a scalar
   -----------------------------------------------------------------------------
   function Apply_Activation (X : Real; Act : Activation_Function) return Real 
   with SPARK_Mode => Off is
   begin
      case Act is
         when Sigmoid => 
            return 1.0 / (1.0 + Exp (-X));
         when ReLU => 
            return (if X > 0.0 then X else 0.0);
         when Tanh => 
            return Math.Tanh (X);
         when Linear => 
            return X;
      end case;
   end Apply_Activation;

   -----------------------------------------------------------------------------
   -- Helper: Applies the derivative of the chosen activation function
   -----------------------------------------------------------------------------
   function Apply_Derivative (X, A : Real; Act : Activation_Function) return Real 
   with SPARK_Mode => Off is
   begin
      case Act is
         when Sigmoid => 
            return A * (1.0 - A);
         when ReLU => 
            return (if X > 0.0 then 1.0 else 0.0);
         when Tanh => 
            return 1.0 - (A * A);
         when Linear => 
            return 1.0;
      end case;
   end Apply_Derivative;

   -----------------------------------------------------------------------------
   -- Creates a new neural network with randomly initialized weights
   -----------------------------------------------------------------------------
   function Create_Network
     (Inputs, Hiddens, Outputs : Dimension;
      Act                      : Activation_Function) return Neural_Network
   with SPARK_Mode => Off
   is
      Net : Neural_Network (Inputs, Hiddens, Outputs);
      use Ada.Numerics.Float_Random;
   begin
      Net.Act := Act;
      
      -- Initialize W1 and B1
      for I in 1 .. Hiddens loop
         Net.B1 (I) := 0.0;
         for J in 1 .. Inputs loop
            -- Scale to approx [-1.0, 1.0] for initial weights
            Net.W1 (I, J) := Real (Random (Gen)) * 2.0 - 1.0;
         end loop;
      end loop;
      
      -- Initialize W2 and B2
      for I in 1 .. Outputs loop
         Net.B2 (I) := 0.0;
         for J in 1 .. Hiddens loop
            Net.W2 (I, J) := Real (Random (Gen)) * 2.0 - 1.0;
         end loop;
      end loop;
      
      return Net;
   end Create_Network;

   -----------------------------------------------------------------------------
   -- Forward Pass
   -----------------------------------------------------------------------------
   procedure Forward
     (Net   : Neural_Network;
      Input : Vector;
      State : out Network_State)
   with SPARK_Mode => Off
   is
   begin
      if Input'Length /= Net.Inputs or Input'First /= 1 then
         raise Dimension_Error with "Input vector dimensions mismatch";
      end if;
      
      if State.Inputs /= Net.Inputs or State.Hiddens /= Net.Hiddens or State.Outputs /= Net.Outputs then
         raise Dimension_Error with "State dimensions mismatch";
      end if;

      State.A0 := Input;

      -- Hidden Layer (Z1 = W1 * Input + B1)
      for I in 1 .. Net.Hiddens loop
         State.Z1 (I) := Net.B1 (I);
         for J in 1 .. Net.Inputs loop
            State.Z1 (I) := State.Z1 (I) + Net.W1 (I, J) * State.A0 (J);
         end loop;
         State.A1 (I) := Apply_Activation (State.Z1 (I), Net.Act);
      end loop;

      -- Output Layer (Z2 = W2 * A1 + B2)
      for I in 1 .. Net.Outputs loop
         State.Z2 (I) := Net.B2 (I);
         for J in 1 .. Net.Hiddens loop
            State.Z2 (I) := State.Z2 (I) + Net.W2 (I, J) * State.A1 (J);
         end loop;
         State.A2 (I) := Apply_Activation (State.Z2 (I), Net.Act);
      end loop;
   end Forward;

   -----------------------------------------------------------------------------
   -- Computes Mean Squared Error (MSE)
   -----------------------------------------------------------------------------
   function Compute_Loss (Prediction, Target : Vector) return Real 
   with SPARK_Mode => Off is
      Sum_Error : Real := 0.0;
      Diff      : Real;
   begin
      if Prediction'Length /= Target'Length or Prediction'First /= 1 or Target'First /= 1 then
         raise Dimension_Error with "Loss vectors mismatch";
      end if;

      for I in 1 .. Prediction'Length loop
         Diff := Prediction (I) - Target (I);
         Sum_Error := Sum_Error + (Diff * Diff);
      end loop;
      
      return Sum_Error / Real (Prediction'Length);
   end Compute_Loss;

   -----------------------------------------------------------------------------
   -- Backward Pass (Calculates Gradients via Chain Rule)
   -----------------------------------------------------------------------------
   procedure Backward
     (Net    : Neural_Network;
      State  : Network_State;
      Target : Vector;
      Grads  : out Network_Gradients)
   with SPARK_Mode => Off
   is
      DZ2 : Vector (1 .. Net.Outputs);
      DA1 : Vector (1 .. Net.Hiddens);
      DZ1 : Vector (1 .. Net.Hiddens);
   begin
      if Target'Length /= Net.Outputs or Target'First /= 1 then
         raise Dimension_Error with "Target dimension mismatch";
      end if;
      
      if Grads.Inputs /= Net.Inputs or Grads.Hiddens /= Net.Hiddens or Grads.Outputs /= Net.Outputs then
         raise Dimension_Error with "Gradients dimension mismatch";
      end if;

      -- 1. Output Layer Errors
      for I in 1 .. Net.Outputs loop
         -- MSE derivative w.r.t Activation: (A2 - Target)
         -- Chain rule: dZ2 = dA2 * Activation'(Z2)
         DZ2 (I) := (State.A2 (I) - Target (I)) * Apply_Derivative (State.Z2 (I), State.A2 (I), Net.Act);
         
         -- Gradients for W2 and B2
         Grads.DB2 (I) := DZ2 (I);
         for J in 1 .. Net.Hiddens loop
            Grads.DW2 (I, J) := DZ2 (I) * State.A1 (J);
         end loop;
      end loop;

      -- 2. Hidden Layer Errors
      for J in 1 .. Net.Hiddens loop
         DA1 (J) := 0.0;
         -- Backpropagate error from output layer (W2^T * DZ2)
         for I in 1 .. Net.Outputs loop
            DA1 (J) := DA1 (J) + Net.W2 (I, J) * DZ2 (I);
         end loop;
         
         DZ1 (J) := DA1 (J) * Apply_Derivative (State.Z1 (J), State.A1 (J), Net.Act);
         
         -- Gradients for W1 and B1
         Grads.DB1 (J) := DZ1 (J);
         for K in 1 .. Net.Inputs loop
            Grads.DW1 (J, K) := DZ1 (J) * State.A0 (K);
         end loop;
      end loop;
   end Backward;

   -----------------------------------------------------------------------------
   -- Zeroes out a Gradients structure
   -----------------------------------------------------------------------------
   procedure Zero_Gradients (Grads : out Network_Gradients) is
   begin
      Grads.DW1 := [others => [others => 0.0]];
      Grads.DB1 := [others => 0.0];
      Grads.DW2 := [others => [others => 0.0]];
      Grads.DB2 := [others => 0.0];
   end Zero_Gradients;

   -----------------------------------------------------------------------------
   -- Accumulate Gradients for Mini-batch
   -----------------------------------------------------------------------------
   procedure Accumulate_Gradients
     (Total_Grads : in out Network_Gradients;
      New_Grads   : Network_Gradients)
   with SPARK_Mode => Off
   is
   begin
      if Total_Grads.Inputs /= New_Grads.Inputs 
        or else Total_Grads.Hiddens /= New_Grads.Hiddens 
        or else Total_Grads.Outputs /= New_Grads.Outputs 
      then
         raise Dimension_Error with "Accumulation gradients dimension mismatch";
      end if;

      for I in 1 .. Total_Grads.Hiddens loop
         Total_Grads.DB1 (I) := Total_Grads.DB1 (I) + New_Grads.DB1 (I);
         for J in 1 .. Total_Grads.Inputs loop
            Total_Grads.DW1 (I, J) := Total_Grads.DW1 (I, J) + New_Grads.DW1 (I, J);
         end loop;
      end loop;

      for I in 1 .. Total_Grads.Outputs loop
         Total_Grads.DB2 (I) := Total_Grads.DB2 (I) + New_Grads.DB2 (I);
         for J in 1 .. Total_Grads.Hiddens loop
            Total_Grads.DW2 (I, J) := Total_Grads.DW2 (I, J) + New_Grads.DW2 (I, J);
         end loop;
      end loop;
   end Accumulate_Gradients;

   -----------------------------------------------------------------------------
   -- Standard SGD Update
   -----------------------------------------------------------------------------
   procedure Update_Weights
     (Net           : in out Neural_Network;
      Grads         : Network_Gradients;
      Learning_Rate : Real)
   with SPARK_Mode => Off
   is
   begin
      if Net.Inputs /= Grads.Inputs 
        or else Net.Hiddens /= Grads.Hiddens 
        or else Net.Outputs /= Grads.Outputs 
      then
         raise Dimension_Error with "Network and Gradients dimension mismatch";
      end if;

      for I in 1 .. Net.Hiddens loop
         Net.B1 (I) := Net.B1 (I) - Learning_Rate * Grads.DB1 (I);
         for J in 1 .. Net.Inputs loop
            Net.W1 (I, J) := Net.W1 (I, J) - Learning_Rate * Grads.DW1 (I, J);
         end loop;
      end loop;

      for I in 1 .. Net.Outputs loop
         Net.B2 (I) := Net.B2 (I) - Learning_Rate * Grads.DB2 (I);
         for J in 1 .. Net.Hiddens loop
            Net.W2 (I, J) := Net.W2 (I, J) - Learning_Rate * Grads.DW2 (I, J);
         end loop;
      end loop;
   end Update_Weights;

   -----------------------------------------------------------------------------
   -- Momentum Update
   -----------------------------------------------------------------------------
   procedure Update_Weights_Momentum
     (Net           : in out Neural_Network;
      Grads         : Network_Gradients;
      Velocity      : in out Network_Gradients;
      Learning_Rate : Real;
      Momentum      : Real)
   with SPARK_Mode => Off
   is
   begin
      if Net.Inputs /= Grads.Inputs or else Net.Inputs /= Velocity.Inputs
        or else Net.Hiddens /= Grads.Hiddens or else Net.Hiddens /= Velocity.Hiddens
        or else Net.Outputs /= Grads.Outputs or else Net.Outputs /= Velocity.Outputs
      then
         raise Dimension_Error with "Network, Gradients, and Velocity dimension mismatch";
      end if;

      -- Update Layer 1
      for I in 1 .. Net.Hiddens loop
         Velocity.DB1 (I) := Momentum * Velocity.DB1 (I) + Learning_Rate * Grads.DB1 (I);
         Net.B1 (I) := Net.B1 (I) - Velocity.DB1 (I);
         for J in 1 .. Net.Inputs loop
            Velocity.DW1 (I, J) := Momentum * Velocity.DW1 (I, J) + Learning_Rate * Grads.DW1 (I, J);
            Net.W1 (I, J) := Net.W1 (I, J) - Velocity.DW1 (I, J);
         end loop;
      end loop;

      -- Update Layer 2
      for I in 1 .. Net.Outputs loop
         Velocity.DB2 (I) := Momentum * Velocity.DB2 (I) + Learning_Rate * Grads.DB2 (I);
         Net.B2 (I) := Net.B2 (I) - Velocity.DB2 (I);
         for J in 1 .. Net.Hiddens loop
            Velocity.DW2 (I, J) := Momentum * Velocity.DW2 (I, J) + Learning_Rate * Grads.DW2 (I, J);
            Net.W2 (I, J) := Net.W2 (I, J) - Velocity.DW2 (I, J);
         end loop;
      end loop;
   end Update_Weights_Momentum;

begin
   Ada.Numerics.Float_Random.Reset (Gen);
end Backpropagation;
