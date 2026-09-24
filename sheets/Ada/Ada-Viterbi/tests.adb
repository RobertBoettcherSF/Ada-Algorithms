--  Standalone test suite for Viterbi (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Viterbi;     use Viterbi;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
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

begin
   Put_Line ("Viterbi test suite");
   Put_Line ("==================");

   ---------------------------------------------------------------------
   Section ("1. Near / Log / Exp helpers");
   ---------------------------------------------------------------------
   declare
      L0 : constant Log_Probability := Log (0.0);
      L1 : constant Log_Probability := Log (1.0);
      LE : constant Log_Probability := Log (2.718281828);
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (L0 <= Log_Zero / 2.0, "Log(0) is Log_Zero sentinel");
      Check (Approx (L1, 0.0, 1.0E-6), "Log(1) ≈ 0");
      Check (Approx (Exp (0.0), 1.0, 1.0E-5), "Exp(0) ≈ 1");
      Check (Approx (Exp (L0), 0.0, 1.0E-12), "Exp(Log_Zero) ≈ 0");
      Check (Approx (Exp (LE), 2.718281828, 1.0E-4), "Exp(Log(e)) ≈ e");
      Check (Approx (Exp (Log (0.25)), 0.25, 1.0E-5), "Exp(Log(0.25))≈0.25");
      Check (Near (Log (0.5), Log (0.5)), "Log idempotent Near");
   end;

   ---------------------------------------------------------------------
   Section ("2. HMM validation / Normalize_Rows");
   ---------------------------------------------------------------------
   declare
      Good   : constant HMM := Make_Doctor_Fever_HMM;
      Bad    : HMM (N_States => 2, N_Symbols => 2);
      Empty  : HMM (N_States => 0, N_Symbols => 0);
      Raised : Boolean;
   begin
      Check (Is_Valid_HMM (Good), "doctor/fever Is_Valid_HMM");
      Check (Is_Valid_HMM (Good, Require_Stochastic => True),
             "doctor/fever stochastic");
      Check (not Is_Valid_HMM (Empty), "empty HMM invalid");

      Bad.Init := [1 => 0.5, 2 => 0.5];
      Bad.Trans :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0]];
      Bad.Emit :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0]];
      Check (Is_Valid_HMM (Bad), "simple 2x2 valid");

      Bad.Init (1) := 0.9;  -- no longer sums to 1
      Check (not Is_Valid_HMM (Bad), "init not stochastic -> invalid");
      Check (Is_Valid_HMM (Bad, Require_Stochastic => False),
             "non-stochastic allowed when not required");

      Bad.Init (1) := 0.0;
      --  Use a negative via unchecked path: set through Real cast assignment
      --  Non_Negative range starts at 0, so simulate invalid by zeroing both
      --  and checking Require_Stochastic False still rejects empty support
      --  separately; for negative, build with Trans negative via subtype.
      declare
         Neg : HMM (N_States => 2, N_Symbols => 1);
      begin
         Neg.Init := [1 => 0.5, 2 => 0.5];
         Neg.Trans :=
           [1 => [1 => 0.5, 2 => 0.5],
            2 => [1 => 0.5, 2 => 0.5]];
         Neg.Emit := [1 => [1 => 1.0], 2 => [1 => 1.0]];
         --  Force a negative by assigning 0 and using a crafted check:
         --  overwrite emit with an impossible value using 'Unchecked
         --  not needed: set Init sum ok but Trans entry negative via
         --  Probability'First edge — assign 0 and mark invalid by
         --  putting a non-finite? Simpler: assign Trans (1,1) := 0.0
         --  and Trans (1,2) := 0.0 so row sum 0 fails stochastic;
         --  for negative test use Is_Valid with a modified copy via
         --  System.Storage — skip; instead test zero-sum row:
         Neg.Trans (1, 1) := 0.0;
         Neg.Trans (1, 2) := 0.0;
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
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Normalize_Rows empty raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("3. Single-observation path = argmax init*emit");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs_N : constant Observation_Sequence := [Normal];
      Obs_D : constant Observation_Sequence := [Dizzy];
      Rn    : constant Viterbi_Result := Viterbi_Decode (Model, Obs_N);
      Rd    : constant Viterbi_Result := Viterbi_Decode (Model, Obs_D);
      Rl    : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs_N);
      A_N   : constant State_Index :=
        Argmax_Init_Emit (Model.Init, Model.Emit, Normal);
      A_D   : constant State_Index :=
        Argmax_Init_Emit (Model.Init, Model.Emit, Dizzy);
   begin
      Check (A_N = Healthy, "argmax normal -> Healthy");
      Check (Rn.Path (1) = Healthy, "decode normal -> Healthy");
      Check (Rn.Length = 1, "single-obs length 1");
      Check (Approx (Rn.Probability, 0.3), "P(H,normal)=0.3");
      Check (A_D = Fever, "argmax dizzy -> Fever");
      Check (Rd.Path (1) = Fever, "decode dizzy -> Fever");
      Check (Approx (Rd.Probability, 0.24), "P(F,dizzy)=0.24");
      Check (Rl.Path (1) = Rn.Path (1), "log decode agrees single-obs");
      Check (Approx (Exp (Rl.Log_Probability), Rn.Probability, 1.0E-5),
             "log Exp(L) matches product P");
   end;

   ---------------------------------------------------------------------
   Section ("4. Two-state deterministic chain recovers forced path");
   ---------------------------------------------------------------------
   declare
      Model : HMM (N_States => 2, N_Symbols => 2);
      Obs   : constant Observation_Sequence := [1, 2, 1];
      R     : Viterbi_Result (Length => 3, N_States => 2);
      Rl    : Viterbi_Result (Length => 3, N_States => 2);
   begin
      Model.Init := [1 => 1.0, 2 => 0.0];
      Model.Trans :=
        [1 => [1 => 0.0, 2 => 1.0],
         2 => [1 => 1.0, 2 => 0.0]];
      Model.Emit :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 0.0, 2 => 1.0]];
      Check (Is_Valid_HMM (Model), "deterministic HMM valid");
      R  := Viterbi_Decode (Model, Obs);
      Rl := Viterbi_Decode_Log (Model, Obs);
      Check (R.Path (1) = 1, "det path t1=1");
      Check (R.Path (2) = 2, "det path t2=2");
      Check (R.Path (3) = 1, "det path t3=1");
      Check (Paths_Equal (R.Path, Rl.Path), "log matches product det path");
      Check (Approx (R.Probability, 1.0), "det path probability 1");
      Check (Approx (Path_Probability (Model, Obs, R.Path), 1.0),
             "Path_Probability of det path = 1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia doctor/fever example path + probability");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      R     : constant Viterbi_Result := Viterbi_Decode (Model, Obs);
      Rl    : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs);
      Expected : constant State_Sequence := [Healthy, Healthy, Fever];
      P_Path : constant Real := Path_Probability (Model, Obs, R.Path);
   begin
      Check (R.Path (1) = Healthy, "wiki path day1 Healthy");
      Check (R.Path (2) = Healthy, "wiki path day2 Healthy");
      Check (R.Path (3) = Fever,   "wiki path day3 Fever");
      Check (Paths_Equal (R.Path, Expected), "wiki path (H,H,F)");
      Check (Paths_Equal (Rl.Path, Expected), "log wiki path (H,H,F)");
      Check (Approx (R.Probability, 0.01512, 1.0E-6),
             "wiki final P = 0.01512");
      Check (Approx (P_Path, 0.01512, 1.0E-6),
             "Path_Probability(H,H,F)=0.01512");
      Check (Approx (Exp (Rl.Log_Probability), 0.01512, 1.0E-5),
             "log decode Exp(L)≈0.01512");
      Check (Approx (Exp (Log_Path_Probability (Model, Obs, Expected)),
                     0.01512, 1.0E-5),
             "Log_Path_Probability matches");
   end;

   ---------------------------------------------------------------------
   Section ("6. Wikipedia DP table cells (product form)");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      R     : constant Viterbi_Result :=
        Viterbi_Decode (Model, Obs, Fill_Table => True);
   begin
      Check (R.Has_Table, "Has_Table true");
      Check (Approx (R.Prob_Table (1, Healthy), 0.3),    "P[1,H]=0.3");
      Check (Approx (R.Prob_Table (1, Fever),   0.04),   "P[1,F]=0.04");
      Check (Approx (R.Prob_Table (2, Healthy), 0.084),  "P[2,H]=0.084");
      Check (Approx (R.Prob_Table (2, Fever),   0.027),  "P[2,F]=0.027");
      Check (Approx (R.Prob_Table (3, Healthy), 0.00588), "P[3,H]=0.00588");
      Check (Approx (R.Prob_Table (3, Fever),   0.01512), "P[3,F]=0.01512");
      Check (R.Backpointers (2, Healthy) = Natural (Healthy),
             "bp[2,H]=Healthy");
      Check (R.Backpointers (2, Fever) = Natural (Healthy),
             "bp[2,F]=Healthy");
      Check (R.Backpointers (3, Fever) = Natural (Healthy),
             "bp[3,F]=Healthy");
   end;

   ---------------------------------------------------------------------
   Section ("7. Log decode agrees with product on tiny probs");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs1  : constant Observation_Sequence := [Normal];
      Obs2  : constant Observation_Sequence := [Normal, Cold];
      Obs3  : constant Observation_Sequence := [Normal, Cold, Dizzy];
      Obs4  : constant Observation_Sequence := [Cold, Cold, Normal, Dizzy];
   begin
      declare
         Rp : constant Viterbi_Result := Viterbi_Decode (Model, Obs1);
         Rl : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs1);
      begin
         Check (Paths_Equal (Rp.Path, Rl.Path), "agree len1 path");
         Check (Approx (Rp.Probability, Exp (Rl.Log_Probability), 1.0E-5),
                "agree len1 prob");
      end;
      declare
         Rp : constant Viterbi_Result := Viterbi_Decode (Model, Obs2);
         Rl : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs2);
      begin
         Check (Paths_Equal (Rp.Path, Rl.Path), "agree len2 path");
         Check (Approx (Rp.Probability, Exp (Rl.Log_Probability), 1.0E-5),
                "agree len2 prob");
      end;
      declare
         Rp : constant Viterbi_Result := Viterbi_Decode (Model, Obs3);
         Rl : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs3);
      begin
         Check (Paths_Equal (Rp.Path, Rl.Path), "agree len3 path");
         Check (Approx (Rp.Probability, Exp (Rl.Log_Probability), 1.0E-5),
                "agree len3 prob");
         Check (Approx (Rp.Log_Probability, Rl.Log_Probability, 1.0E-4),
                "agree len3 log-prob");
      end;
      declare
         Rp : constant Viterbi_Result := Viterbi_Decode (Model, Obs4);
         Rl : constant Viterbi_Result := Viterbi_Decode_Log (Model, Obs4);
      begin
         Check (Paths_Equal (Rp.Path, Rl.Path), "agree len4 path");
         Check (Approx (Rp.Probability, Exp (Rl.Log_Probability), 1.0E-5),
                "agree len4 prob");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Viterbi path score ≥ any alternate path");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      R     : constant Viterbi_Result := Viterbi_Decode (Model, Obs);
      Best  : constant Real := Path_Probability (Model, Obs, R.Path);
      type Path3 is array (1 .. 3) of State_Index;
      Alts : constant array (1 .. 8) of Path3 :=
        [[1, 1, 1], [1, 1, 2], [1, 2, 1], [1, 2, 2],
         [2, 1, 1], [2, 1, 2], [2, 2, 1], [2, 2, 2]];
      All_Leq  : Boolean := True;
      Count_Eq : Natural := 0;
   begin
      for A of Alts loop
         declare
            Pth : constant State_Sequence := [A (1), A (2), A (3)];
            P   : constant Real := Path_Probability (Model, Obs, Pth);
         begin
            if P > Best + 1.0E-12 then
               All_Leq := False;
            end if;
            if Approx (P, Best, 1.0E-9) then
               Count_Eq := Count_Eq + 1;
            end if;
            Check (P <= Best + 1.0E-12,
                   "alt path scored ≤ best");
         end;
      end loop;
      Check (All_Leq, "all 8 paths ≤ Viterbi path");
      Check (Count_Eq >= 1, "at least the Viterbi path ties best");
      Check (Approx (Best, 0.01512), "best is wiki 0.01512");
   end;

   ---------------------------------------------------------------------
   Section ("9. Empty obs / bad symbol raises");
   ---------------------------------------------------------------------
   declare
      Model  : constant HMM := Make_Doctor_Fever_HMM;
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Empty  : Observation_Sequence (1 .. 0);
            Unused : Viterbi_Result := Viterbi_Decode (Model, Empty);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "empty obs raises (product)");

      Raised := False;
      begin
         declare
            Empty  : Observation_Sequence (1 .. 0);
            Unused : Viterbi_Result := Viterbi_Decode_Log (Model, Empty);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "empty obs raises (log)");

      Raised := False;
      begin
         declare
            Bad    : constant Observation_Sequence := [1, 4, 2];
            Unused : Viterbi_Result := Viterbi_Decode (Model, Bad);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "bad symbol raises Invalid_Argument");

      Raised := False;
      begin
         declare
            Obs    : constant Observation_Sequence := [Normal, Cold];
            Path   : constant State_Sequence := [Healthy];
            Unused : Real := Path_Probability (Model, Obs, Path);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "path/obs length mismatch raises");
   end;

   ---------------------------------------------------------------------
   Section ("10. Uniform noise model sanity");
   ---------------------------------------------------------------------
   declare
      Model : HMM (N_States => 3, N_Symbols => 2);
      Obs   : constant Observation_Sequence := [1, 2, 1, 2, 1];
      R     : Viterbi_Result (Length => 5, N_States => 3);
      Rl    : Viterbi_Result (Length => 5, N_States => 3);
      Third : constant Probability := Probability (1.0 / 3.0);
   begin
      Model.Init := [1 => Third, 2 => Third, 3 => Third];
      for S in 1 .. 3 loop
         for T in 1 .. 3 loop
            Model.Trans (S, T) := Third;
         end loop;
         Model.Emit (S, 1) := 0.5;
         Model.Emit (S, 2) := 0.5;
      end loop;
      Check (Is_Valid_HMM (Model), "uniform HMM valid");
      R  := Viterbi_Decode (Model, Obs);
      Rl := Viterbi_Decode_Log (Model, Obs);
      Check (R.Path'Length = Obs'Length, "uniform path length = obs");
      Check (Paths_Equal (R.Path, Rl.Path), "uniform log=product path");
            Check (Approx (R.Probability, Exp (Rl.Log_Probability), 1.0E-5),
             "uniform P matches Exp(L)");
      Check (R.Path (1) = 1, "tie-break prefers lowest index t1");
      Check (R.Path (2) = 1, "tie-break prefers lowest index t2");
      Check (Approx (Path_Probability (Model, Obs, R.Path), R.Probability,
                     1.0E-9),
             "path score equals DP final");
   end;

   ---------------------------------------------------------------------
   Section ("11. Backpointer correctness on hand-worked 2×3 trellis");
   ---------------------------------------------------------------------
   declare
      Model : HMM (N_States => 2, N_Symbols => 3);
      Obs   : constant Observation_Sequence := [1, 2, 3];
      R     : Viterbi_Result (Length => 3, N_States => 2);
   begin
      Model.Init := [1 => 0.8, 2 => 0.2];
      Model.Trans :=
        [1 => [1 => 0.6, 2 => 0.4],
         2 => [1 => 0.5, 2 => 0.5]];
      Model.Emit :=
        [1 => [1 => 0.7, 2 => 0.2, 3 => 0.1],
         2 => [1 => 0.1, 2 => 0.3, 3 => 0.6]];
      Check (Is_Valid_HMM (Model), "hand trellis HMM valid");
      R := Viterbi_Decode (Model, Obs, Fill_Table => True);
      Check (Approx (R.Prob_Table (1, 1), 0.56), "hand P[1,1]=0.56");
      Check (Approx (R.Prob_Table (1, 2), 0.02), "hand P[1,2]=0.02");
      Check (Approx (R.Prob_Table (2, 1), 0.0672), "hand P[2,1]=0.0672");
      Check (Approx (R.Prob_Table (2, 2), 0.0672), "hand P[2,2]=0.0672");
      Check (Approx (R.Prob_Table (3, 1), 0.004032), "hand P[3,1]=0.004032");
      Check (Approx (R.Prob_Table (3, 2), 0.02016),  "hand P[3,2]=0.02016");
      Check (R.Backpointers (2, 1) = 1, "hand bp[2,1]=1");
      Check (R.Backpointers (2, 2) = 1, "hand bp[2,2]=1");
      Check (R.Backpointers (3, 2) = 2, "hand bp[3,2]=2");
      Check (R.Path (1) = 1, "hand path t1=1");
      Check (R.Path (2) = 2, "hand path t2=2");
      Check (R.Path (3) = 2, "hand path t3=2");
      Check (Approx (R.Probability, 0.02016), "hand final P=0.02016");
      Check (Approx (Path_Probability (Model, Obs, R.Path), 0.02016),
             "hand Path_Probability matches");
   end;

   ---------------------------------------------------------------------
   Section ("12. Degenerate geometry (zero emissions) raises");
   ---------------------------------------------------------------------
   declare
      Model  : HMM (N_States => 2, N_Symbols => 2);
      Raised : Boolean;
   begin
      Model.Init := [1 => 0.5, 2 => 0.5];
      Model.Trans :=
        [1 => [1 => 0.5, 2 => 0.5],
         2 => [1 => 0.5, 2 => 0.5]];
      Model.Emit :=
        [1 => [1 => 1.0, 2 => 0.0],
         2 => [1 => 1.0, 2 => 0.0]];
      Raised := False;
      begin
         declare
            Obs    : constant Observation_Sequence := [2];
            Unused : Viterbi_Result := Viterbi_Decode (Model, Obs);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "zero emit at t1 raises Degenerate_Geometry");

      Raised := False;
      begin
         declare
            Obs    : constant Observation_Sequence := [1, 2];
            Unused : Viterbi_Result := Viterbi_Decode_Log (Model, Obs);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "zero emit mid-seq raises (log)");
   end;

   ---------------------------------------------------------------------
   Section ("13. Argmax / Make_Doctor_Fever_HMM fixture details");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Row   : constant Initial_Vector := Model.Init;
      H_Id  : constant Integer := Integer (Healthy);
      F_Id  : constant Integer := Integer (Fever);
      N_Id  : constant Integer := Integer (Normal);
      C_Id  : constant Integer := Integer (Cold);
      D_Id  : constant Integer := Integer (Dizzy);
   begin
      Check (Model.N_States = 2, "fixture N_States=2");
      Check (Model.N_Symbols = 3, "fixture N_Symbols=3");
      Check (Approx (Real (Model.Init (Healthy)), 0.6), "init H=0.6");
      Check (Approx (Real (Model.Init (Fever)), 0.4), "init F=0.4");
      Check (Approx (Real (Model.Trans (Healthy, Healthy)), 0.7), "a_HH=0.7");
      Check (Approx (Real (Model.Trans (Healthy, Fever)), 0.3), "a_HF=0.3");
      Check (Approx (Real (Model.Trans (Fever, Healthy)), 0.4), "a_FH=0.4");
      Check (Approx (Real (Model.Trans (Fever, Fever)), 0.6), "a_FF=0.6");
      Check (Approx (Real (Model.Emit (Healthy, Normal)), 0.5), "b_Hn=0.5");
      Check (Approx (Real (Model.Emit (Healthy, Cold)), 0.4), "b_Hc=0.4");
      Check (Approx (Real (Model.Emit (Healthy, Dizzy)), 0.1), "b_Hd=0.1");
      Check (Approx (Real (Model.Emit (Fever, Normal)), 0.1), "b_Fn=0.1");
      Check (Approx (Real (Model.Emit (Fever, Cold)), 0.3), "b_Fc=0.3");
      Check (Approx (Real (Model.Emit (Fever, Dizzy)), 0.6), "b_Fd=0.6");
      Check (Argmax_Row (Row) = Healthy, "Argmax_Row init -> Healthy");
      pragma Warnings (Off, "condition is always");
      Check (H_Id = 1, "Healthy constant = 1");
      Check (F_Id = 2, "Fever constant = 2");
      Check (N_Id = 1, "Normal constant = 1");
      Check (C_Id = 2, "Cold constant = 2");
      Check (D_Id = 3, "Dizzy constant = 3");
      pragma Warnings (On, "condition is always");
   end;

   ---------------------------------------------------------------------
   Section ("14. Fill_Table false / alternate path scores");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : constant Observation_Sequence := [Normal, Cold, Dizzy];
      R0    : constant Viterbi_Result :=
        Viterbi_Decode (Model, Obs, Fill_Table => False);
      Alt   : constant State_Sequence := [Fever, Fever, Fever];
      P_Alt : constant Real := Path_Probability (Model, Obs, Alt);
      P_Vit : constant Real := Path_Probability (Model, Obs, R0.Path);
   begin
      Check (not R0.Has_Table, "Fill_Table false => Has_Table false");
      Check (Paths_Equal (R0.Path, [Healthy, Healthy, Fever]),
             "still recovers wiki path without table");
      Check (P_Vit > P_Alt, "Viterbi path beats all-Fever");
      Check (Approx (P_Alt,
                     0.4 * 0.1 * 0.6 * 0.3 * 0.6 * 0.6, 1.0E-9),
             "all-Fever path analytic");
      Check (Approx (P_Alt, 0.002592), "all-Fever P=0.002592");
      Check (Approx (Log_Path_Probability (Model, Obs, Alt),
                     Log (P_Alt), 1.0E-4),
             "Log_Path_Probability ≈ Log(P)");
   end;

   ---------------------------------------------------------------------
   Section ("15. Longer sequence log stability vs product");
   ---------------------------------------------------------------------
   declare
      Model : constant HMM := Make_Doctor_Fever_HMM;
      Obs   : Observation_Sequence (1 .. 20);
      Rp, Rl : Viterbi_Result (Length => 20, N_States => 2);
   begin
      for T in Obs'Range loop
         case T mod 3 is
            when 1 =>
               Obs (T) := Normal;
            when 2 =>
               Obs (T) := Cold;
            when others =>
               Obs (T) := Dizzy;
         end case;
      end loop;
      Rp := Viterbi_Decode (Model, Obs);
      Rl := Viterbi_Decode_Log (Model, Obs);
      Check (Paths_Equal (Rp.Path, Rl.Path),
             "len20 path product=log");
      Check (Rl.Log_Probability < 0.0, "len20 log-prob negative");
      Check (Rp.Probability > 0.0, "len20 product still > 0");
      Check (Approx (Rp.Log_Probability, Rl.Log_Probability, 1.0E-3),
             "len20 log-probs agree");
      Check (Approx (Path_Probability (Model, Obs, Rl.Path),
                     Rp.Probability, 1.0E-9),
             "len20 Path_Probability = DP P");
   end;

   New_Line;
   Put_Line ("==================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
   Put_Line ("All tests passed.");
end Tests;
