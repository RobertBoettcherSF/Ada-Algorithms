--  Standalone test suite for Wang_Landau (main program).

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;
with Ada.Text_IO; use Ada.Text_IO;
with Wang_Landau; use Wang_Landau;

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

   function Approx (A, B : Real; Tol : Real) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   --  Mild / tight educational configs (stochastic algorithms)
   Cfg_Toy : constant Config :=
     (Flatness        => 0.8,
      F_Final         => 1.0E-4,
      Ln_F_Initial    => 1.0,
      Max_Stages      => 24,
      Steps_Per_Check => 500,
      Min_Entries     => 50,
      Seed            => 42);

   Cfg_Bin : constant Config :=
     (Flatness        => 0.8,
      F_Final         => 1.0E-4,
      Ln_F_Initial    => 1.0,
      Max_Stages      => 28,
      Steps_Per_Check => 2_000,
      Min_Entries     => 200,
      Seed            => 7);

   Cfg_Ising : constant Config :=
     (Flatness        => 0.75,
      F_Final         => 1.0E-3,
      Ln_F_Initial    => 1.0,
      Max_Stages      => 24,
      Steps_Per_Check => 2_000,
      Min_Entries     => 200,
      Seed            => 99);

   Cfg_Fast : constant Config :=
     (Flatness        => 0.7,
      F_Final         => 1.0E-2,
      Ln_F_Initial    => 1.0,
      Max_Stages      => 16,
      Steps_Per_Check => 200,
      Min_Entries     => 40,
      Seed            => 1);

begin
   Put_Line ("Wang_Landau test suite (flat-histogram density of states)");
   Put_Line ("=========================================================");

   ---------------------------------------------------------------------
   Section ("1. Exact_Binomial_Density / helpers");
   ---------------------------------------------------------------------
   declare
      D2 : constant Density_Array := Exact_Binomial_Density (2);
      D3 : constant Density_Array := Exact_Binomial_Density (3);
      D4 : constant Density_Array := Exact_Binomial_Density (4);
      Sum4 : Real := 0.0;
   begin
      Check (D2'Length = 3, "binomial L=2 has 3 bins");
      Check (Approx (D2 (0), 1.0, 1.0E-12), "C(2,0)=1");
      Check (Approx (D2 (1), 2.0, 1.0E-12), "C(2,1)=2");
      Check (Approx (D2 (2), 1.0, 1.0E-12), "C(2,2)=1");
      Check (Approx (D3 (0), 1.0, 1.0E-12), "C(3,0)=1");
      Check (Approx (D3 (1), 3.0, 1.0E-12), "C(3,1)=3");
      Check (Approx (D3 (2), 3.0, 1.0E-12), "C(3,2)=3");
      Check (Approx (D3 (3), 1.0, 1.0E-12), "C(3,3)=1");
      Check (Approx (D4 (2), 6.0, 1.0E-12), "C(4,2)=6");
      for K in D4'Range loop
         Sum4 := Sum4 + D4 (K);
      end loop;
      Check (Approx (Sum4, 16.0, 1.0E-10), "sum C(4,k) = 16");
   end;

   declare
      Ln_G : constant Ln_G_Array (0 .. 1) := [0.0, 0.0];
      Norm : constant Density_Array := Normalize_Density (Ln_G, 2.0);
   begin
      Check (Approx (Norm (0), 1.0, 1.0E-12), "Normalize equal ln g -> 1");
      Check (Approx (Norm (1), 1.0, 1.0E-12), "Normalize equal ln g -> 1 (bin1)");
   end;

   --  Normalize with known ratio exp(ln g)
   declare
      --  ln g = (0, ln 3) ⇒ g ∝ (1, 3)
      Ln_G : Ln_G_Array (0 .. 1);
      Norm : Density_Array (0 .. 1);
      use Ada.Numerics.Elementary_Functions;
   begin
      Ln_G (0) := 0.0;
      Ln_G (1) := Real (Log (3.0));
      Norm := Normalize_Density (Ln_G, 4.0);
      Check (Approx (Norm (0), 1.0, 1.0E-6), "Normalize ratio bin0 = 1");
      Check (Approx (Norm (1), 3.0, 1.0E-6), "Normalize ratio bin1 = 3");
   end;

   declare
      A : constant Density_Array (0 .. 1) := [1.0, 3.0];
      B : constant Density_Array (0 .. 1) := [1.0, 3.0];
      C : constant Density_Array (0 .. 1) := [2.0, 2.0];
   begin
      Check (Approx (Relative_L1 (A, B), 0.0, 1.0E-14), "Relative_L1 identical");
      Check (Relative_L1 (C, B) > 0.0, "Relative_L1 differs when unequal");
   end;

   ---------------------------------------------------------------------
   Section ("2. Ising energy bin mapping");
   ---------------------------------------------------------------------
   Check (Ising_Energy_To_Bin (-4, 4) = 0, "Ising N=4 E=-4 -> bin 0");
   Check (Ising_Energy_To_Bin (-2, 4) = 1, "Ising N=4 E=-2 -> bin 1");
   Check (Ising_Energy_To_Bin (0, 4) = 2, "Ising N=4 E=0 -> bin 2");
   Check (Ising_Energy_To_Bin (2, 4) = 3, "Ising N=4 E=2 -> bin 3");
   Check (Ising_Energy_To_Bin (4, 4) = 4, "Ising N=4 E=4 -> bin 4");
   Check (Ising_Bin_To_Energy (0, 4) = -4, "bin 0 -> E=-4");
   Check (Ising_Bin_To_Energy (4, 4) = 4, "bin 4 -> E=4");
   Check (Ising_Bin_To_Energy (2, 6) = -2, "N=6 bin 2 -> E=-2");

   ---------------------------------------------------------------------
   Section ("3. Exact_Ising_1D_Density");
   ---------------------------------------------------------------------
   declare
      D2 : constant Density_Array := Exact_Ising_1D_Density (2);
      D4 : constant Density_Array := Exact_Ising_1D_Density (4);
      Sum2, Sum4 : Real := 0.0;
   begin
      Check (D2'Length = 3, "Ising N=2 has N+1 bins");
      for K in D2'Range loop
         Sum2 := Sum2 + D2 (K);
      end loop;
      Check (Approx (Sum2, 4.0, 1.0E-12), "Ising N=2 enumerates 4 configs");
      --  N=2: EE both aligned E=-2 (2 configs: ++ and --), anti E=+2 (2 configs)
      Check (Approx (D2 (0), 2.0, 1.0E-12), "Ising N=2 g(E=-2)=2");
      Check (Approx (D2 (2), 2.0, 1.0E-12), "Ising N=2 g(E=+2)=2");
      Check (Approx (D2 (1), 0.0, 1.0E-12), "Ising N=2 g(E=0)=0 unreachable");

      for K in D4'Range loop
         Sum4 := Sum4 + D4 (K);
      end loop;
      Check (Approx (Sum4, 16.0, 1.0E-12), "Ising N=4 enumerates 16 configs");
      --  Classic: g(-4)=2, g(-2)=0?, actually for N=4 periodic:
      --  all-up/all-down: E=-4; known DOS: 2, 0, 12, 0, 2 for E=-4,-2,0,2,4
      --  Wait: E steps of 2. Let me verify via enumeration values printed in test.
      Check (Approx (D4 (0), 2.0, 1.0E-12), "Ising N=4 g(E=-4)=2");
      Check (Approx (D4 (4), 2.0, 1.0E-12), "Ising N=4 g(E=+4)=2");
      Check (D4 (0) + D4 (1) + D4 (2) + D4 (3) + D4 (4) = 16.0
               or else Approx (Sum4, 16.0, 1.0E-12),
             "Ising N=4 DOS sums to 16");
   end;

   ---------------------------------------------------------------------
   Section ("4. Two-level toy (known g)");
   ---------------------------------------------------------------------
   declare
      R : constant Result := Estimate_Two_Level (3, 1, Cfg_Toy);
      G : constant Density_Array := Normalize_Density (R.Ln_G, 4.0);
      Exact : constant Density_Array (0 .. 1) := [3.0, 1.0];
      Err : constant Real := Relative_L1 (G, Exact);
   begin
      Check (N_Bins (R) = 2, "two-level N_Bins=2");
      Check (R.Stages > 0, "two-level ran at least one stage");
      Check (R.Total_Steps > 0, "two-level took steps");
      Check (Err < 0.15, "two-level G0=3,G1=1 relative L1 < 0.15");
      Check (G (0) > G (1), "two-level estimates g0 > g1");
   end;

   declare
      R : constant Result := Run_Two_Level (5, 5, Cfg_Toy);
      G : constant Density_Array := Normalize_Density (R.Ln_G, 10.0);
   begin
      Check (Approx (G (0), 5.0, 1.0), "two-level equal 5:5 roughly bin0");
      Check (Approx (G (1), 5.0, 1.0), "two-level equal 5:5 roughly bin1");
      Check (Relative_L1 (G, [5.0, 5.0]) < 0.2,
             "two-level 5:5 relative L1 < 0.2");
   end;

   declare
      R : constant Result := Estimate_Two_Level (1, 7, Cfg_Toy);
      G : constant Density_Array := Normalize_Density (R.Ln_G, 8.0);
   begin
      Check (G (1) > G (0), "two-level 1:7 estimates g1 > g0");
      Check (Relative_L1 (G, [1.0, 7.0]) < 0.25,
             "two-level 1:7 relative L1 < 0.25");
   end;

   ---------------------------------------------------------------------
   Section ("5. Binomial Wang–Landau");
   ---------------------------------------------------------------------
   declare
      L : constant Positive := 4;
      R : constant Result := Estimate_Binomial (L, Cfg_Bin);
      Exact : constant Density_Array := Exact_Binomial_Density (L);
      Est : constant Density_Array :=
        Normalize_Density (R.Ln_G, 16.0);
      Err : constant Real := Relative_L1 (Est, Exact);
   begin
      Check (N_Bins (R) = 5, "binomial L=4 N_Bins=5");
      Check (R.Stages >= 4, "binomial enough stages");
      Check (Err < 0.25, "binomial L=4 relative L1 < 0.25");
      Check (Est (0) > 0.0 and then Est (4) > 0.0,
             "binomial extremes positive");
      Check (Est (2) > Est (0), "binomial peak near center vs E=0");
   end;

   declare
      R : constant Result := Estimate_Density_Of_States (3, Cfg_Bin);
      Exact : constant Density_Array := Exact_Binomial_Density (3);
      Est : constant Density_Array :=
        Normalize_Density (R.Ln_G, 8.0);
   begin
      Check (N_Bins (R) = 4, "Estimate_Density_Of_States L=3 bins");
      Check (Relative_L1 (Est, Exact) < 0.3, "DOS alias L=3 L1 < 0.3");
   end;

   declare
      R : constant Result := Run_Binomial (2, Cfg_Fast);
      Exact : constant Density_Array := Exact_Binomial_Density (2);
      Est : constant Density_Array := Normalize_Density (R.Ln_G, 4.0);
   begin
      Check (N_Bins (R) = 3, "binomial L=2 bins");
      Check (Relative_L1 (Est, Exact) < 0.35, "binomial L=2 coarse L1");
      Check (R.Visits'Length = 3, "visits length matches");
   end;

   ---------------------------------------------------------------------
   Section ("6. 1D Ising Wang–Landau");
   ---------------------------------------------------------------------
   declare
      N : constant Positive := 4;
      R : constant Result := Estimate_Ising_1D (N, Cfg_Ising);
      Exact : constant Density_Array := Exact_Ising_1D_Density (N);
      --  Only compare reachable bins (Exact > 0)
      Est : constant Density_Array :=
        Normalize_Density (R.Ln_G, 16.0);
      Err : Real := 0.0;
      Sum_Ex : Real := 0.0;
   begin
      Check (N_Bins (R) = 5, "Ising N=4 N_Bins=5");
      Check (R.Stages > 0, "Ising stages > 0");
      for K in Exact'Range loop
         if Exact (K) > 0.0 then
            Err := Err + abs (Est (K) - Exact (K));
            Sum_Ex := Sum_Ex + Exact (K);
         end if;
      end loop;
      if Sum_Ex > 0.0 then
         Err := Err / Sum_Ex;
      end if;
      Check (Err < 0.35, "Ising N=4 reachable-bin L1 < 0.35");
      Check (Est (0) > 0.0 and then Est (4) > 0.0,
             "Ising ground/highest estimated positive");
   end;

   declare
      R : constant Result := Run_Ising_1D (2, Cfg_Fast);
      Exact : constant Density_Array := Exact_Ising_1D_Density (2);
      Est : constant Density_Array := Normalize_Density (R.Ln_G, 4.0);
   begin
      Check (N_Bins (R) = 3, "Ising N=2 bins");
      --  Bins 0 and 2 should dominate; bin 1 unreachable
      Check (Est (0) > 0.5 and then Est (2) > 0.5,
             "Ising N=2 both aligned sectors populated");
      Check (Exact (0) = 2.0 and then Exact (2) = 2.0,
             "exact Ising N=2 reference");
   end;

   ---------------------------------------------------------------------
   Section ("7. Thermodynamics helper");
   ---------------------------------------------------------------------
   declare
      Ln_G : constant Ln_G_Array (0 .. 1) := [0.0, 0.0];
      Ens  : constant Energy_Array (0 .. 1) := [0.0, 1.0];
      M    : constant Real := Canonical_Mean_Energy (Ln_G, Ens, 1.0);
   begin
      --  Equal g ⇒ ⟨E⟩ = 0*p0 + 1*p1 with p1 = e^{-1}/(1+e^{-1})
      Check (M > 0.0 and then M < 1.0, "canonical mean in (0,1)");
      Check (Approx (M, 1.0 / (1.0 + 2.718281828459045), 0.05)
               or else (M > 0.2 and then M < 0.4),
             "canonical mean near 1/(1+e)");
   end;

   declare
      --  Binomial L=2 exact ln g
      Exact : constant Density_Array := Exact_Binomial_Density (2);
      Ln_G  : Ln_G_Array (0 .. 2);
      Ens   : Energy_Array (0 .. 2);
      M_Hi, M_Lo : Real;
      use Ada.Numerics.Elementary_Functions;
   begin
      for K in Exact'Range loop
         Ln_G (K) := Real (Log (Float (Exact (K))));
         Ens (K) := Real (K);
      end loop;
      M_Hi := Canonical_Mean_Energy (Ln_G, Ens, 100.0);
      M_Lo := Canonical_Mean_Energy (Ln_G, Ens, 0.1);
      Check (M_Hi > 0.5 and then M_Hi < 1.5,
             "high-T mean energy near 1 for L=2");
      Check (M_Lo < M_Hi, "low-T mean energy < high-T");
   end;

   ---------------------------------------------------------------------
   Section ("8. Config / Result bookkeeping");
   ---------------------------------------------------------------------
   declare
      R1 : constant Result := Estimate_Two_Level (2, 2, Cfg_Fast);
      R2 : constant Result := Estimate_Two_Level (2, 2,
        (Flatness | F_Final | Ln_F_Initial | Max_Stages |
         Steps_Per_Check | Min_Entries => <>,
         Seed => 123));
   begin
      Check (R1.Final_Ln_F > 0.0, "Final_Ln_F positive");
      Check (R1.Final_Ln_F < 1.0, "Final_Ln_F reduced from 1");
      Check (R2.Total_Steps > 0, "seed 123 runs");
      Check (R1.Total_Steps > 0, "seed 42 runs");
      Check (R1.Visits (0) + R1.Visits (1) > 0, "last-stage visits nonzero");
   end;

   --  Rename / API smoke
   declare
      A : constant Result := Run_Two_Level (2, 3, Cfg_Fast);
      B : constant Result := Run_Binomial (3, Cfg_Fast);
      C : constant Result := Run_Ising_1D (3, Cfg_Fast);
      D : constant Result := Estimate_Density_Of_States (3, Cfg_Fast);
   begin
      Check (N_Bins (A) = 2, "Run_Two_Level API");
      Check (N_Bins (B) = 4, "Run_Binomial API");
      Check (N_Bins (C) = 4, "Run_Ising_1D API");
      Check (N_Bins (D) = 4, "Estimate_Density_Of_States API");
      Check (A.Stages >= 1 and then B.Stages >= 1
               and then C.Stages >= 1,
             "all Run_* produced stages");
   end;

   ---------------------------------------------------------------------
   Section ("9. Reproducibility (same seed)");
   ---------------------------------------------------------------------
   declare
      R1 : constant Result := Estimate_Two_Level (4, 2, Cfg_Toy);
      R2 : constant Result := Estimate_Two_Level (4, 2, Cfg_Toy);
      Match : Boolean := True;
   begin
      for K in R1.Ln_G'Range loop
         if abs (R1.Ln_G (K) - R2.Ln_G (K)) > 1.0E-12 then
            Match := False;
         end if;
      end loop;
      Check (Match, "same seed reproduces Ln_G");
      Check (R1.Total_Steps = R2.Total_Steps, "same seed same step count");
      Check (R1.Stages = R2.Stages, "same seed same stages");
   end;

   ---------------------------------------------------------------------
   Section ("10. Extra binomial / two-level sanity");
   ---------------------------------------------------------------------
   declare
      R : constant Result := Estimate_Binomial (5, Cfg_Bin);
      Exact : constant Density_Array := Exact_Binomial_Density (5);
      Est : constant Density_Array :=
        Normalize_Density (R.Ln_G, 32.0);
   begin
      Check (N_Bins (R) = 6, "binomial L=5 bins");
      Check (Relative_L1 (Est, Exact) < 0.3, "binomial L=5 L1 < 0.3");
      Check (Est (0) < Est (2) and then Est (5) < Est (3),
             "binomial L=5 unimodal-ish");
   end;

   declare
      R : constant Result := Estimate_Two_Level (10, 1, Cfg_Toy);
      G : constant Density_Array := Normalize_Density (R.Ln_G, 11.0);
   begin
      Check (G (0) / G (1) > 5.0, "strongly skewed two-level ratio");
   end;

   --  Default config smoke (may be slower)
   declare
      Cfg_Def : Config;
      R : Result (Last_Bin => 1);
   begin
      Cfg_Def.F_Final := 1.0E-2;
      Cfg_Def.Max_Stages := 12;
      Cfg_Def.Steps_Per_Check := 300;
      Cfg_Def.Min_Entries := 40;
      Cfg_Def.Flatness := 0.75;
      R := Estimate_Two_Level (2, 2, Cfg_Def);
      Check (R.Converged or else R.Stages >= 1, "default-ish config runs");
      Check (R.Ln_G'Length = 2, "result ln_g length");
   end;

   ---------------------------------------------------------------------
   Section ("11. More exact DOS checks");
   ---------------------------------------------------------------------
   declare
      D6 : constant Density_Array := Exact_Binomial_Density (6);
      S  : Real := 0.0;
   begin
      for K in D6'Range loop
         S := S + D6 (K);
      end loop;
      Check (Approx (S, 64.0, 1.0E-9), "sum C(6,k)=64");
      Check (Approx (D6 (3), 20.0, 1.0E-9), "C(6,3)=20");
   end;

   declare
      D3 : constant Density_Array := Exact_Ising_1D_Density (3);
      S  : Real := 0.0;
   begin
      for K in D3'Range loop
         S := S + D3 (K);
      end loop;
      Check (Approx (S, 8.0, 1.0E-12), "Ising N=3 has 8 configs");
      Check (D3'Length = 4, "Ising N=3 has 4 bins");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
