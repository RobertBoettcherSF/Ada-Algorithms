--  Buzens_Algorithm — Ada 2023 educational package for Wikipedia
--  "Buzen's algorithm" / convolution method for closed queueing networks:
--  efficient computation of Gordon–Newell normalizing constants G(0)..G(N)
--  and derived marginal probabilities / means (Buzen 1971/1973;
--  Gordon & Newell 1967).
--  Input X_i are relative visit ratios / loadings solving the traffic
--  equations μ_j X_j = Σ_i μ_i X_i p_ij.

pragma Ada_2022;

package Buzens_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 12: adequate for moderate N with careful test products.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Stations  : constant Positive := 64;
   Max_Customers : constant Natural  := 256;

   subtype Station_Count  is Natural  range 0 .. Max_Stations;
   subtype Station_Index  is Positive range 1 .. Max_Stations;
   subtype Customer_Count is Natural  range 0 .. Max_Customers;

   --  Relative loadings / visit-scaled service demands X[1..M] > 0.
   type X_Vector is array (Station_Index range <>) of Real;

   --  Normalizing constants indexed by customer count: G(0) .. G(N).
   type G_Vector is array (Natural range <>) of Real;

   --  Full pedagogical table g(n, m) for n = 0 .. N, m in X'Range.
   type G_Matrix is array (Natural range <>, Station_Index range <>) of Real;

   --  Customer counts per station (composition of N).
   type Customer_Vector is array (Station_Index range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;  -- unused alias slot (style parity)
   Singular_System     : exception renames Degenerate_Geometry;
   Capacity_Exceeded   : exception;
   Empty_Sample        : exception;  -- unused; style parity with sibling pkgs

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Power (Base : Real; Exp : Natural) return Real
     with Global => null;
   --  Base^Exp via iterative multiply (Exp = 0 => 1).

   ---------------------------------------------------------------------------
   -- Loadings from service rates (educational traffic helpers)
   ---------------------------------------------------------------------------

   function Make_X_Cyclic (Service_Rates : X_Vector) return X_Vector
     with Pre => Service_Rates'Length >= 1,
          Global => null;
   --  Two-center / cyclic balanced visits: X_i = 1 / μ_i.
   --  Raises Invalid_Argument if any μ_i <= 0.

   function Make_X_From_Rates
     (Service_Rates : X_Vector;
      Visit_Ratios  : X_Vector) return X_Vector
     with Pre => Service_Rates'Length >= 1
       and then Visit_Ratios'Length = Service_Rates'Length
       and then Visit_Ratios'First = Service_Rates'First,
          Global => null;
   --  X_i = Visit_Ratios(i) / Service_Rates(i).
   --  Raises Invalid_Argument if any rate <= 0 or visit ratio <= 0.

   ---------------------------------------------------------------------------
   -- Buzen convolution: G(0) .. G(N)
   ---------------------------------------------------------------------------

   function Compute_G (X : X_Vector; N : Natural) return G_Vector
     with Pre => X'Length >= 1 and then N <= Max_Customers,
          Global => null,
          Post => Compute_G'Result'First = 0
            and then Compute_G'Result'Last = N;
   --  In-place column convolution (Wikipedia Pascal). Raises
   --  Invalid_Argument if X empty or any X(i) <= 0; Capacity_Exceeded
   --  if N > Max_Customers.

   function Compute_G_Matrix (X : X_Vector; N : Natural) return G_Matrix
     with Pre => X'Length >= 1 and then N <= Max_Customers,
          Global => null,
          Post => Compute_G_Matrix'Result'First (1) = 0
            and then Compute_G_Matrix'Result'Last (1) = N
            and then Compute_G_Matrix'Result'First (2) = X'First
            and then Compute_G_Matrix'Result'Last (2) = X'Last;
   --  Full g(n,m) = g(n,m-1) + X_m * g(n-1,m) with g(0,*)=1,
   --  g(n, first) = X_first^n. Last column equals Compute_G.

   ---------------------------------------------------------------------------
   -- Marginals and means (Buzen / Wikipedia)
   ---------------------------------------------------------------------------

   function Prob_Ni_At_Least
     (X_i : Real;
      K   : Natural;
      G   : G_Vector) return Real
     with Pre => X_i > 0.0
       and then G'First = 0
       and then G'Length >= 1
       and then K <= G'Last,
          Global => null;
   --  P(n_i ≥ k) = X_i^k * G(N-k) / G(N). Raises Invalid_Argument if
   --  G(N) <= 0 or X_i <= 0.

   function Prob_Ni_Equals
     (X_i : Real;
      K   : Natural;
      G   : G_Vector) return Real
     with Pre => X_i > 0.0
       and then G'First = 0
       and then G'Length >= 1
       and then K <= G'Last,
          Global => null;
   --  P(n_i = k) via Wikipedia formulas (k < N and k = N cases).

   function Expected_Ni (X_i : Real; G : G_Vector) return Real
     with Pre => X_i > 0.0
       and then G'First = 0
       and then G'Length >= 1,
          Global => null;
   --  E[n_i] = Σ_{k=1}^N X_i^k * G(N-k) / G(N).

   function Station_Utilization (X_i : Real; G : G_Vector) return Real
     with Pre => X_i > 0.0
       and then G'First = 0
       and then G'Length >= 1,
          Global => null;
   --  U_i = X_i * G(N-1)/G(N) for load-independent servers (N≥1);
   --  returns 0 when N = 0. Textbook identity for single-server FCFS/PS/LCFS.

   function State_Probability
     (N_Vec : Customer_Vector;
      X     : X_Vector;
      G_N   : Real) return Real
     with Pre => N_Vec'Length >= 1
       and then X'Length = N_Vec'Length
       and then X'First = N_Vec'First
       and then G_N > 0.0,
          Global => null;
   --  P(n) = (Π_i X_i^{n_i}) / G(N) for a state with Σ n_i = N
   --  (caller responsibility). Raises Invalid_Argument on bad X.

end Buzens_Algorithm;
