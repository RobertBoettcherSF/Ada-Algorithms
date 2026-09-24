-- LPBoost (Linear Programming Boosting) Package Specification
--
-- This package implements the LPBoost algorithm, which maximizes the margin
-- between positive and negative examples by generating weak hypotheses
-- (decision stumps) and solving a Linear Program (LP) to find optimal weights.
--
-- The dual LP formulation solves for the hardest distribution of examples,
-- while the primal gives the optimal weights (Alphas) for each weak hypothesis.

package LPBoost with Spark_Mode => On is

   -- Core floating point type for numeric stability in the LP solver
   type Real is digits 15;

   -- A single data point (feature vector)
   type Data_Point is array (Positive range <>) of Real;

   -- A dataset represented as a 2D array: (Sample_Index, Feature_Index)
   type Dataset is array (Positive range <>, Positive range <>) of Real;

   -- Labels must be exactly -1 or 1
   subtype Label is Integer range -1 .. 1;
   type Labels is array (Positive range <>) of Label
     with Dynamic_Predicate =>
       (for all L of Labels => L = -1 or L = 1);

   -- Probability distribution over examples
   type Distribution is array (Positive range <>) of Real;

   -- A decision stump acts as our weak learner
   type Weak_Hypothesis is record
      Feature   : Positive := 1;
      Threshold : Real := 0.0;
      Polarity  : Integer := 1;
      Weight    : Real := 0.0;
   end record;

   type Hypothesis_Array is array (Positive range <>) of Weak_Hypothesis;

   -- The resulting ensemble model
   type Model (Max_Size : Natural) is record
      Size       : Natural := 0;
      Hypotheses : Hypothesis_Array (1 .. Max_Size);
   end record;

   -----------------------------------------------------------------------------
   -- Public API
   -----------------------------------------------------------------------------

   -- Train an LPBoost model on the given dataset.
   -- 
   -- Nu : Regularization parameter in (0.0, 1.0]. A smaller Nu imposes stronger
   --      regularization (softer margin) by capping the maximum weight of any
   --      single example to 1 / (Nu * M).
   -- Max_Iter : Maximum number of weak hypotheses to generate.
   function Train
     (Data     : Dataset;
      Lbls     : Labels;
      Nu       : Real;
      Max_Iter : Positive) return Model
     with Pre => Data'Length (1) > 0 
                 and Data'Length (2) > 0
                 and Data'Length (1) = Lbls'Length
                 and Nu > 0.0 
                 and Nu <= 1.0,
          Post => Train'Result.Size <= Max_Iter;

   -- Predict the classification (-1 or 1) of a new data point
   function Predict
     (M_Mod : Model;
      Point : Data_Point) return Label
     with Pre => M_Mod.Size > 0 
                 and Point'Length > 0;

   -- Get the raw margin score of a prediction (sum of weighted hypothesis outputs)
   function Predict_Score
     (M_Mod : Model;
      Point : Data_Point) return Real
     with Pre => M_Mod.Size > 0 
                 and Point'Length > 0;

end LPBoost;
