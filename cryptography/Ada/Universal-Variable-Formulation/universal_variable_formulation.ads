--  Universal Variable Formulation in Orbital Mechanics
--  Package Specification
--  Standard: Ada 2023 (ISO/IEC 8652:2023)

package Universal_Variable_Formulation with
  SPARK_Mode => Off
is

   --  ========================================================================
   --  Domain Types and Subtypes
   --  ========================================================================

   type Real is new Long_Float;

   type Distance is new Real;
   subtype Length is Distance;
   subtype Non_Negative_Distance is Distance range 0.0 .. Distance'Last;
   subtype Positive_Distance is Distance range 1.0e-12 .. Distance'Last;

   type Velocity is new Real;
   type Time_Span is new Real;
   subtype Positive_Time is Time_Span range 1.0e-12 .. Time_Span'Last;

   type Gravitational_Parameter is new Real range 1.0e-12 .. Real'Last;
   type Universal_Anomaly is new Real;
   type Dimensionless is new Real;

   type Vector_3D is record
      X : Real := 0.0;
      Y : Real := 0.0;
      Z : Real := 0.0;
   end record;

   type State_Vector is record
      R : Vector_3D;
      V : Vector_3D;
   end record;

   type Orbit_Type is (Elliptic, Parabolic, Hyperbolic);

   --  Standard Gravitational Parameter for Earth (km^3 / s^2)
   Earth_Mu : constant Gravitational_Parameter := 398600.4418;

   --  Standard Gravitational Parameter for Sun (km^3 / s^2)
   Sun_Mu   : constant Gravitational_Parameter := 132712440018.0;

   --  ========================================================================
   --  Exceptions
   --  ========================================================================

   Convergence_Error  : exception;
   Invalid_State      : exception;
   Singularity_Error  : exception;

   --  ========================================================================
   --  Vector Helper Operations
   --  ========================================================================

   function "+" (Left, Right : Vector_3D) return Vector_3D with
     Inline,
     Global => null;

   function "-" (Left, Right : Vector_3D) return Vector_3D with
     Inline,
     Global => null;

   function "*" (Scalar : Real; Vec : Vector_3D) return Vector_3D with
     Inline,
     Global => null;

   function "*" (Vec : Vector_3D; Scalar : Real) return Vector_3D with
     Inline,
     Global => null;

   function "/" (Vec : Vector_3D; Scalar : Real) return Vector_3D with
     Inline,
     Pre    => Scalar /= 0.0,
     Global => null;

   function Dot_Product (U, V : Vector_3D) return Real with
     Inline,
     Global => null;

   function Cross_Product (U, V : Vector_3D) return Vector_3D with
     Inline,
     Global => null;

   function Magnitude (V : Vector_3D) return Distance with
     Inline,
     Global => null;

   --  ========================================================================
   --  Stumpff Functions: c_0(z), c_1(z), c_2(z), c_3(z), c_4(z), c_5(z)
   --  ========================================================================

   function Stumpff_C0 (Z : Real) return Real with
     Global => null;

   function Stumpff_C1 (Z : Real) return Real with
     Global => null;

   function Stumpff_C2 (Z : Real) return Real with
     Global => null;

   function Stumpff_C3 (Z : Real) return Real with
     Global => null;

   function Stumpff_C4 (Z : Real) return Real with
     Global => null;

   function Stumpff_C5 (Z : Real) return Real with
     Global => null;

   --  ========================================================================
   --  Core Orbital Calculations
   --  ========================================================================

   function Specific_Mechanical_Energy
     (R  : Vector_3D;
      V  : Vector_3D;
      Mu : Gravitational_Parameter) return Real with
     Pre    => Magnitude (R) > 0.0,
     Global => null;

   function Classify_Orbit
     (R  : Vector_3D;
      V  : Vector_3D;
      Mu : Gravitational_Parameter) return Orbit_Type with
     Pre    => Magnitude (R) > 0.0,
     Global => null;

   function Reciprocal_Semi_Major_Axis
     (R_Mag : Distance;
      V_Mag : Velocity;
      Mu    : Gravitational_Parameter) return Real with
     Pre    => R_Mag > 0.0,
     Global => null;

   --  ========================================================================
   --  Universal Variable Propagation (Gauss f and g)
   --  ========================================================================

   function Solve_Kepler_Universal
     (R0         : Vector_3D;
      V0         : Vector_3D;
      Dt         : Time_Span;
      Mu         : Gravitational_Parameter;
      Tolerance  : Real := 1.0e-10;
      Max_Iter   : Positive := 100) return Universal_Anomaly with
     Pre    => Magnitude (R0) > 0.0,
     Global => null;

   procedure Propagate_Kepler_Universal
     (R0         : in  Vector_3D;
      V0         : in  Vector_3D;
      Dt         : in  Time_Span;
      Mu         : in  Gravitational_Parameter;
      R_Final    : out Vector_3D;
      V_Final    : out Vector_3D;
      Tolerance  : in  Real := 1.0e-10;
      Max_Iter   : in  Positive := 100) with
     Pre    => Magnitude (R0) > 0.0,
     Post   => Magnitude (R_Final) > 0.0,
     Global => null;

   function Propagate_State
     (State      : State_Vector;
      Dt         : Time_Span;
      Mu         : Gravitational_Parameter;
      Tolerance  : Real := 1.0e-10;
      Max_Iter   : Positive := 100) return State_Vector with
     Pre    => Magnitude (State.R) > 0.0,
     Global => null;

   --  ========================================================================
   --  Universal Variable Lambert Problem Solver
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
      Max_Iter   : in  Positive := 120) with
     Pre    => Magnitude (R1) > 0.0 and Magnitude (R2) > 0.0 and Dt > 0.0,
     Global => null;

end Universal_Variable_Formulation;
