--  Support Vector Machine (SVM) algorithm suite.
--  Implements variants discussed in the literature:
--    1. Linear Hard-Margin SVM
--    2. Linear Soft-Margin SVM
--    3. Non-linear SVM via the Kernel Trick (Polynomial, RBF)

package SVM is
   pragma Preelaborate;

   --  Fundamental scalar type
   type Real is digits 15;

   --  Basic tensor types
   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;

   --  Label types (+1.0 or -1.0)
   subtype Label_Type is Real range -1.0 .. 1.0;
   type Label_Array is array (Positive range <>) of Label_Type;

   --  Supported Kernel Functions for non-linear separation
   type Kernel_Type is (Linear_Kernel, Polynomial_Kernel, RBF_Kernel);

   --  Exception raised for input array dimension mismatches
   Dimension_Mismatch : exception;
   
   --  Exception raised for degenerate or empty input data
   Invalid_Data : exception;

   --  Model structures
   
   --  Linear Model using primal weights. Efficient for linear classification.
   type Linear_Model (Dim : Natural) is record
      Weights : Vector (1 .. Dim);
      Bias    : Real;
   end record;

   --  Dual Model using Support Vectors. Required for Kernel trick.
   type Dual_Model (Num_Support_Vectors : Natural; Features_Dim : Natural) is record
      Alphas          : Vector (1 .. Num_Support_Vectors);
      Support_Labels  : Label_Array (1 .. Num_Support_Vectors);
      Support_Vectors : Matrix (1 .. Num_Support_Vectors, 1 .. Features_Dim);
      Bias            : Real;
      Kernel          : Kernel_Type;
      Gamma           : Real;
      Degree          : Real;
      Coef0           : Real;
   end record;

   --  Core API: Training
   
   --  Trains a Linear SVM using the Pegasos Sub-Gradient Descent algorithm.
   --  To emulate a "Hard Margin", C can be set extremely high (e.g., 1.0e6).
   --  For a "Soft Margin", C acts as the standard regularization parameter.
   function Train_Linear
     (X        : Matrix;
      Y        : Label_Array;
      C        : Real;
      Max_Iter : Positive) return Linear_Model
     with Pre => X'Length (1) = Y'Length and then X'Length (1) > 0 and then X'Length (2) > 0,
          Post => Train_Linear'Result.Dim = X'Length (2);

   --  Trains a Kernelized Dual SVM using a simplified Sequential Minimal Optimization (SMO).
   --  Supports Polynomial and RBF (Radial Basis Function) kernels.
   function Train_Dual_SMO
     (X          : Matrix;
      Y          : Label_Array;
      C          : Real;
      Kernel     : Kernel_Type;
      Max_Passes : Positive;
      Tol        : Real := 1.0e-3;
      Degree     : Real := 3.0;
      Gamma      : Real := 1.0;
      Coef0      : Real := 0.0) return Dual_Model
     with Pre => X'Length (1) = Y'Length and then X'Length (1) > 0 and then X'Length (2) > 0,
          Post => Train_Dual_SMO'Result.Features_Dim = X'Length (2);

   --  Core API: Prediction
   
   --  Predicts class label using a Linear_Model
   function Predict (Model : Linear_Model; X_Test : Vector) return Label_Type
     with Pre => Model.Dim = X_Test'Length;

   --  Predicts class label using a Dual_Model
   function Predict (Model : Dual_Model; X_Test : Vector) return Label_Type
     with Pre => Model.Features_Dim = X_Test'Length;

   --  Helper Mathematical Operations exposed for testing/validation
   function Dot_Product (A, B : Vector) return Real
     with Pre => A'Length = B'Length;

   function Kernel_Compute
     (K_Type   : Kernel_Type;
      A, B     : Vector;
      Degree   : Real;
      Gamma    : Real;
      Coef0    : Real) return Real
     with Pre => A'Length = B'Length;

end SVM;
