--  N_Body_Problems — Ada 2023 educational survey of the classical
--  gravitational n-body problem in 2-D: Newtonian forces with softening,
--  two-body circular-orbit helpers, direct O(N²) summation, Euler and
--  leapfrog (velocity Verlet) integrators, energies / momentum / COM,
--  and a trivial far-cluster monopole force note (see siblings Ada-Barnes-Hut
--  and Ada-Fast-Multipole-Method for hierarchical methods).
--  Based on Wikipedia "n-body problem".

pragma Ada_2022;

package N_Body_Problems
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Bodies : constant Positive := 4_096;

   subtype Body_Count is Natural range 0 .. Max_Bodies;
   subtype Body_Index is Positive range 1 .. Max_Bodies;

   type Vec2 is record
      X, Y : Real := 0.0;
   end record;

   type Body_State is record
      Mass : Non_Negative := 1.0;
      Pos  : Vec2 := (0.0, 0.0);
      Vel  : Vec2 := (0.0, 0.0);
   end record;

   type Body_Array  is array (Body_Index range <>) of Body_State;
   type Force_Array is array (Body_Index range <>) of Vec2;
   type Accel_Array is array (Body_Index range <>) of Vec2;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Empty_System      : exception;

   ---------------------------------------------------------------------------
   -- Configuration (G, softening ε)
   ---------------------------------------------------------------------------

   type NB_Config is record
      G         : Non_Negative := 1.0;
      Softening : Non_Negative := 1.0E-4;
   end record;

   function Default_Config return NB_Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-9;
   Two_Pi      : constant Real := 6.283185307179586_47692;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Hypot (X, Y : Real) return Non_Negative
     with Global => null;
   --  sqrt(X^2 + Y^2) without overflow for educational ranges.

   function Soft_Denom (DX, DY, Soft_Eps : Real) return Positive_Real
     with Pre => Soft_Eps >= 0.0, Global => null;
   --  (r^2 + eps^2)^{3/2} floored away from zero for the force kernel.

   function Vec_Add (A, B : Vec2) return Vec2
     with Global => null;

   function Vec_Sub (A, B : Vec2) return Vec2
     with Global => null;

   function Vec_Scale (V : Vec2; S : Real) return Vec2
     with Global => null;

   function Vec_Norm (V : Vec2) return Non_Negative
     with Global => null;

   function Dot (A, B : Vec2) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Softened Newtonian pairwise force
   ---------------------------------------------------------------------------
   --  F_on_1_by_2 = G * m1 * m2 * (P2 - P1) / (r^2 + eps^2)^{3/2}
   --  (attraction of body 1 toward body 2). Softening avoids singularities.
   --  The 3-D formula is identical with Vec3; this survey uses 2-D.

   function Pair_Force
     (M1, M2      : Non_Negative;
      P1, P2      : Vec2;
      G, Soft_Eps : Non_Negative) return Vec2
     with Global => null;

   function Pair_Potential
     (M1, M2      : Non_Negative;
      P1, P2      : Vec2;
      G, Soft_Eps : Non_Negative) return Real
     with Global => null;
   --  Softened pair potential: -G m1 m2 / sqrt(r^2 + eps^2).

   ---------------------------------------------------------------------------
   -- Direct summation O(N²)
   ---------------------------------------------------------------------------

   procedure Forces_Direct
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : NB_Config;
      Out_F  : out Force_Array)
     with Pre => Count <= Bodies'Length
                 and then Out_F'Length >= Count
                 and then Out_F'First = 1,
          Global => null;

   procedure Accelerations_Direct
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : NB_Config;
      Out_A  : out Accel_Array)
     with Pre => Count <= Bodies'Length
                 and then Out_A'Length >= Count
                 and then Out_A'First = 1,
          Global => null;
   --  a_i = F_i / m_i (zero mass => zero accel).

   ---------------------------------------------------------------------------
   -- Energies, momentum, center of mass
   ---------------------------------------------------------------------------

   function Kinetic_Energy
     (Bodies : Body_Array; Count : Body_Count) return Non_Negative
     with Pre => Count <= Bodies'Length, Global => null;
   --  sum_i (1/2) m_i |v_i|^2

   function Potential_Energy
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : NB_Config) return Real
     with Pre => Count <= Bodies'Length, Global => null;
   --  Softened sum_{i<j} Pair_Potential (negative for gravity).

   function Total_Energy
     (Bodies : Body_Array;
      Count  : Body_Count;
      Config : NB_Config) return Real
     with Pre => Count <= Bodies'Length, Global => null;

   function Linear_Momentum
     (Bodies : Body_Array; Count : Body_Count) return Vec2
     with Pre => Count <= Bodies'Length, Global => null;
   --  sum_i m_i v_i

   function Total_Mass
     (Bodies : Body_Array; Count : Body_Count) return Non_Negative
     with Pre => Count <= Bodies'Length, Global => null;

   function Center_Of_Mass
     (Bodies : Body_Array; Count : Body_Count) return Vec2
     with Pre => Count <= Bodies'Length, Global => null;
   --  Raises Empty_System if total mass is zero.

   function Angular_Momentum_Z
     (Bodies : Body_Array; Count : Body_Count) return Real
     with Pre => Count <= Bodies'Length, Global => null;
   --  2-D scalar L_z about origin: sum_i m (x v_y - y v_x).

   ---------------------------------------------------------------------------
   -- Two-body helpers
   ---------------------------------------------------------------------------

   function Reduced_Mass (M1, M2 : Non_Negative) return Non_Negative
     with Global => null;
   --  μ = m1 m2 / (m1 + m2); 0 if both masses vanish.

   function Circular_Orbit_Speed
     (M_Total : Non_Negative;
      A       : Positive_Real;
      G       : Non_Negative := 1.0) return Non_Negative
     with Global => null;
   --  Relative circular speed sqrt(G M / a) for separation a.

   function Circular_Orbit_Period
     (M_Total : Non_Negative;
      A       : Positive_Real;
      G       : Non_Negative := 1.0) return Positive_Real
     with Pre => G > 0.0 and then M_Total > 0.0,
          Global => null;
   --  Kepler: T = 2π sqrt(a³ / (G M)).

   function Circular_Orbit_Energy
     (M1, M2 : Non_Negative;
      A      : Positive_Real;
      G      : Non_Negative := 1.0) return Real
     with Global => null;
   --  E = -G m1 m2 / (2 a) for a circular relative orbit.

   procedure Make_Circular_Binary
     (M1, M2   : Non_Negative;
      Separation : Positive_Real;
      G        : Non_Negative;
      Bodies   : out Body_Array;
      Count    : out Body_Count)
     with Pre => Bodies'Length >= 2
                 and then Bodies'First = 1
                 and then (M1 + M2) > 0.0,
          Global => null;
   --  Two bodies on COM-centered circular orbits in the XY plane,
   --  along the X axis at t=0, counter-clockwise.

   ---------------------------------------------------------------------------
   -- Integrators
   ---------------------------------------------------------------------------

   procedure Euler_Step
     (Bodies : in out Body_Array;
      Count  : Body_Count;
      Config : NB_Config;
      Dt     : Real)
     with Pre => Count <= Bodies'Length and then Dt >= 0.0,
          Global => null;
   --  Explicit Euler: a = F/m; x += v dt; v += a dt.

   procedure Leapfrog_Step
     (Bodies : in out Body_Array;
      Count  : Body_Count;
      Config : NB_Config;
      Dt     : Real)
     with Pre => Count <= Bodies'Length and then Dt >= 0.0,
          Global => null;
   --  Velocity Verlet / leapfrog (kick-drift-kick):
   --  v += 0.5 a dt; x += v dt; recompute a; v += 0.5 a dt.
   --  Symplectic; better long-term energy behaviour than Euler.

   ---------------------------------------------------------------------------
   -- Few-body / many-body helpers
   ---------------------------------------------------------------------------

   function Force_Sum
     (Forces : Force_Array; Count : Body_Count) return Vec2
     with Pre => Count <= Forces'Length and then Forces'First = 1,
          Global => null;
   --  Net force (should be ~0 by Newton's third law when soft eps is shared).

   function Force_Approx_Monopole_Cluster
     (Target_Mass : Non_Negative;
      Target_Pos  : Vec2;
      Cluster_Mass : Non_Negative;
      Cluster_COM  : Vec2;
      G, Soft_Eps  : Non_Negative) return Vec2
     with Global => null;
   --  Trivial far-field monopole: treat a distant cluster as one point mass
   --  at its COM. Educational stand-in; full tree / FMM live in siblings
   --  Ada-Barnes-Hut and Ada-Fast-Multipole-Method (not dependencies).

   function Accept_Monopole
     (Cluster_Size : Non_Negative;
      Dist         : Non_Negative;
      Theta        : Non_Negative) return Boolean
     with Global => null;
   --  Classic opening criterion Size/Dist < Theta (same idea as Barnes–Hut).

end N_Body_Problems;
