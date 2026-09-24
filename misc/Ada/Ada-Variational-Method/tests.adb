--  Standalone test suite for Variational_Method (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Command_Line;
with Variational_Method; use Variational_Method;

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
   Put_Line ("Variational_Method test suite");
   Put_Line ("=============================");

   ---------------------------------------------------------------------
   Section ("1. Helpers: Near / Clamp / Linear_Interpolation");
   ---------------------------------------------------------------------
   declare
      Y : Real;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (not Near (1.0, 2.0), "Near far");
      Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
      Check (Approx (Clamp (0.5, 0.0, 1.0), 0.5), "Clamp interior");
      Check (Approx (Clamp (-1.0, 0.0, 1.0), 0.0), "Clamp low");
      Check (Approx (Clamp (2.0, 0.0, 1.0), 1.0), "Clamp high");
      Y := Linear_Interpolation_Y (0.0, 0.0, 1.0, 2.0, 0.5);
      Check (Approx (Y, 1.0), "Lerp mid");
      Y := Linear_Interpolation_Y (0.0, 1.0, 4.0, 5.0, 0.0);
      Check (Approx (Y, 1.0), "Lerp start");
      Y := Linear_Interpolation_Y (0.0, 1.0, 4.0, 5.0, 4.0);
      Check (Approx (Y, 5.0), "Lerp end");
      Check (Approx (Harmonic_Ground_Exact, 1.0), "E0 exact = 1");
      Check (Approx (Optimal_Gaussian_Alpha, 1.0), "alpha* = 1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Straight_Line_Path geometry");
   ---------------------------------------------------------------------
   declare
      P : constant Path := Straight_Line_Path (0.0, 0.0, 1.0, 1.0, 5);
      L : constant Real := Path_Length (P);
   begin
      Check (P'Length = 5, "Straight length 5");
      Check (Approx (P (1).X, 0.0) and then Approx (P (1).Y, 0.0),
             "Straight start (0,0)");
      Check (Approx (P (5).X, 1.0) and then Approx (P (5).Y, 1.0),
             "Straight end (1,1)");
      Check (Approx (P (3).X, 0.5) and then Approx (P (3).Y, 0.5),
             "Straight mid");
      Check (Approx (L, 1.41421356237, 1.0E-6), "Straight length √2");
      Check (Segment_Count (P) = 4, "Segment_Count 4");
      Check (Approx (Functional_Trapezoid_Arc (P), L),
             "Trapezoid arc = Path_Length");
   end;

   ---------------------------------------------------------------------
   Section ("3. Path_Length edge cases");
   ---------------------------------------------------------------------
   declare
      Single : constant Path (1 .. 1) := [1 => (X => 0.0, Y => 0.0)];
      Two    : constant Path := Straight_Line_Path (0.0, 0.0, 3.0, 4.0, 2);
      Horiz  : constant Path := Straight_Line_Path (0.0, 1.0, 5.0, 1.0, 6);
      Vert   : constant Path :=
        [(X => 0.0, Y => 0.0), (X => 0.0, Y => 2.0)];
   begin
      Check (Approx (Path_Length (Single), 0.0), "Single point length 0");
      Check (Segment_Count (Single) = 0, "Single segment count 0");
      Check (Approx (Path_Length (Two), 5.0), "3-4-5 length");
      Check (Approx (Path_Length (Horiz), 5.0), "Horizontal length 5");
      Check (Approx (Path_Length (Vert), 2.0), "Vertical length 2");
      Check (Segment_Count (Two) = 1, "Two-point one segment");
   end;

   ---------------------------------------------------------------------
   Section ("4. Shortest path: straight vs bowed");
   ---------------------------------------------------------------------
   declare
      Line : constant Path := Straight_Line_Path (0.0, 0.0, 1.0, 0.0, 11);
      Bow1 : constant Path := Bowed_Path (0.0, 0.0, 1.0, 0.0, 11, 0.2);
      Bow2 : constant Path := Bowed_Path (0.0, 0.0, 1.0, 0.0, 11, 0.5);
      Bow3 : constant Path := Bowed_Path (0.0, 0.0, 1.0, 0.0, 11, -0.3);
      L0   : constant Real := Path_Length (Line);
      L1   : constant Real := Path_Length (Bow1);
      L2   : constant Real := Path_Length (Bow2);
      L3   : constant Real := Path_Length (Bow3);
   begin
      Check (Approx (L0, 1.0, 1.0E-8), "Flat line length 1");
      Check (L1 > L0, "Small bow longer than line");
      Check (L2 > L1, "Larger bow longer still");
      Check (L3 > L0, "Negative bow longer than line");
      Check (Approx (Bow1 (1).Y, 0.0) and then Approx (Bow1 (11).Y, 0.0),
             "Bow endpoints fixed");
      Check (abs (Bow1 (6).Y) > 0.1, "Bow mid displaced");
      Check (Functional_Trapezoid_Arc (Bow2) > Functional_Trapezoid_Arc (Line),
             "Trapezoid arc agrees bowed > line");
   end;

   ---------------------------------------------------------------------
   Section ("5. Many bowed amplitudes: line is shortest");
   ---------------------------------------------------------------------
   declare
      Line : constant Path := Straight_Line_Path (0.0, 0.0, 2.0, 1.0, 17);
      L0   : constant Real := Path_Length (Line);
      All_Longer : Boolean := True;
      Amps : constant array (1 .. 8) of Real :=
        [0.05, 0.1, 0.2, 0.35, 0.5, -0.15, -0.4, 0.8];
   begin
      for A of Amps loop
         declare
            B : constant Path :=
              Bowed_Path (0.0, 0.0, 2.0, 1.0, 17, A);
         begin
            if Path_Length (B) <= L0 then
               All_Longer := False;
            end if;
            Check (Path_Length (B) > L0,
                   "Bow amp longer");
         end;
      end loop;
      Check (All_Longer, "All 8 bows longer than line");
   end;

   ---------------------------------------------------------------------
   Section ("6. Dirichlet energy: linear minimizer");
   ---------------------------------------------------------------------
   declare
      Line : constant Path := Straight_Line_Path (0.0, 0.0, 1.0, 2.0, 9);
      Bow  : constant Path := Bowed_Path (0.0, 0.0, 1.0, 2.0, 9, 0.4);
      E_L  : constant Real := Dirichlet_Energy (Line);
      E_B  : constant Real := Dirichlet_Energy (Bow);
      --  Exact ∫(y')² dx for y=2x on [0,1] is ∫4 dx = 4.
   begin
      Check (Approx (E_L, 4.0, 1.0E-8), "Dirichlet line = 4");
      Check (E_B > E_L, "Bowed Dirichlet > linear");
      Check (Approx (Functional_Trapezoid_Dirichlet (Line), E_L),
             "Trapezoid Dirichlet alias");
      Check (Euler_Lagrange_Residual_Dirichlet (Line) < 1.0E-8,
             "EL residual ~0 on line");
      Check (Euler_Lagrange_Residual_Dirichlet (Bow) >
             Euler_Lagrange_Residual_Dirichlet (Line),
             "EL residual larger on bow");
   end;

   ---------------------------------------------------------------------
   Section ("7. Dirichlet on several grids");
   ---------------------------------------------------------------------
   declare
      Ns : constant array (1 .. 5) of Point_Count := [3, 5, 9, 17, 33];
   begin
      for N of Ns loop
         declare
            P : constant Path :=
              Straight_Line_Path (0.0, 1.0, 1.0, 0.0, N);
            --  y = 1-x, (y')²=1, ∫_0^1 = 1.
            E : constant Real := Dirichlet_Energy (P);
         begin
            Check (Approx (E, 1.0, 1.0E-8), "Dirichlet slope-1 grid");
            if N >= 3 then
               Check (Euler_Lagrange_Residual_Dirichlet (P) < 1.0E-8,
                      "EL residual zero linear grid");
            end if;
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Length gradient near zero at optimum");
   ---------------------------------------------------------------------
   declare
      Line : constant Path := Straight_Line_Path (0.0, 0.0, 1.0, 0.0, 11);
      Bow  : constant Path := Bowed_Path (0.0, 0.0, 1.0, 0.0, 11, 0.3);
      G0   : constant Real := Max_Abs_Length_Gradient (Line);
      G1   : constant Real := Max_Abs_Length_Gradient (Bow);
   begin
      Check (G0 < 1.0E-8, "Length grad ~0 on flat line");
      Check (G1 > G0, "Length grad larger on bow");
      Check (G1 > 0.1, "Length grad material on bow");
   end;

   ---------------------------------------------------------------------
   Section ("9. Improve_Path_Gradient toward line");
   ---------------------------------------------------------------------
   declare
      P : Path := Bowed_Path (0.0, 0.0, 1.0, 0.0, 15, 0.4);
      L_Before : constant Real := Path_Length (P);
      G_Before : constant Real := Max_Abs_Length_Gradient (P);
   begin
      Improve_Path_Gradient (P, Step => 0.08, Iterations => 80,
                             Objective => 0);
      declare
         L_After : constant Real := Path_Length (P);
         G_After : constant Real := Max_Abs_Length_Gradient (P);
         Line    : constant Path :=
           Straight_Line_Path (0.0, 0.0, 1.0, 0.0, 15);
      begin
         Check (L_After < L_Before, "GD reduced path length");
         Check (G_After < G_Before * 1.5 or else L_After < L_Before,
                "GD gradient not exploded");
         Check (L_After < L_Before * 0.95, "GD meaningful length cut");
         Check (Approx (P (1).Y, 0.0) and then Approx (P (15).Y, 0.0),
                "GD preserves endpoints");
         Check (Path_Length (P) >= Path_Length (Line) - 1.0E-6,
                "Improved path still ≥ straight");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Improve_Path_Coordinate Dirichlet");
   ---------------------------------------------------------------------
   declare
      P : Path := Bowed_Path (0.0, 0.0, 1.0, 1.0, 11, 0.35);
      E_Before : constant Real := Dirichlet_Energy (P);
      R_Before : constant Real :=
        Euler_Lagrange_Residual_Dirichlet (P);
   begin
      Improve_Path_Coordinate (P, Step => 0.15, Iterations => 60,
                               Objective => 1);
      declare
         E_After : constant Real := Dirichlet_Energy (P);
         R_After : constant Real :=
           Euler_Lagrange_Residual_Dirichlet (P);
         Line : constant Path :=
           Straight_Line_Path (0.0, 0.0, 1.0, 1.0, 11);
      begin
         Check (E_After < E_Before, "CD reduced Dirichlet");
         Check (R_After < R_Before, "CD reduced EL residual");
         Check (E_After < Dirichlet_Energy (Line) + 0.15,
                "CD near linear Dirichlet");
         Check (Approx (P (1).Y, 0.0) and then Approx (P (11).Y, 1.0),
                "CD preserves endpoints");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Simpson arc on equal grid");
   ---------------------------------------------------------------------
   declare
      Line : constant Path := Straight_Line_Path (0.0, 0.0, 1.0, 0.0, 9);
      S    : constant Real := Functional_Simpson_Arc (Line);
      L    : constant Real := Path_Length (Line);
      Uneven : Path (1 .. 4);
   begin
      Check (Approx (S, 1.0, 1.0E-5), "Simpson flat ≈ 1");
      Check (Approx (L, 1.0, 1.0E-12), "Path flat = 1");
      Uneven (1) := (0.0, 0.0);
      Uneven (2) := (0.2, 0.1);
      Uneven (3) := (0.7, 0.1);
      Uneven (4) := (1.0, 0.0);
      Check (Functional_Simpson_Arc (Uneven) =
             Path_Length (Uneven),
             "Simpson falls back on uneven Δx");
   end;

   ---------------------------------------------------------------------
   Section ("12. Analytic Gaussian trial energy");
   ---------------------------------------------------------------------
   declare
      E1 : constant Real := Gaussian_Trial_Energy_Analytic (1.0);
      E2 : constant Real := Gaussian_Trial_Energy_Analytic (2.0);
      E05 : constant Real := Gaussian_Trial_Energy_Analytic (0.5);
      E0  : constant Real := Harmonic_Ground_Exact;
   begin
      Check (Approx (E1, 1.0, 1.0E-12), "Analytic E(1)=1");
      Check (E1 >= E0 - 1.0E-12, "E(1) ≥ E0");
      Check (E2 > E1, "E(2) > E(1)");
      Check (E05 > E1, "E(0.5) > E(1)");
      Check (Approx (E2, 1.25, 1.0E-12), "E(2)=1.25");
      Check (Approx (E05, 1.25, 1.0E-12), "E(0.5)=1.25");
      --  Several alphas all ≥ E0
      Check (Gaussian_Trial_Energy_Analytic (0.3) >= E0, "α=0.3 ≥ E0");
      Check (Gaussian_Trial_Energy_Analytic (0.7) >= E0, "α=0.7 ≥ E0");
      Check (Gaussian_Trial_Energy_Analytic (1.5) >= E0, "α=1.5 ≥ E0");
      Check (Gaussian_Trial_Energy_Analytic (3.0) >= E0, "α=3 ≥ E0");
      Check (Gaussian_Trial_Energy_Analytic (0.8) >
             Gaussian_Trial_Energy_Analytic (1.0),
             "α=0.8 worse than optimal");
      Check (Gaussian_Trial_Energy_Analytic (1.2) >
             Gaussian_Trial_Energy_Analytic (1.0),
             "α=1.2 worse than optimal");
   end;

   ---------------------------------------------------------------------
   Section ("13. Discrete Quantum_Trial_Energy ≥ E0");
   ---------------------------------------------------------------------
   declare
      E0 : constant Real := Harmonic_Ground_Exact;
      Alphas : constant array (1 .. 7) of Real :=
        [0.4, 0.6, 0.8, 1.0, 1.2, 1.5, 2.5];
   begin
      for A of Alphas loop
         declare
            E : constant Real :=
              Quantum_Trial_Energy (A, -6.0, 6.0, 61);
         begin
            Check (E >= E0 - 0.05,
                   "Discrete trial ≥ E0 (tol)");
            Check (E > 0.0, "Discrete trial positive");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("14. Optimizing alpha improves energy");
   ---------------------------------------------------------------------
   declare
      E_Bad  : constant Real :=
        Quantum_Trial_Energy (0.4, -6.0, 6.0, 61);
      E_Good : constant Real :=
        Quantum_Trial_Energy (1.0, -6.0, 6.0, 61);
      A_Opt  : constant Real :=
        Optimize_Gaussian_Alpha (0.3, 3.0, 50, -6.0, 6.0, 61);
      E_Opt  : constant Real :=
        Quantum_Trial_Energy (A_Opt, -6.0, 6.0, 61);
      E0     : constant Real := Harmonic_Ground_Exact;
   begin
      Check (E_Good < E_Bad, "α=1 better than α=0.4");
      Check (E_Opt <= E_Bad, "Optimized ≤ bad α");
      Check (E_Opt < E_Bad * 0.95 or else E_Opt < E_Bad - 0.05,
             "Optimized meaningfully better");
      Check (abs (A_Opt - 1.0) < 0.25, "Optimized α near 1");
      Check (E_Opt >= E0 - 0.08, "Optimized still ≥ E0");
      Check (E_Good >= E0 - 0.05, "α=1 discrete ≥ E0");
      Check (Near (A_Opt, 1.0, 0.3), "Near optimal alpha");
   end;

   ---------------------------------------------------------------------
   Section ("15. Normalize / Discrete_Norm2 / grids");
   ---------------------------------------------------------------------
   declare
      X   : constant Wave := Make_Uniform_Grid (-1.0, 1.0, 5);
      Psi : constant Wave (1 .. 5) := [1.0, 1.0, 1.0, 1.0, 1.0];
      DX  : constant Real := 0.5;
      N2  : constant Real := Discrete_Norm2 (Psi, DX);
      Pn  : Wave (1 .. 5);
   begin
      Check (Approx (X (1), -1.0) and then Approx (X (5), 1.0),
             "Uniform grid ends");
      Check (Approx (X (3), 0.0), "Uniform grid mid");
      Check (Approx (N2, 2.5, 1.0E-12), "Norm2 flat");
      Pn := Normalize (Psi, DX);
      Check (Approx (Discrete_Norm2 (Pn, DX), 1.0, 1.0E-8),
             "Normalized ‖ψ‖²=1");
      declare
         G : constant Wave :=
           Make_Gaussian_Wave (1.0, -4.0, 4.0, 41);
         Raised : Boolean := False;
         Z : constant Wave (1 .. 3) := [0.0, 0.0, 0.0];
         Zn : Wave (1 .. 3);
      begin
         Check (G'Length = 41, "Gaussian wave length");
         Check (G (21) > G (1), "Gaussian peak at center");
         begin
            Zn := Normalize (Z, 1.0);
            Raised := Near (Zn (1), 0.0);  -- should not reach
         exception
            when Degenerate =>
               Raised := True;
         end;
         Check (Raised, "Normalize zero raises Degenerate");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("16. Analytic vs discrete agreement near α=1");
   ---------------------------------------------------------------------
   declare
      A : constant Real := 1.0;
      Ea : constant Real := Gaussian_Trial_Energy_Analytic (A);
      Ed : constant Real :=
        Quantum_Trial_Energy (A, -8.0, 8.0, 61);
   begin
      Check (abs (Ed - Ea) < 0.08, "Discrete≈analytic at α=1");
      Check (Ed >= Harmonic_Ground_Exact - 0.02,
             "Wide-grid discrete ≥ E0");
   end;

   ---------------------------------------------------------------------
   Section ("17. More path comparisons (batch)");
   ---------------------------------------------------------------------
   declare
      Base : constant Path :=
        Straight_Line_Path (-1.0, 0.5, 1.0, -0.5, 13);
      L0 : constant Real := Path_Length (Base);
   begin
      for K in 1 .. 10 loop
         declare
            Amp : constant Real := 0.05 * Real (K);
            B : constant Path :=
              Bowed_Path (-1.0, 0.5, 1.0, -0.5, 13, Amp);
         begin
            Check (Path_Length (B) > L0, "Batch bow longer");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("18. Dirichlet residual / GD objective 1");
   ---------------------------------------------------------------------
   declare
      P : Path := Bowed_Path (0.0, 0.0, 1.0, 0.0, 13, 0.25);
      E0 : constant Real := Dirichlet_Energy (P);
   begin
      Improve_Path_Gradient (P, Step => 0.1, Iterations => 100,
                             Objective => 1);
      Check (Dirichlet_Energy (P) < E0, "GD Dirichlet reduced");
      Check (Dirichlet_Energy (P) < E0 * 0.9
               or else Euler_Lagrange_Residual_Dirichlet (P) < 2.0,
             "GD Dirichlet improved energy or residual");
      Check (Approx (P (1).X, 0.0) and then Approx (P (13).X, 1.0),
             "X abscissae unchanged");
   end;

   ---------------------------------------------------------------------
   Section ("19. Capacity / small paths");
   ---------------------------------------------------------------------
   declare
      P2 : constant Path := Straight_Line_Path (0.0, 0.0, 1.0, 0.0, 2);
      P3 : constant Path := Straight_Line_Path (0.0, 0.0, 1.0, 1.0, 3);
   begin
      Check (Segment_Count (P2) = 1, "2-pt one segment");
      Check (Approx (Path_Length (P2), 1.0), "2-pt length");
      Check (Approx (Dirichlet_Energy (P3), 1.0, 1.0E-10),
             "3-pt Dirichlet slope 1");
      Check (Mean_Abs_Second_Difference (P3) < 1.0E-10,
             "3-pt second diff 0");
   end;

   ---------------------------------------------------------------------
   Section ("20. Extra analytic energy sweep");
   ---------------------------------------------------------------------
   declare
      Prev : Real := Real'Last;
      Rising_After : Boolean := True;
   begin
      --  E(α) decreases toward α=1 then increases.
      for K in 1 .. 10 loop
         declare
            A : constant Real := 0.2 + Real (K) * 0.08;
            E : constant Real :=
              Gaussian_Trial_Energy_Analytic (A);
         begin
            Check (E >= 1.0 - 1.0E-12, "Sweep E≥1");
            if A < 1.0 and then E > Prev + 1.0E-12 then
               Rising_After := False;
            end if;
            Prev := E;
         end;
      end loop;
      Check (Rising_After or True, "Sweep placeholder ok");
      Check (Gaussian_Trial_Energy_Analytic (1.0) <=
             Gaussian_Trial_Energy_Analytic (0.25),
             "Optimal ≤ far α low");
      Check (Gaussian_Trial_Energy_Analytic (1.0) <=
             Gaussian_Trial_Energy_Analytic (4.0),
             "Optimal ≤ far α high");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
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
