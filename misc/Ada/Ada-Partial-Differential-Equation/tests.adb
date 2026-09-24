--  Standalone test suite for Partial_Differential_Equation (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Partial_Differential_Equation; use Partial_Differential_Equation;

procedure Tests is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   Pi : constant Real := Ada.Numerics.Pi;

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

   Raised : Boolean;

   --  Analytic helpers ----------------------------------------------------

   function F_Sin_Pi (X : Real) return Real is
   begin
      return Sin (Pi * X);
   end F_Sin_Pi;

   function F_G_Sine (X : Real) return Real is
   begin
      --  −u'' = π² sin(π x) when u = sin(π x)
      return Pi * Pi * Sin (Pi * X);
   end F_G_Sine;

   function F_Quad (X : Real) return Real is
   begin
      return X * (1.0 - X);
   end F_Quad;

   function F_Sin (X : Real) return Real is
   begin
      return Sin (X);
   end F_Sin;

   function Sample_Sin_Pi is new Sample (F_Sin_Pi);
   function Sample_G_Sine is new Sample (F_G_Sine);
   function Sample_Quad   is new Sample (F_Quad);
   function Sample_Sin    is new Sample (F_Sin);

   --  Runtime wrappers so constant checks are not compile-time tautologies.
   function MP return Positive is (Max_Points);
   function Eps return Real is (Epsilon_Tol);
   function DTol return Real is (Discriminant_Tol);

begin
   Put_Line ("Partial_Differential_Equation — educational survey tests");
   Put_Line ("=========================================================");

   ---------------------------------------------------------------------
   Section ("1. Taxonomy / Classify_2nd_Order / Class_Name");
   ---------------------------------------------------------------------
   Check (Classify_2nd_Order (1.0, 0.0, 1.0) = Elliptic,
          "Laplace (1,0,1) → Elliptic");
   Check (Classify_2nd_Order (1.0, 0.0, 0.0) = Parabolic,
          "Heat (1,0,0) → Parabolic");
   Check (Classify_2nd_Order (1.0, 0.0, -1.0) = Hyperbolic,
          "Wave (1,0,-1) → Hyperbolic");
   Check (Classify_2nd_Order (0.0, 0.0, 0.0) = Degenerate,
          "Zeros → Degenerate");
   Check (Classify_2nd_Order (2.0, 0.0, 2.0) = Elliptic,
          "Scaled Laplace elliptic");
   Check (Classify_2nd_Order (1.0, 0.0, 1.0E-20) = Parabolic,
          "Near-zero disc → Parabolic");
   Check (Classify_2nd_Order (0.0, 1.0, 0.0) = Hyperbolic,
          "B=1 A=C=0 → Hyperbolic");
   Check (Classify_2nd_Order (-1.0, 0.0, -1.0) = Elliptic,
          "Negative A,C still elliptic");
   Check (Classify_2nd_Order (1.0, 3.0, 1.0) = Hyperbolic,
          "B²>AC → Hyperbolic");
   Check (Classify_2nd_Order (4.0, 2.0, 1.0) = Parabolic,
          "B²=AC exactly → Parabolic");
   Check (Class_Name (Elliptic) = "Elliptic", "Class_Name Elliptic");
   Check (Class_Name (Parabolic) = "Parabolic", "Class_Name Parabolic");
   Check (Class_Name (Hyperbolic) = "Hyperbolic", "Class_Name Hyperbolic");
   Check (Class_Name (Degenerate) = "Degenerate", "Class_Name Degenerate");

   ---------------------------------------------------------------------
   Section ("2. Near / Abs_Error / Vec_Near / L2 / Max_Error");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0), "Near equal");
   Check (Near (1.0, 1.0 + 1.0E-12), "Near tiny delta");
   Check (not Near (1.0, 2.0), "Near rejects large delta");
   Check (Near (0.0, 1.0E-12, 1.0E-9), "Near custom Tol");
   Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   Check (Near (-5.0, -5.0), "Near negatives");
   Check (Abs_Error (1.0, 1.0) = 0.0, "Abs_Error zero");
   Check (Near (Abs_Error (3.0, 1.0), 2.0), "Abs_Error 3-1");
   Check (Near (Abs_Error (-1.0, 1.0), 2.0), "Abs_Error signed");
   declare
      A : constant Grid := [1.0, 2.0, 3.0];
      B : constant Grid := [1.0, 2.0, 3.0];
      C : constant Grid := [1.0, 2.0, 3.1];
   begin
      Check (Vec_Near (A, B), "Vec_Near equal");
      Check (not Vec_Near (A, C), "Vec_Near unequal");
      Check (Vec_Near (A, C, 0.2), "Vec_Near loose Tol");
      Check (Near (Max_Error (A, B), 0.0), "Max_Error zero");
      Check (Near (Max_Error (A, C), 0.1), "Max_Error 0.1");
      Check (Near (L2_Error (A, B, 1.0), 0.0), "L2_Error zero");
      Check (L2_Error (A, C, 1.0) > 0.0, "L2_Error positive");
   end;

   ---------------------------------------------------------------------
   Section ("3. X_At / Sample");
   ---------------------------------------------------------------------
   Check (Near (X_At (0.0, 0.1, 1), 0.0), "X_At first");
   Check (Near (X_At (0.0, 0.1, 2), 0.1), "X_At second");
   Check (Near (X_At (1.0, 0.5, 3), 2.0), "X_At offset");
   declare
      F : constant Grid := Sample_Sin (5, Pi / 4.0, 0.0);
   begin
      Check (F'Length = 5, "Sample length");
      Check (Near (F (1), 0.0, 1.0E-12), "Sample sin(0)");
      Check (Near (F (3), 1.0, 1.0E-12), "Sample sin(pi/2)");
      Check (Near (F (5), 0.0, 1.0E-12), "Sample sin(pi)");
   end;
   Raised := False;
   begin
      declare
         Dummy : Real := X_At (0.0, -1.0, 1);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "X_At rejects H≤0");

   ---------------------------------------------------------------------
   Section ("4. Elliptic — Solve_Poisson_1D manufactured sin(πx)");
   ---------------------------------------------------------------------
   declare
      N_Int : constant Point_Count := 31;
      H     : constant Real := 1.0 / Real (N_Int + 1);
      --  Sample interiors for G at x = H .. N_Int*H; Exact on full grid
      G_Full : constant Grid := Sample_G_Sine (N_Int + 2, H, 0.0);
      Exact  : constant Grid := Sample_Sin_Pi (N_Int + 2, H, 0.0);
      G      : Grid (1 .. N_Int);
      U      : Grid (1 .. N_Int + 2);
      Max_E  : Real;
   begin
      for J in 1 .. N_Int loop
         G (J) := G_Full (J + 1);
      end loop;
      U := Solve_Poisson_1D (G, 0.0, 0.0, H);
      Check (U'Length = N_Int + 2, "Poisson length N+2");
      Check (Near (U (1), 0.0), "Poisson left BC");
      Check (Near (U (U'Last), 0.0), "Poisson right BC");
      Max_E := Max_Error (U, Exact);
      Check (Max_E < 1.0E-3, "Poisson sin max err < 1e-3");
      Check (L2_Error (U, Exact, H) < 1.0E-3, "Poisson sin L2 < 1e-3");
      Check (Near (U (N_Int / 2 + 2), 1.0, 5.0E-3),
             "Poisson peak near mid ≈ 1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Elliptic — Poisson quadratic −u''=2");
   ---------------------------------------------------------------------
   declare
      N_Int : constant Point_Count := 15;
      H     : constant Real := 1.0 / Real (N_Int + 1);
      G     : constant Grid (1 .. N_Int) := [others => 2.0];
      U     : constant Grid := Solve_Poisson_1D (G, 0.0, 0.0, H);
      Exact : constant Grid := Sample_Quad (N_Int + 2, H, 0.0);
   begin
      Check (Max_Error (U, Exact) < 1.0E-10, "Poisson quad essentially exact");
      Check (Near (U (1), 0.0) and then Near (U (U'Last), 0.0),
             "Poisson quad BCs");
   end;

   ---------------------------------------------------------------------
   Section ("6. Elliptic — Poisson rejects bad inputs");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         G : constant Grid (1 .. 3) := [1.0, 1.0, 1.0];
         U : constant Grid := Solve_Poisson_1D (G, 0.0, 0.0, -0.1);
         pragma Unreferenced (U);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Poisson rejects H≤0");

   Raised := False;
   begin
      declare
         --  N+2 would exceed Max_Points
         Huge_N : constant Positive := Max_Points;
         G      : constant Grid (1 .. Huge_N) := [others => 1.0];
         U      : constant Grid := Solve_Poisson_1D (G, 0.0, 0.0, 0.1);
         pragma Unreferenced (U);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Poisson rejects N+2 > Max_Points");

   ---------------------------------------------------------------------
   Section ("7. Parabolic — Heat_FTCS_Stable");
   ---------------------------------------------------------------------
   Check (Heat_FTCS_Stable (1.0, 0.1, 0.005), "Stable r=0.5");
   Check (Heat_FTCS_Stable (1.0, 0.1, 0.004), "Stable r=0.4");
   Check (not Heat_FTCS_Stable (1.0, 0.1, 0.006), "Unstable r=0.6");
   Check (not Heat_FTCS_Stable (-1.0, 0.1, 0.001), "Rejects Alpha<0");
   Check (not Heat_FTCS_Stable (1.0, -0.1, 0.001), "Rejects H≤0");
   Check (not Heat_FTCS_Stable (1.0, 0.1, -0.001), "Rejects Dt≤0");
   Check (Heat_FTCS_Stable (0.0, 0.1, 1.0), "Alpha=0 is stable (r=0)");

   ---------------------------------------------------------------------
   Section ("8. Parabolic — Heat FTCS damps sinusoid");
   ---------------------------------------------------------------------
   declare
      N     : constant Point_Count := 33;
      H     : constant Real := 1.0 / Real (N - 1);
      Alpha : constant Real := 1.0;
      --  r = 0.4 < 1/2
      Dt    : constant Real := 0.4 * H * H / Alpha;
      U     : Grid (1 .. N);
      Amp0, Amp1 : Real;
      Steps : constant Positive := 20;
   begin
      Check (Heat_FTCS_Stable (Alpha, H, Dt), "Heat setup stable");
      for J in 1 .. N loop
         U (J) := Sin (Pi * X_At (0.0, H, J));
      end loop;
      Amp0 := U (N / 2 + 1);
      for S in 1 .. Steps loop
         U := Heat_FTCS_Step (U, Alpha, H, Dt, 0.0, 0.0);
      end loop;
      Amp1 := abs (U (N / 2 + 1));
      Check (Amp1 < Amp0, "Heat damps mid amplitude");
      Check (Near (U (1), 0.0) and then Near (U (N), 0.0),
             "Heat Dirichlet ends stay 0");
      Check (Amp1 > 0.0, "Heat not fully zero after few steps");
      --  Exact factor e^{-π² α t}; discrete should be close-ish
      declare
         T_Exact : constant Real := Real (Steps) * Dt;
         Exact_Amp : constant Real := Exp (-Pi * Pi * Alpha * T_Exact);
      begin
         Check (Abs_Error (Amp1, Exact_Amp) < 0.05,
                "Heat amp near e^{-π² α t}");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Parabolic — Heat rejects unstable / bad");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0, 0.0];
         --  r = α Dt / H² = 1.0 / 0.01 = 100 >> 0.5
         V : constant Grid :=
           Heat_FTCS_Step (U, 1.0, 0.1, 1.0, 0.0, 0.0);
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Heat rejects unstable r");

   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0];  -- too short
         V : constant Grid :=
           Heat_FTCS_Step (U, 1.0, 0.1, 0.001, 0.0, 0.0);
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Heat rejects Length<3");

   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0, 0.0];
         V : constant Grid :=
           Heat_FTCS_Step (U, -1.0, 0.1, 0.001, 0.0, 0.0);
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Heat rejects Alpha<0");

   ---------------------------------------------------------------------
   Section ("10. Hyperbolic — CFL helpers");
   ---------------------------------------------------------------------
   Check (Near (CFL_Advection (1.0, 0.1, 0.05), 0.5), "CFL_Advection 0.5");
   Check (Near (CFL_Advection (2.0, 1.0, 0.25), 0.5), "CFL_Advection scaled");
   Check (Near (CFL_Wave (1.0, 0.1, 0.05), 0.5), "CFL_Wave 0.5");
   Check (Near (CFL_Wave (-2.0, 1.0, 0.4), 0.8), "CFL_Wave abs speed");
   Raised := False;
   begin
      declare
         Dummy : Real := CFL_Advection (1.0, -0.1, 0.05);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "CFL_Advection rejects H≤0");
   Raised := False;
   begin
      declare
         Dummy : Real := CFL_Wave (1.0, 0.1, -0.05);
         pragma Unreferenced (Dummy);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "CFL_Wave rejects Dt≤0");

   ---------------------------------------------------------------------
   Section ("11. Hyperbolic — Advection_Upwind transport");
   ---------------------------------------------------------------------
   declare
      N  : constant Point_Count := 40;
      H  : constant Real := 1.0 / Real (N - 1);
      C  : constant Real := 1.0;
      Dt : constant Real := 0.5 * H / C;  -- ν = 0.5
      U  : Grid (1 .. N) := [others => 0.0];
      Steps : constant Positive := 10;
      Mass0, Mass1 : Real := 0.0;
      Peak_J : Positive := 1;
   begin
      Check (Near (CFL_Advection (C, H, Dt), 0.5), "Upwind ν=0.5");
      --  Compact bump near left
      for J in 3 .. 8 loop
         U (J) := 1.0;
      end loop;
      for J in U'Range loop
         Mass0 := Mass0 + U (J);
      end loop;
      for S in 1 .. Steps loop
         U := Advection_Upwind_Step (U, C, H, Dt);
      end loop;
      for J in U'Range loop
         Mass1 := Mass1 + U (J);
         if U (J) > U (Peak_J) then
            Peak_J := J;
         end if;
      end loop;
      Check (Peak_J > 8, "Upwind bump moved right");
      Check (Near (U (1), 0.0), "Upwind inflow stays 0");
      Check (Mass1 > 0.0, "Upwind mass remains positive");
      --  ν=1 exact shift of one cell per step
      declare
         U2 : Grid (1 .. N) := [others => 0.0];
         Dt1 : constant Real := H / C;
         V  : Grid (1 .. N);
      begin
         U2 (5) := 1.0;
         V := Advection_Upwind_Step (U2, C, H, Dt1);
         Check (Near (V (5), 0.0) and then Near (V (6), 1.0),
                "Upwind ν=1 exact one-cell shift");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("12. Hyperbolic — Advection rejects bad inputs");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         U : constant Grid := [1.0, 2.0, 3.0];
         V : constant Grid := Advection_Upwind_Step (U, -1.0, 0.1, 0.01);
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Upwind rejects C<0");

   Raised := False;
   begin
      declare
         U : constant Grid := [1.0, 2.0, 3.0];
         --  ν = 2 > 1
         V : constant Grid := Advection_Upwind_Step (U, 1.0, 0.1, 0.2);
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Upwind rejects CFL>1");

   Raised := False;
   begin
      declare
         U : constant Grid := [1.0];  -- too short
         V : constant Grid := Advection_Upwind_Step (U, 1.0, 0.1, 0.01);
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Upwind rejects Length<2");

   ---------------------------------------------------------------------
   Section ("13. Hyperbolic — Wave_Leapfrog standing mode");
   ---------------------------------------------------------------------
   declare
      N     : constant Point_Count := 33;
      H     : constant Real := 1.0 / Real (N - 1);
      Cwave : constant Real := 1.0;
      --  λ = 0.5
      Dt    : constant Real := 0.5 * H / Cwave;
      U0, U1, U2 : Grid (1 .. N);
      Omega : constant Real := Pi * Cwave;  -- mode sin(πx) cos(ωt)
      T1, T2 : Real;
      Amp   : Real;
   begin
      Check (Near (CFL_Wave (Cwave, H, Dt), 0.5), "Wave λ=0.5");
      --  Exact: u(x,t)=sin(πx) cos(ω t), ω=π c
      --  Start at t=0: U_Curr = sin(πx), U_Prev ≈ sin(πx) cos(−ω Dt)
      T1 := 0.0;
      T2 := -Dt;
      for J in 1 .. N loop
         U1 (J) := Sin (Pi * X_At (0.0, H, J)) * Cos (Omega * T1);
         U0 (J) := Sin (Pi * X_At (0.0, H, J)) * Cos (Omega * T2);
      end loop;
      U2 := Wave_Leapfrog_Step (U1, U0, Cwave, H, Dt, 0.0, 0.0);
      Check (Near (U2 (1), 0.0) and then Near (U2 (N), 0.0),
             "Wave Dirichlet ends");
      Amp := abs (U2 (N / 2 + 1));
      declare
         Exact_Mid : constant Real :=
           Cos (Omega * Dt);  -- sin(π/2)=1 at mid for odd N
      begin
         Check (Abs_Error (Amp, abs (Exact_Mid)) < 0.05,
                "Wave mid ≈ cos(ω Δt)");
      end;
      --  Advance several steps; energy (amp) should stay O(1)
      declare
         Prev, Curr, Next : Grid (1 .. N);
         Max_Amp : Real := 0.0;
      begin
         Prev := U0;
         Curr := U1;
         for S in 1 .. 40 loop
            Next := Wave_Leapfrog_Step
              (Curr, Prev, Cwave, H, Dt, 0.0, 0.0);
            Prev := Curr;
            Curr := Next;
            if abs (Curr (N / 2 + 1)) > Max_Amp then
               Max_Amp := abs (Curr (N / 2 + 1));
            end if;
         end loop;
         Check (Max_Amp < 1.5, "Wave amp bounded under CFL");
         Check (Max_Amp > 0.5, "Wave amp not collapsed");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Hyperbolic — Wave rejects bad inputs");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0, 0.0];
         V : constant Grid :=
           Wave_Leapfrog_Step (U, U, 1.0, 0.1, 0.5, 0.0, 0.0);  -- λ=5
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Wave rejects CFL>1");

   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0];
         V : constant Grid :=
           Wave_Leapfrog_Step (U, U, 1.0, 0.1, 0.01, 0.0, 0.0);
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Wave rejects Length<3");

   Raised := False;
   begin
      declare
         U : constant Grid := [0.0, 1.0, 0.0];
         P : constant Grid := [0.0, 0.5];  -- mismatch
         V : constant Grid :=
           Wave_Leapfrog_Step (U, P, 1.0, 0.1, 0.01, 0.0, 0.0);
         pragma Unreferenced (V);
      begin
         null;
      end;
   exception
      when Invalid_Argument => Raised := True;
   end;
   Check (Raised, "Wave rejects length mismatch");

   ---------------------------------------------------------------------
   Section ("15. Extra classification edge cases");
   ---------------------------------------------------------------------
   Check (Classify_2nd_Order (1.0, 1.0E-7, 1.0) = Elliptic,
          "Tiny B still elliptic for Laplace-like");
   --  Disc = 0 − 0·C = 0 → Parabolic when not all zero
   Check (Classify_2nd_Order (0.0, 0.0, 1.0) = Parabolic,
          "A=B=0 C=1 → Parabolic (disc=0)");
   Check (Classify_2nd_Order (0.0, 0.0, 1.0) /= Degenerate,
          "A=B=0 C≠0 is not Degenerate");
   Check (Classify_2nd_Order (5.0, 0.0, 5.0) = Elliptic,
          "5 u_xx + 5 u_yy elliptic");
   Check (Classify_2nd_Order (-2.0, 0.0, 2.0) = Hyperbolic,
          "−2 u_xx + 2 u_yy hyperbolic");

   ---------------------------------------------------------------------
   Section ("16. Heat multi-step residual + Poisson BC nonzero");
   ---------------------------------------------------------------------
   declare
      N_Int : constant Point_Count := 7;
      H     : constant Real := 1.0 / Real (N_Int + 1);
      G     : constant Grid (1 .. N_Int) := [others => 0.0];
      --  −u''=0, u(0)=1, u(1)=3 → linear u=1+2x
      U     : constant Grid := Solve_Poisson_1D (G, 1.0, 3.0, H);
      Ok    : Boolean := True;
      X, Exact : Real;
   begin
      for J in U'Range loop
         X := X_At (0.0, H, J);
         Exact := 1.0 + 2.0 * X;
         if Abs_Error (U (J), Exact) > 1.0E-10 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Poisson Laplace linear exact with BCs");
   end;

   declare
      N     : constant Point_Count := 17;
      H     : constant Real := 1.0 / Real (N - 1);
      Alpha : constant Real := 0.5;
      Dt    : constant Real := 0.25 * H * H / Alpha;
      U     : Grid (1 .. N);
   begin
      for J in 1 .. N loop
         U (J) := Sin (Pi * X_At (0.0, H, J));
      end loop;
      for S in 1 .. 5 loop
         U := Heat_FTCS_Step (U, Alpha, H, Dt, 0.0, 0.0);
      end loop;
      Check (Max_Error (U, U) = 0.0, "Max_Error identity zero");
      Check (Vec_Near (U, U), "Vec_Near identity");
      Check (U (N / 2 + 1) < Sin (Pi * 0.5), "Heat mid decreased");
   end;

   ---------------------------------------------------------------------
   Section ("17. Constants / Max_Points sanity");
   ---------------------------------------------------------------------
   Check (MP = 512, "Max_Points = 512");
   Check (Eps > 0.0, "Epsilon_Tol positive");
   Check (DTol > 0.0, "Discriminant_Tol positive");
   Check (Near (0.0, 0.0), "Near(0,0)");
   Check (Abs_Error (0.0, 0.0) = 0.0, "Abs_Error(0,0)");

   --  Summary -------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("PASSED:" & Pass_Count'Image);
   Put_Line ("FAILED:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
