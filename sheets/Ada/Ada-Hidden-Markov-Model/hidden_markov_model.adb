--  Hidden_Markov_Model body — compact survey embeddings of scaled FB,
--  log-domain Viterbi, and Baum–Welch EM.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Hidden_Markov_Model
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Elementary_Functions;

   -----------------------------------------------------------------------
   -- Tiny seeded LCG
   -----------------------------------------------------------------------

   type U32 is mod 2 ** 32;

   procedure Next_RNG (State : in out U32) is
   begin
      State := State * 1664525 + 1013904223;
   end Next_RNG;

   function Uniform (State : in out U32) return Real is
   begin
      Next_RNG (State);
      return Real (State) / Real (U32'Last);
   end Uniform;

   function Sample_Categorical
     (Weights : Initial_Vector;
      State   : in out U32) return State_Index
   is
      U   : constant Real := Uniform (State);
      Acc : Real := 0.0;
   begin
      for I in Weights'Range loop
         Acc := Acc + Real (Weights (I));
         if U <= Acc then
            return I;
         end if;
      end loop;
      return Weights'Last;
   end Sample_Categorical;

   function Sample_Emit
     (Row   : Emission_Matrix;
      S     : State_Index;
      First : Symbol_Index;
      Last  : Symbol_Index;
      State : in out U32) return Symbol_Index
   is
      U   : constant Real := Uniform (State);
      Acc : Real := 0.0;
   begin
      for O in First .. Last loop
         Acc := Acc + Real (Row (S, O));
         if U <= Acc then
            return O;
         end if;
      end loop;
      return Last;
   end Sample_Emit;

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

   -----------------------------------------------------------------------
   -- Validation
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

   procedure Check_Path
     (Model : HMM;
      Obs   : Observation_Sequence;
      Path  : State_Sequence)
   is
   begin
      if Obs'Length /= Path'Length then
         raise Invalid_Argument with "Obs and Path length mismatch";
      end if;
      Check_Obs (Model, Obs);
      for T in Path'Range loop
         if Path (T) > Model.N_States then
            raise Invalid_Argument with "path state out of model range";
         end if;
      end loop;
   end Check_Path;

   -----------------------------------------------------------------------
   -- Fixtures / random init / sampling
   -----------------------------------------------------------------------

   function Make_Doctor_Fever_HMM return HMM is
      Model : HMM (N_States => 2, N_Symbols => 3);
   begin
      Model.Init := [Healthy => 0.6, Fever => 0.4];
      Model.Trans :=
        [Healthy => [Healthy => 0.7, Fever => 0.3],
         Fever   => [Healthy => 0.4, Fever => 0.6]];
      Model.Emit :=
        [Healthy => [Normal => 0.5, Cold => 0.4, Dizzy => 0.1],
         Fever   => [Normal => 0.1, Cold => 0.3, Dizzy => 0.6]];
      return Model;
   end Make_Doctor_Fever_HMM;

   function Random_Init_HMM
     (N_States  : State_Count;
      N_Symbols : Symbol_Count;
      Seed      : Natural) return HMM
   is
      Model : HMM (N_States => N_States, N_Symbols => N_Symbols);
      State : U32 := U32 (Seed) + 1;
      Sum   : Real;
   begin
      if N_States = 0 or else N_Symbols = 0 then
         raise Invalid_Argument with "Random_Init_HMM: zero dimensions";
      end if;

      Sum := 0.0;
      for I in 1 .. N_States loop
         Model.Init (I) := Probability (0.01 + Uniform (State));
         Sum := Sum + Model.Init (I);
      end loop;
      for I in 1 .. N_States loop
         Model.Init (I) := Probability (Model.Init (I) / Sum);
      end loop;

      for I in 1 .. N_States loop
         Sum := 0.0;
         for J in 1 .. N_States loop
            Model.Trans (I, J) := Probability (0.01 + Uniform (State));
            Sum := Sum + Model.Trans (I, J);
         end loop;
         for J in 1 .. N_States loop
            Model.Trans (I, J) :=
              Probability (Model.Trans (I, J) / Sum);
         end loop;

         Sum := 0.0;
         for K in 1 .. N_Symbols loop
            Model.Emit (I, K) := Probability (0.01 + Uniform (State));
            Sum := Sum + Model.Emit (I, K);
         end loop;
         for K in 1 .. N_Symbols loop
            Model.Emit (I, K) :=
              Probability (Model.Emit (I, K) / Sum);
         end loop;
      end loop;

      return Model;
   end Random_Init_HMM;

   function Sample_Path
     (Model : HMM;
      T     : Time_Count;
      Seed  : Natural) return State_Sequence
   is
      Path  : State_Sequence (1 .. T);
      State : U32 := U32 (Seed) + 1;
      S     : State_Index;
      Row   : Initial_Vector (1 .. Model.N_States);
   begin
      if T = 0 then
         raise Invalid_Argument with "Sample_Path: T = 0";
      end if;
      S := Sample_Categorical (Model.Init, State);
      Path (1) := S;
      for Time in 2 .. T loop
         for J in 1 .. Model.N_States loop
            Row (J) := Model.Trans (S, J);
         end loop;
         S := Sample_Categorical (Row, State);
         Path (Time) := S;
      end loop;
      return Path;
   end Sample_Path;

   function Sample_Observations
     (Model : HMM;
      T     : Time_Count;
      Seed  : Natural) return Observation_Sequence
   is
      Obs   : Observation_Sequence (1 .. T);
      State : U32 := U32 (Seed) + 1;
      S     : State_Index;
      Row   : Initial_Vector (1 .. Model.N_States);
   begin
      if T = 0 then
         raise Invalid_Argument with "Sample_Observations: T = 0";
      end if;
      S := Sample_Categorical (Model.Init, State);
      Obs (1) := Sample_Emit
        (Model.Emit, S, 1, Symbol_Index (Model.N_Symbols), State);

      for Time in 2 .. T loop
         for J in 1 .. Model.N_States loop
            Row (J) := Model.Trans (S, J);
         end loop;
         S := Sample_Categorical (Row, State);
         Obs (Time) := Sample_Emit
           (Model.Emit, S, 1, Symbol_Index (Model.N_Symbols), State);
      end loop;
      return Obs;
   end Sample_Observations;

   -----------------------------------------------------------------------
   -- Scaled forward–backward (shared core)
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
      Result : FB_Result
        (Length => T_Len, N_States => N, Xi_Last => Xi_Len);

      Sym  : Symbol_Index;
      Sum  : Real;
      Acc  : Real;
      Lik  : Real;
      LogL : Log_Probability;
   begin
      Check_Obs (Model, Obs);

      Sym := Obs (Obs'First);
      Sum := 0.0;
      for I in 1 .. N loop
         Result.Alpha (1, I) :=
           Real (Model.Init (I)) * Real (Model.Emit (I, Sym));
         Sum := Sum + Result.Alpha (1, I);
      end loop;
      if Sum <= 0.0 then
         raise Degenerate_Geometry with "Forward_Backward: α_1 mass zero";
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
            raise Degenerate_Geometry with "Forward_Backward: α_t mass zero";
         end if;
         Result.Scales (T) := Sum;
         for J in 1 .. N loop
            Result.Alpha (T, J) := Result.Alpha (T, J) / Sum;
         end loop;
      end loop;

      Lik := 1.0;
      LogL := 0.0;
      for T in 1 .. T_Len loop
         Lik := Lik * Result.Scales (T);
         LogL := LogL + Log (Result.Scales (T));
         if Lik > 1.0E200 then
            Lik := Real'Last;
         end if;
      end loop;
      if Lik <= 0.0 or else Lik >= Real'Last / 2.0 then
         Lik := Exp (LogL);
      end if;
      Result.Likelihood := Lik;
      Result.Log_Likelihood := LogL;

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

      for T in 1 .. T_Len loop
         Sum := 0.0;
         for I in 1 .. N loop
            Result.Gamma (T, I) :=
              Result.Alpha (T, I) * Result.Beta (T, I);
            Sum := Sum + Result.Gamma (T, I);
         end loop;
         if Sum > 0.0 and then abs (Sum - 1.0) > Prob_Tol then
            for I in 1 .. N loop
               Result.Gamma (T, I) := Result.Gamma (T, I) / Sum;
            end loop;
         elsif Sum <= 0.0 then
            raise Degenerate_Geometry with "Forward_Backward: γ row mass zero";
         end if;
      end loop;

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

      return Result;
   end Forward_Backward;

   function Log_Likelihood
     (Model : HMM;
      Obs   : Observation_Sequence) return Log_Probability
   is
      FB : constant FB_Result :=
        Forward_Backward (Model, Obs, Fill_Xi => False);
   begin
      return FB.Log_Likelihood;
   end Log_Likelihood;

   function Likelihood
     (Model : HMM;
      Obs   : Observation_Sequence) return Real
   is
      FB : constant FB_Result :=
        Forward_Backward (Model, Obs, Fill_Xi => False);
   begin
      return FB.Likelihood;
   end Likelihood;

   function Filter
     (Model : HMM;
      Obs   : Observation_Sequence) return Posterior_Table
   is
      FB : constant FB_Result :=
        Forward_Backward (Model, Obs, Fill_Xi => False);
      Out_G : Posterior_Table (1 .. FB.Length, 1 .. FB.N_States);
   begin
      --  Scaled α_t is already P(X_t | o_1:t).
      for T in 1 .. FB.Length loop
         for I in 1 .. FB.N_States loop
            Out_G (T, I) := FB.Alpha (T, I);
         end loop;
      end loop;
      return Out_G;
   end Filter;

   function Smooth
     (Model : HMM;
      Obs   : Observation_Sequence) return Posterior_Table
   is
      FB : constant FB_Result :=
        Forward_Backward (Model, Obs, Fill_Xi => False);
      Out_G : Posterior_Table (1 .. FB.Length, 1 .. FB.N_States);
   begin
      for T in 1 .. FB.Length loop
         for I in 1 .. FB.N_States loop
            Out_G (T, I) := FB.Gamma (T, I);
         end loop;
      end loop;
      return Out_G;
   end Smooth;

   function Posterior_Mode_Path
     (Gamma : Posterior_Table) return State_Sequence
   is
      T_Len : constant Time_Count := Gamma'Length (1);
      N     : constant State_Count := Gamma'Length (2);
      Path  : State_Sequence (1 .. T_Len);
      Best_S : State_Index;
      Best_V : Real;
   begin
      for T in 1 .. T_Len loop
         Best_S := 1;
         Best_V := Gamma (Gamma'First (1) + (T - 1), Gamma'First (2));
         for S in 1 .. N loop
            declare
               V : constant Real :=
                 Gamma (Gamma'First (1) + (T - 1),
                        Gamma'First (2) + (S - 1));
            begin
               if V > Best_V then
                  Best_V := V;
                  Best_S := State_Index (S);
               end if;
            end;
         end loop;
         Path (T) := Best_S;
      end loop;
      return Path;
   end Posterior_Mode_Path;

   -----------------------------------------------------------------------
   -- Path scoring
   -----------------------------------------------------------------------

   function Path_Probability
     (Model : HMM;
      Obs   : Observation_Sequence;
      Path  : State_Sequence) return Real
   is
      P    : Real;
      From : State_Index;
      To   : State_Index;
      Sym  : Symbol_Index;
   begin
      Check_Path (Model, Obs, Path);

      From := Path (Path'First);
      Sym  := Obs (Obs'First);
      P    := Real (Model.Init (From)) * Real (Model.Emit (From, Sym));

      for K in 1 .. Obs'Length - 1 loop
         From := Path (Path'First + K - 1);
         To   := Path (Path'First + K);
         Sym  := Obs (Obs'First + K);
         P    := P * Real (Model.Trans (From, To))
                   * Real (Model.Emit (To, Sym));
      end loop;
      return P;
   end Path_Probability;

   function Log_Path_Probability
     (Model : HMM;
      Obs   : Observation_Sequence;
      Path  : State_Sequence) return Log_Probability
   is
      L    : Log_Probability;
      From : State_Index;
      To   : State_Index;
      Sym  : Symbol_Index;
   begin
      Check_Path (Model, Obs, Path);

      From := Path (Path'First);
      Sym  := Obs (Obs'First);
      L    := Log (Real (Model.Init (From)))
           + Log (Real (Model.Emit (From, Sym)));

      for K in 1 .. Obs'Length - 1 loop
         From := Path (Path'First + K - 1);
         To   := Path (Path'First + K);
         Sym  := Obs (Obs'First + K);
         L    := L + Log (Real (Model.Trans (From, To)))
                   + Log (Real (Model.Emit (To, Sym)));
      end loop;
      return L;
   end Log_Path_Probability;

   -----------------------------------------------------------------------
   -- Viterbi
   -----------------------------------------------------------------------

   procedure Backtrace
     (Prev   : Backpointer_Table;
      Last_S : State_Index;
      Path   : out State_Sequence)
   is
      S : State_Index := Last_S;
   begin
      Path (Path'Last) := S;
      for T in reverse Path'First .. Path'Last - 1 loop
         declare
            Pred : constant Natural := Prev (T + 1, S);
         begin
            if Pred = 0 then
               raise Degenerate_Geometry
                 with "missing backpointer during traceback";
            end if;
            S := State_Index (Pred);
            Path (T) := S;
         end;
      end loop;
   end Backtrace;

   function Viterbi_Decode
     (Model      : HMM;
      Obs        : Observation_Sequence;
      Fill_Table : Boolean := True) return Viterbi_Result
   is
      T_Len  : constant Time_Count := Obs'Length;
      N      : constant State_Count := Model.N_States;
      Result : Viterbi_Result (Length => T_Len, N_States => N);

      Prob : array (1 .. T_Len, 1 .. N) of Real :=
        [others => [others => 0.0]];
      Prev : Backpointer_Table (1 .. T_Len, 1 .. N) :=
        [others => [others => 0]];

      Best_S : State_Index;
      Best_V : Real;
      Cand   : Real;
      Sym    : Symbol_Index;
      Any    : Boolean;
   begin
      Check_Obs (Model, Obs);

      Sym := Obs (Obs'First);
      Any := False;
      for S in 1 .. N loop
         Prob (1, S) :=
           Real (Model.Init (S)) * Real (Model.Emit (S, Sym));
         Prev (1, S) := 0;
         if Prob (1, S) > 0.0 then
            Any := True;
         end if;
      end loop;
      if not Any then
         raise Degenerate_Geometry
           with "Viterbi_Decode: all init*emit zero at t=1";
      end if;

      for T in 2 .. T_Len loop
         Sym := Obs (Obs'First + T - 1);
         Any := False;
         for S in 1 .. N loop
            Best_V := -1.0;
            Best_S := 1;
            for R in 1 .. N loop
               Cand := Prob (T - 1, R)
                 * Real (Model.Trans (R, S))
                 * Real (Model.Emit (S, Sym));
               if Cand > Best_V then
                  Best_V := Cand;
                  Best_S := R;
               end if;
            end loop;
            if Best_V < 0.0 then
               Best_V := 0.0;
            end if;
            Prob (T, S) := Best_V;
            if Best_V > 0.0 then
               Prev (T, S) := Natural (Best_S);
               Any := True;
            else
               Prev (T, S) := 0;
            end if;
         end loop;
         if not Any then
            raise Degenerate_Geometry
              with "Viterbi_Decode: all path probs zero mid-sequence";
         end if;
      end loop;

      Best_S := 1;
      Best_V := Prob (T_Len, 1);
      for S in 2 .. N loop
         if Prob (T_Len, S) > Best_V then
            Best_V := Prob (T_Len, S);
            Best_S := S;
         end if;
      end loop;

      if Best_V <= 0.0 then
         raise Degenerate_Geometry
           with "Viterbi_Decode: no positive-probability path";
      end if;

      Backtrace (Prev, Best_S, Result.Path);
      Result.Probability     := Best_V;
      Result.Log_Probability := Log (Best_V);
      Result.Has_Table       := Fill_Table;
      Result.Backpointers    := Prev;

      if Fill_Table then
         for T in 1 .. T_Len loop
            for S in 1 .. N loop
               Result.Prob_Table (T, S) := Prob (T, S);
            end loop;
         end loop;
      end if;

      return Result;
   end Viterbi_Decode;

   function Viterbi_Decode_Log
     (Model      : HMM;
      Obs        : Observation_Sequence;
      Fill_Table : Boolean := True) return Viterbi_Result
   is
      T_Len  : constant Time_Count := Obs'Length;
      N      : constant State_Count := Model.N_States;
      Result : Viterbi_Result (Length => T_Len, N_States => N);

      L    : array (1 .. T_Len, 1 .. N) of Log_Probability :=
        [others => [others => Log_Zero]];
      Prev : Backpointer_Table (1 .. T_Len, 1 .. N) :=
        [others => [others => 0]];

      Best_S : State_Index;
      Best_L : Log_Probability;
      Cand   : Log_Probability;
      Sym    : Symbol_Index;
      Emit_L : Log_Probability;
      Any    : Boolean;
   begin
      Check_Obs (Model, Obs);

      Sym := Obs (Obs'First);
      Any := False;
      for S in 1 .. N loop
         L (1, S) := Log (Real (Model.Init (S)))
           + Log (Real (Model.Emit (S, Sym)));
         Prev (1, S) := 0;
         if L (1, S) > Log_Zero / 2.0 then
            Any := True;
         end if;
      end loop;
      if not Any then
         raise Degenerate_Geometry
           with "Viterbi_Decode_Log: all init*emit zero at t=1";
      end if;

      for T in 2 .. T_Len loop
         Sym := Obs (Obs'First + T - 1);
         Any := False;
         for S in 1 .. N loop
            Emit_L := Log (Real (Model.Emit (S, Sym)));
            Best_L := Log_Zero;
            Best_S := 1;
            for R in 1 .. N loop
               Cand := L (T - 1, R)
                 + Log (Real (Model.Trans (R, S)))
                 + Emit_L;
               if Cand > Best_L then
                  Best_L := Cand;
                  Best_S := R;
               end if;
            end loop;
            L (T, S) := Best_L;
            if Best_L > Log_Zero / 2.0 then
               Prev (T, S) := Natural (Best_S);
               Any := True;
            else
               Prev (T, S) := 0;
            end if;
         end loop;
         if not Any then
            raise Degenerate_Geometry
              with "Viterbi_Decode_Log: all path logs degenerate";
         end if;
      end loop;

      Best_S := 1;
      Best_L := L (T_Len, 1);
      for S in 2 .. N loop
         if L (T_Len, S) > Best_L then
            Best_L := L (T_Len, S);
            Best_S := S;
         end if;
      end loop;

      if Best_L <= Log_Zero / 2.0 then
         raise Degenerate_Geometry
           with "Viterbi_Decode_Log: no finite-probability path";
      end if;

      Backtrace (Prev, Best_S, Result.Path);
      Result.Log_Probability := Best_L;
      Result.Probability     := Exp (Best_L);
      Result.Has_Table       := Fill_Table;
      Result.Backpointers    := Prev;

      if Fill_Table then
         for T in 1 .. T_Len loop
            for S in 1 .. N loop
               Result.Prob_Table (T, S) := Exp (L (T, S));
            end loop;
         end loop;
      end if;

      return Result;
   end Viterbi_Decode_Log;

   -----------------------------------------------------------------------
   -- Baum–Welch (single-sequence EM)
   -----------------------------------------------------------------------

   procedure M_Step_From_Stats
     (N_States  : State_Count;
      N_Symbols : Symbol_Count;
      Prev      : HMM;
      Pi_Num    : in out Initial_Vector;
      A_Num     : in out Transition_Matrix;
      A_Den     : Initial_Vector;
      B_Num     : in out Emission_Matrix;
      B_Den     : Initial_Vector;
      Out_Model : out HMM)
   is
      Sum : Real;
   begin
      Out_Model := Prev;

      Sum := 0.0;
      for I in 1 .. N_States loop
         if Pi_Num (I) < 0.0 then
            Pi_Num (I) := 0.0;
         end if;
         Sum := Sum + Pi_Num (I);
      end loop;
      if Sum > 0.0 then
         for I in 1 .. N_States loop
            Out_Model.Init (I) := Probability (Pi_Num (I) / Sum);
         end loop;
      end if;

      for I in 1 .. N_States loop
         if A_Den (I) > 0.0 then
            Sum := 0.0;
            for J in 1 .. N_States loop
               if A_Num (I, J) < 0.0 then
                  A_Num (I, J) := 0.0;
               end if;
               Out_Model.Trans (I, J) :=
                 Probability (A_Num (I, J) / A_Den (I));
               Sum := Sum + Out_Model.Trans (I, J);
            end loop;
            if Sum > 0.0 and then abs (Sum - 1.0) > Prob_Tol then
               for J in 1 .. N_States loop
                  Out_Model.Trans (I, J) :=
                    Probability (Out_Model.Trans (I, J) / Sum);
               end loop;
            end if;
         end if;
      end loop;

      for I in 1 .. N_States loop
         if B_Den (I) > 0.0 then
            Sum := 0.0;
            for K in 1 .. N_Symbols loop
               if B_Num (I, K) < 0.0 then
                  B_Num (I, K) := 0.0;
               end if;
               Out_Model.Emit (I, K) :=
                 Probability (B_Num (I, K) / B_Den (I));
               Sum := Sum + Out_Model.Emit (I, K);
            end loop;
            if Sum > 0.0 and then abs (Sum - 1.0) > Prob_Tol then
               for K in 1 .. N_Symbols loop
                  Out_Model.Emit (I, K) :=
                    Probability (Out_Model.Emit (I, K) / Sum);
               end loop;
            end if;
         end if;
      end loop;
   end M_Step_From_Stats;

   function Baum_Welch_Step
     (Model : HMM;
      Obs   : Observation_Sequence) return HMM
   is
      N      : constant State_Count := Model.N_States;
      M      : constant Symbol_Count := Model.N_Symbols;
      T_Len  : constant Time_Count := Obs'Length;
      FB     : constant FB_Result :=
        Forward_Backward (Model, Obs, Fill_Xi => True);
      Pi_Num : Initial_Vector (1 .. N) := [others => 0.0];
      A_Num  : Transition_Matrix (1 .. N, 1 .. N) :=
        [others => [others => 0.0]];
      A_Den  : Initial_Vector (1 .. N) := [others => 0.0];
      B_Num  : Emission_Matrix (1 .. N, 1 .. M) :=
        [others => [others => 0.0]];
      B_Den  : Initial_Vector (1 .. N) := [others => 0.0];
      Out_M  : HMM (N_States => N, N_Symbols => M);
      Sym    : Symbol_Index;
   begin
      for I in 1 .. N loop
         Pi_Num (I) := FB.Gamma (1, I);
      end loop;

      for T in 1 .. T_Len - 1 loop
         for I in 1 .. N loop
            A_Den (I) := A_Den (I) + FB.Gamma (T, I);
            for J in 1 .. N loop
               A_Num (I, J) := A_Num (I, J) + FB.Xi (T, I, J);
            end loop;
         end loop;
      end loop;

      for T in 1 .. T_Len loop
         Sym := Obs (Obs'First + (T - 1));
         for I in 1 .. N loop
            B_Den (I) := B_Den (I) + FB.Gamma (T, I);
            B_Num (I, Sym) := B_Num (I, Sym) + FB.Gamma (T, I);
         end loop;
      end loop;

      M_Step_From_Stats
        (N, M, Model, Pi_Num, A_Num, A_Den, B_Num, B_Den, Out_M);
      return Out_M;
   end Baum_Welch_Step;

   function Baum_Welch_Fit
     (Init_Model       : HMM;
      Obs              : Observation_Sequence;
      Max_Iter         : Positive := 100;
      Tol              : Real := 1.0E-6;
      Keep_History     : Boolean := True;
      Raise_On_No_Conv : Boolean := False) return Fit_Result
   is
      N    : constant State_Count := Init_Model.N_States;
      M    : constant Symbol_Count := Init_Model.N_Symbols;
      HLen : constant Natural :=
        (if Keep_History then Natural (Max_Iter) else 0);
      Result  : Fit_Result
        (N_States => N, N_Symbols => M, History_Len => HLen);
      Current : HMM (N_States => N, N_Symbols => M) := Init_Model;
      Prev_LL : Log_Probability;
      Curr_LL : Log_Probability;
      LL_Delta : Real;
   begin
      Check_Obs (Init_Model, Obs);
      if not Is_Valid_HMM (Init_Model, Require_Stochastic => False) then
         raise Invalid_Argument with "Baum_Welch_Fit: invalid Init_Model";
      end if;

      Curr_LL := Log_Likelihood (Current, Obs);
      Result.Log_Likelihood := Curr_LL;
      Result.Model := Current;
      Result.Iterations := 0;
      Result.Converged := False;

      for Iter in 1 .. Max_Iter loop
         Prev_LL := Curr_LL;
         Current := Baum_Welch_Step (Current, Obs);
         Curr_LL := Log_Likelihood (Current, Obs);

         Result.Iterations := Iter;
         Result.Model := Current;
         Result.Log_Likelihood := Curr_LL;
         if Keep_History then
            Result.History (Iter) := Curr_LL;
         end if;

         LL_Delta := abs (Curr_LL - Prev_LL);
         if LL_Delta < Tol then
            Result.Converged := True;
            return Result;
         end if;
      end loop;

      if Raise_On_No_Conv then
         raise Did_Not_Converge
           with "Baum_Welch_Fit: Max_Iter reached without convergence";
      end if;
      return Result;
   end Baum_Welch_Fit;

end Hidden_Markov_Model;
