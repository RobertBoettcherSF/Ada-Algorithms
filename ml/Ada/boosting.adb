with Ada.Numerics.Generic_Elementary_Functions;

package body Boosting is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   -----------------------------------------------------------------------------
   --  AdaBoost.M1
   -----------------------------------------------------------------------------

   function Train_AdaBoost
     (X              : Real_Matrix;
      Y              : Real_Vector;
      Max_Iterations : Positive) return AdaBoost_Model
   is
      N           : constant Natural := X'Length (1);
      W           : Real_Vector (X'Range (1)) := (others => 1.0 / Real (N));
      Stumps      : AdaBoost_Stump_Array (1 .. Max_Iterations);
      Actual_Iter : Natural := 0;
      Min_Error   : Real;
      Best_Feat   : Positive;
      Best_Thresh : Real;
      Best_Pol    : Integer;
      Eps         : constant Real := 1.0e-9;
   begin
      --  Input Validation
      if X'Length (1) /= Y'Length then
         raise Invalid_Input_Error with "X rows must match Y length";
      end if;

      for I in Y'Range loop
         if abs (Y (I) - 1.0) > Eps and abs (Y (I) + 1.0) > Eps then
            raise Invalid_Labels_Error with "AdaBoost labels must be -1 or 1";
         end if;
      end loop;

      --  Boosting iterations
      for Iter in 1 .. Max_Iterations loop
         Min_Error   := Real'Last;
         Best_Feat   := X'First (2);
         Best_Thresh := 0.0;
         Best_Pol    := 1;

         --  Find the best weak learner (decision stump)
         for Col in X'Range (2) loop
            for Thresh_Row in X'Range (1) loop
               declare
                  Thresh : constant Real := X (Thresh_Row, Col);
               begin
                  for Pol in 1 .. 2 loop
                     declare
                        P   : constant Integer := (if Pol = 1 then 1 else -1);
                        Err : Real := 0.0;
                     begin
                        for Row in X'Range (1) loop
                           declare
                              Y_Index : constant Positive := Y'First + (Row - X'First (1));
                              Pred    : constant Real := (if (X (Row, Col) < Thresh) = (P = 1) then 1.0 else -1.0);
                           begin
                              if abs (Pred - Y (Y_Index)) > 0.5 then
                                 Err := Err + W (Row);
                              end if;
                           end;
                        end loop;

                        if Err < Min_Error then
                           Min_Error   := Err;
                           Best_Feat   := Col;
                           Best_Thresh := Thresh;
                           Best_Pol    := P;
                        end if;
                     end;
                  end loop;
               end;
            end loop;
         end loop;

         --  Check for early stopping conditions
         if Min_Error > 0.5 - Eps then
            --  Weak learner is worse than random chance; stop boosting.
            exit;
         end if;

         declare
            Alpha : Real;
            Z     : Real := 0.0;
         begin
            if Min_Error < Eps then
               Alpha := 5.0; -- Cap alpha to avoid infinity if perfect classification
            else
               Alpha := 0.5 * Math.Log ((1.0 - Min_Error) / Min_Error);
            end if;

            Actual_Iter := Actual_Iter + 1;
            Stumps (Actual_Iter) :=
              (Feature   => Best_Feat,
               Threshold => Best_Thresh,
               Polarity  => Best_Pol,
               Alpha     => Alpha);

            --  If error is virtually zero, stop after saving this stump
            if Min_Error < Eps then
               exit;
            end if;

            --  Update data weights
            for Row in X'Range (1) loop
               declare
                  Y_Index : constant Positive := Y'First + (Row - X'First (1));
                  Pred    : constant Real := (if (X (Row, Best_Feat) < Best_Thresh) = (Best_Pol = 1) then 1.0 else -1.0);
               begin
                  W (Row) := W (Row) * Math.Exp (-Alpha * Y (Y_Index) * Pred);
                  Z := Z + W (Row);
               end;
            end loop;

            --  Normalize weights to form a probability distribution
            if Z > Eps then
               for Row in X'Range (1) loop
                  W (Row) := W (Row) / Z;
               end loop;
            end if;
         end;
      end loop;

      --  Return constrained model instance
      return Model : AdaBoost_Model (Actual_Iter) do
         Model.Stumps (1 .. Actual_Iter) := Stumps (1 .. Actual_Iter);
      end return;
   end Train_AdaBoost;

   function Predict_AdaBoost
     (Model : AdaBoost_Model;
      X_Row : Real_Vector) return Real
   is
      Sum : Real := 0.0;
   begin
      for I in 1 .. Model.Num_Iterations loop
         declare
            S    : constant AdaBoost_Stump := Model.Stumps (I);
            Idx  : constant Positive := X_Row'First + (S.Feature - 1);
            Pred : constant Real := (if (X_Row (Idx) < S.Threshold) = (S.Polarity = 1) then 1.0 else -1.0);
         begin
            Sum := Sum + S.Alpha * Pred;
         end;
      end loop;

      if Sum >= 0.0 then
         return 1.0;
      else
         return -1.0;
      end if;
   end Predict_AdaBoost;

   -----------------------------------------------------------------------------
   --  Gradient Boosting (Least-Squares Regression)
   -----------------------------------------------------------------------------

   function Train_Gradient_Boosting
     (X              : Real_Matrix;
      Y              : Real_Vector;
      Max_Iterations : Natural;
      Learning_Rate  : Real := 0.1) return Gradient_Boosting_Model
   is
      N          : constant Natural := X'Length (1);
      F_Pred     : Real_Vector (X'Range (1)) := (others => 0.0);
      R          : Real_Vector (X'Range (1));
      Init_Pred  : Real := 0.0;
      Stumps     : Gradient_Stump_Array (1 .. Max_Iterations);
   begin
      --  Input Validation
      if X'Length (1) /= Y'Length then
         raise Invalid_Input_Error with "X rows must match Y length";
      end if;

      --  Step 1: Initialize model with constant value (mean of Y)
      for I in Y'Range loop
         Init_Pred := Init_Pred + Y (I);
      end loop;
      Init_Pred := Init_Pred / Real (N);

      for I in F_Pred'Range loop
         F_Pred (I) := Init_Pred;
      end loop;

      --  Step 2: Iteratively fit trees to pseudo-residuals
      for Iter in 1 .. Max_Iterations loop
         for Row in X'Range (1) loop
            declare
               Y_Index : constant Positive := Y'First + (Row - X'First (1));
            begin
               R (Row) := Y (Y_Index) - F_Pred (Row);
            end;
         end loop;

         declare
            Min_Sq_Error : Real := Real'Last;
            Best_Feat    : Positive := X'First (2);
            Best_Thresh  : Real := 0.0;
            Best_Left    : Real := 0.0;
            Best_Right   : Real := 0.0;
         begin
            --  Search for the best stump optimizing squared error
            for Col in X'Range (2) loop
               for Thresh_Row in X'Range (1) loop
                  declare
                     Thresh      : constant Real := X (Thresh_Row, Col);
                     Sum_L, Sum_R : Real := 0.0;
                     Cnt_L, Cnt_R : Real := 0.0;
                     Mean_L      : Real := 0.0;
                     Mean_R      : Real := 0.0;
                     Sq_Err      : Real := 0.0;
                  begin
                     for Row in X'Range (1) loop
                        if X (Row, Col) < Thresh then
                           Sum_L := Sum_L + R (Row);
                           Cnt_L := Cnt_L + 1.0;
                        else
                           Sum_R := Sum_R + R (Row);
                           Cnt_R := Cnt_R + 1.0;
                        end if;
                     end loop;

                     if Cnt_L > 0.5 then Mean_L := Sum_L / Cnt_L; end if;
                     if Cnt_R > 0.5 then Mean_R := Sum_R / Cnt_R; end if;

                     for Row in X'Range (1) loop
                        if X (Row, Col) < Thresh then
                           Sq_Err := Sq_Err + (R (Row) - Mean_L) ** 2;
                        else
                           Sq_Err := Sq_Err + (R (Row) - Mean_R) ** 2;
                        end if;
                     end loop;

                     if Sq_Err < Min_Sq_Error then
                        Min_Sq_Error := Sq_Err;
                        Best_Feat    := Col;
                        Best_Thresh  := Thresh;
                        Best_Left    := Mean_L;
                        Best_Right   := Mean_R;
                     end if;
                  end;
               end loop;
            end loop;

            Stumps (Iter) :=
              (Feature     => Best_Feat,
               Threshold   => Best_Thresh,
               Left_Value  => Best_Left,
               Right_Value => Best_Right,
               Weight      => Learning_Rate);

            --  Update F_Pred with new stump
            for Row in X'Range (1) loop
               if X (Row, Best_Feat) < Best_Thresh then
                  F_Pred (Row) := F_Pred (Row) + Learning_Rate * Best_Left;
               else
                  F_Pred (Row) := F_Pred (Row) + Learning_Rate * Best_Right;
               end if;
            end loop;
         end;
      end loop;

      return Model : Gradient_Boosting_Model (Max_Iterations) do
         Model.Initial_Prediction := Init_Pred;
         Model.Stumps := Stumps;
      end return;
   end Train_Gradient_Boosting;

   function Predict_Gradient_Boosting
     (Model : Gradient_Boosting_Model;
      X_Row : Real_Vector) return Real
   is
      Result : Real := Model.Initial_Prediction;
   begin
      for I in 1 .. Model.Num_Iterations loop
         declare
            S   : constant Gradient_Stump := Model.Stumps (I);
            Idx : constant Positive := X_Row'First + (S.Feature - 1);
         begin
            if X_Row (Idx) < S.Threshold then
               Result := Result + S.Weight * S.Left_Value;
            else
               Result := Result + S.Weight * S.Right_Value;
            end if;
         end;
      end loop;
      return Result;
   end Predict_Gradient_Boosting;

end Boosting;
