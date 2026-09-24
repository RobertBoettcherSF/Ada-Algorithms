--  Featherstone — Ada 2023 educational planar serial-chain rigid-body
--  dynamics: Recursive Newton–Euler (RNEA) inverse dynamics and the
--  Articulated-Body Algorithm (ABA) for O(N) forward dynamics, plus
--  Composite-Rigid-Body (CRBA) mass-matrix formation. Based on
--  Roy Featherstone, Robot Dynamics Algorithms (1987); Mirtich thesis;
--  Wikipedia "Featherstone's algorithm". Planar (2-D) revolute chains.

pragma Ada_2022;

package Featherstone
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_N : constant Positive := 16;

   subtype Link_Count is Natural range 0 .. Max_N;
   subtype Link_Index is Positive range 1 .. Max_N;

   type Vec2 is record
      X, Y : Real := 0.0;
   end record;

   --  One rigid link in a planar serial open chain (revolute joint at the
   --  proximal end). Distal / COM are expressed in the link body frame
   --  (x along the undeformed link axis when the relative angle is zero).
   type Link is record
      Mass     : Non_Negative := 1.0;
      COM      : Vec2 := (0.5, 0.0);   -- COM relative to proximal joint
      I_COM    : Non_Negative := 0.0;  -- scalar inertia about COM (planar)
      Distal   : Vec2 := (1.0, 0.0);   -- next joint relative to proximal
   end record;

   type Link_Array  is array (Link_Index range <>) of Link;
   type Real_Array  is array (Link_Index range <>) of Real;
   type Vec2_Array  is array (Link_Index range <>) of Vec2;
   type Mat_NN      is array (Link_Index range <>, Link_Index range <>) of Real;

   --  Fixed-size working chain (educational; capacity Max_N).
   type Chain is private;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Empty_Chain       : exception;
   Singular_Inertia  : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Vec (A, B : Vec2; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Cross_Z (A, B : Vec2) return Real
     with Global => null;
   --  Planar cross product z-component: Ax*By - Ay*Bx.

   function Rot (Angle : Real; V : Vec2) return Vec2
     with Global => null;
   --  Rotate V by Angle (radians, CCW).

   function Mag (V : Vec2) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- Chain construction / accessors
   ---------------------------------------------------------------------------

   function Create
     (N        : Link_Count;
      Gravity  : Vec2 := (0.0, -9.81)) return Chain
     with Pre => N <= Max_N, Global => null;
   --  Empty geometry; call Set_Link for each body. State cleared to zero.

   procedure Set_Link
     (C : in out Chain;
      I : Link_Index;
      L : Link)
     with Pre => I <= Max_N;

   procedure Set_Gravity (C : in out Chain; G : Vec2);

   procedure Set_State
     (C   : in out Chain;
      Q   : Real_Array;
      Qd  : Real_Array;
      Qdd : Real_Array;
      Tau : Real_Array)
     with Pre =>
       Q'First = 1 and Qd'First = 1 and Qdd'First = 1 and Tau'First = 1;

   procedure Set_Q   (C : in out Chain; Q   : Real_Array);
   procedure Set_Qd  (C : in out Chain; Qd  : Real_Array);
   procedure Set_Qdd (C : in out Chain; Qdd : Real_Array);
   procedure Set_Tau (C : in out Chain; Tau : Real_Array);

   function N_Links  (C : Chain) return Link_Count;
   function Gravity  (C : Chain) return Vec2;
   function Get_Link (C : Chain; I : Link_Index) return Link
     with Pre => I <= N_Links (C);

   function Get_Q   (C : Chain; I : Link_Index) return Real
     with Pre => I <= N_Links (C);
   function Get_Qd  (C : Chain; I : Link_Index) return Real
     with Pre => I <= N_Links (C);
   function Get_Qdd (C : Chain; I : Link_Index) return Real
     with Pre => I <= N_Links (C);
   function Get_Tau (C : Chain; I : Link_Index) return Real
     with Pre => I <= N_Links (C);

   --  Convenience: uniform identical links of length Len, mass M, COM at mid.
   function Make_Uniform_Chain
     (N       : Link_Count;
      Len     : Positive_Real := 1.0;
      Mass    : Positive_Real := 1.0;
      Gravity : Vec2 := (0.0, -9.81)) return Chain
     with Pre => N >= 1 and N <= Max_N;

   ---------------------------------------------------------------------------
   -- Forward kinematics
   ---------------------------------------------------------------------------

   type FK_Result is record
      Abs_Angle : Real_Array (1 .. Max_N);
      Joint_Pos : Vec2_Array (1 .. Max_N);  -- proximal joint of each link
      COM_Pos   : Vec2_Array (1 .. Max_N);
      Tip_Pos   : Vec2 := (0.0, 0.0);
      Used      : Link_Count := 0;
   end record;

   function Forward_Kinematics (C : Chain) return FK_Result
     with Pre => N_Links (C) >= 1;

   ---------------------------------------------------------------------------
   -- Inverse dynamics — Recursive Newton–Euler (RNEA), O(N)
   ---------------------------------------------------------------------------
   --  Given q, qd, qdd (stored in C) return joint torques Tau.
   --  Includes gravity, Coriolis / centrifugal, and inertial terms.

   function Inverse_Dynamics_RNEA (C : Chain) return Real_Array
     with Pre => N_Links (C) >= 1;

   --  Override accelerations without mutating C.
   function Inverse_Dynamics_RNEA
     (C   : Chain;
      Qdd : Real_Array) return Real_Array
     with Pre => N_Links (C) >= 1 and Qdd'First = 1;

   ---------------------------------------------------------------------------
   -- Mass matrix — Composite-Rigid-Body Algorithm (CRBA) spirit, O(N^2)
   ---------------------------------------------------------------------------
   --  H(q) such that Tau = H(q) Qdd + C(q,qd) with C = RNEA(q,qd,0).
   --  Built column-wise via unit-acceleration RNEA (gravity cancelled).

   function Mass_Matrix (C : Chain) return Mat_NN
     with Pre => N_Links (C) >= 1;

   ---------------------------------------------------------------------------
   -- Forward dynamics — Articulated-Body Algorithm (ABA), O(N)
   ---------------------------------------------------------------------------
   --  Given q, qd, Tau (in C) return joint accelerations Qdd.
   --  Planar 3-D spatial algebra (ω, vx, vy) with articulated inertias.

   function Forward_Dynamics_ABA (C : Chain) return Real_Array
     with Pre => N_Links (C) >= 1;

   --  CRBA + dense solve: Qdd = H^{-1} (Tau - RNEA(q,qd,0)). O(N^3) solve
   --  after O(N^2) H; useful cross-check against ABA.
   function Forward_Dynamics_CRBA (C : Chain) return Real_Array
     with Pre => N_Links (C) >= 1;

   ---------------------------------------------------------------------------
   -- Bias / gravity helpers
   ---------------------------------------------------------------------------

   function Bias_Forces (C : Chain) return Real_Array
     with Pre => N_Links (C) >= 1;
   --  RNEA(q, qd, 0) = Coriolis/centrifugal + gravity torques.

   function Gravity_Torques (C : Chain) return Real_Array
     with Pre => N_Links (C) >= 1;
   --  RNEA(q, 0, 0) with current gravity.

private

   type Chain is record
      N       : Link_Count := 0;
      Links   : Link_Array (1 .. Max_N);
      Q       : Real_Array (1 .. Max_N) := [others => 0.0];
      Qd      : Real_Array (1 .. Max_N) := [others => 0.0];
      Qdd     : Real_Array (1 .. Max_N) := [others => 0.0];
      Tau     : Real_Array (1 .. Max_N) := [others => 0.0];
      Grav    : Vec2 := (0.0, -9.81);
   end record;

end Featherstone;
