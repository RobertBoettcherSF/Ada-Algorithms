package body Naive_Bayes is

   Pi : constant Real := 3.14159_26535_89793_23846;

   ----------------------------------------------------------------------------
   --  Gaussian Naive Bayes Implementation
   ----------------------------------------------------------------------------

   function Train_Gaussian
     (X             : Feature_Matrix;
      Y             : Label_Vector;
      Num_Classes   : Positive;
      Var_Smoothing : Real := 1.0e-9) return Gaussian_Model
   is
      Num_Features : constant Positive := X'Length (2);
      Model        : Gaussian_Model (Num_Classes, Num_Features);
      
      Class_Counts : Vector (1 .. Num_Classes) := [others => 0.0];
   begin
      --  Initialize arrays
      Model.Log_Priors := [others => 0.0];
      Model.Means      := [others => [others => 0.0]];
      Model.Variances  := [others => [others => 0.0]];

      --  First pass: Calculate means and class occurrences
      for Row_Idx in X'Range (1) loop
         declare
            L_Idx : constant Positive := Y'First + (Row_Idx - X'First (1));
            C_Idx : constant Positive := Positive (Y (L_Idx));
         begin
            if C_Idx > Num_Classes then
               raise Data_Error with "Label exceeds Num_Classes";
            end if;

            Class_Counts (C_Idx) := Class_Counts (C_Idx) + 1.0;
            
            for Col_Idx in X'Range (2) loop
               declare
                  F_Idx : constant Positive := 1 + (Col_Idx - X'First (2));
               begin
                  Model.Means (C_Idx, F_Idx) := Model.Means (C_Idx, F_Idx) + X (Row_Idx, Col_Idx);
               end;
            end loop;
         end;
      end loop;

      for C in 1 .. Num_Classes loop
         if Class_Counts (C) > 0.0 then
            for F in 1 .. Num_Features loop
               Model.Means (C, F) := Model.Means (C, F) / Class_Counts (C);
            end loop;
         end if;
      end loop;

      --  Second pass: Calculate variances
      for Row_Idx in X'Range (1) loop
         declare
            L_Idx : constant Positive := Y'First + (Row_Idx - X'First (1));
            C_Idx : constant Positive := Positive (Y (L_Idx));
         begin
            for Col_Idx in X'Range (2) loop
               declare
                  F_Idx : constant Positive := 1 + (Col_Idx - X'First (2));
                  Diff  : constant Real := X (Row_Idx, Col_Idx) - Model.Means (C_Idx, F_Idx);
               begin
                  Model.Variances (C_Idx, F_Idx) := Model.Variances (C_Idx, F_Idx) + (Diff * Diff);
               end;
            end loop;
         end;
      end loop;

      for C in 1 .. Num_Classes loop
         if Class_Counts (C) > 0.0 then
            --  Calculate final variance with smoothing applied
            for F in 1 .. Num_Features loop
               Model.Variances (C, F) := (Model.Variances (C, F) / Class_Counts (C)) + Var_Smoothing;
            end loop;
            --  Calculate Log Prior
            Model.Log_Priors (C) := Real_Math.Log (Class_Counts (C) / Real (X'Length (1)));
         else
            --  Handle classes with zero samples safely
            for F in 1 .. Num_Features loop
               Model.Variances (C, F) := Var_Smoothing;
            end loop;
            Model.Log_Priors (C) := -1.0e30; -- Effectively zero probability
         end if;
      end loop;

      return Model;
   end Train_Gaussian;

   function Predict_Gaussian
     (Model : Gaussian_Model;
      X     : Feature_Vector) return Class_ID
   is
      Best_Class : Class_ID := 1;
      Max_Prob   : Real := Real'First;
      Prob       : Real;
   begin
      for C in 1 .. Model.Num_Classes loop
         Prob := Model.Log_Priors (C);
         
         for F_Idx in 1 .. Model.Num_Features loop
            declare
               Val  : constant Real := X (X'First + F_Idx - 1);
               Mean : constant Real := Model.Means (C, F_Idx);
               Var  : constant Real := Model.Variances (C, F_Idx);
            begin
               Prob := Prob - 0.5 * Real_Math.Log (2.0 * Pi * Var) - ((Val - Mean) ** 2) / (2.0 * Var);
            end;
         end loop;

         if Prob > Max_Prob then
            Max_Prob := Prob;
            Best_Class := Class_ID (C);
         end if;
      end loop;

      return Best_Class;
   end Predict_Gaussian;


   ----------------------------------------------------------------------------
   --  Multinomial Naive Bayes Implementation
   ----------------------------------------------------------------------------

   function Train_Multinomial
     (X           : Feature_Matrix;
      Y           : Label_Vector;
      Num_Classes : Positive;
      Alpha       : Real := 1.0) return Multinomial_Model
   is
      Num_Features : constant Positive := X'Length (2);
      Model        : Multinomial_Model (Num_Classes, Num_Features);
      
      Feature_Counts : Matrix (1 .. Num_Classes, 1 .. Num_Features) := [others => [others => 0.0]];
      Class_Counts   : Vector (1 .. Num_Classes) := [others => 0.0];
      Class_Totals   : Vector (1 .. Num_Classes) := [others => 0.0];
   begin
      Model.Log_Priors := [others => 0.0];
      Model.Log_Probabilities := [others => [others => 0.0]];

      --  Accumulate word/feature frequencies
      for Row_Idx in X'Range (1) loop
         declare
            L_Idx : constant Positive := Y'First + (Row_Idx - X'First (1));
            C_Idx : constant Positive := Positive (Y (L_Idx));
         begin
            if C_Idx > Num_Classes then
               raise Data_Error with "Label exceeds Num_Classes";
            end if;

            Class_Counts (C_Idx) := Class_Counts (C_Idx) + 1.0;

            for Col_Idx in X'Range (2) loop
               declare
                  F_Idx : constant Positive := 1 + (Col_Idx - X'First (2));
                  Val   : constant Real := X (Row_Idx, Col_Idx);
               begin
                  Feature_Counts (C_Idx, F_Idx) := Feature_Counts (C_Idx, F_Idx) + Val;
                  Class_Totals (C_Idx) := Class_Totals (C_Idx) + Val;
               end;
            end loop;
         end;
      end loop;

      --  Calculate Log Probabilities and Priors with Laplace smoothing
      for C in 1 .. Num_Classes loop
         if Class_Counts (C) > 0.0 then
            Model.Log_Priors (C) := Real_Math.Log (Class_Counts (C) / Real (X'Length (1)));
         else
            Model.Log_Priors (C) := -1.0e30;
         end if;

         declare
            Denominator : constant Real := Class_Totals (C) + Alpha * Real (Num_Features);
         begin
            for F in 1 .. Num_Features loop
               declare
                  Numerator : constant Real := Feature_Counts (C, F) + Alpha;
               begin
                  Model.Log_Probabilities (C, F) := Real_Math.Log (Numerator / Denominator);
               end;
            end loop;
         end;
      end loop;

      return Model;
   end Train_Multinomial;

   function Predict_Multinomial
     (Model : Multinomial_Model;
      X     : Feature_Vector) return Class_ID
   is
      Best_Class : Class_ID := 1;
      Max_Prob   : Real := Real'First;
      Prob       : Real;
   begin
      for C in 1 .. Model.Num_Classes loop
         Prob := Model.Log_Priors (C);
         
         for F_Idx in 1 .. Model.Num_Features loop
            declare
               Val : constant Real := X (X'First + F_Idx - 1);
            begin
               Prob := Prob + Val * Model.Log_Probabilities (C, F_Idx);
            end;
         end loop;

         if Prob > Max_Prob then
            Max_Prob := Prob;
            Best_Class := Class_ID (C);
         end if;
      end loop;

      return Best_Class;
   end Predict_Multinomial;


   ----------------------------------------------------------------------------
   --  Bernoulli Naive Bayes Implementation
   ----------------------------------------------------------------------------

   function Train_Bernoulli
     (X           : Feature_Matrix;
      Y           : Label_Vector;
      Num_Classes : Positive;
      Alpha       : Real := 1.0) return Bernoulli_Model
   is
      Num_Features : constant Positive := X'Length (2);
      Model        : Bernoulli_Model (Num_Classes, Num_Features);
      
      Present_Counts : Matrix (1 .. Num_Classes, 1 .. Num_Features) := [others => [others => 0.0]];
      Class_Counts   : Vector (1 .. Num_Classes) := [others => 0.0];
   begin
      Model.Log_Priors := [others => 0.0];
      Model.Log_Prob_Present := [others => [others => 0.0]];
      Model.Log_Prob_Absent  := [others => [others => 0.0]];

      --  Count documents where feature is present (Value > 0)
      for Row_Idx in X'Range (1) loop
         declare
            L_Idx : constant Positive := Y'First + (Row_Idx - X'First (1));
            C_Idx : constant Positive := Positive (Y (L_Idx));
         begin
            if C_Idx > Num_Classes then
               raise Data_Error with "Label exceeds Num_Classes";
            end if;

            Class_Counts (C_Idx) := Class_Counts (C_Idx) + 1.0;

            for Col_Idx in X'Range (2) loop
               declare
                  F_Idx : constant Positive := 1 + (Col_Idx - X'First (2));
                  Val   : constant Real := X (Row_Idx, Col_Idx);
               begin
                  if Val > 0.0 then
                     Present_Counts (C_Idx, F_Idx) := Present_Counts (C_Idx, F_Idx) + 1.0;
                  end if;
               end;
            end loop;
         end;
      end loop;

      --  Calculate probabilities using Lidstone/Laplace smoothing
      for C in 1 .. Num_Classes loop
         if Class_Counts (C) > 0.0 then
            Model.Log_Priors (C) := Real_Math.Log (Class_Counts (C) / Real (X'Length (1)));
         else
            Model.Log_Priors (C) := -1.0e30;
         end if;

         declare
            Denominator : constant Real := Class_Counts (C) + 2.0 * Alpha;
         begin
            for F in 1 .. Num_Features loop
               declare
                  Prob_Present : constant Real := (Present_Counts (C, F) + Alpha) / Denominator;
               begin
                  Model.Log_Prob_Present (C, F) := Real_Math.Log (Prob_Present);
                  Model.Log_Prob_Absent (C, F)  := Real_Math.Log (1.0 - Prob_Present);
               end;
            end loop;
         end;
      end loop;

      return Model;
   end Train_Bernoulli;

   function Predict_Bernoulli
     (Model : Bernoulli_Model;
      X     : Feature_Vector) return Class_ID
   is
      Best_Class : Class_ID := 1;
      Max_Prob   : Real := Real'First;
      Prob       : Real;
   begin
      for C in 1 .. Model.Num_Classes loop
         Prob := Model.Log_Priors (C);
         
         for F_Idx in 1 .. Model.Num_Features loop
            declare
               Val : constant Real := X (X'First + F_Idx - 1);
            begin
               if Val > 0.0 then
                  Prob := Prob + Model.Log_Prob_Present (C, F_Idx);
               else
                  Prob := Prob + Model.Log_Prob_Absent (C, F_Idx);
               end if;
            end;
         end loop;

         if Prob > Max_Prob then
            Max_Prob := Prob;
            Best_Class := Class_ID (C);
         end if;
      end loop;

      return Best_Class;
   end Predict_Bernoulli;

end Naive_Bayes;
