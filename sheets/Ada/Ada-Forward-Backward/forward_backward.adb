--  Forward_Backward body — unscaled and Rabiner-scaled HMM smoothing.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Forward_Backward
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Elementary_Functions;

   -----------------------------------------------------------------------
   -- Numeric helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Log (X : Real) return Log_Probability is
   begin
      if X <= 0.0 then
         return Log_Zero;
      else
         return Log_Probability (EF.Log (Float (X)));
      end if;
   end Log;

   function Exp (X : Log_Probability) return Real is
   begin
      if X <= Log_Zero / 2.0 then
         return 0.0;
      elsif X > 80.0 then
         return Real'Last;
      else
         return Real (EF.Exp (Float (X)));
      end if;
   end Exp;

   function Log_Sum_Exp (A, B : Log_Probability) return Log_Probability is
      M : Log_Probability;
   begin
      if A <= Log_Zero / 2.0 then
         return B;
      elsif B <= Log_Zero / 2.0 then
         return A;
      end if;
      if A > B then
         M := A;
         return M + Log (1.0 + Exp (B - M));
      else
         M := B;
         return M + Log (1.0 + Exp (A - M));
      end if;
   end Log_Sum_Exp;

   function Log_Sum_Exp_Row
     (Values : Initial_Vector) return Log_Probability
   is
      Sum : Real := 0.0;
   begin
      for V of Values loop
         if V > 0.0 then
            Sum := Sum + Real (V);
         end if;
      end loop;
      return Log (Sum);
   end Log_Sum_Exp_Row;

   function Log_Sum_Exp_Logs
     (Logs : Log_Vector) return Log_Probability
   is
      M   : Log_Probability := Log_Zero;
      Acc : Real := 0.0;
      Found : Boolean := False;
   begin
      for L of Logs loop
         if L > Log_Zero / 2.0 then
            if not Found or else L > M then
               M := L;
            end if;
            Found := True;
         end if;
      end loop;
      if not Found then
         return Log_Zero;
      end if;
      for L of Logs loop
         if L > Log_Zero / 2.0 then
            Acc := Acc + Exp (L - M);
         end if;
      end loop;
      return M + Log (Acc);
   end Log_Sum_Exp_Logs;

   -----------------------------------------------------------------------
   -- Validation helpers
   -----------------------------------------------------------------------

   function Row_Sum_Init (V : Initial_Vector) return Real is
      S : Real := 0.0;
   begin
      for X of V loop
         S := S + X;
      end loop;
      return S;
   end Row_Sum_Init;

   function Is_Valid_HMM
     (Model              : HMM;
      Tol                : Real := Prob_Tol;
      Require_Stochastic : Boolean := True) return Boolean
   is
      Sum : Real;
   begin
      if Model.N_States = 0 or else Model.N_Symbols = 0 then
         return False;
      end if;

      for S in 1 .. Model.N_States loop
         if Model.Init (S) < 0.0 then
            return False;
         end if;
         for T in 1 .. Model.N_States loop
            if Model.Trans (S, T) < 0.0 then
               return False;
            end if;
         end loop;
         for O in 1 .. Model.N_Symbols loop
            if Model.Emit (S, O) < 0.0 then
               return False;
            end if;
         end loop;
      end loop;

      if not Require_Stochastic then
         return True;
      end if;

      if abs (Row_Sum_Init (Model.Init) - 1.0) > Tol then
         return False;
      end if;

      for S in 1 .. Model.N_States loop
         Sum := 0.0;
         for T in 1 .. Model.N_States loop
            Sum := Sum + Model.Trans (S, T);
         end loop;
         if abs (Sum - 1.0) > Tol then
            return False;
         end if;

         Sum := 0.0;
         for O in 1 .. Model.N_Symbols loop
            Sum := Sum + Model.Emit (S, O);
         end loop;
         if abs (Sum - 1.0) > Tol then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_HMM;

   procedure Normalize_Rows (Model : in out HMM) is
      Sum : Real;
   begin
      if Model.N_States = 0 or else Model.N_Symbols = 0 then
         raise Invalid_Argument with "Normalize_Rows: empty HMM dimensions";
      end if;

      Sum := Row_Sum_Init (Model.Init);
      if Sum > 0.0 then
         for S in 1 .. Model.N_States loop
            Model.Init (S) := Probability (Model.Init (S) / Sum);
         end loop;
      end if;

      for S in 1 .. Model.N_States loop
         Sum := 0.0;
         for T in 1 .. Model.N_States loop
            Sum := Sum + Model.Trans (S, T);
         end loop;
         if Sum > 0.0 then
            for T in 1 .. Model.N_States loop
               Model.Trans (S, T) :=
                 Probability (Model.Trans (S, T) / Sum);
            end loop;
         end if;

         Sum := 0.0;
         for O in 1 .. Model.N_Symbols loop
            Sum := Sum + Model.Emit (S, O);
         end loop;
         if Sum > 0.0 then
            for O in 1 .. Model.N_Symbols loop
               Model.Emit (S, O) :=
                 Probability (Model.Emit (S, O) / Sum);
            end loop;
         end if;
      end loop;
   end Normalize_Rows;

   -----------------------------------------------------------------------
   -- Index / observation checks
   -----------------------------------------------------------------------

   procedure Check_Obs (Model : HMM; Obs : Observation_Sequence) is
   begin
      if Obs'Length = 0 then
         raise Invalid_Argument with "observation sequence is empty";
      end if;
      if Obs'Length > Max_Time then
         raise Capacity_Exceeded with "observation length exceeds Max_Time";
      end if;
      if Model.N_States = 0 or else Model.N_Symbols = 0 then
         raise Invalid_Argument with "HMM has zero states or symbols";
      end if;
      for T in Obs'Range loop
         if Obs (T) > Model.N_Symbols then
            raise Invalid_Argument
              with "observation symbol out of model range";
         end if;
      end loop;
   end Check_Obs;

   -----------------------------------------------------------------------
   -- Forward (unscaled)
   -----------------------------------------------------------------------

   function Forward
     (Model : HMM;
      Obs   : Observation_Sequence) return Alpha_Table
   is
      T_Len : constant Time_Count := Obs'Length;
      N     : constant State_Count := Model.N_States;
      Alpha : Alpha_Table (1 .. T_Len, 1 .. N) :=
        [others => [others => 0.0]];
      Sym   : Symbol_Index;
      Sum   : Real;
      Acc   : Real;
   begin
      Check_Obs (Model, Obs);

      Sym := Obs (Obs'First);
      Sum := 0.0;
      for I in 1 .. N loop
         Alpha (1, I) :=
           Real (Model.Init (I)) * Real (Model.Emit (I, Sym));
         Sum := Sum + Alpha (1, I);
      end loop;
      if Sum <= 0.0 then
         raise Degenerate_Geometry
           with "Forward: all α_1 zero (likelihood lost)";
      end if;

      for T in 2 .. T_Len loop
         Sym := Obs (Obs'First + (T - 1));
         Sum := 0.0;
         for J in 1 .. N loop
            Acc := 0.0;
            for I in 1 .. N loop
               Acc := Acc + Alpha (T - 1, I) * Real (Model.Trans (I, J));
            end loop;
            Alpha (T, J) := Acc * Real (Model.Emit (J, Sym));
            Sum := Sum + Alpha (T, J);
         end loop;
         if Sum <= 0.0 then
            raise Degenerate_Geometry
              with "Forward: all α_t zero at some t";
         end if;
      end loop;

      return Alpha;
   end Forward;

   function Likelihood_From_Alpha
     (Alpha : Alpha_Table) return Real
   is
      Sum : Real := 0.0;
      T   : constant Time_Index := Alpha'Last (1);
   begin
      for I in Alpha'Range (2) loop
         Sum := Sum + Alpha (T, I);
      end loop;
      return Sum;
   end Likelihood_From_Alpha;

   -----------------------------------------------------------------------
   -- Backward (unscaled)
   -----------------------------------------------------------------------

   function Backward
     (Model : HMM;
      Obs   : Observation_Sequence) return Beta_Table
   is
      T_Len : constant Time_Count := Obs'Length;
      N     : constant State_Count := Model.N_States;
      Beta  : Beta_Table (1 .. T_Len, 1 .. N) :=
        [others => [others => 0.0]];
      Sym   : Symbol_Index;
      Acc   : Real;
   begin
      Check_Obs (Model, Obs);

      for I in 1 .. N loop
         Beta (T_Len, I) := 1.0;
      end loop;

      for T in reverse 1 .. T_Len - 1 loop
         Sym := Obs (Obs'First + T);  -- o_{t+1} with 1-based T as t
         for I in 1 .. N loop
            Acc := 0.0;
            for J in 1 .. N loop
               Acc := Acc
                 + Real (Model.Trans (I, J))
                 * Real (Model.Emit (J, Sym))
                 * Beta (T + 1, J);
            end loop;
            Beta (T, I) := Acc;
         end loop;
      end loop;

      return Beta;
   end Backward;

   -----------------------------------------------------------------------
   -- Smooth / Xi helpers
   -----------------------------------------------------------------------

   procedure Fill_Gamma
     (Alpha : Alpha_Table;
      Beta  : Beta_Table;
      Lik   : Real;
      Gamma : out Posterior_Table)
   is
   begin
      if Lik <= 0.0 then
         raise Degenerate_Geometry with "Fill_Gamma: non-positive likelihood";
      end if;
      for T in Alpha'Range (1) loop
         for I in Alpha'Range (2) loop
            Gamma (T, I) := Alpha (T, I) * Beta (T, I) / Lik;
         end loop;
      end loop;
   end Fill_Gamma;

   procedure Fill_Xi_Unscaled
     (Model : HMM;
      Obs   : Observation_Sequence;
      Alpha : Alpha_Table;
      Beta  : Beta_Table;
      Lik   : Real;
      Xi    : out Xi_Table)
   is
      N   : constant State_Count := Model.N_States;
      Sym : Symbol_Index;
   begin
      if Lik <= 0.0 then
         raise Degenerate_Geometry with "Fill_Xi: non-positive likelihood";
      end if;
      for T in Xi'Range (1) loop
         Sym := Obs (Obs'First + T);  -- o_{t+1}
         for I in 1 .. N loop
            for J in 1 .. N loop
               Xi (T, I, J) :=
                 Alpha (T, I)
                 * Real (Model.Trans (I, J))
                 * Real (Model.Emit (J, Sym))
                 * Beta (T + 1, J)
                 / Lik;
            end loop;
         end loop;
      end loop;
   end Fill_Xi_Unscaled;

   function Smooth
     (Model : HMM;
      Obs   : Observation_Sequence) return Posterior_Table
   is
      T_Len : constant Time_Count := Obs'Length;
      N     : constant State_Count := Model.N_States;
      Alpha : constant Alpha_Table := Forward (Model, Obs);
      Beta  : constant Beta_Table := Backward (Model, Obs);
      Lik   : constant Real := Likelihood_From_Alpha (Alpha);
      Gamma : Posterior_Table (1 .. T_Len, 1 .. N);
   begin
      Fill_Gamma (Alpha, Beta, Lik, Gamma);
      return Gamma;
   end Smooth;

   -----------------------------------------------------------------------
   -- Forward_Backward (unscaled bundle)
   -----------------------------------------------------------------------

   function Forward_Backward
     (Model   : HMM;
      Obs     : Observation_Sequence;
      Fill_Xi : Boolean := True) return FB_Result
   is
      T_Len  : constant Time_Count := Obs'Length;
      N      : constant State_Count := Model.N_States;
      Xi_Len : constant Time_Count :=
        (if Fill_Xi and then T_Len > 0 then T_Len - 1 else 0);
      Result : FB_Result (Length => T_Len, N_States => N, Xi_Last => Xi_Len);
      Alpha  : constant Alpha_Table := Forward (Model, Obs);
      Beta   : constant Beta_Table := Backward (Model, Obs);
      Lik    : constant Real := Likelihood_From_Alpha (Alpha);
   begin
      Result.Alpha := Alpha;
      Result.Beta := Beta;
      Result.Likelihood := Lik;
      Result.Log_Likelihood := Log (Lik);
      Result.Scaled := False;
      Result.Has_Xi := Fill_Xi;
      for T in 1 .. T_Len loop
         Result.Scales (T) := 1.0;
      end loop;
      Fill_Gamma (Alpha, Beta, Lik, Result.Gamma);
      if Fill_Xi and then Xi_Len > 0 then
         Fill_Xi_Unscaled (Model, Obs, Alpha, Beta, Lik, Result.Xi);
      end if;
      return Result;
   end Forward_Backward;

   -----------------------------------------------------------------------
   -- Forward_Backward_Scaled (Rabiner c_t)
   -----------------------------------------------------------------------

   function Forward_Backward_Scaled
     (Model   : HMM;
      Obs     : Observation_Sequence;
      Fill_Xi : Boolean := True) return FB_Result
   is
      T_Len  : constant Time_Count := Obs'Length;
      N      : constant State_Count := Model.N_States;
      Xi_Len : constant Time_Count :=
        (if Fill_Xi and then T_Len > 0 then T_Len - 1 else 0);
      Result : FB_Result (Length => T_Len, N_States => N, Xi_Last => Xi_Len);

      Sym  : Symbol_Index;
      Sum  : Real;
      Acc  : Real;
      Lik  : Real;
      LogL : Log_Probability;
   begin
      Check_Obs (Model, Obs);

      --  Forward with scaling: c_t = Σ_i α'_t(i); α̂_t = α'_t / c_t
      Sym := Obs (Obs'First);
      Sum := 0.0;
      for I in 1 .. N loop
         Result.Alpha (1, I) :=
           Real (Model.Init (I)) * Real (Model.Emit (I, Sym));
         Sum := Sum + Result.Alpha (1, I);
      end loop;
      if Sum <= 0.0 then
         raise Degenerate_Geometry
           with "Forward_Backward_Scaled: α_1 mass zero";
      end if;
      Result.Scales (1) := Sum;
      for I in 1 .. N loop
         Result.Alpha (1, I) := Result.Alpha (1, I) / Sum;
      end loop;

      for T in 2 .. T_Len loop
         Sym := Obs (Obs'First + (T - 1));
         Sum := 0.0;
         for J in 1 .. N loop
            Acc := 0.0;
            for I in 1 .. N loop
               Acc := Acc
                 + Result.Alpha (T - 1, I) * Real (Model.Trans (I, J));
            end loop;
            Result.Alpha (T, J) := Acc * Real (Model.Emit (J, Sym));
            Sum := Sum + Result.Alpha (T, J);
         end loop;
         if Sum <= 0.0 then
            raise Degenerate_Geometry
              with "Forward_Backward_Scaled: α_t mass zero";
         end if;
         Result.Scales (T) := Sum;
         for J in 1 .. N loop
            Result.Alpha (T, J) := Result.Alpha (T, J) / Sum;
         end loop;
      end loop;

      --  P(o) = Π_t c_t
      Lik := 1.0;
      LogL := 0.0;
      for T in 1 .. T_Len loop
         Lik := Lik * Result.Scales (T);
         LogL := LogL + Log (Result.Scales (T));
         --  Guard product overflow/underflow into Log only path
         if Lik > 1.0E200 then
            Lik := Real'Last;
         elsif Lik > 0.0 and then Lik < 1.0E-200 and then T < T_Len then
            --  keep multiplying in log; Lik may underflow — restore later
            null;
         end if;
      end loop;
      --  Prefer Exp(LogL) when product under/overflowed
      if Lik <= 0.0 or else Lik >= Real'Last / 2.0 then
         Lik := Exp (LogL);
      end if;
      Result.Likelihood := Lik;
      Result.Log_Likelihood := LogL;

      --  Backward with same c_t: β̂_T = 1/c_T; β̂_t = (1/c_t) Σ_j …
      for I in 1 .. N loop
         Result.Beta (T_Len, I) := 1.0 / Result.Scales (T_Len);
      end loop;

      for T in reverse 1 .. T_Len - 1 loop
         Sym := Obs (Obs'First + T);
         for I in 1 .. N loop
            Acc := 0.0;
            for J in 1 .. N loop
               Acc := Acc
                 + Real (Model.Trans (I, J))
                 * Real (Model.Emit (J, Sym))
                 * Result.Beta (T + 1, J);
            end loop;
            Result.Beta (T, I) := Acc / Result.Scales (T);
         end loop;
      end loop;

      --  γ_t(i) = α̂_t(i) β̂_t(i)  (already normalised under this scaling)
      for T in 1 .. T_Len loop
         Sum := 0.0;
         for I in 1 .. N loop
            Result.Gamma (T, I) :=
              Result.Alpha (T, I) * Result.Beta (T, I);
            Sum := Sum + Result.Gamma (T, I);
         end loop;
         --  Renormalise defensively (floating noise)
         if Sum > 0.0 and then abs (Sum - 1.0) > Prob_Tol then
            for I in 1 .. N loop
               Result.Gamma (T, I) := Result.Gamma (T, I) / Sum;
            end loop;
         elsif Sum <= 0.0 then
            raise Degenerate_Geometry
              with "Forward_Backward_Scaled: γ row mass zero";
         end if;
      end loop;

      --  ξ_t(i,j) = α̂_t(i) a_ij b_j(o_{t+1}) β̂_{t+1}(j) / c_{t+1}?
      --  With β̂ already including 1/c scaling: standard form is
      --  ξ = α̂_t(i) * a_ij * b_j * β̂_{t+1}(j)   then renormalise by
      --  noting Σ_{i,j} ξ should be 1; equivalently divide by c? 
      --  Since β̂_{t+1} was divided by c_{t+1} already when formed from
      --  the recurrence that ends with /c_{t+1}, the product
      --  α̂_t a b β̂_{t+1} already equals the joint posterior.
      if Fill_Xi and then Xi_Len > 0 then
         Result.Has_Xi := True;
         for T in 1 .. Xi_Len loop
            Sym := Obs (Obs'First + T);
            Sum := 0.0;
            for I in 1 .. N loop
               for J in 1 .. N loop
                  Result.Xi (T, I, J) :=
                    Result.Alpha (T, I)
                    * Real (Model.Trans (I, J))
                    * Real (Model.Emit (J, Sym))
                    * Result.Beta (T + 1, J);
                  Sum := Sum + Result.Xi (T, I, J);
               end loop;
            end loop;
            if Sum > 0.0 then
               for I in 1 .. N loop
                  for J in 1 .. N loop
                     Result.Xi (T, I, J) := Result.Xi (T, I, J) / Sum;
                  end loop;
               end loop;
            end if;
         end loop;
      else
         Result.Has_Xi := False;
      end if;

      Result.Scaled := True;
      return Result;
   end Forward_Backward_Scaled;

   -----------------------------------------------------------------------
   -- Posterior mode path
   -----------------------------------------------------------------------

   function Posterior_Mode_Path
     (Gamma : Posterior_Table) return State_Sequence
   is
      Path : State_Sequence (Gamma'Range (1));
      Best : State_Index;
      Best_V : Real;
   begin
      for T in Gamma'Range (1) loop
         Best := Gamma'First (2);
         Best_V := Gamma (T, Best);
         for I in Gamma'Range (2) loop
            if Gamma (T, I) > Best_V then
               Best_V := Gamma (T, I);
               Best := I;
            end if;
         end loop;
         Path (T) := Best;
      end loop;
      return Path;
   end Posterior_Mode_Path;

   -----------------------------------------------------------------------
   -- Wikipedia doctor / fever fixture
   -----------------------------------------------------------------------

   function Make_Doctor_Fever_HMM return HMM is
      Model : HMM (N_States => 2, N_Symbols => 3);
   begin
      --  init = {Healthy: 0.6, Fever: 0.4}
      Model.Init := [Healthy => 0.6, Fever => 0.4];

      --  trans (Viterbi-page folding of end-state mass into stay)
      Model.Trans :=
        [Healthy => [Healthy => 0.7, Fever => 0.3],
         Fever   => [Healthy => 0.4, Fever => 0.6]];

      --  emit
      Model.Emit :=
        [Healthy => [Normal => 0.5, Cold => 0.4, Dizzy => 0.1],
         Fever   => [Normal => 0.1, Cold => 0.3, Dizzy => 0.6]];

      return Model;
   end Make_Doctor_Fever_HMM;

end Forward_Backward;
