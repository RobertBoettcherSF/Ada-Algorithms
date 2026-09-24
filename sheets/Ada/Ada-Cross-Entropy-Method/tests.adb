--  Standalone test suite for Cross_Entropy_Method (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;
with Cross_Entropy_Method; use Cross_Entropy_Method;

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

begin
   Put_Line ("Cross_Entropy_Method test suite");
   Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp / Elite_Count / Default_Parameters");
   ---------------------------------------------------------------------
   declare
      P : Parameters;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Clamp (0.5, 0.0, 1.0) = 0.5, "Clamp interior");
      Check (Clamp (-1.0, 0.0, 1.0) = 0.0, "Clamp below");
      Check (Clamp (2.0, 0.0, 1.0) = 1.0, "Clamp above");
      Check (Clamp (0.0, 0.0, 1.0) = 0.0, "Clamp at Lo");
      Check (Clamp (1.0, 0.0, 1.0) = 1.0, "Clamp at Hi");
      Check (Elite_Count (100, 0.1) = 10, "Elite_Count 100*0.1");
      Check (Elite_Count (50, 0.1) = 5, "Elite_Count 50*0.1");
      Check (Elite_Count (10, 0.05) = 1, "Elite_Count floors to 1");
      Check (Elite_Count (8, 1.0) = 8, "Elite_Count Rho=1");
      Check (Elite_Count (256, 0.25) = 64, "Elite_Count 256*0.25");
      P := Default_Parameters;
      Check (P.N = 100, "Default N");
      Check (Approx (Real (P.Rho), 0.1, 1.0E-12), "Default Rho");
      Check (Approx (Real (P.Alpha), 0.7, 1.0E-12), "Default Alpha");
      Check (P.Max_Iter = 100, "Default Max_Iter");
      Check (P.Seed = 1, "Default Seed");
      Check (Approx (P.Sigma_Min, 1.0E-6, 1.0E-12), "Default Sigma_Min");
      P := Default_Parameters
        (N => 32, Rho => 0.2, Alpha => 1.0, Max_Iter => 5,
         Seed => 42, Sigma_Min => 1.0E-4);
      Check (P.N = 32 and then P.Seed = 42 and then P.Max_Iter = 5,
             "Default_Parameters overrides");
      Check (Approx (Real (P.Rho), 0.2) and then Approx (Real (P.Alpha), 1.0),
             "Default_Parameters Rho/Alpha");
   end;

   ---------------------------------------------------------------------
   Section ("2. Clamp inverted raises");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Unused : Real;
   begin
      Raised := False;
      begin
         Unused := Clamp (0.0, 2.0, 1.0);
         Check (Unused < 0.0, "unreachable clamp success");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Clamp inverted raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. RNG determinism / range / Next_Index");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      All_Match  : Boolean := True;
      Saw_Diff   : Boolean := False;
      Idx        : Positive;
      Idx_Ok     : Boolean := True;
      Uni_Ok     : Boolean := True;
      V          : Real;
   begin
      Seed_RNG (S1, 7);
      Seed_RNG (S2, 7);
      Seed_RNG (S3, 8);
      for K in 1 .. 50 loop
         U1 := Next_Unit (S1);
         U2 := Next_Unit (S2);
         U3 := Next_Unit (S3);
         if U1 /= U2 then
            All_Match := False;
         end if;
         if U1 /= U3 then
            Saw_Diff := True;
         end if;
         if Real (U1) < 0.0 then
            All_Match := False;
         end if;
      end loop;
      Check (All_Match, "RNG same seed reproduces and stays in [0,1)");
      Check (Saw_Diff, "RNG different seeds diverge");

      Seed_RNG (S1, 0);
      Seed_RNG (S2, 0);
      Check (Next_Unit (S1) = Next_Unit (S2), "Seed 0 maps identically");

      Seed_RNG (S1, 99);
      for K in 1 .. 200 loop
         Idx := Next_Index (S1, 1, 5);
         if Idx > 5 then
            Idx_Ok := False;
         end if;
      end loop;
      Check (Idx_Ok, "Next_Index in [1,5]");

      declare
         Counts : array (1 .. 3) of Natural := [others => 0];
         Seen_All : Boolean;
      begin
         Seed_RNG (S1, 123);
         for K in 1 .. 300 loop
            Idx := Next_Index (S1, 1, 3);
            Counts (Idx) := Counts (Idx) + 1;
         end loop;
         Seen_All := Counts (1) > 0 and then Counts (2) > 0
           and then Counts (3) > 0;
         Check (Seen_All, "Next_Index hits all of 1..3");
         Check (Counts (1) + Counts (2) + Counts (3) = 300,
                "Next_Index count sum 300");
      end;

      Seed_RNG (S1, 3);
      for K in 1 .. 100 loop
         V := Next_Uniform (S1, -2.0, 2.0);
         if V < -2.0 or else V > 2.0 then
            Uni_Ok := False;
         end if;
      end loop;
      Check (Uni_Ok, "Next_Uniform in [-2,2]");
   end;

   ---------------------------------------------------------------------
   Section ("4. Next_Gaussian stats roughly match μ/σ");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      N : constant := 2000;
      Acc, Acc2 : Real := 0.0;
      X : Real;
      Mean_Est, Var_Est, Std_Est : Real;
      Mu : constant Real := 3.0;
      Sig : constant Real := 2.0;
   begin
      Seed_RNG (S, 77);
      for K in 1 .. N loop
         X := Next_Gaussian (S, Mu, Sig);
         Acc := Acc + X;
         Acc2 := Acc2 + X * X;
      end loop;
      Mean_Est := Acc / Real (N);
      Var_Est := Acc2 / Real (N) - Mean_Est * Mean_Est;
      Std_Est := Real (Sqrt (Float (Var_Est)));
      Check (Approx (Mean_Est, Mu, 0.15), "Gaussian sample mean ~ μ");
      Check (Approx (Std_Est, Sig, 0.20), "Gaussian sample std ~ σ");

      Seed_RNG (S, 1);
      Check (Approx (Next_Gaussian (S, 5.0, 0.0), 5.0, 1.0E-12),
             "Gaussian Std=0 is deterministic");
   end;

   ---------------------------------------------------------------------
   Section ("5. Objectives Sphere / Rosenbrock / Rastrigin / Shifted");
   ---------------------------------------------------------------------
   declare
      Z2 : constant Vector := [0.0, 0.0];
      O2 : constant Vector := [1.0, 1.0];
      A2 : constant Vector := [1.0, 0.0];
      Raised : Boolean;
   begin
      Check (Approx (Sphere (Z2), 0.0), "Sphere at origin");
      Check (Approx (Sphere (A2), 1.0), "Sphere (1,0)");
      Check (Approx (Sphere ([3.0, 4.0]), 25.0), "Sphere 3-4-5");
      Check (Approx (Rosenbrock (O2), 0.0), "Rosenbrock at (1,1)");
      Check (Rosenbrock (Z2) > 0.0, "Rosenbrock origin positive");
      Check (Approx (Rastrigin (Z2), 0.0, 1.0E-5), "Rastrigin at origin");
      Check (Rastrigin ([1.0, 1.0]) > 0.0, "Rastrigin (1,1) positive");
      Check (Approx (Shifted_Sphere (O2), 0.0), "Shifted_Sphere at ones");
      Check (Approx (Shifted_Sphere (Z2), 2.0), "Shifted_Sphere at origin D=2");

      Raised := False;
      begin
         declare
            Unused : constant Real := Rosenbrock ([1.0]);
         begin
            Check (Unused < 0.0, "unreachable rosenbrock success");
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Rosenbrock D=1 raises");
   end;

   ---------------------------------------------------------------------
   Section ("6. Init_Isotropic / Sample_Gaussian shape");
   ---------------------------------------------------------------------
   declare
      G : Gaussian_Params;
      Buf : Sample_Buffer (Capacity => 40);
      S : RNG_State;
      Acc : Real;
      Mean_Est : Real;
   begin
      G := Init_Isotropic (3, 2.0, 1.5);
      Check (G.Dim = 3, "Init_Isotropic Dim");
      Check (Approx (G.Means (1), 2.0) and then Approx (G.Means (3), 2.0),
             "Init_Isotropic Means");
      Check (Approx (G.Stds (2), 1.5), "Init_Isotropic Stds");
      Check (Approx (G.Means (4), 0.0), "Init_Isotropic unused mean 0");

      Seed_RNG (S, 11);
      Sample_Gaussian (Buf, G, S);
      Check (Buf.Size = 40 and then Buf.Dim = 3, "Sample_Gaussian Size/Dim");
      Acc := 0.0;
      for K in 1 .. Buf.Size loop
         Acc := Acc + Buf.Members (K).X (1);
      end loop;
      Mean_Est := Acc / Real (Buf.Size);
      Check (Approx (Mean_Est, 2.0, 0.6), "Sample_Gaussian dim1 mean ~ 2");
   end;

   --  Recount candidate Dim without flooding: redo compact check
   declare
      G : constant Gaussian_Params := Init_Isotropic (2, 0.0, 1.0);
      Buf : Sample_Buffer (Capacity => 8);
      S : RNG_State;
      Ok : Boolean := True;
   begin
      Seed_RNG (S, 2);
      Sample_Gaussian (Buf, G, S);
      for K in 1 .. Buf.Size loop
         if Buf.Members (K).Dim /= 2 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "All candidates Dim=2");
   end;

   ---------------------------------------------------------------------
   Section ("7. Evaluate_Samples / Elite_Indices order");
   ---------------------------------------------------------------------
   declare
      Buf : Sample_Buffer (Capacity => 6);
      Elite : Index_List (1 .. 2);
      S : RNG_State;
      G : constant Gaussian_Params := Init_Isotropic (1, 0.0, 1.0);
   begin
      Seed_RNG (S, 5);
      Sample_Gaussian (Buf, G, S);
      --  Overwrite with known costs / positions for elite order test.
      Buf.Size := 5;
      Buf.Dim := 1;
      Buf.Members (1).X (1) := 10.0;
      Buf.Members (1).Cost := 10.0;
      Buf.Members (2).X (1) := 1.0;
      Buf.Members (2).Cost := 1.0;
      Buf.Members (3).X (1) := 5.0;
      Buf.Members (3).Cost := 5.0;
      Buf.Members (4).X (1) := 0.5;
      Buf.Members (4).Cost := 0.5;
      Buf.Members (5).X (1) := 3.0;
      Buf.Members (5).Cost := 3.0;

      declare
         E : constant Index_List := Elite_Indices (Buf, 0.4);
         --  Ne = floor(0.4*5)=2 → indices of costs 0.5 then 1.0 → 4, 2
      begin
         Check (E'Length = 2, "Elite length 2 for Rho=0.4 N=5");
         Check (E (1) = 4, "Elite first is index 4 (cost 0.5)");
         Check (E (2) = 2, "Elite second is index 2 (cost 1.0)");
         Check (Buf.Members (E (1)).Cost <= Buf.Members (E (2)).Cost,
                "Elite ascending cost order");
      end;

      declare
         E1 : constant Index_List := Elite_Indices (Buf, 0.01);
      begin
         Check (E1'Length = 1 and then E1 (1) = 4,
                "Elite Rho tiny still picks best");
      end;

      --  Evaluate_Samples with Sphere
      Buf.Size := 4;
      Buf.Dim := 2;
      for K in 1 .. 4 loop
         Buf.Members (K).X (1) := Real (K);
         Buf.Members (K).X (2) := 0.0;
         Buf.Members (K).Dim := 2;
      end loop;
      Evaluate_Samples (Buf, Sphere'Access);
      Check (Approx (Buf.Members (1).Cost, 1.0), "Evaluate Sphere k=1");
      Check (Approx (Buf.Members (3).Cost, 9.0), "Evaluate Sphere k=3");
      Check (Approx (Buf.Members (4).Cost, 16.0), "Evaluate Sphere k=4");
      Elite := Elite_Indices (Buf, 0.5);
      Check (Elite'Length = 2, "Elite half of 4");
      Check (Elite (1) = 1 and then Elite (2) = 2, "Elite best two indices");
   end;

   ---------------------------------------------------------------------
   Section ("8. Update_From_Elite smoothing / Sigma_Min");
   ---------------------------------------------------------------------
   declare
      G : Gaussian_Params := Init_Isotropic (1, 0.0, 5.0);
      Buf : Sample_Buffer (Capacity => 4);
      Elite : Index_List (1 .. 2);
   begin
      Buf.Size := 4;
      Buf.Dim := 1;
      Buf.Members (1).X (1) := 2.0;
      Buf.Members (2).X (1) := 4.0;
      Buf.Members (3).X (1) := 100.0;
      Buf.Members (4).X (1) := -100.0;
      Elite (1) := 1;
      Elite (2) := 2;
      --  μ_e = 3, σ_e = sqrt(((2-3)^2+(4-3)^2)/2)=1; α=1 → μ=3, σ=1
      Update_From_Elite (G, Buf, Elite, 1.0, 1.0E-6);
      Check (Approx (G.Means (1), 3.0), "Update α=1 mean → elite mean");
      Check (Approx (G.Stds (1), 1.0, 1.0E-5), "Update α=1 std → elite std");

      G := Init_Isotropic (1, 0.0, 4.0);
      Update_From_Elite (G, Buf, Elite, 0.5, 1.0E-6);
      --  μ = 0.5*0 + 0.5*3 = 1.5; σ = 0.5*4 + 0.5*1 = 2.5
      Check (Approx (G.Means (1), 1.5), "Update α=0.5 smoothed mean");
      Check (Approx (G.Stds (1), 2.5, 1.0E-5), "Update α=0.5 smoothed std");

      --  Sigma_Min floor
      G := Init_Isotropic (1, 0.0, 0.01);
      Buf.Members (1).X (1) := 1.0;
      Buf.Members (2).X (1) := 1.0;
      Update_From_Elite (G, Buf, Elite, 1.0, 0.5);
      Check (Approx (G.Means (1), 1.0), "Update identical elite mean");
      Check (Approx (G.Stds (1), 0.5), "Update Sigma_Min floor applied");

      --  Single elite → σ_e = 0 then floor
      declare
         E1 : constant Index_List (1 .. 1) := [1];
      begin
         G := Init_Isotropic (1, 9.0, 3.0);
         Buf.Members (1).X (1) := 7.0;
         Update_From_Elite (G, Buf, E1, 1.0, 0.25);
         Check (Approx (G.Means (1), 7.0), "Single elite mean");
         Check (Approx (G.Stds (1), 0.25), "Single elite Sigma_Min");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Step one iteration improves Sphere mean");
   ---------------------------------------------------------------------
   declare
      G : Gaussian_Params := Init_Isotropic (2, 5.0, 3.0);
      Buf : Sample_Buffer (Capacity => 64);
      P : constant Parameters := Default_Parameters
        (N => 64, Rho => 0.2, Alpha => 0.9, Max_Iter => 1, Seed => 9);
      S : RNG_State;
      Best_Cost : Real := Real'Last;
      Best_X : Vector (1 .. 2) := [0.0, 0.0];
      Mean_Norm_Before, Mean_Norm_After : Real;
   begin
      Seed_RNG (S, P.Seed);
      Mean_Norm_Before :=
        G.Means (1) * G.Means (1) + G.Means (2) * G.Means (2);
      Step (G, Buf, P, Sphere'Access, S, Best_Cost, Best_X);
      Mean_Norm_After :=
        G.Means (1) * G.Means (1) + G.Means (2) * G.Means (2);
      Check (Best_Cost < Real'Last / 2.0, "Step records a best cost");
      Check (Mean_Norm_After < Mean_Norm_Before,
             "Step pulls mean toward origin on Sphere");
      Check (G.Stds (1) < 3.0 or else G.Stds (2) < 3.0,
             "Step typically shrinks some σ");
      Check (Buf.Size = 64, "Step uses N samples");
   end;

   ---------------------------------------------------------------------
   Section ("10. Minimize Sphere converges near 0");
   ---------------------------------------------------------------------
   declare
      R : Result;
      P : Parameters;
   begin
      P := Default_Parameters
        (N => 80, Rho => 0.1, Alpha => 0.7, Max_Iter => 60,
         Seed => 42, Sigma_Min => 1.0E-4);
      R := Minimize_Isotropic
        (Sphere'Access, 2, Mean => 3.0, Std => 4.0, Params => P);
      Check (R.Dim = 2, "Minimize Sphere Dim");
      Check (R.Iterations > 0, "Minimize ran iterations");
      Check (R.Best_Cost < 0.05, "Sphere best cost near 0");
      Check (Approx (R.Best_X (1), 0.0, 0.25), "Sphere best x1 near 0");
      Check (Approx (R.Best_X (2), 0.0, 0.25), "Sphere best x2 near 0");
      Check (abs (R.Final_Mean (1)) < 0.5, "Final mean1 near 0");
      Check (abs (R.Final_Mean (2)) < 0.5, "Final mean2 near 0");

      --  D=1 Sphere
      P := Default_Parameters
        (N => 40, Rho => 0.15, Alpha => 0.8, Max_Iter => 40, Seed => 7);
      R := Minimize_Isotropic
        (Sphere'Access, 1, Mean => -8.0, Std => 5.0, Params => P);
      Check (R.Best_Cost < 0.02, "D=1 Sphere near 0");
      Check (Approx (R.Best_X (1), 0.0, 0.2), "D=1 best x near 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. Shifted_Sphere / Rosenbrock / Rastrigin toys");
   ---------------------------------------------------------------------
   declare
      R : Result;
      P : Parameters;
   begin
      P := Default_Parameters
        (N => 100, Rho => 0.1, Alpha => 0.7, Max_Iter => 80,
         Seed => 3, Sigma_Min => 1.0E-4);
      R := Minimize_Isotropic
        (Shifted_Sphere'Access, 2, Mean => 0.0, Std => 3.0, Params => P);
      Check (R.Best_Cost < 0.1, "Shifted_Sphere near 0");
      Check (Approx (R.Best_X (1), 1.0, 0.35), "Shifted_Sphere x1~1");
      Check (Approx (R.Best_X (2), 1.0, 0.35), "Shifted_Sphere x2~1");

      P := Default_Parameters
        (N => 120, Rho => 0.1, Alpha => 0.7, Max_Iter => 120,
         Seed => 11, Sigma_Min => 1.0E-3);
      R := Minimize_Isotropic
        (Rosenbrock'Access, 2, Mean => 0.0, Std => 1.5, Params => P);
      Check (R.Best_Cost < 5.0, "Rosenbrock educational progress");
      Check (R.Iterations > 0, "Rosenbrock iterations > 0");

      P := Default_Parameters
        (N => 100, Rho => 0.1, Alpha => 0.7, Max_Iter => 80,
         Seed => 19, Sigma_Min => 1.0E-3);
      R := Minimize_Isotropic
        (Rastrigin'Access, 2, Mean => 0.5, Std => 2.0, Params => P);
      Check (R.Best_Cost < 15.0, "Rastrigin educational progress");
   end;

   ---------------------------------------------------------------------
   Section ("12. Max_Iter=0 init-only / validation");
   ---------------------------------------------------------------------
   declare
      R : Result;
      P : Parameters;
      Raised : Boolean;
      G : Gaussian_Params;
   begin
      P := Default_Parameters (N => 20, Max_Iter => 0, Seed => 1);
      R := Minimize_Isotropic
        (Sphere'Access, 2, Mean => 1.0, Std => 1.0, Params => P);
      Check (R.Iterations = 0, "Max_Iter=0 → 0 iterations");
      Check (R.Best_Cost < Real'Last / 2.0, "Max_Iter=0 still evaluates");
      Check (R.Samples_Used = 20, "Samples_Used = N");

      Raised := False;
      begin
         R := Minimize (null, Init_Isotropic (1, 0.0, 1.0), P);
         Check (False, "unreachable null objective");
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Null Objective raises");

      --  Caps exercised by constructing at Max_Dim / large N
      G := Init_Isotropic (Max_Dim, 0.0, 1.0);
      Check (G.Dim = Max_Dim, "Init at Max_Dim");
      Check (Approx (G.Stds (Max_Dim), 1.0), "Init Max_Dim last std");
      declare
         Big : Sample_Buffer (Capacity => Max_N);
         S   : RNG_State;
      begin
         Seed_RNG (S, 2);
         Sample_Gaussian (Big, G, S);
         Check (Big.Size = Max_N, "Sample_Gaussian at Max_N");
         Check (Big.Dim = Max_Dim, "Sample_Gaussian Max_N keeps Dim");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Reproducibility same seed");
   ---------------------------------------------------------------------
   declare
      P : constant Parameters := Default_Parameters
        (N => 30, Rho => 0.2, Alpha => 0.8, Max_Iter => 15, Seed => 99);
      R1, R2 : Result;
   begin
      R1 := Minimize_Isotropic
        (Sphere'Access, 2, Mean => 2.0, Std => 2.0, Params => P);
      R2 := Minimize_Isotropic
        (Sphere'Access, 2, Mean => 2.0, Std => 2.0, Params => P);
      Check (Approx (R1.Best_Cost, R2.Best_Cost, 1.0E-12),
             "Same seed same Best_Cost");
      Check (Approx (R1.Best_X (1), R2.Best_X (1), 1.0E-12)
               and then Approx (R1.Best_X (2), R2.Best_X (2), 1.0E-12),
             "Same seed same Best_X");
      Check (R1.Iterations = R2.Iterations, "Same seed same Iterations");
   end;

   ---------------------------------------------------------------------
   Section ("14. Bernoulli sketch / Tiny_Knapsack");
   ---------------------------------------------------------------------
   declare
      B : Bernoulli_Params;
      S : RNG_State;
      Bits : Bit_Vector (1 .. 4);
      Values  : constant Vector := [10.0, 6.0, 5.0, 1.0];
      Weights : constant Vector := [5.0, 3.0, 3.0, 1.0];
      Cap : constant Non_Negative := 8.0;
      V : Real;
      Elite_Pack : Bit_Vector (1 .. 8);
      --  2 elites × 4 bits
   begin
      B := Init_Bernoulli (4, 0.5);
      Check (B.Dim = 4, "Init_Bernoulli Dim");
      Check (Approx (B.Probs (1), 0.5) and then Approx (B.Probs (4), 0.5),
             "Init_Bernoulli P=0.5");

      Seed_RNG (S, 21);
      Sample_Bernoulli_Bits (Bits, B, S);
      --  Just ensure call works; check value function
      Bits := [True, True, False, False];  -- weight 5+3=8, value 10+6=16
      V := Tiny_Knapsack_Value (Bits, Values, Weights, Cap);
      Check (Approx (V, 16.0), "Knapsack feasible value 16");
      Bits := [True, True, True, False];  -- weight 11 > 8
      V := Tiny_Knapsack_Value (Bits, Values, Weights, Cap);
      Check (V < -1.0E20, "Knapsack infeasible → penalty");

      --  Elite both select bit1=True, bit2=False, bit3=True, bit4=False
      Elite_Pack :=
        [True, False, True, False,
         True, False, True, False];
      B := Init_Bernoulli (4, 0.5);
      Update_Bernoulli_From_Elite (B, Elite_Pack, 2, 1.0);
      Check (B.Probs (1) > 0.9, "Bernoulli elite raises p1");
      Check (B.Probs (2) < 0.1, "Bernoulli elite lowers p2");
      Check (B.Probs (3) > 0.9, "Bernoulli elite raises p3");
      Check (B.Probs (4) < 0.1, "Bernoulli elite lowers p4");

      --  Next_Bernoulli frequency roughly matches P
      declare
         Ones : Natural := 0;
         Ok : Boolean;
      begin
         Seed_RNG (S, 55);
         for K in 1 .. 1000 loop
            if Next_Bernoulli (S, 0.3) then
               Ones := Ones + 1;
            end if;
         end loop;
         Ok := Ones > 200 and then Ones < 400;
         Check (Ok, "Bernoulli p=0.3 frequency ballpark");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Caps / multi-D Sphere D=3");
   ---------------------------------------------------------------------
   declare
      R : Result;
      P : constant Parameters := Default_Parameters
        (N => 100, Rho => 0.1, Alpha => 0.75, Max_Iter => 70,
         Seed => 13, Sigma_Min => 1.0E-4);
   begin
      R := Minimize_Isotropic
        (Sphere'Access, 3, Mean => 2.0, Std => 3.0, Params => P);
      Check (R.Dim = 3, "D=3 Sphere Dim");
      Check (R.Best_Cost < 0.15, "D=3 Sphere near 0");
      Check (abs (R.Best_X (1)) < 0.4
               and then abs (R.Best_X (2)) < 0.4
               and then abs (R.Best_X (3)) < 0.4,
             "D=3 best coords near 0");
      Check (R.Samples_Used = 100, "D=3 Samples_Used");
   end;

   ---------------------------------------------------------------------
   Section ("16. Elite tie-break prefers smaller index");
   ---------------------------------------------------------------------
   declare
      Buf : Sample_Buffer (Capacity => 4);
      E : Index_List (1 .. 2);
   begin
      Buf.Size := 4;
      Buf.Dim := 1;
      Buf.Members (1).Cost := 1.0;
      Buf.Members (2).Cost := 1.0;
      Buf.Members (3).Cost := 5.0;
      Buf.Members (4).Cost := 5.0;
      E := Elite_Indices (Buf, 0.5);
      Check (E'Length = 2, "Tie elite length");
      Check (E (1) = 1 and then E (2) = 2, "Tie-break smaller indices first");
   end;

   New_Line;
   Put_Line ("=================================");
   Put_Line ("Pass_Count =" & Pass_Count'Image);
   Put_Line ("Fail_Count =" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
