--  Standalone test suite for Ground_State (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Ground_State; use Ground_State;

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
   Put_Line ("Ground_State test suite");
   Put_Line ("=======================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Clamp / Pi");
   ---------------------------------------------------------------------
   declare
      P : constant Real := Pi_Value;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near far");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (Approx (Clamp (0.5, 0.0, 1.0), 0.5), "Clamp interior");
      Check (Approx (Clamp (-1.0, 0.0, 1.0), 0.0), "Clamp low");
      Check (Approx (Clamp (2.0, 0.0, 1.0), 1.0), "Clamp high");
      Check (Approx (P, 3.141592653589793, 1.0E-12), "Pi value");
      Check (P > 3.14 and then P < 3.15, "Pi in range");
   end;

   ---------------------------------------------------------------------
   Section ("2. Infinite well exact spectrum");
   ---------------------------------------------------------------------
   declare
      L  : constant Real := 1.0;
      E1 : constant Real := Infinite_Well_Ground_Energy (L);
      E2 : constant Real := Infinite_Well_Energy (2, L);
      E3 : constant Real := Infinite_Well_Energy (3, L);
      Pi2 : constant Real := Pi_Value * Pi_Value;
   begin
      Check (Approx (E1, Pi2 / 2.0, 1.0E-10), "E1 = π²/(2L²)");
      Check (Approx (E2, 4.0 * E1, 1.0E-10), "E2 = 4 E1");
      Check (Approx (E3, 9.0 * E1, 1.0E-10), "E3 = 9 E1");
      Check (E2 > E1 and then E3 > E2, "Well spectrum ordered");
      Check (Approx (Infinite_Well_Energy (1, 2.0), E1 / 4.0, 1.0E-10),
             "Wider well lowers E1");
      Check (Approx
               (Infinite_Well_Energy (1, 1.0, Hbar => 2.0),
                4.0 * E1, 1.0E-9),
             "E scales with ħ²");
      Check (Approx
               (Infinite_Well_Energy (1, 1.0, Mass => 2.0),
                E1 / 2.0, 1.0E-9),
             "E scales as 1/m");
   end;

   ---------------------------------------------------------------------
   Section ("3. Infinite well wavefunction");
   ---------------------------------------------------------------------
   declare
      L   : constant Real := 1.0;
      Mid : constant Real := Infinite_Well_Psi (1, 0.5, L);
      P0  : constant Real := Infinite_Well_Psi (1, 0.0, L);
      PL  : constant Real := Infinite_Well_Psi (1, L, L);
      Neg : constant Real := Infinite_Well_Psi (1, -0.1, L);
      Outside : constant Real := Infinite_Well_Psi (1, 1.1, L);
      N2m : constant Real := Infinite_Well_Psi (2, 0.5, L);
      N2q : constant Real := Infinite_Well_Psi (2, 0.25, L);
   begin
      Check (Approx (P0, 0.0), "ψ1(0)=0");
      Check (Approx (PL, 0.0), "ψ1(L)=0");
      Check (Approx (Neg, 0.0), "ψ1 outside left =0");
      Check (Approx (Outside, 0.0), "ψ1 outside right =0");
      Check (Mid > 0.0, "ψ1 mid positive");
      Check (Approx (Mid, 1.41421356237, 1.0E-6), "ψ1 mid = √2");
      Check (Approx (N2m, 0.0, 1.0E-10), "ψ2 mid node");
      Check (N2q > 0.0, "ψ2 first lobe positive");
      Check (Infinite_Well_Psi (2, 0.75, L) < 0.0, "ψ2 second lobe negative");
   end;

   ---------------------------------------------------------------------
   Section ("4. Harmonic oscillator exact / zero-point");
   ---------------------------------------------------------------------
   declare
      W  : constant Real := 2.0;
      E0 : constant Real := Zero_Point_Energy (W);
      E1 : constant Real := Harmonic_Energy (1, W);
      E2 : constant Real := Harmonic_Energy (2, W);
      G0 : constant Real := Harmonic_Ground_Psi (0.0, W);
      G1 : constant Real := Harmonic_Ground_Psi (1.0, W);
   begin
      Check (Approx (E0, 1.0, 1.0E-12), "ZPE = ½ ħω = 1 for ω=2");
      Check (Approx (Harmonic_Energy (0, W), E0), "E0 via Harmonic_Energy");
      Check (Approx (E1, 3.0, 1.0E-12), "E1 = 3/2 ħω");
      Check (Approx (E2, 5.0, 1.0E-12), "E2 = 5/2 ħω");
      Check (E1 > E0 and then E2 > E1, "HO spectrum ordered");
      Check (Approx (Zero_Point_Energy (1.0), 0.5), "ZPE ω=1 is 0.5");
      Check (G0 > G1 and then G1 > 0.0, "Gaussian peaks at origin");
      Check (Approx
               (Harmonic_Ground_Psi (0.0, 1.0),
                0.75112554446, 1.0E-6),
             "ψ0(0) for ω=1 ≈ π^{-1/4}");
      Check (Approx (Harmonic_Energy (0, 1.0, Hbar => 2.0), 1.0),
             "ZPE scales with ħ");
   end;

   ---------------------------------------------------------------------
   Section ("5. Discrete infinite well ≈ analytic");
   ---------------------------------------------------------------------
   declare
      L      : constant Real := 1.0;
      N      : constant Dim_N := 48;
      H      : constant Matrix := Build_Infinite_Well_Hamiltonian (L, N);
      Energy : Real;
      Psi    : Vector (1 .. N);
      E_Exact : constant Real := Infinite_Well_Ground_Energy (L);
      Res    : Real;
   begin
      Lowest_Eigenpair (H, Energy, Psi, N);
      Res := Real (Residual_Norm (H, Psi, Energy));
      Check (Approx (Energy, E_Exact, 0.02), "Discrete well E0 ≈ analytic");
      Check (Energy > E_Exact * 0.99, "Discrete E0 above ~99% exact");
      Check (Energy < E_Exact * 1.05, "Discrete E0 within 5%");
      Check (Res < 1.0E-6, "Well residual small");
      Check (Is_Nodeless_Interior (Wave (Psi)), "Discrete ground nodeless");
      Check (Count_Sign_Changes (Wave (Psi)) = 0, "Zero sign changes ground");
      Check (Approx (Rayleigh_Quotient (H, Psi), Energy, 1.0E-8),
             "Rayleigh = eigenvalue");
   end;

   ---------------------------------------------------------------------
   Section ("6. Discrete harmonic ≈ 0.5 ħω");
   ---------------------------------------------------------------------
   declare
      Omega  : constant Real := 1.0;
      N      : constant Dim_N := 61;
      H      : constant Matrix :=
        Build_Harmonic_Hamiltonian (Omega, -6.0, 6.0, N);
      Energy : Real;
      Psi    : Vector (1 .. N);
      E_Exact : constant Real := Zero_Point_Energy (Omega);
      Res    : Real;
   begin
      Lowest_Eigenpair (H, Energy, Psi, N);
      Res := Real (Residual_Norm (H, Psi, Energy));
      Check (Approx (Energy, E_Exact, 0.05), "Discrete HO E0 ≈ 0.5");
      Check (Energy > 0.45 and then Energy < 0.55, "HO E0 in [0.45,0.55]");
      Check (Res < 1.0E-5, "HO residual small");
      Check (Is_Nodeless_Interior (Wave (Psi)), "HO ground nodeless");
      Check (Approx (Rayleigh_Quotient (H, Psi), Energy, 1.0E-7),
             "HO Rayleigh = eigenvalue");
   end;

   ---------------------------------------------------------------------
   Section ("7. Excited states have nodes");
   ---------------------------------------------------------------------
   declare
      L     : constant Real := 1.0;
      N     : constant Dim_N := 40;
      H     : Matrix := Build_Infinite_Well_Hamiltonian (L, N);
      Y     : Matrix (1 .. N, 1 .. N);
      Eigs  : Vector (1 .. N);
      Psi1  : Wave (1 .. N);
      Psi2  : Wave (1 .. N);
      Psi3  : Wave (1 .. N);
   begin
      Jacobi_Symmetric (H, Y, Eigs, N);
      for I in 1 .. N loop
         Psi1 (I) := Y (I, 1);
         Psi2 (I) := Y (I, 2);
         Psi3 (I) := Y (I, 3);
      end loop;
      Check (Count_Sign_Changes (Psi1) = 0, "n=1 has 0 nodes");
      Check (Count_Sign_Changes (Psi2) = 1, "n=2 has 1 node");
      Check (Count_Sign_Changes (Psi3) = 2, "n=3 has 2 nodes");
      Check (Eigs (2) > Eigs (1), "E2 > E1 discrete");
      Check (Eigs (3) > Eigs (2), "E3 > E2 discrete");
      Check (Approx (Eigs (1), Infinite_Well_Ground_Energy (L), 0.03),
             "E1 discrete close");
      Check (Approx (Eigs (2), Infinite_Well_Energy (2, L), 0.08),
             "E2 discrete close");
   end;

   ---------------------------------------------------------------------
   Section ("8. Analytic sign changes for exact well ψ");
   ---------------------------------------------------------------------
   declare
      L    : constant Real := 1.0;
      M    : constant Dim_N := 50;
      W1   : Wave (1 .. M);
      W2   : Wave (1 .. M);
      W3   : Wave (1 .. M);
      DX   : constant Real := L / Real (M + 1);
   begin
      for I in 1 .. M loop
         declare
            X : constant Real := Real (I) * DX;
         begin
            W1 (I) := Infinite_Well_Psi (1, X, L);
            W2 (I) := Infinite_Well_Psi (2, X, L);
            W3 (I) := Infinite_Well_Psi (3, X, L);
         end;
      end loop;
      Check (Count_Sign_Changes (W1) = 0, "Exact ψ1 nodeless");
      Check (Count_Sign_Changes (W2) = 1, "Exact ψ2 one node");
      Check (Count_Sign_Changes (W3) = 2, "Exact ψ3 two nodes");
      Check (Is_Nodeless_Interior (W1), "Is_Nodeless ψ1");
      Check (not Is_Nodeless_Interior (W2), "Not nodeless ψ2");
   end;

   ---------------------------------------------------------------------
   Section ("9. Variational Gaussian ≥ exact and near optimum");
   ---------------------------------------------------------------------
   declare
      Omega : constant Real := 1.0;
      E0    : constant Real := Zero_Point_Energy (Omega);
      A_Star : constant Real := Optimal_Gaussian_Alpha (Omega);
      E_Star : constant Real :=
        Variational_Gaussian_Energy (A_Star, Omega);
      Best_A, Best_E : Positive_Real;
      E_High : constant Real :=
        Variational_Gaussian_Energy (3.0, Omega);
      E_Low  : constant Real :=
        Variational_Gaussian_Energy (0.3, Omega);
   begin
      Check (Approx (A_Star, 1.0), "α* = mω/ħ = 1");
      Check (Approx (E_Star, E0, 1.0E-12), "E(α*) = E0 exactly");
      Check (E_High >= E0, "E(3) ≥ E0");
      Check (E_Low >= E0, "E(0.3) ≥ E0");
      Check (E_High > E_Star, "Off-optimum above minimum");
      Check (E_Low > E_Star, "Under-optimum above minimum");
      Optimize_Gaussian_Trial (Omega, Best_A, Best_E);
      Check (Approx (Best_A, A_Star, 0.05), "Optimized α near α*");
      Check (Approx (Best_E, E0, 0.01), "Optimized E near E0");
      Check (Best_E >= E0 - 1.0E-12, "Variational upper bound");
      --  ω = 2
      declare
         W2 : constant Real := 2.0;
         A2 : constant Real := Optimal_Gaussian_Alpha (W2);
         E2 : constant Real := Variational_Gaussian_Energy (A2, W2);
      begin
         Check (Approx (A2, 2.0), "α*(ω=2)=2");
         Check (Approx (E2, 1.0, 1.0E-12), "E(α*)=ZPE for ω=2");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Degeneracy demos");
   ---------------------------------------------------------------------
   declare
      H    : Matrix := Make_Equal_Diagonal_2x2 (3.5);
      Y    : Matrix (1 .. 2, 1 .. 2);
      Eigs : Vector (1 .. 2);
      Deg  : Positive;
   begin
      Jacobi_Symmetric (H, Y, Eigs, 2);
      Check (Approx (Eigs (1), 3.5), "Degenerate λ1=3.5");
      Check (Approx (Eigs (2), 3.5), "Degenerate λ2=3.5");
      Deg := Degeneracy_Of_Level (Eigs, 1);
      Check (Deg = 2, "Degeneracy count = 2");
      Check (Degeneracy_Of_Level (Eigs, 2) = 2, "Degeneracy from index 2");
      Check (Isotropic_2D_Oscillator_Degeneracy (0) = 1, "2D HO n=0 deg=1");
      Check (Isotropic_2D_Oscillator_Degeneracy (1) = 2, "2D HO n=1 deg=2");
      Check (Isotropic_2D_Oscillator_Degeneracy (2) = 3, "2D HO n=2 deg=3");
      Check (Isotropic_2D_Oscillator_Degeneracy (5) = 6, "2D HO n=5 deg=6");
   end;

   ---------------------------------------------------------------------
   Section ("11. Non-degenerate well spectrum multiplicity");
   ---------------------------------------------------------------------
   declare
      L    : constant Real := 1.0;
      N    : constant Dim_N := 16;
      H    : Matrix := Build_Infinite_Well_Hamiltonian (L, N);
      Y    : Matrix (1 .. N, 1 .. N);
      Eigs : Vector (1 .. N);
   begin
      Jacobi_Symmetric (H, Y, Eigs, N);
      Check (Degeneracy_Of_Level (Eigs, 1, 1.0E-6) = 1,
             "Well ground non-degenerate");
      Check (Degeneracy_Of_Level (Eigs, 2, 1.0E-6) = 1,
             "Well first excited non-deg");
      Check (Eigs (1) < Eigs (2), "Strict ordering E1 < E2");
   end;

   ---------------------------------------------------------------------
   Section ("12. Grid helpers / Build_Discrete_Hamiltonian");
   ---------------------------------------------------------------------
   declare
      X  : constant Wave := Make_Uniform_Grid (-1.0, 1.0, 5);
      DX : constant Real := Grid_Spacing (-1.0, 1.0, 5);
      V  : constant Wave (1 .. 5) := [others => 0.0];
      H  : constant Matrix := Build_Discrete_Hamiltonian (X, V);
   begin
      Check (X'Length = 5, "Grid length 5");
      Check (Approx (X (1), -1.0), "Grid start -1");
      Check (Approx (X (5), 1.0), "Grid end 1");
      Check (Approx (X (3), 0.0), "Grid mid 0");
      Check (Approx (DX, 0.5), "DX = 0.5");

      Check (Near (H (1, 2), H (2, 1)), "H symmetric off-diag");
      Check (H (1, 3) = 0.0, "H tridiagonal far zero");
      Check (H (1, 1) > 0.0, "Kinetic diagonal positive");
      Check (Approx (H (2, 1), -H (1, 1) / 2.0, 1.0E-10),
             "Off-diag = −diag/2 for V=0");
   end;

   ---------------------------------------------------------------------
   Section ("13. Jacobi / residual / 2×2 analytic");
   ---------------------------------------------------------------------
   declare
      H    : constant Matrix (1 .. 2, 1 .. 2) :=
        [1 => [1 => 2.0, 2 => 1.0],
         2 => [1 => 1.0, 2 => 2.0]];
      Work : Matrix := H;
      Y    : Matrix (1 .. 2, 1 .. 2);
      Eigs : Vector (1 .. 2);
      Psi  : Vector (1 .. 2);
      E0   : Real;
      Res  : Real;
   begin
      Jacobi_Symmetric (Work, Y, Eigs, 2);
      Check (Approx (Eigs (1), 1.0, 1.0E-10), "2x2 λ1=1");
      Check (Approx (Eigs (2), 3.0, 1.0E-10), "2x2 λ2=3");
      Lowest_Eigenpair (H, E0, Psi, 2);
      Check (Approx (E0, 1.0, 1.0E-10), "Lowest = 1");
      Res := Real (Residual_Norm (H, Psi, E0));
      Check (Res < 1.0E-10, "2x2 residual tiny");
      Check (Approx (Norm (Psi), 1.0, 1.0E-10), "Eigenvector unit");
      Check (Approx (Dot (Psi, Psi), 1.0, 1.0E-10), "Dot self =1");
   end;

   ---------------------------------------------------------------------
   Section ("14. Normalize / Degenerate / edge vectors");
   ---------------------------------------------------------------------
   declare
      V : Vector (1 .. 3) := [3.0, 0.0, 4.0];
      Z : Vector (1 .. 2) := [0.0, 0.0];
      Raised : Boolean := False;
   begin
      Check (Approx (Norm (V), 5.0), "3-4-5 norm");
      Check (Approx (Norm2 (V), 25.0), "Norm2 = 25");
      Normalize_In_Place (V);
      Check (Approx (Norm (V), 1.0, 1.0E-12), "Normalized");
      begin
         Normalize_In_Place (Z);
      exception
         when Degenerate =>
            Raised := True;
      end;
      Check (Raised, "Normalize zero raises Degenerate");
      Raised := False;
      declare
         H : constant Matrix (1 .. 2, 1 .. 2) :=
           [1 => [1 => 1.0, 2 => 0.0],
            2 => [1 => 0.0, 2 => 2.0]];
         Dummy : Real;
      begin
         Dummy := Rayleigh_Quotient (H, Z);
         pragma Unreferenced (Dummy);
      exception
         when Degenerate =>
            Raised := True;
      end;
      Check (Raised, "Rayleigh zero raises Degenerate");
   end;

   ---------------------------------------------------------------------
   Section ("15. More spectrum / variational identities");
   ---------------------------------------------------------------------
   declare
      --  Batch of exact formula checks
      Ok : Boolean := True;
   begin
      for N in 1 .. 8 loop
         declare
            E : constant Real := Infinite_Well_Energy (N, 1.0);
            E1 : constant Real := Infinite_Well_Ground_Energy (1.0);
         begin
            if not Approx (E, Real (N * N) * E1, 1.0E-10) then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "E_n = n² E_1 for n=1..8");

      Ok := True;
      for N in 0 .. 6 loop
         declare
            E : constant Real := Harmonic_Energy (N, 1.0);
         begin
            if not Approx (E, Real (N) + 0.5, 1.0E-12) then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "HO E_n = n+1/2 for n=0..6");

      --  Variational identity E(α)+E(ω²/α) style symmetry for ω=1:
      --  E(α) = α/4 + 1/(4α); E(1/α) = same.
      Check (Approx
               (Variational_Gaussian_Energy (2.0, 1.0),
                Variational_Gaussian_Energy (0.5, 1.0), 1.0E-12),
             "E(α)=E(1/α) for ω=1");
      Check (Variational_Gaussian_Energy (4.0, 2.0)
               >= Zero_Point_Energy (2.0) - 1.0E-12,
             "E(4,ω=2) ≥ ZPE");
      Check (Approx
               (Variational_Gaussian_Energy (1.0, 2.0),
                Variational_Gaussian_Energy (4.0, 2.0), 1.0E-12),
             "E(α)=E(ω²/α) for ω=2");
   end;

   ---------------------------------------------------------------------
   Section ("16. Discrete well improves with N");
   ---------------------------------------------------------------------
   declare
      L      : constant Real := 1.0;
      Exact  : constant Real := Infinite_Well_Ground_Energy (L);
      E_Coarse, E_Fine : Real;
      Psi_C  : Vector (1 .. 12);
      Psi_F  : Vector (1 .. 36);
      H_C    : constant Matrix := Build_Infinite_Well_Hamiltonian (L, 12);
      H_F    : constant Matrix := Build_Infinite_Well_Hamiltonian (L, 36);
   begin
      Lowest_Eigenpair (H_C, E_Coarse, Psi_C, 12);
      Lowest_Eigenpair (H_F, E_Fine, Psi_F, 36);
      Check (abs (E_Fine - Exact) < abs (E_Coarse - Exact),
             "Finer grid closer to analytic");
      Check (Approx (E_Coarse, Exact, 0.15),
             "Coarse discrete near exact");
      Check (Approx (E_Fine, Exact, 0.03),
             "Fine discrete near exact");
   end;

   ---------------------------------------------------------------------
   Section ("17. Sign-change edge cases");
   ---------------------------------------------------------------------
   declare
      All_Pos : constant Wave (1 .. 4) := [1.0, 2.0, 3.0, 0.5];
      All_Neg : constant Wave (1 .. 4) := [-1.0, -0.2, -3.0, -0.1];
      With_Z  : constant Wave (1 .. 5) := [1.0, 0.0, 0.0, -1.0, -0.5];
      Single  : constant Wave (1 .. 1) := [3.0];
      Osc     : constant Wave (1 .. 6) :=
        [1.0, -1.0, 1.0, -1.0, 1.0, -1.0];
   begin
      Check (Count_Sign_Changes (All_Pos) = 0, "All positive: 0");
      Check (Count_Sign_Changes (All_Neg) = 0, "All negative: 0");
      Check (Count_Sign_Changes (With_Z) = 1, "Zeros then flip: 1");
      Check (Count_Sign_Changes (Single) = 0, "Single sample: 0");
      Check (Count_Sign_Changes (Osc) = 5, "Alternating: 5");
      Check (Is_Nodeless_Interior (All_Pos), "All_Pos nodeless");
      Check (not Is_Nodeless_Interior (Osc), "Osc has nodes");
   end;

   ---------------------------------------------------------------------
   Section ("18. Extra HO discrete / variational batch");
   ---------------------------------------------------------------------
   declare
      Omega : constant Real := 1.5;
      E0    : constant Real := Zero_Point_Energy (Omega);
      N     : constant Dim_N := 51;
      H     : constant Matrix :=
        Build_Harmonic_Hamiltonian (Omega, -8.0, 8.0, N);
      Energy : Real;
      Psi    : Vector (1 .. N);
      BA, BE : Positive_Real;
   begin
      Lowest_Eigenpair (H, Energy, Psi, N);
      Check (Approx (Energy, E0, 0.08), "HO ω=1.5 discrete ≈ ZPE");
      Check (Is_Nodeless_Interior (Wave (Psi)), "ω=1.5 ground nodeless");
      Optimize_Gaussian_Trial (Omega, BA, BE,
                               Alpha_Lo => 0.2, Alpha_Hi => 5.0, Steps => 60);
      Check (BE >= E0 - 1.0E-9, "Var ≥ ZPE ω=1.5");
      Check (Approx (BE, E0, 0.05), "Var near ZPE ω=1.5");
      Check (Approx (BA, Optimal_Gaussian_Alpha (Omega), 0.15),
             "α opt near analytic ω=1.5");
   end;

   ---------------------------------------------------------------------
   Section ("19. Mass / ħ parameter sweeps");
   ---------------------------------------------------------------------
   declare
      Ok : Boolean := True;
   begin
      for K in 1 .. 5 loop
         declare
            M : constant Real := Real (K);
            E : constant Real :=
              Infinite_Well_Ground_Energy (1.0, Mass => Positive_Real (M));
            E_Ref : constant Real :=
              Infinite_Well_Ground_Energy (1.0) / M;
         begin
            if not Approx (E, E_Ref, 1.0E-10) then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "Well E ∝ 1/m for m=1..5");

      Ok := True;
      for K in 1 .. 5 loop
         declare
            Hb : constant Real := Real (K);
            E  : constant Real := Zero_Point_Energy (1.0, Hbar => Positive_Real (Hb));
         begin
            if not Approx (E, 0.5 * Hb, 1.0E-12) then
               Ok := False;
            end if;
         end;
      end loop;
      Check (Ok, "ZPE ∝ ħ for ħ=1..5");
   end;

   ---------------------------------------------------------------------
   Section ("20. Final consistency batch");
   ---------------------------------------------------------------------
   declare
      L : constant Real := Pi_Value;
      E1 : constant Real := Infinite_Well_Ground_Energy (L);
      --  E1 = π² / (2 L²) = π² / (2 π²) = 1/2
   begin
      Check (Approx (E1, 0.5, 1.0E-12), "Well L=π → E1=1/2");
      Check (Infinite_Well_Psi (1, L / 2.0, L) >
              Infinite_Well_Psi (1, L / 4.0, L),
             "ψ1 max nearer mid than quarter");
   end;

   --  Local helper nested via declare for √(2/L) check rewritten without nested fn
   declare
      L   : constant Real := 2.0;
      Max : constant Real := Infinite_Well_Psi (1, 1.0, L);
      Exp : constant Real := 1.0;  -- √(2/2)=1
   begin
      Check (Approx (Max, Exp, 1.0E-10), "ψ1(L/2) for L=2 is 1");
      Check (Near (0.0, 0.0), "Near zero");
      Check (not Near (0.0, 1.0, 0.1), "Not near with tol 0.1");
      Check (Approx (Clamp (5.0, -1.0, 1.0), 1.0), "Clamp high again");
      Check (Approx (Harmonic_Energy (10, 0.5), 5.25, 1.0E-12),
             "E_10(ω=0.5)=5.25");
      Check (Isotropic_2D_Oscillator_Degeneracy (3) = 4, "2D HO n=3 deg=4");
      Check (Isotropic_2D_Oscillator_Degeneracy (4) = 5, "2D HO n=4 deg=5");
      Check (Approx (Variational_Gaussian_Energy (1.0, 1.0), 0.5),
             "E(1,1)=0.5");
      Check (Approx (Variational_Gaussian_Energy (2.0, 2.0), 1.0),
             "E(α=ω=2)=1");
   end;

   New_Line;
   Put_Line ("PASS: " & Natural'Image (Pass_Count));
   Put_Line ("FAIL: " & Natural'Image (Fail_Count));
   Put_Line ("Fail_Count=" & Natural'Image (Fail_Count));
   if Fail_Count = 0 and then Pass_Count >= 100 then
      Put_Line ("All tests passed.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Put_Line ("Some tests failed or PASS count < 100.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
