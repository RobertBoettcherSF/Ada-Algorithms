--  Universal Variable Formulation in Orbital Mechanics
--  Package Body
--  Standard: Ada 2023 (ISO/IEC 8652:2023)

with Ada.Numerics.Generic_Elementary_Functions;

package body Universal_Variable_Formulation is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Math;

   --  ========================================================================
   --  Vector Arithmetic
   --  ========================================================================

   function "+" (Left, Right : Vector_3D) return Vector_3D is
   begin
      return (X => Left.X + Right.X,
              Y => Left.Y + Right.Y,
              Z => Left.Z + Right.Z);
   end "+";

   function "-" (Left, Right : Vector_3D) return Vector_3D is
   begin
      return (X => Left.X - Right.X,
              Y => Left.Y - Right.Y,
              Z => Left.Z - Right.Z);
   end "-";

   function "*" (Scalar : Real; Vec : Vector_3D) return Vector_3D is
   begin
      return (X => Scalar * Vec.X,
              Y => Scalar * Vec.Y,
              Z => Scalar * Vec.Z);
   end "*";

   function "*" (Vec : Vector_3D; Scalar : Real) return Vector_3D is
   begin
      return (X => Vec.X * Scalar,
              Y => Vec.Y * Scalar,
              Z => Vec.Z * Scalar);
   end "*";

   function "/" (Vec : Vector_3D; Scalar : Real) return Vector_3D is
   begin
      return (X => Vec.X / Scalar,
              Y => Vec.Y / Scalar,
              Z => Vec.Z / Scalar);
   end "/";

   function Dot_Product (U, V : Vector_3D) return Real is
   begin
      return U.X * V.X + U.Y * V.Y + U.Z * V.Z;
   end Dot_Product;

   function Cross_Product (U, V : Vector_3D) return Vector_3D is
   begin
      return (X => U.Y * V.Z - U.Z * V.Y,
              Y => U.Z * V.X - U.X * V.Z,
              Z => U.X * V.Y - U.Y * V.X);
   end Cross_Product;

   function Magnitude (V : Vector_3D) return Distance is
      Sum_Sq : constant Real := V.X * V.X + V.Y * V.Y + V.Z * V.Z;
   begin
      if Sum_Sq <= 0.0 then
         return 0.0;
      else
         return Distance (Sqrt (Sum_Sq));
      end if;
   end Magnitude;

   --  ========================================================================
   --  Stumpff Functions
   --  Evaluated via closed form for |z| >= 0.1, and Taylor series for |z| < 0.1
   --  ========================================================================

   function Stumpff_C0 (Z : Real) return Real is
   begin
      if Z > 0.1 then
         return Cos (Sqrt (Z));
      elsif Z < -0.1 then
         return Cosh (Sqrt (-Z));
      else
         --  Series: 1 - z/2! + z^2/4! - z^3/6! + z^4/8! ...
         declare
            Term : Real := 1.0;
            Sum  : Real := 1.0;
         begin
            for K in 1 .. 6 loop
               Term := -Term * Z / Real ((2 * K - 1) * (2 * K));
               Sum  := Sum + Term;
            end loop;
            return Sum;
         end;
      end if;
   end Stumpff_C0;

   function Stumpff_C1 (Z : Real) return Real is
   begin
      if Z > 0.1 then
         return Sin (Sqrt (Z)) / Sqrt (Z);
      elsif Z < -0.1 then
         return Sinh (Sqrt (-Z)) / Sqrt (-Z);
      else
         --  Series: 1 - z/3! + z^2/5! - z^3/7! + z^4/9! ...
         declare
            Term : Real := 1.0;
            Sum  : Real := 1.0;
         begin
            for K in 1 .. 6 loop
               Term := -Term * Z / Real ((2 * K) * (2 * K + 1));
               Sum  := Sum + Term;
            end loop;
            return Sum;
         end;
      end if;
   end Stumpff_C1;

   function Stumpff_C2 (Z : Real) return Real is
   begin
      if Z > 0.1 then
         return (1.0 - Cos (Sqrt (Z))) / Z;
      elsif Z < -0.1 then
         return (Cosh (Sqrt (-Z)) - 1.0) / (-Z);
      else
         --  Series: 1/2! - z/4! + z^2/6! - z^3/8! + z^4/10! ...
         declare
            Term : Real := 0.5;
            Sum  : Real := 0.5;
         begin
            for K in 1 .. 6 loop
               Term := -Term * Z / Real ((2 * K + 1) * (2 * K + 2));
               Sum  := Sum + Term;
            end loop;
            return Sum;
         end;
      end if;
   end Stumpff_C2;

   function Stumpff_C3 (Z : Real) return Real is
   begin
      if Z > 0.1 then
         declare
            S_Z : constant Real := Sqrt (Z);
         begin
            return (S_Z - Sin (S_Z)) / (Z * S_Z);
         end;
      elsif Z < -0.1 then
         declare
            S_Neg_Z : constant Real := Sqrt (-Z);
         begin
            return (Sinh (S_Neg_Z) - S_Neg_Z) / ((-Z) * S_Neg_Z);
         end;
      else
         --  Series: 1/3! - z/5! + z^2/7! - z^3/9! + z^4/11! ...
         declare
            Term : Real := 1.0 / 6.0;
            Sum  : Real := 1.0 / 6.0;
         begin
            for K in 1 .. 6 loop
               Term := -Term * Z / Real ((2 * K + 2) * (2 * K + 3));
               Sum  := Sum + Term;
            end loop;
            return Sum;
         end;
      end if;
   end Stumpff_C3;

   function Stumpff_C4 (Z : Real) return Real is
   begin
      return (0.5 - Stumpff_C2 (Z)) / Z;
   end Stumpff_C4;

   function Stumpff_C5 (Z : Real) return Real is
   begin
      return (1.0 / 6.0 - Stumpff_C3 (Z)) / Z;
   end Stumpff_C5;

   --  ========================================================================
   --  Core Orbital Properties
   --  ========================================================================

   function Specific_Mechanical_Energy
     (R  : Vector_3D;
      V  : Vector_3D;
      Mu : Gravitational_Parameter) return Real
   is
      R_Mag : constant Distance := Magnitude (R);
      V_Mag_Sq : constant Real := Dot_Product (V, V);
   begin
      if R_Mag <= 0.0 then
         raise Invalid_State with "Position magnitude is zero";
      end if;
      return 0.5 * V_Mag_Sq - Real (Mu) / Real (R_Mag);
   end Specific_Mechanical_Energy;

   function Classify_Orbit
     (R  : Vector_3D;
      V  : Vector_3D;
      Mu : Gravitational_Parameter) return Orbit_Type
   is
      Energy : constant Real := Specific_Mechanical_Energy (R, V, Mu);
      Tol    : constant Real := 1.0e-7;
   begin
      if Energy < -Tol then
         return Elliptic;
      elsif Energy > Tol then
         return Hyperbolic;
      else
         return Parabolic;
      end if;
   end Classify_Orbit;

   function Reciprocal_Semi_Major_Axis
     (R_Mag : Distance;
      V_Mag : Velocity;
      Mu    : Gravitational_Parameter) return Real
   is
   begin
      return (2.0 / Real (R_Mag)) - (Real (V_Mag) * Real (V_Mag) / Real (Mu));
   end Reciprocal_Semi_Major_Axis;

   --  ========================================================================
   --  Universal Kepler Solver
   --  Solves Kepler's Equation for the universal anomaly Chi via Newton-Raphson
   --  ========================================================================

   function Solve_Kepler_Universal
     (R0         : Vector_3D;
      V0         : Vector_3D;
      Dt         : Time_Span;
      Mu         : Gravitational_Parameter;
      Tolerance  : Real := 1.0e-10;
      Max_Iter   : Positive := 100) return Universal_Anomaly
   is
      R0_Mag  : constant Real := Real (Magnitude (R0));
      Mu_Real : constant Real := Real (Mu);
      Sqrt_Mu : constant Real := Sqrt (Mu_Real);
      Alpha   : constant Real := (2.0 / R0_Mag)
                                 - (Dot_Product (V0, V0) / Mu_Real);
      Radial_V : constant Real := Dot_Product (R0, V0) / Sqrt_Mu;

      --  Initial guess for Chi
      Chi : Real;
   begin
      if R0_Mag <= 0.0 then
         raise Invalid_State with "Radius magnitude must be positive";
      end if;

      if Dt = 0.0 then
         return 0.0;
      end if;

      if Alpha > 1.0e-6 then
         --  Elliptic orbit initial estimate
         Chi := Sqrt_Mu * Real (Dt) * Alpha;
      elsif Alpha < -1.0e-6 then
         --  Hyperbolic initial estimate
         declare
            A : constant Real := 1.0 / Alpha;
            Arg : constant Real := -2.0 * Mu_Real * Real (Dt)
              / (A * (Radial_V + (if Dt >= 0.0 then 1.0 else -1.0)
                       * Sqrt (-Mu_Real * A)));
         begin
            if Arg > 1.0 then
               Chi := (if Dt >= 0.0 then 1.0 else -1.0) * Sqrt (-A) * Log (Arg);
            else
               Chi := Sqrt_Mu * Real (Dt) * Alpha;
            end if;
         end;
      else
         --  Parabolic initial estimate (Barker's equation approx)
         declare
            H_Vec : constant Vector_3D := Cross_Product (R0, V0);
            P_Semi : constant Real := Dot_Product (H_Vec, H_Vec) / Mu_Real;
            S : constant Real := 0.5 * (1.0 / Tan (0.5 * Arctan (3.0 * Real (Dt)
                   * Sqrt (Mu_Real / (P_Semi * P_Semi * P_Semi)))));
         begin
            Chi := Sqrt (P_Semi) * 2.0 / Tan (2.0 * Arctan (S));
         exception
            when others =>
               Chi := Sqrt_Mu * Real (Dt) / R0_Mag;
         end;
      end if;

      --  Newton-Raphson iteration
      for Iter in 1 .. Max_Iter loop
         declare
            Z   : constant Real := Alpha * Chi * Chi;
            C2  : constant Real := Stumpff_C2 (Z);
            C3  : constant Real := Stumpff_C3 (Z);

            --  Universal Kepler function: F(Chi) = 0
            F_Val : constant Real :=
              R0_Mag * Chi * Stumpff_C1 (Z)
              + Radial_V * (Chi * Chi) * C2
              + (Chi * Chi * Chi) * C3
              - Sqrt_Mu * Real (Dt);

            --  First derivative: dF/dChi
            F_Prime : constant Real :=
              R0_Mag * Stumpff_C0 (Z)
              + Radial_V * Chi * (1.0 - Z * C3)
              + (Chi * Chi) * C2;

            Delta_Chi : Real;
         begin
            if abs (F_Prime) < 1.0e-15 then
               raise Convergence_Error with "Derivative vanished in Kepler solver";
            end if;

            Delta_Chi := F_Val / F_Prime;
            Chi := Chi - Delta_Chi;

            if abs (Delta_Chi) < Tolerance then
               return Universal_Anomaly (Chi);
            end if;
         end;
      end loop;

      raise Convergence_Error with "Kepler solver reached maximum iterations";
   end Solve_Kepler_Universal;

   --  ========================================================================
   --  Universal Orbit Propagation (Lagrange Coefficients f, g, f_dot, g_dot)
   --  ========================================================================

   procedure Propagate_Kepler_Universal
     (R0         : in  Vector_3D;
      V0         : in  Vector_3D;
      Dt         : in  Time_Span;
      Mu         : in  Gravitational_Parameter;
      R_Final    : out Vector_3D;
      V_Final    : out Vector_3D;
      Tolerance  : in  Real := 1.0e-10;
      Max_Iter   : in  Positive := 100)
   is
      R0_Mag  : constant Real := Real (Magnitude (R0));
      Mu_Real : constant Real := Real (Mu);
      Sqrt_Mu : constant Real := Sqrt (Mu_Real);

      Alpha : constant Real := (2.0 / R0_Mag)
                               - (Dot_Product (V0, V0) / Mu_Real);
      Chi   : Real;
      Z     : Real;
      C2    : Real;
      C3    : Real;

      F, G          : Real;
      F_Dot, G_Dot  : Real;
      R_Final_Mag   : Real;
   begin
      if Dt = 0.0 then
         R_Final := R0;
         V_Final := V0;
         return;
      end if;

      Chi := Real (Solve_Kepler_Universal
                     (R0, V0, Dt, Mu, Tolerance, Max_Iter));
      Z   := Alpha * Chi * Chi;
      C2  := Stumpff_C2 (Z);
      C3  := Stumpff_C3 (Z);

      --  Lagrange coefficients f and g
      F := 1.0 - (Chi * Chi / R0_Mag) * C2;
      G := Real (Dt) - (Chi * Chi * Chi / Sqrt_Mu) * C3;

      R_Final := F * R0 + G * V0;
      R_Final_Mag := Real (Magnitude (R_Final));

      if R_Final_Mag <= 0.0 then
         raise Singularity_Error with "Zero radius encountered in propagation";
      end if;

      --  Time derivatives: f_dot and g_dot
      F_Dot := (Sqrt_Mu / (R0_Mag * R_Final_Mag)) * Chi * (Z * C3 - 1.0);
      G_Dot := 1.0 - (Chi * Chi / R_Final_Mag) * C2;

      V_Final := F_Dot * R0 + G_Dot * V0;
   end Propagate_Kepler_Universal;

   function Propagate_State
     (State      : State_Vector;
      Dt         : Time_Span;
      Mu         : Gravitational_Parameter;
      Tolerance  : Real := 1.0e-10;
      Max_Iter   : Positive := 100) return State_Vector
   is
      Result : State_Vector;
   begin
      Propagate_Kepler_Universal
        (R0         => State.R,
         V0         => State.V,
         Dt         => Dt,
         Mu         => Mu,
         R_Final    => Result.R,
         V_Final    => Result.V,
         Tolerance  => Tolerance,
         Max_Iter   => Max_Iter);
      return Result;
   end Propagate_State;

   --  ========================================================================
   --  Universal Lambert Solver (Universal Variable Formulation)
   --  ========================================================================

   procedure Solve_Lambert_Universal
     (R1         : in  Vector_3D;
      R2         : in  Vector_3D;
      Dt         : in  Positive_Time;
      Mu         : in  Gravitational_Parameter;
      V1         : out Vector_3D;
      V2         : out Vector_3D;
      Prograde   : in  Boolean := True;
      Tolerance  : in  Real := 1.0e-9;
      Max_Iter   : in  Positive := 120)
   is
      R1_Mag : constant Real := Real (Magnitude (R1));
      R2_Mag : constant Real := Real (Magnitude (R2));
      Mu_Real : constant Real := Real (Mu);

      Dot_12 : constant Real := Dot_Product (R1, R2);
      Cos_Theta : constant Real := Dot_12 / (R1_Mag * R2_Mag);

      --  Clamping for numerical stability
      Cos_D_Nu : constant Real :=
        (if Cos_Theta > 1.0 then 1.0
         elsif Cos_Theta < -1.0 then -1.0
         else Cos_Theta);

      Cross_12 : constant Vector_3D := Cross_Product (R1, R2);
      Sin_Theta_Raw : constant Real := Sqrt (Real'Max (0.0, 1.0 - Cos_D_Nu * Cos_D_Nu));

      --  Determine orbital transfer angle direction
      Sin_Theta : Real;
      A_Param   : Real;

      Z         : Real;
      Y_Val     : Real;
      F_Val     : Real;
      F_Prime   : Real;
      Ratio     : Real;
   begin
      if (Prograde and then Cross_12.Z >= 0.0)
         or else (not Prograde and then Cross_12.Z < 0.0)
      then
         Sin_Theta := Sin_Theta_Raw;
      else
         Sin_Theta := -Sin_Theta_Raw;
      end if;

      A_Param := Sin_Theta * Sqrt (R1_Mag * R2_Mag / (1.0 - Cos_D_Nu));

      if abs (A_Param) < 1.0e-12 then
         raise Singularity_Error with "Degenerate 180-degree or 0-degree transfer";
      end if;

      --  Initial guess for z
      Z := 0.0;

      for Iter in 1 .. Max_Iter loop
         declare
            C2 : constant Real := Stumpff_C2 (Z);
            C3 : constant Real := Stumpff_C3 (Z);
         begin
            if C2 <= 0.0 then
               raise Convergence_Error with "C2 non-positive in Lambert solver";
            end if;

            Y_Val := R1_Mag + R2_Mag + A_Param * (Z * C3 - 1.0) / Sqrt (C2);

            if A_Param > 0.0 and then Y_Val < 0.0 then
               --  Adjust iterate to retain positive spatial variable Y
               Z := Z + 0.1;
            else
               declare
                  Chi : constant Real := Sqrt (Y_Val / C2);
               begin
                  F_Val := ((Chi * Chi * Chi) * C3 + A_Param * Sqrt (Y_Val))
                           / Sqrt (Mu_Real) - Real (Dt);

                  if abs (Z) < 1.0e-5 then
                     F_Prime := (Sqrt (2.0) / 40.0) * (Y_Val ** 1.5)
                       + (A_Param / 8.0) * (Sqrt (Y_Val)
                          + A_Param * Sqrt (1.0 / (2.0 * Y_Val)));
                     F_Prime := F_Prime / Sqrt (Mu_Real);
                  else
                     declare
                        C1_Half_Z : constant Real := Stumpff_C1 (0.5 * Z);
                        D_Chi_Dz  : constant Real :=
                          (1.0 / (2.0 * Chi)) *
                          ((1.0 / (2.0 * C2)) * (R1_Mag + R2_Mag)
                           - (A_Param / (4.0 * (C2 ** 1.5))) * C1_Half_Z);
                     begin
                        F_Prime := ((3.0 * (Chi * Chi) * C3 * D_Chi_Dz)
                                    + (Chi * Chi * Chi) * (1.0 / (2.0 * Z))
                                      * (C2 - 3.0 * C3)
                                    + (A_Param / (2.0 * Sqrt (Y_Val)))
                                      * (2.0 * C2 * Chi * D_Chi_Dz
                                         + (Chi * Chi) * (1.0 / (2.0 * Z))
                                           * (Stumpff_C1 (Z) - 2.0 * C2)))
                                   / Sqrt (Mu_Real);
                     end;
                  end if;

                  if abs (F_Prime) < 1.0e-15 then
                     raise Convergence_Error with "Vanishing derivative in Lambert solver";
                  end if;

                  Ratio := F_Val / F_Prime;
                  Z := Z - Ratio;

                  if abs (Ratio) < Tolerance or else abs (F_Val) < Tolerance then
                     exit;
                  end if;
               end;
            end if;
         end;

         if Iter = Max_Iter then
            raise Convergence_Error with "Lambert solver failed to converge";
         end if;
      end loop;

      --  Compute velocity vectors using Lagrange coefficients
      declare
         F_Coeff  : constant Real := 1.0 - Y_Val / R1_Mag;
         G_Coeff  : constant Real := A_Param * Sqrt (Y_Val / Mu_Real);
         G_Dot    : constant Real := 1.0 - Y_Val / R2_Mag;
      begin
         if abs (G_Coeff) < 1.0e-14 then
            raise Singularity_Error with "Transfer time too short or degenerate transfer";
         end if;

         V1 := (1.0 / G_Coeff) * (R2 - F_Coeff * R1);
         V2 := (1.0 / G_Coeff) * (G_Dot * R2 - R1);
      end;
   end Solve_Lambert_Universal;

end Universal_Variable_Formulation;
