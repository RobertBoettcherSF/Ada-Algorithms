--  Standalone test suite for Random_Search (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Random_Search; use Random_Search;

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
   Put_Line ("Random_Search test suite");
   Put_Line ("========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp helpers");
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
      Check (Clamp (0.5, 0.0, 1.0) = 0.5, "Clamp interior");
      Check (Clamp (-1.0, 0.0, 1.0) = 0.0, "Clamp below");
      Check (Clamp (2.0, 0.0, 1.0) = 1.0, "Clamp above");
      Check (Clamp (0.0, 0.0, 1.0) = 0.0, "Clamp at Lo");
      Check (Clamp (1.0, 0.0, 1.0) = 1.0, "Clamp at Hi");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG determinism / range");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      All_In     : Boolean := True;
      Saw_Diff   : Boolean := False;
      X          : Real;
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
      for I in 1 .. 40 loop
         U1 := Next_Unit (S1);
         U2 := Next_Unit (S2);
         if U1 /= U2 then
            Saw_Diff := True;
         end if;
         if U1 < 0.0 or else U1 >= 1.0 then
            All_In := False;
         end if;
      end loop;
      Check (not Saw_Diff, "same seed stream matches for 40 draws");
      Check (All_In, "40 units stay in [0,1)");

      Seed_RNG (S1, 0);
      U1 := Next_Unit (S1);
      Check (U1 >= 0.0 and then U1 < 1.0, "Seed 0 still valid");

      Seed_RNG (S1, 123);
      X := Next_Uniform (S1, -2.0, 5.0);
      Check (X >= -2.0 and then X <= 5.0, "Next_Uniform in [Lo,Hi]");
      Seed_RNG (S1, 123);
      Check (Approx (Next_Uniform (S1, 3.0, 3.0), 3.0),
             "Next_Uniform Lo=Hi");
   end;

   ---------------------------------------------------------------------
   Section ("3. Sample_Uniform / Sample_Log_Uniform");
   ---------------------------------------------------------------------
   declare
      S        : RNG_State;
      X        : Real;
      All_In   : Boolean := True;
      Min_X    : Real := Real'Last;
      Max_X    : Real := Real'First;
      Log_Ok   : Boolean := True;
      Saw_Low  : Boolean := False;
      Saw_High : Boolean := False;
   begin
      Seed_RNG (S, 11);
      for I in 1 .. 50 loop
         X := Sample_Uniform (S, -1.0, 1.0);
         if X < -1.0 or else X > 1.0 then
            All_In := False;
         end if;
         if X < Min_X then
            Min_X := X;
         end if;
         if X > Max_X then
            Max_X := X;
         end if;
      end loop;
      Check (All_In, "50 uniform samples in [-1,1]");
      Check (Min_X < -0.2, "uniform covers left side");
      Check (Max_X > 0.2, "uniform covers right side");

      Seed_RNG (S, 21);
      for I in 1 .. 80 loop
         X := Sample_Log_Uniform (S, 1.0E-4, 1.0E2);
         if X < 1.0E-4 or else X > 1.0E2 then
            Log_Ok := False;
         end if;
         if X < 0.01 then
            Saw_Low := True;
         end if;
         if X > 1.0 then
            Saw_High := True;
         end if;
      end loop;
      Check (Log_Ok, "80 log-uniform samples in [1e-4, 100]");
      Check (Saw_Low, "log-uniform hits small scales");
      Check (Saw_High, "log-uniform hits large scales");

      Seed_RNG (S, 3);
      X := Sample_Log_Uniform (S, 2.0, 2.0);
      Check (Approx (X, 2.0, 1.0E-9), "log-uniform Lo=Hi");
   end;

   ---------------------------------------------------------------------
   Section ("4. Built-in objectives");
   ---------------------------------------------------------------------
   declare
      P0 : constant Point (1 .. 2) := [0.0, 0.0];
      P1 : constant Point (1 .. 2) := [0.75, 9.0];
      P2 : constant Point (1 .. 3) := [1.0, 2.0, 3.0];
      P_Far : constant Point (1 .. 2) := [0.0, 100.0];
      P_One : constant Point (1 .. 2) := [1.0, 1.0];
   begin
      Check (Approx (Quadratic_1D (0.0), 0.0), "Quadratic_1D(0)=0");
      Check (Approx (Quadratic_1D (2.0), 4.0), "Quadratic_1D(2)=4");
      Check (Approx (Quadratic_1D (-3.0), 9.0), "Quadratic_1D(-3)=9");
      Check (Approx (Shifted_Quadratic_1D (3.0), 0.0),
             "Shifted_Quadratic_1D(3)=0");
      Check (Approx (Shifted_Quadratic_1D (0.0), 9.0),
             "Shifted_Quadratic_1D(0)=9");
      Check (Approx (Needle_1D (0.7), 0.0), "Needle_1D(0.7)=0");
      Check (Needle_1D (0.0) > Needle_1D (0.7), "Needle_1D worse at 0");
      Check (Approx (Sphere_ND (P0), 0.0), "Sphere at origin 0");
      Check (Approx (Sphere_ND (P2), 14.0), "Sphere(1,2,3)=14");
      Check (Approx (Needle_Haystack_2D (P1), 0.0),
             "Needle_Haystack at x=0.75 is 0");
      Check (Needle_Haystack_2D (P_Far) > Needle_Haystack_2D (P1),
             "Needle_Haystack ignores y");
      Check (Approx (Rastrigin_2D (P0), 0.0, 1.0E-9),
             "Rastrigin_2D(0,0)≈0");
      Check (Rastrigin_2D (P_One) > 0.0,
             "Rastrigin_2D away from 0 is positive");
      Check (Approx (Neg_Sphere_ND (P0), 0.0), "Neg_Sphere at 0");
      Check (Neg_Sphere_ND (P_One) < 0.0, "Neg_Sphere away negative");
      Check (Approx (Log10_Squared_1D (1.0), 0.0), "Log10_Squared(1)=0");
      Check (Log10_Squared_1D (10.0) > 0.9, "Log10_Squared(10)≈1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Search_1D: quadratic near-min");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Trials => 500, Kind => Uniform, Sense_Flag => Minimize_Sense);
      R   : Result;
   begin
      R := Search_1D (Quadratic_1D'Access, -5.0, 5.0, Cfg, 42);
      Check (R.Trials_Run = 500, "1D trials_run=500");
      Check (R.Dim = 1, "1D dim=1");
      Check (abs (R.Best_X (1)) < 0.3, "1D finds x near 0");
      Check (R.Best_F < 0.1, "1D Best_F small");
      Check (R.Best_Trial >= 1 and then R.Best_Trial <= 500,
             "1D Best_Trial in range");

      R := Search_1D
        (Shifted_Quadratic_1D'Access, -2.0, 8.0, Cfg, 7);
      Check (abs (R.Best_X (1) - 3.0) < 0.35, "1D finds x near 3");
      Check (R.Best_F < 0.15, "shifted Best_F small");
   end;

   ---------------------------------------------------------------------
   Section ("6. Best improves (non-increasing) over iterations");
   ---------------------------------------------------------------------
   declare
      Cfg_Small : constant Config :=
        (Trials => 10, Kind => Uniform, Sense_Flag => Minimize_Sense);
      Cfg_Big   : constant Config :=
        (Trials => 200, Kind => Uniform, Sense_Flag => Minimize_Sense);
      R1, R2    : Result;
   begin
      R1 := Search_1D (Quadratic_1D'Access, -4.0, 4.0, Cfg_Small, 99);
      R2 := Search_1D (Quadratic_1D'Access, -4.0, 4.0, Cfg_Big, 99);
      Check (R2.Best_F <= R1.Best_F + 1.0E-12,
             "more trials => best_f <= fewer trials (same seed prefix)");
      Check (R2.Trials_Run = 200, "big run trials");
      Check (R1.Trials_Run = 10, "small run trials");
      Check (R2.Best_Trial >= 1, "best trial positive");
   end;

   ---------------------------------------------------------------------
   Section ("7. Seeded reproducibility");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Trials => 80, Kind => Uniform, Sense_Flag => Minimize_Sense);
      R1, R2, R3 : Result;
      B : constant Bounds (1 .. 2) :=
        [1 => (Lo => -2.0, Hi => 2.0),
         2 => (Lo => -2.0, Hi => 2.0)];
   begin
      R1 := Search_ND (Sphere_ND'Access, B, Cfg, 12345);
      R2 := Search_ND (Sphere_ND'Access, B, Cfg, 12345);
      R3 := Search_ND (Sphere_ND'Access, B, Cfg, 54321);
      Check (Approx (R1.Best_F, R2.Best_F, 0.0),
             "same seed identical Best_F");
      Check (Approx (R1.Best_X (1), R2.Best_X (1), 0.0),
             "same seed identical Best_X1");
      Check (Approx (R1.Best_X (2), R2.Best_X (2), 0.0),
             "same seed identical Best_X2");
      Check (R1.Best_Trial = R2.Best_Trial, "same seed Best_Trial");
      Check (R1.Best_F /= R3.Best_F or else
             R1.Best_X (1) /= R3.Best_X (1),
             "different seeds typically differ");
   end;

   ---------------------------------------------------------------------
   Section ("8. Empty / zero trials edge");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Trials => 0, Kind => Uniform, Sense_Flag => Minimize_Sense);
      R   : Result;
      B   : constant Bounds (1 .. 2) :=
        [1 => (-1.0, 1.0), 2 => (-1.0, 1.0)];
   begin
      R := Search_1D (Quadratic_1D'Access, -1.0, 1.0, Cfg, 1);
      Check (R.Trials_Run = 0, "1D zero trials_run");
      Check (R.Best_Trial = 0, "1D zero best_trial");
      Check (R.Dim = 1, "1D zero still dim=1");

      R := Search_ND (Sphere_ND'Access, B, Cfg, 1);
      Check (R.Trials_Run = 0, "ND zero trials_run");
      Check (R.Best_Trial = 0, "ND zero best_trial");
      Check (R.Dim = 2, "ND zero dim=2");

      R := Minimize (Sphere_ND'Access, B, 0, 1);
      Check (R.Trials_Run = 0, "Minimize zero trials");
   end;

   ---------------------------------------------------------------------
   Section ("9. Bound clamping of samples");
   ---------------------------------------------------------------------
   declare
      S      : RNG_State;
      B      : constant Bounds (1 .. 3) :=
        [1 => (0.0, 1.0),
         2 => (-5.0, -4.0),
         3 => (10.0, 10.5)];
      P      : Point (1 .. 3);
      All_Ok : Boolean := True;
   begin
      Seed_RNG (S, 55);
      for K in 1 .. 30 loop
         P := Sample_Point (S, B, Uniform);
         if P (1) < 0.0 or else P (1) > 1.0
           or else P (2) < -5.0 or else P (2) > -4.0
           or else P (3) < 10.0 or else P (3) > 10.5
         then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Sample_Point respects per-dim bounds");

      declare
         Cfg : constant Config :=
           (Trials => 40, Kind => Uniform, Sense_Flag => Minimize_Sense);
         R   : Result;
         Bx  : constant Bounds (1 .. 1) := [1 => (2.0, 4.0)];
      begin
         R := Search_1D (Quadratic_1D'Access, 2.0, 4.0, Cfg, 8);
         Check (R.Best_X (1) >= 2.0 and then R.Best_X (1) <= 4.0,
                "1D best clamped to [2,4]");
         Check (R.Best_X (1) < 2.5, "1D on [2,4] prefers left");
         R := Minimize (Sphere_ND'Access, Bx, 40, 8);
         Check (R.Best_X (1) >= 2.0 and then R.Best_X (1) <= 4.0,
                "Minimize best in bounds");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Minimize / Maximize convenience");
   ---------------------------------------------------------------------
   declare
      B : constant Bounds (1 .. 2) :=
        [1 => (-1.0, 1.0), 2 => (-1.0, 1.0)];
      Rmin, Rmax : Result;
   begin
      Rmin := Minimize (Sphere_ND'Access, B, 300, 17);
      Check (Rmin.Best_F < 0.15, "Minimize sphere small");
      Check (abs (Rmin.Best_X (1)) < 0.4, "Minimize X1 near 0");
      Check (abs (Rmin.Best_X (2)) < 0.4, "Minimize X2 near 0");

      Rmax := Maximize (Neg_Sphere_ND'Access, B, 300, 17);
      Check (Rmax.Best_F > -0.15, "Maximize -sphere near 0");
      Check (abs (Rmax.Best_X (1)) < 0.4, "Maximize X1 near 0");

      Rmax := Maximize (Sphere_ND'Access, B, 200, 3);
      Check (Rmax.Best_F > 1.2, "Maximize sphere pushes to corner");
   end;

   ---------------------------------------------------------------------
   Section ("11. Log-uniform search on positive scales");
   ---------------------------------------------------------------------
   declare
      Cfg : constant Config :=
        (Trials => 400, Kind => Log_Uniform, Sense_Flag => Minimize_Sense);
      R   : Result;
   begin
      R := Search_1D (Log10_Squared_1D'Access, 1.0E-3, 1.0E3, Cfg, 77);
      Check (R.Best_X (1) > 0.05 and then R.Best_X (1) < 20.0,
             "log-uniform search near x=1 order");
      Check (R.Best_F < 1.0, "log-uniform Best_F reasonable");
      Check (R.Trials_Run = 400, "log-uniform trials");
   end;

   ---------------------------------------------------------------------
   Section ("12. Needle-in-haystack: random vs grid (Bergstra)");
   ---------------------------------------------------------------------
   declare
      Bx : constant Bound := (Lo => 0.0, Hi => 1.0);
      By : constant Bound := (Lo => 0.0, Hi => 1.0);
      B  : constant Bounds (1 .. 2) := [1 => Bx, 2 => By];
      G  : Result;
      R  : Result;
      Budget : constant Positive := 25;
   begin
      G := Grid_Search_2D
        (Needle_Haystack_2D'Access, Bx, By, 5, 5, Minimize_Sense);
      R := Minimize
        (Needle_Haystack_2D'Access, B, Budget, 2022);

      Check (G.Trials_Run = 25, "grid evaluates 5x5=25");
      Check (R.Trials_Run = 25, "random evaluates 25");
      Check (G.Dim = 2 and then R.Dim = 2, "both dim=2");
      Check (G.Best_F <= 1.0E-12, "grid hits x=0.75 exactly on this mesh");
      Check (R.Best_F < 0.05, "random finds good x within budget");

      declare
         G2 : Result;
         R2 : Result;
         Wins : Natural := 0;
      begin
         G2 := Grid_Search_2D
           (Needle_Haystack_2D'Access, Bx, By, 3, 3, Minimize_Sense);
         Check (Approx (G2.Best_F, 0.0625, 1.0E-9),
                "coarse 3x3 grid Best_F=0.0625");
         for Seed in 1 .. 20 loop
            R2 := Minimize
              (Needle_Haystack_2D'Access, B, 9, Seed);
            if R2.Best_F < G2.Best_F - 1.0E-12 then
               Wins := Wins + 1;
            end if;
         end loop;
         Check (Wins >= 8,
                "random beats coarse grid on >=8/20 seeds (Bergstra)");
         Check (G2.Trials_Run = 9, "coarse grid 9 evals");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Grid_Search_2D basics");
   ---------------------------------------------------------------------
   declare
      Bx : constant Bound := (-1.0, 1.0);
      By : constant Bound := (-1.0, 1.0);
      G  : Result;
   begin
      G := Grid_Search_2D (Sphere_ND'Access, Bx, By, 5, 5);
      Check (G.Trials_Run = 25, "sphere grid 25");
      Check (Approx (G.Best_F, 0.0, 1.0E-12), "sphere grid hits origin");
      Check (Approx (G.Best_X (1), 0.0, 1.0E-12), "sphere grid X1=0");
      Check (Approx (G.Best_X (2), 0.0, 1.0E-12), "sphere grid X2=0");

      G := Grid_Search_2D
        (Sphere_ND'Access, Bx, By, 1, 1, Minimize_Sense);
      Check (G.Trials_Run = 1, "1x1 grid one eval");
      Check (Approx (G.Best_X (1), 0.0), "1x1 center X");
      Check (Approx (G.Best_X (2), 0.0), "1x1 center Y");

      G := Grid_Search_2D
        (Sphere_ND'Access, Bx, By, 4, 3, Maximize_Sense);
      Check (G.Trials_Run = 12, "4x3 maximize trials");
      Check (G.Best_F > 1.0, "maximize sphere large");
   end;

   ---------------------------------------------------------------------
   Section ("14. ND sphere / Rastrigin");
   ---------------------------------------------------------------------
   declare
      B2 : constant Bounds (1 .. 2) :=
        [1 => (-3.0, 3.0), 2 => (-3.0, 3.0)];
      B3 : constant Bounds (1 .. 3) :=
        [1 => (-2.0, 2.0),
         2 => (-2.0, 2.0),
         3 => (-2.0, 2.0)];
      R  : Result;
      Cfg : constant Config :=
        (Trials => 600, Kind => Uniform, Sense_Flag => Minimize_Sense);
   begin
      R := Search_ND (Sphere_ND'Access, B2, Cfg, 9);
      Check (R.Best_F < 0.2, "2D sphere Best_F small");
      Check (abs (R.Best_X (1)) < 0.5, "2D sphere X1");
      Check (abs (R.Best_X (2)) < 0.5, "2D sphere X2");

      R := Search_ND (Sphere_ND'Access, B3, Cfg, 11);
      Check (R.Dim = 3, "3D dim");
      Check (R.Best_F < 0.5, "3D sphere Best_F");

      R := Minimize (Rastrigin_2D'Access, B2, 800, 13);
      Check (R.Best_F < 5.0, "Rastrigin finds a good basin");
   end;

   ---------------------------------------------------------------------
   Section ("15. Invalid / edge raises");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Cfg    : constant Config :=
        (Trials => 5, Kind => Log_Uniform, Sense_Flag => Minimize_Sense);
      R      : Result;
      pragma Unreferenced (R);
   begin
      Raised := False;
      begin
         R := Search_1D
           (Quadratic_1D'Access, -1.0, 1.0, Cfg, 1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Search_1D Log_Uniform on negative Lo raises");

      Raised := False;
      begin
         R := Search_1D
           (Quadratic_1D'Access, 1.0, 1.0,
            (Trials => 5, Kind => Uniform, Sense_Flag => Minimize_Sense),
            1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Search_1D Lo>=Hi raises");

      Raised := False;
      begin
         R := Search_ND
           (Sphere_ND'Access,
            [1 => (1.0, 0.0)],  -- inverted bounds
            (Trials => 5, Kind => Uniform, Sense_Flag => Minimize_Sense),
            1);
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Search_ND inverted bounds raises");
   end;

   ---------------------------------------------------------------------
   Section ("16. Sample_Point multi-dim + Max_Dim");
   ---------------------------------------------------------------------
   declare
      S      : RNG_State;
      B8     : Bounds (1 .. Max_Dim);
      P      : Point (1 .. Max_Dim);
      All_Ok : Boolean := True;
      R      : Result;
   begin
      for I in B8'Range loop
         B8 (I) := (Lo => Real (I), Hi => Real (I) + 0.5);
      end loop;
      Seed_RNG (S, 404);
      P := Sample_Point (S, B8, Uniform);
      for I in P'Range loop
         if P (I) < B8 (I).Lo or else P (I) > B8 (I).Hi then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "8-D Sample_Point in bounds");
      Check (P'Length = Max_Dim, "point length Max_Dim");

      R := Minimize (Sphere_ND'Access, B8, 50, 5);
      Check (R.Dim = Max_Dim, "search Max_Dim");
      Check (R.Trials_Run = 50, "Max_Dim trials");
      All_Ok := True;
      for I in 1 .. Max_Dim loop
         if R.Best_X (I) < B8 (I).Lo or else R.Best_X (I) > B8 (I).Hi then
            All_Ok := False;
         end if;
      end loop;
      Check (All_Ok, "Max_Dim best in bounds");
   end;

   ---------------------------------------------------------------------
   Section ("17. Progressive improvement snapshots");
   ---------------------------------------------------------------------
   declare
      Prev : Real := Real'Last;
      Ok   : Boolean := True;
      R    : Result;
      Cfg  : Config;
   begin
      for N in 1 .. 15 loop
         Cfg :=
           (Trials     => N * 20,
            Kind       => Uniform,
            Sense_Flag => Minimize_Sense);
         R := Search_1D (Quadratic_1D'Access, -10.0, 10.0, Cfg, 4242);
         if R.Best_F > Prev + 1.0E-12 then
            Ok := False;
         end if;
         Prev := R.Best_F;
      end loop;
      Check (Ok, "non-increasing Best_F as budget grows (fixed seed)");
      Check (Prev < 0.05, "final Best_F after 300 trials small");
   end;

   ---------------------------------------------------------------------
   Section ("18. Extra sampling / sense checks");
   ---------------------------------------------------------------------
   declare
      S    : RNG_State;
      X    : Real;
      Cfg  : constant Config :=
        (Trials => 100, Kind => Uniform, Sense_Flag => Maximize_Sense);
      R    : Result;
      B    : constant Bounds (1 .. 1) := [1 => (0.5, 1.5)];
      Hits : Natural;
   begin
      Seed_RNG (S, 1);
      Hits := 0;
      for I in 1 .. 100 loop
         X := Sample_Uniform (S, 0.0, 1.0);
         if X < 0.5 then
            Hits := Hits + 1;
         end if;
      end loop;
      Check (Hits > 20 and then Hits < 80, "uniform ~half below 0.5");

      R := Search_1D (Quadratic_1D'Access, -2.0, 2.0, Cfg, 6);
      Check (abs (R.Best_X (1)) > 1.5, "1D maximize |x| large");
      Check (R.Best_F > 2.0, "1D maximize Best_F large");

      R := Maximize (Neg_Quadratic_1D_As_ND'Access, B, 80, 4);
      Check (R.Best_X (1) >= 0.5 and then R.Best_X (1) <= 1.5,
             "Maximize wrapper in bounds");
      Check (R.Best_X (1) < 0.85, "Maximize -x² prefers Lo");
   end;

   ---------------------------------------------------------------------
   Section ("19. Config field defaults / Result fields");
   ---------------------------------------------------------------------
   declare
      C : Config;
      R : Result;
      B : constant Bounds (1 .. 2) :=
        [1 => (-0.5, 0.5), 2 => (-0.5, 0.5)];
   begin
      Check (C.Trials = 100, "Config default Trials=100");
      Check (C.Kind = Uniform, "Config default Uniform");
      Check (C.Sense_Flag = Minimize_Sense, "Config default Minimize");
      R := Search_ND (Sphere_ND'Access, B, C, 2);
      Check (R.Trials_Run = 100, "default config used");
      Check (R.Best_Trial >= 1, "Best_Trial set");
      Check (R.Dim = 2, "Result Dim");
   end;

   ---------------------------------------------------------------------
   Section ("20. Batch reproducibility mini-suite");
   ---------------------------------------------------------------------
   declare
      Match : Natural := 0;
      R1, R2 : Result;
      B : constant Bounds (1 .. 2) :=
        [1 => (0.0, 1.0), 2 => (0.0, 1.0)];
   begin
      for Seed in 100 .. 119 loop
         R1 := Minimize (Needle_Haystack_2D'Access, B, 30, Seed);
         R2 := Minimize (Needle_Haystack_2D'Access, B, 30, Seed);
         if Approx (R1.Best_F, R2.Best_F, 0.0)
           and then Approx (R1.Best_X (1), R2.Best_X (1), 0.0)
         then
            Match := Match + 1;
         end if;
      end loop;
      Check (Match = 20, "20/20 seeded Minimize pairs identical");
   end;

   ---------------------------------------------------------------------
   Section ("21. Extra objective / sample edge checks");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      X : Real;
      B : constant Bounds (1 .. 2) :=
        [1 => (1.0E-3, 10.0), 2 => (1.0E-3, 10.0)];
      R : Result;
      P : Point (1 .. 2);
      Ok : Boolean := True;
   begin
      Check (Approx (Neg_Quadratic_1D_As_ND ([1 => 2.0]), -4.0),
             "Neg_Quadratic_1D_As_ND(2)=-4");
      Seed_RNG (S, 88);
      for I in 1 .. 25 loop
         P := Sample_Point (S, B, Log_Uniform);
         if P (1) < 1.0E-3 or else P (1) > 10.0
           or else P (2) < 1.0E-3 or else P (2) > 10.0
         then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Sample_Point Log_Uniform in positive box");

      R := Minimize (Sphere_ND'Access, B, 100, 9, Log_Uniform);
      Check (R.Trials_Run = 100, "log Minimize trials");
      Check (R.Best_X (1) >= 1.0E-3 and then R.Best_X (1) <= 10.0,
             "log Minimize X1 in range");

      Seed_RNG (S, 2);
      X := Sample_Uniform (S, 5.0, 5.0);
      Check (Approx (X, 5.0), "Sample_Uniform Lo=Hi");
   end;

   New_Line;
   Put_Line ("========================================");
   Put_Line
     ("Result: Pass_Count=" & Natural'Image (Pass_Count)
      & "  Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("ALL TESTS PASSED");
   elsif Fail_Count = 0 then
      Put_Line ("NO FAILURES (but Pass_Count < 100)");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

end Tests;
