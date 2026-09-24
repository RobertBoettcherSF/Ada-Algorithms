package body Perceptron is

   function Create (Dimensions : Positive) return Perceptron_Model is
      Result : constant Perceptron_Model (Dimensions) :=
        (Dimensions         => Dimensions,
         Weights            => [others => 0.0],
         Bias               => 0.0,
         Pocket_Weights     => [others => 0.0],
         Pocket_Bias        => 0.0,
         Best_Run           => 0,
         Averaged_Weights   => [others => 0.0],
         Averaged_Bias      => 0.0,
         Total_Samples_Seen => 0);
   begin
      return Result;
   end Create;

   -- Internal helper: Calculate dot product of weights against a specific matrix row.
   -- Avoids creating temporary vectors and allocations.
   function Compute_Activation (Weights : Vector; Bias : Real; X : Matrix; Row : Positive) return Real is
      Sum   : Real := Bias;
      W_Idx : Positive := Weights'First;
   begin
      for Col in X'Range(2) loop
         Sum := Sum + Weights (W_Idx) * X (Row, Col);
         W_Idx := W_Idx + 1;
      end loop;
      return Sum;
   end Compute_Activation;

   -- Internal helper: Calculate dot product of weights against a 1D vector (for prediction).
   function Compute_Predict_Activation (Weights : Vector; Bias : Real; X : Vector) return Real is
      Sum   : Real := Bias;
      W_Idx : Positive := Weights'First;
      X_Idx : Positive := X'First;
   begin
      for J in 1 .. Weights'Length loop
         Sum := Sum + Weights (W_Idx) * X (X_Idx);
         W_Idx := W_Idx + 1;
         X_Idx := X_Idx + 1;
      end loop;
      return Sum;
   end Compute_Predict_Activation;

   procedure Train_Standard
     (Model         : in out Perceptron_Model;
      X             : in Matrix;
      Y             : in Label_Array;
      Epochs        : in Positive;
      Learning_Rate : in Real)
   is
      Epoch_Count : Positive := 1;
   begin
      while Epoch_Count <= Epochs loop
         declare
            Y_Idx : Positive := Y'First;
         begin
            for I in X'Range(1) loop
               declare
                  Act  : constant Real := Compute_Activation (Model.Weights, Model.Bias, X, I);
                  Pred : constant Valid_Label := (if Act > 0.0 then 1 else -1);
               begin
                  if Pred /= Y (Y_Idx) then
                     -- Apply the standard perceptron learning rule
                     declare
                        W_Idx : Positive := Model.Weights'First;
                     begin
                        for Col in X'Range(2) loop
                           Model.Weights (W_Idx) := Model.Weights (W_Idx) + Learning_Rate * Real (Y (Y_Idx)) * X (I, Col);
                           W_Idx := W_Idx + 1;
                        end loop;
                     end;
                     Model.Bias := Model.Bias + Learning_Rate * Real (Y (Y_Idx));
                  end if;
               end;
               Y_Idx := Y_Idx + 1;
            end loop;
         end;
         Epoch_Count := Epoch_Count + 1;
      end loop;
   end Train_Standard;

   function Predict_Standard
     (Model : Perceptron_Model;
      X     : in Vector) return Valid_Label
   is
      Act : constant Real := Compute_Predict_Activation (Model.Weights, Model.Bias, X);
   begin
      return (if Act > 0.0 then 1 else -1);
   end Predict_Standard;

   procedure Train_Pocket
     (Model         : in out Perceptron_Model;
      X             : in Matrix;
      Y             : in Label_Array;
      Epochs        : in Positive;
      Learning_Rate : in Real)
   is
      Run_Length  : Natural := 0;
      Epoch_Count : Positive := 1;
   begin
      while Epoch_Count <= Epochs loop
         declare
            Y_Idx : Positive := Y'First;
         begin
            for I in X'Range(1) loop
               declare
                  Act  : constant Real := Compute_Activation (Model.Weights, Model.Bias, X, I);
                  Pred : constant Valid_Label := (if Act > 0.0 then 1 else -1);
               begin
                  if Pred = Y (Y_Idx) then
                     -- Correct prediction: increase run length and evaluate pocket
                     Run_Length := Run_Length + 1;
                     if Run_Length > Model.Best_Run then
                        Model.Best_Run := Run_Length;
                        Model.Pocket_Weights := Model.Weights;
                        Model.Pocket_Bias := Model.Bias;
                     end if;
                  else
                     -- Incorrect prediction: reset run length and update standard weights
                     Run_Length := 0;
                     declare
                        W_Idx : Positive := Model.Weights'First;
                     begin
                        for Col in X'Range(2) loop
                           Model.Weights (W_Idx) := Model.Weights (W_Idx) + Learning_Rate * Real (Y (Y_Idx)) * X (I, Col);
                           W_Idx := W_Idx + 1;
                        end loop;
                     end;
                     Model.Bias := Model.Bias + Learning_Rate * Real (Y (Y_Idx));
                  end if;
               end;
               Y_Idx := Y_Idx + 1;
            end loop;
         end;
         Epoch_Count := Epoch_Count + 1;
      end loop;
   end Train_Pocket;

   function Predict_Pocket
     (Model : Perceptron_Model;
      X     : in Vector) return Valid_Label
   is
      Act : constant Real := Compute_Predict_Activation (Model.Pocket_Weights, Model.Pocket_Bias, X);
   begin
      return (if Act > 0.0 then 1 else -1);
   end Predict_Pocket;

   procedure Train_Averaged
     (Model         : in out Perceptron_Model;
      X             : in Matrix;
      Y             : in Label_Array;
      Epochs        : in Positive;
      Learning_Rate : in Real)
   is
      Epoch_Count : Positive := 1;
   begin
      while Epoch_Count <= Epochs loop
         declare
            Y_Idx : Positive := Y'First;
         begin
            for I in X'Range(1) loop
               declare
                  Act  : constant Real := Compute_Activation (Model.Weights, Model.Bias, X, I);
                  Pred : constant Valid_Label := (if Act > 0.0 then 1 else -1);
               begin
                  -- Phase 1: Standard update rule
                  if Pred /= Y (Y_Idx) then
                     declare
                        W_Idx : Positive := Model.Weights'First;
                     begin
                        for Col in X'Range(2) loop
                           Model.Weights (W_Idx) := Model.Weights (W_Idx) + Learning_Rate * Real (Y (Y_Idx)) * X (I, Col);
                           W_Idx := W_Idx + 1;
                        end loop;
                     end;
                     Model.Bias := Model.Bias + Learning_Rate * Real (Y (Y_Idx));
                  end if;

                  -- Phase 2: Averaging update
                  -- To maintain numerical stability across many epochs, we compute an iterative running mean
                  Model.Total_Samples_Seen := Model.Total_Samples_Seen + 1;
                  declare
                     N      : constant Real := Real (Model.Total_Samples_Seen);
                     W_Idx  : Positive := Model.Weights'First;
                     AW_Idx : Positive := Model.Averaged_Weights'First;
                  begin
                     for J in 1 .. Model.Dimensions loop
                        -- Running average: A_new = A_old + (W_current - A_old) / N
                        Model.Averaged_Weights (AW_Idx) :=
                          Model.Averaged_Weights (AW_Idx) + (Model.Weights (W_Idx) - Model.Averaged_Weights (AW_Idx)) / N;
                        W_Idx := W_Idx + 1;
                        AW_Idx := AW_Idx + 1;
                     end loop;
                     Model.Averaged_Bias := Model.Averaged_Bias + (Model.Bias - Model.Averaged_Bias) / N;
                  end;
               end;
               Y_Idx := Y_Idx + 1;
            end loop;
         end;
         Epoch_Count := Epoch_Count + 1;
      end loop;
   end Train_Averaged;

   function Predict_Averaged
     (Model : Perceptron_Model;
      X     : in Vector) return Valid_Label
   is
      Act : constant Real := Compute_Predict_Activation (Model.Averaged_Weights, Model.Averaged_Bias, X);
   begin
      return (if Act > 0.0 then 1 else -1);
   end Predict_Averaged;

end Perceptron;
