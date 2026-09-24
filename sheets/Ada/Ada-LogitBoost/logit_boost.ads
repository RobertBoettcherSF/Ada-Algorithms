package Logit_Boost is

   -- Strong typing: defining custom floating-point type for all feature and model logic.
   type Real is new Float;

   type Feature_Vector is array (Positive range <>) of Real;
   
   -- Feature_Matrix where dim 1 is samples, dim 2 is features
   type Feature_Matrix is array (Positive range <>, Positive range <>) of Real;

   -- Binary class label mapping to 0 and 1
   type Class_Label is range 0 .. 1;
   
   type Label_Vector is array (Positive range <>) of Class_Label;

   -- A weak learner forming the basis of the ensemble
   type Decision_Stump is record
      Feature_Index : Positive;
      Threshold     : Real;
      Left_Value    : Real;
      Right_Value   : Real;
   end record;

   type Stump_Array is array (Positive range <>) of Decision_Stump;

   -- The final trained LogitBoost ensemble model
   type Model (Number_Of_Stumps : Natural) is record
      Stumps : Stump_Array (1 .. Number_Of_Stumps);
   end record;

   Invalid_Data_Error : exception;

   -- Fits a LogitBoost model using decision stumps.
   -- Preconditions enforce matched array sizes and non-empty structures.
   function Train (X          : Feature_Matrix;
                   Y          : Label_Vector;
                   Iterations : Natural) return Model
     with Pre => X'Length(1) = Y'Length
                 and then X'Length(1) > 0
                 and then X'Length(2) > 0;

   -- Evaluates the raw F(x) function (1/2 * log-odds) for a given sample.
   function Predict_F (M : Model; X : Feature_Vector) return Real
     with Pre => (if M.Number_Of_Stumps > 0 then X'Length >= 1 else True);

   -- Predicts the probability of class 1 based on the ensemble F(x).
   function Predict_Probability (M : Model; X : Feature_Vector) return Real
     with Pre => (if M.Number_Of_Stumps > 0 then X'Length >= 1 else True);

   -- Predicts the class label (0 or 1) by thresholding probability at 0.5.
   function Predict (M : Model; X : Feature_Vector) return Class_Label
     with Pre => (if M.Number_Of_Stumps > 0 then X'Length >= 1 else True);

   -- Helper for Testing: Calculates working responses and weights for LogitBoost algorithm.
   procedure Calculate_Working_Data (P : in Real; Y : in Class_Label; Z : out Real; W : out Real)
     with Post => W >= 0.0;

   type Real_Vector is array (Positive range <>) of Real;

   -- Helper for Testing: Fits a single decision stump based on weighted least squares.
   function Fit_Stump (X : Feature_Matrix; Z : Real_Vector; W : Real_Vector) return Decision_Stump
     with Pre => X'Length(1) = Z'Length and then Z'Length = W'Length
                 and then X'Length(1) > 0 and then X'Length(2) > 0;

end Logit_Boost;
