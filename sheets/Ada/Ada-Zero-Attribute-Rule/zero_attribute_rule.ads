package Zero_Attribute_Rule is
   pragma Pure;

   --  Strong types for numeric target variables (used in Regression).
   --  By using custom types instead of bare Float, we enforce domain separation.
   type Numeric_Value is new Float;
   type Numeric_Array is array (Positive range <>) of Numeric_Value;

   --  Strong types for nominal/categorical target variables (used in Classification).
   --  Represented as natural numbers for class labels (e.g., Class 0, 1, 2...).
   type Nominal_Value is new Natural;
   type Nominal_Array is array (Positive range <>) of Nominal_Value;

   --  Exception raised when a safe wrapper function is given an empty dataset.
   Empty_Dataset_Error : exception;

   -----------------------------------------------------------------------------
   --  Zero-Attribute Rule (ZeroR) - Core Implementations
   -----------------------------------------------------------------------------

   --  1. Numeric Target: Mean
   --  Calculates the standard ZeroR for regression problems (Arithmetic Mean).
   function Predict_Numeric_Mean (Targets : Numeric_Array) return Numeric_Value
     with Pre => Targets'Length > 0;

   --  2. Numeric Target: Median
   --  Calculates the robust ZeroR for regression problems (Median).
   --  This is more resilient to outliers than the mean.
   function Predict_Numeric_Median (Targets : Numeric_Array) return Numeric_Value
     with Pre => Targets'Length > 0;

   --  3. Nominal Target: Mode
   --  Calculates the standard ZeroR for classification problems (Mode / Most Frequent).
   --  If there is a tie in frequencies, it resolves to the smallest nominal value.
   function Predict_Nominal_Mode (Targets : Nominal_Array) return Nominal_Value
     with Pre => Targets'Length > 0;

   -----------------------------------------------------------------------------
   --  Zero-Attribute Rule (ZeroR) - Safe Dynamic Wrappers
   -----------------------------------------------------------------------------
   --  These wrappers do not use preconditions for array length. Instead, they
   --  validate the input dynamically and raise Empty_Dataset_Error on failure.

   function Safe_Predict_Numeric_Mean (Targets : Numeric_Array) return Numeric_Value;
   function Safe_Predict_Numeric_Median (Targets : Numeric_Array) return Numeric_Value;
   function Safe_Predict_Nominal_Mode (Targets : Nominal_Array) return Nominal_Value;

end Zero_Attribute_Rule;
