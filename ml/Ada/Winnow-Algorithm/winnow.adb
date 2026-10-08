-- winnow.adb
-- Implementation of the Winnow Algorithm and its variants.

package body Winnow is

   -----------------------------------------------------------------------------
   -- Helper Functions
   -----------------------------------------------------------------------------
   function Calculate_Dot_Product (W : Weight_Vector; X : Feature_Vector) return Float is
      Sum : Float := 0.0;
   begin
      if W'Length /= X'Length then
         raise Invalid_Input_Error with "Vector lengths must match.";
      end if;

      for I in W'Range loop
         -- Offset index to handle potentially different starting indices safely
         Sum := Sum + W (I) * Float (X (X'First + (I - W'First)));
      end loop;
      
      return Sum;
   end Calculate_Dot_Product;

   -----------------------------------------------------------------------------
   -- Standard Winnow Implementation
   -----------------------------------------------------------------------------
   function Initialize 
     (N : Positive; Alpha : Float := 2.0; Threshold : Float := -1.0) 
      return Winnow_Model 
   is
      Initial_Weights : constant Weight_Vector (1 .. N) := (others => 1.0);
      Actual_Threshold : Float := Threshold;
   begin
      if Alpha <= 1.0 then
         raise Configuration_Error with "Alpha must be strictly greater than 1.0";
      end if;

      if Actual_Threshold < 0.0 then
         Actual_Threshold := Float (N) / 2.0;
      end if;

      return (N => N, Weights => Initial_Weights, Alpha => Alpha, Threshold => Actual_Threshold);
   end Initialize;

   function Predict (Model : Winnow_Model; X : Feature_Vector) return Boolean is
   begin
      if X'Length /= Model.N then
         raise Invalid_Input_Error with "Feature vector size does not match model.";
      end if;
      return Calculate_Dot_Product (Model.Weights, X) > Model.Threshold;
   end Predict;

   procedure Train (Model : in out Winnow_Model; X : Feature_Vector; Y : Boolean) is
      Prediction : Boolean;
   begin
      if X'Length /= Model.N then
         raise Invalid_Input_Error with "Feature vector size does not match model.";
      end if;

      Prediction := Predict (Model, X);

      -- Update rule only triggers on incorrect predictions
      if Prediction /= Y then
         for I in Model.Weights'Range loop
            if X (X'First + (I - Model.Weights'First)) = 1 then
               if Y then
                  -- False Negative -> Promotion
                  Model.Weights (I) := Model.Weights (I) * Model.Alpha;
               else
                  -- False Positive -> Demotion
                  Model.Weights (I) := Model.Weights (I) / Model.Alpha;
               end if;
            end if;
         end loop;
      end if;
   end Train;


   -----------------------------------------------------------------------------
   -- Balanced Winnow Implementation
   -----------------------------------------------------------------------------
   function Initialize_Balanced 
     (N : Positive; Alpha : Float := 2.0; Threshold : Float := 0.0) 
      return Balanced_Winnow_Model 
   is
      Initial_Weights : constant Weight_Vector (1 .. N) := (others => 2.0);
   begin
      if Alpha <= 1.0 then
         raise Configuration_Error with "Alpha must be strictly greater than 1.0";
      end if;

      return (N           => N, 
              Weights_Pos => Initial_Weights, 
              Weights_Neg => Initial_Weights, 
              Alpha       => Alpha, 
              Threshold   => Threshold);
   end Initialize_Balanced;

   function Predict (Model : Balanced_Winnow_Model; X : Feature_Vector) return Boolean is
      Sum_Pos, Sum_Neg : Float;
   begin
      if X'Length /= Model.N then
         raise Invalid_Input_Error with "Feature vector size does not match model.";
      end if;
      
      Sum_Pos := Calculate_Dot_Product (Model.Weights_Pos, X);
      Sum_Neg := Calculate_Dot_Product (Model.Weights_Neg, X);
      
      return (Sum_Pos - Sum_Neg) > Model.Threshold;
   end Predict;

   procedure Train (Model : in out Balanced_Winnow_Model; X : Feature_Vector; Y : Boolean) is
      Prediction : Boolean;
   begin
      if X'Length /= Model.N then
         raise Invalid_Input_Error with "Feature vector size does not match model.";
      end if;

      Prediction := Predict (Model, X);

      -- Update weights only when wrong
      if Prediction /= Y then
         for I in Model.Weights_Pos'Range loop
            if X (X'First + (I - Model.Weights_Pos'First)) = 1 then
               if Y then
                  -- False Negative -> Promote Pos, Demote Neg
                  Model.Weights_Pos (I) := Model.Weights_Pos (I) * Model.Alpha;
                  Model.Weights_Neg (I) := Model.Weights_Neg (I) / Model.Alpha;
               else
                  -- False Positive -> Demote Pos, Promote Neg
                  Model.Weights_Pos (I) := Model.Weights_Pos (I) / Model.Alpha;
                  Model.Weights_Neg (I) := Model.Weights_Neg (I) * Model.Alpha;
               end if;
            end if;
         end loop;
      end if;
   end Train;

end Winnow;
