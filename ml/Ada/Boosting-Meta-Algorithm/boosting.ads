package Boosting
  with Preelaborate
is
   --  High-precision floating point type for algorithm calculations
   type Real is digits 15;

   --  Vectors and Matrices for Dataset and Labels
   type Real_Vector is array (Positive range <>) of Real;
   type Real_Matrix is array (Positive range <>, Positive range <>) of Real;

   --  Named exceptions for edge cases and input validation
   Invalid_Input_Error  : exception;
   Invalid_Labels_Error : exception;

   -----------------------------------------------------------------------------
   --  AdaBoost.M1 (Binary Classification)
   -----------------------------------------------------------------------------

   --  A decision stump (1-level decision tree) used as a weak learner
   type AdaBoost_Stump is record
      Feature   : Positive := 1;
      Threshold : Real     := 0.0;
      Polarity  : Integer  := 1;
      Alpha     : Real     := 0.0; --  The weight of this stump's vote
   end record;

   type AdaBoost_Stump_Array is array (Positive range <>) of AdaBoost_Stump;

   --  The trained model container. The discriminant allows arrays of exact length.
   type AdaBoost_Model (Num_Iterations : Natural) is record
      Stumps : AdaBoost_Stump_Array (1 .. Num_Iterations);
   end record;

   --  Trains an AdaBoost binary classifier.
   --  Expects Y to contain strictly -1.0 or 1.0.
   function Train_AdaBoost
     (X              : Real_Matrix;
      Y              : Real_Vector;
      Max_Iterations : Positive) return AdaBoost_Model
     with Global => null,
          Pre    => X'Length (1) > 0 and then X'Length (2) > 0;

   --  Predicts the class label (-1.0 or 1.0) for a single data point.
   function Predict_AdaBoost
     (Model : AdaBoost_Model;
      X_Row : Real_Vector) return Real
     with Global => null,
          Pre    => X_Row'Length > 0,
          Post   => abs (Predict_AdaBoost'Result) = 1.0;

   -----------------------------------------------------------------------------
   --  Gradient Boosting (Least-Squares Regression)
   -----------------------------------------------------------------------------

   --  A regression decision stump used to predict residuals
   type Gradient_Stump is record
      Feature     : Positive := 1;
      Threshold   : Real     := 0.0;
      Left_Value  : Real     := 0.0;
      Right_Value : Real     := 0.0;
      Weight      : Real     := 1.0; --  Learning Rate scaling
   end record;

   type Gradient_Stump_Array is array (Positive range <>) of Gradient_Stump;

   type Gradient_Boosting_Model (Num_Iterations : Natural) is record
      Initial_Prediction : Real := 0.0;
      Stumps             : Gradient_Stump_Array (1 .. Num_Iterations);
   end record;

   --  Trains a Gradient Boosting regressor optimizing Mean Squared Error (MSE).
   function Train_Gradient_Boosting
     (X              : Real_Matrix;
      Y              : Real_Vector;
      Max_Iterations : Natural;
      Learning_Rate  : Real := 0.1) return Gradient_Boosting_Model
     with Global => null,
          Pre    => X'Length (1) > 0 and then X'Length (2) > 0;

   --  Predicts the continuous real value for a single data point.
   function Predict_Gradient_Boosting
     (Model : Gradient_Boosting_Model;
      X_Row : Real_Vector) return Real
     with Global => null,
          Pre    => X_Row'Length > 0;

end Boosting;
