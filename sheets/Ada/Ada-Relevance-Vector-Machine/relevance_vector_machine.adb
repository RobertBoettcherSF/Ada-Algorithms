with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Unchecked_Deallocation;

package body Relevance_Vector_Machine is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   --------------------------------------------------------------------------
   -- Memory Management
   --------------------------------------------------------------------------
   
   procedure Free_Matrix is new Ada.Unchecked_Deallocation
     (Real_Matrix, Real_Matrix_Access);
   procedure Free_Vector is new Ada.Unchecked_Deallocation
     (Real_Vector, Real_Vector_Access);

   overriding procedure Finalize (Model : in out RVM_Model) is
   begin
      if Model.SVs /= null then
         Free_Matrix (Model.SVs);
      end if;
      if Model.Weights /= null then
         Free_Vector (Model.Weights);
      end if;
   end Finalize;

   --------------------------------------------------------------------------
   -- Helpers & Getters
   --------------------------------------------------------------------------

   function Is_Trained_Successfully (Model : RVM_Model) return Boolean is
     (Model.Is_Trained);

   function Features_Count (Model : RVM_Model) return Natural is
     (Model.Num_Features);

   function Support_Vectors_Count (Model : RVM_Model) return Natural is
     (Model.Num_SVs);

   function Get_Row (M : Real_Matrix; Row : Positive) return Real_Vector is
      V : Real_Vector (M'Range (2));
   begin
      for J in M'Range (2) loop
         V (J) := M (Row, J);
      end loop;
      return V;
   end Get_Row;

   -- Kernel Calculation (Linear or Radial Basis Function)
   function Kernel_Calc (X1, X2 : Real_Vector; Kernel : Kernel_Function; Gamma : Real) return Real is
   begin
      if Kernel = Linear then
         return X1 * X2;
      else
         declare
            Diff    : constant Real_Vector := X1 - X2;
            Dist_Sq : constant Real := Diff * Diff;
         begin
            return Exp (-Gamma * Dist_Sq);
         end;
      end if;
   end Kernel_Calc;

   -- Sigmoid function for classification probabilities
   function Sigmoid (Z : Real) return Real is
   begin
      if Z > 20.0 then return 1.0; end if;
      if Z < -20.0 then return 0.0; end if;
      return 1.0 / (1.0 + Exp (-Z));
   end Sigmoid;

   -- Matrix Inverse with Tikhonov regularization for numerical stability
   function Robust_Inverse (M : Real_Matrix) return Real_Matrix is
      Ident : Real_Matrix (M'Range (1), M'Range (2)) := [others => [others => 0.0]];
      Reg   : constant Real := 1.0e-7;
   begin
      for I in Ident'Range (1) loop
         Ident (I, I) := Reg;
      end loop;
      return Inverse (M + Ident);
   end Robust_Inverse;

   --------------------------------------------------------------------------
   -- Training Logic
   --------------------------------------------------------------------------

   procedure Train
     (Model   : in out RVM_Model;
      X       : Real_Matrix;
      Y       : Real_Vector;
      Variant : Model_Variant;
      Kernel  : Kernel_Function := Linear;
      Gamma   : Real := 1.0)
   is
      N : constant Positive := X'Length (1);
      D : constant Positive := X'Length (2);
      
      Phi : Real_Matrix (1 .. N, 1 .. N + 1);
      Active : array (1 .. N + 1) of Boolean := [others => True];
      
      Alpha : Real_Vector (1 .. N + 1) := [others => 1.0e-3];
      Beta  : Real := 1.0; 
      
      Max_Iter : constant Positive := 500;
      Alpha_Threshold : constant Real := 1.0e6;
   begin
      -- 1. Build initial Design/Kernel Matrix Phi
      for I in 1 .. N loop
         for J in 1 .. N loop
            Phi (I, J) := Kernel_Calc (Get_Row (X, I), Get_Row (X, J), Kernel, Gamma);
         end loop;
         Phi (I, N + 1) := 1.0; -- Bias column
      end loop;

      -- 2. EM / Sparse Bayesian Learning Loop
      for Iter in 1 .. Max_Iter loop
         pragma Unreferenced (Iter);
         declare
            M_Act : Natural := 0;
         begin
            for B of Active loop
               if B then M_Act := M_Act + 1; end if;
            end loop;

            if M_Act = 0 then
               raise Data_Error with "All basis functions pruned.";
            end if;

            declare
               Phi_Act : Real_Matrix (1 .. N, 1 .. M_Act);
               Col     : Natural := 1;
               A_Diag  : Real_Matrix (1 .. M_Act, 1 .. M_Act) := [others => [others => 0.0]];
               Mu      : Real_Vector (1 .. M_Act) := [others => 0.0];
               Sigma   : Real_Matrix (1 .. M_Act, 1 .. M_Act);
            begin
               -- Sub-select active columns
               for J in Active'Range loop
                  if Active (J) then
                     for I in 1 .. N loop
                        Phi_Act (I, Col) := Phi (I, J);
                     end loop;
                     A_Diag (Col, Col) := Alpha (J);
                     Col := Col + 1;
                  end if;
               end loop;

               if Variant = Regression then
                  declare
                     Phi_T : constant Real_Matrix := Transpose (Phi_Act);
                     H     : constant Real_Matrix := Beta * (Phi_T * Phi_Act) + A_Diag;
                     Tmp1  : constant Real_Vector := Phi_T * Y;
                  begin
                     Sigma := Robust_Inverse (H);
                     Mu := Beta * (Sigma * Tmp1);
                  end;
               else
                  -- Classification: IRLS inner loop (MacKay / Tipping)
                  for IRLS_Iter in 1 .. 10 loop
                     pragma Unreferenced (IRLS_Iter);
                     declare
                        Pred_Z  : constant Real_Vector := Phi_Act * Mu;
                        B_Phi   : Real_Matrix (1 .. N, 1 .. M_Act);
                        Prob    : Real_Vector (1 .. N);
                        Diff    : Real_Vector (1 .. N);
                        B_Val   : Real;
                        Phi_T   : constant Real_Matrix := Transpose (Phi_Act);
                     begin
                        for I in 1 .. N loop
                           Prob (I) := Sigmoid (Pred_Z (I));
                           B_Val    := Prob (I) * (1.0 - Prob (I));
                           if B_Val < 1.0e-5 then B_Val := 1.0e-5; end if;
                           for J in 1 .. M_Act loop
                              B_Phi (I, J) := B_Val * Phi_Act (I, J);
                           end loop;
                           Diff (I) := Y (I) - Prob (I);
                        end loop;
                        
                        declare
                           H     : constant Real_Matrix := (Phi_T * B_Phi) + A_Diag;
                           Grad  : constant Real_Vector := (Phi_T * Diff) - (A_Diag * Mu);
                        begin
                           Sigma := Robust_Inverse (H);
                           Mu := Mu + (Sigma * Grad);
                        end;
                     end;
                  end loop;
               end if;

               -- Update Alpha & Beta
               Col := 1;
               declare
                  Gamma_Sum : Real := 0.0;
                  Gamma_K   : Real;
               begin
                  for J in Active'Range loop
                     if Active (J) then
                        Gamma_K := 1.0 - Alpha (J) * Sigma (Col, Col);
                        Gamma_Sum := Gamma_Sum + Gamma_K;
                        
                        Alpha (J) := Gamma_K / (Mu (Col)**2 + 1.0e-12);
                        
                        if Alpha (J) > Alpha_Threshold then
                           Active (J) := False;
                        end if;
                        Col := Col + 1;
                     end if;
                  end loop;

                  if Variant = Regression then
                     declare
                        Pred_Y : constant Real_Vector := Phi_Act * Mu;
                        Err    : constant Real_Vector := Y - Pred_Y;
                        Sum_Sq : constant Real := Err * Err;
                     begin
                        Beta := (Real (N) - Gamma_Sum) / (Sum_Sq + 1.0e-12);
                     end;
                  end if;
               end;
            end;
         end;
      end loop;

      -- 3. Extract Support Vectors and Weights
      declare
         Final_SVs : Natural := 0;
         Col       : Natural := 1;
      begin
         for J in 1 .. N loop
            if Active (J) then Final_SVs := Final_SVs + 1; end if;
         end loop;

         Model.Num_SVs := Final_SVs;
         Model.Num_Features := D;
         Model.Variant := Variant;
         Model.Kernel := Kernel;
         Model.Gamma := Gamma;
         Model.Bias := 0.0;
         
         if Model.SVs /= null then Free_Matrix (Model.SVs); end if;
         if Model.Weights /= null then Free_Vector (Model.Weights); end if;
         
         if Final_SVs > 0 then
            Model.SVs := new Real_Matrix (1 .. Final_SVs, 1 .. D);
            Model.Weights := new Real_Vector (1 .. Final_SVs);
         end if;

         -- Recalculate Mu one last time for the final active set
         declare
            M_Act : Natural := Final_SVs;
         begin
            if Active (N + 1) then M_Act := M_Act + 1; end if;
            
            declare
               Phi_Act : Real_Matrix (1 .. N, 1 .. M_Act);
               C       : Natural := 1;
               A_Diag  : Real_Matrix (1 .. M_Act, 1 .. M_Act) := [others => [others => 0.0]];
               Mu      : Real_Vector (1 .. M_Act) := [others => 0.0];
               Sigma   : Real_Matrix (1 .. M_Act, 1 .. M_Act);
            begin
               for J in Active'Range loop
                  if Active (J) then
                     for I in 1 .. N loop
                        Phi_Act (I, C) := Phi (I, J);
                     end loop;
                     A_Diag (C, C) := Alpha (J);
                     C := C + 1;
                  end if;
               end loop;

               if Variant = Regression then
                  declare
                     Phi_T : constant Real_Matrix := Transpose (Phi_Act);
                     H     : constant Real_Matrix := Beta * (Phi_T * Phi_Act) + A_Diag;
                  begin
                     Sigma := Robust_Inverse (H);
                     Mu := Beta * (Sigma * (Phi_T * Y));
                  end;
               else
                  for IRLS_Iter in 1 .. 20 loop
                     pragma Unreferenced (IRLS_Iter);
                     declare
                        Pred_Z  : constant Real_Vector := Phi_Act * Mu;
                        B_Phi   : Real_Matrix (1 .. N, 1 .. M_Act);
                        Prob    : Real_Vector (1 .. N);
                        Diff    : Real_Vector (1 .. N);
                        Phi_T   : constant Real_Matrix := Transpose (Phi_Act);
                     begin
                        for I in 1 .. N loop
                           Prob (I) := Sigmoid (Pred_Z (I));
                           for J in 1 .. M_Act loop
                              B_Phi (I, J) := Prob (I) * (1.0 - Prob (I)) * Phi_Act (I, J);
                           end loop;
                           Diff (I) := Y (I) - Prob (I);
                        end loop;
                        declare
                           H     : constant Real_Matrix := (Phi_T * B_Phi) + A_Diag;
                           Grad  : constant Real_Vector := (Phi_T * Diff) - (A_Diag * Mu);
                        begin
                           Sigma := Robust_Inverse (H);
                           Mu := Mu + (Sigma * Grad);
                        end;
                     end;
                  end loop;
               end if;

               -- Store final model parameters
               C := 1;
               for J in 1 .. N loop
                  if Active (J) then
                     for K in 1 .. D loop
                        Model.SVs (Col, K) := X (J, K);
                     end loop;
                     Model.Weights (Col) := Mu (C);
                     Col := Col + 1;
                     C := C + 1;
                  end if;
               end loop;
               
               if Active (N + 1) then
                  Model.Bias := Mu (C);
               end if;
            end;
         end;
      end;

      Model.Is_Trained := True;
   end Train;

   --------------------------------------------------------------------------
   -- Prediction
   --------------------------------------------------------------------------

   function Predict
     (Model : RVM_Model;
      X     : Real_Vector) return Target_Value
   is
      Result : Real := Model.Bias;
   begin
      if not Model.Is_Trained then raise Model_Not_Trained; end if;
      if X'Length /= Model.Num_Features then raise Dimension_Mismatch; end if;

      for I in 1 .. Model.Num_SVs loop
         Result := Result + Model.Weights (I) * Kernel_Calc (X, Get_Row (Model.SVs.all, I), Model.Kernel, Model.Gamma);
      end loop;

      return Result;
   end Predict;

   function Predict_Prob
     (Model : RVM_Model;
      X     : Real_Vector) return Probability
   is
      Result : constant Real := Predict (Model, X);
   begin
      return Probability (Sigmoid (Result));
   end Predict_Prob;

end Relevance_Vector_Machine;
