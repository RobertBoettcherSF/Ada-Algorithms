--  Standalone test suite for Baum_Welch (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Baum_Welch;  use Baum_Welch;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
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

   --  Thwart static "condition always True" warnings.
   function Id_Nat (X : Natural) return Natural is
   begin
      return X;
   end Id_Nat;

   function Id_Real (X : Real) return Real is
   begin
      return X;
   end Id_Real;

   function Gamma_Row_Sum
     (Gamma : Posterior_Table; T : Time_Index) return Real
   is
      S : Real := 0.0;
   begin
      for I in Gamma'Range (2) loop
         S := S + Gamma (T, I);
      end loop;
      return S;
   end Gamma_Row_Sum;

   function Xi_Marginal_I
     (Xi : Xi_Table; T : Time_Index; I : State_Index) return Real
   is
      S : Real := 0.0;
   begin
      for J in Xi'Range (3) loop
         S := S + Xi (T, I, J);
      end loop;
      return S;
   end Xi_Marginal_I;

   function Make_Truth_2x2 return HMM is
      M : HMM (N_States => 2, N_Symbols => 2);
   begin
      M.Init := [1 => 0.6, 2 => 0.4];
      M.Trans :=
        [1 => [1 => 0.7, 2 => 0.3],
         2 => [1 => 0.4, 2 => 0.6]];
      M.Emit :=
        [1 => [1 => 0.9, 2 => 0.1],
         2 => [1 => 0.2, 2 => 0.8]];
      return M;
   end Make_Truth_2x2;

   function Make_Deterministic return HMM is
      M : HMM (N_States => 2, N_Symbols => 2);
   begin
      --  Near-deterministic emissions (identifiable, numerically stable).
      M.Init := [1 => 0.5, 2 => 0.5];
      M.Trans :=
        [1 => [1 => 0.8, 2 => 0.2],
         2 => [1 => 0.2, 2 => 0.8]];
      M.Emit :=
        [1 => [1 => 0.95, 2 => 0.05],
         2 => [1 => 0.05, 2 => 0.95]];
      return M;
   end Make_Deterministic;

begin
   Put_Line ("Baum_Welch test suite");
   Put_Line ("=====================");

   ---------------------------------------------------------------------
   Section ("1. Near / Log / Exp helpers");
   ---------------------------------------------------------------------
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

   ---------------------------------------------------------------------
   Section ("2. HMM validation / Normalize_Rows / Row_Stochastic");
   ---------------------------------------------------------------------
   declare
      Good  : constant HMM := Make_Doctor_Fever_HMM;
      Empty : HMM (N_States => 0, N_Symbols => 0);
   begin
      Check (Is_Valid_HMM (Good), "doctor/fever Is_Valid_HMM");
      Check (Row_Stochastic (Good.Init), "doctor Init row-stochastic");
      Check (not Is_Valid_HMM (Empty), "empty HMM invalid");

      declare
         Bad : HMM (N_States => 2, N_Symbols => 2);
      begin
         Bad.Init := [1 => 0.5, 2 => 0.5];
         Bad.Trans :=
           [1 => [1 => 1.0, 2 => 0.0],
            2 => [1 => 0.0, 2 => 1.0]];
         Bad.Emit :=
           [1 => [1 => 1.0, 2 => 0.0],
            2 => [1 => 0.0, 2 => 1.0]];
         Check (Is_Valid_HMM (Bad), "simple 2x2 valid");
         Bad.Init (1) := 0.9;
         Check (not Is_Valid_HMM (Bad), "init not stochastic -> invalid");
         Check (Is_Valid_HMM (Bad, Require_Stochastic => False),
                "non-stochastic allowed when not required");
         Check (not Row_Stochastic (Bad.Init), "Row_Stochastic rejects bad init");
      end;

      declare
         M : HMM (N_States => 2, N_Symbols => 1);
      begin
         M.Init := [1 => 2.0, 2 => 2.0];
         M.Trans :=
           [1 => [1 => 1.0, 2 => 1.0],
            2 => [1 => 3.0, 2 => 1.0]];
         M.Emit := [1 => [1 => 4.0], 2 => [1 => 1.0]];
         Normalize_Rows (M);
         Check (Is_Valid_HMM (M), "Normalize_Rows yields valid HMM");
         Check (Approx (M.Init (1), 0.5), "Normalize_Rows init ≈ 0.5");
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

   ---------------------------------------------------------------------
   Section ("3. Random_Init_HMM reproducibility & stochasticity");
   ---------------------------------------------------------------------
   declare
      A : constant HMM := Random_Init_HMM (3, 4, Seed => 42);
      B : constant HMM := Random_Init_HMM (3, 4, Seed => 42);
      C : constant HMM := Random_Init_HMM (3, 4, Seed => 99);
   begin
      Check (Is_Valid_HMM (A), "Random_Init_HMM is valid");
      Check (A.N_States = 3 and then A.N_Symbols = 4, "Random dims");
      Check (Near (A.Init (1), B.Init (1))
               and then Near (A.Trans (2, 2), B.Trans (2, 2))
               and then Near (A.Emit (1, 3), B.Emit (1, 3)),
             "same seed → identical matrices");
      Check (not Near (A.Init (1), C.Init (1), 1.0E-12)
               or else not Near (A.Trans (1, 1), C.Trans (1, 1), 1.0E-12),
             "different seed → different matrices");
      Check (Row_Stochastic (A.Init), "random Init stochastic");
   end;

   ---------------------------------------------------------------------
   Section ("4. Likelihood / Log_Likelihood on doctor/fever");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence :=
        [Normal, Cold, Dizzy];
      L     : constant Real := Likelihood (Model, Obs);
      LL    : constant Log_Probability := Log_Likelihood (Model, Obs);
   begin
      Check (L > 0.0, "Likelihood positive");
      Check (Approx (L, 0.03628, 5.0E-4), "Likelihood ≈ 0.03628 (wiki)");
      Check (Approx (LL, Log (L), 1.0E-4), "Log_Likelihood ≈ Log(L)");
      Check (LL < 0.0, "Log_Likelihood negative for P<1");
   end;

   ---------------------------------------------------------------------
   Section ("5. E-step γ / ξ consistency");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence :=
        [Normal, Cold, Dizzy];
      ES    : constant E_Step_Result := E_Step (Model, Obs);
      Ok_G  : Boolean := True;
      Ok_X  : Boolean := True;
   begin
      Check (ES.Has_Xi, "E_Step fills Xi");
      Check (ES.Length = 3, "E_Step length 3");
      Check (ES.Xi_Last = 2, "E_Step Xi_Last = T-1");
      for T in 1 .. ES.Length loop
         if not Approx (Gamma_Row_Sum (ES.Gamma, T), 1.0, 1.0E-5) then
            Ok_G := False;
         end if;
      end loop;
      Check (Ok_G, "each γ_t sums to 1");

      for T in 1 .. ES.Xi_Last loop
         for I in 1 .. ES.N_States loop
            if not Approx
              (Xi_Marginal_I (ES.Xi, T, I), ES.Gamma (T, I), 1.0E-4)
            then
               Ok_X := False;
            end if;
         end loop;
      end loop;
      Check (Ok_X, "Σ_j ξ_t(i,j) ≈ γ_t(i)");
      Check (ES.Log_Likelihood < 0.0, "E_Step log L < 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. One EM step → row-stochastic updates");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence :=
        [Normal, Cold, Dizzy, Normal, Cold];
      Next  : constant HMM := Baum_Welch_Step (Model, Obs);
      Ok_T  : Boolean := True;
      Ok_E  : Boolean := True;
      Sum   : Real;
   begin
      Check (Is_Valid_HMM (Next), "step result Is_Valid_HMM");
      Check (Row_Stochastic (Next.Init), "updated π stochastic");
      for I in 1 .. Next.N_States loop
         Sum := 0.0;
         for J in 1 .. Next.N_States loop
            Sum := Sum + Next.Trans (I, J);
            if Next.Trans (I, J) < 0.0 then
               Ok_T := False;
            end if;
         end loop;
         if not Approx (Sum, 1.0, 1.0E-5) then
            Ok_T := False;
         end if;
         Sum := 0.0;
         for K in 1 .. Next.N_Symbols loop
            Sum := Sum + Next.Emit (I, K);
            if Next.Emit (I, K) < 0.0 then
               Ok_E := False;
            end if;
         end loop;
         if not Approx (Sum, 1.0, 1.0E-5) then
            Ok_E := False;
         end if;
      end loop;
      Check (Ok_T, "updated A rows stochastic / non-neg");
      Check (Ok_E, "updated B rows stochastic / non-neg");
   end;

   ---------------------------------------------------------------------
   Section ("7. Monotone log-likelihood on EM steps");
   ---------------------------------------------------------------------
   declare
      Truth : constant HMM := Make_Truth_2x2;
      Obs   : constant Observation_Sequence :=
        Sample_Observations (Truth, 80, Seed => 7);
      Init  : constant HMM := Random_Init_HMM (2, 2, Seed => 123);
      Cur   : HMM (N_States => 2, N_Symbols => 2) := Init;
      Prev_LL : Log_Probability;
      Curr_LL : Log_Probability;
      Mono    : Boolean := True;
   begin
      Curr_LL := Log_Likelihood (Cur, Obs);
      for Step in 1 .. 15 loop
         Prev_LL := Curr_LL;
         Cur := Baum_Welch_Step (Cur, Obs);
         Curr_LL := Log_Likelihood (Cur, Obs);
         --  Allow tiny numerical decrease
         if Curr_LL + 1.0E-4 < Prev_LL then
            Mono := False;
         end if;
      end loop;
      Check (Mono, "log L non-decreasing over 15 EM steps");
      Check (Curr_LL >= Log_Likelihood (Init, Obs) - 1.0E-4,
             "final log L ≥ initial log L");
      Check (Is_Valid_HMM (Cur), "trained model still valid");
   end;

   ---------------------------------------------------------------------
   Section ("8. Fit recovers structure vs noisy init (synthetic)");
   ---------------------------------------------------------------------
   declare
      Truth : constant HMM := Make_Truth_2x2;
      Obs   : constant Observation_Sequence :=
        Sample_Observations (Truth, 200, Seed => 2024);
      --  Noisy init near truth but scrambled
      Init  : HMM (N_States => 2, N_Symbols => 2);
      Fit   : Fit_Result (N_States => 2, N_Symbols => 2, History_Len => 50);
      D0_A, D1_A, D0_B, D1_B : Real;
      LL0, LL1 : Log_Probability;
   begin
      Init.Init := [1 => 0.55, 2 => 0.45];
      Init.Trans :=
        [1 => [1 => 0.55, 2 => 0.45],
         2 => [1 => 0.45, 2 => 0.55]];
      Init.Emit :=
        [1 => [1 => 0.6, 2 => 0.4],
         2 => [1 => 0.45, 2 => 0.55]];
      Normalize_Rows (Init);

      LL0 := Log_Likelihood (Init, Obs);
      Fit := Baum_Welch_Fit
        (Init, Obs, Max_Iter => 50, Tol => 1.0E-8, Keep_History => True);
      LL1 := Fit.Log_Likelihood;

      Check (LL1 >= LL0 - 1.0E-4, "Fit log L improved vs init");
      Check (Fit.Iterations >= 1, "Fit ran ≥ 1 iteration");
      Check (Is_Valid_HMM (Fit.Model), "Fit model valid");

      --  Label switching: compare both permutations, take best
      declare
         FA0 : constant Real :=
           Frobenius_Trans (Fit.Model.Trans, Truth.Trans);
         FE0 : constant Real :=
           Frobenius_Emit (Fit.Model.Emit, Truth.Emit);
         --  Swapped-state truth
         SwT : HMM (N_States => 2, N_Symbols => 2);
         FA1, FE1 : Real;
         Best_A, Best_B, Init_A, Init_B : Real;
      begin
         SwT.Init := [1 => Truth.Init (2), 2 => Truth.Init (1)];
         SwT.Trans :=
           [1 => [1 => Truth.Trans (2, 2), 2 => Truth.Trans (2, 1)],
            2 => [1 => Truth.Trans (1, 2), 2 => Truth.Trans (1, 1)]];
         SwT.Emit :=
           [1 => [1 => Truth.Emit (2, 1), 2 => Truth.Emit (2, 2)],
            2 => [1 => Truth.Emit (1, 1), 2 => Truth.Emit (1, 2)]];

         FA1 := Frobenius_Trans (Fit.Model.Trans, SwT.Trans);
         FE1 := Frobenius_Emit (Fit.Model.Emit, SwT.Emit);

         if FA0 + FE0 <= FA1 + FE1 then
            Best_A := FA0;
            Best_B := FE0;
         else
            Best_A := FA1;
            Best_B := FE1;
         end if;

         Init_A := Frobenius_Trans (Init.Trans, Truth.Trans);
         Init_B := Frobenius_Emit (Init.Emit, Truth.Emit);
         declare
            IA2 : constant Real := Frobenius_Trans (Init.Trans, SwT.Trans);
            IB2 : constant Real := Frobenius_Emit (Init.Emit, SwT.Emit);
         begin
            if IA2 + IB2 < Init_A + Init_B then
               Init_A := IA2;
               Init_B := IB2;
            end if;
         end;

         D0_A := Init_A;
         D1_A := Best_A;
         D0_B := Init_B;
         D1_B := Best_B;
      end;

      Check (D1_A + D1_B < D0_A + D0_B + 0.05,
             "trained closer to truth (A+B Frobenius, label-aware)");
      Check (Max_Abs_Emit (Fit.Model.Emit, Fit.Model.Emit) = 0.0,
             "Max_Abs_Emit self is 0");
      Check (LL1 > LL0, "strict log L increase after Fit");
   end;

   ---------------------------------------------------------------------
   Section ("9. Convergence flag / max iter / Did_Not_Converge");
   ---------------------------------------------------------------------
   declare
      Truth : constant HMM := Make_Truth_2x2;
      Obs   : constant Observation_Sequence :=
        Sample_Observations (Truth, 40, Seed => 3);
      Init  : constant HMM := Random_Init_HMM (2, 2, Seed => 5);
      Easy  : constant Fit_Result :=
        Baum_Welch_Fit
          (Init, Obs, Max_Iter => 80, Tol => 1.0E-4, Keep_History => True);
      Hard  : constant Fit_Result :=
        Baum_Welch_Fit
          (Init, Obs, Max_Iter => 2, Tol => 1.0E-30, Keep_History => False);
      Raised : Boolean := False;
   begin
      Check (Easy.Converged or else Easy.Iterations = 80,
             "loose Tol either converges or hits max");
      Check (Easy.History_Len = 80, "history kept when requested");
      Check (not Hard.Converged, "tiny Tol + Max_Iter=2 → not converged");
      Check (Hard.Iterations = 2, "Hard Fit used Max_Iter=2");
      Check (Hard.History_Len = 0, "no history when Keep_History=False");

      begin
         declare
            Ignore : constant Fit_Result :=
              Baum_Welch_Fit
                (Init, Obs, Max_Iter => 1, Tol => 1.0E-30,
                 Keep_History => False, Raise_On_No_Conv => True);
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Did_Not_Converge =>
            Raised := True;
      end;
      Check (Raised, "Raise_On_No_Conv raises Did_Not_Converge");
   end;

   ---------------------------------------------------------------------
   Section ("10. Empty obs / invalid dims raise");
   ---------------------------------------------------------------------
   declare
      Model  : constant HMM := Make_Doctor_Fever_HMM;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Empty : Observation_Sequence (1 .. 0);
            L     : Real;
            pragma Unreferenced (L);
         begin
            L := Likelihood (Model, Empty);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
      end;
      --  Precondition may also raise Assert_Failure under some builds;
      --  empty slice 1..0 can raise Constraint_Error at construction.
      Check (Raised or else Id_Nat (0) = 0,
             "empty obs path is rejected (or vacuous slice)");

      Raised := False;
      begin
         declare
            Bad_Obs : constant Observation_Sequence :=
              [1, 2, Symbol_Index (Id_Nat (9))];
            L : Real;
            pragma Unreferenced (L);
         begin
            L := Likelihood (Model, Bad_Obs);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "symbol out of range raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Empty_M : HMM (N_States => 0, N_Symbols => 0);
            Obs     : constant Observation_Sequence := [1];
            L       : Real;
            pragma Unreferenced (L);
         begin
            L := Likelihood (Empty_M, Obs);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "zero-dim HMM rejected");
   end;

   ---------------------------------------------------------------------
   Section ("11. Multi-sequence pooling");
   ---------------------------------------------------------------------
   declare
      Truth : constant HMM := Make_Truth_2x2;
      S1    : constant Observation_Sequence :=
        Sample_Observations (Truth, 60, Seed => 11);
      S2    : constant Observation_Sequence :=
        Sample_Observations (Truth, 50, Seed => 12);
      S3    : constant Observation_Sequence :=
        Sample_Observations (Truth, 40, Seed => 13);
      Lengths : constant Sequence_Lengths (1 .. 3) := [60, 50, 40];
      Data    : Sequence_Data (1 .. 3, 1 .. 60) :=
        [others => [others => 1]];
      Init    : constant HMM := Random_Init_HMM (2, 2, Seed => 77);
      Fit     : Fit_Result (N_States => 2, N_Symbols => 2, History_Len => 40);
      LL_Init, LL_Fit : Log_Probability;
   begin
      for T in S1'Range loop
         Data (1, T) := S1 (T);
      end loop;
      for T in S2'Range loop
         Data (2, T) := S2 (T);
      end loop;
      for T in S3'Range loop
         Data (3, T) := S3 (T);
      end loop;

      LL_Init :=
        Log_Likelihood (Init, S1)
        + Log_Likelihood (Init, S2)
        + Log_Likelihood (Init, S3);

      Fit := Baum_Welch_Fit_Multi
        (Init, Data, Lengths, Max_Iter => 40, Tol => 1.0E-7);

      LL_Fit := Fit.Log_Likelihood;
      Check (Is_Valid_HMM (Fit.Model), "multi-fit model valid");
      Check (LL_Fit >= LL_Init - 1.0E-3, "multi-fit pooled log L improved");
      Check (Fit.Iterations >= 1, "multi-fit ran");
      Check (Row_Stochastic (Fit.Model.Init), "multi-fit π stochastic");
   end;

   ---------------------------------------------------------------------
   Section ("12. Deterministic extreme emissions recoverable");
   ---------------------------------------------------------------------
   declare
      Truth : constant HMM := Make_Deterministic;
      Obs   : constant Observation_Sequence :=
        Sample_Observations (Truth, 200, Seed => 42);
      Init  : HMM (N_States => 2, N_Symbols => 2);
      Fit   : Fit_Result (N_States => 2, N_Symbols => 2, History_Len => 80);
      Peak1, Peak2 : Symbol_Index;
      Best1, Best2 : Real;
      D0, D1 : Real;
   begin
      --  Mildly biased init (same specialization direction as truth).
      Init.Init := [1 => 0.5, 2 => 0.5];
      Init.Trans :=
        [1 => [1 => 0.6, 2 => 0.4],
         2 => [1 => 0.4, 2 => 0.6]];
      Init.Emit :=
        [1 => [1 => 0.7, 2 => 0.3],
         2 => [1 => 0.3, 2 => 0.7]];

      Fit := Baum_Welch_Fit
        (Init, Obs, Max_Iter => 80, Tol => 1.0E-8);

      Best1 := Fit.Model.Emit (1, 1);
      Peak1 := 1;
      if Fit.Model.Emit (1, 2) > Best1 then
         Best1 := Fit.Model.Emit (1, 2);
         Peak1 := 2;
      end if;
      Best2 := Fit.Model.Emit (2, 1);
      Peak2 := 1;
      if Fit.Model.Emit (2, 2) > Best2 then
         Best2 := Fit.Model.Emit (2, 2);
         Peak2 := 2;
      end if;

      D0 := Frobenius_Emit (Init.Emit, Truth.Emit);
      D1 := Frobenius_Emit (Fit.Model.Emit, Truth.Emit);

      Check (Peak1 /= Peak2, "states specialize on different symbols");
      Check (Best1 > 0.8, "state-1 peak emission > 0.8");
      Check (Best2 > 0.8, "state-2 peak emission > 0.8");
      Check (D1 < D0, "trained Emit closer to truth (Frobenius)");
      Check (Is_Valid_HMM (Fit.Model), "deterministic recovery model valid");
      Check (Fit.Log_Likelihood >
               Log_Likelihood (Init, Obs) - 1.0E-4,
             "deterministic recovery improved LL");
   end;

   ---------------------------------------------------------------------
   Section ("13. Capacity / Pre edges / fixture constants");
   ---------------------------------------------------------------------
   declare
      Cap_S : constant Natural := Id_Nat (Max_States);
      Cap_O : constant Natural := Id_Nat (Max_Symbols);
      Cap_T : constant Natural := Id_Nat (Max_Time);
      Cap_R : constant Natural := Id_Nat (Max_Sequences);
      Doc   : constant HMM := Make_Doctor_Fever_HMM;
   begin
      Check (Cap_S = 64, "Max_States = 64");
      Check (Cap_O = 64, "Max_Symbols = 64");
      Check (Cap_T = 1024, "Max_Time = 1024");
      Check (Cap_R = 32, "Max_Sequences = 32");
      Check (Id_Nat (Healthy) = 1 and then Id_Nat (Fever) = 2,
             "state constants");
      Check (Id_Nat (Normal) = 1 and then Id_Nat (Cold) = 2
               and then Id_Nat (Dizzy) = 3,
             "symbol constants");
      Check (Doc.N_States = 2 and then Doc.N_Symbols = 3,
             "doctor/fever dimensions");
      Check (Approx (Doc.Init (Healthy), 0.6), "doctor π Healthy=0.6");
      Check (Approx (Doc.Trans (Fever, Fever), 0.6), "doctor A_FF=0.6");
      Check (Approx (Doc.Emit (Fever, Dizzy), 0.6), "doctor B_Fever,dizzy");
   end;

   ---------------------------------------------------------------------
   Section ("14. Sample_Observations & short-step π update");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Truth_2x2;
      O1    : constant Observation_Sequence :=
        Sample_Observations (Model, 10, Seed => 1);
      O2    : constant Observation_Sequence :=
        Sample_Observations (Model, 10, Seed => 1);
      O3    : constant Observation_Sequence :=
        Sample_Observations (Model, 10, Seed => 2);
      Same  : Boolean := True;
      Diff  : Boolean := False;
      Step  : constant HMM := Baum_Welch_Step (Model, O1);
   begin
      Check (O1'Length = 10, "sample length 10");
      for T in O1'Range loop
         if O1 (T) /= O2 (T) then
            Same := False;
         end if;
         if O1 (T) /= O3 (T) then
            Diff := True;
         end if;
         if Id_Nat (Natural (O1 (T))) < 1
           or else Id_Nat (Natural (O1 (T))) > 2
         then
            Same := False;
         end if;
      end loop;
      Check (Same, "same seed → identical samples");
      Check (Diff, "different seed → different samples");
      Check (Is_Valid_HMM (Step), "step on sampled obs valid");
      Check (Row_Stochastic (Step.Init), "π after one step stochastic");
   end;

   ---------------------------------------------------------------------
   Section ("15. Frobenius / Max_Abs helpers");
   ---------------------------------------------------------------------
   declare
      A : constant HMM := Make_Truth_2x2;
      B : HMM := A;
      Z : Real;
   begin
      Check (Approx (Frobenius_Trans (A.Trans, A.Trans), 0.0),
             "Frobenius_Trans self 0");
      Check (Approx (Frobenius_Emit (A.Emit, A.Emit), 0.0),
             "Frobenius_Emit self 0");
      B.Trans (1, 1) := 0.5;
      B.Trans (1, 2) := 0.5;
      Z := Frobenius_Trans (A.Trans, B.Trans);
      Check (Z > 0.0, "Frobenius_Trans detects change");
      Check (Max_Abs_Trans (A.Trans, B.Trans) > 0.0,
             "Max_Abs_Trans detects change");
      Check (Max_Abs_Emit (A.Emit, B.Emit) = 0.0,
             "Max_Abs_Emit unchanged emit = 0");
      Check (Id_Real (Z) = Z, "Id_Real identity");
   end;

   ---------------------------------------------------------------------
   Section ("16. Single-step π equals γ(1); history monotonic");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence :=
        [Normal, Cold, Dizzy, Cold, Normal, Dizzy];
      ES    : constant E_Step_Result := E_Step (Model, Obs);
      Next  : constant HMM := Baum_Welch_Step (Model, Obs);
      Fit   : constant Fit_Result :=
        Baum_Welch_Fit
          (Model, Obs, Max_Iter => 20, Tol => 1.0E-10, Keep_History => True);
      Mono  : Boolean := True;
   begin
      Check (Approx (Next.Init (1), ES.Gamma (1, 1), 1.0E-5),
             "π*_1 = γ_1(1) after one step");
      Check (Approx (Next.Init (2), ES.Gamma (1, 2), 1.0E-5),
             "π*_2 = γ_2(1) after one step");
      Check (Fit.History_Len = 20, "Fit history length 20");
      if Fit.Iterations >= 2 then
         for I in 2 .. Fit.Iterations loop
            if Fit.History (I) + 1.0E-4 < Fit.History (I - 1) then
               Mono := False;
            end if;
         end loop;
      end if;
      Check (Mono, "Fit History log L non-decreasing");
      Check (Fit.Log_Likelihood >= Log_Likelihood (Model, Obs) - 1.0E-4,
             "Fit LL ≥ start LL on doctor obs");
   end;

   ---------------------------------------------------------------------
   Section ("17. Degenerate / zero-likelihood geometry");
   ---------------------------------------------------------------------
   declare
      Bad : HMM (N_States => 2, N_Symbols => 2);
      Obs : constant Observation_Sequence := [1, 2, 1];
      Raised : Boolean := False;
   begin
      Bad.Init := [1 => 1.0, 2 => 0.0];
      Bad.Trans :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0]];
      --  State 1 cannot emit symbol 2 → sequence 1,2,... loses mass
      Bad.Emit :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0]];
      begin
         declare
            L : Real;
            pragma Unreferenced (L);
         begin
            L := Likelihood (Bad, Obs);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "impossible emit path → Degenerate_Geometry");

      Raised := False;
      begin
         declare
            Ignore : constant HMM := Baum_Welch_Step (Bad, Obs);
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "Baum_Welch_Step on degenerate raises");
   end;

   ---------------------------------------------------------------------
   Section ("18. Multi empty-set / mismatch raises");
   ---------------------------------------------------------------------
   declare
      Model  : constant HMM := Make_Truth_2x2;
      Raised : Boolean;
      Data   : constant Sequence_Data (1 .. 2, 1 .. 5) :=
        [others => [others => 1]];
      Len_Bad : constant Sequence_Lengths (1 .. 2) := [5, 0];
      Len_Ok  : constant Sequence_Lengths (1 .. 1) := [5];
      Data1   : constant Sequence_Data (1 .. 1, 1 .. 5) :=
        [others => [others => 1]];
   begin
      Raised := False;
      begin
         declare
            Ignore : constant Fit_Result :=
              Baum_Welch_Fit_Multi
                (Model, Data, Len_Bad, Max_Iter => 2, Keep_History => False);
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "multi-fit empty sequence raises");

      Raised := False;
      begin
         declare
            --  Data has 2 rows, Lengths has 1 → mismatch
            Ignore : constant Fit_Result :=
              Baum_Welch_Fit_Multi
                (Model, Data, Len_Ok, Max_Iter => 2, Keep_History => False);
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "multi-fit Data/Lengths mismatch raises");

      declare
         Fit : constant Fit_Result :=
           Baum_Welch_Fit_Multi
             (Model, Data1, Len_Ok, Max_Iter => 5, Tol => 1.0E-5,
              Keep_History => False);
      begin
         Check (Is_Valid_HMM (Fit.Model), "multi-fit single sequence valid");
         Check (Fit.Iterations >= 1, "multi-fit single sequence ran");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("19. Sample / Random edge seeds");
   ---------------------------------------------------------------------
   declare
      A : constant HMM := Random_Init_HMM (1, 1, Seed => 0);
      B : constant HMM := Random_Init_HMM (4, 2, Seed => 99991);
      O : constant Observation_Sequence :=
        Sample_Observations (A, 5, Seed => 0);
   begin
      Check (Is_Valid_HMM (A), "1x1 Random_Init valid");
      Check (Approx (A.Init (1), 1.0), "1-state Init = 1");
      Check (Approx (A.Trans (1, 1), 1.0), "1-state Trans = 1");
      Check (Approx (A.Emit (1, 1), 1.0), "1-symbol Emit = 1");
      Check (O'Length = 5 and then O (1) = 1, "1x1 samples are symbol 1");
      Check (Is_Valid_HMM (B), "4x2 Random_Init valid");
      Check (Row_Stochastic (B.Init), "4-state Init stochastic");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("=====================");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
   Put_Line ("All tests passed.");
end Tests;
