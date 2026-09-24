with Ada.Numerics.Generic_Real_Arrays;
with Ada.Finalization;

package Relevance_Vector_Machine is
   
   -- Core scalar type for precision
   type Real is digits 15;
   
   -- Vector and Matrix operations from standard library
   package Real_Arrays is new Ada.Numerics.Generic_Real_Arrays (Real);
   use Real_Arrays;

   -- Subtypes for domain clarity
   subtype Feature_Value is Real;
   subtype Target_Value is Real;
   subtype Probability is Real range 0.0 .. 1.0;

   -- Supported Kernels
   type Kernel_Function is (Linear, RBF);

   -- Supported Variants
   type Model_Variant is (Regression, Classification);

   -- Memory-safe controlled type for the RVM Model
   type RVM_Model is new Ada.Finalization.Controlled with private;

   -- Exceptions
   Model_Not_Trained  : exception;
   Dimension_Mismatch : exception;
   Data_Error         : exception;

   -- Training procedure
   -- Automatically determines the relevance vectors and optimal weights
   procedure Train
     (Model   : in out RVM_Model;
      X       : Real_Matrix;
      Y       : Real_Vector;
      Variant : Model_Variant;
      Kernel  : Kernel_Function := Linear;
      Gamma   : Real := 1.0)
     with Pre => X'Length (1) > 0 and then
                 X'Length (1) = Y'Length,
          Post => Model.Is_Trained_Successfully;

   -- Predict raw target value (for Regression)
   function Predict
     (Model : RVM_Model;
      X     : Real_Vector) return Target_Value
     with Pre => Model.Is_Trained_Successfully and then
                 X'Length = Model.Features_Count;

   -- Predict probability (for Classification)
   function Predict_Prob
     (Model : RVM_Model;
      X     : Real_Vector) return Probability
     with Pre => Model.Is_Trained_Successfully and then
                 X'Length = Model.Features_Count;

   -- Getters for model state verification
   function Is_Trained_Successfully (Model : RVM_Model) return Boolean;
   function Features_Count (Model : RVM_Model) return Natural;
   function Support_Vectors_Count (Model : RVM_Model) return Natural;

private

   type Real_Matrix_Access is access Real_Matrix;
   type Real_Vector_Access is access Real_Vector;

   type RVM_Model is new Ada.Finalization.Controlled with record
      Variant        : Model_Variant := Regression;
      Kernel         : Kernel_Function := Linear;
      Gamma          : Real := 1.0;
      Is_Trained     : Boolean := False;
      
      Num_Features   : Natural := 0;
      Num_SVs        : Natural := 0;
      
      SVs            : Real_Matrix_Access := null;
      Weights        : Real_Vector_Access := null;
      Bias           : Real := 0.0;
   end record;

   overriding procedure Finalize (Model : in out RVM_Model);

end Relevance_Vector_Machine;
