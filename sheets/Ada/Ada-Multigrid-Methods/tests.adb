--  Standalone test suite for Multigrid_Methods (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;
with Multigrid_Methods; use Multigrid_Methods;

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

   function F_Rhs_Sin (X : Real) return Real is
   begin
      --  −u'' = π² sin(π x) for u = sin(π x)
      return Pi * Pi * Sin (Pi * X);
   end F_Rhs_Sin;

   function F_Quad (X : Real) return Real is
   begin
      return X * (1.0 - X);
   end F_Quad;

   function Sample_Sin is new Sample (F_Sin_Pi);
   function Sample_Rhs is new Sample (F_Rhs_Sin);
   function Sample_Quad is new Sample (F_Quad);

   function Make_Zero (N : Positive) return Grid is
      Z : constant Grid (1 .. N) := [others => 0.0];
   begin
      return Z;
   end Make_Zero;

begin
   ---------------------------------------------------------------------
   Section ("1. Near / Abs_Error / Vec_Near");
   ---------------------------------------------------------------------
   Check (Near (1.0, 1.0 + 1.0E-12), "Near equal");
   Check (not Near (1.0, 2.0), "Near unequal");
   Check (Near (Abs_Error (3.0, 5.0), 2.0), "Abs_Error");
   declare
      A : constant Grid := [1.0, 2.0, 3.0];
      B : constant Grid := [1.0, 2.0, 3.0];
      C : constant Grid := [1.0, 2.0, 4.0];
   begin
      Check (Vec_Near (A, B), "Vec_Near equal");
      Check (not Vec_Near (A, C), "Vec_Near unequal");
   end;

   ---------------------------------------------------------------------
   Section ("2. X_At / Sample / L2 / Max_Error");
   ---------------------------------------------------------------------
   Check (Near (X_At (0.0, 0.25, 1), 0.0), "X_At first");
   Check (Near (X_At (0.0, 0.25, 5), 1.0), "X_At last");
   declare
      H : constant Real := 0.25;
      U : constant Grid := Sample_Quad (5, H);
   begin
      Check (U'Length = 5, "Sample length");
      Check (Near (U (1), 0.0), "Sample quad left");
      Check (Near (U (5), 0.0), "Sample quad right");
      Check (Near (U (3), 0.25), "Sample quad mid");
      Check (Near (L2_Error (U, U, H), 0.0), "L2_Error self");
      Check (Near (Max_Error (U, U), 0.0), "Max_Error self");
   end;

   ---------------------------------------------------------------------
   Section ("3. Coarse_Length / Compatible_Sizes");
   ---------------------------------------------------------------------
   Check (Coarse_Length (5) = 3, "Coarse 5→3");
   Check (Coarse_Length (9) = 5, "Coarse 9→5");
   Check (Coarse_Length (17) = 9, "Coarse 17→9");
   Check (Coarse_Length (65) = 33, "Coarse 65→33");
   Check (Compatible_Sizes (9, 5), "Compatible 9/5");
   Check (not Compatible_Sizes (8, 4), "Incompatible even fine");
   Check (not Compatible_Sizes (9, 4), "Incompatible wrong coarse");
   Check (not Compatible_Sizes (2, 1), "Incompatible short");

   ---------------------------------------------------------------------
   Section ("4. Apply_Poisson_1D on manufactured u=sin(πx)");
   ---------------------------------------------------------------------
   declare
      N  : constant Positive := 17;
      H  : constant Real := 1.0 / Real (N - 1);
      U  : constant Grid := Sample_Sin (N, H);
      F  : constant Grid := Sample_Rhs (N, H);
      Au : constant Grid := Apply_Poisson_1D (U, H);
      Max_E : Real := 0.0;
      D     : Real;
   begin
      Check (Au'Length = N, "Apply length");
      Check (Near (Au (1), 0.0) and then Near (Au (N), 0.0),
             "Apply ends zero");
      for J in 2 .. N - 1 loop
         D := abs (Au (J) - F (J));
         if D > Max_E then
            Max_E := D;
         end if;
      end loop;
      --  O(h²) truncation; H=1/16 → expect ~1e-2 or better
      Check (Max_E < 0.05, "Apply ≈ π² sin on interiors");
      Check (Residual_L2 (U, F, H) < 0.03, "Residual of continuous O(h^2)");
   end;

   ---------------------------------------------------------------------
   Section ("5. Apply_Poisson_1D on quadratic −u''=2");
   ---------------------------------------------------------------------
   declare
      N  : constant Positive := 9;
      H  : constant Real := 1.0 / Real (N - 1);
      U  : constant Grid := Sample_Quad (N, H);
      Au : constant Grid := Apply_Poisson_1D (U, H);
      Ok : Boolean := True;
   begin
      --  u=x(1−x), −u''=2, but Apply returns (+u'' stencil of −(−u''))?
      --  A u = (−u_{j−1}+2u_j−u_{j+1})/H² = −u'' ≈ 2
      for J in 2 .. N - 1 loop
         if not Near (Au (J), 2.0, 1.0E-8) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "Quadratic: A u = 2 exactly");
   end;

   ---------------------------------------------------------------------
   Section ("6. Smooth_Jacobi / Smooth_Gauss_Seidel reduce residual");
   ---------------------------------------------------------------------
   declare
      N   : constant Positive := 33;
      H   : constant Real := 1.0 / Real (N - 1);
      F   : constant Grid := Sample_Rhs (N, H);
      U_J : Grid := Make_Zero (N);
      U_G : Grid := Make_Zero (N);
      R0, Rj, Rg : Real;
   begin
      R0 := Residual_L2 (U_J, F, H);
      Smooth_Jacobi (U_J, F, H, 20, Default_Omega);
      Smooth_Gauss_Seidel (U_G, F, H, 20);
      Rj := Residual_L2 (U_J, F, H);
      Rg := Residual_L2 (U_G, F, H);
      Check (Rj < R0, "Jacobi reduces residual");
      Check (Rg < R0, "GS reduces residual");
      Check (Rg < Rj, "GS typically beats Jacobi (same sweeps)");
      Check (Near (U_J (1), 0.0) and then Near (U_J (N), 0.0),
             "Jacobi holds Dirichlet");
      Check (Near (U_G (1), 0.0) and then Near (U_G (N), 0.0),
             "GS holds Dirichlet");
   end;

   ---------------------------------------------------------------------
   Section ("7. Restrict_Injection size and values");
   ---------------------------------------------------------------------
   declare
      Fine : constant Grid :=
        [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
      C    : constant Grid := Restrict_Injection (Fine);
   begin
      Check (C'Length = 5, "Injection length 9→5");
      Check (Near (C (1), 0.0), "Injection C1");
      Check (Near (C (2), 2.0), "Injection C2");
      Check (Near (C (3), 4.0), "Injection C3");
      Check (Near (C (4), 6.0), "Injection C4");
      Check (Near (C (5), 8.0), "Injection C5");
   end;

   ---------------------------------------------------------------------
   Section ("8. Restrict_Full_Weighting 1-2-1");
   ---------------------------------------------------------------------
   declare
      Fine : constant Grid :=
        [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
      C    : constant Grid := Restrict_Full_Weighting (Fine);
   begin
      Check (C'Length = 5, "FW length 9→5");
      Check (Near (C (1), 0.0), "FW ends left");
      Check (Near (C (5), 8.0), "FW ends right");
      --  j=2 centre fine idx 3: (1 + 2*2 + 3)/4 = 2
      Check (Near (C (2), 2.0), "FW interior j=2");
      --  j=3 centre fine idx 5: (3 + 2*4 + 5)/4 = 4
      Check (Near (C (3), 4.0), "FW interior j=3");
      --  j=4 centre fine idx 7: (5 + 2*6 + 7)/4 = 6
      Check (Near (C (4), 6.0), "FW interior j=4");
   end;

   ---------------------------------------------------------------------
   Section ("9. Prolong_Linear");
   ---------------------------------------------------------------------
   declare
      Coarse : constant Grid := [0.0, 2.0, 4.0, 6.0, 8.0];
      Fine   : constant Grid := Prolong_Linear (Coarse, 9);
   begin
      Check (Fine'Length = 9, "Prolong length");
      Check (Near (Fine (1), 0.0), "Prolong odd 1");
      Check (Near (Fine (2), 1.0), "Prolong even 2");
      Check (Near (Fine (3), 2.0), "Prolong odd 3");
      Check (Near (Fine (4), 3.0), "Prolong even 4");
      Check (Near (Fine (5), 4.0), "Prolong odd 5");
      Check (Near (Fine (9), 8.0), "Prolong odd 9");
   end;

   ---------------------------------------------------------------------
   Section ("10. Injection of a coarse-smooth mode");
   ---------------------------------------------------------------------
   declare
      --  Coarse mode sampled on fine odd nodes; injection recovers it
      Nc : constant Positive := 5;
      Nf : constant Positive := 9;
      Hc : constant Real := 1.0 / Real (Nc - 1);
      Coarse : constant Grid := Sample_Sin (Nc, Hc);
      Fine   : Grid (1 .. Nf) := [others => 0.0];
      Back   : Grid (1 .. Nc);
   begin
      --  Place coarse samples on odd fine indices via prolong
      Fine := Prolong_Linear (Coarse, Nf);
      Back := Restrict_Injection (Fine);
      Check (Vec_Near (Back, Coarse, 1.0E-12),
             "Inject(Prolong(c)) = c on smooth mode");
   end;

   ---------------------------------------------------------------------
   Section ("11. Prolong / FW adjoint-ish (scaling)");
   ---------------------------------------------------------------------
   declare
      --  <R_fw f, c> ≈ <f, P c> / 2  in 1D geometric MG (mass scaling).
      --  Check a weaker size+symmetry property: P maps Rc-size correctly
      --  and FW(P(c)) ≈ c for linear coarse vectors.
      Coarse : constant Grid := [0.0, 2.0, 4.0, 6.0, 8.0];
      Fine   : constant Grid := Prolong_Linear (Coarse, 9);
      Back   : constant Grid := Restrict_Full_Weighting (Fine);
   begin
      Check (Fine'Length = 9, "P size");
      Check (Back'Length = 5, "R size");
      --  Globally linear coarse samples: FW ∘ P = Id
      Check (Vec_Near (Back, Coarse, 1.0E-12),
             "FW(Prolong(linear)) ≈ identity");
   end;

   ---------------------------------------------------------------------
   Section ("12. Solve_Coarse_Thomas small system");
   ---------------------------------------------------------------------
   declare
      --  N=5, H=0.25, u=x(1−x), f=2
      N : constant Positive := 5;
      H : constant Real := 0.25;
      F : Grid (1 .. N) := [others => 2.0];
      U : Grid (1 .. N);
      Exact : constant Grid := Sample_Quad (N, H);
   begin
      F (1) := 0.0;
      F (N) := 0.0;
      U := Solve_Coarse_Thomas (F, H, 0.0, 0.0);
      Check (Near (U (1), 0.0) and then Near (U (N), 0.0),
             "Thomas BCs");
      Check (Vec_Near (U, Exact, 1.0E-10),
             "Thomas matches quadratic exact");
   end;

   declare
      --  sin manufactured on tiny grid — discrete solve close to continuous
      N : constant Positive := 5;
      H : constant Real := 1.0 / Real (N - 1);
      F : constant Grid := Sample_Rhs (N, H);
      U : constant Grid := Solve_Coarse_Thomas (F, H, 0.0, 0.0);
      Exact : constant Grid := Sample_Sin (N, H);
   begin
      Check (Max_Error (U, Exact) < 0.1, "Thomas sin on N=5");
   end;

   ---------------------------------------------------------------------
   Section ("13. Two_Grid_V_Cycle converges");
   ---------------------------------------------------------------------
   declare
      N  : constant Positive := 33;
      H  : constant Real := 1.0 / Real (N - 1);
      F  : constant Grid := Sample_Rhs (N, H);
      Exact : constant Grid := Sample_Sin (N, H);
      U  : Grid := Make_Zero (N);
      R0, R1 : Real;
   begin
      R0 := Residual_L2 (U, F, H);
      for K in 1 .. 8 loop
         Two_Grid_V_Cycle (U, F, H, Nu_1 => 2, Nu_2 => 2);
      end loop;
      R1 := Residual_L2 (U, F, H);
      Check (R1 < R0 * 1.0E-3, "Two-grid residual drop");
      Check (Max_Error (U, Exact) < 1.0E-3, "Two-grid near exact");
      Check (L2_Error (U, Exact, H) < 1.0E-3, "Two-grid L2 near exact");
   end;

   ---------------------------------------------------------------------
   Section ("14. V_Cycle converges");
   ---------------------------------------------------------------------
   declare
      N  : constant Positive := 65;
      H  : constant Real := 1.0 / Real (N - 1);
      F  : constant Grid := Sample_Rhs (N, H);
      Exact : constant Grid := Sample_Sin (N, H);
      U  : Grid := Make_Zero (N);
      Lev : constant Natural := 4;  -- 65→33→17→9→5 (then Thomas)
      R0, R1 : Real;
   begin
      R0 := Residual_L2 (U, F, H);
      for K in 1 .. 5 loop
         V_Cycle (U, F, H, Lev, Nu_1 => 2, Nu_2 => 2);
      end loop;
      R1 := Residual_L2 (U, F, H);
      Check (R1 < R0 * 1.0E-4, "V-cycle residual drop");
      Check (Max_Error (U, Exact) < 5.0E-4, "V-cycle near exact");
      Check (Near (U (1), 0.0) and then Near (U (N), 0.0),
             "V-cycle Dirichlet");
   end;

   ---------------------------------------------------------------------
   Section ("15. V-cycle vs pure Jacobi residual drop");
   ---------------------------------------------------------------------
   declare
      N  : constant Positive := 65;
      H  : constant Real := 1.0 / Real (N - 1);
      F  : constant Grid := Sample_Rhs (N, H);
      U_MG : Grid := Make_Zero (N);
      U_J : Grid := Make_Zero (N);
      Lev : constant Natural := 4;
      --  5 V-cycles × (2+2) smooth sweeps ≈ 20 fine smooths + coarse work
      --  Compare to 20 Jacobi sweeps alone.
      R_MG, R_J : Real;
   begin
      for K in 1 .. 5 loop
         V_Cycle (U_MG, F, H, Lev, Nu_1 => 2, Nu_2 => 2);
      end loop;
      Smooth_Jacobi (U_J, F, H, 20, Default_Omega);
      R_MG := Residual_L2 (U_MG, F, H);
      R_J  := Residual_L2 (U_J, F, H);
      Check (R_MG < R_J, "V-cycle beats equal fine Jacobi sweeps");
      Check (R_MG < R_J * 0.1, "V-cycle residual ≪ Jacobi residual");
   end;

   ---------------------------------------------------------------------
   Section ("16. Solve_Poisson_MG wrapper");
   ---------------------------------------------------------------------
   declare
      N  : constant Positive := 33;
      H  : constant Real := 1.0 / Real (N - 1);
      F  : constant Grid := Sample_Rhs (N, H);
      Exact : constant Grid := Sample_Sin (N, H);
      U  : constant Grid :=
        Solve_Poisson_MG (F, H, N_Cycles => 6, Nu_1 => 2, Nu_2 => 2);
   begin
      Check (Max_Error (U, Exact) < 1.0E-3, "Solve_Poisson_MG accuracy");
      Check (Residual_L2 (U, F, H) < 1.0E-3, "Solve_Poisson_MG residual");
   end;

   ---------------------------------------------------------------------
   Section ("17. V_Cycle with Gauss–Seidel smoother");
   ---------------------------------------------------------------------
   declare
      N  : constant Positive := 33;
      H  : constant Real := 1.0 / Real (N - 1);
      F  : constant Grid := Sample_Rhs (N, H);
      Exact : constant Grid := Sample_Sin (N, H);
      U  : Grid := Make_Zero (N);
   begin
      for K in 1 .. 5 loop
         V_Cycle
           (U, F, H, Level => 3, Nu_1 => 1, Nu_2 => 1,
            Use_Gauss_Seidel => True);
      end loop;
      Check (Max_Error (U, Exact) < 1.0E-3, "V-cycle GS near exact");
   end;

   ---------------------------------------------------------------------
   Section ("18. Level 0 is pure Thomas");
   ---------------------------------------------------------------------
   declare
      N : constant Positive := 9;
      H : constant Real := 1.0 / Real (N - 1);
      F : constant Grid := Sample_Rhs (N, H);
      Exact : constant Grid := Sample_Sin (N, H);
      U : Grid := Make_Zero (N);
      T : constant Grid := Solve_Coarse_Thomas (F, H, 0.0, 0.0);
   begin
      V_Cycle (U, F, H, Level => 0, Nu_1 => 0, Nu_2 => 0);
      Check (Vec_Near (U, T, 1.0E-12), "Level 0 ≡ Thomas");
      Check (Max_Error (U, Exact) < 0.02, "Level 0 sin accuracy");
   end;

   ---------------------------------------------------------------------
   Section ("19. Two-grid with GS");
   ---------------------------------------------------------------------
   declare
      N : constant Positive := 17;
      H : constant Real := 1.0 / Real (N - 1);
      F : constant Grid := Sample_Rhs (N, H);
      Exact : constant Grid := Sample_Sin (N, H);
      U : Grid := Make_Zero (N);
   begin
      for K in 1 .. 10 loop
         Two_Grid_V_Cycle
           (U, F, H, Nu_1 => 2, Nu_2 => 2, Use_Gauss_Seidel => True);
      end loop;
      Check (Max_Error (U, Exact) < 5.0E-3, "Two-grid GS accuracy");
   end;

   ---------------------------------------------------------------------
   Section ("20. Invalid_Argument edge cases");
   ---------------------------------------------------------------------
   Raised := False;
   begin
      declare
         Discard : constant Real := X_At (0.0, 0.0, 1);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "X_At H=0");

   Raised := False;
   begin
      declare
         U : constant Grid := [1.0, 2.0];
         Discard : constant Grid := Apply_Poisson_1D (U, 0.1);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Apply short grid");

   Raised := False;
   begin
      declare
         U : constant Grid := [1.0, 2.0, 3.0];
         Discard : constant Grid := Apply_Poisson_1D (U, -1.0);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Apply H<0");

   Raised := False;
   begin
      declare
         Discard : constant Positive := Coarse_Length (4);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Coarse_Length even N-1");

   Raised := False;
   begin
      declare
         Discard : constant Positive := Coarse_Length (2);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Coarse_Length N<3");

   Raised := False;
   begin
      declare
         Fine : constant Grid := [1.0, 2.0, 3.0, 4.0];
         Discard : constant Grid := Restrict_Injection (Fine);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Restrict incompatible");

   Raised := False;
   begin
      declare
         C : constant Grid := [0.0, 1.0, 0.0];
         Discard : constant Grid := Prolong_Linear (C, 8);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Prolong incompatible Fine_N");

   Raised := False;
   begin
      declare
         U : Grid := [0.0, 0.0, 0.0];
         F : constant Grid := [1.0, 1.0];
      begin
         Smooth_Jacobi (U, F, 0.1, 1);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Smooth length mismatch");

   Raised := False;
   begin
      declare
         U : Grid := [0.0, 0.0, 0.0];
         F : constant Grid := [0.0, 1.0, 0.0];
      begin
         Smooth_Jacobi (U, F, 0.1, 1, Omega => 0.0);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Smooth Omega=0");

   Raised := False;
   begin
      declare
         F : constant Grid := [0.0, 1.0];
         Discard : constant Grid := Solve_Coarse_Thomas (F, 0.1);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Thomas short grid");

   Raised := False;
   begin
      declare
         U : Grid := [0.0, 0.0, 0.0];
         F : constant Grid := [0.0, 1.0, 0.0];
      begin
         Two_Grid_V_Cycle (U, F, -0.5);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Two-grid H<0");

   Raised := False;
   begin
      declare
         --  N=3 cannot coarsen (Coarse_Length(3)=2? wait (3-1)/2+1=2)
         --  Actually (3-1) rem 2 = 0, Coarse_Length(3)=2, but coarse
         --  solve needs ≥3. Two_Grid on N=3: Nc=2 → Thomas fails.
         U : Grid := [0.0, 0.0, 0.0];
         F : constant Grid := [0.0, 1.0, 0.0];
      begin
         Two_Grid_V_Cycle (U, F, 0.5);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Two-grid N=3 coarse too small");

   Raised := False;
   begin
      declare
         U : Grid := Make_Zero (5);
         F : constant Grid := [0.0, 1.0, 2.0];
      begin
         V_Cycle (U, F, 0.25, Level => 1);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "V_Cycle length mismatch");

   Raised := False;
   begin
      declare
         A : constant Grid := [1.0, 2.0];
         B : constant Grid := [1.0];
         Discard : constant Real := L2_Error (A, B, 0.1);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "L2_Error length mismatch");

   Raised := False;
   begin
      declare
         F : constant Grid := Sample_Rhs (9, 0.125);
         Discard : constant Grid :=
           Solve_Poisson_MG (F, 0.125, Omega => -1.0);
      begin
         pragma Unreferenced (Discard);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Solve_Poisson_MG Omega<0");

   ---------------------------------------------------------------------
   Section ("21. Residual_L2 zero at discrete Thomas solution");
   ---------------------------------------------------------------------
   declare
      N : constant Positive := 17;
      H : constant Real := 1.0 / Real (N - 1);
      F : Grid (1 .. N) := [others => 2.0];
      U : Grid (1 .. N);
   begin
      F (1) := 0.0;
      F (N) := 0.0;
      U := Solve_Coarse_Thomas (F, H, 0.0, 0.0);
      Check (Residual_L2 (U, F, H) < 1.0E-10,
             "Thomas residual ~ 0 for f=2");
   end;

   ---------------------------------------------------------------------
   Section ("22. Default_Omega and Max_Points");
   ---------------------------------------------------------------------
   Check (Near (Default_Omega, 2.0 / 3.0), "Default_Omega = 2/3");
   Check (Coarse_Length (Max_Points) = 129, "Max_Points coarsens to 129");
   Check (Compatible_Sizes (257, 129), "257→129 compatible");

   ---------------------------------------------------------------------
   Section ("23. Extra manufactured / transfer checks");
   ---------------------------------------------------------------------
   declare
      N : constant Positive := 129;
      H : constant Real := 1.0 / Real (N - 1);
      F : constant Grid := Sample_Rhs (N, H);
      Exact : constant Grid := Sample_Sin (N, H);
      U : constant Grid :=
        Solve_Poisson_MG
          (F, H, N_Cycles => 4, Level => 5, Nu_1 => 2, Nu_2 => 2);
   begin
      Check (Max_Error (U, Exact) < 5.0E-4, "MG on N=129");
      Check (L2_Error (U, Exact, H) < 5.0E-4, "MG L2 on N=129");
   end;

   declare
      Fine : constant Grid := Sample_Sin (17, 1.0 / 16.0);
      Inj  : constant Grid := Restrict_Injection (Fine);
      FW   : constant Grid := Restrict_Full_Weighting (Fine);
   begin
      Check (Inj'Length = FW'Length, "Inj/FW same length");
      Check (Near (Inj (1), FW (1)) and then Near (Inj (Inj'Last), FW (FW'Last)),
             "Inj/FW share ends");
   end;

   declare
      U : Grid := Make_Zero (9);
      F : constant Grid := Sample_Rhs (9, 0.125);
      R_Before, R_After : Real;
   begin
      R_Before := Residual_L2 (U, F, 0.125);
      Smooth_Jacobi (U, F, 0.125, 0, Default_Omega);
      R_After := Residual_L2 (U, F, 0.125);
      Check (Near (R_Before, R_After), "Nu=0 Jacobi is no-op");
   end;

   declare
      U : Grid := Make_Zero (9);
      F : constant Grid := Sample_Rhs (9, 0.125);
   begin
      Smooth_Gauss_Seidel (U, F, 0.125, 5);
      Check (Residual_L2 (U, F, 0.125)
             < Residual_L2 (Make_Zero (9), F, 0.125),
             "GS Nu=5 helps");
   end;

   New_Line;
   Put_Line ("===================================");
   Put_Line
     ("Result: " & Natural'Image (Pass_Count) & " passed, "
      & Natural'Image (Fail_Count) & " failed");
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
