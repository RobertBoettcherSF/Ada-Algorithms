-- Bootstrap Aggregating (Bagging) Meta-Algorithm
--
-- This package implements the Bootstrap Aggregating algorithm as described
-- in standard machine learning literature. It reduces variance and helps
-- avoid overfitting by training multiple models on random subsets of the
-- original dataset (sampled with replacement) and aggregating their predictions.
--
-- Variants included:
--   1. Classification Bagging (aggregates via Majority Voting)
--   2. Regression Bagging (aggregates via Averaging)
--
-- Note: To remain domain-agnostic, datasets are represented by indices. The
-- user is responsible for mapping these indices to their actual data structures
-- within their Model implementations.

package Bootstrap_Aggregating is

   -------------------------------------------------------------------------
   -- Common Types and Exceptions
   -------------------------------------------------------------------------

   -- Represents an index pointing to a data sample in the original dataset.
   type Dataset_Index is new Positive;
   
   -- An array of dataset indices, used to represent a bootstrap sample.
   type Index_Array is array (Positive range <>) of Dataset_Index;

   -- Raised when inputs to training or prediction functions are logically invalid.
   Invalid_Configuration_Error : exception;
   
   -- Raised when prediction is attempted on an empty ensemble.
   Empty_Ensemble_Error        : exception;

   -------------------------------------------------------------------------
   -- Bootstrap Sampling Helper
   -------------------------------------------------------------------------
   
   -- Generates an array of Target_Size containing indices chosen uniformly
   -- at random with replacement from the range 1 .. Source_Size.
   function Generate_Bootstrap_Sample
     (Source_Size : Natural;
      Target_Size : Natural) return Index_Array
     with Pre => Source_Size > 0 and Target_Size > 0;

   -------------------------------------------------------------------------
   -- Variant 1: Classification Bagging (Majority Voting)
   -------------------------------------------------------------------------
   
   -- Discrete label for classification tasks.
   type Class_Label is new Natural;
   type Class_Array is array (Positive range <>) of Class_Label;

   -- Abstract base interface for a single classification model.
   -- Users must implement this interface for their specific base learners.
   type Classification_Model is interface;
   
   -- Predicts the class label for a given data item (referenced by index).
   function Predict (Model : Classification_Model; Item : Dataset_Index) return Class_Label is abstract;

   type Classification_Model_Access is access all Classification_Model'Class;
   type Classification_Ensemble is array (Positive range <>) of Classification_Model_Access;

   -- Trainer function type: accepts bootstrap sample indices, returns a newly allocated fitted model.
   type Classification_Trainer is access function (Sample_Indices : Index_Array) return Classification_Model_Access;

   -- Trains an ensemble of Classification models.
   -- If Sample_Size is 0, it defaults to Original_Size (standard Bagging).
   function Train_Classifier
     (Original_Size : Natural;
      Num_Models    : Positive;
      Trainer       : Classification_Trainer;
      Sample_Size   : Natural := 0) return Classification_Ensemble
     with Pre => Original_Size > 0 and Num_Models > 0 and Trainer /= null;

   -- Predicts the class using Majority Voting among all models in the ensemble.
   -- In case of a tie, the class encountered first in the voting sequence is selected deterministically.
   function Predict_Classifier
     (Ensemble : Classification_Ensemble;
      Item     : Dataset_Index) return Class_Label
     with Pre => Ensemble'Length > 0;

   -- Frees the memory allocated for the models in the ensemble.
   -- Safe to call multiple times; leaves elements as null.
   procedure Free_Classifier_Ensemble (Ensemble : in out Classification_Ensemble);


   -------------------------------------------------------------------------
   -- Variant 2: Regression Bagging (Averaging)
   -------------------------------------------------------------------------
   
   -- Continuous value for regression tasks.
   type Regression_Value is new Float;
   type Regression_Array is array (Positive range <>) of Regression_Value;

   -- Abstract base interface for a single regression model.
   type Regression_Model is interface;
   
   -- Predicts the continuous target variable for a given data item.
   function Predict (Model : Regression_Model; Item : Dataset_Index) return Regression_Value is abstract;

   type Regression_Model_Access is access all Regression_Model'Class;
   type Regression_Ensemble is array (Positive range <>) of Regression_Model_Access;

   -- Trainer function type: accepts bootstrap sample indices, returns a newly allocated fitted model.
   type Regression_Trainer is access function (Sample_Indices : Index_Array) return Regression_Model_Access;

   -- Trains an ensemble of Regression models.
   -- If Sample_Size is 0, it defaults to Original_Size (standard Bagging).
   function Train_Regressor
     (Original_Size : Natural;
      Num_Models    : Positive;
      Trainer       : Regression_Trainer;
      Sample_Size   : Natural := 0) return Regression_Ensemble
     with Pre => Original_Size > 0 and Num_Models > 0 and Trainer /= null;

   -- Predicts the continuous value using Averaging among all models in the ensemble.
   function Predict_Regressor
     (Ensemble : Regression_Ensemble;
      Item     : Dataset_Index) return Regression_Value
     with Pre => Ensemble'Length > 0;

   -- Frees the memory allocated for the models in the ensemble.
   procedure Free_Regressor_Ensemble (Ensemble : in out Regression_Ensemble);

end Bootstrap_Aggregating;
