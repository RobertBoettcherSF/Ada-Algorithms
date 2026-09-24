with Ada.Numerics.Elementary_Functions;

package body Logit_Boost is

   -- Internal helper to handle Float/Real conversion for exponential
   function Exp_Real (X : Real) return Real is
   begin
      return Real (Ada.Numerics.Elementary_Functions.Exp (Float (X)));
   end Exp_Real;

   procedure Calculate_Working_Data (P : in Real; Y : in Class_Label; Z : out Real; W : out Real) is
      P_Bounded : Real := P;
      Z_Max     : constant Real := 4.0;
      P_Min     : constant Real := 0.00001;
      P_Max     : constant Real := 0.99999;
   begin
      -- Bound P to avoid numerical instability and division by zero
      if P_Bounded < P_Min then
         P_Bounded := P_Min;
      elsif P_Bounded > P_Max then
         P_Bounded := P_Max;
      end if;

      -- W = p * (1 - p)
      W := P_Bounded * (1.0 - P_Bounded);

      -- Z = (Y* - P) / (p * (1 - p))
      if Y = 1 then
         Z := (1.0 - P_Bounded) / W;
      else
         Z := (0.0 - P_Bounded) / W;
      end if;

      -- Bound Z strongly (Friedman suggests bounding Z to a maximum absolute value)
      if Z > Z_Max then
         Z := Z_Max;
      elsif Z < -Z_Max then
         Z := -Z_Max;
      end if;
   end Calculate_Working_Data;

   function Fit_Stump (X : Feature_Matrix; Z : Real_Vector; W : Real_Vector) return Decision_Stump is
      Best_Stump : Decision_Stump := (Feature_Index => 1, Threshold => 0.0, Left_Value => 0.0, Right_Value => 0.0);
      Min_Error  : Real := Real'Last;
      T          : Real;
      Err        : Real;
      W_L, W_R   : Real;
      WZ_L, WZ_R : Real;
      C_L, C_R   : Real;
   begin
      -- Iterate over all features
      for J_Offset in 0 .. X'Length(2) - 1 loop
         declare
            J : constant Positive := X'First(2) + J_Offset;
         begin
            -- Use each distinct feature value as a potential threshold
            for I in X'Range(1) loop
               T := X(I, J);
               W_L := 0.0; W_R := 0.0; WZ_L := 0.0; WZ_R := 0.0;

               -- Accumulate weighted sums for the split
               for K_Offset in 0 .. X'Length(1) - 1 loop
                  declare
                     K   : constant Positive := X'First(1) + K_Offset;
                     Z_K : constant Real := Z(Z'First + K_Offset);
                     W_K : constant Real := W(W'First + K_Offset);
                  begin
                     if X(K, J) <= T then
                        W_L  := W_L  + W_K;
                        WZ_L := WZ_L + W_K * Z_K;
                     else
                        W_R  := W_R  + W_K;
                        WZ_R := WZ_R + W_K * Z_K;
                     end if;
                  end;
               end loop;

               -- Compute left and right node estimates
               if W_L > 0.0 then
                  C_L := WZ_L / W_L;
               else
                  C_L := 0.0;
               end if;

               if W_R > 0.0 then
                  C_R := WZ_R / W_R;
               else
                  C_R := 0.0;
               end if;

               -- Compute weighted squared error for this threshold
               Err := 0.0;
               for K_Offset in 0 .. X'Length(1) - 1 loop
                  declare
                     K   : constant Positive := X'First(1) + K_Offset;
                     Z_K : constant Real := Z(Z'First + K_Offset);
                     W_K : constant Real := W(W'First + K_Offset);
                  begin
                     if X(K, J) <= T then
                        Err := Err + W_K * (Z_K - C_L)**2;
                     else
                        Err := Err + W_K * (Z_K - C_R)**2;
                     end if;
                  end;
               end loop;

               -- Keep the stump with minimal error
               if Err < Min_Error then
                  Min_Error := Err;
                  Best_Stump := (Feature_Index => J_Offset + 1,
                                 Threshold     => T,
                                 Left_Value    => C_L,
                                 Right_Value   => C_R);
               end if;
            end loop;
         end;
      end loop;

      return Best_Stump;
   end Fit_Stump;

   function Train (X : Feature_Matrix; Y : Label_Vector; Iterations : Natural) return Model is
      Z_Vec   : Real_Vector (1 .. X'Length(1));
      W_Vec   : Real_Vector (1 .. X'Length(1));
      P_Vec   : Real_Vector (1 .. X'Length(1)) := (others => 0.5);
      F_Vec   : Real_Vector (1 .. X'Length(1)) := (others => 0.0);
      Result  : Model(Number_Of_Stumps => Iterations);
      Stump   : Decision_Stump;
      Val     : Real;
      E_Val   : Real;
   begin
      -- Dynamic check for cases where constraints might not be evaluated
      if X'Length(1) /= Y'Length or else X'Length(1) = 0 or else X'Length(2) = 0 then
         raise Invalid_Data_Error;
      end if;

      for M in 1 .. Iterations loop
         -- 1. Compute working responses and weights
         for I_Offset in 0 .. X'Length(1) - 1 loop
            Calculate_Working_Data (P => P_Vec(P_Vec'First + I_Offset),
                                    Y => Y(Y'First + I_Offset),
                                    Z => Z_Vec(Z_Vec'First + I_Offset),
                                    W => W_Vec(W_Vec'First + I_Offset));
         end loop;

         -- 2. Fit weak learner (decision stump) to working data
         Stump := Fit_Stump (X, Z_Vec, W_Vec);
         Result.Stumps(M) := Stump;

         -- 3. Update F(x) and class probabilities
         for I_Offset in 0 .. X'Length(1) - 1 loop
            declare
               I : constant Positive := X'First(1) + I_Offset;
               J : constant Positive := X'First(2) + Stump.Feature_Index - 1;
            begin
               if X(I, J) <= Stump.Threshold then
                  Val := Stump.Left_Value;
               else
                  Val := Stump.Right_Value;
               end if;

               -- F(x) <- F(x) + 0.5 * f_m(x)
               F_Vec(F_Vec'First + I_Offset) := F_Vec(F_Vec'First + I_Offset) + 0.5 * Val;

               -- Update p(x) for next iteration
               E_Val := -2.0 * F_Vec(F_Vec'First + I_Offset);
               if E_Val > 50.0 then
                  P_Vec(P_Vec'First + I_Offset) := 0.0;
               elsif E_Val < -50.0 then
                  P_Vec(P_Vec'First + I_Offset) := 1.0;
               else
                  P_Vec(P_Vec'First + I_Offset) := 1.0 / (1.0 + Exp_Real (E_Val));
               end if;
            end;
         end loop;
      end loop;

      return Result;
   end Train;

   function Predict_F (M : Model; X : Feature_Vector) return Real is
      F : Real := 0.0;
      S : Decision_Stump;
      J : Positive;
   begin
      -- F(x) is the sum of (0.5 * stump_responses)
      for I in 1 .. M.Number_Of_Stumps loop
         S := M.Stumps(I);
         J := X'First + S.Feature_Index - 1;
         if X(J) <= S.Threshold then
            F := F + 0.5 * S.Left_Value;
         else
            F := F + 0.5 * S.Right_Value;
         end if;
      end loop;
      return F;
   end Predict_F;

   function Predict_Probability (M : Model; X : Feature_Vector) return Real is
      F     : constant Real := Predict_F (M, X);
      E_Val : constant Real := -2.0 * F;
   begin
      -- P(y=1|x) = e^F / (e^F + e^-F) = 1 / (1 + e^-2F)
      if E_Val > 50.0 then
         return 0.0;
      elsif E_Val < -50.0 then
         return 1.0;
      else
         return 1.0 / (1.0 + Exp_Real (E_Val));
      end if;
   end Predict_Probability;

   function Predict (M : Model; X : Feature_Vector) return Class_Label is
      Prob : constant Real := Predict_Probability (M, X);
   begin
      if Prob >= 0.5 then
         return 1;
      else
         return 0;
      end if;
   end Predict;

end Logit_Boost;
