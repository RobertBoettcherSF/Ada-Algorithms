--  Standalone test suite for Stochastic_Tunneling (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Stochastic_Tunneling; use Stochastic_Tunneling;

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
   Put_Line ("Stochastic_Tunneling test suite");
   Put_Line ("===============================");

   ---------------------------------------------------------------------
   Section ("1. Near helper");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (-5.0, -5.0), "Near negatives");
      Check (Near (100.0, 100.0 + 5.0E-11), "Near large magnitude");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG determinism / range");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      G1, G2     : Real;
      All_In     : Boolean := True;
      Saw_Neg    : Boolean := False;
      Saw_Pos    : Boolean := False;
   begin
      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      Seed_RNG (S3, 99);
      U1 := Next_Unit (S1);
      U2 := Next_Unit (S2);
      U3 := Next_Unit (S3);
      Check (U1 = U2, "same seed -> same first draw");
      Check (U1 /= U3, "different seeds differ");
      Check (U1 >= 0.0 and then U1 < 1.0, "U in [0,1)");

      Seed_RNG (S1, 7);
      Seed_RNG (S2, 7);
      for I in 1 .. 20 loop
         U1 := Next_Unit (S1);
         U2 := Next_Unit (S2);
         if U1 /= U2 then
            All_In := False;
         end if;
         if not (U1 >= 0.0 and then U1 < 1.0) then
            All_In := False;
         end if;
      end loop;
      Check (All_In, "20 draws match across identical seeds and in range");

      Seed_RNG (S1, 123);
      Seed_RNG (S2, 123);
      G1 := Next_Gaussian (S1);
      G2 := Next_Gaussian (S2);
      Check (Near (G1, G2, 0.0), "Gaussian reproducible with seed");

      Seed_RNG (S1, 55);
      for I in 1 .. 40 loop
         G1 := Next_Gaussian (S1);
         if G1 < 0.0 then
            Saw_Neg := True;
         end if;
         if G1 > 0.0 then
            Saw_Pos := True;
         end if;
      end loop;
      Check (Saw_Neg and Saw_Pos, "Gaussian produces both signs");

      Seed_RNG (S1, 3);
      declare
         V : Real;
         Ok : Boolean := True;
      begin
         for I in 1 .. 30 loop
            V := Next_Uniform (S1, -2.0, 5.0);
            if V < -2.0 or else V > 5.0 then
               Ok := False;
            end if;
         end loop;
         Check (Ok, "Next_Uniform stays in [Lo,Hi]");
      end;

      Seed_RNG (S1, 0);
      U1 := Next_Unit (S1);
      Check (U1 >= 0.0 and then U1 < 1.0, "Seed 0 is valid");
   end;

   ---------------------------------------------------------------------
   Section ("3. Stun_Transform: floor, monotone, edges");
   ---------------------------------------------------------------------
   declare
      G : constant Positive_Real := 1.0;
      F0, F1, F2, F3 : Non_Negative;
   begin
      F0 := Stun_Transform (0.0, 0.0, G);
      Check (Near (Real (F0), 0.0), "f_STUN(E=E0) = 0");
      Check (Near (Real (Stun_Transform (5.0, 5.0, G)), 0.0),
             "f_STUN(E=E0=5) = 0");

      --  Clamp when E < E0
      Check (Near (Real (Stun_Transform (-1.0, 0.0, G)), 0.0),
             "E < E0 clamps to 0");
      Check (Near (Real (Stun_Transform (0.0, 10.0, G)), 0.0),
             "E << E0 clamps to 0");

      F1 := Stun_Transform (1.0, 0.0, G);
      F2 := Stun_Transform (2.0, 0.0, G);
      F3 := Stun_Transform (3.0, 0.0, G);
      Check (F1 > 0.0, "f_STUN(1) > 0");
      Check (F2 > F1, "monotone: f(2) > f(1)");
      Check (F3 > F2, "monotone: f(3) > f(2)");
      Check (F3 < 1.0, "f_STUN < 1 for finite E");

      --  Exact value: 1 - exp(-1) ≈ 0.6321205588
      Check (Approx (Real (Stun_Transform (1.0, 0.0, 1.0)),
                     1.0 - 0.36787944117, 1.0E-8),
             "f_STUN(1,0,1) = 1-e^{-1}");
      Check (Approx (Real (Stun_Transform (2.0, 0.0, 1.0)),
                     1.0 - 0.135335283237, 1.0E-8),
             "f_STUN(2,0,1) = 1-e^{-2}");

      --  Gamma scale: larger gamma → smaller transform for same ΔE
      Check (Stun_Transform (1.0, 0.0, 2.0) < Stun_Transform (1.0, 0.0, 1.0),
             "larger gamma softens transform");
      Check (Stun_Transform (1.0, 0.0, 0.5) > Stun_Transform (1.0, 0.0, 1.0),
             "smaller gamma sharpens transform");

      --  Huge barrier → saturates near 1
      Check (Approx (Real (Stun_Transform (1.0E6, 0.0, 1.0)), 1.0, 1.0E-12),
             "huge Delta E saturates to 1");

      --  Tiny excess energy
      Check (Stun_Transform (1.0E-8, 0.0, 1.0) > 0.0,
             "tiny excess > 0");
      Check (Stun_Transform (1.0E-8, 0.0, 1.0) < 1.0E-7,
             "tiny excess small");

      --  Shift invariance in (E - E0)
      Check (Near (Real (Stun_Transform (5.0, 3.0, 1.0)),
                   Real (Stun_Transform (2.0, 0.0, 1.0))),
             "depends only on E-E0");

      --  Several gamma edge cases
      Check (Near (Real (Stun_Transform (0.0, 0.0, 1.0E-6)), 0.0),
             "tiny gamma at E=E0 still 0");
      Check (Stun_Transform (1.0, 0.0, 1.0E-6) > 0.99,
             "tiny gamma + Delta=1 saturates");
      Check (Stun_Transform (1.0, 0.0, 1.0E6) < 1.0E-5,
             "huge gamma almost flat");
   end;

   ---------------------------------------------------------------------
   Section ("4. Metropolis accept: downhill / uphill");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      Always : Boolean := True;
      Prob   : Unit_Interval;
      Acc_Count : Natural := 0;
   begin
      Seed_RNG (S, 1);
      for I in 1 .. 25 loop
         if not Metropolis_Accept_Stun (-0.5, 5.0, S) then
            Always := False;
         end if;
      end loop;
      Check (Always, "always accept downhill Delta_f < 0 (25 trials)");

      Seed_RNG (S, 2);
      Always := True;
      for I in 1 .. 25 loop
         if not Metropolis_Accept_Stun (0.0, 5.0, S) then
            Always := False;
         end if;
      end loop;
      Check (Always, "always accept Delta_f = 0");

      Prob := Metropolis_Accept_Prob (-1.0, 10.0);
      Check (Near (Real (Prob), 1.0), "Prob downhill = 1");
      Prob := Metropolis_Accept_Prob (0.0, 10.0);
      Check (Near (Real (Prob), 1.0), "Prob flat = 1");
      Prob := Metropolis_Accept_Prob (1.0, 0.0);
      Check (Near (Real (Prob), 1.0), "Beta=0 always Prob=1");

      Prob := Metropolis_Accept_Prob (1.0, 1.0);
      Check (Approx (Real (Prob), 0.36787944117, 1.0E-8),
             "Prob(Delta=1, beta=1) = e^{-1}");
      Prob := Metropolis_Accept_Prob (2.0, 1.0);
      Check (Approx (Real (Prob), 0.135335283237, 1.0E-8),
             "Prob(Delta=2, beta=1) = e^{-2}");
      Prob := Metropolis_Accept_Prob (100.0, 10.0);
      Check (Near (Real (Prob), 0.0), "huge uphill Prob ~ 0");

      --  Stochastic uphill: some accepts at moderate beta
      Seed_RNG (S, 99);
      Acc_Count := 0;
      for I in 1 .. 200 loop
         if Metropolis_Accept_Stun (0.2, 1.0, S) then
            Acc_Count := Acc_Count + 1;
         end if;
      end loop;
      Check (Acc_Count > 20 and then Acc_Count < 190,
             "moderate uphill sometimes accepted (count in (20,190))");

      --  Plain energy Metropolis mirrors STUN Metropolis on same Delta
      Seed_RNG (S, 11);
      declare
         S2 : RNG_State;
         A1, A2 : Boolean;
         Match : Boolean := True;
      begin
         Seed_RNG (S2, 11);
         for I in 1 .. 15 loop
            A1 := Metropolis_Accept_Stun (0.3, 2.0, S);
            A2 := Metropolis_Accept_Energy (0.3, 2.0, S2);
            if A1 /= A2 then
               Match := False;
            end if;
         end loop;
         Check (Match, "Accept_Stun and Accept_Energy agree on same stream");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Built-in objectives: known structure");
   ---------------------------------------------------------------------
   declare
      E_L, E_R, E_0, E_M : Real;
   begin
      E_L := Double_Well (-1.0);
      E_R := Double_Well (1.0);
      E_0 := Double_Well (0.0);
      Check (E_L < E_R, "Double_Well: left well deeper than right");
      Check (E_0 > E_R, "Double_Well: barrier above right well");
      Check (E_0 > E_L, "Double_Well: barrier above left well");
      Check (Double_Well (-1.0) < Double_Well (-0.5),
             "Double_Well: -1 better than -0.5");
      Check (Double_Well (1.0) < Double_Well (0.5),
             "Double_Well: +1 better than +0.5");

      Check (Near (Rastrigin_1D (0.0), 0.0, 1.0E-12),
             "Rastrigin global min ~ 0 at x=0");
      Check (Rastrigin_1D (1.0) > 0.0, "Rastrigin(1) > 0");
      Check (Rastrigin_1D (0.5) > Rastrigin_1D (0.0),
             "Rastrigin local worse than 0");

      E_M := Sum_Of_Gaussians (-2.0);
      Check (E_M < Sum_Of_Gaussians (0.0),
             "Gaussians: well at -2 deeper than 0");
      Check (E_M < Sum_Of_Gaussians (2.0),
             "Gaussians: well at -2 deeper than +2");
      Check (Sum_Of_Gaussians (-2.0) < 0.0, "Gaussians negative at wells");
   end;

   ---------------------------------------------------------------------
   Section ("6. Minimize_1D reproducibility");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Gamma => 0.5, Beta => 8.0, Step => 0.35,
         Max_Iters => 800, Use_Gaussian_Step => True);
      R1, R2, R3 : Result;
   begin
      R1 := Minimize_1D (Double_Well'Access, 0.9, Cfg, 42, -3.0, 3.0);
      R2 := Minimize_1D (Double_Well'Access, 0.9, Cfg, 42, -3.0, 3.0);
      R3 := Minimize_1D (Double_Well'Access, 0.9, Cfg, 43, -3.0, 3.0);
      Check (Near (R1.Best_X, R2.Best_X, 0.0), "same seed -> same Best_X");
      Check (Near (R1.Best_E, R2.Best_E, 0.0), "same seed -> same Best_E");
      Check (R1.Iters = R2.Iters, "same seed -> same Iters");
      Check (R1.Iters = Cfg.Max_Iters, "Iters = Max_Iters");
      Check (R1.Best_X /= R3.Best_X or else R1.Best_E /= R3.Best_E,
             "different seeds usually differ (soft)");
   end;

   ---------------------------------------------------------------------
   Section ("7. Double-well: STUN finds global from bad start");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Gamma => 0.4, Beta => 12.0, Step => 0.45,
         Max_Iters => 4_000, Use_Gaussian_Step => True);
      R : Result;
      Ok_Count : Natural := 0;
      Global_E : constant Real := Double_Well (-1.05);
      --  Tolerate finding near the left (global) basin: x < 0 and E close
      --  to the known left-well energy (~ Double_Well(-1) ≈ -0.15).
   begin
      for Seed in 1 .. 12 loop
         R := Minimize_1D
           (Double_Well'Access, 1.0, Cfg, Seed, -3.0, 3.0);
         if R.Best_X < 0.0
           and then R.Best_E < Double_Well (1.0) - 0.05
         then
            Ok_Count := Ok_Count + 1;
         end if;
         Check (R.Best_E <= Double_Well (1.0) + 1.0E-9,
                "seed" & Integer'Image (Seed) &
                ": Best_E <= start-basin energy");
      end loop;
      Check (Ok_Count >= 4,
             "STUN reaches left (global) basin often (>=4/12 seeds)");
      --  One explicit tolerant check from a known good seed
      R := Minimize_1D (Double_Well'Access, 0.95, Cfg, 5, -3.0, 3.0);
      Check (R.Best_E < 0.0 or else R.Best_X < 0.25,
             "tolerant: improved or moved left from bad start");
      Check (Global_E < Double_Well (1.0), "sanity: left energy < right");
   end;

   ---------------------------------------------------------------------
   Section ("8. STUN vs plain Metropolis on tall barrier (soft)");
   ---------------------------------------------------------------------
   declare
      --  Tall barrier (~25): raw Metropolis at β≈2 rarely climbs;
      --  STUN Δf ≤ 1 so accept prob ~ e^{-β} remains usable.
      Cfg : constant Config :=
        (Gamma => 1.0, Beta => 2.0, Step => 0.55,
         Max_Iters => 6_000, Use_Gaussian_Step => True);
      Stun_Escapes : Natural := 0;
      Metro_Escapes : Natural := 0;
      Rs, Rm : Result;
      Right_E : constant Real := Tall_Double_Well (1.0);
   begin
      Check (Tall_Double_Well (0.0) > 20.0, "tall barrier height > 20");
      Check (Tall_Double_Well (-1.0) < Tall_Double_Well (1.0),
             "tall: left deeper than right");
      for Seed in 100 .. 119 loop
         Rs := Minimize_1D
           (Tall_Double_Well'Access, 1.0, Cfg, Seed, -3.0, 3.0);
         Rm := Minimize_1D_Metropolis
           (Tall_Double_Well'Access, 1.0, Cfg, Seed, -3.0, 3.0);
         if Rs.Best_X < 0.0
           and then Rs.Best_E < Right_E - 0.05
         then
            Stun_Escapes := Stun_Escapes + 1;
         end if;
         if Rm.Best_X < 0.0
           and then Rm.Best_E < Right_E - 0.05
         then
            Metro_Escapes := Metro_Escapes + 1;
         end if;
      end loop;
      Check (Stun_Escapes >= Metro_Escapes,
             "STUN escapes >= plain Metropolis (soft statistical)");
      Check (Stun_Escapes >= 3,
             "STUN escapes at least 3/20 seeds on tall barrier");
      Put_Line ("    (STUN escapes=" & Natural'Image (Stun_Escapes)
                & " Metropolis escapes=" & Natural'Image (Metro_Escapes)
                & ")");
   end;

   ---------------------------------------------------------------------
   Section ("9. Quadratic / shifted: finds near optimum");
   ---------------------------------------------------------------------
   declare
      Cfg : Config :=
        (Gamma => 1.0, Beta => 5.0, Step => 0.3,
         Max_Iters => 2_000, Use_Gaussian_Step => True);
      R : Result;
   begin
      R := Minimize_1D (Quadratic'Access, 2.5, Cfg, 7, -5.0, 5.0);
      Check (abs (R.Best_X) < 0.35, "quadratic: Best_X near 0");
      Check (R.Best_E < 0.15, "quadratic: Best_E small");

      R := Minimize_1D (Shifted_Quadratic'Access, 0.0, Cfg, 8, -1.0, 6.0);
      Check (abs (R.Best_X - 3.0) < 0.4, "shifted quad: near x=3");
      Check (R.Best_E < 0.2, "shifted quad: Best_E small");

      Cfg.Use_Gaussian_Step := False;
      R := Minimize_1D (Quadratic'Access, -2.0, Cfg, 9, -5.0, 5.0);
      Check (abs (R.Best_X) < 0.5, "uniform-step quadratic near 0");
   end;

   ---------------------------------------------------------------------
   Section ("10. Rastrigin / Gaussians minimization");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Gamma => 0.6, Beta => 6.0, Step => 0.5,
         Max_Iters => 5_000, Use_Gaussian_Step => True);
      R : Result;
      Hits : Natural := 0;
   begin
      for Seed in 1 .. 8 loop
         R := Minimize_1D
           (Rastrigin_1D'Access, 2.5, Cfg, Seed, -5.5, 5.5);
         Check (R.Best_E < 5.0,
                "Rastrigin seed" & Integer'Image (Seed) &
                ": Best_E < 5");
         if abs (R.Best_X) < 0.75 and then R.Best_E < 1.5 then
            Hits := Hits + 1;
         end if;
      end loop;
      Check (Hits >= 1, "Rastrigin: at least one near-global hit");

      Hits := 0;
      for Seed in 20 .. 27 loop
         R := Minimize_1D
           (Sum_Of_Gaussians'Access, 2.0, Cfg, Seed, -5.0, 5.0);
         Check (R.Best_E < Sum_Of_Gaussians (2.0) + 0.01,
                "Gaussians seed" & Integer'Image (Seed) &
                ": not worse than start well");
         if R.Best_X < -1.0 then
            Hits := Hits + 1;
         end if;
      end loop;
      Check (Hits >= 1, "Gaussians: reached left deep well at least once");
   end;

   ---------------------------------------------------------------------
   Section ("11. Gamma / Beta / Step config variants");
   ---------------------------------------------------------------------
   declare
      Base : constant Config :=
        (Gamma => 1.0, Beta => 3.0, Step => 0.25,
         Max_Iters => 500, Use_Gaussian_Step => True);
      C : Config;
      R : Result;
   begin
      C := Base;
      C.Gamma := 0.1;
      R := Minimize_1D (Double_Well'Access, 0.5, C, 1, -3.0, 3.0);
      Check (R.Iters = 500, "gamma=0.1 runs Max_Iters");
      Check (R.Best_E <= Double_Well (0.5) + 1.0E-9,
             "gamma=0.1 Best_E <= start");

      C := Base;
      C.Gamma := 10.0;
      R := Minimize_1D (Double_Well'Access, 0.5, C, 1, -3.0, 3.0);
      Check (R.Best_E <= Double_Well (0.5) + 1.0E-9,
             "gamma=10 Best_E <= start");

      C := Base;
      C.Beta := 0.0;
      R := Minimize_1D (Quadratic'Access, 1.0, C, 2, -4.0, 4.0);
      Check (R.Iters = 500, "beta=0 completes");

      C := Base;
      C.Beta := 50.0;
      R := Minimize_1D (Double_Well'Access, 1.0, C, 3, -3.0, 3.0);
      Check (R.Best_E <= Double_Well (1.0) + 1.0E-9,
             "high beta Best_E <= start");

      C := Base;
      C.Step := 0.05;
      R := Minimize_1D (Quadratic'Access, 1.0, C, 4, -2.0, 2.0);
      Check (R.Best_X >= -2.0 and then R.Best_X <= 2.0,
             "small step stays in bounds");

      C := Base;
      C.Step := 1.5;
      R := Minimize_1D (Quadratic'Access, 0.0, C, 5, -2.0, 2.0);
      Check (R.Best_X >= -2.0 and then R.Best_X <= 2.0,
             "large step clamped to bounds");

      C := Base;
      C.Max_Iters := 1;
      R := Minimize_1D (Quadratic'Access, 1.0, C, 6, -5.0, 5.0);
      Check (R.Iters = 1, "Max_Iters=1");

      C := Base;
      C.Use_Gaussian_Step := False;
      R := Minimize_1D_Metropolis
        (Quadratic'Access, 1.5, C, 7, -5.0, 5.0);
      Check (R.Best_E <= 1.5 * 1.5 + 1.0E-9,
             "plain Metropolis uniform step improves or equals");
   end;

   ---------------------------------------------------------------------
   Section ("12. Bounds clamping / Best never worse than start");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Gamma => 0.5, Beta => 4.0, Step => 0.8,
         Max_Iters => 300, Use_Gaussian_Step => True);
      R : Result;
      Start_E : Real;
   begin
      for Seed in 1 .. 10 loop
         Start_E := Double_Well (0.8);
         R := Minimize_1D
           (Double_Well'Access, 0.8, Cfg, Seed, -1.5, 1.5);
         Check (R.Best_X >= -1.5 and then R.Best_X <= 1.5,
                "bound seed" & Integer'Image (Seed) & ": x in range");
         Check (R.Best_E <= Start_E + 1.0E-9,
                "bound seed" & Integer'Image (Seed) &
                ": Best_E <= E(start)");
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("13. Transform grid / Metropolis Prob grid");
   ---------------------------------------------------------------------
   declare
      Prev : Non_Negative := 0.0;
      Cur  : Non_Negative;
      Mono : Boolean := True;
      P    : Unit_Interval;
   begin
      for K in 0 .. 20 loop
         Cur := Stun_Transform (Real (K) * 0.25, 0.0, 1.0);
         if K > 0 and then Cur < Prev then
            Mono := False;
         end if;
         Prev := Cur;
      end loop;
      Check (Mono, "f_STUN monotone on grid 0..5 step 0.25");

      for K in 0 .. 9 loop
         Cur := Stun_Transform (1.0, 0.0, Positive_Real (0.5 + Real (K)));
         Check (Cur < 1.0, "gamma grid f < 1 (k=" & Integer'Image (K) & ")");
      end loop;

      for K in 0 .. 9 loop
         P := Metropolis_Accept_Prob (Real (K) * 0.1, 2.0);
         Check (P >= 0.0 and then P <= 1.0,
                "Prob in [0,1] k=" & Integer'Image (K));
      end loop;

      --  Decreasing accept prob as Delta grows
      declare
         P0 : constant Unit_Interval := Metropolis_Accept_Prob (0.1, 3.0);
         P1 : constant Unit_Interval := Metropolis_Accept_Prob (0.5, 3.0);
         P2 : constant Unit_Interval := Metropolis_Accept_Prob (1.5, 3.0);
      begin
         Check (P0 > P1 and then P1 > P2,
                "accept Prob decreases with Delta_f");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Default Config / Result fields");
   ---------------------------------------------------------------------
   declare
      C : Config;
      R : Result;
   begin
      Check (Near (C.Gamma, 1.0), "default Gamma is 1");
      Check (Near (C.Beta, 5.0), "default Beta is 5");
      Check (Near (C.Step, 0.4), "default Step is 0.4");
      Check (C.Max_Iters = 5_000, "default Max_Iters is 5000");
      Check (C.Use_Gaussian_Step, "default Use_Gaussian_Step True");
      Check (Near (R.Best_X, 0.0), "default Result Best_X");
      Check (Near (R.Best_E, 0.0), "default Result Best_E");
      Check (R.Iters = 0, "default Result Iters");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("================================");
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("================================");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
