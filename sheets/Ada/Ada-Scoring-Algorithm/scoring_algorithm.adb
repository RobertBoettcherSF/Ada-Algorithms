--  Scoring_Algorithm body — Fisher scoring / observed-information Newton.

pragma Ada_2022;

package body Scoring_Algorithm
  with SPARK_Mode => Off
is

   -----------------------------------------------------------------------
   -- Numeric helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Clamp_Unit_Interval
     (P : Real; Eps : Real := Prob_Eps) return Real
   is
   begin
      if P < Eps then
         return Eps;
      elsif P > 1.0 - Eps then
         return 1.0 - Eps;
      else
         return P;
      end if;
   end Clamp_Unit_Interval;

   function Sample_Sum (Data : Sample) return Real is
      S : Real := 0.0;
   begin
      for X of Data loop
         S := S + X;
      end loop;
      return S;
   end Sample_Sum;

   function Sample_Mean (Data : Sample) return Real is
   begin
      if Data'Length = 0 then
         raise Empty_Sample with "Sample_Mean requires at least one observation";
      end if;
      return Sample_Sum (Data) / Real (Data'Length);
   end Sample_Mean;

   function Count_Successes (Data : Sample) return Natural is
      K : Natural := 0;
   begin
      for X of Data loop
         if X >= 0.5 then
            K := K + 1;
         end if;
      end loop;
      return K;
   end Count_Successes;

   -----------------------------------------------------------------------
   -- Generic scalar step / iteration
   -----------------------------------------------------------------------

   function Fisher_Step
     (Theta : Real;
      Score : Real;
      Info  : Real) return Real
   is
   begin
      if abs (Info) < Info_Singularity then
         raise Singular_Information
           with "Fisher_Step: information near zero";
      end if;
      return Theta + Score / Info;
   end Fisher_Step;

   function Run_Scalar_Scoring
     (Data          : Sample;
      Start         : Real;
      Score_Of      : Score_Fn;
      Info_Of       : Info_Fn;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True;
      Lower         : Real := Real'First;
      Upper         : Real := Real'Last) return Scoring_Result
   is
      --  Kind is recorded in the result; caller selects Info_Of = I or J.
      Theta   : Real := Start;
      V, Ij   : Real;
      D_Theta : Real;
      Res     : Scoring_Result;
      Done    : Boolean := False;
   begin
      if Data'Length = 0 then
         raise Empty_Sample with "Run_Scalar_Scoring: empty sample";
      end if;
      if Score_Of = null or else Info_Of = null then
         raise Invalid_Argument with "Run_Scalar_Scoring: null callback";
      end if;

      --  Project start onto optional domain bounds.
      if Theta < Lower then
         Theta := Lower;
      elsif Theta > Upper then
         Theta := Upper;
      end if;

      Res.Kind := Kind;
      Res.Converged := False;
      Res.Iterations := 0;

      for Iter in 1 .. Max_Iter loop
         V := Score_Of (Theta, Data);
         Ij := Info_Of (Theta, Data);
         Res.Last_Score := V;
         Res.Last_Info := Ij;
         Res.Iterations := Iter;

         if abs (V) <= Tol then
            Res.Estimate := Theta;
            Res.Converged := True;
            Done := True;
            exit;
         end if;

         declare
            Theta_Prev : constant Real := Theta;
         begin
            D_Theta := Fisher_Step (Theta, V, Ij) - Theta;
            Theta := Theta + D_Theta;

            --  Optional domain projection (e.g. λ >= Prob_Eps for Poisson).
            if Theta < Lower then
               Theta := Lower;
            elsif Theta > Upper then
               Theta := Upper;
            end if;

            --  Step size after projection (may be 0 if clamped to a bound).
            D_Theta := Theta - Theta_Prev;
         end;

         --  Re-evaluate at (possibly projected) point so Last_Score is
         --  meaningful and convergence can use |V| at the feasible θ.
         V := Score_Of (Theta, Data);
         Ij := Info_Of (Theta, Data);
         Res.Last_Score := V;
         Res.Last_Info := Ij;

         if abs (D_Theta) <= Tol or else abs (V) <= Tol then
            Res.Estimate := Theta;
            Res.Converged := True;
            Done := True;
            exit;
         end if;
      end loop;

      if not Done then
         Res.Estimate := Theta;
         Res.Converged := False;
         if Raise_On_Fail then
            raise Did_Not_Converge
              with "Run_Scalar_Scoring: failed to converge within Max_Iter";
         end if;
      end if;

      return Res;
   end Run_Scalar_Scoring;

   -----------------------------------------------------------------------
   -- Bernoulli
   -----------------------------------------------------------------------

   function Bernoulli_Score
     (P : Real; K : Natural; N : Positive) return Real
   is
      N_Fail : constant Natural := N - K;
   begin
      return Real (K) / P - Real (N_Fail) / (1.0 - P);
   end Bernoulli_Score;

   function Bernoulli_Fisher_Info
     (P : Real; N : Positive) return Real
   is
   begin
      return Real (N) / (P * (1.0 - P));
   end Bernoulli_Fisher_Info;

   function Bernoulli_Observed_Info
     (P : Real; K : Natural; N : Positive) return Real
   is
      N_Fail : constant Natural := N - K;
   begin
      return Real (K) / (P * P) + Real (N_Fail) / ((1.0 - P) * (1.0 - P));
   end Bernoulli_Observed_Info;

   function Bernoulli_MLE (K : Natural; N : Positive) return Real is
   begin
      return Real (K) / Real (N);
   end Bernoulli_MLE;

   function Bernoulli_Score_Sample (P : Real; Data : Sample) return Real is
      K : constant Natural := Count_Successes (Data);
      N : constant Positive := Data'Length;
   begin
      return Bernoulli_Score (P, K, N);
   end Bernoulli_Score_Sample;

   function Bernoulli_Fisher_Info_Sample
     (P : Real; Data : Sample) return Real
   is
   begin
      return Bernoulli_Fisher_Info (P, Data'Length);
   end Bernoulli_Fisher_Info_Sample;

   function Bernoulli_Observed_Info_Sample
     (P : Real; Data : Sample) return Real
   is
      K : constant Natural := Count_Successes (Data);
   begin
      return Bernoulli_Observed_Info (P, K, Data'Length);
   end Bernoulli_Observed_Info_Sample;

   --  Wrapped callbacks that clamp θ into (Prob_Eps, 1−Prob_Eps).
   function Bern_Score_Cb (Theta : Real; Data : Sample) return Real is
      P : constant Real := Clamp_Unit_Interval (Theta);
   begin
      return Bernoulli_Score_Sample (P, Data);
   end Bern_Score_Cb;

   function Bern_Fisher_Cb (Theta : Real; Data : Sample) return Real is
      P : constant Real := Clamp_Unit_Interval (Theta);
   begin
      return Bernoulli_Fisher_Info_Sample (P, Data);
   end Bern_Fisher_Cb;

   function Bern_Obs_Cb (Theta : Real; Data : Sample) return Real is
      P : constant Real := Clamp_Unit_Interval (Theta);
   begin
      return Bernoulli_Observed_Info_Sample (P, Data);
   end Bern_Obs_Cb;

   function Fit_Bernoulli
     (Data          : Sample;
      Start         : Real := 0.5;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
   is
      Info : Info_Fn;
      S0   : constant Real := Clamp_Unit_Interval (Start);
      Res  : Scoring_Result;
   begin
      if Data'Length = 0 then
         raise Empty_Sample with "Fit_Bernoulli: empty sample";
      end if;

      case Kind is
         when Fisher_Expected =>
            Info := Bern_Fisher_Cb'Access;
         when Observed_Newton =>
            Info := Bern_Obs_Cb'Access;
      end case;

      Res := Run_Scalar_Scoring
        (Data          => Data,
         Start         => S0,
         Score_Of      => Bern_Score_Cb'Access,
         Info_Of       => Info,
         Kind          => Kind,
         Max_Iter      => Max_Iter,
         Tol           => Tol,
         Raise_On_Fail => Raise_On_Fail);
      --  Report estimate clamped to open unit interval for numerical safety.
      Res.Estimate := Clamp_Unit_Interval (Res.Estimate);
      return Res;
   end Fit_Bernoulli;

   function Fit_Bernoulli_Counts
     (K             : Natural;
      N             : Positive;
      Start         : Real := 0.5;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
   is
      Data : Sample (1 .. N);
   begin
      for I in Data'Range loop
         if I <= K then
            Data (I) := 1.0;
         else
            Data (I) := 0.0;
         end if;
      end loop;
      return Fit_Bernoulli
        (Data, Start, Kind, Max_Iter, Tol, Raise_On_Fail);
   end Fit_Bernoulli_Counts;

   -----------------------------------------------------------------------
   -- Poisson
   -----------------------------------------------------------------------

   function Poisson_Score (Lambda : Real; Data : Sample) return Real is
      N : constant Positive := Data'Length;
   begin
      return -Real (N) + Sample_Sum (Data) / Lambda;
   end Poisson_Score;

   function Poisson_Fisher_Info
     (Lambda : Real; Data : Sample) return Real
   is
   begin
      return Real (Data'Length) / Lambda;
   end Poisson_Fisher_Info;

   function Poisson_Observed_Info
     (Lambda : Real; Data : Sample) return Real
   is
   begin
      return Sample_Sum (Data) / (Lambda * Lambda);
   end Poisson_Observed_Info;

   function Poisson_MLE (Data : Sample) return Real is
   begin
      return Sample_Mean (Data);
   end Poisson_MLE;

   function Pois_Score_Cb (Theta : Real; Data : Sample) return Real is
      Lam : Real := Theta;
   begin
      if Lam < Prob_Eps then
         Lam := Prob_Eps;
      end if;
      return Poisson_Score (Lam, Data);
   end Pois_Score_Cb;

   function Pois_Fisher_Cb (Theta : Real; Data : Sample) return Real is
      Lam : Real := Theta;
   begin
      if Lam < Prob_Eps then
         Lam := Prob_Eps;
      end if;
      return Poisson_Fisher_Info (Lam, Data);
   end Pois_Fisher_Cb;

   function Pois_Obs_Cb (Theta : Real; Data : Sample) return Real is
      Lam : Real := Theta;
   begin
      if Lam < Prob_Eps then
         Lam := Prob_Eps;
      end if;
      return Poisson_Observed_Info (Lam, Data);
   end Pois_Obs_Cb;

   function Fit_Poisson
     (Data          : Sample;
      Start         : Real := 1.0;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
   is
      Info : Info_Fn;
      S0   : Real := Start;
      Res  : Scoring_Result;
   begin
      if Data'Length = 0 then
         raise Empty_Sample with "Fit_Poisson: empty sample";
      end if;
      if S0 < Prob_Eps then
         S0 := Prob_Eps;
      end if;

      case Kind is
         when Fisher_Expected =>
            Info := Pois_Fisher_Cb'Access;
         when Observed_Newton =>
            Info := Pois_Obs_Cb'Access;
      end case;

      Res := Run_Scalar_Scoring
        (Data, S0, Pois_Score_Cb'Access, Info, Kind,
         Max_Iter, Tol, Raise_On_Fail, Lower => Prob_Eps);
      if Res.Estimate < Prob_Eps then
         Res.Estimate := Prob_Eps;
      end if;
      return Res;
   end Fit_Poisson;

   -----------------------------------------------------------------------
   -- Normal mean (known σ²)
   -----------------------------------------------------------------------

   --  Package-level Sigma2 for callback closures (set before Run).
   Normal_Sigma2_Store : Real := 1.0;

   function Normal_Mean_Score
     (Mu : Real; Sigma2 : Real; Data : Sample) return Real
   is
      Acc : Real := 0.0;
   begin
      for X of Data loop
         Acc := Acc + (X - Mu);
      end loop;
      return Acc / Sigma2;
   end Normal_Mean_Score;

   function Normal_Mean_Fisher_Info
     (Sigma2 : Real; N : Positive) return Real
   is
   begin
      return Real (N) / Sigma2;
   end Normal_Mean_Fisher_Info;

   function Normal_Mean_Observed_Info
     (Sigma2 : Real; N : Positive) return Real
   is
   begin
      return Real (N) / Sigma2;
   end Normal_Mean_Observed_Info;

   function Normal_Mean_MLE (Data : Sample) return Real is
   begin
      return Sample_Mean (Data);
   end Normal_Mean_MLE;

   function Norm_Score_Cb (Theta : Real; Data : Sample) return Real is
   begin
      return Normal_Mean_Score (Theta, Normal_Sigma2_Store, Data);
   end Norm_Score_Cb;

   function Norm_Fisher_Cb (Theta : Real; Data : Sample) return Real is
      pragma Unreferenced (Theta);
   begin
      return Normal_Mean_Fisher_Info (Normal_Sigma2_Store, Data'Length);
   end Norm_Fisher_Cb;

   function Norm_Obs_Cb (Theta : Real; Data : Sample) return Real is
      pragma Unreferenced (Theta);
   begin
      return Normal_Mean_Observed_Info (Normal_Sigma2_Store, Data'Length);
   end Norm_Obs_Cb;

   function Fit_Normal_Mean
     (Data          : Sample;
      Sigma2        : Real;
      Start         : Real := 0.0;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
   is
      Info : Info_Fn;
   begin
      if Data'Length = 0 then
         raise Empty_Sample with "Fit_Normal_Mean: empty sample";
      end if;
      if Sigma2 <= 0.0 then
         raise Invalid_Argument with "Fit_Normal_Mean: Sigma2 must be > 0";
      end if;

      Normal_Sigma2_Store := Sigma2;

      case Kind is
         when Fisher_Expected =>
            Info := Norm_Fisher_Cb'Access;
         when Observed_Newton =>
            Info := Norm_Obs_Cb'Access;
      end case;

      return Run_Scalar_Scoring
        (Data, Start, Norm_Score_Cb'Access, Info, Kind,
         Max_Iter, Tol, Raise_On_Fail);
   end Fit_Normal_Mean;

   -----------------------------------------------------------------------
   -- Exponential rate
   -----------------------------------------------------------------------

   function Exponential_Score (Lambda : Real; Data : Sample) return Real is
   begin
      return Real (Data'Length) / Lambda - Sample_Sum (Data);
   end Exponential_Score;

   function Exponential_Fisher_Info
     (Lambda : Real; Data : Sample) return Real
   is
   begin
      return Real (Data'Length) / (Lambda * Lambda);
   end Exponential_Fisher_Info;

   function Exponential_Observed_Info
     (Lambda : Real; Data : Sample) return Real
   is
   begin
      return Real (Data'Length) / (Lambda * Lambda);
   end Exponential_Observed_Info;

   function Exponential_MLE (Data : Sample) return Real is
      Mu : constant Real := Sample_Mean (Data);
   begin
      if Mu <= 0.0 then
         raise Invalid_Argument
           with "Exponential_MLE: sample mean must be positive";
      end if;
      return 1.0 / Mu;
   end Exponential_MLE;

   function Exp_Score_Cb (Theta : Real; Data : Sample) return Real is
      Lam : Real := Theta;
   begin
      if Lam < Prob_Eps then
         Lam := Prob_Eps;
      end if;
      return Exponential_Score (Lam, Data);
   end Exp_Score_Cb;

   function Exp_Fisher_Cb (Theta : Real; Data : Sample) return Real is
      Lam : Real := Theta;
   begin
      if Lam < Prob_Eps then
         Lam := Prob_Eps;
      end if;
      return Exponential_Fisher_Info (Lam, Data);
   end Exp_Fisher_Cb;

   function Exp_Obs_Cb (Theta : Real; Data : Sample) return Real is
      Lam : Real := Theta;
   begin
      if Lam < Prob_Eps then
         Lam := Prob_Eps;
      end if;
      return Exponential_Observed_Info (Lam, Data);
   end Exp_Obs_Cb;

   function Fit_Exponential
     (Data          : Sample;
      Start         : Real := 1.0;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
   is
      Info : Info_Fn;
      S0   : Real := Start;
      Res  : Scoring_Result;
   begin
      if Data'Length = 0 then
         raise Empty_Sample with "Fit_Exponential: empty sample";
      end if;
      if S0 < Prob_Eps then
         S0 := Prob_Eps;
      end if;

      case Kind is
         when Fisher_Expected =>
            Info := Exp_Fisher_Cb'Access;
         when Observed_Newton =>
            Info := Exp_Obs_Cb'Access;
      end case;

      Res := Run_Scalar_Scoring
        (Data, S0, Exp_Score_Cb'Access, Info, Kind,
         Max_Iter, Tol, Raise_On_Fail, Lower => Prob_Eps);
      if Res.Estimate < Prob_Eps then
         Res.Estimate := Prob_Eps;
      end if;
      return Res;
   end Fit_Exponential;

end Scoring_Algorithm;
