with Ada.Numerics.Generic_Elementary_Functions;

package Naive_Bayes is

   --  Use high precision for probability calculations
   type Real is digits 15;
   
   --  Instantiate elementary functions for logarithmic operations
   package Real_Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   --  Core types for features and labels
   type Feature_Vector is array (Positive range <>) of Real;
   type Feature_Matrix is array (Positive range <>, Positive range <>) of Real;
   
   type Class_ID is new Positive;
   type Label_Vector is array (Positive range <>) of Class_ID;

   --  Internal array types for model parameters
   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;

   --  Exception raised for invalid algorithm inputs (e.g., zero samples for a class)
   Data_Error : exception;

   --  ========================================================================
   --  Gaussian Naive Bayes (for continuous data)
   --  ========================================================================

   type Gaussian_Model (Num_Classes, Num_Features : Positive) is record
      Log_Priors : Vector (1 .. Num_Classes);
      Means      : Matrix (1 .. Num_Classes, 1 .. Num_Features);
      Variances  : Matrix (1 .. Num_Classes, 1 .. Num_Features);
   end record;

   --  Train a Gaussian Naive Bayes model.
   --  Var_Smoothing adds a small epsilon to variances to prevent division by zero.
   function Train_Gaussian
     (X             : Feature_Matrix;
      Y             : Label_Vector;
      Num_Classes   : Positive;
      Var_Smoothing : Real := 1.0e-9) return Gaussian_Model
     with Pre => X'Length (1) = Y'Length 
                 and then X'Length (1) > 0 
                 and then X'Length (2) > 0 
                 and then Var_Smoothing >= 0.0;

   function Predict_Gaussian
     (Model : Gaussian_Model;
      X     : Feature_Vector) return Class_ID
     with Pre => X'Length = Model.Num_Features;

   --  ========================================================================
   --  Multinomial Naive Bayes (for frequency/count data)
   --  ========================================================================

   type Multinomial_Model (Num_Classes, Num_Features : Positive) is record
      Log_Priors        : Vector (1 .. Num_Classes);
      Log_Probabilities : Matrix (1 .. Num_Classes, 1 .. Num_Features);
   end record;

   --  Train a Multinomial Naive Bayes model.
   --  Alpha is the Laplace/Lidstone smoothing parameter.
   function Train_Multinomial
     (X           : Feature_Matrix;
      Y           : Label_Vector;
      Num_Classes : Positive;
      Alpha       : Real := 1.0) return Multinomial_Model
     with Pre => X'Length (1) = Y'Length 
                 and then X'Length (1) > 0 
                 and then X'Length (2) > 0 
                 and then Alpha > 0.0;

   function Predict_Multinomial
     (Model : Multinomial_Model;
      X     : Feature_Vector) return Class_ID
     with Pre => X'Length = Model.Num_Features;

   --  ========================================================================
   --  Bernoulli Naive Bayes (for binary/boolean data)
   --  ========================================================================

   type Bernoulli_Model (Num_Classes, Num_Features : Positive) is record
      Log_Priors       : Vector (1 .. Num_Classes);
      Log_Prob_Present : Matrix (1 .. Num_Classes, 1 .. Num_Features);
      Log_Prob_Absent  : Matrix (1 .. Num_Classes, 1 .. Num_Features);
   end record;

   --  Train a Bernoulli Naive Bayes model.
   --  Features > 0.0 are treated as Present (1), otherwise Absent (0).
   function Train_Bernoulli
     (X           : Feature_Matrix;
      Y           : Label_Vector;
      Num_Classes : Positive;
      Alpha       : Real := 1.0) return Bernoulli_Model
     with Pre => X'Length (1) = Y'Length 
                 and then X'Length (1) > 0 
                 and then X'Length (2) > 0 
                 and then Alpha > 0.0;

   function Predict_Bernoulli
     (Model : Bernoulli_Model;
      X     : Feature_Vector) return Class_ID
     with Pre => X'Length = Model.Num_Features;

end Naive_Bayes;
