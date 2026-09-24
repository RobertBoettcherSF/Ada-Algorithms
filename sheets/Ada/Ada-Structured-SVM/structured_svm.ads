pragma Ada_2022;

generic
   type Real is digits <>;
   type Input_Type is private;
   type Output_Type is private;

   type Feature_Index is (<>);
   type Feature_Vector is array (Feature_Index) of Real;

   -- Joint feature map: \phi(X, Y)
   with function Joint_Feature_Map (X : Input_Type; Y : Output_Type) return Feature_Vector;
   
   -- Loss function: \Delta(True_Y, Predicted_Y)
   with function Loss (True_Y, Predicted_Y : Output_Type) return Real;

   -- Standard Inference: argmax_y { w^T \phi(X, y) }
   with function Predict_Max (X : Input_Type; W : Feature_Vector) return Output_Type;
   
   -- Loss-Augmented Inference (Margin Rescaling): argmax_y { \Delta(True_Y, y) + w^T \phi(X, y) }
   with function Argmax_Margin_Rescaling (X : Input_Type; True_Y : Output_Type; W : Feature_Vector) return Output_Type;
   
   -- Loss-Augmented Inference (Slack Rescaling): argmax_y { \Delta(True_Y, y) * (1 - w^T (\phi(X, True_Y) - \phi(X, y))) }
   with function Argmax_Slack_Rescaling (X : Input_Type; True_Y : Output_Type; W : Feature_Vector) return Output_Type;

package Structured_SVM is

   type Dataset_Array is array (Positive range <>) of Input_Type;
   type Label_Array is array (Positive range <>) of Output_Type;

   type Model is record
      Weights : Feature_Vector := [others => 0.0];
   end record;

   Dataset_Size_Mismatch  : exception;
   Invalid_Hyperparameter : exception;
   Empty_Dataset          : exception;

   -- Trains the SSVM using the Margin-Rescaling formulation
   function Train_Margin_Rescaling
     (Inputs : Dataset_Array;
      Labels : Label_Array;
      Lambda : Real;
      Epochs : Positive) return Model;

   -- Trains the SSVM using the Slack-Rescaling formulation
   function Train_Slack_Rescaling
     (Inputs : Dataset_Array;
      Labels : Label_Array;
      Lambda : Real;
      Epochs : Positive) return Model;

   -- Evaluates the model using standard inference
   function Predict (M : Model; X : Input_Type) return Output_Type;

   -- Vector math helpers
   function Dot_Product (A, B : Feature_Vector) return Real;
   function "+" (A, B : Feature_Vector) return Feature_Vector;
   function "-" (A, B : Feature_Vector) return Feature_Vector;
   function "*" (Scalar : Real; V : Feature_Vector) return Feature_Vector;

end Structured_SVM;
