--  Viterbi body — product-form and log-domain HMM decoding.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Viterbi
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
         --  Avoid Float overflow in EF.Exp; Real'Last as sentinel.
         return Real'Last;
      else
         return Real (EF.Exp (Float (X)));
      end if;
   end Exp;

   function Argmax_Row (Row : Initial_Vector) return State_Index is
      Best_S : State_Index := Row'First;
      Best_V : Real := Row (Row'First);
   begin
      for S in Row'Range loop
         if Row (S) > Best_V then
            Best_V := Row (S);
            Best_S := S;
         end if;
      end loop;
      return Best_S;
   end Argmax_Row;

   function Argmax_Init_Emit
     (Init : Initial_Vector;
      Emit : Emission_Matrix;
      Obs  : Symbol_Index) return State_Index
   is
      Best_S : State_Index := Init'First;
      Best_V : Real := Init (Init'First) * Emit (Init'First, Obs);
      V      : Real;
   begin
      for S in Init'Range loop
         V := Init (S) * Emit (S, Obs);
         if V > Best_V then
            Best_V := V;
            Best_S := S;
         end if;
      end loop;
      return Best_S;
   end Argmax_Init_Emit;

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
   -- Backtrace shared helper
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
         --  Prev (T+1, S) stores predecessor at time T+1 for state S.
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

   -----------------------------------------------------------------------
   -- Product-form decode
   -----------------------------------------------------------------------

   function Viterbi_Decode
     (Model      : HMM;
      Obs        : Observation_Sequence;
      Fill_Table : Boolean := True) return Viterbi_Result
   is
      T_Len : constant Time_Count := Obs'Length;
      N     : constant State_Count := Model.N_States;
      Result : Viterbi_Result (Length => T_Len, N_States => N);

      --  Local working tables indexed 1 .. T_Len, 1 .. N
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

      --  t = 1 (Wikipedia t = 0)
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

      --  t = 2 .. T
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

      --  Argmax at final time
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

   -----------------------------------------------------------------------
   -- Log-domain decode
   -----------------------------------------------------------------------

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
   -- Wikipedia doctor / fever fixture
   -----------------------------------------------------------------------

   function Make_Doctor_Fever_HMM return HMM is
      Model : HMM (N_States => 2, N_Symbols => 3);
   begin
      --  init = {Healthy: 0.6, Fever: 0.4}
      Model.Init := [Healthy => 0.6, Fever => 0.4];

      --  trans
      Model.Trans :=
        [Healthy => [Healthy => 0.7, Fever => 0.3],
         Fever   => [Healthy => 0.4, Fever => 0.6]];

      --  emit
      Model.Emit :=
        [Healthy => [Normal => 0.5, Cold => 0.4, Dizzy => 0.1],
         Fever   => [Normal => 0.1, Cold => 0.3, Dizzy => 0.6]];

      return Model;
   end Make_Doctor_Fever_HMM;

end Viterbi;
