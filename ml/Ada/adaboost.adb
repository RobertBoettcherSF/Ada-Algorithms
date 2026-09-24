with Ada.Numerics.Elementary_Functions;

package body Adaboost is
   use Ada.Numerics.Elementary_Functions;

   type Sample_Weight_Array is array (Sample_Index range <>) of Classifier_Weight;

   function Evaluate_Stump (Stump : Decision_Stump; Val : Feature_Value) return Class_Label is
   begin
      if Stump.Polarity = 1 then
         return (if Val > Stump.Threshold then Positive else Negative);
      else
         return (if Val <= Stump.Threshold then Positive else Negative);
      end if;
   end Evaluate_Stump;

   procedure Find_Best_Stump
     (X          : in Features_Matrix;
      Y          : in Labels_Array;
      D          : in Sample_Weight_Array;
      Best_Stump : out Decision_Stump;
      Min_Error  : out Classifier_Weight)
   is
      Err  : Classifier_Weight;
      Pred : Class_Label;
   begin
      Min_Error := Classifier_Weight'Last;
      Best_Stump := (Feature => X'First (2), Threshold => 0.0, Polarity => 1);

      for J in X'Range (2) loop
         for I in X'Range (1) loop
            declare
               Thresh : constant Feature_Value := X (I, J);
            begin
               -- Test Polarity 1 (Val > Threshold => Positive)
               Err := 0.0;
               for K in X'Range (1) loop
                  Pred := (if X (K, J) > Thresh then Positive else Negative);
                  if Pred /= Y (K) then
                     Err := Err + D (K);
                  end if;
               end loop;
               if Err < Min_Error then
                  Min_Error := Err;
                  Best_Stump := (Feature => J, Threshold => Thresh, Polarity => 1);
               end if;

               -- Test Polarity -1 (Val <= Threshold => Positive)
               Err := 0.0;
               for K in X'Range (1) loop
                  Pred := (if X (K, J) <= Thresh then Positive else Negative);
                  if Pred /= Y (K) then
                     Err := Err + D (K);
                  end if;
               end loop;
               if Err < Min_Error then
                  Min_Error := Err;
                  Best_Stump := (Feature => J, Threshold => Thresh, Polarity => -1);
               end if;
            end;
         end loop;
      end loop;
   end Find_Best_Stump;

   procedure Train
     (Model      : out AdaBoost_Model;
      X          : in Features_Matrix;
      Y          : in Labels_Array)
   is
   begin
      Model.Count := 0;
      Model.Feature_Count := 0;
      Model.Learners := [others => (Feature => 1, Threshold => 0.0, Polarity => 1)];
      Model.Alphas := [others => 0.0];

      if X'Length (1) = 0 or else X'Length (2) = 0 then
         raise Empty_Dataset_Error;
      end if;
      
      if X'Length (1) /= Y'Length then
         raise Dimension_Mismatch_Error;
      end if;

      Model.Feature_Count := Natural (X'Length (2));

      declare
         D : Sample_Weight_Array (X'Range (1)) := 
           [others => 1.0 / Classifier_Weight (X'Length (1))];
         Stump : Decision_Stump;
         Err   : Classifier_Weight;
      begin
         for Iter in 1 .. Model.Max_Iterations loop
            Find_Best_Stump (X, Y, D, Stump, Err);

            -- If the weak learner is worse than or equal to random guessing, abort loop early
            if Err >= 0.5 - 1.0e-5 then
               exit;
            end if;

            declare
               -- Bound error to prevent division by zero or Log(0)
               Eps   : constant Classifier_Weight := Classifier_Weight'Max (Err, 1.0e-10);
               Alpha : constant Classifier_Weight := 
                 0.5 * Classifier_Weight (Log (Float (1.0 - Eps) / Float (Eps)));
               Z     : Classifier_Weight := 0.0;
            begin
               Model.Count := Iter;
               Model.Learners (Iter) := Stump;
               Model.Alphas (Iter) := Alpha;

               -- Stop early if we have a perfect classifier
               if Err < 1.0e-10 then
                  exit;
               end if;

               -- Update distributions
               for I in X'Range (1) loop
                  declare
                     Pred_Lbl : constant Class_Label := Evaluate_Stump (Stump, X (I, Stump.Feature));
                     Pred_Num : constant Float := (if Pred_Lbl = Positive then 1.0 else -1.0);
                     Y_Num    : constant Float := (if Y (I) = Positive then 1.0 else -1.0);
                     Factor   : constant Float := Exp (-Float (Alpha) * Y_Num * Pred_Num);
                  begin
                     D (I) := D (I) * Classifier_Weight (Factor);
                     Z := Z + D (I);
                  end;
               end loop;

               -- Normalize distributions
               for I in X'Range (1) loop
                  D (I) := D (I) / Z;
               end loop;
            end;
         end loop;
      end;
   end Train;

   function Predict_Score
     (Model : in AdaBoost_Model;
      X     : in Feature_Vector) return Classifier_Weight
   is
      Score : Classifier_Weight := 0.0;
      Pred  : Class_Label;
      Val   : Float;
   begin
      if Model.Feature_Count > 0 and then X'Length /= Model.Feature_Count then
         raise Dimension_Mismatch_Error;
      end if;

      for Iter in 1 .. Model.Count loop
         Pred := Evaluate_Stump (Model.Learners (Iter), X (Model.Learners (Iter).Feature));
         Val  := (if Pred = Positive then 1.0 else -1.0);
         Score := Score + Model.Alphas (Iter) * Classifier_Weight (Val);
      end loop;
      return Score;
   end Predict_Score;

   function Predict
     (Model : in AdaBoost_Model;
      X     : in Feature_Vector) return Class_Label is
   begin
      if Predict_Score (Model, X) >= 0.0 then
         return Positive;
      else
         return Negative;
      end if;
   end Predict;

end Adaboost;
