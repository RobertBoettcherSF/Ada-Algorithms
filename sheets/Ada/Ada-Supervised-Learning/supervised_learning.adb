package body Supervised_Learning is

   -----------------------------------------------------------------------------
   -- 1. Simple Linear Regression
   -----------------------------------------------------------------------------
   function Train_Linear_Regression (Train_X, Train_Y : Vector) return Linear_Model is
      N : constant Natural := Train_X'Length;
   begin
      -- Validate inputs internally for robustness beyond Pre aspect
      if N < 2 then 
         raise Insufficient_Data_Error; 
      end if;
      if Train_X'Length /= Train_Y'Length then 
         raise Dimension_Mismatch_Error; 
      end if;

      declare
         Sum_X, Sum_Y, Sum_XY, Sum_XX : Real := 0.0;
         Mean_X, Mean_Y : Real;
         Slope, Intercept : Real;
         X_Idx : Positive := Train_X'First;
         Y_Idx : Positive := Train_Y'First;
      begin
         -- Calculate Means
         for I in 1 .. N loop
            Sum_X := Sum_X + Train_X(X_Idx);
            Sum_Y := Sum_Y + Train_Y(Y_Idx);
            X_Idx := X_Idx + 1;
            Y_Idx := Y_Idx + 1;
         end loop;
         Mean_X := Sum_X / Real(N);
         Mean_Y := Sum_Y / Real(N);

         -- Calculate Covariance/Variance sums
         X_Idx := Train_X'First;
         Y_Idx := Train_Y'First;
         for I in 1 .. N loop
            declare
               X_Diff : constant Real := Train_X(X_Idx) - Mean_X;
               Y_Diff : constant Real := Train_Y(Y_Idx) - Mean_Y;
            begin
               Sum_XX := Sum_XX + (X_Diff * X_Diff);
               Sum_XY := Sum_XY + (X_Diff * Y_Diff);
            end;
            X_Idx := X_Idx + 1;
            Y_Idx := Y_Idx + 1;
         end loop;

         -- Prevent division by zero if all X values are identical
         if abs (Sum_XX) < 1.0E-9 then 
            raise Zero_Variance_Error; 
         end if;

         Slope := Sum_XY / Sum_XX;
         Intercept := Mean_Y - (Slope * Mean_X);

         return (Slope => Slope, Intercept => Intercept);
      end;
   end Train_Linear_Regression;

   function Predict_Linear_Regression (Model : Linear_Model; Test_X : Real) return Real is
   begin
      return (Model.Slope * Test_X) + Model.Intercept;
   end Predict_Linear_Regression;


   -----------------------------------------------------------------------------
   -- 2. K-Nearest Neighbors Classification
   -----------------------------------------------------------------------------
   function Predict_KNN (Train_X : Matrix; Train_Y : Label_Array; Test_X : Vector; K : K_Value) return Class_Label is
   begin
      -- Dynamic length validations
      if Train_X'Length(1) = 0 or else Train_X'Length(2) = 0 then
         raise Insufficient_Data_Error;
      end if;
      if Train_X'Length(1) /= Train_Y'Length then
         raise Dimension_Mismatch_Error;
      end if;
      if Train_X'Length(2) /= Test_X'Length then
         raise Dimension_Mismatch_Error;
      end if;
      if Natural(K) > Train_X'Length(1) then
         raise Invalid_Hyperparameter_Error;
      end if;

      declare
         type Distance_Record is record
            Dist  : Real;
            Label : Class_Label;
         end record;
         type Distance_Array is array (1 .. Train_X'Length(1)) of Distance_Record;
         
         Distances       : Distance_Array;
         Row_Idx         : Positive := 1;
         Train_Row       : Positive := Train_X'First(1);
         Train_Label_Idx : Positive := Train_Y'First;
      begin
         -- Calculate Squared Euclidean Distances (avoid sqrt to save cycles)
         for I in 1 .. Train_X'Length(1) loop
            declare
               Sum_Sq   : Real := 0.0;
               Test_Idx : Positive := Test_X'First;
               Col_Idx  : Positive := Train_X'First(2);
            begin
               for J in 1 .. Train_X'Length(2) loop
                  declare
                     Diff : constant Real := Train_X(Train_Row, Col_Idx) - Test_X(Test_Idx);
                  begin
                     Sum_Sq := Sum_Sq + (Diff * Diff);
                  end;
                  Test_Idx := Test_Idx + 1;
                  Col_Idx := Col_Idx + 1;
               end loop;
               
               Distances(Row_Idx) := (Dist => Sum_Sq, Label => Train_Y(Train_Label_Idx));
               Row_Idx := Row_Idx + 1;
               Train_Row := Train_Row + 1;
               Train_Label_Idx := Train_Label_Idx + 1;
            end;
         end loop;

         -- Sort Distances using Insertion Sort (Stable, fast for small arrays)
         for I in 2 .. Distances'Last loop
            declare
               Key : constant Distance_Record := Distances(I);
               J   : Integer := I - 1;
            begin
               while J >= Distances'First and then Distances(J).Dist > Key.Dist loop
                  Distances(J + 1) := Distances(J);
                  J := J - 1;
               end loop;
               Distances(J + 1) := Key;
            end;
         end loop;

         -- Perform Majority Voting among top K
         declare
            type Count_Record is record
               Label : Class_Label;
               Count : Natural;
            end record;
            type Count_Array is array (1 .. Natural(K)) of Count_Record;
            
            Counts       : Count_Array := (others => (Label => 0, Count => 0));
            Unique_Count : Natural := 0;
            Max_Count    : Natural := 0;
            Best_Label   : Class_Label := Distances(1).Label;
         begin
            for I in 1 .. Natural(K) loop
               declare
                  Found : Boolean := False;
               begin
                  for J in 1 .. Unique_Count loop
                     if Counts(J).Label = Distances(I).Label then
                        Counts(J).Count := Counts(J).Count + 1;
                        Found := True;
                        exit;
                     end if;
                  end loop;
                  
                  if not Found then
                     Unique_Count := Unique_Count + 1;
                     Counts(Unique_Count) := (Label => Distances(I).Label, Count => 1);
                  end if;
               end;
            end loop;

            -- Find label with maximum vote
            for I in 1 .. Unique_Count loop
               if Counts(I).Count > Max_Count then
                  Max_Count  := Counts(I).Count;
                  Best_Label := Counts(I).Label;
               end if;
            end loop;
            
            return Best_Label;
         end;
      end;
   end Predict_KNN;


   -----------------------------------------------------------------------------
   -- 3. Simple Perceptron Classification
   -----------------------------------------------------------------------------
   function Train_Perceptron (Train_X : Matrix; Train_Y : Label_Array; Learning_Rate : Real; Epochs : Epoch_Count) return Perceptron_Model is
   begin
      if Train_X'Length(1) = 0 or else Train_X'Length(2) = 0 then
         raise Insufficient_Data_Error;
      end if;
      if Train_X'Length(1) /= Train_Y'Length then
         raise Dimension_Mismatch_Error;
      end if;
      if Learning_Rate <= 0.0 then
         raise Invalid_Hyperparameter_Error;
      end if;

      declare
         Model : Perceptron_Model (Dimension => Train_X'Length(2));
      begin
         -- Initialize Weights & Bias to zero
         for I in Model.Weights'Range loop
            Model.Weights(I) := 0.0;
         end loop;
         Model.Bias := 0.0;

         -- Train for specified epochs
         for Epoch in 1 .. Natural(Epochs) loop
            pragma Unreferenced (Epoch);
            declare
               Train_Row       : Positive := Train_X'First(1);
               Train_Label_Idx : Positive := Train_Y'First;
            begin
               for I in 1 .. Train_X'Length(1) loop
                  declare
                     Activation : Real := Model.Bias;
                     Y_True     : constant Real := Real (Integer (Train_Y(Train_Label_Idx)));
                     Pred       : Real;
                     Weight_Idx : Positive := Model.Weights'First;
                     Col_Idx    : Positive := Train_X'First(2);
                  begin
                     -- Validate proper perceptron labels
                     if abs (Y_True - 1.0) > 0.0001 and then abs (Y_True + 1.0) > 0.0001 then
                        raise Invalid_Label_Error;
                     end if;

                     -- Dot product
                     for J in 1 .. Train_X'Length(2) loop
                        Activation := Activation + (Model.Weights(Weight_Idx) * Train_X(Train_Row, Col_Idx));
                        Weight_Idx := Weight_Idx + 1;
                        Col_Idx := Col_Idx + 1;
                     end loop;

                     -- Step function
                     if Activation >= 0.0 then
                        Pred := 1.0;
                     else
                        Pred := -1.0;
                     end if;

                     -- Apply update rule if prediction is wrong
                     if abs (Pred - Y_True) > 0.0001 then
                        Weight_Idx := Model.Weights'First;
                        Col_Idx := Train_X'First(2);
                        for J in 1 .. Train_X'Length(2) loop
                           Model.Weights(Weight_Idx) := Model.Weights(Weight_Idx) + (Learning_Rate * Y_True * Train_X(Train_Row, Col_Idx));
                           Weight_Idx := Weight_Idx + 1;
                           Col_Idx := Col_Idx + 1;
                        end loop;
                        Model.Bias := Model.Bias + (Learning_Rate * Y_True);
                     end if;
                  end;
                  Train_Row := Train_Row + 1;
                  Train_Label_Idx := Train_Label_Idx + 1;
               end loop;
            end;
         end loop;
         return Model;
      end;
   end Train_Perceptron;

   function Predict_Perceptron (Model : Perceptron_Model; Test_X : Vector) return Class_Label is
      Activation : Real := Model.Bias;
      Weight_Idx : Positive := Model.Weights'First;
      Test_Idx   : Positive := Test_X'First;
   begin
      if Test_X'Length /= Model.Dimension then 
         raise Dimension_Mismatch_Error; 
      end if;

      for J in 1 .. Model.Dimension loop
         Activation := Activation + (Model.Weights(Weight_Idx) * Test_X(Test_Idx));
         Weight_Idx := Weight_Idx + 1;
         Test_Idx := Test_Idx + 1;
      end loop;

      if Activation >= 0.0 then
         return 1;
      else
         return -1;
      end if;
   end Predict_Perceptron;

end Supervised_Learning;
