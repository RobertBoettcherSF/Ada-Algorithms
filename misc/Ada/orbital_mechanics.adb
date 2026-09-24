--  Package Body: Orbital_Mechanics
--  Standard: Ada 2023 (ISO/IEC 8652:2023)

with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;

package body Orbital_Mechanics with
  SPARK_Mode => On
is

   Two_Pi : constant Long_Float := 2.0 * Ada.Numerics.Pi;

   ----------------------------------------------------------------------
   --  Helper: Normalize Angle to [0, 2*pi)
   ----------------------------------------------------------------------
   function Normalize_Angle (Angle : Long_Float) return Long_Float is
      Res : Long_Float := Angle;
   begin
      while Res < 0.0 loop
         Res := Res + Two_Pi;
      end loop;
      while Res >= Two_Pi loop
         Res := Res - Two_Pi;
      end loop;
      return Res;
   end Normalize_Angle;

   ----------------------------------------------------------------------
   --  1. Orbital Velocities
   ----------------------------------------------------------------------

   function Vis_Viva_Velocity
     (Mu                   : Gravitational_Parameter;
      Current_Radius       : Positive_Distance;
      Semi_Major_Axis_Inv  : Long_Float) return Speed
   is
      Term : constant Long_Float :=
        (2.0 / Long_Float (Current_Radius)) - Semi_Major_Axis_Inv;
   begin
      if Term < 0.0 then
         raise Singularity_Error with "Negative energy term in vis-viva equation";
      end if;
      return Speed (Sqrt (Long_Float (Mu) * Term));
   end Vis_Viva_Velocity;

   function Circular_Velocity
     (Mu     : Gravitational_Parameter;
      Radius : Positive_Distance) return Speed
   is
   begin
      --  In a circular orbit, a = r, so 1/a = 1/r.
      --  Vis-viva gives: 2/r - 1/r = 1/r => v = sqrt(mu / r)
      return Speed (Sqrt (Long_Float (Mu) / Long_Float (Radius)));
   end Circular_Velocity;

   function Escape_Velocity
     (Mu     : Gravitational_Parameter;
      Radius : Positive_Distance) return Speed
   is
      V_Circ : constant Speed := Circular_Velocity (Mu, Radius);
   begin
      --  Parabolic trajectory (a -> infinity => 1/a = 0):
      --  v_esc = sqrt(2 * mu / r) = sqrt(2) * v_circ
      return Speed (Long_Float (V_Circ) * Sqrt (2.0));
   end Escape_Velocity;

   function Hyperbolic_Excess_Velocity
     (Mu              : Gravitational_Parameter;
      Semi_Major_Axis : Long_Float) return Speed
   is
   begin
      --  Semi_Major_Axis < 0.0 for hyperbolic trajectory
      return Speed (Sqrt (-Long_Float (Mu) / Semi_Major_Axis));
   end Hyperbolic_Excess_Velocity;

   ----------------------------------------------------------------------
   --  2. Kepler's Third Law Variants
   ----------------------------------------------------------------------

   function Orbital_Period
     (Mu              : Gravitational_Parameter;
      Semi_Major_Axis : Positive_Distance) return Positive_Time
   is
      A : constant Long_Float := Long_Float (Semi_Major_Axis);
   begin
      return Positive_Time (Two_Pi * Sqrt ((A * A * A) / Long_Float (Mu)));
   end Orbital_Period;

   function Semi_Major_Axis_From_Period
     (Mu     : Gravitational_Parameter;
      Period : Positive_Time) return Positive_Distance
   is
      T     : constant Long_Float := Long_Float (Period);
      Term  : constant Long_Float := Long_Float (Mu) * (T / Two_Pi) ** 2;
   begin
      return Positive_Distance (Term ** (1.0 / 3.0));
   end Semi_Major_Axis_From_Period;

   function Mean_Motion
     (Mu              : Gravitational_Parameter;
      Semi_Major_Axis : Positive_Distance) return Long_Float
   is
      A : constant Long_Float := Long_Float (Semi_Major_Axis);
   begin
      return Sqrt (Long_Float (Mu) / (A * A * A));
   end Mean_Motion;

   ----------------------------------------------------------------------
   --  3. Specific Orbital Energy and Momentum
   ----------------------------------------------------------------------

   function Specific_Orbital_Energy
     (Speed_Val : Speed;
      Radius    : Positive_Distance;
      Mu        : Gravitational_Parameter) return Long_Float
   is
      V : constant Long_Float := Long_Float (Speed_Val);
      R : constant Long_Float := Long_Float (Radius);
   begin
      return (V * V / 2.0) - (Long_Float (Mu) / R);
   end Specific_Orbital_Energy;

   function Specific_Relative_Angular_Momentum
     (Semi_Latus_Rectum : Positive_Distance;
      Mu                : Gravitational_Parameter) return Long_Float
   is
   begin
      return Sqrt (Long_Float (Semi_Latus_Rectum) * Long_Float (Mu));
   end Specific_Relative_Angular_Momentum;

   function Semi_Latus_Rectum
     (Semi_Major_Axis : Positive_Distance;
      Ecc             : Elliptic_Eccentricity) return Positive_Distance
   is
      E : constant Long_Float := Long_Float (Ecc);
   begin
      return Positive_Distance (Long_Float (Semi_Major_Axis) * (1.0 - E * E));
   end Semi_Latus_Rectum;

   ----------------------------------------------------------------------
   --  4. Apsidal Geometry
   ----------------------------------------------------------------------

   function Periapsis_Distance
     (Semi_Major_Axis : Positive_Distance;
      Ecc             : Eccentricity) return Distance
   is
   begin
      return Distance (Long_Float (Semi_Major_Axis) * (1.0 - Long_Float (Ecc)));
   end Periapsis_Distance;

   function Apoapsis_Distance
     (Semi_Major_Axis : Positive_Distance;
      Ecc             : Elliptic_Eccentricity) return Positive_Distance
   is
   begin
      return Positive_Distance (Long_Float (Semi_Major_Axis) * (1.0 + Long_Float (Ecc)));
   end Apoapsis_Distance;

   ----------------------------------------------------------------------
   --  5. Kepler's Equation Solvers
   ----------------------------------------------------------------------

   function Solve_Kepler_Elliptic
     (Mean_Anomaly : Radians;
      Ecc          : Elliptic_Eccentricity;
      Tolerance    : Long_Float := 1.0e-12;
      Max_Iter     : Positive   := 100) return Radians
   is
      M_Norm : constant Long_Float := Normalize_Angle (Long_Float (Mean_Anomaly));
      E_Val  : Long_Float;
      Step   : Long_Float;
      E_Num  : constant Long_Float := Long_Float (Ecc);
   begin
      --  Initial guess: E_0 = M for e < 0.8, else pi
      if E_Num < 0.8 then
         E_Val := M_Norm;
      else
         E_Val := Ada.Numerics.Pi;
      end if;

      --  Newton-Raphson iteration:
      --  f(E) = E - e*sin(E) - M
      --  f'(E) = 1 - e*cos(E)
      for Iter in 1 .. Max_Iter loop
         Step := (E_Val - E_Num * Sin (E_Val) - M_Norm) /
                 (1.0 - E_Num * Cos (E_Val));
         E_Val := E_Val - Step;

         if abs (Step) < Tolerance then
            return Radians (E_Val);
         end if;
      end loop;

      raise Convergence_Error with "Newton-Raphson failed to converge for elliptic Kepler equation";
   end Solve_Kepler_Elliptic;

   function Solve_Kepler_Hyperbolic
     (Mean_Anomaly : Radians;
      Ecc          : Hyperbolic_Eccentricity;
      Tolerance    : Long_Float := 1.0e-12;
      Max_Iter     : Positive   := 100) return Radians
   is
      M_Val : constant Long_Float := Long_Float (Mean_Anomaly);
      E_Num : constant Long_Float := Long_Float (Ecc);
      H_Val : Long_Float;
      Step  : Long_Float;
   begin
      --  Initial estimate for hyperbolic anomaly
      H_Val := M_Val / (E_Num - 1.0);
      if abs (H_Val) > 5.0 then
         if M_Val > 0.0 then
            H_Val := Log (2.0 * M_Val / E_Num);
         else
            H_Val := -Log (-2.0 * M_Val / E_Num);
         end if;
      end if;

      --  Newton-Raphson:
      --  f(H) = e * sinh(H) - H - M
      --  f'(H) = e * cosh(H) - 1
      for Iter in 1 .. Max_Iter loop
         Step := (E_Num * Sinh (H_Val) - H_Val - M_Val) /
                 (E_Num * Cosh (H_Val) - 1.0);
         H_Val := H_Val - Step;

         if abs (Step) < Tolerance then
            return Radians (H_Val);
         end if;
      end loop;

      raise Convergence_Error with "Newton-Raphson failed to converge for hyperbolic Kepler equation";
   end Solve_Kepler_Hyperbolic;

   function True_Anomaly_From_Eccentric
     (Eccentric_Anomaly : Radians;
      Ecc               : Elliptic_Eccentricity) return Radians
   is
      E_Val   : constant Long_Float := Long_Float (Eccentric_Anomaly);
      E_Num   : constant Long_Float := Long_Float (Ecc);
      Factor  : constant Long_Float := Sqrt ((1.0 + E_Num) / (1.0 - E_Num));
      Nu_Half : constant Long_Float := Arctan (Factor * Tan (E_Val / 2.0));
   begin
      return Radians (2.0 * Nu_Half);
   end True_Anomaly_From_Eccentric;

   function Radius_At_True_Anomaly
     (Semi_Latus_Rectum_Val : Positive_Distance;
      Ecc                   : Eccentricity;
      True_Anomaly          : Radians) return Positive_Distance
   is
      P      : constant Long_Float := Long_Float (Semi_Latus_Rectum_Val);
      E_Num  : constant Long_Float := Long_Float (Ecc);
      Denom  : constant Long_Float := 1.0 + E_Num * Cos (Long_Float (True_Anomaly));
   begin
      if Denom <= 0.0 then
         raise Singularity_Error with "Denominator non-positive at given true anomaly";
      end if;
      return Positive_Distance (P / Denom);
   end Radius_At_True_Anomaly;

   ----------------------------------------------------------------------
   --  6. Hohmann Orbital Transfer
   ----------------------------------------------------------------------

   function Hohmann_Transfer
     (Mu       : Gravitational_Parameter;
      Radius_1 : Positive_Distance;
      Radius_2 : Positive_Distance) return Hohmann_Transfer_Result
   is
      R1     : constant Long_Float := Long_Float (Radius_1);
      R2     : constant Long_Float := Long_Float (Radius_2);
      A_Tx   : constant Long_Float := (R1 + R2) / 2.0;

      V_C1   : constant Long_Float := Long_Float (Circular_Velocity (Mu, Radius_1));
      V_C2   : constant Long_Float := Long_Float (Circular_Velocity (Mu, Radius_2));

      --  Velocity on transfer ellipse at periapsis / apoapsis
      V_Tx1  : constant Long_Float := Long_Float (Vis_Viva_Velocity (Mu, Radius_1, 1.0 / A_Tx));
      V_Tx2  : constant Long_Float := Long_Float (Vis_Viva_Velocity (Mu, Radius_2, 1.0 / A_Tx));

      Dv1    : constant Long_Float := abs (V_Tx1 - V_C1);
      Dv2    : constant Long_Float := abs (V_C2 - V_Tx2);
      T_Hohm : constant Long_Float := Long_Float (Orbital_Period (Mu, Positive_Distance (A_Tx))) / 2.0;
   begin
      return Hohmann_Transfer_Result'
        (Transfer_Semi_Major_Axis => Positive_Distance (A_Tx),
         Delta_V_1                => Speed (Dv1),
         Delta_V_2                => Speed (Dv2),
         Total_Delta_V            => Speed (Dv1 + Dv2),
         Time_Of_Flight           => Positive_Time (T_Hohm));
   end Hohmann_Transfer;

end Orbital_Mechanics;
