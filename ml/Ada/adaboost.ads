package Adaboost is
   -- Strong typing for domain variables
   type Feature_Value is new Float;
   type Class_Label is (Negative, Positive);

   type Feature_Index is new Standard.Positive;
   type Sample_Index is new Standard.Positive;

   type Feature_Vector is array (Feature_Index range <>) of Feature_Value;
   type Features_Matrix is array (Sample_Index range <>, Feature_Index range <>) of Feature_Value;
   type Labels_Array is array (Sample_Index range <>) of Class_Label;

   -- Exceptions for edge cases
   Empty_Dataset_Error      : exception;
   Dimension_Mismatch_Error : exception;

   -- A Weak Learner (Decision Stump)
   type Decision_Stump is record
      Feature   : Feature_Index := 1;
      Threshold : Feature_Value := 0.0;
      Polarity  : Integer range -1 .. 1 := 1;
   end record;

   type Classifier_Weight is new Float;
   type Weak_Learner_Array is array (Standard.Positive range <>) of Decision_Stump;
   type Weights_Array is array (Standard.Positive range <>) of Classifier_Weight;

   -- The Strong Classifier
   type AdaBoost_Model (Max_Iterations : Standard.Positive) is record
      Count         : Natural := 0;
      Feature_Count : Natural := 0;
      Learners      : Weak_Learner_Array (1 .. Max_Iterations);
      Alphas        : Weights_Array (1 .. Max_Iterations);
   end record;

   -- Public Subprograms
   procedure Train
     (Model      : out AdaBoost_Model;
      X          : in Features_Matrix;
      Y          : in Labels_Array)
     with Pre => Model.Max_Iterations > 0,
          Post => Model.Count <= Model.Max_Iterations;

   function Predict
     (Model : in AdaBoost_Model;
      X     : in Feature_Vector) return Class_Label;

   function Predict_Score
     (Model : in AdaBoost_Model;
      X     : in Feature_Vector) return Classifier_Weight;

end Adaboost;
