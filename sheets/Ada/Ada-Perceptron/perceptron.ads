package Perceptron is
   pragma Preelaborate;

   -- Domain types and constants
   type Real is new Float;
   
   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;
   
   -- Labels must be +1 or -1 according to standard binary perceptron formulation
   subtype Valid_Label is Integer with Dynamic_Predicate => Valid_Label in -1 | 1;
   type Label_Array is array (Positive range <>) of Valid_Label;

   type Perceptron_Model (Dimensions : Positive) is private;

   -- Initializes all weights and biases to 0.0
   function Create (Dimensions : Positive) return Perceptron_Model
     with Post => Create'Result.Dimensions = Dimensions;

   -----------------------------------------------------------------------------
   -- Standard Perceptron (Online Learning)
   -- Updates weights immediately upon encountering a misclassified example.
   -----------------------------------------------------------------------------
   procedure Train_Standard
     (Model         : in out Perceptron_Model;
      X             : in Matrix;
      Y             : in Label_Array;
      Epochs        : in Positive;
      Learning_Rate : in Real)
     with Pre => X'Length(1) > 0 and then
                 X'Length(1) = Y'Length and then
                 X'Length(2) = Model.Dimensions and then
                 Learning_Rate >= 0.0;

   function Predict_Standard
     (Model : Perceptron_Model;
      X     : in Vector) return Valid_Label
     with Pre => X'Length = Model.Dimensions;

   -----------------------------------------------------------------------------
   -- Pocket Algorithm (Gallant)
   -- Keeps track of the longest contiguous sequence of correct classifications.
   -- Saves the "best" weight configuration seen so far in its "pocket".
   -----------------------------------------------------------------------------
   procedure Train_Pocket
     (Model         : in out Perceptron_Model;
      X             : in Matrix;
      Y             : in Label_Array;
      Epochs        : in Positive;
      Learning_Rate : in Real)
     with Pre => X'Length(1) > 0 and then
                 X'Length(1) = Y'Length and then
                 X'Length(2) = Model.Dimensions and then
                 Learning_Rate >= 0.0;

   function Predict_Pocket
     (Model : Perceptron_Model;
      X     : in Vector) return Valid_Label
     with Pre => X'Length = Model.Dimensions;

   -----------------------------------------------------------------------------
   -- Averaged Perceptron
   -- Reduces noisy updates by keeping a running average of all weight 
   -- vectors computed throughout the training lifecycle.
   -----------------------------------------------------------------------------
   procedure Train_Averaged
     (Model         : in out Perceptron_Model;
      X             : in Matrix;
      Y             : in Label_Array;
      Epochs        : in Positive;
      Learning_Rate : in Real)
     with Pre => X'Length(1) > 0 and then
                 X'Length(1) = Y'Length and then
                 X'Length(2) = Model.Dimensions and then
                 Learning_Rate >= 0.0;

   function Predict_Averaged
     (Model : Perceptron_Model;
      X     : in Vector) return Valid_Label
     with Pre => X'Length = Model.Dimensions;

private
   type Perceptron_Model (Dimensions : Positive) is record
      -- Core / Standard state
      Weights : Vector (1 .. Dimensions) := [others => 0.0];
      Bias    : Real := 0.0;

      -- Pocket state (Best preserved weights)
      Pocket_Weights : Vector (1 .. Dimensions) := [others => 0.0];
      Pocket_Bias    : Real := 0.0;
      Best_Run       : Natural := 0;

      -- Averaged state
      Averaged_Weights   : Vector (1 .. Dimensions) := [others => 0.0];
      Averaged_Bias      : Real := 0.0;
      Total_Samples_Seen : Natural := 0;
   end record;

end Perceptron;
