--  Standalone test suite for Glauber_Dynamics (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Glauber_Dynamics; use Glauber_Dynamics;

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
   Put_Line ("Glauber_Dynamics test suite");
   Put_Line ("===========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp01 / Wrap");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Clamp01 (-0.5) = 0.0, "Clamp01 neg -> 0");
      Check (Clamp01 (1.5) = 1.0, "Clamp01 >1 -> 1");
      Check (Clamp01 (0.3) = 0.3, "Clamp01 mid");
      Check (Wrap (0, 4) = 4, "Wrap 0 -> L");
      Check (Wrap (5, 4) = 1, "Wrap L+1 -> 1");
      Check (Wrap (1, 4) = 1, "Wrap 1 -> 1");
      Check (Wrap (-1, 4) = 3, "Wrap -1 -> L-1");
      Check (Wrap (8, 4) = 4, "Wrap 8 -> 4 for L=4");
      Check (Wrap (9, 4) = 1, "Wrap 9 -> 1 for L=4");
   end;

   ---------------------------------------------------------------------
   Section ("2. RNG determinism / range");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      U1, U2, U3 : Unit_Interval;
      Idx : Coord;
      All_In : Boolean := True;
   begin
      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      Seed_RNG (S3, 99);
      U1 := Next_Unit (S1);
      U2 := Next_Unit (S2);
      U3 := Next_Unit (S3);
      Check (U1 = U2, "same seed -> same first draw");
      Check (U1 /= U3, "different seeds differ (almost surely)");
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
      All_In := True;
      declare
         Seen : array (1 .. 5) of Boolean := [others => False];
         Count_Seen : Natural := 0;
      begin
         for K in 1 .. 200 loop
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
   Section ("3. Init_All / Init_Random / Site_Count");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Rng : RNG_State;
      All_Plus, All_Minus : Boolean;
      Saw_Plus, Saw_Minus : Boolean;
   begin
      Init_All (Lat, 4, 1);
      Check (Lat.L = 4, "Init_All sets L=4");
      Check (Site_Count (Lat) = 16, "Site_Count 4x4=16");
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
      Check (Saw_Plus and Saw_Minus, "Init_Random has both signs");
      Set_Spin (Lat, 1, 1, 1);
      Check (Get_Spin (Lat, 1, 1) = 1, "Set/Get_Spin");
      Set_Spin (Lat, 1, 1, -1);
      Check (Get_Spin (Lat, 1, 1) = -1, "Set_Spin to -1");
   end;

   ---------------------------------------------------------------------
   Section ("4. Neighbor_Sum with PBC");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
   begin
      --  All +1 on 2x2: each site has 4 neighbors all +1 → sum = 4.
      Init_All (Lat, 2, 1);
      Check (Approx (Neighbor_Sum (Lat, 1, 1), 4.0), "2x2 all+ nn=4");
      Check (Approx (Neighbor_Sum (Lat, 2, 2), 4.0), "2x2 all+ nn=4 at (2,2)");
      Init_All (Lat, 2, -1);
      Check (Approx (Neighbor_Sum (Lat, 1, 1), -4.0), "2x2 all- nn=-4");
      --  Checker pattern on 2x2 with PBC: neighbors of (1,1)=+1 are all -1
      --  because PBC wraps to opposite checker color... wait:
      --  (1,1)=+ (1,2)=- (2,1)=- (2,2)=+
      --  nn of (1,1): (2,1)=- (Wrap0→2,1)=- (1,2)=- (1,Wrap0→2)=- → sum=-4
      Init_All (Lat, 2, 1);
      Set_Spin (Lat, 1, 2, -1);
      Set_Spin (Lat, 2, 1, -1);
      Check (Get_Spin (Lat, 1, 1) = 1, "checker (1,1)=+");
      Check (Get_Spin (Lat, 2, 2) = 1, "checker (2,2)=+");
      Check (Approx (Neighbor_Sum (Lat, 1, 1), -4.0), "checker nn at + = -4");
      Check (Approx (Neighbor_Sum (Lat, 1, 2), 4.0), "checker nn at - = +4");
      --  3x3: all +1 → nn=4; flip one neighbor of center.
      Init_All (Lat, 3, 1);
      Check (Approx (Neighbor_Sum (Lat, 2, 2), 4.0), "3x3 center nn=4");
      Set_Spin (Lat, 2, 1, -1);
      Check (Approx (Neighbor_Sum (Lat, 2, 2), 2.0), "3x3 center nn=2 after flip");
      --  Corner (1,1) PBC on 3x3 all+: still 4.
      Init_All (Lat, 3, 1);
      Check (Approx (Neighbor_Sum (Lat, 1, 1), 4.0), "3x3 corner PBC nn=4");
      --  Isolate: set (1,1)=+ and all else -, then nn of (1,1) = -4.
      Init_All (Lat, 4, -1);
      Set_Spin (Lat, 1, 1, 1);
      Check (Approx (Neighbor_Sum (Lat, 1, 1), -4.0), "isolated + nn=-4");
   end;

   ---------------------------------------------------------------------
   Section ("5. Local_Field / Delta_E_Flip");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Cfg : Config := (J => 1.0, H => 0.0, Beta => 1.0);
      Hi, DE : Real;
   begin
      Init_All (Lat, 2, 1);
      Hi := Local_Field (Lat, 1, 1, Cfg);
      Check (Approx (Hi, 4.0), "Local_Field all+ J=1 h=0 -> 4");
      Cfg.H := 0.5;
      Hi := Local_Field (Lat, 1, 1, Cfg);
      Check (Approx (Hi, 4.5), "Local_Field with h=0.5");
      Cfg.H := 0.0;
      Cfg.J := 2.0;
      Hi := Local_Field (Lat, 1, 1, Cfg);
      Check (Approx (Hi, 8.0), "Local_Field J=2 -> 8");
      Cfg.J := 1.0;
      --  ΔE flip of +1 with S=4: ΔE = 2*(+1)*4 = 8.
      DE := Delta_E_Flip (Lat, 1, 1, Cfg);
      Check (Approx (DE, 8.0), "Delta_E flip aligned = +8");
      Init_All (Lat, 2, -1);
      DE := Delta_E_Flip (Lat, 1, 1, Cfg);
      --  σ=-1, S=-4, h_i=-4, ΔE=2*(-1)*(-4)=8 (same: leaving ground costs).
      Check (Approx (DE, 8.0), "Delta_E flip all- = +8");
      --  Antialigned 2x2 checker: σ=+ at (1,1), S=-4 → ΔE=2*(+1)*(-4)=-8.
      Init_All (Lat, 2, 1);
      Set_Spin (Lat, 1, 2, -1);
      Set_Spin (Lat, 2, 1, -1);
      DE := Delta_E_Flip (Lat, 1, 1, Cfg);
      Check (Approx (DE, -8.0), "Delta_E flip antialigned = -8");
   end;

   ---------------------------------------------------------------------
   Section ("6. Heatbath_Prob_Plus in (0,1), monotone");
   ---------------------------------------------------------------------
   declare
      P0, Pm, Pp, P_Inf, P_Neg, P_Zero_B : Unit_Interval;
      Mono_OK : Boolean := True;
      Prev, Cur : Unit_Interval;
      Fields : constant array (1 .. 7) of Real :=
        [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0];
   begin
      P0 := Heatbath_Prob_Plus (0.0, 1.0);
      Check (Approx (P0, 0.5, 1.0E-12), "P(+|h=0)=1/2");
      Pm := Heatbath_Prob_Plus (-1.0, 1.0);
      Pp := Heatbath_Prob_Plus (1.0, 1.0);
      Check (Pm < 0.5, "P(+|h<0)<1/2");
      Check (Pp > 0.5, "P(+|h>0)>1/2");
      Check (Approx (Pm + Pp, 1.0, 1.0E-12), "P(h)+P(-h)=1");
      Check (Pm > 0.0 and then Pm < 1.0, "Pm in (0,1)");
      Check (Pp > 0.0 and then Pp < 1.0, "Pp in (0,1)");
      P_Inf := Heatbath_Prob_Plus (50.0, 1.0);
      Check (P_Inf = 1.0, "large +h -> P=1");
      P_Neg := Heatbath_Prob_Plus (-50.0, 1.0);
      Check (P_Neg = 0.0, "large -h -> P=0");
      P_Zero_B := Heatbath_Prob_Plus (5.0, 0.0);
      Check (Approx (P_Zero_B, 0.5, 1.0E-12), "beta=0 -> P=1/2 always");
      Prev := Heatbath_Prob_Plus (Fields (1), 1.0);
      for I in 2 .. Fields'Last loop
         Cur := Heatbath_Prob_Plus (Fields (I), 1.0);
         if Cur < Prev then
            Mono_OK := False;
         end if;
         Prev := Cur;
      end loop;
      Check (Mono_OK, "Heatbath_Prob_Plus monotone in field");
      --  Higher beta sharpens: P(+|h=1, beta=10) > P(+|h=1, beta=0.1)
      Check (Heatbath_Prob_Plus (1.0, 10.0) >
             Heatbath_Prob_Plus (1.0, 0.1),
             "higher beta sharpens toward 1 for +h");
      Check (Heatbath_Prob_Plus (-1.0, 10.0) <
             Heatbath_Prob_Plus (-1.0, 0.1),
             "higher beta sharpens toward 0 for -h");
   end;

   ---------------------------------------------------------------------
   Section ("7. Heatbath_Flip_Prob Fermi form");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Cfg : Config := (J => 1.0, H => 0.0, Beta => 1.0);
      P_Up, P_Anti, P_Zero : Unit_Interval;
   begin
      Init_All (Lat, 2, 1);
      P_Up := Heatbath_Flip_Prob (Lat, 1, 1, Cfg);
      --  ΔE=+8, β=1 → p = 1/(1+e^8) ≈ very small
      Check (P_Up < 0.01, "flip aligned unlikely");
      Check (P_Up > 0.0, "flip aligned still >0 (ergodic)");
      Init_All (Lat, 2, 1);
      Set_Spin (Lat, 1, 2, -1);
      Set_Spin (Lat, 2, 1, -1);
      P_Anti := Heatbath_Flip_Prob (Lat, 1, 1, Cfg);
      --  ΔE=-8 → p = 1/(1+e^{-8}) ≈ 1
      Check (P_Anti > 0.99, "flip antialigned almost sure");
      --  Artificial: force ΔE=0 by h canceling? With S=0 impossible on
      --  square nn (even). Use Beta=0.
      Cfg.Beta := 0.0;
      Init_All (Lat, 2, 1);
      P_Zero := Heatbath_Flip_Prob (Lat, 1, 1, Cfg);
      Check (Approx (P_Zero, 0.5, 1.0E-12), "beta=0 flip prob=1/2");
   end;

   ---------------------------------------------------------------------
   Section ("8. Metropolis_Accept_Prob");
   ---------------------------------------------------------------------
   declare
      P_Neg, P_Zero, P_Pos, P_Large : Unit_Interval;
   begin
      P_Neg := Metropolis_Accept_Prob (-1.0, 1.0);
      Check (P_Neg = 1.0, "Metro ΔE<0 always accept");
      P_Zero := Metropolis_Accept_Prob (0.0, 1.0);
      Check (P_Zero = 1.0, "Metro ΔE=0 accept");
      P_Pos := Metropolis_Accept_Prob (1.0, 1.0);
      Check (Approx (P_Pos, 0.36787944117, 1.0E-8), "Metro e^{-1}");
      P_Large := Metropolis_Accept_Prob (100.0, 1.0);
      Check (P_Large = 0.0, "Metro huge ΔE -> 0");
      Check (Metropolis_Accept_Prob (2.0, 0.0) = 1.0,
             "Metro beta=0 always accept");
      Check (Metropolis_Accept_Prob (1.0, 2.0) <
             Metropolis_Accept_Prob (1.0, 0.5),
             "Metro higher beta lower accept for uphill");
   end;

   ---------------------------------------------------------------------
   Section ("9. Energy / Magnetization / ground states");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Cfg : Config := (J => 1.0, H => 0.0, Beta => 1.0);
      E, M : Real;
   begin
      Init_All (Lat, 2, 1);
      --  2x2 PBC: 8 bonds all +1, field 0 → E = -8
      E := Energy (Lat, Cfg);
      Check (Approx (E, -8.0), "2x2 all+ energy=-8J");
      Check (Approx (Energy_Density (Lat, Cfg), -2.0), "energy density=-2");
      M := Magnetization (Lat);
      Check (Approx (M, 1.0), "all+ m=1");
      Check (Approx (Absolute_Magnetization (Lat), 1.0), "|m|=1");
      Init_All (Lat, 2, -1);
      Check (Approx (Energy (Lat, Cfg), -8.0), "2x2 all- energy=-8J");
      Check (Approx (Magnetization (Lat), -1.0), "all- m=-1");
      Check (Approx (Absolute_Magnetization (Lat), 1.0), "|m|=1 for all-");
      --  With field h=1: all+ has E = -8 - 4 = -12; all- has E = -8 - (-4) = -4
      Cfg.H := 1.0;
      Init_All (Lat, 2, 1);
      Check (Approx (Energy (Lat, Cfg), -12.0), "all+ with h=1");
      Init_All (Lat, 2, -1);
      Check (Approx (Energy (Lat, Cfg), -4.0), "all- with h=1");
      Cfg.H := 0.0;
      --  Checker 2x2: bonds: (1,1)-(2,1)=(+)*(-)=-1, (1,1)-(1,2)=-1,
      --  (2,2)-(1,2)=(+)*(-)=-1, (2,2)-(2,1)=-1,
      --  and PBC: (1,1)-(Wrap+1=1? wait X wrap of 2+1=1): (2,1)-right=(2,1)-(1,1)
      --  already counted as right of (2,1)? Let's trust Energy: all 8 bonds
      --  are antiferromagnetic → each product -1 → Bond sum = -8 → E=+8
      Init_All (Lat, 2, 1);
      Set_Spin (Lat, 1, 2, -1);
      Set_Spin (Lat, 2, 1, -1);
      Check (Approx (Energy (Lat, Cfg), 8.0), "checker energy=+8");
      Check (Approx (Magnetization (Lat), 0.0), "checker m=0");
      --  4x4 all+ : bonds = 2*16=32, E=-32
      Init_All (Lat, 4, 1);
      Check (Approx (Energy (Lat, Cfg), -32.0), "4x4 all+ E=-32");
      Check (Approx (Magnetization (Lat), 1.0), "4x4 m=1");
   end;

   ---------------------------------------------------------------------
   Section ("10. Susceptibility_Estimator");
   ---------------------------------------------------------------------
   declare
      Chi : Real;
   begin
      Chi := Susceptibility_Estimator (0.0, 0.25, 1.0, 16);
      Check (Approx (Chi, 4.0), "chi = beta N var = 4");
      Chi := Susceptibility_Estimator (1.0, 1.0, 1.0, 16);
      Check (Approx (Chi, 0.0), "chi=0 when no variance");
      Chi := Susceptibility_Estimator (0.5, 0.2, 1.0, 4);
      --  var = 0.2 - 0.25 = -0.05 → clamped 0
      Check (Approx (Chi, 0.0), "chi clamps negative var");
      Chi := Susceptibility_Estimator (0.0, 1.0, 0.5, 100);
      Check (Approx (Chi, 50.0), "chi with beta=0.5");
   end;

   ---------------------------------------------------------------------
   Section ("11. Exact 2x2 Boltzmann weights");
   ---------------------------------------------------------------------
   declare
      Cfg : Config := (J => 1.0, H => 0.0, Beta => 0.5);
      Z : Positive_Real;
      Em, Mm, Am : Real;
      Cfg0 : constant Config := (J => 1.0, H => 0.0, Beta => 0.0);
   begin
      Z := Exact_2x2_Partition (Cfg);
      Check (Z > 0.0, "Z > 0");
      --  At h=0, symmetry ⇒ ⟨m⟩ = 0
      Mm := Exact_2x2_Mean_Magnetization (Cfg);
      Check (Approx (Mm, 0.0, 1.0E-10), "exact ⟨m⟩=0 at h=0");
      Am := Exact_2x2_Mean_Abs_Magnetization (Cfg);
      Check (Am > 0.0 and then Am <= 1.0, "exact ⟨|m|⟩ in (0,1]");
      Em := Exact_2x2_Mean_Energy (Cfg);
      Check (Em < 0.0, "exact ⟨E⟩ < 0 for ferro J>0");
      --  beta=0: uniform over 16 configs, ⟨E⟩ = average of energies
      Z := Exact_2x2_Partition (Cfg0);
      Check (Approx (Z, 16.0, 1.0E-10), "beta=0 Z=16");
      Mm := Exact_2x2_Mean_Magnetization (Cfg0);
      Check (Approx (Mm, 0.0, 1.0E-10), "beta=0 ⟨m⟩=0");
      --  With field, ⟨m⟩ > 0
      Cfg.H := 1.0;
      Mm := Exact_2x2_Mean_Magnetization (Cfg);
      Check (Mm > 0.0, "⟨m⟩>0 when h>0");
      Cfg.H := -1.0;
      Mm := Exact_2x2_Mean_Magnetization (Cfg);
      Check (Mm < 0.0, "⟨m⟩<0 when h<0");
      --  Large beta, h=0: ⟨|m|⟩ → 1
      Cfg := (J => 1.0, H => 0.0, Beta => 5.0);
      Am := Exact_2x2_Mean_Abs_Magnetization (Cfg);
      Check (Am > 0.95, "low T exact ⟨|m|⟩→1");
      Em := Exact_2x2_Mean_Energy (Cfg);
      Check (Em < -7.0, "low T exact ⟨E⟩→-8");
   end;

   ---------------------------------------------------------------------
   Section ("12. Glauber_Update_Site / reproducibility");
   ---------------------------------------------------------------------
   declare
      Lat1, Lat2, Lat3 : Lattice;
      R1, R2, R3 : RNG_State;
      Cfg : constant Config := (J => 1.0, H => 0.0, Beta => 0.5);
      Same : Boolean;
   begin
      Seed_RNG (R1, 55);
      Seed_RNG (R2, 55);
      Seed_RNG (R3, 77);
      Init_All (Lat1, 3, 1);
      Init_All (Lat2, 3, 1);
      Init_All (Lat3, 3, 1);
      for K in 1 .. 20 loop
         Glauber_Update_Site (Lat1, 2, 2, Cfg, R1);
         Glauber_Update_Site (Lat2, 2, 2, Cfg, R2);
         Glauber_Update_Site (Lat3, 2, 2, Cfg, R3);
      end loop;
      Same := True;
      for X in 1 .. 3 loop
         for Y in 1 .. 3 loop
            if Get_Spin (Lat1, X, Y) /= Get_Spin (Lat2, X, Y) then
               Same := False;
            end if;
         end loop;
      end loop;
      Check (Same, "same seed → identical configs");
      --  Different seed should differ with high probability after many updates
      --  on the updated site path — compare RNG streams instead
      Seed_RNG (R1, 55);
      Seed_RNG (R3, 77);
      Check (Next_Unit (R1) /= Next_Unit (R3), "diff seeds diverge");
   end;

   ---------------------------------------------------------------------
   Section ("13. Glauber_Sweep orders / Metropolis_Sweep");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Rng : RNG_State;
      Cfg : constant Config := (J => 1.0, H => 0.0, Beta => 0.3);
      M_Before, M_After : Real;
   begin
      Seed_RNG (Rng, 9);
      Init_Random (Lat, 4, Rng);
      M_Before := Magnetization (Lat);
      Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
      M_After := Magnetization (Lat);
      Check (abs (M_After) <= 1.0, "after random sweep |m|<=1");
      --  Sequential / checkerboard do not crash and keep spins valid
      Glauber_Sweep (Lat, Cfg, Rng, Sequential);
      Check (abs (Magnetization (Lat)) <= 1.0, "sequential sweep ok");
      Glauber_Sweep (Lat, Cfg, Rng, Checkerboard);
      Check (abs (Magnetization (Lat)) <= 1.0, "checkerboard sweep ok");
      Metropolis_Sweep (Lat, Cfg, Rng, Random_Sites);
      Check (abs (Magnetization (Lat)) <= 1.0, "Metropolis sweep ok");
      Metropolis_Sweep (Lat, Cfg, Rng, Sequential);
      Check (Site_Count (Lat) = 16, "L unchanged by sweeps");
      --  Silence unused warning conceptually: M_Before compared loosely
      Check (abs (M_Before) <= 1.0, "initial |m|<=1");
   end;

   ---------------------------------------------------------------------
   Section ("14. beta→0 ≈ random (m near 0)");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Rng : RNG_State;
      Cfg : constant Config := (J => 1.0, H => 0.0, Beta => 0.0);
      Sum_M : Real := 0.0;
      Acc : Natural := 0;
   begin
      Seed_RNG (Rng, 101);
      Init_All (Lat, 6, 1);
      --  Equilibrate
      for S in 1 .. 50 loop
         Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
      end loop;
      for S in 1 .. 100 loop
         Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
         Sum_M := Sum_M + Magnetization (Lat);
         Acc := Acc + 1;
      end loop;
      Check (abs (Sum_M / Real (Acc)) < 0.15,
             "beta=0 mean m near 0");
      Check (Absolute_Magnetization (Lat) < 0.6,
             "beta=0 single-sample |m| not frozen");
   end;

   ---------------------------------------------------------------------
   Section ("15. beta→∞ freeze / ground state from ordered start");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Rng : RNG_State;
      Cfg : Config := (J => 1.0, H => 0.0, Beta => 20.0);
      Flipped : Natural := 0;
   begin
      Seed_RNG (Rng, 202);
      Init_All (Lat, 4, 1);
      for S in 1 .. 30 loop
         Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
      end loop;
      Check (Approx (Absolute_Magnetization (Lat), 1.0, 1.0E-12),
             "high beta stays |m|=1 from ordered");
      Check (Approx (Energy (Lat, Cfg), -32.0, 1.0E-9),
             "high beta stays at ground energy");
      --  T=0-like: Metropolis from ordered never leaves
      Cfg.Beta := 1.0E9;
      Init_All (Lat, 3, 1);
      Seed_RNG (Rng, 1);
      for S in 1 .. 20 loop
         Metropolis_Sweep (Lat, Cfg, Rng, Sequential);
      end loop;
      for X in 1 .. 3 loop
         for Y in 1 .. 3 loop
            if Get_Spin (Lat, X, Y) /= 1 then
               Flipped := Flipped + 1;
            end if;
         end loop;
      end loop;
      Check (Flipped = 0, "T→0 Metropolis freeze from ordered +");
      Init_All (Lat, 3, -1);
      Seed_RNG (Rng, 2);
      Flipped := 0;
      for S in 1 .. 20 loop
         Metropolis_Sweep (Lat, Cfg, Rng, Sequential);
      end loop;
      for X in 1 .. 3 loop
         for Y in 1 .. 3 loop
            if Get_Spin (Lat, X, Y) /= -1 then
               Flipped := Flipped + 1;
            end if;
         end loop;
      end loop;
      Check (Flipped = 0, "T→0 Metropolis freeze from ordered -");
   end;

   ---------------------------------------------------------------------
   Section ("16. Energy decreases in expectation at high beta");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Rng : RNG_State;
      Cfg : constant Config := (J => 1.0, H => 0.0, Beta => 3.0);
      E0, E1, Sum_DE : Real := 0.0;
      Trials : constant := 40;
   begin
      Seed_RNG (Rng, 303);
      for T in 1 .. Trials loop
         Init_Random (Lat, 4, Rng);
         E0 := Energy (Lat, Cfg);
         Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
         Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
         Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
         E1 := Energy (Lat, Cfg);
         Sum_DE := Sum_DE + (E1 - E0);
      end loop;
      Check (Sum_DE / Real (Trials) < 0.0,
             "high-beta mean ΔE after sweeps < 0 from random");
   end;

   ---------------------------------------------------------------------
   Section ("17. 2x2 MC vs exact (multiple seeds)");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Rng : RNG_State;
      Cfg : constant Config := (J => 1.0, H => 0.0, Beta => 0.6);
      Exact_E : constant Real := Exact_2x2_Mean_Energy (Cfg);
      Exact_AM : constant Real := Exact_2x2_Mean_Abs_Magnetization (Cfg);
      Seeds : constant array (1 .. 4) of Natural := [11, 22, 33, 44];
      Sum_E, Sum_AM : Real;
      Samples : constant := 8000;
      Thermal : constant := 500;
      Mean_E, Mean_AM : Real;
      Tol_E : constant Real := 0.35;
      Tol_AM : constant Real := 0.12;
   begin
      Check (Exact_E < 0.0, "exact E reference negative");
      for Si in Seeds'Range loop
         Seed_RNG (Rng, Seeds (Si));
         Init_Random (Lat, 2, Rng);
         for S in 1 .. Thermal loop
            Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
         end loop;
         Sum_E := 0.0;
         Sum_AM := 0.0;
         for S in 1 .. Samples loop
            Glauber_Sweep (Lat, Cfg, Rng, Random_Sites);
            Sum_E := Sum_E + Energy (Lat, Cfg);
            Sum_AM := Sum_AM + Absolute_Magnetization (Lat);
         end loop;
         Mean_E := Sum_E / Real (Samples);
         Mean_AM := Sum_AM / Real (Samples);
         Check (abs (Mean_E - Exact_E) < Tol_E,
                "2x2 MC ⟨E⟩ near exact seed" & Seeds (Si)'Image);
         Check (abs (Mean_AM - Exact_AM) < Tol_AM,
                "2x2 MC ⟨|m|⟩ near exact seed" & Seeds (Si)'Image);
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("18. Flip symmetry / field response");
   ---------------------------------------------------------------------
   declare
      Lat_P, Lat_M : Lattice;
      Rng_P, Rng_M : RNG_State;
      Cfg_P : constant Config := (J => 1.0, H => 0.8, Beta => 0.7);
      Cfg_M : constant Config := (J => 1.0, H => -0.8, Beta => 0.7);
      Sum_P, Sum_M : Real := 0.0;
      Samples : constant := 3000;
   begin
      Seed_RNG (Rng_P, 404);
      Init_Random (Lat_P, 3, Rng_P);
      --  Re-seed so Lat_M gets same init stream
      Seed_RNG (Rng_M, 404);
      Init_Random (Lat_M, 3, Rng_M);
      for S in 1 .. 200 loop
         Glauber_Sweep (Lat_P, Cfg_P, Rng_P, Random_Sites);
         Glauber_Sweep (Lat_M, Cfg_M, Rng_M, Random_Sites);
      end loop;
      for S in 1 .. Samples loop
         Glauber_Sweep (Lat_P, Cfg_P, Rng_P, Random_Sites);
         Glauber_Sweep (Lat_M, Cfg_M, Rng_M, Random_Sites);
         Sum_P := Sum_P + Magnetization (Lat_P);
         Sum_M := Sum_M + Magnetization (Lat_M);
      end loop;
      Check (Sum_P / Real (Samples) > 0.1, "h>0 ⇒ mean m > 0");
      Check (Sum_M / Real (Samples) < -0.1, "h<0 ⇒ mean m < 0");
      Check (Approx (Sum_P / Real (Samples),
                     -(Sum_M / Real (Samples)), 0.15),
             "flip symmetry ⟨m⟩(h) ≈ −⟨m⟩(−h)");
   end;

   ---------------------------------------------------------------------
   Section ("19. Heat-bath vs Metropolis both preserve |spin|=1");
   ---------------------------------------------------------------------
   declare
      Lat_G, Lat_M : Lattice;
      Rg, Rm : RNG_State;
      Cfg : constant Config := (J => 1.0, H => 0.2, Beta => 0.8);
      Ok : Boolean := True;
   begin
      Seed_RNG (Rg, 7);
      Init_Random (Lat_G, 5, Rg);
      Seed_RNG (Rm, 8);
      Init_Random (Lat_M, 5, Rm);
      for S in 1 .. 25 loop
         Glauber_Sweep (Lat_G, Cfg, Rg, Checkerboard);
         Metropolis_Sweep (Lat_M, Cfg, Rm, Checkerboard);
      end loop;
      for X in 1 .. 5 loop
         for Y in 1 .. 5 loop
            if abs (Integer (Get_Spin (Lat_G, X, Y))) /= 1 then
               Ok := False;
            end if;
            if abs (Integer (Get_Spin (Lat_M, X, Y))) /= 1 then
               Ok := False;
            end if;
         end loop;
      end loop;
      Check (Ok, "spins remain ±1 under both dynamics");
      Check (abs (Energy (Lat_G, Cfg)) < 1.0E6, "Glauber energy finite");
      Check (abs (Energy (Lat_M, Cfg)) < 1.0E6, "Metro energy finite");
   end;

   ---------------------------------------------------------------------
   Section ("20. Extra API / edge cases");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Rng : RNG_State;
      Cfg : Config := (J => 0.5, H => 0.0, Beta => 1.0);
      P1, P2 : Unit_Interval;
   begin
      Init_All (Lat, 1, 1);
      --  1x1 PBC: four self-neighbors (wrap to self) → nn sum = 4
      Check (Approx (Neighbor_Sum (Lat, 1, 1), 4.0), "1x1 PBC nn=4");
      Check (Approx (Energy (Lat, Cfg), -0.5 * 2.0 * 1.0, 1.0E-12),
             "1x1 energy = -J*2 (two self-bonds right+down)");
      Check (Approx (Magnetization (Lat), 1.0), "1x1 m=1");
      Seed_RNG (Rng, 999);
      Glauber_Update_Site (Lat, 1, 1, Cfg, Rng);
      Check (abs (Integer (Get_Spin (Lat, 1, 1))) = 1, "1x1 update valid");
      --  Prob equivalence: Heatbath_Prob_Plus vs setting from field
      Init_All (Lat, 2, 1);
      Cfg := (J => 1.0, H => 0.0, Beta => 1.0);
      declare
         Hi : constant Real := Local_Field (Lat, 1, 1, Cfg);
         --  Current spin +1; P(stay +) = Heatbath_Prob_Plus
         --  Flip prob = 1 - P(+) = Heatbath_Flip_Prob
         P_Plus : constant Unit_Interval :=
           Heatbath_Prob_Plus (Hi, Cfg.Beta);
         P_Flip : constant Unit_Interval :=
           Heatbath_Flip_Prob (Lat, 1, 1, Cfg);
      begin
         Check (Approx (P_Plus + P_Flip, 1.0, 1.0E-10),
                "P(+)+P(flip)=1 when sigma=+");
      end;
      P1 := Heatbath_Prob_Plus (2.0, 1.5);
      P2 := Heatbath_Prob_Plus (2.0, 1.5);
      Check (P1 = P2, "Heatbath_Prob_Plus pure");
      Init_All (Lat, Max_L, 1);
      Check (Site_Count (Lat) = Max_L * Max_L, "Max_L lattice ok");
      Check (Approx (Magnetization (Lat), 1.0), "Max_L all+ m=1");
      Check (Approx (Neighbor_Sum (Lat, 1, 1), 4.0), "Max_L corner nn=4");
      Check (Approx (Energy_Density (Lat, (J => 1.0, H => 0.0, Beta => 1.0)),
                     -2.0), "Max_L all+ density=-2");
   end;

   ---------------------------------------------------------------------
   Section ("21. Batch neighbor / energy consistency");
   ---------------------------------------------------------------------
   declare
      Lat : Lattice;
      Rng : RNG_State;
      Cfg : constant Config := (J => 1.0, H => 0.25, Beta => 1.0);
      --  Verify ΔE matches Energy-after - Energy-before for flips
      E_Before, E_After, DE_Pred : Real;
      Match : Natural := 0;
      Trials : constant := 30;
      X, Y : Coord;
      Old : Spin;
   begin
      Seed_RNG (Rng, 515);
      Init_Random (Lat, 5, Rng);
      for T in 1 .. Trials loop
         X := Next_Index (Rng, 5);
         Y := Next_Index (Rng, 5);
         E_Before := Energy (Lat, Cfg);
         DE_Pred := Delta_E_Flip (Lat, X, Y, Cfg);
         Old := Get_Spin (Lat, X, Y);
         Set_Spin (Lat, X, Y, Spin (-Integer (Old)));
         E_After := Energy (Lat, Cfg);
         Set_Spin (Lat, X, Y, Old);
         if Approx (E_After - E_Before, DE_Pred, 1.0E-9) then
            Match := Match + 1;
         end if;
      end loop;
      Check (Match = Trials, "Delta_E matches explicit energy diff");
      --  More unit checks on Wrap for L=5
      Check (Wrap (0, 5) = 5, "Wrap0 L5");
      Check (Wrap (6, 5) = 1, "Wrap6 L5");
      Check (Wrap (3, 5) = 3, "Wrap3 L5");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   Put_Line ("========================================");
   if Fail_Count /= 0 then
      raise Program_Error with
        "Glauber_Dynamics tests failed:" & Fail_Count'Image;
   end if;
   pragma Assert (Fail_Count = 0);
end Tests;
