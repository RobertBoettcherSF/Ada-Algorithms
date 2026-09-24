--  Lax_Wendroff body — single-step and Richtmyer two-step LW for
--  1D periodic linear advection.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Lax_Wendroff
  with SPARK_Mode => Off
is

   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;

   -------------------------------------------------------------------------
   -- Local helpers
   -------------------------------------------------------------------------

   procedure Check_Geometry (Dx, Dt : Real) is
   begin
      if Dx <= 0.0 or else Dt <= 0.0 then
         raise Invalid_Argument;
      end if;
   end Check_Geometry;

   procedure Check_CFL (Nu : Real) is
   begin
      if abs (Nu) > 1.0 then
         raise Invalid_Argument;
      end if;
   end Check_CFL;

   --  Periodic neighbour indices for 1-based cells 1 .. N.
   function Left_Of (J : Cell_Index; N : Cell_Count) return Cell_Index is
   begin
      if J = 1 then
         return N;
      else
         return J - 1;
      end if;
   end Left_Of;

   function Right_Of (J : Cell_Index; N : Cell_Count) return Cell_Index is
   begin
      if J = N then
         return 1;
      else
         return J + 1;
      end if;
   end Right_Of;

   function Active_Slice (State : Grid_State) return Grid is
   begin
      return State.U (1 .. State.N);
   end Active_Slice;

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

   -------------------------------------------------------------------------
   -- Geometry / CFL
   -------------------------------------------------------------------------

   function Domain_Length (State : Grid_State) return Real is
   begin
      return Real (State.N) * State.Dx;
   end Domain_Length;

   function X_At (State : Grid_State; J : Cell_Index) return Real is
   begin
      return State.X_Min + Real (J - 1) * State.Dx;
   end X_At;

   function CFL (A, Dt, Dx : Real) return Real is
   begin
      if Dx = 0.0 then
         raise Invalid_Argument;
      end if;
      return A * Dt / Dx;
   end CFL;

   function CFL (State : Grid_State) return Real is
   begin
      return CFL (State.A, State.Dt, State.Dx);
   end CFL;

   function CFL_OK (State : Grid_State) return Boolean is
   begin
      if State.Dx <= 0.0 or else State.Dt <= 0.0 then
         return False;
      end if;
      return abs (CFL (State)) <= 1.0;
   end CFL_OK;

   -------------------------------------------------------------------------
   -- Construction / ICs
   -------------------------------------------------------------------------

   function Make_Grid
     (N     : Cell_Count;
      Dx    : Real;
      Dt    : Real;
      A     : Real := 1.0;
      X_Min : Real := 0.0) return Grid_State
   is
      S : Grid_State;
   begin
      Check_Geometry (Dx, Dt);
      S.N := N;
      S.Dx := Dx;
      S.Dt := Dt;
      S.A := A;
      S.X_Min := X_Min;
      S.U := [others => 0.0];
      return S;
   end Make_Grid;

   function Make_Gaussian
     (N      : Cell_Count;
      Dx     : Real;
      Dt     : Real;
      A      : Real := 1.0;
      X_Min  : Real := 0.0;
      Centre : Real := 0.5;
      Width  : Real := 0.1;
      Amp    : Real := 1.0) return Grid_State
   is
      S : Grid_State;
      X : Real;
      Z : Real;
   begin
      Check_Geometry (Dx, Dt);
      if Width <= 0.0 then
         raise Invalid_Argument;
      end if;
      S := Make_Grid (N, Dx, Dt, A, X_Min);
      for J in 1 .. N loop
         X := X_At (S, J);
         Z := (X - Centre) / Width;
         S.U (J) := Amp * Exp (-Z * Z);
      end loop;
      return S;
   end Make_Gaussian;

   function Make_Pulse
     (N     : Cell_Count;
      Dx    : Real;
      Dt    : Real;
      A     : Real := 1.0;
      X_Min : Real := 0.0;
      Left  : Real := 0.25;
      Right : Real := 0.5;
      Amp   : Real := 1.0) return Grid_State
   is
      S : Grid_State;
      X : Real;
   begin
      Check_Geometry (Dx, Dt);
      if Right <= Left then
         raise Invalid_Argument;
      end if;
      S := Make_Grid (N, Dx, Dt, A, X_Min);
      for J in 1 .. N loop
         X := X_At (S, J);
         if X >= Left and then X <= Right then
            S.U (J) := Amp;
         else
            S.U (J) := 0.0;
         end if;
      end loop;
      return S;
   end Make_Pulse;

   function Make_Constant
     (N     : Cell_Count;
      Dx    : Real;
      Dt    : Real;
      Value : Real;
      A     : Real := 1.0;
      X_Min : Real := 0.0) return Grid_State
   is
      S : Grid_State;
   begin
      Check_Geometry (Dx, Dt);
      S := Make_Grid (N, Dx, Dt, A, X_Min);
      for J in 1 .. N loop
         S.U (J) := Value;
      end loop;
      return S;
   end Make_Constant;

   -------------------------------------------------------------------------
   -- Time stepping
   -------------------------------------------------------------------------

   procedure Step (State : in out Grid_State) is
      N      : constant Cell_Count := State.N;
      Nu     : Real;
      Nu2    : Real;
      U_Old  : Grid (1 .. N);
      U_New  : Grid (1 .. N);
      Jm1, Jp1 : Cell_Index;
      Uj, Ul, Ur : Real;
   begin
      Check_Geometry (State.Dx, State.Dt);
      Nu := CFL (State);
      Check_CFL (Nu);
      Nu2 := Nu * Nu;
      U_Old := State.U (1 .. N);

      for J in 1 .. N loop
         Jm1 := Left_Of (J, N);
         Jp1 := Right_Of (J, N);
         Uj := U_Old (J);
         Ul := U_Old (Jm1);
         Ur := U_Old (Jp1);
         U_New (J) :=
           Uj
           - (Nu / 2.0) * (Ur - Ul)
           + (Nu2 / 2.0) * (Ur - 2.0 * Uj + Ul);
      end loop;

      State.U (1 .. N) := U_New;
   end Step;

   procedure Advance (State : in out Grid_State; N_Steps : Positive) is
   begin
      for K in 1 .. N_Steps loop
         Step (State);
      end loop;
   end Advance;

   procedure Step_Richtmyer (State : in out Grid_State) is
      N     : constant Cell_Count := State.N;
      Nu    : Real;
      U_Old : Grid (1 .. N);
      --  Midpoint predictors live on edges 1 .. N where edge J is
      --  between cells J and Right_Of(J), i.e. u_{j+1/2}.
      U_Half : Grid (1 .. N);
      U_New  : Grid (1 .. N);
      Jp1, Jm1 : Cell_Index;
      U_Left_Edge, U_Right_Edge : Real;
   begin
      Check_Geometry (State.Dx, State.Dt);
      Nu := CFL (State);
      Check_CFL (Nu);
      U_Old := State.U (1 .. N);

      --  Half-step Lax–Friedrichs-like predictors at j+1/2:
      --    u_{j+1/2}^{n+1/2} = (u_j + u_{j+1})/2 − (ν/2)(u_{j+1} − u_j)
      for J in 1 .. N loop
         Jp1 := Right_Of (J, N);
         U_Half (J) :=
           0.5 * (U_Old (J) + U_Old (Jp1))
           - (Nu / 2.0) * (U_Old (Jp1) - U_Old (J));
      end loop;

      --  Full step: u_j^{n+1} = u_j − ν (u_{j+1/2} − u_{j−1/2})
      for J in 1 .. N loop
         Jm1 := Left_Of (J, N);
         --  Edge J is j+1/2; edge Left_Of(J) is (j−1)+1/2 = j−1/2
         U_Right_Edge := U_Half (J);
         U_Left_Edge := U_Half (Jm1);
         U_New (J) := U_Old (J) - Nu * (U_Right_Edge - U_Left_Edge);
      end loop;

      State.U (1 .. N) := U_New;
   end Step_Richtmyer;

   procedure Advance_Richtmyer
     (State : in out Grid_State; N_Steps : Positive)
   is
   begin
      for K in 1 .. N_Steps loop
         Step_Richtmyer (State);
      end loop;
   end Advance_Richtmyer;

   -------------------------------------------------------------------------
   -- Exact advection
   -------------------------------------------------------------------------

   function Wrap_Periodic
     (X, X_Min, Length : Real) return Real
   is
      Y : Real := X - X_Min;
   begin
      if Length <= 0.0 then
         raise Invalid_Argument;
      end if;
      --  Bring into [0, Length)
      Y := Y - Length * Real'Floor (Y / Length);
      if Y < 0.0 then
         Y := Y + Length;
      end if;
      if Y >= Length then
         Y := Y - Length;
      end if;
      return X_Min + Y;
   end Wrap_Periodic;

   function Exact_Advection
     (U0       : Grid;
      N        : Cell_Count;
      Dx       : Real;
      X_Min    : Real;
      Distance : Real) return Grid
   is
      Result : Grid (1 .. N);
      L      : constant Real := Real (N) * Dx;
      X, Xi  : Real;
      --  Foot of characteristic: sample U0 at Xi = X − Distance
      S, Alpha : Real;
      I0, I1   : Integer;
      J0, J1   : Cell_Index;
   begin
      if Dx <= 0.0 or else U0'Length /= Natural (N) then
         raise Invalid_Argument;
      end if;

      for J in 1 .. N loop
         X := X_Min + Real (J - 1) * Dx;
         Xi := Wrap_Periodic (X - Distance, X_Min, L);
         --  Continuous index in [0, N): cell centres at k = 0 .. N-1
         S := (Xi - X_Min) / Dx;
         --  Floor into 0 .. N-1
         I0 := Integer (Real'Floor (S));
         Alpha := S - Real (I0);
         --  Normalize I0 into 0 .. N-1
         I0 := I0 mod Integer (N);
         if I0 < 0 then
            I0 := I0 + Integer (N);
         end if;
         I1 := (I0 + 1) mod Integer (N);
         J0 := Cell_Index (I0 + 1);
         J1 := Cell_Index (I1 + 1);
         Result (J) :=
           (1.0 - Alpha) * U0 (U0'First + J0 - 1)
           + Alpha * U0 (U0'First + J1 - 1);
      end loop;
      return Result;
   end Exact_Advection;

   function Exact_Advection
     (State : Grid_State; T : Real) return Grid
   is
   begin
      return Exact_Advection
        (Active_Slice (State),
         State.N,
         State.Dx,
         State.X_Min,
         State.A * T);
   end Exact_Advection;

   function Shift_Grid (U : Grid; K : Integer) return Grid is
      N      : constant Positive := U'Length;
      Result : Grid (1 .. N);
      Src    : Integer;
   begin
      for J in 1 .. N loop
         --  Profile shifts +K cells: new[j] = old[j − K] (periodic)
         Src := ((J - 1 - K) mod N + N) mod N;
         Result (J) := U (U'First + Src);
      end loop;
      return Result;
   end Shift_Grid;

   -------------------------------------------------------------------------
   -- Errors / mass
   -------------------------------------------------------------------------

   function L2_Error
     (U, Exact : Grid; Dx : Real) return Non_Negative
   is
      Sum : Real := 0.0;
      D   : Real;
      Lo  : constant Positive := Exact'First;
   begin
      if Dx <= 0.0 or else U'Length /= Exact'Length then
         raise Invalid_Argument;
      end if;
      for I in U'Range loop
         D := U (I) - Exact (Lo + (I - U'First));
         Sum := Sum + D * D;
      end loop;
      return Sqrt (Dx * Sum);
   end L2_Error;

   function L2_Error
     (State : Grid_State; Exact : Grid) return Non_Negative
   is
   begin
      return L2_Error (Active_Slice (State), Exact, State.Dx);
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

   function Max_Error
     (State : Grid_State; Exact : Grid) return Non_Negative
   is
   begin
      return Max_Error (Active_Slice (State), Exact);
   end Max_Error;

   function Mass (U : Grid; Dx : Real) return Real is
      Sum : Real := 0.0;
   begin
      if Dx <= 0.0 then
         raise Invalid_Argument;
      end if;
      for I in U'Range loop
         Sum := Sum + U (I);
      end loop;
      return Sum * Dx;
   end Mass;

   function Mass (State : Grid_State) return Real is
   begin
      return Mass (Active_Slice (State), State.Dx);
   end Mass;

   function Max_Abs (U : Grid) return Non_Negative is
      M : Real := 0.0;
      A : Real;
   begin
      for I in U'Range loop
         A := abs (U (I));
         if A > M then
            M := A;
         end if;
      end loop;
      return M;
   end Max_Abs;

end Lax_Wendroff;
