--  Multigrid_Methods body — 1D Poisson operator, smoothers, transfers,
--  Thomas coarsest solve, two-grid and recursive V-cycle.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Multigrid_Methods
  with SPARK_Mode => Off
is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   procedure Check_H (H : Real) is
   begin
      if H <= 0.0 then
         raise Invalid_Argument;
      end if;
   end Check_H;

   procedure Check_Same_Length (A, B : Grid) is
   begin
      if A'Length /= B'Length then
         raise Invalid_Argument;
      end if;
   end Check_Same_Length;

   procedure Check_Grid_Min3 (G : Grid) is
   begin
      if G'Length < 3 then
         raise Invalid_Argument;
      end if;
   end Check_Grid_Min3;

   function Max_Level_For (N : Positive) return Natural is
      M : Positive := N;
      L : Natural := 0;
   begin
      while M > 3 and then (M - 1) rem 2 = 0 loop
         M := (M - 1) / 2 + 1;
         L := L + 1;
      end loop;
      return L;
   end Max_Level_For;

   procedure Thomas_Solve
     (A, B, C, D : Grid;
      X          : out Grid;
      N          : Positive)
   is
      Cp    : Grid (1 .. N);
      Dp    : Grid (1 .. N);
      Denom : Real;
   begin
      if abs (B (B'First)) <= Pivot_Tol then
         raise Invalid_Argument;
      end if;
      Cp (1) := C (C'First) / B (B'First);
      Dp (1) := D (D'First) / B (B'First);

      for I in 2 .. N loop
         Denom := B (B'First + I - 1)
           - A (A'First + I - 1) * Cp (I - 1);
         if abs (Denom) <= Pivot_Tol then
            raise Invalid_Argument;
         end if;
         if I < N then
            Cp (I) := C (C'First + I - 1) / Denom;
         else
            Cp (I) := 0.0;
         end if;
         Dp (I) :=
           (D (D'First + I - 1) - A (A'First + I - 1) * Dp (I - 1))
           / Denom;
      end loop;

      X (X'First + N - 1) := Dp (N);
      for I in reverse 1 .. N - 1 loop
         X (X'First + I - 1) := Dp (I) - Cp (I) * X (X'First + I);
      end loop;
   end Thomas_Solve;

   function Residual (U, F : Grid; H : Real) return Grid is
      Au   : constant Grid := Apply_Poisson_1D (U, H);
      R    : Grid (1 .. U'Length);
      Lo_F : constant Positive := F'First;
      Lo_A : constant Positive := Au'First;
   begin
      R (1) := 0.0;
      R (U'Length) := 0.0;
      for J in 2 .. U'Length - 1 loop
         R (J) := F (Lo_F + J - 1) - Au (Lo_A + J - 1);
      end loop;
      return R;
   end Residual;

   procedure Smooth_One_Jacobi
     (U     : in out Grid;
      F     : Grid;
      H     : Real;
      Omega : Real)
   is
      N    : constant Positive := U'Length;
      Lo_U : constant Positive := U'First;
      Lo_F : constant Positive := F'First;
      H2   : constant Real := H * H;
      Old  : constant Grid := U;
      Jac  : Real;
   begin
      for J in 2 .. N - 1 loop
         Jac :=
           (Old (Lo_U + J - 2) + Old (Lo_U + J) + H2 * F (Lo_F + J - 1))
           / 2.0;
         U (Lo_U + J - 1) :=
           (1.0 - Omega) * Old (Lo_U + J - 1) + Omega * Jac;
      end loop;
   end Smooth_One_Jacobi;

   procedure Smooth_One_GS
     (U : in out Grid;
      F : Grid;
      H : Real)
   is
      N    : constant Positive := U'Length;
      Lo_U : constant Positive := U'First;
      Lo_F : constant Positive := F'First;
      H2   : constant Real := H * H;
   begin
      for J in 2 .. N - 1 loop
         U (Lo_U + J - 1) :=
           (U (Lo_U + J - 2) + U (Lo_U + J) + H2 * F (Lo_F + J - 1))
           / 2.0;
      end loop;
   end Smooth_One_GS;

   procedure Do_Smooth
     (U                : in out Grid;
      F                : Grid;
      H                : Real;
      Nu               : Natural;
      Omega            : Real;
      Use_Gauss_Seidel : Boolean)
   is
   begin
      if Use_Gauss_Seidel then
         for Sweep in 1 .. Nu loop
            Smooth_One_GS (U, F, H);
         end loop;
      else
         for Sweep in 1 .. Nu loop
            Smooth_One_Jacobi (U, F, H, Omega);
         end loop;
      end if;
   end Do_Smooth;

   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Abs_Error (Approx, Exact : Real) return Non_Negative is
   begin
      return abs (Approx - Exact);
   end Abs_Error;

   function Vec_Near
     (A, B : Grid; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      if A'Length /= B'Length then
         return False;
      end if;
      for I in A'Range loop
         if abs (A (I) - B (I - A'First + B'First)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function L2_Error
     (U, Exact : Grid; H : Real) return Non_Negative
   is
      Sum : Real := 0.0;
      D   : Real;
      Lo  : constant Positive := Exact'First;
   begin
      Check_H (H);
      if U'Length /= Exact'Length then
         raise Invalid_Argument;
      end if;
      for I in U'Range loop
         D := U (I) - Exact (Lo + (I - U'First));
         Sum := Sum + D * D;
      end loop;
      return Sqrt (H * Sum);
   end L2_Error;

   function Max_Error (U, Exact : Grid) return Non_Negative is
      M  : Real := 0.0;
      D  : Real;
      Lo : constant Positive := Exact'First;
   begin
      if U'Length /= Exact'Length then
         raise Invalid_Argument;
      end if;
      for I in U'Range loop
         D := abs (U (I) - Exact (Lo + (I - U'First)));
         if D > M then
            M := D;
         end if;
      end loop;
      return M;
   end Max_Error;

   function Residual_L2 (U, F : Grid; H : Real) return Non_Negative is
      R   : Grid (1 .. U'Length);
      Sum : Real := 0.0;
   begin
      Check_H (H);
      Check_Same_Length (U, F);
      Check_Grid_Min3 (U);
      R := Residual (U, F, H);
      for J in 2 .. U'Length - 1 loop
         Sum := Sum + R (J) * R (J);
      end loop;
      return Sqrt (H * Sum);
   end Residual_L2;

   -------------------------------------------------------------------------
   -- Geometry / sampling
   -------------------------------------------------------------------------

   function X_At (X_Min, H : Real; J : Positive) return Real is
   begin
      Check_H (H);
      return X_Min + Real (J - 1) * H;
   end X_At;

   function Sample
     (N     : Point_Count;
      H     : Real;
      X_Min : Real := 0.0) return Grid
   is
      Result : Grid (1 .. N);
   begin
      Check_H (H);
      for J in 1 .. N loop
         Result (J) := F (X_At (X_Min, H, J));
      end loop;
      return Result;
   end Sample;

   function Coarse_Length (Fine_N : Positive) return Positive is
   begin
      if Fine_N < 3 then
         raise Invalid_Argument;
      end if;
      if (Fine_N - 1) rem 2 /= 0 then
         raise Invalid_Argument;
      end if;
      return (Fine_N - 1) / 2 + 1;
   end Coarse_Length;

   function Compatible_Sizes (Fine_N, Coarse_N : Positive) return Boolean is
   begin
      if Fine_N < 3 then
         return False;
      end if;
      if (Fine_N - 1) rem 2 /= 0 then
         return False;
      end if;
      return Coarse_N = (Fine_N - 1) / 2 + 1;
   end Compatible_Sizes;

   -------------------------------------------------------------------------
   -- Poisson operator
   -------------------------------------------------------------------------

   function Apply_Poisson_1D (U : Grid; H : Real) return Grid is
      N  : constant Natural := U'Length;
      Lo : constant Positive := U'First;
      H2 : Real;
      Au : Grid (1 .. N);
   begin
      Check_H (H);
      if N < 3 then
         raise Invalid_Argument;
      end if;
      H2 := H * H;
      Au (1) := 0.0;
      Au (N) := 0.0;
      for J in 2 .. N - 1 loop
         Au (J) :=
           (-U (Lo + J - 2) + 2.0 * U (Lo + J - 1) - U (Lo + J)) / H2;
      end loop;
      return Au;
   end Apply_Poisson_1D;

   -------------------------------------------------------------------------
   -- Smoothers
   -------------------------------------------------------------------------

   procedure Smooth_Jacobi
     (U     : in out Grid;
      F     : Grid;
      H     : Real;
      Nu    : Natural;
      Omega : Real := Default_Omega)
   is
   begin
      Check_H (H);
      Check_Same_Length (U, F);
      Check_Grid_Min3 (U);
      if Omega <= 0.0 then
         raise Invalid_Argument;
      end if;
      for Sweep in 1 .. Nu loop
         Smooth_One_Jacobi (U, F, H, Omega);
      end loop;
   end Smooth_Jacobi;

   procedure Smooth_Gauss_Seidel
     (U  : in out Grid;
      F  : Grid;
      H  : Real;
      Nu : Natural)
   is
   begin
      Check_H (H);
      Check_Same_Length (U, F);
      Check_Grid_Min3 (U);
      for Sweep in 1 .. Nu loop
         Smooth_One_GS (U, F, H);
      end loop;
   end Smooth_Gauss_Seidel;

   -------------------------------------------------------------------------
   -- Transfers
   -------------------------------------------------------------------------

   function Restrict_Injection (Fine : Grid) return Grid is
      Nf : constant Positive := Fine'Length;
      Nc : constant Positive := Coarse_Length (Nf);
      Lo : constant Positive := Fine'First;
      Result : Grid (1 .. Nc);
   begin
      for J in 1 .. Nc loop
         Result (J) := Fine (Lo + (2 * J - 1) - 1);
      end loop;
      return Result;
   end Restrict_Injection;

   function Restrict_Full_Weighting (Fine : Grid) return Grid is
      Nf     : constant Positive := Fine'Length;
      Nc     : constant Positive := Coarse_Length (Nf);
      Lo     : constant Positive := Fine'First;
      Result : Grid (1 .. Nc);
      K      : Positive;
   begin
      Result (1) := Fine (Lo);
      Result (Nc) := Fine (Lo + Nf - 1);
      for J in 2 .. Nc - 1 loop
         K := 2 * J - 1;
         Result (J) :=
           (Fine (Lo + K - 2)
            + 2.0 * Fine (Lo + K - 1)
            + Fine (Lo + K))
           / 4.0;
      end loop;
      return Result;
   end Restrict_Full_Weighting;

   function Prolong_Linear (Coarse : Grid; Fine_N : Positive) return Grid is
      Nc   : constant Positive := Coarse'Length;
      Lo   : constant Positive := Coarse'First;
      Fine : Grid (1 .. Fine_N);
   begin
      if not Compatible_Sizes (Fine_N, Nc) then
         raise Invalid_Argument;
      end if;
      if Fine_N > Max_Points then
         raise Invalid_Argument;
      end if;
      for J in 1 .. Nc loop
         Fine (2 * J - 1) := Coarse (Lo + J - 1);
      end loop;
      for J in 1 .. Nc - 1 loop
         Fine (2 * J) :=
           0.5 * (Coarse (Lo + J - 1) + Coarse (Lo + J));
      end loop;
      return Fine;
   end Prolong_Linear;

   -------------------------------------------------------------------------
   -- Coarsest Thomas solve
   -------------------------------------------------------------------------

   function Solve_Coarse_Thomas
     (F       : Grid;
      H       : Real;
      U_Left  : Real := 0.0;
      U_Right : Real := 0.0) return Grid
   is
      N_Full : constant Natural := F'Length;
      N      : Natural;
      H2     : Real;
      Lo_F   : constant Positive := F'First;
   begin
      Check_H (H);
      if N_Full < 3 then
         raise Invalid_Argument;
      end if;
      if N_Full > Max_Points then
         raise Invalid_Argument;
      end if;

      N := N_Full - 2;
      H2 := H * H;

      declare
         A, B, C, D, X_Int : Grid (1 .. N);
         U                 : Grid (1 .. N_Full);
      begin
         for I in 1 .. N loop
            A (I) := -1.0;
            B (I) := 2.0;
            C (I) := -1.0;
            D (I) := F (Lo_F + I) * H2;
         end loop;
         A (1) := 0.0;
         C (N) := 0.0;
         D (1) := D (1) + U_Left;
         D (N) := D (N) + U_Right;

         Thomas_Solve (A, B, C, D, X_Int, N);

         U (1) := U_Left;
         for I in 1 .. N loop
            U (I + 1) := X_Int (I);
         end loop;
         U (N_Full) := U_Right;
         return U;
      end;
   end Solve_Coarse_Thomas;

   -------------------------------------------------------------------------
   -- Two-grid V-cycle
   -------------------------------------------------------------------------

   procedure Two_Grid_V_Cycle
     (U                : in out Grid;
      F                : Grid;
      H                : Real;
      Nu_1             : Natural := 2;
      Nu_2             : Natural := 2;
      Omega            : Real := Default_Omega;
      Use_Gauss_Seidel : Boolean := False)
   is
      Nf    : constant Positive := U'Length;
      Nc    : Positive;
      H_C   : Real;
      Lo_U  : constant Positive := U'First;
      U_L   : Real;
      U_R   : Real;
   begin
      Check_H (H);
      Check_Same_Length (U, F);
      Check_Grid_Min3 (U);
      if Omega <= 0.0 then
         raise Invalid_Argument;
      end if;
      Nc := Coarse_Length (Nf);
      if Nc < 3 then
         raise Invalid_Argument;
      end if;
      H_C := 2.0 * H;
      U_L := U (Lo_U);
      U_R := U (Lo_U + Nf - 1);

      Do_Smooth (U, F, H, Nu_1, Omega, Use_Gauss_Seidel);

      declare
         R_F : constant Grid := Residual (U, F, H);
         R_C : constant Grid := Restrict_Full_Weighting (R_F);
         E_C : constant Grid :=
           Solve_Coarse_Thomas (R_C, H_C, 0.0, 0.0);
         E_F : constant Grid := Prolong_Linear (E_C, Nf);
      begin
         for J in 1 .. Nf loop
            U (Lo_U + J - 1) := U (Lo_U + J - 1) + E_F (J);
         end loop;
         U (Lo_U) := U_L;
         U (Lo_U + Nf - 1) := U_R;
      end;

      Do_Smooth (U, F, H, Nu_2, Omega, Use_Gauss_Seidel);
      U (Lo_U) := U_L;
      U (Lo_U + Nf - 1) := U_R;
   end Two_Grid_V_Cycle;

   -------------------------------------------------------------------------
   -- Recursive V-cycle
   -------------------------------------------------------------------------

   procedure V_Cycle
     (U                : in out Grid;
      F                : Grid;
      H                : Real;
      Level            : Natural;
      Nu_1             : Natural := 2;
      Nu_2             : Natural := 2;
      Omega            : Real := Default_Omega;
      Use_Gauss_Seidel : Boolean := False)
   is
      Nf   : constant Positive := U'Length;
      Lo_U : constant Positive := U'First;
      U_L  : Real;
      U_R  : Real;
   begin
      Check_H (H);
      Check_Same_Length (U, F);
      Check_Grid_Min3 (U);
      if Omega <= 0.0 then
         raise Invalid_Argument;
      end if;

      U_L := U (Lo_U);
      U_R := U (Lo_U + Nf - 1);

      --  Coarsest: direct Thomas solve for the residual equation is
      --  replaced by solving A U = F with the current Dirichlet ends.
      if Level = 0 or else Nf <= 3 then
         declare
            Solved : constant Grid :=
              Solve_Coarse_Thomas (F, H, U_L, U_R);
         begin
            U := Solved;
         end;
         return;
      end if;

      Do_Smooth (U, F, H, Nu_1, Omega, Use_Gauss_Seidel);

      declare
         Nc  : constant Positive := Coarse_Length (Nf);
         H_C : constant Real := 2.0 * H;
         R_F : constant Grid := Residual (U, F, H);
         R_C : constant Grid := Restrict_Full_Weighting (R_F);
         E_C : Grid (1 .. Nc) := [others => 0.0];
         E_F : Grid (1 .. Nf);
      begin
         V_Cycle
           (E_C, R_C, H_C, Level - 1, Nu_1, Nu_2, Omega, Use_Gauss_Seidel);
         E_F := Prolong_Linear (E_C, Nf);
         for J in 1 .. Nf loop
            U (Lo_U + J - 1) := U (Lo_U + J - 1) + E_F (J);
         end loop;
         U (Lo_U) := U_L;
         U (Lo_U + Nf - 1) := U_R;
      end;

      Do_Smooth (U, F, H, Nu_2, Omega, Use_Gauss_Seidel);
      U (Lo_U) := U_L;
      U (Lo_U + Nf - 1) := U_R;
   end V_Cycle;

   -------------------------------------------------------------------------
   -- Multi-cycle wrapper
   -------------------------------------------------------------------------

   function Solve_Poisson_MG
     (F                : Grid;
      H                : Real;
      N_Cycles         : Positive := 5;
      Level            : Natural := Natural'Last;
      Nu_1             : Natural := 2;
      Nu_2             : Natural := 2;
      Omega            : Real := Default_Omega;
      Use_Gauss_Seidel : Boolean := False)
     return Grid
   is
      N   : constant Positive := F'Length;
      U   : Grid (1 .. N) := [others => 0.0];
      Lev : Natural;
   begin
      Check_H (H);
      Check_Grid_Min3 (F);
      if N > Max_Points then
         raise Invalid_Argument;
      end if;
      if Omega <= 0.0 then
         raise Invalid_Argument;
      end if;

      --  Homogeneous Dirichlet guess; non-zero BCs can be set via F ends
      --  only if the caller seeds them into an external U — here we use 0.
      U (1) := 0.0;
      U (N) := 0.0;

      if Level = Natural'Last then
         Lev := Max_Level_For (N);
      else
         Lev := Level;
      end if;

      for Cycle in 1 .. N_Cycles loop
         V_Cycle (U, F, H, Lev, Nu_1, Nu_2, Omega, Use_Gauss_Seidel);
      end loop;
      return U;
   end Solve_Poisson_MG;

end Multigrid_Methods;
