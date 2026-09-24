--  Standalone test suite for Demon_Method (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Demon_Method; use Demon_Method;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-9) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Demon_Method test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Near / Wrap");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Wrap (0, 4) = 4, "Wrap 0 -> L");
      Check (Wrap (5, 4) = 1, "Wrap L+1 -> 1");
      Check (Wrap (1, 4) = 1, "Wrap 1 -> 1");
      Check (Wrap (-1, 4) = 3, "Wrap -1 -> L-1");
      Check (Wrap (8, 4) = 4, "Wrap 8 -> 4 for L=4");
      Check (Wrap (9, 4) = 1, "Wrap 9 -> 1 for L=4");
      Check (Wrap (2, 2) = 2, "Wrap 2 -> 2 for L=2");
      Check (Wrap (3, 2) = 1, "Wrap 3 -> 1 for L=2");
      Check (Wrap (0, 2) = 2, "Wrap 0 -> 2 for L=2");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG determinism / range");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      Idx        : Coord;
      All_In     : Boolean := True;
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
      for K in 1 .. 200 loop
         U1 := Next_Unit (S1);
         if U1 < 0.0 or else U1 >= 1.0 then
            All_In := False;
         end if;
      end loop;
      Check (All_In, "200 draws all in [0,1)");
      Seed_RNG (S1, 3);
      declare
         Seen       : array (1 .. 5) of Boolean := [others => False];
         Count_Seen : Natural := 0;
      begin
         for K in 1 .. 300 loop
            Idx := Next_Index (S1, 5);
            Seen (Integer (Idx)) := True;
         end loop;
         for I in Seen'Range loop
            if Seen (I) then
               Count_Seen := Count_Seen + 1;
            end if;
         end loop;
         Check (Count_Seen = 5, "Next_Index covers 1..5");
      end;
      Seed_RNG (S1, 0);
      Check (Next_Unit (S1) >= 0.0, "Seed 0 is valid");
   end;

   ---------------------------------------------------------------------
   Section ("3. Init_All / Init_Random / Site_Count / Bond_Count");
   ---------------------------------------------------------------------
   declare
      Lat                    : Lattice;
      Rng                    : RNG_State;
      All_Plus, All_Minus    : Boolean;
      Saw_Plus, Saw_Minus    : Boolean;
   begin
      Init_All (Lat, 4, 1);
      Check (Lat.L = 4, "Init_All sets L=4");
      Check (Site_Count (Lat) = 16, "Site_Count 4x4=16");
      Check (Bond_Count (Lat) = 32, "Bond_Count 4x4=32");
      All_Plus := True;
      for X in 1 .. 4 loop
         for Y in 1 .. 4 loop
            if Get_Spin (Lat, X, Y) /= 1 then
               All_Plus := False;
            end if;
         end loop;
      end loop;
      Check (All_Plus, "Init_All(+1) all plus");
      Init_All (Lat, 3, -1);
      Check (Site_Count (Lat) = 9, "Site_Count 3x3=9");
      Check (Bond_Count (Lat) = 18, "Bond_Count 3x3=18");
      All_Minus := True;
      for X in 1 .. 3 loop
         for Y in 1 .. 3 loop
            if Get_Spin (Lat, X, Y) /= -1 then
               All_Minus := False;
            end if;
         end loop;
      end loop;
      Check (All_Minus, "Init_All(-1) all minus");
      Seed_RNG (Rng, 123);
      Init_Random (Lat, 8, Rng);
      Check (Lat.L = 8, "Init_Random L=8");
      Check (Site_Count (Lat) = 64, "Site_Count 8x8=64");
      Saw_Plus := False;
      Saw_Minus := False;
      for X in 1 .. 8 loop
         for Y in 1 .. 8 loop
            if Get_Spin (Lat, X, Y) = 1 then
               Saw_Plus := True;
            else
               Saw_Minus := True;
            end if;
         end loop;
      end loop;
      Check (Saw_Plus and then Saw_Minus, "Init_Random sees both signs");
      Init_All (Lat, 2, 1);
      Check (Site_Count (Lat) = 4, "L=2 Site_Count=4");
      Check (Bond_Count (Lat) = 8, "L=2 Bond_Count=8");
   end;

   ---------------------------------------------------------------------
   Section ("4. Neighbor_Sum / Delta_E formulas");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Cfg : Config := (J => 1.0, H => 0.0);
      S   : Real;
      DE  : Real;
   begin
      --  All +1: every neighbor sum = 4; Delta_E_Flip = 2*(+1)*4 = 8.
      Init_All (Lat, 4, 1);
      S := Neighbor_Sum (Lat, 2, 2);
      Check (Approx (S, 4.0), "all-plus Neighbor_Sum=4");
      DE := Delta_E_Flip (Lat, 2, 2, Cfg);
      Check (Approx (DE, 8.0), "all-plus Delta_E=8");
      Check (Approx (Energy (Lat, Cfg), -32.0), "all-plus E=-2*L^2=-32");
      Check (Approx (Magnetization (Lat), 1.0), "all-plus m=1");

      --  All -1: Neighbor_Sum=-4; Delta_E=2*(-1)*(-4)=8 (still uphill).
      Init_All (Lat, 4, -1);
      Check (Approx (Neighbor_Sum (Lat, 1, 1), -4.0), "all-minus S=-4");
      Check (Approx (Delta_E_Flip (Lat, 1, 1, Cfg), 8.0), "all-minus DE=8");
      Check (Approx (Energy (Lat, Cfg), -32.0), "all-minus E=-32");
      Check (Approx (Magnetization (Lat), -1.0), "all-minus m=-1");

      --  L=2 all plus: E=-2*4=-8.
      Init_All (Lat, 2, 1);
      Check (Approx (Energy (Lat, Cfg), -8.0), "L=2 all-plus E=-8");
      Check (Approx (Delta_E_Flip (Lat, 1, 1, Cfg), 8.0), "L=2 DE=8");
      Check (Approx (Neighbor_Sum (Lat, 1, 1), 4.0), "L=2 S=4 (PBC)");

      --  Single flip on 4x4 all-plus: flip (2,2) -> DE should match Energy.
      Init_All (Lat, 4, 1);
      declare
         E0 : constant Real := Energy (Lat, Cfg);
         DE0 : constant Real := Delta_E_Flip (Lat, 2, 2, Cfg);
         E1 : Real;
      begin
         Set_Spin (Lat, 2, 2, -1);
         E1 := Energy (Lat, Cfg);
         Check (Approx (E1 - E0, DE0), "Delta_E matches Energy difference");
         --  After one flip, flipping back is downhill DE=-8.
         Check (Approx (Delta_E_Flip (Lat, 2, 2, Cfg), -8.0),
                "flip-back DE=-8");
      end;

      --  With field h=1: Local_Field = J*S + h = 4+1=5; DE=2*1*5=10.
      Init_All (Lat, 3, 1);
      Cfg := (J => 1.0, H => 1.0);
      Check (Approx (Local_Field (Lat, 2, 2, Cfg), 5.0), "Local_Field with h");
      Check (Approx (Delta_E_Flip (Lat, 2, 2, Cfg), 10.0), "DE with h=1");

      --  J=2 doubles interaction DE.
      Cfg := (J => 2.0, H => 0.0);
      Init_All (Lat, 3, 1);
      Check (Approx (Delta_E_Flip (Lat, 1, 1, Cfg), 16.0), "J=2 DE=16");
      Check (Approx (Energy (Lat, Cfg), -36.0), "J=2 all-plus E=-2*J*N=-36");
   end;

   ---------------------------------------------------------------------
   Section ("5. Would_Accept / New_Demon_Energy");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Would_Accept (0.0, -4.0), "downhill always (Ed=0)");
      Check (Would_Accept (0.0, 0.0), "DeltaE=0 always accepted");
      Check (Would_Accept (10.0, -8.0), "downhill with rich demon");
      Check (not Would_Accept (0.0, 4.0), "reject when demon poor");
      Check (not Would_Accept (3.0, 4.0), "reject Ed < DeltaE");
      Check (Would_Accept (4.0, 4.0), "accept Ed = DeltaE");
      Check (Would_Accept (8.0, 4.0), "accept Ed > DeltaE");
      Check (Approx (New_Demon_Energy (0.0, -4.0), 4.0), "downhill Ed += 4");
      Check (Approx (New_Demon_Energy (8.0, 4.0), 4.0), "uphill Ed -= 4");
      Check (Approx (New_Demon_Energy (4.0, 4.0), 0.0), "exact pay -> Ed=0");
      Check (Approx (New_Demon_Energy (5.0, -3.0), 8.0), "downhill Ed+=3");
      Check (Approx (New_Demon_Energy (10.0, 0.0), 10.0), "DE=0 Ed unchanged");
   end;

   ---------------------------------------------------------------------
   Section ("6. Demon_Update_Site accept / reject / never negative");
   ---------------------------------------------------------------------
   declare
      Lat      : Lattice;
      Cfg      : constant Config := (J => 1.0, H => 0.0);
      Dem      : Demon_State;
      Acc      : Boolean;
      Spin_Before : Spin;
   begin
      --  All plus, Ed=0: uphill flip must be rejected.
      Init_All (Lat, 4, 1);
      Dem.Energy := 0.0;
      Spin_Before := Get_Spin (Lat, 2, 2);
      Demon_Update_Site (Lat, 2, 2, Cfg, Dem, Acc);
      Check (not Acc, "reject uphill when Ed=0");
      Check (Get_Spin (Lat, 2, 2) = Spin_Before, "spin restored on reject");
      Check (Approx (Dem.Energy, 0.0), "Ed stays 0 on reject");

      --  All plus, Ed=8: uphill accepted, Ed -> 0.
      Dem.Energy := 8.0;
      Demon_Update_Site (Lat, 2, 2, Cfg, Dem, Acc);
      Check (Acc, "accept uphill when Ed=8");
      Check (Get_Spin (Lat, 2, 2) = -1, "spin flipped on accept");
      Check (Approx (Dem.Energy, 0.0), "Ed=0 after paying 8");

      --  Now flip back is downhill: always accept, Ed gets 8.
      Demon_Update_Site (Lat, 2, 2, Cfg, Dem, Acc);
      Check (Acc, "downhill always accepted");
      Check (Get_Spin (Lat, 2, 2) = 1, "spin flipped back");
      Check (Approx (Dem.Energy, 8.0), "Ed receives 8 downhill");

      --  Demon never negative over many forced attempts with small Ed.
      Init_All (Lat, 3, 1);
      Dem.Energy := 2.0;  -- less than 8, so all uphill rejected
      for X in 1 .. 3 loop
         for Y in 1 .. 3 loop
            Demon_Update_Site (Lat, X, Y, Cfg, Dem, Acc);
            Check (Dem.Energy >= 0.0, "Ed >= 0 after site attempt");
            Check (not Acc, "poor demon rejects all-plus uphill");
         end loop;
      end loop;
      Check (Approx (Dem.Energy, 2.0), "Ed unchanged after all rejects");
   end;

   ---------------------------------------------------------------------
   Section ("7. Total energy conservation over sweeps");
   ---------------------------------------------------------------------
   declare
      Lat   : Lattice;
      Cfg   : constant Config := (J => 1.0, H => 0.0);
      Dem   : Demon_State;
      Rng   : RNG_State;
      E_Tot : Real;
      Ok    : Boolean := True;
      Neg   : Boolean := False;
   begin
      Init_All (Lat, 6, 1);
      Dem.Energy := 40.0;  -- excess energy in demon
      E_Tot := Total_Energy (Lat, Cfg, Dem);
      Check (Approx (E_Tot, Energy (Lat, Cfg) + 40.0), "initial total");
      Seed_RNG (Rng, 2024);
      for Sweep in 1 .. 50 loop
         Demon_Sweep (Lat, Cfg, Dem, Rng, Random_Sites);
         if not Near (Total_Energy (Lat, Cfg, Dem), E_Tot, 1.0E-8) then
            Ok := False;
         end if;
         if Dem.Energy < 0.0 then
            Neg := True;
         end if;
      end loop;
      Check (Ok, "E_sys+Ed conserved over 50 random sweeps");
      Check (not Neg, "demon never negative over 50 sweeps");
      Check (Near (Total_Energy (Lat, Cfg, Dem), E_Tot, 1.0E-8),
             "final total matches initial");

      --  Sequential sweeps also conserve.
      Init_All (Lat, 4, 1);
      Dem.Energy := 24.0;
      E_Tot := Total_Energy (Lat, Cfg, Dem);
      Seed_RNG (Rng, 11);
      Ok := True;
      for Sweep in 1 .. 30 loop
         Demon_Sweep (Lat, Cfg, Dem, Rng, Sequential);
         if not Near (Total_Energy (Lat, Cfg, Dem), E_Tot, 1.0E-8) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "conservation over 30 sequential sweeps");
      Check (Dem.Energy >= 0.0, "Ed >= 0 after sequential");

      --  Random init + conservation.
      Seed_RNG (Rng, 55);
      Init_Random (Lat, 5, Rng);
      Dem.Energy := 16.0;
      E_Tot := Total_Energy (Lat, Cfg, Dem);
      Ok := True;
      for Sweep in 1 .. 40 loop
         Demon_Sweep (Lat, Cfg, Dem, Rng, Random_Sites);
         if not Near (Total_Energy (Lat, Cfg, Dem), E_Tot, 1.0E-8) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "conservation from random init");
   end;

   ---------------------------------------------------------------------
   Section ("8. Seed reproducibility");
   ---------------------------------------------------------------------
   declare
      Lat1, Lat2 : Lattice;
      Dem1, Dem2 : Demon_State;
      R1, R2     : RNG_State;
      Cfg        : constant Config := (J => 1.0, H => 0.0);
      Same       : Boolean := True;
   begin
      Init_All (Lat1, 4, 1);
      Init_All (Lat2, 4, 1);
      Dem1.Energy := 20.0;
      Dem2.Energy := 20.0;
      Seed_RNG (R1, 777);
      Seed_RNG (R2, 777);
      for Sweep in 1 .. 25 loop
         Demon_Sweep (Lat1, Cfg, Dem1, R1);
         Demon_Sweep (Lat2, Cfg, Dem2, R2);
      end loop;
      for X in 1 .. 4 loop
         for Y in 1 .. 4 loop
            if Get_Spin (Lat1, X, Y) /= Get_Spin (Lat2, X, Y) then
               Same := False;
            end if;
         end loop;
      end loop;
      Check (Same, "same seed -> identical lattices");
      Check (Approx (Dem1.Energy, Dem2.Energy), "same seed -> same Ed");
      Check (Approx (Magnetization (Lat1), Magnetization (Lat2)),
             "same seed -> same m");
      Check (Approx (Energy (Lat1, Cfg), Energy (Lat2, Cfg)),
             "same seed -> same E");
   end;

   ---------------------------------------------------------------------
   Section ("9. Ordered vs disordered regimes");
   ---------------------------------------------------------------------
   declare
      Lat_Cold, Lat_Hot : Lattice;
      Dem_Cold, Dem_Hot : Demon_State;
      Rng               : RNG_State;
      Cfg               : constant Config := (J => 1.0, H => 0.0);
      M_Cold, M_Hot     : Real;
      E_Cold, E_Hot     : Real;
   begin
      --  Cold: start ground state, little excess energy.
      Init_All (Lat_Cold, 8, 1);
      Dem_Cold.Energy := 4.0;
      Seed_RNG (Rng, 1001);
      for Sweep in 1 .. 80 loop
         Demon_Sweep (Lat_Cold, Cfg, Dem_Cold, Rng);
      end loop;
      M_Cold := Absolute_Magnetization (Lat_Cold);
      E_Cold := Energy (Lat_Cold, Cfg);

      --  Hot: start ground state, large excess energy in demon.
      Init_All (Lat_Hot, 8, 1);
      Dem_Hot.Energy := 200.0;
      Seed_RNG (Rng, 1001);
      for Sweep in 1 .. 80 loop
         Demon_Sweep (Lat_Hot, Cfg, Dem_Hot, Rng);
      end loop;
      M_Hot := Absolute_Magnetization (Lat_Hot);
      E_Hot := Energy (Lat_Hot, Cfg);

      Check (M_Cold > 0.5, "cold |m| remains high");
      Check (M_Hot < M_Cold, "hot |m| < cold |m|");
      Check (E_Hot > E_Cold, "hot system energy > cold");
      Check (Dem_Cold.Energy >= 0.0 and then Dem_Hot.Energy >= 0.0,
             "both demons non-negative");
      Check (Near (Total_Energy (Lat_Cold, Cfg, Dem_Cold),
                   -2.0 * 64.0 + 4.0, 1.0E-6),
             "cold total conserved");
      Check (Near (Total_Energy (Lat_Hot, Cfg, Dem_Hot),
                   -2.0 * 64.0 + 200.0, 1.0E-6),
             "hot total conserved");
   end;

   ---------------------------------------------------------------------
   Section ("10. Higher energy heats the demon (thermometer)");
   ---------------------------------------------------------------------
   declare
      Lat_A, Lat_B     : Lattice;
      Dem_A, Dem_B     : Demon_State;
      Rng              : RNG_State;
      Cfg              : constant Config := (J => 1.0, H => 0.0);
      Sum_A, Sum_B     : Real := 0.0;
      Mean_A, Mean_B   : Real;
      Samples          : constant Positive := 100;
      Warmup           : constant Positive := 40;
      T_Cont_A, T_Cont_B : Real;
      T_Disc_A, T_Disc_B : Real;
   begin
      --  Two microcanonical shells: modest vs large excess energy.
      Init_All (Lat_A, 6, 1);
      Dem_A.Energy := 24.0;
      Seed_RNG (Rng, 42);
      for S in 1 .. Warmup loop
         Demon_Sweep (Lat_A, Cfg, Dem_A, Rng);
      end loop;
      for S in 1 .. Samples loop
         Demon_Sweep (Lat_A, Cfg, Dem_A, Rng);
         Sum_A := Sum_A + Dem_A.Energy;
      end loop;
      Mean_A := Sum_A / Real (Samples);

      Init_All (Lat_B, 6, 1);
      Dem_B.Energy := 120.0;
      Seed_RNG (Rng, 42);
      for S in 1 .. Warmup loop
         Demon_Sweep (Lat_B, Cfg, Dem_B, Rng);
      end loop;
      for S in 1 .. Samples loop
         Demon_Sweep (Lat_B, Cfg, Dem_B, Rng);
         Sum_B := Sum_B + Dem_B.Energy;
      end loop;
      Mean_B := Sum_B / Real (Samples);

      Check (Mean_B > Mean_A, "higher total energy -> hotter mean Ed");
      Check (Mean_A >= 0.0 and then Mean_B >= 0.0, "mean Ed non-negative");

      T_Cont_A := Temperature_From_Mean_Demon (Mean_A);
      T_Cont_B := Temperature_From_Mean_Demon (Mean_B);
      Check (Approx (T_Cont_A, Mean_A), "continuous T equals mean Ed");
      Check (T_Cont_B > T_Cont_A, "continuous T_B > T_A");

      T_Disc_A := Ising_Demon_Temperature_Estimator (Mean_A, 4.0);
      T_Disc_B := Ising_Demon_Temperature_Estimator (Mean_B, 4.0);
      Check (T_Disc_B > T_Disc_A, "discrete Ising T_B > T_A");
      Check (Ising_Demon_Temperature_Estimator (0.0) = 0.0,
             "zero mean Ed -> T=0");
      --  Analytic check: Mean=4/3, Quantum=4 => T = 4/ln(1+3)=4/ln(4).
      declare
         M  : constant Non_Negative := 4.0 / 3.0;
         T  : constant Real := Ising_Demon_Temperature_Estimator (M, 4.0);
         --  ln(4) ≈ 1.386294361 → T ≈ 2.88539
      begin
         Check (Approx (T, 4.0 / 1.38629436112, 1.0E-6),
                "discrete estimator analytic 4/ln(4)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Edge L=2");
   ---------------------------------------------------------------------
   declare
      Lat   : Lattice;
      Cfg   : constant Config := (J => 1.0, H => 0.0);
      Dem   : Demon_State;
      Rng   : RNG_State;
      E_Tot : Real;
      Ok    : Boolean := True;
      Acc   : Boolean;
   begin
      Init_All (Lat, 2, 1);
      Check (Lat.L = 2, "L=2 set");
      Check (Approx (Energy (Lat, Cfg), -8.0), "L=2 ground E=-8");
      Check (Approx (Magnetization (Lat), 1.0), "L=2 m=1");
      Check (Approx (Neighbor_Sum (Lat, 1, 2), 4.0), "L=2 PBC neighbors");

      Dem.Energy := 8.0;
      E_Tot := Total_Energy (Lat, Cfg, Dem);
      Seed_RNG (Rng, 9);
      for Sweep in 1 .. 60 loop
         Demon_Sweep (Lat, Cfg, Dem, Rng);
         if not Near (Total_Energy (Lat, Cfg, Dem), E_Tot, 1.0E-8) then
            Ok := False;
         end if;
         if Dem.Energy < 0.0 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "L=2 conservation + Ed>=0 over 60 sweeps");

      --  Explicit site update on L=2.
      Init_All (Lat, 2, 1);
      Dem.Energy := 0.0;
      Demon_Update_Site (Lat, 1, 1, Cfg, Dem, Acc);
      Check (not Acc, "L=2 reject when Ed=0");
      Dem.Energy := 8.0;
      Demon_Update_Site (Lat, 1, 1, Cfg, Dem, Acc);
      Check (Acc, "L=2 accept when Ed=8");
      Check (Approx (Dem.Energy, 0.0), "L=2 Ed depleted");
      Check (Approx (Energy (Lat, Cfg) + Dem.Energy, 0.0),
             "L=2 total after one flip = 0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Energy_Density / Absolute_Magnetization / accessors");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Cfg : constant Config := (J => 1.0, H => 0.0);
   begin
      Init_All (Lat, 4, 1);
      Check (Approx (Energy_Density (Lat, Cfg), -2.0), "e = E/N = -2");
      Check (Approx (Absolute_Magnetization (Lat), 1.0), "|m|=1 all plus");
      Init_All (Lat, 4, -1);
      Check (Approx (Absolute_Magnetization (Lat), 1.0), "|m|=1 all minus");
      Set_Spin (Lat, 1, 1, 1);
      Check (Get_Spin (Lat, 1, 1) = 1, "Get/Set_Spin roundtrip");
      Check (Get_Spin (Lat, 2, 2) = -1, "untouched site stays -1");

      --  Checker of Total_Energy vs Energy + Ed.
      declare
         Dem : Demon_State;
      begin
         Dem.Energy := 7.5;
         Check (Approx (Total_Energy (Lat, Cfg, Dem),
                        Energy (Lat, Cfg) + 7.5),
                "Total_Energy = E + Ed");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("13. Bulk Delta_E / accept matrix");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Cfg : constant Config := (J => 1.0, H => 0.0);
      --  Build a configuration with mixed neighbor sums.
      --  Stripe: columns alternate +1/-1 on 4x4.
   begin
      Init_All (Lat, 4, 1);
      for Y in 1 .. 4 loop
         Set_Spin (Lat, 2, Y, -1);
         Set_Spin (Lat, 4, Y, -1);
      end loop;
      --  Site (1,1)=+1: neighbors (2,1)=-1, (4,1)=-1 (wrap), (1,2)=+1, (1,4)=+1
      --  S = -1 + -1 + 1 + 1 = 0; DE = 0.
      Check (Approx (Neighbor_Sum (Lat, 1, 1), 0.0), "stripe S=0 at (1,1)");
      Check (Approx (Delta_E_Flip (Lat, 1, 1, Cfg), 0.0), "stripe DE=0");
      Check (Would_Accept (0.0, 0.0), "DE=0 accept with Ed=0");

      --  Site (2,1)=-1: nn (1,1)=+1,(3,1)=+1,(2,2)=-1,(2,4)=-1 => S=0; DE=0.
      Check (Approx (Neighbor_Sum (Lat, 2, 1), 0.0), "stripe S=0 at (2,1)");

      --  Accept matrix table.
      Check (Would_Accept (0.0, -8.0), "table: Ed0 DE-8");
      Check (Would_Accept (0.0, -4.0), "table: Ed0 DE-4");
      Check (Would_Accept (0.0, 0.0), "table: Ed0 DE0");
      Check (not Would_Accept (0.0, 4.0), "table: Ed0 DE+4");
      Check (not Would_Accept (0.0, 8.0), "table: Ed0 DE+8");
      Check (Would_Accept (4.0, 4.0), "table: Ed4 DE+4");
      Check (not Would_Accept (4.0, 8.0), "table: Ed4 DE+8");
      Check (Would_Accept (8.0, 8.0), "table: Ed8 DE+8");
      Check (Would_Accept (8.0, 4.0), "table: Ed8 DE+4");
   end;

   ---------------------------------------------------------------------
   Section ("14. Many single-site conservation steps");
   ---------------------------------------------------------------------
   declare
      Lat   : Lattice;
      Cfg   : constant Config := (J => 1.0, H => 0.5);
      Dem   : Demon_State;
      Rng   : RNG_State;
      E_Tot : Real;
      Acc   : Boolean;
      Ok    : Boolean := True;
      X, Y  : Coord;
   begin
      Seed_RNG (Rng, 31337);
      Init_Random (Lat, 5, Rng);
      Dem.Energy := 30.0;
      E_Tot := Total_Energy (Lat, Cfg, Dem);
      for K in 1 .. 200 loop
         X := Next_Index (Rng, Lat.L);
         Y := Next_Index (Rng, Lat.L);
         Demon_Update_Site (Lat, X, Y, Cfg, Dem, Acc);
         if not Near (Total_Energy (Lat, Cfg, Dem), E_Tot, 1.0E-7) then
            Ok := False;
         end if;
         if Dem.Energy < 0.0 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "200 site updates conserve total (with h=0.5)");
      Check (Dem.Energy >= 0.0, "Ed >= 0 after 200 updates");
   end;

   ---------------------------------------------------------------------
   Section ("15. Ground-state / magnetisation bounds");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Cfg : constant Config := (J => 1.0, H => 0.0);
      M   : Real;
   begin
      for L in Lattice_Size range 2 .. 6 loop
         Init_All (Lat, L, 1);
         Check (Approx (Energy (Lat, Cfg), -2.0 * Real (L * L)),
                "ground E=-2L^2 for L");
         M := Magnetization (Lat);
         Check (M >= -1.0 and then M <= 1.0, "m in [-1,1]");
         Check (Approx (M, 1.0), "all-plus m=1");
      end loop;
   end;

   New_Line;
   Put_Line ("=======================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count /= 0 then
      raise Program_Error with
        "Demon_Method tests failed:" & Fail_Count'Image;
   end if;
   pragma Assert (Fail_Count = 0);

end Tests;
