--  Ground_State body — exact spectra, discrete H, Jacobi, variational, nodes.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Ground_State
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   Pi : constant Real := 3.141592653589793_23846;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Pi_Value return Real is
   begin
      return Pi;
   end Pi_Value;

   function Clamp (V, Lo, Hi : Real) return Real is
   begin
      if V < Lo then
         return Lo;
      elsif V > Hi then
         return Hi;
      else
         return V;
      end if;
   end Clamp;

   function Dot (A, B : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in A'Range loop
         S := S + A (I) * B (I);
      end loop;
      return S;
   end Dot;

   function Norm2 (X : Vector) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      if S < 0.0 then
         return 0.0;
      end if;
      return Non_Negative (S);
   end Norm2;

   function Norm (X : Vector) return Non_Negative is
      S2 : constant Non_Negative := Norm2 (X);
   begin
      if S2 = 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Real (S2)));
   end Norm;

   procedure Normalize_In_Place (X : in out Vector) is
      Nrm : constant Real := Real (Norm (X));
   begin
      if Nrm < Epsilon_Tol then
         raise Degenerate;
      end if;
      for I in X'Range loop
         X (I) := X (I) / Nrm;
      end loop;
   end Normalize_In_Place;

   -------------------------------------------------------------------------
   -- Exact infinite well
   -------------------------------------------------------------------------

   function Infinite_Well_Energy
     (N     : Positive;
      L     : Positive_Real;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Positive_Real
   is
      Nn : constant Real := Real (N);
      Num : constant Real :=
        Nn * Nn * Pi * Pi * Hbar * Hbar;
      Den : constant Real := 2.0 * Mass * L * L;
   begin
      return Positive_Real (Num / Den);
   end Infinite_Well_Energy;

   function Infinite_Well_Ground_Energy
     (L    : Positive_Real;
      Hbar : Positive_Real := Default_Hbar;
      Mass : Positive_Real := Default_Mass) return Positive_Real
   is
   begin
      return Infinite_Well_Energy (1, L, Hbar, Mass);
   end Infinite_Well_Ground_Energy;

   function Infinite_Well_Psi
     (N : Positive;
      X : Real;
      L : Positive_Real) return Real
   is
   begin
      if X <= 0.0 or else X >= L then
         return 0.0;
      end if;
      return Math.Sqrt (2.0 / L)
        * Math.Sin (Real (N) * Pi * X / L);
   end Infinite_Well_Psi;

   -------------------------------------------------------------------------
   -- Exact harmonic oscillator
   -------------------------------------------------------------------------

   function Harmonic_Energy
     (N     : Natural;
      Omega : Positive_Real;
      Hbar  : Positive_Real := Default_Hbar) return Positive_Real
   is
   begin
      return Positive_Real ((Real (N) + 0.5) * Hbar * Omega);
   end Harmonic_Energy;

   function Zero_Point_Energy
     (Omega : Positive_Real;
      Hbar  : Positive_Real := Default_Hbar) return Positive_Real
   is
   begin
      return Positive_Real (0.5 * Hbar * Omega);
   end Zero_Point_Energy;

   function Harmonic_Ground_Psi
     (X     : Real;
      Omega : Positive_Real;
      Mass  : Positive_Real := Default_Mass;
      Hbar  : Positive_Real := Default_Hbar) return Real
   is
      --  (m ω / (π ħ))^{1/4} exp(− m ω x² / (2 ħ))
      Pref : constant Real :=
        Math.Sqrt (Math.Sqrt (Mass * Omega / (Pi * Hbar)));
      Exp_Arg : constant Real :=
        -0.5 * Mass * Omega * X * X / Hbar;
   begin
      if Exp_Arg < -80.0 then
         return 0.0;
      end if;
      return Pref * Math.Exp (Exp_Arg);
   end Harmonic_Ground_Psi;

   -------------------------------------------------------------------------
   -- Grid helpers
   -------------------------------------------------------------------------

   function Make_Uniform_Grid
     (X_Min : Real;
      X_Max : Real;
      N     : Dim_N) return Wave
   is
      Result : Wave (1 .. N);
      DX     : constant Real := (X_Max - X_Min) / Real (N - 1);
   begin
      for I in 1 .. N loop
         Result (I) := X_Min + Real (I - 1) * DX;
      end loop;
      return Result;
   end Make_Uniform_Grid;

   function Grid_Spacing (X_Min, X_Max : Real; N : Dim_N) return Positive_Real
   is
   begin
      return Positive_Real ((X_Max - X_Min) / Real (N - 1));
   end Grid_Spacing;

   function Build_Discrete_Hamiltonian
     (X     : Wave;
      V     : Wave;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Matrix
   is
      N  : constant Dim_N := X'Length;
      H  : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      DX : Real;
      T  : Real;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      DX := X (X'First + 1) - X (X'First);
      if DX <= 0.0 then
         raise Invalid_Argument;
      end if;
      --  Verify uniform spacing (educational check; tolerate tiny jitter).
      for I in X'First .. X'Last - 1 loop
         if abs ((X (I + 1) - X (I)) - DX) > 1.0E-8 * abs (DX) then
            raise Invalid_Argument;
         end if;
      end loop;

      T := (Hbar * Hbar) / (2.0 * Mass * DX * DX);
      for I in 1 .. N loop
         H (I, I) := 2.0 * T + V (V'First + (I - 1));
         if I > 1 then
            H (I, I - 1) := -T;
         end if;
         if I < N then
            H (I, I + 1) := -T;
         end if;
      end loop;
      return H;
   end Build_Discrete_Hamiltonian;

   function Build_Infinite_Well_Hamiltonian
     (L     : Positive_Real;
      N     : Dim_N;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Matrix
   is
      --  Interior points between Dirichlet walls at 0 and L.
      DX : constant Real := L / Real (N + 1);
      X  : Wave (1 .. N);
      V  : constant Wave (1 .. N) := [others => 0.0];
   begin
      for I in 1 .. N loop
         X (I) := Real (I) * DX;
      end loop;
      return Build_Discrete_Hamiltonian (X, V, Hbar, Mass);
   end Build_Infinite_Well_Hamiltonian;

   function Build_Harmonic_Hamiltonian
     (Omega : Positive_Real;
      X_Min : Real;
      X_Max : Real;
      N     : Dim_N;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Matrix
   is
      X : constant Wave := Make_Uniform_Grid (X_Min, X_Max, N);
      V : Wave (1 .. N);
   begin
      for I in 1 .. N loop
         V (I) := 0.5 * Mass * Omega * Omega * X (I) * X (I);
      end loop;
      return Build_Discrete_Hamiltonian (X, V, Hbar, Mass);
   end Build_Harmonic_Hamiltonian;

   -------------------------------------------------------------------------
   -- Jacobi eigensolver
   -------------------------------------------------------------------------

   procedure Sort_Eigenpairs
     (Eigenvals : in out Vector;
      Y         : in out Matrix;
      N         : Dim_N)
   is
   begin
      for I in 1 .. N - 1 loop
         declare
            Min_I : Dim_N := I;
         begin
            for J in I + 1 .. N loop
               if Eigenvals (J) < Eigenvals (Min_I) then
                  Min_I := J;
               end if;
            end loop;
            if Min_I /= I then
               declare
                  Tmp : constant Real := Eigenvals (I);
               begin
                  Eigenvals (I) := Eigenvals (Min_I);
                  Eigenvals (Min_I) := Tmp;
               end;
               for R in 1 .. N loop
                  declare
                     Tmp : constant Real := Y (R, I);
                  begin
                     Y (R, I) := Y (R, Min_I);
                     Y (R, Min_I) := Tmp;
                  end;
               end loop;
            end if;
         end;
      end loop;
   end Sort_Eigenpairs;

   procedure Eigen_2x2
     (A11, A12, A22 : Real;
      Lam1, Lam2    : out Real;
      V1x, V1y      : out Real;
      V2x, V2y      : out Real)
   is
      Diff : constant Real := A11 - A22;
      Disc : constant Real :=
        Math.Sqrt (Diff * Diff + 4.0 * A12 * A12);
      Trace : constant Real := A11 + A22;
      Nrm   : Real;
   begin
      Lam1 := 0.5 * (Trace - Disc);
      Lam2 := 0.5 * (Trace + Disc);
      if abs (A12) < 1.0E-15 and then abs (Diff) < 1.0E-15 then
         V1x := 1.0;
         V1y := 0.0;
         V2x := 0.0;
         V2y := 1.0;
      elsif abs (A12) >= abs (Diff) then
         V1x := A12;
         V1y := Lam1 - A11;
         Nrm := Math.Sqrt (V1x * V1x + V1y * V1y);
         if Nrm > 0.0 then
            V1x := V1x / Nrm;
            V1y := V1y / Nrm;
         end if;
         V2x := -V1y;
         V2y := V1x;
      else
         V1x := Lam1 - A22;
         V1y := A12;
         Nrm := Math.Sqrt (V1x * V1x + V1y * V1y);
         if Nrm > 0.0 then
            V1x := V1x / Nrm;
            V1y := V1y / Nrm;
         end if;
         V2x := -V1y;
         V2y := V1x;
      end if;
   end Eigen_2x2;

   procedure Jacobi_Symmetric
     (H         : in out Matrix;
      Y         : out Matrix;
      Eigenvals : out Vector;
      N         : Dim_N;
      Tol       : Real := Jacobi_Tol)
   is
      Max_Sweeps : constant Natural := 80;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            if I = J then
               Y (I, J) := 1.0;
            else
               Y (I, J) := 0.0;
            end if;
         end loop;
      end loop;

      if N = 1 then
         Eigenvals (1) := H (1, 1);
         return;
      end if;

      if N = 2 then
         declare
            L1, L2, V1x, V1y, V2x, V2y : Real;
         begin
            Eigen_2x2
              (H (1, 1), H (1, 2), H (2, 2),
               L1, L2, V1x, V1y, V2x, V2y);
            H (1, 1) := L1;
            H (2, 2) := L2;
            H (1, 2) := 0.0;
            H (2, 1) := 0.0;
            Y (1, 1) := V1x;
            Y (2, 1) := V1y;
            Y (1, 2) := V2x;
            Y (2, 2) := V2y;
            Eigenvals (1) := L1;
            Eigenvals (2) := L2;
            return;
         end;
      end if;

      for Sweep in 1 .. Max_Sweeps loop
         declare
            Off : Real := 0.0;
         begin
            for I in 1 .. N loop
               for J in I + 1 .. N loop
                  Off := Off + abs (H (I, J));
               end loop;
            end loop;
            exit when Off < Tol * Real (N);

            for P in 1 .. N - 1 loop
               for Q in P + 1 .. N loop
                  declare
                     App : constant Real := H (P, P);
                     Aqq : constant Real := H (Q, Q);
                     Apq : constant Real := H (P, Q);
                  begin
                     if abs (Apq) > Tol then
                        declare
                           Tau : constant Real :=
                             (Aqq - App) / (2.0 * Apq);
                           T_Rot : Real;
                           C, S  : Real;
                        begin
                           if Tau >= 0.0 then
                              T_Rot :=
                                1.0 /
                                (Tau + Math.Sqrt (1.0 + Tau * Tau));
                           else
                              T_Rot :=
                                -1.0 /
                                (-Tau + Math.Sqrt (1.0 + Tau * Tau));
                           end if;
                           C := 1.0 / Math.Sqrt (1.0 + T_Rot * T_Rot);
                           S := T_Rot * C;

                           H (P, P) := App - T_Rot * Apq;
                           H (Q, Q) := Aqq + T_Rot * Apq;
                           H (P, Q) := 0.0;
                           H (Q, P) := 0.0;

                           for R in 1 .. N loop
                              if R /= P and then R /= Q then
                                 declare
                                    Trp : constant Real := H (R, P);
                                    Trq : constant Real := H (R, Q);
                                 begin
                                    H (R, P) := C * Trp - S * Trq;
                                    H (P, R) := H (R, P);
                                    H (R, Q) := S * Trp + C * Trq;
                                    H (Q, R) := H (R, Q);
                                 end;
                              end if;
                           end loop;

                           for R in 1 .. N loop
                              declare
                                 Yrp : constant Real := Y (R, P);
                                 Yrq : constant Real := Y (R, Q);
                              begin
                                 Y (R, P) := C * Yrp - S * Yrq;
                                 Y (R, Q) := S * Yrp + C * Yrq;
                              end;
                           end loop;
                        end;
                     end if;
                  end;
               end loop;
            end loop;
         end;
      end loop;

      for I in 1 .. N loop
         Eigenvals (I) := H (I, I);
      end loop;
      Sort_Eigenpairs (Eigenvals, Y, N);
   end Jacobi_Symmetric;

   procedure Lowest_Eigenpair
     (H      : Matrix;
      Energy : out Real;
      Psi    : out Vector;
      N      : Dim_N)
   is
      Work : Matrix := H;
      Y    : Matrix (1 .. N, 1 .. N);
      Eigs : Vector (1 .. N);
   begin
      Jacobi_Symmetric (Work, Y, Eigs, N);
      Energy := Eigs (1);
      for I in 1 .. N loop
         Psi (I) := Y (I, 1);
      end loop;
      --  Prefer a phase with positive max component (nodeless ground often >0).
      declare
         Max_Abs : Real := 0.0;
         Max_I   : Index_N := 1;
      begin
         for I in 1 .. N loop
            if abs (Psi (I)) > Max_Abs then
               Max_Abs := abs (Psi (I));
               Max_I := I;
            end if;
         end loop;
         if Psi (Max_I) < 0.0 then
            for I in 1 .. N loop
               Psi (I) := -Psi (I);
            end loop;
         end if;
      end;
   end Lowest_Eigenpair;

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      Y : Vector (X'Range) := [others => 0.0];
   begin
      for I in A'Range (1) loop
         declare
            S : Real := 0.0;
         begin
            for J in A'Range (2) loop
               S := S + A (I, J) * X (J);
            end loop;
            Y (I) := S;
         end;
      end loop;
      return Y;
   end Mat_Vec;

   function Rayleigh_Quotient (H : Matrix; Psi : Vector) return Real is
      Nrm2 : constant Real := Real (Norm2 (Psi));
      Ax   : Vector (Psi'Range);
      Num  : Real := 0.0;
   begin
      if Nrm2 < Epsilon_Tol then
         raise Degenerate;
      end if;
      Ax := Mat_Vec (H, Psi);
      for I in Psi'Range loop
         Num := Num + Psi (I) * Ax (I);
      end loop;
      return Num / Nrm2;
   end Rayleigh_Quotient;

   function Residual_Norm
     (H : Matrix; Psi : Vector; Energy : Real) return Non_Negative
   is
      Ax : constant Vector := Mat_Vec (H, Psi);
      R  : Vector (Psi'Range);
   begin
      for I in Psi'Range loop
         R (I) := Ax (I) - Energy * Psi (I);
      end loop;
      return Norm (R);
   end Residual_Norm;

   -------------------------------------------------------------------------
   -- Nodes
   -------------------------------------------------------------------------

   function Count_Sign_Changes (Psi : Wave) return Natural is
      Count : Natural := 0;
      Last  : Real := 0.0;
      Found : Boolean := False;
   begin
      for I in Psi'Range loop
         if abs (Psi (I)) > 1.0E-14 then
            if Found and then Last * Psi (I) < 0.0 then
               Count := Count + 1;
            end if;
            Last := Psi (I);
            Found := True;
         end if;
      end loop;
      return Count;
   end Count_Sign_Changes;

   function Is_Nodeless_Interior (Psi : Wave) return Boolean is
   begin
      return Count_Sign_Changes (Psi) = 0;
   end Is_Nodeless_Interior;

   -------------------------------------------------------------------------
   -- Degeneracy
   -------------------------------------------------------------------------

   function Degeneracy_Of_Level
     (Eigenvals : Vector;
      Index     : Index_N;
      Tol       : Real := 1.0E-8) return Positive
   is
      Target : constant Real := Eigenvals (Index);
      Count  : Natural := 0;
   begin
      for I in Eigenvals'Range loop
         if abs (Eigenvals (I) - Target) <= Tol then
            Count := Count + 1;
         end if;
      end loop;
      if Count = 0 then
         return 1;
      end if;
      return Positive (Count);
   end Degeneracy_Of_Level;

   function Isotropic_2D_Oscillator_Degeneracy (Total_Quanta : Natural)
     return Positive
   is
   begin
      return Positive (Total_Quanta + 1);
   end Isotropic_2D_Oscillator_Degeneracy;

   function Make_Equal_Diagonal_2x2 (Lam : Real) return Matrix is
      H : Matrix (1 .. 2, 1 .. 2) := [others => [others => 0.0]];
   begin
      H (1, 1) := Lam;
      H (2, 2) := Lam;
      return H;
   end Make_Equal_Diagonal_2x2;

   -------------------------------------------------------------------------
   -- Variational Gaussian
   -------------------------------------------------------------------------

   function Variational_Gaussian_Energy
     (Alpha : Positive_Real;
      Omega : Positive_Real;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Positive_Real
   is
      --  E(α) = ħ² α / (4 m) + m ω² / (4 α)
      Kinetic : constant Real := (Hbar * Hbar * Alpha) / (4.0 * Mass);
      Pot     : constant Real := (Mass * Omega * Omega) / (4.0 * Alpha);
   begin
      return Positive_Real (Kinetic + Pot);
   end Variational_Gaussian_Energy;

   function Optimal_Gaussian_Alpha
     (Omega : Positive_Real;
      Mass  : Positive_Real := Default_Mass;
      Hbar  : Positive_Real := Default_Hbar) return Positive_Real
   is
   begin
      return Positive_Real (Mass * Omega / Hbar);
   end Optimal_Gaussian_Alpha;

   procedure Optimize_Gaussian_Trial
     (Omega       : Positive_Real;
      Best_Alpha  : out Positive_Real;
      Best_Energy : out Positive_Real;
      Alpha_Lo    : Positive_Real := 0.05;
      Alpha_Hi    : Positive_Real := 20.0;
      Steps       : Positive := 80;
      Hbar        : Positive_Real := Default_Hbar;
      Mass        : Positive_Real := Default_Mass)
   is
      Best_A : Real := Alpha_Lo;
      Best_E : Real := Real'Last;
      A, E   : Real;
      H      : constant Real :=
        (Alpha_Hi - Alpha_Lo) / Real (Steps);
   begin
      for K in 0 .. Steps loop
         A := Alpha_Lo + Real (K) * H;
         if A < Real'Model_Small then
            A := Real'Model_Small;
         end if;
         E := Variational_Gaussian_Energy
           (Positive_Real (A), Omega, Hbar, Mass);
         if E < Best_E then
            Best_E := E;
            Best_A := A;
         end if;
      end loop;
      Best_Alpha := Positive_Real (Best_A);
      Best_Energy := Positive_Real (Best_E);
   end Optimize_Gaussian_Trial;

end Ground_State;
