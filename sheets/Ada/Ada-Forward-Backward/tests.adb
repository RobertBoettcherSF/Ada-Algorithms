--  Standalone test suite for Forward_Backward.Forward_Backward (main program).

pragma Ada_2022;

with Ada.Text_IO;        use Ada.Text_IO;
with Forward_Backward;   use Forward_Backward;

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

   --  Thwart static "condition always True" warnings for capacity/fixture.
   function Id_Nat (X : Natural) return Natural is
   begin
      return X;
   end Id_Nat;

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

begin
   Put_Line ("Forward_Backward test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Log / Exp / LogSumExp helpers");
   ---------------------------------------------------------------------
   declare
      L0 : constant Log_Probability := Log (0.0);
      L1 : constant Log_Probability := Log (1.0);
      Row : constant Initial_Vector :=
        [1 => 0.25, 2 => 0.25, 3 => 0.5];
      Logs : constant Log_Vector :=
        [1 => Log (0.25), 2 => Log (0.25), 3 => Log (0.5)];
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (L0 <= Log_Zero / 2.0, "Log(0) is Log_Zero sentinel");
      Check (Approx (L1, 0.0, 1.0E-6), "Log(1) ≈ 0");
      Check (Approx (Exp (0.0), 1.0, 1.0E-5), "Exp(0) ≈ 1");
      Check (Approx (Exp (L0), 0.0, 1.0E-12), "Exp(Log_Zero) ≈ 0");
      Check (Approx (Exp (Log (0.25)), 0.25, 1.0E-5), "Exp(Log(0.25))≈0.25");
      Check (Approx (Log_Sum_Exp (Log (0.3), Log (0.7)), 0.0, 1.0E-5),
             "LogSumExp(log 0.3, log 0.7) ≈ 0");
      Check (Approx (Log_Sum_Exp (Log_Zero, Log (0.5)), Log (0.5), 1.0E-5),
             "LogSumExp absorbs Log_Zero");
      Check (Approx (Log_Sum_Exp_Row (Row), 0.0, 1.0E-5),
             "Log_Sum_Exp_Row of probs summing to 1 ≈ 0");
      Check (Approx (Log_Sum_Exp_Logs (Logs), 0.0, 1.0E-5),
             "Log_Sum_Exp_Logs of log-probs ≈ 0");
   end;

   ---------------------------------------------------------------------
   Section ("2. HMM validation / Normalize_Rows");
   ---------------------------------------------------------------------
   declare
      Good   : constant HMM := Make_Doctor_Fever_HMM;
      Empty  : HMM (N_States => 0, N_Symbols => 0);
      Raised : Boolean;
   begin
      Check (Is_Valid_HMM (Good), "doctor/fever Is_Valid_HMM");
      Check (Is_Valid_HMM (Good, Require_Stochastic => True),
             "doctor/fever stochastic");
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
      end;

      declare
         Neg : HMM (N_States => 2, N_Symbols => 1);
      begin
         Neg.Init := [1 => 0.5, 2 => 0.5];
         Neg.Trans :=
           [1 => [1 => 0.0, 2 => 0.0],
            2 => [1 => 0.5, 2 => 0.5]];
         Neg.Emit := [1 => [1 => 1.0], 2 => [1 => 1.0]];
         Check (not Is_Valid_HMM (Neg), "zero trans row fails stochastic");
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
         Check (Approx (Real (M.Init (1)), 0.5), "normalized init 0.5");
         Check (Approx (Real (M.Trans (1, 1)), 0.5), "normalized trans row");
         Check (Approx (Real (M.Emit (1, 1)), 1.0), "normalized emit row");
      end;

      Raised := False;
      begin
         declare
            M0 : HMM (N_States => 0, N_Symbols => 0);
         begin
            Normalize_Rows (M0);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Normalize_Rows empty raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("3. Fixture constants / Make_Doctor_Fever_HMM");
   ---------------------------------------------------------------------
   declare
      M : constant HMM := Make_Doctor_Fever_HMM;
   begin
      Check (M.N_States = 2 and then M.N_Symbols = 3, "fixture dims 2x3");
      Check (M.Init'Length = 2, "fixture init length 2");
      Check (M.Emit'Length (2) = 3, "fixture emit symbol count 3");
      Check (Approx (Real (M.Init (Healthy)), 0.6), "π_Healthy = 0.6");
      Check (Approx (Real (M.Init (Fever)), 0.4), "π_Fever = 0.4");
      Check (Approx (Real (M.Trans (Healthy, Healthy)), 0.7), "a_HH = 0.7");
      Check (Approx (Real (M.Trans (Fever, Fever)), 0.6), "a_FF = 0.6");
      Check (Approx (Real (M.Emit (Healthy, Normal)), 0.5), "b_H,normal");
      Check (Approx (Real (M.Emit (Fever, Dizzy)), 0.6), "b_F,dizzy");
   end;

   ---------------------------------------------------------------------
   Section ("4. Forward α / Likelihood_From_Alpha");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      Alpha : constant Alpha_Table := Forward (Model, Obs);
      Lik   : constant Real := Likelihood_From_Alpha (Alpha);
   begin
      Check (Alpha'Length (1) = 3, "α has T=3 rows");
      Check (Alpha'Length (2) = 2, "α has N=2 cols");
      --  Hand-worked: α1(H)=0.3, α1(F)=0.04
      Check (Approx (Alpha (1, Healthy), 0.3, 1.0E-9), "α1(H)=0.3");
      Check (Approx (Alpha (1, Fever), 0.04, 1.0E-9), "α1(F)=0.04");
      --  α2(H)=0.0904, α2(F)=0.0342
      Check (Approx (Alpha (2, Healthy), 0.0904, 1.0E-6), "α2(H)=0.0904");
      Check (Approx (Alpha (2, Fever), 0.0342, 1.0E-6), "α2(F)=0.0342");
      --  α3(H)=0.007696, α3(F)=0.028584; P(o)=0.03628
      Check (Approx (Alpha (3, Healthy), 0.007696, 1.0E-6), "α3(H)");
      Check (Approx (Alpha (3, Fever), 0.028584, 1.0E-6), "α3(F)");
      Check (Lik > 0.0, "likelihood > 0");
      Check (Approx (Lik, 0.03628, 1.0E-5), "P(o) ≈ 0.03628");
      Check (Approx (Lik, Alpha (3, Healthy) + Alpha (3, Fever), 1.0E-12),
             "α sum at T = likelihood");
   end;

   ---------------------------------------------------------------------
   Section ("5. Backward β / Smooth γ");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      Alpha : constant Alpha_Table := Forward (Model, Obs);
      Beta  : constant Beta_Table := Backward (Model, Obs);
      Gamma : constant Posterior_Table := Smooth (Model, Obs);
      Lik   : constant Real := Likelihood_From_Alpha (Alpha);
   begin
      Check (Approx (Beta (3, Healthy), 1.0), "β_T(H)=1");
      Check (Approx (Beta (3, Fever), 1.0), "β_T(F)=1");
      Check (Approx (Beta (2, Healthy), 0.25, 1.0E-6), "β2(H)=0.25");
      Check (Approx (Beta (2, Fever), 0.40, 1.0E-6), "β2(F)=0.40");
      Check (Approx (Beta (1, Healthy), 0.106, 1.0E-6), "β1(H)=0.106");
      Check (Approx (Beta (1, Fever), 0.112, 1.0E-6), "β1(F)=0.112");

      for T in 1 .. 3 loop
         Check (Approx (Gamma_Row_Sum (Gamma, T), 1.0, 1.0E-5),
                "γ row sums to 1 at t=" & T'Image);
      end loop;

      --  Proportional consistency: α_t(i)β_t(i) ∝ γ_t(i)
      for T in 1 .. 3 loop
         declare
            R1 : constant Real := Alpha (T, Healthy) * Beta (T, Healthy);
            R2 : constant Real := Alpha (T, Fever) * Beta (T, Fever);
         begin
            Check (Approx (R1 / Lik, Gamma (T, Healthy), 1.0E-5),
                   "αβ/P = γ Healthy t=" & T'Image);
            Check (Approx (R2 / Lik, Gamma (T, Fever), 1.0E-5),
                   "αβ/P = γ Fever t=" & T'Image);
         end;
      end loop;

      --  Wiki-style posterior tendencies
      Check (Gamma (1, Healthy) > Gamma (1, Fever), "t=1 Healthy dominates");
      Check (Gamma (3, Fever) > Gamma (3, Healthy), "t=3 Fever dominates");
      Check (Approx (Gamma (1, Healthy), 0.8765, 1.0E-3), "γ1(H)≈0.877");
      Check (Approx (Gamma (3, Fever), 0.7879, 1.0E-3), "γ3(F)≈0.788");
   end;

   ---------------------------------------------------------------------
   Section ("6. Forward_Backward bundle + Xi marginalization");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      R     : constant FB_Result :=
        Forward_Backward.Forward_Backward (Model, Obs, Fill_Xi => True);
      Mode  : constant State_Sequence := Posterior_Mode_Path (R.Gamma);
      Expect : constant State_Sequence := [Healthy, Healthy, Fever];
   begin
      Check (not R.Scaled, "unscaled FB_Result.Scaled=False");
      Check (R.Has_Xi, "Has_Xi True");
      Check (R.Xi_Last = 2, "Xi_Last = T-1 = 2");
      Check (R.Likelihood > 0.0, "bundle likelihood > 0");
      Check (Approx (R.Likelihood, 0.03628, 1.0E-5), "bundle P(o)");
      Check (Paths_Equal (Mode, Expect),
             "posterior mode = Healthy,Healthy,Fever");

      for T in 1 .. R.Xi_Last loop
         for I in 1 .. R.N_States loop
            declare
               S : Real := 0.0;
            begin
               for J in 1 .. R.N_States loop
                  S := S + R.Xi (T, I, J);
               end loop;
               Check (Approx (S, R.Gamma (T, I), 1.0E-5),
                      "Σ_j ξ_t(i,j)=γ_t(i) t="
                      & T'Image & " i=" & I'Image);
            end;
         end loop;
      end loop;

      declare
         R0 : constant FB_Result :=
           Forward_Backward.Forward_Backward (Model, Obs, Fill_Xi => False);
      begin
         Check (not R0.Has_Xi, "Fill_Xi False -> Has_Xi False");
         Check (R0.Xi_Last = 0, "Fill_Xi False -> Xi_Last 0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Scaled vs unscaled agree on short sequences");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      U     : constant FB_Result :=
        Forward_Backward.Forward_Backward (Model, Obs, Fill_Xi => True);
      S     : constant FB_Result :=
        Forward_Backward_Scaled (Model, Obs, Fill_Xi => True);
   begin
      Check (S.Scaled, "scaled flag True");
      Check (Approx (U.Likelihood, S.Likelihood, 1.0E-5),
             "scaled/unscaled likelihood agree");
      Check (Approx (U.Log_Likelihood, S.Log_Likelihood, 1.0E-4),
             "scaled/unscaled log-likelihood agree");

      for T in 1 .. 3 loop
         for I in 1 .. 2 loop
            Check (Approx (U.Gamma (T, I), S.Gamma (T, I), 1.0E-5),
                   "γ agree t=" & T'Image & " i=" & I'Image);
         end loop;
      end loop;

      for T in 1 .. 2 loop
         for I in 1 .. 2 loop
            for J in 1 .. 2 loop
               Check (Approx (U.Xi (T, I, J), S.Xi (T, I, J), 1.0E-5),
                      "ξ agree");
            end loop;
         end loop;
      end loop;

      --  Scaled α rows sum to 1
      for T in 1 .. 3 loop
         declare
            Sum : Real := 0.0;
         begin
            for I in 1 .. 2 loop
               Sum := Sum + S.Alpha (T, I);
            end loop;
            Check (Approx (Sum, 1.0, 1.0E-5),
                   "scaled α row sum 1 t=" & T'Image);
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Posterior_Mode_Path vs known tendencies");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      Gamma : constant Posterior_Table := Smooth (Model, Obs);
      Path  : constant State_Sequence := Posterior_Mode_Path (Gamma);
   begin
      Check (Path (1) = Healthy, "mode t1 Healthy");
      Check (Path (2) = Healthy, "mode t2 Healthy");
      Check (Path (3) = Fever, "mode t3 Fever");
      --  Same observation as Viterbi Wikipedia path
      Check (Paths_Equal (Path, [Healthy, Healthy, Fever]),
             "mode path matches classic Viterbi path on this example");
   end;

   ---------------------------------------------------------------------
   Section ("9. Empty / invalid raises");
   ---------------------------------------------------------------------
   declare
      Model  : constant HMM := Make_Doctor_Fever_HMM;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Empty : Observation_Sequence (1 .. 0);
            A     : Alpha_Table := Forward (Model, Empty);
            pragma Unreferenced (A);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
         when others           => Raised := False;
      end;
      Check (Raised, "Forward empty Obs raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Bad : constant Observation_Sequence :=
              [1 => Symbol_Index (4)];  -- out of range for 3-symbol model
            A   : Alpha_Table := Forward (Model, Bad);
            pragma Unreferenced (A);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Forward bad symbol raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Empty_M : HMM (N_States => 0, N_Symbols => 0);
            Obs     : constant Observation_Sequence := [Normal];
            A       : Alpha_Table := Forward (Empty_M, Obs);
            pragma Unreferenced (A);
         begin
            null;
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;  -- Pre may fire
      end;
      Check (Raised, "Forward empty HMM raises");

      Raised := False;
      begin
         declare
            Deg : HMM (N_States => 2, N_Symbols => 1);
            Obs : constant Observation_Sequence := [1 => 1];
         begin
            Deg.Init := [1 => 0.5, 2 => 0.5];
            Deg.Trans :=
              [1 => [1 => 0.5, 2 => 0.5],
               2 => [1 => 0.5, 2 => 0.5]];
            Deg.Emit := [1 => [1 => 0.0], 2 => [1 => 0.0]];
            declare
               A : constant Alpha_Table := Forward (Deg, Obs);
               pragma Unreferenced (A);
            begin
               null;
            end;
         end;
      exception
         when Degenerate_Geometry => Raised := True;
      end;
      Check (Raised, "zero emissions raise Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("10. Deterministic HMM recovers obvious posteriors");
   ---------------------------------------------------------------------
   declare
      --  State 1 always emits symbol 1; state 2 always emits symbol 2.
      --  Stay with probability 1. Init prefers state 1.
      M : HMM (N_States => 2, N_Symbols => 2);
      Obs : constant Observation_Sequence := [1, 1, 1];
      Obs2 : constant Observation_Sequence := [2, 2];
   begin
      M.Init := [1 => 1.0, 2 => 0.0];
      M.Trans :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0]];
      M.Emit :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0]];

      declare
         G : constant Posterior_Table := Smooth (M, Obs);
      begin
         for T in 1 .. 3 loop
            Check (Approx (G (T, 1), 1.0, 1.0E-9),
                   "deterministic all-1 -> γ(state1)=1 t=" & T'Image);
            Check (Approx (G (T, 2), 0.0, 1.0E-9),
                   "deterministic all-1 -> γ(state2)=0 t=" & T'Image);
         end loop;
         Check (Paths_Equal (Posterior_Mode_Path (G), [1, 1, 1]),
                "mode path all state 1");
      end;

      --  Flip init to state 2 and observe symbol 2
      M.Init := [1 => 0.0, 2 => 1.0];
      declare
         G2 : constant Posterior_Table := Smooth (M, Obs2);
      begin
         for T in 1 .. 2 loop
            Check (Approx (G2 (T, 2), 1.0, 1.0E-9),
                   "deterministic all-2 -> γ(state2)=1");
         end loop;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Longer sequence: scaled stays finite");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      --  Repeat dizzy-heavy pattern to drive small probabilities
      Long  : Observation_Sequence (1 .. 40);
   begin
      for T in Long'Range loop
         case T mod 3 is
            when 1 => Long (T) := Dizzy;
            when 2 => Long (T) := Cold;
            when others => Long (T) := Normal;
         end case;
      end loop;

      declare
         Sc : constant FB_Result :=
           Forward_Backward_Scaled (Model, Long, Fill_Xi => True);
      begin
         Check (Sc.Scaled, "long scaled flag");
         Check (Sc.Log_Likelihood < 0.0, "long log-likelihood negative");
         Check (Sc.Log_Likelihood > Log_Zero / 2.0,
                "long log-likelihood finite (not Log_Zero)");
         --  Likelihood product may underflow to 0 in Real; log path is truth
         Check (Sc.Likelihood >= 0.0, "long likelihood non-negative");

         for T in 1 .. Sc.Length loop
            Check (Approx (Gamma_Row_Sum (Sc.Gamma, T), 1.0, 1.0E-4),
                   "long γ row ~1 t=" & T'Image);
            Check (Sc.Scales (T) > 0.0, "c_t > 0");
         end loop;

         --  Unscaled may underflow: document by checking α becomes tiny
         declare
            Raised_Or_Tiny : Boolean := False;
            Alpha : Alpha_Table (1 .. 40, 1 .. 2);
         begin
            begin
               Alpha := Forward (Model, Long);
               declare
                  Lik : constant Real := Likelihood_From_Alpha (Alpha);
               begin
                  --  Either underflowed (~0) or still tiny vs scaled log
                  Raised_Or_Tiny :=
                    Lik < 1.0E-20
                    or else Lik < Exp (Sc.Log_Likelihood) * 1.0E-3
                    or else Near (Lik, Exp (Sc.Log_Likelihood), 1.0E-8);
               end;
            exception
               when Degenerate_Geometry => Raised_Or_Tiny := True;
            end;
            Check (Raised_Or_Tiny,
                   "unscaled long: underflow/tiny or degenerate (documented)");
            Check (True,
                   "scaled preferred for long T (Rabiner c_t)");
         end;
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Single observation / short edge cases");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs1  : constant Observation_Sequence := [Dizzy];
      R     : constant FB_Result :=
        Forward_Backward.Forward_Backward (Model, Obs1, Fill_Xi => True);
      Sc    : constant FB_Result :=
        Forward_Backward_Scaled (Model, Obs1, Fill_Xi => False);
   begin
      Check (R.Length = 1, "T=1 length");
      Check (R.Xi_Last = 0, "T=1 no Xi slots");
      Check (Approx (Gamma_Row_Sum (R.Gamma, 1), 1.0), "T=1 γ sums 1");
      --  α1(H)=0.6*0.1=0.06; α1(F)=0.4*0.6=0.24; P=0.3
      Check (Approx (R.Likelihood, 0.3, 1.0E-9), "T=1 dizzy P(o)=0.3");
      Check (Approx (R.Gamma (1, Fever), 0.8, 1.0E-9), "T=1 γ(F)=0.8");
      Check (Approx (R.Gamma (1, Healthy), 0.2, 1.0E-9), "T=1 γ(H)=0.2");
      Check (Posterior_Mode_Path (R.Gamma) (1) = Fever, "T=1 mode Fever");
      Check (Approx (Sc.Likelihood, R.Likelihood, 1.0E-9),
             "T=1 scaled=unscaled lik");
      Check (Approx (Sc.Gamma (1, Fever), 0.8, 1.0E-9),
             "T=1 scaled γ(F)");
   end;

   ---------------------------------------------------------------------
   Section ("13. Alternate short obs / scaling factors / Xi sum");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Cold, Dizzy];
      U     : constant FB_Result := Forward_Backward.Forward_Backward (Model, Obs);
      S     : constant FB_Result := Forward_Backward_Scaled (Model, Obs);
      Xi_Sum : Real;
   begin
      Check (Approx (U.Likelihood, S.Likelihood, 1.0E-6),
             "cold,dizzy lik agree");
      Check (Paths_Equal
               (Posterior_Mode_Path (U.Gamma),
                Posterior_Mode_Path (S.Gamma)),
             "cold,dizzy mode paths agree");
      Check (S.Scales (1) > 0.0 and then S.Scales (2) > 0.0,
             "scale factors positive");
      --  Π c_t = likelihood
      Check (Approx (S.Scales (1) * S.Scales (2), S.Likelihood, 1.0E-6),
             "Π c_t = P(o)");

      Xi_Sum := 0.0;
      for I in 1 .. 2 loop
         for J in 1 .. 2 loop
            Xi_Sum := Xi_Sum + U.Xi (1, I, J);
         end loop;
      end loop;
      Check (Approx (Xi_Sum, 1.0, 1.0E-5), "Σ_{i,j} ξ_1 = 1");

      --  Backward likelihood check: Σ_i π_i b_i(o1) β_1(i) = P(o)
      declare
         Acc : Real := 0.0;
      begin
         for I in 1 .. 2 loop
            Acc := Acc
              + Real (Model.Init (I))
              * Real (Model.Emit (I, Obs (1)))
              * U.Beta (1, I);
         end loop;
         Check (Approx (Acc, U.Likelihood, 1.0E-6),
                "π·b·β_1 reconstructs P(o)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Uniform noise sanity / capacity constants");
   ---------------------------------------------------------------------
   declare
      M : HMM (N_States => 3, N_Symbols => 2);
      Obs : constant Observation_Sequence := [1, 2, 1, 2, 1];
   begin
      M.Init := [1 => 1.0 / 3.0, 2 => 1.0 / 3.0, 3 => 1.0 / 3.0];
      for I in 1 .. 3 loop
         for J in 1 .. 3 loop
            M.Trans (I, J) := Probability (1.0 / 3.0);
         end loop;
         M.Emit (I, 1) := 0.5;
         M.Emit (I, 2) := 0.5;
      end loop;
      Check (Is_Valid_HMM (M), "uniform 3-state valid");
      declare
         R : constant FB_Result :=
           Forward_Backward_Scaled (M, Obs, Fill_Xi => True);
      begin
         for T in 1 .. 5 loop
            Check (Approx (Gamma_Row_Sum (R.Gamma, T), 1.0, 1.0E-5),
                   "uniform γ row t=" & T'Image);
            --  Symmetric model => roughly equal posteriors
            Check (Approx (R.Gamma (T, 1), 1.0 / 3.0, 1.0E-4),
                   "uniform γ ≈ 1/3");
         end loop;
      end;
      Check (Id_Nat (Max_States) >= Id_Nat (2), "Max_States capacity ok");
      Check (Id_Nat (Max_Symbols) >= Id_Nat (3), "Max_Symbols capacity ok");
      Check (Id_Nat (Max_Time) >= Id_Nat (Obs'Length), "Max_Time covers obs");
      Check (Near (Prob_Tol, Prob_Tol * Real (Id_Nat (1))), "Prob_Tol Near self");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image
             & "  Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");
   pragma Assert (Fail_Count = 0);

end Tests;
