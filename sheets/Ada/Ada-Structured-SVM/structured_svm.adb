package body Structured_SVM is

   function Dot_Product (A, B : Feature_Vector) return Real is
      Sum : Real := 0.0;
   begin
      for I in A'Range loop
         Sum := Sum + A (I) * B (I);
      end loop;
      return Sum;
   end Dot_Product;

   function "+" (A, B : Feature_Vector) return Feature_Vector is
      Result : Feature_Vector;
   begin
      for I in A'Range loop
         Result (I) := A (I) + B (I);
      end loop;
      return Result;
   end "+";

   function "-" (A, B : Feature_Vector) return Feature_Vector is
      Result : Feature_Vector;
   begin
      for I in A'Range loop
         Result (I) := A (I) - B (I);
      end loop;
      return Result;
   end "-";

   function "*" (Scalar : Real; V : Feature_Vector) return Feature_Vector is
      Result : Feature_Vector;
   begin
      for I in V'Range loop
         Result (I) := Scalar * V (I);
      end loop;
      return Result;
   end "*";

   function Train_Margin_Rescaling
     (Inputs : Dataset_Array;
      Labels : Label_Array;
      Lambda : Real;
      Epochs : Positive) return Model
   is
      W         : Feature_Vector := [others => 0.0];
      T         : Long_Integer := 1;
      Eta       : Real;
      Y_Hat     : Output_Type;
      Delta_Phi : Feature_Vector;
   begin
      if Inputs'Length /= Labels'Length then
         raise Dataset_Size_Mismatch;
      end if;
      if Inputs'Length = 0 then
         raise Empty_Dataset;
      end if;
      if Lambda <= 0.0 then
         raise Invalid_Hyperparameter;
      end if;

      for Epoch in 1 .. Epochs loop
         pragma Unreferenced (Epoch); -- GNAT suppression
         
         for I in Inputs'Range loop
            -- Learning rate scheduling: 1 / (lambda * t)
            Eta := 1.0 / (Lambda * Real (T));
            
            -- Find the most violated constraint (Margin formulation)
            Y_Hat := Argmax_Margin_Rescaling (Inputs (I), Labels (I), W);
            Delta_Phi := Joint_Feature_Map (Inputs (I), Labels (I)) - Joint_Feature_Map (Inputs (I), Y_Hat);

            -- Subgradient update step incorporating regularization decay
            -- W := W - Eta * (Lambda * W - Delta_Phi)
            -- W := (1 - Eta * Lambda) * W + Eta * Delta_Phi
            -- Since Eta = 1 / (Lambda * T), (1 - Eta * Lambda) = (T - 1) / T
            W := ((Real (T) - 1.0) / Real (T)) * W + Eta * Delta_Phi;

            T := T + 1;
         end loop;
      end loop;
      
      return (Weights => W);
   end Train_Margin_Rescaling;

   function Train_Slack_Rescaling
     (Inputs : Dataset_Array;
      Labels : Label_Array;
      Lambda : Real;
      Epochs : Positive) return Model
   is
      W         : Feature_Vector := [others => 0.0];
      T         : Long_Integer := 1;
      Eta       : Real;
      Y_Hat     : Output_Type;
      Delta_Phi : Feature_Vector;
      Loss_Val  : Real;
   begin
      if Inputs'Length /= Labels'Length then
         raise Dataset_Size_Mismatch;
      end if;
      if Inputs'Length = 0 then
         raise Empty_Dataset;
      end if;
      if Lambda <= 0.0 then
         raise Invalid_Hyperparameter;
      end if;

      for Epoch in 1 .. Epochs loop
         pragma Unreferenced (Epoch); 
         
         for I in Inputs'Range loop
            Eta := 1.0 / (Lambda * Real (T));
            
            -- Find the most violated constraint (Slack formulation)
            Y_Hat := Argmax_Slack_Rescaling (Inputs (I), Labels (I), W);
            Delta_Phi := Joint_Feature_Map (Inputs (I), Labels (I)) - Joint_Feature_Map (Inputs (I), Y_Hat);
            Loss_Val := Loss (Labels (I), Y_Hat);

            -- Subgradient update for Slack Rescaling
            -- Gradient includes the loss scaling the margin violation delta_phi
            W := ((Real (T) - 1.0) / Real (T)) * W + (Eta * Loss_Val) * Delta_Phi;

            T := T + 1;
         end loop;
      end loop;
      
      return (Weights => W);
   end Train_Slack_Rescaling;

   function Predict (M : Model; X : Input_Type) return Output_Type is
   begin
      return Predict_Max (X, M.Weights);
   end Predict;

end Structured_SVM;
