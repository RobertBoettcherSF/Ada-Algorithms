with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Numerics.Float_Random;
with Ada.Unchecked_Deallocation;

package body Artificial_Neural_Networks is

   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Real_Math;

   -- Internal vector memory management for backpropagation
   type Vector_Access is access all Vector;
   procedure Free is new Ada.Unchecked_Deallocation (Vector, Vector_Access);

   -----------------------------------------------------------------------------
   -- Helper Functions
   -----------------------------------------------------------------------------

   -- Normalizes vector indexing to strictly 1 .. Length to avoid Constraint_Error 
   -- when users provide subsets/slices (e.g., A(5 .. 10)).
   function Normalize (V : Vector) return Vector is
      Result : Vector (1 .. V'Length);
   begin
      for I in 1 .. V'Length loop
         Result (I) := V (V'First + I - 1);
      end loop;
      return Result;
   end Normalize;

   -- Prevents overflow in exponential calculations
   function Cap (X : Real; Limit : Real) return Real is
   begin
      if X > Limit then 
         return Limit;
      elsif X < -Limit then 
         return -Limit;
      else 
         return X;
      end if;
   end Cap;

   -----------------------------------------------------------------------------
   -- Activation Functions
   -----------------------------------------------------------------------------

   function Apply_Activation (X : Real; Act : Activation_Function) return Real is
   begin
      case Act is
         when Sigmoid =>
            return 1.0 / (1.0 + Exp (-Cap (X, 50.0)));
         when Tanh =>
            return Real_Math.Tanh (Cap (X, 50.0));
         when ReLU =>
            return (if X > 0.0 then X else 0.0);
         when Linear =>
            return X;
      end case;
   end Apply_Activation;

   function Apply_Derivative (Z : Real; Act : Activation_Function) return Real is
      S, T : Real;
   begin
      case Act is
         when Sigmoid =>
            S := Apply_Activation (Z, Sigmoid);
            return S * (1.0 - S);
         when Tanh =>
            T := Apply_Activation (Z, Tanh);
            return 1.0 - (T * T);
         when ReLU =>
            return (if Z > 0.0 then 1.0 else 0.0);
         when Linear =>
            return 1.0;
      end case;
   end Apply_Derivative;

   -----------------------------------------------------------------------------
   -- Loss Functions
   -----------------------------------------------------------------------------

   function Mean_Squared_Error (Prediction, Target : Vector) return Real is
      Norm_Pred   : constant Vector := Normalize (Prediction);
      Norm_Target : constant Vector := Normalize (Target);
      Sum         : Real := 0.0;
   begin
      if Norm_Pred'Length /= Norm_Target'Length then
         raise Dimension_Mismatch;
      end if;

      for I in Norm_Pred'Range loop
         Sum := Sum + (Norm_Pred (I) - Norm_Target (I)) ** 2;
      end loop;
      
      return Sum / Real (Norm_Pred'Length);
   end Mean_Squared_Error;

   -----------------------------------------------------------------------------
   -- Layer Management
   -----------------------------------------------------------------------------

   function Create_Layer
     (Inputs     : Positive;
      Outputs    : Positive;
      Activation : Activation_Function := Sigmoid) return Layer
   is
      Result : Layer (Inputs, Outputs);
   begin
      Result.Activation := Activation;
      return Result;
   end Create_Layer;

   procedure Set_Weights (L : in out Layer; W : Matrix; B : Vector) is
      Norm_B : constant Vector := Normalize (B);
   begin
      for R in 1 .. L.Inputs loop
         for C in 1 .. L.Outputs loop
            L.Weights (R, C) := W (W'First(1) + R - 1, W'First(2) + C - 1);
         end loop;
      end loop;
      L.Biases := Norm_B;
   end Set_Weights;

   function Get_Weight (L : Layer; Row, Col : Positive) return Real is
   begin
      return L.Weights (Row, Col);
   end Get_Weight;

   function Get_Bias (L : Layer; Index : Positive) return Real is
   begin
      return L.Biases (Index);
   end Get_Bias;

   -----------------------------------------------------------------------------
   -- Network Management
   -----------------------------------------------------------------------------

   procedure Add_Layer (Net : in out Network; L : Layer) is
   begin
      if not Net.Layers.Is_Empty then
         if Net.Layers.Last_Element.Outputs /= L.Inputs then
            raise Dimension_Mismatch;
         end if;
      end if;
      Net.Layers.Append (L);
   end Add_Layer;

   function Layer_Count (Net : Network) return Natural is
   begin
      return Natural (Net.Layers.Length);
   end Layer_Count;

   function Get_Layer (Net : Network; Index : Positive) return Layer is
   begin
      return Net.Layers.Element (Index);
   end Get_Layer;

   procedure Initialize_Random (Net : in out Network) is
      Gen : Ada.Numerics.Float_Random.Generator;
   begin
      Ada.Numerics.Float_Random.Reset (Gen);
      
      for I in 1 .. Natural (Net.Layers.Length) loop
         declare
            L : Layer := Net.Layers.Element (I);
         begin
            for R in 1 .. L.Inputs loop
               for C in 1 .. L.Outputs loop
                  -- Initialize weights strictly between -0.5 and 0.5
                  L.Weights (R, C) := Real (Ada.Numerics.Float_Random.Random (Gen)) - 0.5;
               end loop;
            end loop;
            
            for C in 1 .. L.Outputs loop
               L.Biases (C) := Real (Ada.Numerics.Float_Random.Random (Gen)) - 0.5;
            end loop;
            
            Net.Layers.Replace_Element (I, L);
         end;
      end loop;
   end Initialize_Random;

   -----------------------------------------------------------------------------
   -- Inference Variant (Feedforward Propagation)
   -----------------------------------------------------------------------------

   function Predict (Net : Network; Input : Vector) return Vector is
      Num_Layers : constant Natural := Natural (Net.Layers.Length);
   begin
      if Num_Layers = 0 then
         raise Empty_Network;
      end if;

      declare
         Norm_Input  : constant Vector := Normalize (Input);
         Current_Act : Vector_Access := new Vector'(Norm_Input);
         Next_Act    : Vector_Access;
      begin
         if Norm_Input'Length /= Net.Layers.First_Element.Inputs then
            Free (Current_Act);
            raise Dimension_Mismatch;
         end if;

         for I in 1 .. Num_Layers loop
            declare
               L : Layer renames Net.Layers.Element (I);
               Z : Real;
            begin
               Next_Act := new Vector (1 .. L.Outputs);
               for J in 1 .. L.Outputs loop
                  Z := L.Biases (J);
                  for K in 1 .. L.Inputs loop
                     Z := Z + Current_Act (K) * L.Weights (K, J);
                  end loop;
                  Next_Act (J) := Apply_Activation (Z, L.Activation);
               end loop;
               
               Free (Current_Act);
               Current_Act := Next_Act;
            end;
         end loop;

         declare
            Result : constant Vector := Current_Act.all;
         begin
            Free (Current_Act);
            return Result;
         end;
      end;
   end Predict;

   -----------------------------------------------------------------------------
   -- Training Variant (Backpropagation via Stochastic Gradient Descent)
   -----------------------------------------------------------------------------

   procedure Train_Single
     (Net           : in out Network;
      Input         : Vector;
      Target        : Vector;
      Learning_Rate : Real)
   is
      Num_Layers : constant Natural := Natural (Net.Layers.Length);
      
      Norm_Input  : constant Vector := Normalize (Input);
      Norm_Target : constant Vector := Normalize (Target);
      
      -- Arrays to hold step allocations for cleanup later
      A      : array (0 .. Num_Layers) of Vector_Access;
      Z      : array (1 .. Num_Layers) of Vector_Access;
      Deltas : array (1 .. Num_Layers) of Vector_Access;
   begin
      if Num_Layers = 0 then
         raise Empty_Network;
      end if;
      
      if Norm_Input'Length /= Net.Layers.First_Element.Inputs or else 
         Norm_Target'Length /= Net.Layers.Last_Element.Outputs 
      then
         raise Dimension_Mismatch;
      end if;

      -- Seed the input layer activations
      A (0) := new Vector'(Norm_Input);

      -- Forward Pass: cache Z (pre-activation) and A (post-activation)
      for I in 1 .. Num_Layers loop
         declare
            L : Layer renames Net.Layers.Element (I);
            Current_Z : Vector (1 .. L.Outputs) := L.Biases;
            Current_A : Vector (1 .. L.Outputs);
         begin
            for J in 1 .. L.Outputs loop
               for K in 1 .. L.Inputs loop
                  Current_Z (J) := Current_Z (J) + A (I - 1)(K) * L.Weights (K, J);
               end loop;
               Current_A (J) := Apply_Activation (Current_Z (J), L.Activation);
            end loop;
            
            Z (I) := new Vector'(Current_Z);
            A (I) := new Vector'(Current_A);
         end;
      end loop;

      -- Backward Pass: compute error terms (Deltas) propagating backwards
      for I in reverse 1 .. Num_Layers loop
         declare
            L : Layer renames Net.Layers.Element (I);
            Current_Delta : Vector (1 .. L.Outputs);
         begin
            if I = Num_Layers then
               -- Output layer error calculation
               for J in 1 .. L.Outputs loop
                  Current_Delta (J) := (A (I)(J) - Norm_Target (J)) *
                                       Apply_Derivative (Z (I)(J), L.Activation);
               end loop;
            else
               -- Hidden layer error backpropagation calculation
               declare
                  Next_L : Layer renames Net.Layers.Element (I + 1);
                  Sum    : Real;
               begin
                  for J in 1 .. L.Outputs loop
                     Sum := 0.0;
                     for K in 1 .. Next_L.Outputs loop
                        Sum := Sum + Deltas (I + 1)(K) * Next_L.Weights (J, K);
                     end loop;
                     Current_Delta (J) := Sum * Apply_Derivative (Z (I)(J), L.Activation);
                  end loop;
               end;
            end if;
            
            Deltas (I) := new Vector'(Current_Delta);
         end;
      end loop;

      -- Gradient Descent: apply Deltas to update Weights and Biases
      for I in 1 .. Num_Layers loop
         declare
            L : Layer := Net.Layers.Element (I);
         begin
            for J in 1 .. L.Outputs loop
               L.Biases (J) := L.Biases (J) - Learning_Rate * Deltas (I)(J);
               
               for K in 1 .. L.Inputs loop
                  L.Weights (K, J) := L.Weights (K, J) - 
                                      Learning_Rate * A (I - 1)(K) * Deltas (I)(J);
               end loop;
            end loop;
            
            Net.Layers.Replace_Element (I, L);
         end;
      end loop;

      -- Deallocate cache dynamically allocated during this epoch
      Free (A (0));
      for I in 1 .. Num_Layers loop
         Free (A (I));
         Free (Z (I));
         Free (Deltas (I));
      end loop;
   end Train_Single;

end Artificial_Neural_Networks;
