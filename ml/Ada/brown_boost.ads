package Brown_Boost is

   -- Domain types for the algorithm
   type Value_Type is new Long_Float;
   type Class_Label is (Label_Negative, Label_Positive);

   -- Feature and example definitions
   type Feature_Vector is array (Positive range <>) of Value_Type;
   type Feature_Matrix is array (Positive range <>, Positive range <>) of Value_Type;
   type Label_Array is array (Positive range <>) of Class_Label;

   -- A Decision Stump acts as the weak learner
   type Decision_Stump is record
      Feature   : Positive;
      Threshold : Value_Type;
      Direction : Value_Type; -- +1.0 or -1.0
   end record;

   -- Weak model weighting
   type Weak_Model is record
      Stump : Decision_Stump;
      Alpha : Value_Type;
   end record;

   type Model_Array is array (Positive range <>) of Weak_Model;

   -- The aggregate boosted ensemble model
   type Ensemble_Model (Capacity : Positive) is record
      Size   : Natural := 0;
      Models : Model_Array (1 .. Capacity);
   end record;

   -- BrownBoost supports solving the time/alpha differential equations 
   -- either via Bisection (as in JBoost) or Newton's Method (Freund's paper).
   type Solver_Variant is (Bisection_Solver, Newton_Solver);

   Invalid_Data : exception;

   -- Trains a BrownBoost ensemble over the provided dataset.
   -- C is the total "time" limit (variance) representing the expected noise level.
   function Train
     (Features : Feature_Matrix;
      Labels   : Label_Array;
      C        : Value_Type;
      Variant  : Solver_Variant;
      Capacity : Positive := 100) return Ensemble_Model
     with 
       Pre => Features'Length (1) = Labels'Length and then
              Features'Length (1) > 0 and then
              Features'Length (2) > 0 and then
              C > 0.0,
       Post => Train'Result.Size <= Capacity;

   -- Evaluates the trained model against a new feature vector.
   function Predict
     (Model    : Ensemble_Model;
      Features : Feature_Vector) return Class_Label;

end Brown_Boost;
