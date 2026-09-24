--  Standalone test suite for Simulated_Annealing (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Simulated_Annealing; use Simulated_Annealing;

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
   Put_Line ("Simulated_Annealing test suite");
   Put_Line ("==============================");

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

      Seed_RNG (S1, 17);
      declare
         K : Natural;
         Ok : Boolean := True;
         Saw_Lo, Saw_Hi : Boolean := False;
      begin
         for I in 1 .. 200 loop
            K := Next_Natural (S1, 2, 5);
            if K < 2 or else K > 5 then
               Ok := False;
            end if;
            if K = 2 then
               Saw_Lo := True;
            end if;
            if K = 5 then
               Saw_Hi := True;
            end if;
         end loop;
         Check (Ok, "Next_Natural stays in [2,5]");
         Check (Saw_Lo and Saw_Hi, "Next_Natural hits endpoints");
         Check (Next_Natural (S1, 9, 9) = 9, "Next_Natural Lo=Hi");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("3. Accept_Probability: downhill always 1");
   ---------------------------------------------------------------------
   declare
      P : Unit_Interval;
   begin
      P := Accept_Probability (-1.0, 1.0);
      Check (Near (Real (P), 1.0), "Delta_E < 0 => P=1");
      P := Accept_Probability (0.0, 1.0);
      Check (Near (Real (P), 1.0), "Delta_E = 0 => P=1");
      P := Accept_Probability (-100.0, 0.01);
      Check (Near (Real (P), 1.0), "large downhill => P=1");
      P := Accept_Probability (-0.001, 1000.0);
      Check (Near (Real (P), 1.0), "tiny downhill => P=1");
      P := Accept_Probability (0.0, 0.0);
      Check (Near (Real (P), 1.0), "Delta=0 T=0 => P=1");
      P := Accept_Probability (-5.0, 0.0);
      Check (Near (Real (P), 1.0), "downhill T=0 => P=1");
   end;

   ---------------------------------------------------------------------
   Section ("4. Accept_Probability: uphill / edges");
   ---------------------------------------------------------------------
   declare
      P : Unit_Interval;
   begin
      P := Accept_Probability (1.0, 1.0);
      Check (Approx (Real (P), 0.36787944117, 1.0E-8),
             "P(Delta=1,T=1) = e^{-1}");
      P := Accept_Probability (2.0, 1.0);
      Check (Approx (Real (P), 0.135335283237, 1.0E-8),
             "P(Delta=2,T=1) = e^{-2}");
      P := Accept_Probability (1.0, 2.0);
      Check (Approx (Real (P), 0.60653065971, 1.0E-8),
             "P(Delta=1,T=2) = e^{-0.5}");
      P := Accept_Probability (100.0, 0.1);
      Check (Near (Real (P), 0.0), "huge uphill low T => ~0");
      P := Accept_Probability (1.0, 0.0);
      Check (Near (Real (P), 0.0), "uphill T=0 => 0 (greedy)");
      P := Accept_Probability (1.0E-9, 1.0E9);
      Check (P > 0.999, "tiny uphill huge T => ~1");

      --  High T accepts uphill often (probability near 1)
      P := Accept_Probability (0.1, 100.0);
      Check (P > 0.99, "high T: small uphill P > 0.99");
      P := Accept_Probability (1.0, 100.0);
      Check (P > 0.98, "high T: Delta=1 P > 0.98");

      --  Low T rarely accepts large uphill
      P := Accept_Probability (1.0, 0.1);
      Check (P < 0.00005, "low T: Delta=1 P very small");
      P := Accept_Probability (0.5, 0.05);
      Check (P < 1.0E-4, "very low T: moderate uphill rare");

      --  Monotone in Delta and T
      Check (Accept_Probability (0.1, 1.0) >
             Accept_Probability (0.5, 1.0),
             "P decreases as Delta grows");
      Check (Accept_Probability (1.0, 2.0) >
             Accept_Probability (1.0, 1.0),
             "P increases as T grows");
      Check (Accept_Probability (1.0, 5.0) >
             Accept_Probability (1.0, 2.0),
             "P increases further with T");
   end;

   ---------------------------------------------------------------------
   Section ("5. Metropolis_Accept stochastic behaviour");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      Always : Boolean := True;
      Acc_Count : Natural := 0;
   begin
      Seed_RNG (S, 1);
      for I in 1 .. 30 loop
         if not Metropolis_Accept (-0.5, 5.0, S) then
            Always := False;
         end if;
      end loop;
      Check (Always, "always accept downhill Delta_E < 0 (30 trials)");

      Seed_RNG (S, 2);
      Always := True;
      for I in 1 .. 30 loop
         if not Metropolis_Accept (0.0, 5.0, S) then
            Always := False;
         end if;
      end loop;
      Check (Always, "always accept Delta_E = 0");

      --  High T: accept uphill often
      Seed_RNG (S, 99);
      Acc_Count := 0;
      for I in 1 .. 200 loop
         if Metropolis_Accept (0.5, 50.0, S) then
            Acc_Count := Acc_Count + 1;
         end if;
      end loop;
      Check (Acc_Count > 150, "high T accepts uphill often (>150/200)");

      --  Low T: rarely accept large uphill
      Seed_RNG (S, 100);
      Acc_Count := 0;
      for I in 1 .. 200 loop
         if Metropolis_Accept (2.0, 0.05, S) then
            Acc_Count := Acc_Count + 1;
         end if;
      end loop;
      Check (Acc_Count < 5, "low T rarely accepts large uphill (<5/200)");

      --  Moderate: some accepts
      Seed_RNG (S, 77);
      Acc_Count := 0;
      for I in 1 .. 200 loop
         if Metropolis_Accept (0.5, 1.0, S) then
            Acc_Count := Acc_Count + 1;
         end if;
      end loop;
      Check (Acc_Count > 20 and then Acc_Count < 180,
             "moderate T: uphill sometimes accepted");

      --  Reproducibility of accept stream
      declare
         S_A, S_B : RNG_State;
         Match : Boolean := True;
      begin
         Seed_RNG (S_A, 33);
         Seed_RNG (S_B, 33);
         for I in 1 .. 40 loop
            if Metropolis_Accept (0.3, 1.5, S_A) /=
               Metropolis_Accept (0.3, 1.5, S_B)
            then
               Match := False;
            end if;
         end loop;
         Check (Match, "Metropolis_Accept reproducible with seed");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Cooling schedules");
   ---------------------------------------------------------------------
   declare
      T0 : constant Non_Negative := 10.0;
      T  : Non_Negative;
      T2 : Non_Negative;
   begin
      T := Cool_Geometric (T0, 0.9);
      Check (Approx (Real (T), 9.0, 1.0E-12), "Cool_Geometric 0.9*10=9");
      T := Cool_Geometric (T0, 0.5);
      Check (Approx (Real (T), 5.0, 1.0E-12), "Cool_Geometric 0.5*10=5");
      T := Cool_Geometric (T0, 1.0);
      Check (Approx (Real (T), 10.0, 1.0E-12), "Alpha=1 leaves T");
      T := Cool_Geometric (T0, 0.0);
      Check (Near (Real (T), 0.0), "Alpha=0 -> T=0");

      --  Repeated geometric cooling decreases
      T := 8.0;
      for I in 1 .. 5 loop
         T2 := Cool_Geometric (T, 0.8);
         Check (T2 < T, "geometric step decreases T (" &
                Integer'Image (I) & ")");
         T := T2;
      end loop;
      Check (T < 3.0, "five 0.8 cools from 8 to <3");

      --  Linear schedule
      T := Cool_Linear (10.0, 10.0, 0.0, 0.0);
      Check (Approx (Real (T), 10.0, 1.0E-12), "linear progress=0 -> T0");
      T := Cool_Linear (10.0, 10.0, 0.0, 1.0);
      Check (Near (Real (T), 0.0), "linear progress=1 -> T_Min");
      T := Cool_Linear (10.0, 10.0, 0.0, 0.5);
      Check (Approx (Real (T), 5.0, 1.0E-12), "linear progress=0.5 midpoint");
      T := Cool_Linear (7.0, 10.0, 2.0, 0.25);
      Check (Approx (Real (T), 8.0, 1.0E-12),
             "linear 10->2 at 0.25 = 8");

      --  Sequence of linear temps decreases with progress
      declare
         Prev : Non_Negative := Cool_Linear (0.0, 5.0, 1.0, 0.0);
         Cur  : Non_Negative;
         Dec  : Boolean := True;
      begin
         for K in 1 .. 10 loop
            Cur := Cool_Linear
              (0.0, 5.0, 1.0,
               Unit_Interval (Real (K) / 10.0));
            if Cur > Prev then
               Dec := False;
            end if;
            Prev := Cur;
         end loop;
         Check (Dec, "linear schedule nonincreasing in progress");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Built-in objectives");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (Quadratic (0.0), 0.0), "Quadratic(0)=0");
      Check (Near (Quadratic (2.0), 4.0), "Quadratic(2)=4");
      Check (Near (Quadratic (-3.0), 9.0), "Quadratic(-3)=9");
      Check (Quadratic (1.0) < Quadratic (2.0), "Quadratic monotone |x|");

      Check (Near (Shifted_Quadratic (3.0), 0.0), "Shifted_Q(3)=0");
      Check (Near (Shifted_Quadratic (5.0), 4.0), "Shifted_Q(5)=4");
      Check (Shifted_Quadratic (3.0) < Shifted_Quadratic (0.0),
             "Shifted_Q min at 3");

      Check (Rastrigin_1D (0.0) >= 0.0, "Rastrigin(0) >= 0");
      Check (Near (Rastrigin_1D (0.0), 0.0, 1.0E-12), "Rastrigin(0)=0");
      Check (Rastrigin_1D (1.0) > 0.0, "Rastrigin(1) > 0");
      Check (Rastrigin_1D (0.5) > Rastrigin_1D (0.0),
             "Rastrigin local > global");

      --  Double well: deeper near -1 than +1
      Check (Double_Well (-1.0) < Double_Well (1.0),
             "Double_Well deeper at -1 than +1");
      Check (Double_Well (-1.0) < Double_Well (0.0),
             "Double_Well(-1) < barrier at 0");
      Check (Double_Well (1.0) < Double_Well (0.0),
             "Double_Well(+1) is a local min vs 0");
   end;

   ---------------------------------------------------------------------
   Section ("8. Minimize_1D quadratic / shifted");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
   begin
      Cfg.T0 := 5.0;
      Cfg.T_Min := 1.0E-5;
      Cfg.Alpha := 0.92;
      Cfg.Step := 0.35;
      Cfg.Max_Iters := 6_000;
      Cfg.Cool_Every := 15;
      Cfg.Use_Gaussian_Step := True;

      R := Minimize_1D (Quadratic'Access, 4.0, Cfg, 42, -10.0, 10.0);
      Check (abs (R.Best_X) < 0.25, "Quadratic finds near 0 (X)");
      Check (R.Best_E < 0.1, "Quadratic finds near 0 (E)");
      Check (R.Iters > 0, "Quadratic ran some iters");
      Check (R.Final_T <= Cfg.T_Min or else R.Iters = Cfg.Max_Iters,
             "stopped by T_Min or Max_Iters");

      R := Minimize_1D
        (Shifted_Quadratic'Access, 0.0, Cfg, 7, -5.0, 10.0);
      Check (abs (R.Best_X - 3.0) < 0.3, "Shifted_Q finds near 3");
      Check (R.Best_E < 0.15, "Shifted_Q Best_E small");
   end;

   ---------------------------------------------------------------------
   Section ("9. Minimize_1D double-well / Rastrigin");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
   begin
      Cfg.T0 := 8.0;
      Cfg.T_Min := 1.0E-4;
      Cfg.Alpha := 0.97;
      Cfg.Step := 0.25;
      Cfg.Max_Iters := 12_000;
      Cfg.Cool_Every := 25;
      Cfg.Use_Gaussian_Step := True;

      --  Start in shallow well (+1); hope to find deeper near -1
      R := Minimize_1D (Double_Well'Access, 1.0, Cfg, 123, -3.0, 3.0);
      Check (R.Best_E < Double_Well (1.0),
             "Double_Well improved on start");
      Check (R.Best_X < 0.0 or else R.Best_E < Double_Well (0.5),
             "Double_Well found left basin or good energy");
      Check (R.Best_E < 0.0, "Double_Well Best_E near global (<0)");

      Cfg.T0 := 10.0;
      Cfg.Alpha := 0.96;
      Cfg.Step := 0.3;
      Cfg.Max_Iters := 15_000;
      R := Minimize_1D (Rastrigin_1D'Access, 2.5, Cfg, 55, -5.5, 5.5);
      Check (abs (R.Best_X) < 0.5, "Rastrigin finds near 0");
      Check (R.Best_E < 2.0, "Rastrigin Best_E modest");
   end;

   ---------------------------------------------------------------------
   Section ("10. Seeded reproducibility");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R1, R2, R3 : Result;
   begin
      Cfg.T0 := 3.0;
      Cfg.T_Min := 1.0E-3;
      Cfg.Alpha := 0.9;
      Cfg.Step := 0.4;
      Cfg.Max_Iters := 2_000;
      Cfg.Cool_Every := 10;
      Cfg.Use_Gaussian_Step := False;

      R1 := Minimize_1D (Quadratic'Access, 2.0, Cfg, 999, -8.0, 8.0);
      R2 := Minimize_1D (Quadratic'Access, 2.0, Cfg, 999, -8.0, 8.0);
      R3 := Minimize_1D (Quadratic'Access, 2.0, Cfg, 1000, -8.0, 8.0);
      Check (Near (R1.Best_X, R2.Best_X, 0.0), "same seed -> same Best_X");
      Check (Near (R1.Best_E, R2.Best_E, 0.0), "same seed -> same Best_E");
      Check (R1.Iters = R2.Iters, "same seed -> same Iters");
      Check (R1.Accept_Count = R2.Accept_Count,
             "same seed -> same Accept_Count");
      Check (not Near (R1.Best_X, R3.Best_X, 0.0)
             or else R1.Accept_Count /= R3.Accept_Count,
             "different seed usually differs");
   end;

   ---------------------------------------------------------------------
   Section ("11. Linear cooling Minimize_1D");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
   begin
      Cfg.T0 := 6.0;
      Cfg.T_Min := 1.0E-3;
      Cfg.Alpha := 0.95;  -- unused for Linear
      Cfg.Step := 0.3;
      Cfg.Max_Iters := 4_000;
      Cfg.Cool_Every := 20;
      Cfg.Kind := Linear;
      Cfg.Use_Gaussian_Step := True;

      R := Minimize_1D (Quadratic'Access, -3.0, Cfg, 21, -10.0, 10.0);
      Check (abs (R.Best_X) < 0.35, "Linear cool Quadratic near 0");
      Check (R.Best_E < 0.15, "Linear cool Quadratic Best_E");
      Check (R.Final_T <= Cfg.T0, "Final_T <= T0");
      Check (Cfg.Kind = Linear, "Cfg Kind is Linear");
      Check (R.Iters > 0, "Linear cool ran iters");
   end;

   ---------------------------------------------------------------------
   Section ("12. Schedule edge cases / Config defaults");
   ---------------------------------------------------------------------
   declare
      C : Config;
      R : Result;
      Cfg : Config;
   begin
      Check (Near (C.T0, 10.0), "default T0 is 10");
      Check (Near (C.T_Min, 1.0E-4), "default T_Min");
      Check (Near (Real (C.Alpha), 0.95), "default Alpha 0.95");
      Check (Near (C.Step, 0.4), "default Step 0.4");
      Check (C.Max_Iters = 8_000, "default Max_Iters 8000");
      Check (C.Cool_Every = 20, "default Cool_Every 20");
      Check (C.Kind = Geometric, "default Kind Geometric");
      Check (C.Use_Gaussian_Step, "default Gaussian True");
      Check (Near (R.Best_X, 0.0), "default Result Best_X");
      Check (Near (R.Best_E, 0.0), "default Result Best_E");
      Check (R.Iters = 0, "default Result Iters");
      Check (R.Accept_Count = 0, "default Result Accept_Count");

      --  Fast cool stops early
      Cfg.T0 := 1.0;
      Cfg.T_Min := 0.5;
      Cfg.Alpha := 0.5;
      Cfg.Step := 0.2;
      Cfg.Max_Iters := 10_000;
      Cfg.Cool_Every := 1;
      R := Minimize_1D (Quadratic'Access, 1.0, Cfg, 5, -5.0, 5.0);
      Check (R.Iters < 50, "aggressive cool stops well before Max_Iters");
      Check (R.Final_T <= Cfg.T_Min, "Final_T <= T_Min after stop");

      --  Alpha near 1 cools slowly (more iters before T_Min)
      Cfg.Alpha := 0.999;
      Cfg.T0 := 1.0;
      Cfg.T_Min := 0.5;
      Cfg.Cool_Every := 1;
      Cfg.Max_Iters := 10_000;
      R := Minimize_1D (Quadratic'Access, 1.0, Cfg, 5, -5.0, 5.0);
      Check (R.Iters > 100, "slow cool takes many steps to T_Min");
   end;

   ---------------------------------------------------------------------
   Section ("13. Bounds clamping / uniform steps");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
   begin
      Cfg.T0 := 2.0;
      Cfg.T_Min := 1.0E-3;
      Cfg.Alpha := 0.9;
      Cfg.Step := 1.0;
      Cfg.Max_Iters := 3_000;
      Cfg.Cool_Every := 10;
      Cfg.Use_Gaussian_Step := False;

      R := Minimize_1D (Quadratic'Access, 0.5, Cfg, 11, -1.0, 1.0);
      Check (R.Best_X >= -1.0 and then R.Best_X <= 1.0,
             "Best_X stays in bounds");
      Check (abs (R.Best_X) < 0.4, "bounded Quadratic near 0");
   end;

   ---------------------------------------------------------------------
   Section ("14. TSP-lite combinatorial demo");
   ---------------------------------------------------------------------
   declare
      --  4 cities on a square: optimal tour length 4
      D : Dist_Matrix (1 .. 4, 1 .. 4);
      Start : Tour (1 .. 4);
      Cfg : Config;
      TR  : TSP_Result;
      L0  : Non_Negative;
   begin
      for I in 1 .. 4 loop
         for J in 1 .. 4 loop
            D (City_Index (I), City_Index (J)) := 0.0;
         end loop;
      end loop;
      --  Square side 1, diagonal sqrt(2)
      D (1, 2) := 1.0; D (2, 1) := 1.0;
      D (2, 3) := 1.0; D (3, 2) := 1.0;
      D (3, 4) := 1.0; D (4, 3) := 1.0;
      D (4, 1) := 1.0; D (1, 4) := 1.0;
      D (1, 3) := 1.41421356237; D (3, 1) := 1.41421356237;
      D (2, 4) := 1.41421356237; D (4, 2) := 1.41421356237;

      Start := [1, 2, 4, 3];  --  crossed / suboptimal
      L0 := Tour_Length (Start, D);
      Check (L0 > 4.0, "suboptimal start tour > 4");
      declare
         Opt : constant Tour (1 .. 4) := [1, 2, 3, 4];
      begin
         Check (Approx (Real (Tour_Length (Opt, D)), 4.0, 1.0E-6),
                "optimal square tour length 4");
      end;

      Cfg.T0 := 5.0;
      Cfg.T_Min := 1.0E-4;
      Cfg.Alpha := 0.95;
      Cfg.Max_Iters := 5_000;
      Cfg.Cool_Every := 10;
      TR := Minimize_TSP (D, Cfg, 42, Start);
      Check (TR.Best_Length <= L0, "TSP improved or equalled start");
      Check (Approx (Real (TR.Best_Length), 4.0, 0.05)
             or else TR.Best_Length < L0,
             "TSP found near-optimal or improved");
      Check (TR.N = 4, "TSP N=4");
      Check (TR.Iters > 0, "TSP ran");
      Check (TR.Final_T <= Cfg.T0, "TSP Final_T <= T0");

      --  Reproducibility
      declare
         TR2 : TSP_Result;
      begin
         TR2 := Minimize_TSP (D, Cfg, 42, Start);
         Check (Near (Real (TR.Best_Length), Real (TR2.Best_Length), 0.0),
                "TSP same seed -> same Best_Length");
         Check (TR.Iters = TR2.Iters, "TSP same seed -> same Iters");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Extra Accept_Probability / Cool grid");
   ---------------------------------------------------------------------
   declare
   begin
      for K in 1 .. 10 loop
         declare
            De : constant Real := Real (K) * 0.1;
            P_Hi : constant Unit_Interval :=
              Accept_Probability (De, 20.0);
            P_Lo : constant Unit_Interval :=
              Accept_Probability (De, 0.2);
         begin
            Check (P_Hi > P_Lo,
                   "grid: high T > low T for Delta=" &
                   Integer'Image (K));
         end;
      end loop;

      for K in 1 .. 8 loop
         declare
            A : constant Unit_Interval :=
              Unit_Interval (0.5 + Real (K) * 0.05);
            T : constant Non_Negative :=
              Cool_Geometric (4.0, A);
         begin
            Check (T < 4.0 or else A = 1.0,
                   "grid cool Alpha decreases or 1");
            Check (T >= 0.0, "grid cool nonnegative");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("16. Best-so-far tracking");
   ---------------------------------------------------------------------
   declare
      Cfg : Config;
      R   : Result;
   begin
      Cfg.T0 := 0.01;  --  very cold: mostly downhill / greedy
      Cfg.T_Min := 1.0E-6;
      Cfg.Alpha := 0.9;
      Cfg.Step := 0.15;
      Cfg.Max_Iters := 2_000;
      Cfg.Cool_Every := 50;
      R := Minimize_1D (Quadratic'Access, 5.0, Cfg, 8, -20.0, 20.0);
      Check (R.Best_E <= Quadratic (5.0), "Best_E never worse than start");
      Check (R.Best_E <= R.Best_X * R.Best_X + 1.0E-9,
             "Best_E matches Best_X on Quadratic");
      Check (R.Accept_Count <= R.Iters, "Accept_Count <= Iters");
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
