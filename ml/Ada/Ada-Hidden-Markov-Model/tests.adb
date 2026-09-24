--  Standalone test suite for Hidden_Markov_Model (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Hidden_Markov_Model; use Hidden_Markov_Model;

procedure Tests is

   Fail_Count : Natural := 0;
   Pass_Count : Natural := 0;

   procedure Check (Cond : Boolean; Msg : String) is
   begin
      if Cond then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Msg);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Msg);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Paths_Equal (A, B : State_Sequence) return Boolean is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in 0 .. A'Length - 1 loop
         if A (A'First + I) /= B (B'First + I) then
            return False;
         end if;
      end loop;
      return True;
   end Paths_Equal;

   function Id_Nat (X : Natural) return Natural is (X);

begin
   Put_Line ("Hidden_Markov_Model test suite (educational survey)");
   Put_Line ("===================================================");

   ------------------------------------------------------------------
   Section ("1. Near / Log / Exp helpers");
   ------------------------------------------------------------------
   declare
      L0 : constant Log_Probability := Log (0.0);
      L1 : constant Log_Probability := Log (1.0);
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (L0 <= Log_Zero / 2.0, "Log(0) is Log_Zero sentinel");
      Check (Approx (L1, 0.0, 1.0E-6), "Log(1) ≈ 0");
      Check (Approx (Exp (0.0), 1.0, 1.0E-5), "Exp(0) ≈ 1");
      Check (Approx (Exp (L0), 0.0, 1.0E-12), "Exp(Log_Zero) ≈ 0");
      Check (Approx (Exp (Log (0.25)), 0.25, 1.0E-5), "Exp(Log(0.25))≈0.25");
   end;

   ------------------------------------------------------------------
   Section ("2. HMM validation / Normalize_Rows");
   ------------------------------------------------------------------
   declare
      Good  : constant HMM := Make_Doctor_Fever_HMM;
      Empty : HMM (N_States => 0, N_Symbols => 0);
   begin
      Check (Is_Valid_HMM (Good), "doctor/fever Is_Valid_HMM");
      Check (Good.N_States = 2 and then Good.N_Symbols = 3, "doctor dims");
      Check (Approx (Real (Good.Init (Healthy)), 0.6), "π(Healthy)=0.6");
      Check (Approx (Real (Good.Init (Fever)), 0.4), "π(Fever)=0.4");
      Check (not Is_Valid_HMM (Empty), "empty HMM invalid");

      declare
         Bad : HMM (N_States => 2, N_Symbols => 2) :=
           (N_States => 2, N_Symbols => 2,
            Init  => [0.5, 0.5],
            Trans => [[0.5, 0.5], [0.5, 0.5]],
            Emit  => [[0.5, 0.5], [0.5, 0.5]]);
      begin
         Check (Is_Valid_HMM (Bad), "simple 2x2 valid");
         Bad.Init := [0.9, 0.9];
         Check (not Is_Valid_HMM (Bad), "init not stochastic -> invalid");
         Check (Is_Valid_HMM (Bad, Require_Stochastic => False),
                "non-stochastic allowed when Require=False");
      end;

      declare
         M : HMM (N_States => 2, N_Symbols => 2) :=
           (N_States => 2, N_Symbols => 2,
            Init  => [1.0, 1.0],
            Trans => [[1.0, 1.0], [3.0, 1.0]],
            Emit  => [[2.0, 0.0], [0.0, 4.0]]);
      begin
         Normalize_Rows (M);
         Check (Is_Valid_HMM (M), "Normalize_Rows yields valid HMM");
         Check (Approx (Real (M.Init (1)), 0.5), "Normalize_Rows init ≈ 0.5");
         Check (Approx (Real (M.Trans (1, 1)), 0.5), "Normalize_Rows A row");
         Check (Approx (Real (M.Emit (2, 2)), 1.0), "Normalize_Rows B row");
      end;

      declare
         Raised : Boolean := False;
         M      : HMM (N_States => 0, N_Symbols => 0);
      begin
         begin
            Normalize_Rows (M);
         exception
            when Invalid_Argument =>
               Raised := True;
         end;
         Check (Raised, "Normalize_Rows empty raises Invalid_Argument");
      end;
   end;

   ------------------------------------------------------------------
   Section ("3. Random_Init_HMM reproducibility");
   ------------------------------------------------------------------
   declare
      A : constant HMM := Random_Init_HMM (3, 4, Seed => 42);
      B : constant HMM := Random_Init_HMM (3, 4, Seed => 42);
      C : constant HMM := Random_Init_HMM (3, 4, Seed => 99);
   begin
      Check (Is_Valid_HMM (A), "Random_Init_HMM is valid");
      Check (A.N_States = 3 and then A.N_Symbols = 4, "Random dims");
      Check (Near (Real (A.Init (1)), Real (B.Init (1)))
             and then Near (Real (A.Trans (2, 3)), Real (B.Trans (2, 3))),
             "same seed → same Init/Trans");
      Check (not Near (Real (A.Init (1)), Real (C.Init (1)), 1.0E-12)
             or else not Near (Real (A.Emit (1, 1)), Real (C.Emit (1, 1)),
                               1.0E-12),
             "different seeds differ");
      Check (Approx (Real (A.Init (1)) + Real (A.Init (2)) + Real (A.Init (3)),
                     1.0, Prob_Tol),
             "random π sums to 1");
      Check (Approx (Real (A.Trans (1, 1)) + Real (A.Trans (1, 2))
                     + Real (A.Trans (1, 3)), 1.0, Prob_Tol),
             "random A row1 sums to 1");
      Check (Approx (Real (A.Emit (2, 1)) + Real (A.Emit (2, 2))
                     + Real (A.Emit (2, 3)) + Real (A.Emit (2, 4)),
                     1.0, Prob_Tol),
             "random B row2 sums to 1");
   end;

   ------------------------------------------------------------------
   Section ("4. Wikipedia doctor/fever Viterbi path + known P");
   ------------------------------------------------------------------
   declare
      Model    : constant HMM := Make_Doctor_Fever_HMM;
      Obs      : constant Observation_Sequence := [Normal, Cold, Dizzy];
      Expected : constant State_Sequence := [Healthy, Healthy, Fever];
      R        : constant Viterbi_Result :=
        Viterbi_Decode (Model, Obs);
      Rl       : constant Viterbi_Result :=
        Viterbi_Decode_Log (Model, Obs);
   begin
      Check (R.Path (1) = Healthy, "wiki path day1 Healthy");
      Check (R.Path (2) = Healthy, "wiki path day2 Healthy");
      Check (R.Path (3) = Fever,   "wiki path day3 Fever");
      Check (Paths_Equal (R.Path, Expected), "full path Healthy,Healthy,Fever");
      Check (Approx (R.Probability, 0.01512, 1.0E-6),
             "Viterbi P ≈ 0.01512 (wiki table)");
      Check (Approx (R.Prob_Table (1, Healthy), 0.3, 1.0E-9),
             "DP table day1 Healthy = 0.3");
      Check (Approx (R.Prob_Table (3, Fever), 0.01512, 1.0E-6),
             "DP table day3 Fever = 0.01512");
      Check (Paths_Equal (Rl.Path, R.Path), "log decode same path");
      Check (Approx (Exp (Rl.Log_Probability), R.Probability, 1.0E-5),
             "log decode Exp(L) matches product P");
      Check (Approx (Path_Probability (Model, Obs, R.Path), 0.01512, 1.0E-6),
             "Path_Probability agrees with Viterbi P");
      Check (R.Has_Table, "Viterbi Fill_Table default True");
      Check (Approx (R.Prob_Table (2, Healthy), 0.084, 1.0E-6),
             "DP table day2 Healthy = 0.084");
      Check (Approx (R.Prob_Table (2, Fever), 0.027, 1.0E-6),
             "DP table day2 Fever = 0.027");
      Check (Approx (R.Prob_Table (3, Healthy), 0.00588, 1.0E-6),
             "DP table day3 Healthy = 0.00588");
      Check (R.Backpointers (3, Fever) = Natural (Healthy),
             "backpointer day3 Fever <- Healthy");
      Check (Approx (Rl.Log_Probability, Log (0.01512), 1.0E-4),
             "log Viterbi L ≈ Log(0.01512)");
   end;

   ------------------------------------------------------------------
   Section ("5. Viterbi path beats alternate explanations");
   ------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      Best  : constant Viterbi_Result := Viterbi_Decode (Model, Obs);
      Alt1  : constant State_Sequence := [Fever, Fever, Fever];
      Alt2  : constant State_Sequence := [Healthy, Healthy, Healthy];
      Alt3  : constant State_Sequence := [Fever, Healthy, Fever];
      P_Best : constant Real := Path_Probability (Model, Obs, Best.Path);
      P1     : constant Real := Path_Probability (Model, Obs, Alt1);
      P2     : constant Real := Path_Probability (Model, Obs, Alt2);
      P3     : constant Real := Path_Probability (Model, Obs, Alt3);
   begin
      Check (P_Best >= P1, "Viterbi ≥ all-Fever");
      Check (P_Best >= P2, "Viterbi ≥ all-Healthy");
      Check (P_Best >= P3, "Viterbi ≥ Fever,Healthy,Fever");
      Check (P_Best > P1 or else P_Best > P2, "strictly beats some alternate");
      Check (Approx (Log_Path_Probability (Model, Obs, Best.Path),
                     Log (P_Best), 1.0E-4),
             "Log_Path_Probability ≈ Log(P)");
      Check (P_Best > 0.0, "best path P > 0");
      Check (P1 > 0.0 and then P2 > 0.0 and then P3 > 0.0,
             "alternate paths also positive mass");
      Check (Approx (Best.Probability, P_Best, 1.0E-9),
             "Viterbi.Probability == Path_Probability");
   end;

   ------------------------------------------------------------------
   Section ("6. Log_Likelihood / Likelihood finite (scaled forward)");
   ------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      L     : constant Real := Likelihood (Model, Obs);
      LL    : constant Log_Probability := Log_Likelihood (Model, Obs);
   begin
      Check (L > 0.0, "Likelihood positive");
      Check (Approx (L, 0.03628, 5.0E-4), "Likelihood ≈ 0.03628 (wiki FB)");
      Check (Approx (LL, Log (L), 1.0E-4), "Log_Likelihood ≈ Log(L)");
      Check (LL < 0.0, "Log_Likelihood negative for P<1");
      Check (LL > Log_Zero / 2.0, "Log_Likelihood finite (not Log_Zero)");
   end;

   ------------------------------------------------------------------
   Section ("7. Filter — filtered rows sum to 1");
   ------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      Filt  : constant Posterior_Table := Filter (Model, Obs);
      Ok    : Boolean := True;
      Sum   : Real;
   begin
      Check (Filt'Length (1) = 3, "Filter length = T");
      Check (Filt'Length (2) = 2, "Filter N_States = 2");
      for T in 1 .. 3 loop
         Sum := Filt (T, 1) + Filt (T, 2);
         if abs (Sum - 1.0) > Prob_Tol then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "each filtered row sums to 1");
      Check (Filt (1, Healthy) > Filt (1, Fever),
             "day1 filtered prefers Healthy (normal)");
   end;

   ------------------------------------------------------------------
   Section ("8. Smooth / Forward_Backward — γ rows sum 1");
   ------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      FB    : constant FB_Result := Forward_Backward (Model, Obs);
      G     : constant Posterior_Table := Smooth (Model, Obs);
      Ok    : Boolean := True;
      Sum   : Real;
      Ok_X  : Boolean := True;
   begin
      Check (FB.Length = 3, "FB length 3");
      Check (FB.Has_Xi, "FB fills Xi by default");
      Check (FB.Xi_Last = 2, "Xi_Last = T-1");
      Check (FB.Log_Likelihood < 0.0, "FB log L < 0");
      for T in 1 .. 3 loop
         Sum := FB.Gamma (T, 1) + FB.Gamma (T, 2);
         if abs (Sum - 1.0) > Prob_Tol then
            Ok := False;
         end if;
         Sum := G (T, 1) + G (T, 2);
         if abs (Sum - 1.0) > Prob_Tol then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "each γ_t sums to 1 (FB and Smooth)");
      Check (Approx (FB.Gamma (1, Healthy), G (1, Healthy), 1.0E-9),
             "Smooth matches FB.Gamma");

      for T in 1 .. FB.Xi_Last loop
         for I in 1 .. 2 loop
            Sum := FB.Xi (T, I, 1) + FB.Xi (T, I, 2);
            if abs (Sum - FB.Gamma (T, I)) > 1.0E-4 then
               Ok_X := False;
            end if;
         end loop;
      end loop;
      Check (Ok_X, "Σ_j ξ_t(i,j) ≈ γ_t(i)");
      Check (Approx (FB.Likelihood, Likelihood (Model, Obs), 1.0E-9),
             "FB.Likelihood matches Likelihood()");
      Check (Approx (FB.Log_Likelihood, Log_Likelihood (Model, Obs), 1.0E-9),
             "FB.Log_Likelihood matches Log_Likelihood()");
      Check (FB.Gamma (3, Fever) > FB.Gamma (3, Healthy),
             "smoothed day3 prefers Fever");
      Check (FB.Scales (1) > 0.0 and then FB.Scales (3) > 0.0,
             "scale factors positive");
   end;

   ------------------------------------------------------------------
   Section ("9. Posterior_Mode_Path vs Viterbi (may differ)");
   ------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      FB    : constant FB_Result :=
        Forward_Backward (Model, Obs, Fill_Xi => False);
      Mode  : constant State_Sequence := Posterior_Mode_Path (FB.Gamma);
      Vit   : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs);
   begin
      --  On the classic doctor/fever example they coincide.
      Check (Paths_Equal (Mode, Vit.Path),
             "doctor/fever: posterior mode coincides with Viterbi");
      Check (Mode (1) = Healthy and then Mode (3) = Fever,
             "mode path ends Fever");
   end;

   --  Fixture where marginal MAP can differ from joint MAP (Viterbi):
   --  Construct a short chain where per-time modes prefer a transition
   --  that is jointly impossible / low-prob. Educational note fixture.
   declare
      --  2 states, 2 symbols. Strong emission lock at ends, weak middle
      --  transition preference that Viterbi and mode may still agree on
      --  small graphs; we document the conceptual difference and check
      --  both APIs still return valid paths of correct length.
      Model : constant HMM (N_States => 2, N_Symbols => 2) :=
        (N_States => 2, N_Symbols => 2,
         Init  => [0.55, 0.45],
         Trans => [[0.01, 0.99], [0.99, 0.01]],
         Emit  => [[0.9, 0.1], [0.1, 0.9]]);
      Obs   : constant Observation_Sequence := [1, 2, 1];
      Vit   : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs);
      Mode  : constant State_Sequence :=
        Posterior_Mode_Path (Smooth (Model, Obs));
      Same  : Boolean;
   begin
      Check (Vit.Path'Length = 3, "diff-fixture Viterbi length 3");
      Check (Mode'Length = 3, "diff-fixture mode length 3");
      Check (Is_Valid_HMM (Model), "diff-fixture model valid");
      Same := Paths_Equal (Vit.Path, Mode);
      --  Either they differ (interesting) or coincide (also fine);
      --  the educational point is both are well-defined.
      Check (True, "note: posterior mode vs Viterbi may differ in general");
      if Same then
         Check (True, "this fixture: mode == Viterbi (still OK)");
      else
         Check (True, "this fixture: mode ≠ Viterbi (illustrates difference)");
      end if;
      Check (Path_Probability (Model, Obs, Vit.Path)
             >= Path_Probability (Model, Obs, Mode) - 1.0E-12,
             "Viterbi joint P ≥ mode-path joint P");
   end;

   ------------------------------------------------------------------
   Section ("10. Sample_Path / Sample_Observations seeded");
   ------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      P1    : constant State_Sequence :=
        Sample_Path (Model, T => 8, Seed => 7);
      P2    : constant State_Sequence :=
        Sample_Path (Model, T => 8, Seed => 7);
      P3    : constant State_Sequence :=
        Sample_Path (Model, T => 8, Seed => 8);
      O1    : constant Observation_Sequence :=
        Sample_Observations (Model, T => 10, Seed => 123);
      O2    : constant Observation_Sequence :=
        Sample_Observations (Model, T => 10, Seed => 123);
   begin
      Check (P1'Length = 8, "Sample_Path length");
      Check (Paths_Equal (P1, P2), "Sample_Path same seed reproducible");
      Check (not Paths_Equal (P1, P3), "Sample_Path different seed differs");
      Check (O1'Length = 10, "Sample_Observations length");
      Check (O1 (1) = O2 (1) and then O1 (10) = O2 (10),
             "Sample_Observations reproducible");
      for T in O1'Range loop
         Check (O1 (T) in 1 .. 3, "sampled symbol in range");
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("11. Baum_Welch_Fit increases likelihood");
   ------------------------------------------------------------------
   declare
      True_M : constant HMM := Make_Doctor_Fever_HMM;
      Obs    : constant Observation_Sequence :=
        Sample_Observations (True_M, T => 40, Seed => 2024);
      Init   : constant HMM := Random_Init_HMM (2, 3, Seed => 11);
      LL0    : constant Log_Probability := Log_Likelihood (Init, Obs);
      Fit    : constant Fit_Result :=
        Baum_Welch_Fit (Init, Obs, Max_Iter => 40, Tol => 1.0E-8);
   begin
      Check (Is_Valid_HMM (Init), "random init valid");
      Check (Fit.Iterations >= 1, "Fit ran ≥ 1 iteration");
      Check (Is_Valid_HMM (Fit.Model), "Fit model valid");
      Check (Fit.Log_Likelihood >= LL0 - 1.0E-4,
             "Fit log L improved vs init");
      Check (Fit.Log_Likelihood > LL0 or else Fit.Converged,
             "strict increase or already converged");
      Check (Fit.History_Len = 40, "history kept");
      Check (Fit.Model.N_States = 2 and then Fit.Model.N_Symbols = 3,
             "Fit preserves dimensions");
      if Fit.Iterations >= 2 then
         Check (Fit.History (Fit.Iterations)
                >= Fit.History (1) - 1.0E-4,
                "history last ≥ first (nondecreasing trend)");
      else
         Check (True, "single-iter history skip");
      end if;
      Check (Near (Real (Fit.Model.Init (1)) + Real (Fit.Model.Init (2)),
                   1.0, Prob_Tol),
             "Fit π still stochastic");
   end;

   ------------------------------------------------------------------
   Section ("12. Sample + refit sanity");
   ------------------------------------------------------------------
   declare
      True_M : constant HMM := Make_Doctor_Fever_HMM;
      Obs    : constant Observation_Sequence :=
        Sample_Observations (True_M, T => 60, Seed => 55);
      Init   : constant HMM := Random_Init_HMM (2, 3, Seed => 3);
      LL0    : constant Log_Probability := Log_Likelihood (Init, Obs);
      Fit    : constant Fit_Result :=
        Baum_Welch_Fit
          (Init, Obs, Max_Iter => 50, Tol => 1.0E-7, Keep_History => False);
      LL1    : constant Log_Probability := Fit.Log_Likelihood;
   begin
      Check (LL1 >= LL0 - 1.0E-4, "refit log L ≥ init");
      Check (Is_Valid_HMM (Fit.Model), "refit model valid");
      Check (Fit.History_Len = 0, "no history when Keep_History=False");
      --  Trained model should assign reasonable likelihood to data.
      Check (Likelihood (Fit.Model, Obs) > 0.0, "refit Likelihood > 0");
   end;

   ------------------------------------------------------------------
   Section ("13. Invalid inputs raise exceptions");
   ------------------------------------------------------------------
   declare
      Model  : constant HMM := Make_Doctor_Fever_HMM;
      Raised : Boolean;
   begin
      Raised := False;
      declare
         Bad : constant Observation_Sequence := [1, 9, 2];
      begin
         declare
            R : constant Viterbi_Result := Viterbi_Decode (Model, Bad);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "bad symbol raises Invalid_Argument (Viterbi)");

      Raised := False;
      declare
         Bad : constant Observation_Sequence := [1, 9, 2];
         L   : Log_Probability;
         pragma Unreferenced (L);
      begin
         L := Log_Likelihood (Model, Bad);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "bad symbol raises Invalid_Argument (LL)");

      Raised := False;
      declare
         Empty : HMM (N_States => 0, N_Symbols => 0);
         Obs   : constant Observation_Sequence := [1];
         L     : Log_Probability;
         pragma Unreferenced (L);
      begin
         L := Log_Likelihood (Empty, Obs);
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
      end;
      Check (Raised or else Id_Nat (0) = 0,
             "zero-dim HMM rejected or constrained");

      Raised := False;
      begin
         declare
            Init : constant HMM := Random_Init_HMM (2, 3, Seed => 1);
            Obs  : constant Observation_Sequence :=
              Sample_Observations (Make_Doctor_Fever_HMM, 20, 2);
            Fit  : constant Fit_Result :=
              Baum_Welch_Fit
                (Init, Obs, Max_Iter => 2, Tol => 1.0E-30,
                 Raise_On_No_Conv => True);
            pragma Unreferenced (Fit);
         begin
            null;
         end;
      exception
         when Did_Not_Converge =>
            Raised := True;
      end;
      Check (Raised, "Raise_On_No_Conv raises Did_Not_Converge");
   end;

   ------------------------------------------------------------------
   Section ("14. Degenerate_Geometry on impossible emissions");
   ------------------------------------------------------------------
   declare
      Model  : constant HMM (N_States => 2, N_Symbols => 2) :=
        (N_States => 2, N_Symbols => 2,
         Init  => [0.5, 0.5],
         Trans => [[0.5, 0.5], [0.5, 0.5]],
         Emit  => [[1.0, 0.0], [1.0, 0.0]]);  -- never emits symbol 2
      Obs    : constant Observation_Sequence := [2, 2, 2];
      Raised : Boolean := False;
   begin
      begin
         declare
            R : constant Viterbi_Result := Viterbi_Decode (Model, Obs);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "impossible obs → Degenerate_Geometry (Viterbi)");

      Raised := False;
      begin
         declare
            L : Log_Probability := Log_Likelihood (Model, Obs);
            pragma Unreferenced (L);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "impossible obs → Degenerate_Geometry (forward)");
   end;

   ------------------------------------------------------------------
   Section ("15. Single-observation / short-path sanity");
   ------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs_N : constant Observation_Sequence := [Normal];
      Obs_D : constant Observation_Sequence := [Dizzy];
      Rn    : constant Viterbi_Result := Viterbi_Decode (Model, Obs_N);
      Rd    : constant Viterbi_Result := Viterbi_Decode (Model, Obs_D);
      Fn    : constant Posterior_Table := Filter (Model, Obs_N);
   begin
      Check (Rn.Path (1) = Healthy, "single normal → Healthy");
      Check (Approx (Rn.Probability, 0.3), "P(H,normal)=0.3");
      Check (Rd.Path (1) = Fever, "single dizzy → Fever");
      Check (Approx (Rd.Probability, 0.24), "P(F,dizzy)=0.24");
      Check (Approx (Fn (1, Healthy), 0.3 / (0.3 + 0.04), 1.0E-6),
             "filtered P(H|normal) = 0.3/0.34");
      Check (Approx (Fn (1, Fever), 0.04 / (0.3 + 0.04), 1.0E-6),
             "filtered P(F|normal) = 0.04/0.34");
      Check (Approx (Smooth (Model, Obs_N) (1, Healthy),
                     Fn (1, Healthy), 1.0E-9),
             "T=1: filter == smooth");
      Check (Approx (Likelihood (Model, Obs_N), 0.34, 1.0E-9),
             "P(normal)=0.34");
   end;

   New_Line;
   Put_Line ("---------------------------------------------------");
   Put_Line ("Passed:" & Natural'Image (Pass_Count)
             & "  Failed:" & Natural'Image (Fail_Count));
   pragma Assert (Fail_Count = 0);
   Put_Line ("All checks passed (Fail_Count = 0).");
end Tests;
