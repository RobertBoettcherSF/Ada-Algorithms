package body LPBoost is

   -----------------------------------------------------------------------------
   -- Internal LP Solver (Two-Phase Primal Simplex)
   -----------------------------------------------------------------------------
   -- Solves the totally corrective Primal LP for LPBoost.
   -- Minimizes: Sum(Alpha) + C * Sum(Xi)
   -- Subject to: Sum_k (Alpha_k * Y_i * h_k(x_i)) + Xi_i >= 1 for all i
   -- Returns the Alphas (hypothesis weights) and the Dual variables U (example weights).
   
   type H_Matrix_Type is array (Positive range <>, Positive range <>) of Real;
   
   procedure Solve_Master_Problem
     (H_Mat  : H_Matrix_Type;
      Nu     : Real;
      Iter   : Positive;
      U      : out Distribution;
      Alphas : in out Distribution)
   is
      M : constant Positive := H_Mat'Length (1);
      J : constant Positive := Iter;
      
      -- Column Offsets
      Col_Alpha   : constant Natural := 0;
      Col_Xi      : constant Natural := J;
      Col_Surplus : constant Natural := J + M;
      Col_Artif   : constant Natural := J + 2 * M;
      Col_RHS     : constant Natural := J + 3 * M + 1;
      
      -- Tableau: Rows 1..M (Constraints), M+1 (Phase 1 Obj), M+2 (Phase 2 Obj)
      type Tableau_Type is array (1 .. M + 2, 1 .. Col_RHS) of Real;
      T : Tableau_Type := [others => [others => 0.0]];
      
      -- Keeps track of which variable is basic in which row constraint
      Basic_Var : array (1 .. M) of Positive;
      
      C_Val : constant Real := 1.0 / (Nu * Real (M));

      procedure Do_Phase (Obj_Row : Positive; Start_Col, End_Col : Positive) is
         Entering : Natural;
         Leaving  : Natural;
         Min_Val  : Real;
         Min_Ratio: Real;
         Ratio    : Real;
      begin
         loop
            Entering := 0;
            Min_Val := -1.0e-9;
            -- Find the most negative coefficient in the objective row
            for C in Start_Col .. End_Col loop
               if T (Obj_Row, C) < Min_Val then
                  Min_Val := T (Obj_Row, C);
                  Entering := C;
               end if;
            end loop;
            
            exit when Entering = 0; -- Optimal for this phase
            
            Leaving := 0;
            Min_Ratio := Real'Last;
            -- Minimum ratio test to find leaving variable
            for R in 1 .. M loop
               if T (R, Entering) > 1.0e-9 then
                  Ratio := T (R, Col_RHS) / T (R, Entering);
                  if Ratio < Min_Ratio then
                     Min_Ratio := Ratio;
                     Leaving := R;
                  end if;
               end if;
            end loop;
            
            exit when Leaving = 0; -- Unbounded (should not happen in bounded LPBoost)
            
            -- Perform pivot operation
            declare
               Pivot_Elt : constant Real := T (Leaving, Entering);
            begin
               Basic_Var (Leaving) := Entering;
               
               for C in 1 .. Col_RHS loop
                  T (Leaving, C) := T (Leaving, C) / Pivot_Elt;
               end loop;
               
               for R in 1 .. M + 2 loop
                  if R /= Leaving then
                     declare
                        Factor : constant Real := T (R, Entering);
                     begin
                        if Factor /= 0.0 then
                           for C in 1 .. Col_RHS loop
                              T (R, C) := T (R, C) - Factor * T (Leaving, C);
                           end loop;
                        end if;
                     end;
                  end if;
               end loop;
            end;
         end loop;
      end Do_Phase;
      
   begin
      -- 1. Initialize Tableau
      for I in 1 .. M loop
         for K in 1 .. J loop
            T (I, Col_Alpha + K) := H_Mat (I, K);
         end loop;
         T (I, Col_Xi + I)      := 1.0;
         T (I, Col_Surplus + I) := -1.0;
         T (I, Col_Artif + I)   := 1.0;
         T (I, Col_RHS)         := 1.0;
         Basic_Var (I)          := Col_Artif + I;
      end loop;
      
      -- 2. Phase 1 Objective (Maximize W = -\sum a_i)
      for I in 1 .. M loop
         for C in 1 .. Col_Artif loop
            T (M + 1, C) := T (M + 1, C) - T (I, C);
         end loop;
         T (M + 1, Col_RHS) := T (M + 1, Col_RHS) - T (I, Col_RHS);
      end loop;
      
      -- 3. Phase 2 Objective (Maximize Z = -\sum alpha - C \sum xi)
      for K in 1 .. J loop
         T (M + 2, Col_Alpha + K) := 1.0;
      end loop;
      for I in 1 .. M loop
         T (M + 2, Col_Xi + I) := C_Val;
      end loop;
      
      -- 4. Solve Phase 1 (Drive artificial variables out)
      Do_Phase (M + 1, 1, Col_Surplus + M);
      
      -- 5. Solve Phase 2 (Optimize true objective)
      Do_Phase (M + 2, 1, Col_Surplus + M);
      
      -- 6. Extract Results
      -- Extract Dual Variables (Example Weights) from shadow prices of surplus variables
      declare
         Sum_U : Real := 0.0;
      begin
         for I in 1 .. M loop
            U (I) := T (M + 2, Col_Surplus + I);
            if U (I) < 0.0 then 
               U (I) := 0.0; 
            end if;
            Sum_U := Sum_U + U (I);
         end loop;
         
         -- Normalize distribution for the weak learner
         if Sum_U > 1.0e-12 then
            for I in 1 .. M loop
               U (I) := U (I) / Sum_U;
            end loop;
         else
            for I in 1 .. M loop
               U (I) := 1.0 / Real (M);
            end loop;
         end if;
      end;
      
      -- Extract Primal Variables (Hypothesis Weights)
      for K in 1 .. J loop
         Alphas (K) := 0.0;
      end loop;
      for I in 1 .. M loop
         -- Basic_Var is Positive, so it is natively >= 1. We only need the upper bound.
         if Basic_Var (I) <= Col_Alpha + J then
            Alphas (Basic_Var (I) - Col_Alpha) := T (I, Col_RHS);
         end if;
      end loop;
   end Solve_Master_Problem;

   -----------------------------------------------------------------------------
   -- Weak Learner: Decision Stump Training
   -----------------------------------------------------------------------------
   function Train_Stump (X : Dataset; Y : Labels; U : Distribution) return Weak_Hypothesis is
      Best_H  : Weak_Hypothesis := (Feature => 1, Threshold => 0.0, Polarity => 1, Weight => 0.0);
      Min_Err : Real := Real'Last;
      M       : constant Positive := X'Length (1);
      N       : constant Positive := X'Length (2);
   begin
      for F in 1 .. N loop
         for I in 1 .. M loop
            declare
               Thresh  : constant Real := X (I, F);
               Err_Pos : Real := 0.0;
               Err_Neg : Real := 0.0;
               Pred    : Integer;
            begin
               for J in 1 .. M loop
                  Pred := (if X (J, F) >= Thresh then 1 else -1);
                  if Pred /= Y (J) then
                     Err_Pos := Err_Pos + U (J);
                  end if;
                  if -Pred /= Y (J) then
                     Err_Neg := Err_Neg + U (J);
                  end if;
               end loop;
               
               if Err_Pos < Min_Err then
                  Min_Err := Err_Pos;
                  Best_H := (Feature => F, Threshold => Thresh, Polarity => 1, Weight => 0.0);
               end if;
               if Err_Neg < Min_Err then
                  Min_Err := Err_Neg;
                  Best_H := (Feature => F, Threshold => Thresh, Polarity => -1, Weight => 0.0);
               end if;
            end;
         end loop;
      end loop;
      return Best_H;
   end Train_Stump;

   -----------------------------------------------------------------------------
   -- Public API Implementation
   -----------------------------------------------------------------------------

   function Train
     (Data     : Dataset;
      Lbls     : Labels;
      Nu       : Real;
      Max_Iter : Positive) return Model
   is
      M : constant Positive := Data'Length (1);
      U : Distribution (1 .. M) := [others => 1.0 / Real (M)];
      
      Result : Model (Max_Size => Max_Iter);
      H_Mat  : H_Matrix_Type (1 .. M, 1 .. Max_Iter) := [others => [others => 0.0]];
      Alphas : Distribution (1 .. Max_Iter) := [others => 0.0];
      
      Err : Real;
      Pred : Integer;
   begin
      for Iter in 1 .. Max_Iter loop
         declare
            H : constant Weak_Hypothesis := Train_Stump (Data, Lbls, U);
         begin
            -- Evaluate weighted error of the new hypothesis
            Err := 0.0;
            for I in 1 .. M loop
               Pred := (if Data (I, H.Feature) >= H.Threshold then H.Polarity else -H.Polarity);
               if Pred /= Lbls (I) then
                  Err := Err + U (I);
               end if;
            end loop;
            
            -- If the weak learner cannot do better than random guessing (0.5), we have converged.
            if Err >= 0.5 - 1.0e-5 then
               exit;
            end if;
            
            -- If the hypothesis is already present, the master problem is fully optimal.
            declare
               Is_Duplicate : Boolean := False;
            begin
               for K in 1 .. Result.Size loop
                  if Result.Hypotheses (K).Feature = H.Feature
                    and then abs (Result.Hypotheses (K).Threshold - H.Threshold) < 1.0e-9
                    and then Result.Hypotheses (K).Polarity = H.Polarity
                  then
                     Is_Duplicate := True;
                     exit;
                  end if;
               end loop;
               
               if Is_Duplicate then
                  exit; -- Converged early; LP master optimization is complete
               end if;
            end;
            
            Result.Size := Iter;
            Result.Hypotheses (Iter) := H;
            
            -- Update the Hypothesis Response Matrix
            for I in 1 .. M loop
               Pred := (if Data (I, H.Feature) >= H.Threshold then H.Polarity else -H.Polarity);
               H_Mat (I, Iter) := Real (Lbls (I) * Pred);
            end loop;
            
            -- Solve Totally Corrective LP
            Solve_Master_Problem (
               H_Mat  => H_Mat,
               Nu     => Nu,
               Iter   => Iter,
               U      => U,
               Alphas => Alphas
            );
            
            -- Assign updated LP weights to the ensemble
            for K in 1 .. Iter loop
               Result.Hypotheses (K).Weight := Alphas (K);
            end loop;
         end;
      end loop;
      
      return Result;
   end Train;

   function Predict_Score
     (M_Mod : Model;
      Point : Data_Point) return Real
   is
      Score : Real := 0.0;
      Pred  : Integer;
   begin
      for I in 1 .. M_Mod.Size loop
         declare
            H : constant Weak_Hypothesis := M_Mod.Hypotheses (I);
         begin
            Pred := (if Point (H.Feature) >= H.Threshold then H.Polarity else -H.Polarity);
            Score := Score + H.Weight * Real (Pred);
         end;
      end loop;
      return Score;
   end Predict_Score;

   function Predict
     (M_Mod : Model;
      Point : Data_Point) return Label
   is
      Score : constant Real := Predict_Score (M_Mod, Point);
   begin
      if Score >= 0.0 then
         return 1;
      else
         return -1;
      end if;
   end Predict;

end LPBoost;
