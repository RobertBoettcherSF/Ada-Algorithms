--  Package: Orbital_Mechanics
--  Standard: Ada 2023 (ISO/IEC 8652:2023)
--  Description: Core algorithms of classical Keplerian two-body orbital mechanics,
--               including vis-viva equation, Kepler's third law, orbital velocity
--               variants (circular, escape, parabolic, hyperbolic), and Kepler's
--               equation solvers for elliptic and hyperbolic regimes.

with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;

package Orbital_Mechanics with
  SPARK_Mode => On
is
   --  Standard Gravitational Constant (m^3 * kg^-1 * s^-2)
   G_Constant : constant := 6.67430e-11;

   --  Standard Gravitational Parameter for Earth (m^3 * s^-2)
   Mu_Earth   : constant := 3.986004418e14;

   --  Standard Gravitational Parameter for Sun (m^3 * s^-2)
   Mu_Sun     : constant := 1.32712440018e20;

   ----------------------------------------------------------------------
   --  Strong Domain Types & Subtypes
   ----------------------------------------------------------------------
   type Gravitational_Parameter is new Long_Float range 0.0 .. Long_Float'Last;
   --  Standard gravitational parameter (mu = G * M) in m^3 / s^2

   type Distance is new Long_Float range 0.0 .. Long_Float'Last;
   --  Distance or radius in meters (m)

   subtype Positive_Distance is Distance range 1.0e-3 .. Distance'Last;
   --  Strictly positive distance (m)

   type Speed is new Long_Float range 0.0 .. Long_Float'Last;
   --  Speed magnitude in meters per second (m/s)

   type Time_Seconds is new Long_Float range 0.0 .. Long_Float'Last;
   --  Time duration or period in seconds (s)

   subtype Positive_Time is Time_Seconds range 1.0e-6 .. Time_Seconds'Last;

   type Eccentricity is new Long_Float range 0.0 .. Long_Float'Last;
   --  Orbital eccentricity (e >= 0.0)

   subtype Circular_Eccentricity is Eccentricity range 0.0 .. 0.0;
   subtype Elliptic_Eccentricity is Eccentricity range 0.0 .. 0.99999999;
   subtype Parabolic_Eccentricity is Eccentricity range 1.0 .. 1.0;
   subtype Hyperbolic_Eccentricity is Eccentricity range 1.00000001 .. Eccentricity'Last;

   type Radians is new Long_Float;
   --  Angle measure in radians

   subtype Anomaly_Angle is Radians;

   type Dimensionless is new Long_Float;

   --  Exception raised when an iterative numerical method fails to converge
   Convergence_Error : exception;

   --  Exception raised when orbital parameters violate physical assumptions
   Singularity_Error : exception;

   ----------------------------------------------------------------------
   --  1. Orbital Velocities (Vis-Viva Equation and Sub-Variants)
   ----------------------------------------------------------------------

   --  General Vis-Viva Equation: v^2 = mu * (2/r - 1/a)
   --  Applicable to elliptic (a > 0), parabolic (a = infinity -> 1/a = 0),
   --  and hyperbolic (a < 0) trajectories.
   function Vis_Viva_Velocity
     (Mu                   : Gravitational_Parameter;
      Current_Radius       : Positive_Distance;
      Semi_Major_Axis_Inv  : Long_Float) return Speed
   with
     Pre  => Mu > 0.0
             and then ((2.0 / Long_Float (Current_Radius)) - Semi_Major_Axis_Inv) >= 0.0,
     Post => Vis_Viva_Velocity'Result >= 0.0;

   --  Circular Orbital Velocity: v_circ = sqrt(mu / r)
   function Circular_Velocity
     (Mu     : Gravitational_Parameter;
      Radius : Positive_Distance) return Speed
   with
     Pre  => Mu > 0.0,
     Post => Circular_Velocity'Result > 0.0;

   --  Escape Velocity: v_esc = sqrt(2 * mu / r) = sqrt(2) * v_circ
   function Escape_Velocity
     (Mu     : Gravitational_Parameter;
      Radius : Positive_Distance) return Speed
   with
     Pre  => Mu > 0.0,
     Post => Escape_Velocity'Result > 0.0;

   --  Hyperbolic Excess Velocity: v_inf = sqrt(v^2 - v_esc^2) = sqrt(-mu / a)
   function Hyperbolic_Excess_Velocity
     (Mu              : Gravitational_Parameter;
      Semi_Major_Axis : Long_Float) return Speed
   with
     Pre  => Mu > 0.0 and then Semi_Major_Axis < 0.0,
     Post => Hyperbolic_Excess_Velocity'Result > 0.0;

   ----------------------------------------------------------------------
   --  2. Kepler's Third Law Variants
   ----------------------------------------------------------------------

   --  Orbital Period from Semi-Major Axis: T = 2 * pi * sqrt(a^3 / mu)
   function Orbital_Period
     (Mu              : Gravitational_Parameter;
      Semi_Major_Axis : Positive_Distance) return Positive_Time
   with
     Pre  => Mu > 0.0,
     Post => Orbital_Period'Result > 0.0;

   --  Semi-Major Axis from Orbital Period: a = (mu * (T / (2 * pi))^2)^(1/3)
   function Semi_Major_Axis_From_Period
     (Mu     : Gravitational_Parameter;
      Period : Positive_Time) return Positive_Distance
   with
     Pre  => Mu > 0.0,
     Post => Semi_Major_Axis_From_Period'Result > 0.0;

   --  Mean Motion: n = sqrt(mu / a^3) = 2 * pi / T (rad/s)
   function Mean_Motion
     (Mu              : Gravitational_Parameter;
      Semi_Major_Axis : Positive_Distance) return Long_Float
   with
     Pre  => Mu > 0.0,
     Post => Mean_Motion'Result > 0.0;

   ----------------------------------------------------------------------
   --  3. Specific Orbital Energy and Momentum
   ----------------------------------------------------------------------

   --  Specific Mechanical Energy: epsilon = -mu / (2 * a) = v^2 / 2 - mu / r
   function Specific_Orbital_Energy
     (Speed_Val : Speed;
      Radius    : Positive_Distance;
      Mu        : Gravitational_Parameter) return Long_Float
   with
     Pre => Mu > 0.0;

   --  Specific Angular Momentum: h = r * v * sin(phi) or sqrt(p * mu)
   function Specific_Relative_Angular_Momentum
     (Semi_Latus_Rectum : Positive_Distance;
      Mu                : Gravitational_Parameter) return Long_Float
   with
     Pre  => Mu > 0.0,
     Post => Specific_Relative_Angular_Momentum'Result > 0.0;

   --  Semi-Latus Rectum: p = a * (1 - e^2) for elliptic
   function Semi_Latus_Rectum
     (Semi_Major_Axis : Positive_Distance;
      Ecc             : Elliptic_Eccentricity) return Positive_Distance
   with
     Pre  => Ecc < 1.0,
     Post => Semi_Latus_Rectum'Result <= Semi_Major_Axis;

   ----------------------------------------------------------------------
   --  4. Apsidal Geometry
   ----------------------------------------------------------------------

   --  Periapsis radius: r_p = a * (1 - e)
   function Periapsis_Distance
     (Semi_Major_Axis : Positive_Distance;
      Ecc             : Eccentricity) return Distance
   with
     Pre => Ecc <= 1.0;

   --  Apoapsis radius: r_a = a * (1 + e)
   function Apoapsis_Distance
     (Semi_Major_Axis : Positive_Distance;
      Ecc             : Elliptic_Eccentricity) return Positive_Distance
   with
     Pre  => Ecc < 1.0,
     Post => Apoapsis_Distance'Result >= Semi_Major_Axis;

   ----------------------------------------------------------------------
   --  5. Kepler's Equation Solvers
   ----------------------------------------------------------------------

   --  Elliptic Kepler Equation Solver: M = E - e * sin(E)
   --  Finds Eccentric Anomaly E given Mean Anomaly M and Eccentricity e
   function Solve_Kepler_Elliptic
     (Mean_Anomaly : Radians;
      Ecc          : Elliptic_Eccentricity;
      Tolerance    : Long_Float := 1.0e-12;
      Max_Iter     : Positive   := 100) return Radians
   with
     Pre => Ecc < 1.0 and then Tolerance > 0.0;

   --  Hyperbolic Kepler Equation Solver: M_h = e * sinh(H) - H
   --  Finds Hyperbolic Anomaly H given Hyperbolic Mean Anomaly M_h and Eccentricity e
   function Solve_Kepler_Hyperbolic
     (Mean_Anomaly : Radians;
      Ecc          : Hyperbolic_Eccentricity;
      Tolerance    : Long_Float := 1.0e-12;
      Max_Iter     : Positive   := 100) return Radians
   with
     Pre => Ecc > 1.0 and then Tolerance > 0.0;

   --  True Anomaly from Eccentric Anomaly (Elliptic):
   --  cos(nu) = (cos(E) - e) / (1 - e * cos(E))
   --  tan(nu / 2) = sqrt((1 + e) / (1 - e)) * tan(E / 2)
   function True_Anomaly_From_Eccentric
     (Eccentric_Anomaly : Radians;
      Ecc               : Elliptic_Eccentricity) return Radians
   with
     Pre => Ecc < 1.0;

   --  Orbital radius at true anomaly: r = p / (1 + e * cos(nu))
   function Radius_At_True_Anomaly
     (Semi_Latus_Rectum_Val : Positive_Distance;
      Ecc                   : Eccentricity;
      True_Anomaly          : Radians) return Positive_Distance
   with
     Pre => (1.0 + Long_Float (Ecc) *
               Ada.Numerics.Long_Elementary_Functions.Cos (Long_Float (True_Anomaly))) > 0.0;

   ----------------------------------------------------------------------
   --  6. Hohmann Orbital Transfer Calculations
   ----------------------------------------------------------------------

   type Hohmann_Transfer_Result is record
      Transfer_Semi_Major_Axis : Positive_Distance;
      Delta_V_1                : Speed;
      Delta_V_2                : Speed;
      Total_Delta_V            : Speed;
      Time_Of_Flight           : Positive_Time;
   end record;

   --  Calculates two-impulse co-planar Hohmann transfer between circular orbits
   function Hohmann_Transfer
     (Mu       : Gravitational_Parameter;
      Radius_1 : Positive_Distance;
      Radius_2 : Positive_Distance) return Hohmann_Transfer_Result
   with
     Pre => Mu > 0.0 and then Radius_1 /= Radius_2;

end Orbital_Mechanics;
