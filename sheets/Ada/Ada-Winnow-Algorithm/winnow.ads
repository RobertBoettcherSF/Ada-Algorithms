-- winnow.ads
-- Specification for the Winnow Algorithm and its variants.

package Winnow is

   -- Strong typing: Features are strictly binary (0 or 1).
   type Feature_Value is range 0 .. 1;
   type Feature_Vector is array (Positive range <>) of Feature_Value;
   
   -- Weights are maintained as floating point values
   type Weight_Vector is array (Positive range <>) of Float;

   -- Exceptions for error handling
   Invalid_Input_Error : exception;
   Configuration_Error : exception;

   -- =========================================================================
   -- Standard Winnow Model (Winnow1 variant)
   -- Uses a single set of weights. 
   -- Promotes weights on False Negative, Demotes on False Positive.
   -- =========================================================================
   type Winnow_Model (N : Positive) is record
      Weights   : Weight_Vector (1 .. N);
      Alpha     : Float;
      Threshold : Float;
   end record;

   -- Initialize a Standard Winnow Model
   -- N: Number of features
   -- Alpha: Multiplicative factor (> 1.0)
   -- Threshold: Decision boundary. If left < 0.0, defaults to Float(N) / 2.0
   function Initialize 
     (N : Positive; Alpha : Float := 2.0; Threshold : Float := -1.0) 
      return Winnow_Model;

   -- Predict output for a given feature vector
   function Predict (Model : Winnow_Model; X : Feature_Vector) return Boolean;

   -- Train the model using a single instance (x, y)
   procedure Train (Model : in out Winnow_Model; X : Feature_Vector; Y : Boolean);


   -- =========================================================================
   -- Balanced Winnow Model Variant
   -- Uses two sets of weights (Positive and Negative) to handle symmetric learning.
   -- Often provides better performance when features can be negatively correlated.
   -- =========================================================================
   type Balanced_Winnow_Model (N : Positive) is record
      Weights_Pos : Weight_Vector (1 .. N);
      Weights_Neg : Weight_Vector (1 .. N);
      Alpha       : Float;
      Threshold   : Float;
   end record;

   -- Initialize a Balanced Winnow Model
   function Initialize_Balanced 
     (N : Positive; Alpha : Float := 2.0; Threshold : Float := 0.0) 
      return Balanced_Winnow_Model;

   -- Predict output for the balanced model
   function Predict (Model : Balanced_Winnow_Model; X : Feature_Vector) return Boolean;

   -- Train the balanced model
   procedure Train (Model : in out Balanced_Winnow_Model; X : Feature_Vector; Y : Boolean);

private
   -- Helper function for calculating dot products (Sum of W_i * X_i)
   function Calculate_Dot_Product (W : Weight_Vector; X : Feature_Vector) return Float;

end Winnow;
