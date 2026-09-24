package Supervised_Learning is
   pragma Pure;

   -- Domain Types: Strong typing for algorithm-specific data
   type Real is new Float;
   type Class_Label is new Integer;
   subtype K_Value is Positive;
   subtype Epoch_Count is Positive;

   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;
   type Label_Array is array (Positive range <>) of Class_Label;

   -- Exceptions for edge cases and invalid data
   Insufficient_Data_Error      : exception;
   Dimension_Mismatch_Error     : exception;
   Invalid_Hyperparameter_Error : exception;
   Zero_Variance_Error          : exception;
   Invalid_Label_Error          : exception;

   -----------------------------------------------------------------------------
   -- 1. Simple Linear Regression (Regression Variant)
   -----------------------------------------------------------------------------
   type Linear_Model is record
      Slope     : Real;
      Intercept : Real;
   end record;

   -- Train a 1D Simple Linear Regression model using Least Squares
   function Train_Linear_Regression (
      Train_X : Vector;
      Train_Y : Vector
   ) return Linear_Model
     with Pre => Train_X'Length >= 2 and then Train_X'Length = Train_Y'Length;

   -- Predict a continuous target given a feature
   function Predict_Linear_Regression (
      Model  : Linear_Model;
      Test_X : Real
   ) return Real;

   -----------------------------------------------------------------------------
   -- 2. K-Nearest Neighbors (Classification Variant - Distance Based)
   -----------------------------------------------------------------------------
   -- Predict a discrete class for a new point using majority vote of K nearest
   function Predict_KNN (
      Train_X : Matrix;
      Train_Y : Label_Array;
      Test_X  : Vector;
      K       : K_Value
   ) return Class_Label
     with Pre => Train_X'Length(1) > 0 and then
                 Train_X'Length(1) = Train_Y'Length and then
                 Train_X'Length(2) = Test_X'Length and then
                 Natural(K) <= Train_X'Length(1);

   -----------------------------------------------------------------------------
   -- 3. Simple Perceptron (Classification Variant - Iterative/Dynamic)
   -----------------------------------------------------------------------------
   type Perceptron_Model (Dimension : Positive) is record
      Weights : Vector (1 .. Dimension);
      Bias    : Real;
   end record;

   -- Train a Perceptron for binary classification (labels must be +1 or -1)
   function Train_Perceptron (
      Train_X       : Matrix;
      Train_Y       : Label_Array;
      Learning_Rate : Real;
      Epochs        : Epoch_Count
   ) return Perceptron_Model
     with Pre => Train_X'Length(1) > 0 and then
                 Train_X'Length(1) = Train_Y'Length and then
                 Learning_Rate > 0.0;

   -- Predict +1 or -1 for a new vector using learned weights
   function Predict_Perceptron (
      Model  : Perceptron_Model;
      Test_X : Vector
   ) return Class_Label
     with Pre => Model.Dimension = Test_X'Length;

end Supervised_Learning;
