--  Odds_Algorithm body — Bruss odds algorithm for last-success stopping.

pragma Ada_2022;

package body Odds_Algorithm
  with SPARK_Mode => Off
is

   -----------------------------------------------------------------------
   -- Local: simple LCG for Monte Carlo (deterministic, no Ada.Numerics)
   -----------------------------------------------------------------------

   type U32 is mod 2 ** 32;

   function Next_U32 (State : in out U32) return U32 is
   begin
      --  Numerical Recipes LCG parameters
      State := State * 1_664_525 + 1_013_904_223;
      return State;
   end Next_U32;

   function Unit_Random (State : in out U32) return Real is
      X : constant U32 := Next_U32 (State);
   begin
      return Real (X) / Real (U32'Last);
   end Unit_Random;

   function Bernoulli (P : Real; State : in out U32) return Boolean is
   begin
      if P <= 0.0 then
         return False;
      elsif P >= 1.0 then
         return True;
      else
         return Unit_Random (State) < P;
      end if;
   end Bernoulli;

   -----------------------------------------------------------------------
   -- Numeric helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   -----------------------------------------------------------------------
   -- Core odds formula
   -----------------------------------------------------------------------

   function Odds (P_K : Real) return Real is
   begin
      if P_K < 0.0 or else P_K >= 1.0 then
         raise Invalid_Argument
           with "Odds: p must lie in [0, 1)";
      end if;
      if P_K = 0.0 then
         return 0.0;
      end if;
      return P_K / (1.0 - P_K);
   end Odds;

   -----------------------------------------------------------------------
   -- Odds algorithm (Bruss)
   -----------------------------------------------------------------------

   function Compute_Threshold (P : Probability_Vector) return Odds_Result is
      N      : constant Natural := P'Length;
      R_Sum  : Real := 0.0;
      Q_Prod : Real := 1.0;
      S      : Positive;
      Res    : Odds_Result;
      Found  : Boolean := False;
      Sure   : Boolean := False;
      R_K    : Real;
      Q_K    : Real;
      P_K    : Real;
   begin
      if N = 0 then
         raise Invalid_Argument
           with "Compute_Threshold: empty probability vector";
      end if;
      if N > Max_N then
         raise Capacity_Exceeded
           with "Compute_Threshold: length exceeds Max_N";
      end if;

      --  Validate and detect sure successes
      for K in P'Range loop
         P_K := P (K);
         if P_K < 0.0 or else P_K > 1.0 then
            raise Invalid_Argument
              with "Compute_Threshold: each p_k must lie in [0, 1]";
         end if;
         if P_K = 1.0 then
            Sure := True;
         end if;
      end loop;

      --  Sum odds from the end until R ≥ 1; accumulate Q in parallel
      S := P'First;
      for K in reverse P'Range loop
         P_K := P (K);
         if P_K = 1.0 then
            R_K := Huge_Odds;
            Q_K := 0.0;
         else
            Q_K := 1.0 - P_K;
            if P_K = 0.0 then
               R_K := 0.0;
            else
               R_K := P_K / Q_K;
            end if;
         end if;

         R_Sum  := R_Sum + R_K;
         Q_Prod := Q_Prod * Q_K;
         S      := K;

         if R_Sum >= 1.0 then
            Found := True;
            exit;
         end if;
      end loop;

      --  If sum never reaches 1, Wikipedia sets s = 1 (= First)
      if not Found then
         S := P'First;
      end if;

      Res.Threshold_S      := S;
      Res.R_Sum            := R_Sum;
      Res.Q_Product        := Q_Prod;
      Res.Had_Sure_Success := Sure;

      --  w = Q_s R_s; when a sure success (q=0) sits in [s..n], Q=0 and
      --  R may include Huge_Odds — report 0 for the product (indeterminate
      --  ∞·0 case is documented; threshold itself remains well-defined).
      if Sure and then Q_Prod = 0.0 then
         Res.Win_Probability := 0.0;
      else
         Res.Win_Probability := Q_Prod * R_Sum;
      end if;

      return Res;
   end Compute_Threshold;

   function Should_Stop
     (K                       : Positive;
      Observation_Interesting : Boolean;
      Threshold_S             : Positive) return Boolean
   is
   begin
      return K >= Threshold_S and then Observation_Interesting;
   end Should_Stop;

   function Apply_Strategy
     (Interesting : Boolean_Array;
      Threshold_S : Positive) return Natural
   is
   begin
      if Interesting'Length = 0 then
         raise Invalid_Argument
           with "Apply_Strategy: empty observation sequence";
      end if;

      for K in Interesting'Range loop
         if K >= Threshold_S and then Interesting (K) then
            return Natural (K);
         end if;
      end loop;
      return 0;
   end Apply_Strategy;

   -----------------------------------------------------------------------
   -- Helpers
   -----------------------------------------------------------------------

   function Uniform_P (N : Positive; P : Real) return Probability_Vector is
      Result : Probability_Vector (1 .. N);
   begin
      if N > Max_N then
         raise Capacity_Exceeded with "Uniform_P: N exceeds Max_N";
      end if;
      if P < 0.0 or else P >= 1.0 then
         raise Invalid_Argument with "Uniform_P: p must lie in [0, 1)";
      end if;
      for K in Result'Range loop
         Result (K) := P;
      end loop;
      return Result;
   end Uniform_P;

   function Secretary_Record_Probabilities
     (N : Positive) return Probability_Vector
   is
      Result : Probability_Vector (1 .. N);
   begin
      if N > Max_N then
         raise Capacity_Exceeded
           with "Secretary_Record_Probabilities: N exceeds Max_N";
      end if;
      for K in Result'Range loop
         Result (K) := 1.0 / Real (K);
      end loop;
      return Result;
   end Secretary_Record_Probabilities;

   function Simulate_Win_Rate
     (P           : Probability_Vector;
      Threshold_S : Positive;
      Trials      : Positive;
      Seed        : Natural := 1) return Real
   is
      State   : U32 := U32 (Seed) + 1;
      Wins    : Natural := 0;
      Stop_At : Natural;
      Last_Suc : Natural;
      Interesting : Boolean_Array (P'Range);
   begin
      if P'Length = 0 then
         raise Invalid_Argument with "Simulate_Win_Rate: empty P";
      end if;
      if Threshold_S < P'First or else Threshold_S > P'Last then
         raise Invalid_Argument
           with "Simulate_Win_Rate: Threshold_S out of range";
      end if;

      for T in 1 .. Trials loop
         Last_Suc := 0;
         for K in P'Range loop
            Interesting (K) := Bernoulli (P (K), State);
            if Interesting (K) then
               Last_Suc := Natural (K);
            end if;
         end loop;

         Stop_At := Apply_Strategy (Interesting, Threshold_S);

         --  Win iff we stop on the last success (and there was at least one)
         if Last_Suc > 0 and then Stop_At = Last_Suc then
            Wins := Wins + 1;
         end if;
      end loop;

      return Real (Wins) / Real (Trials);
   end Simulate_Win_Rate;

end Odds_Algorithm;
