--  Ant_Colony_Optimization — Ada 2023 educational package for Wikipedia
--  "Ant colony optimization" (Dorigo 1992; Ant System, Dorigo et al. 1996):
--  population-based metaheuristic for combinatorial graphs. Artificial ants
--  construct tours probabilistically using pheromone τ and heuristic η=1/d;
--  trails evaporate and receive deposits Δτ = Q/L. This package implements
--  classical Ant System (AS) for the travelling salesman problem (n ≤ 12).
--  Primary source:
--  https://en.wikipedia.org/wiki/Ant_colony_optimization_algorithms
--  Siblings: Ada-Bees-Algorithm / Ada-Particle-Swarm / Ada-Tabu-Search
--  (README links).

pragma Ada_2022;

package Ant_Colony_Optimization
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Cities : constant := 12;
   Max_Ants  : constant := 64;

   subtype City_Count is Positive range 2 .. Max_Cities;
   subtype City_Index is Positive range 1 .. Max_Cities;
   subtype Ant_Count is Positive range 1 .. Max_Ants;

   type Tour is array (City_Index range <>) of City_Index;

   type Dist_Matrix is
     array (City_Index range <>, City_Index range <>) of Non_Negative;

   type Pheromone_Matrix is
     array (City_Index range <>, City_Index range <>) of Non_Negative;

   type Heuristic_Matrix is
     array (City_Index range <>, City_Index range <>) of Non_Negative;

   type Point2 is record
      X : Real := 0.0;
      Y : Real := 0.0;
   end record;

   type Point2_Array is array (City_Index range <>) of Point2;

   type Tour_Array is array (Ant_Count range <>) of Tour (1 .. Max_Cities);
   type Length_Array is array (Ant_Count range <>) of Non_Negative;

   --  Alpha           : pheromone exponent α
   --  Beta            : heuristic exponent β
   --  Rho             : evaporation rate ρ in [0,1]
   --  Q               : pheromone deposit strength (Δτ = Q/L)
   --  N_Ants         : colony size m
   --  Max_Iterations  : outer AS iteration budget (0 → construct once)
   --  Seed            : LCG seed for reproducibility
   --  Best_Only       : if True, only iteration-best ant deposits
   --  Initial_Tau     : uniform initial pheromone τ0
   type Config is record
      Alpha          : Non_Negative  := 1.0;
      Beta           : Non_Negative  := 2.0;
      Rho            : Unit_Interval := 0.5;
      Q              : Non_Negative  := 100.0;
      N_Ants        : Ant_Count     := 10;
      Max_Iterations : Natural       := 100;
      Seed           : Natural       := 1;
      Best_Only      : Boolean       := False;
      Initial_Tau    : Non_Negative  := 1.0;
   end record;

   type Result is record
      Best_Tour   : Tour (1 .. Max_Cities) := [others => 1];
      N           : City_Count             := 2;
      Best_Length : Non_Negative           := 0.0;
      Iterations  : Natural                := 0;
      Ants_Used   : Natural                := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   --  Large η used when d = 0 (self / degenerate edge); avoids 1/0.
   Big_Heuristic : constant Non_Negative := 1.0E6;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Config
     (Alpha          : Non_Negative  := 1.0;
      Beta           : Non_Negative  := 2.0;
      Rho            : Unit_Interval := 0.5;
      Q              : Non_Negative  := 100.0;
      N_Ants        : Ant_Count     := 10;
      Max_Iterations : Natural       := 100;
      Seed           : Natural       := 1;
      Best_Only      : Boolean       := False;
      Initial_Tau    : Non_Negative  := 1.0) return Config
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible AS
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;
   --  Uniform on [Lo, Hi].

   function Next_Index
     (State : in out RNG_State; Lo, Hi : City_Index) return City_Index
     with Pre => Lo <= Hi, Global => null;
   --  Uniform integer index in [Lo, Hi].

   ---------------------------------------------------------------------------
   -- Distance / heuristic / tour utilities
   ---------------------------------------------------------------------------

   function Euclidean (A, B : Point2) return Non_Negative
     with Global => null;

   function Euclidean_Matrix (Pts : Point2_Array) return Dist_Matrix
     with Pre => Pts'Length >= 2 and then Pts'Length <= Max_Cities,
          Global => null;
   --  Symmetric Euclidean distance matrix; diagonal 0.

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative
     with Pre => T'First = D'First (1)
            and then T'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2),
          Global => null;
   --  Closed tour length (includes return edge T'Last → T'First).

   function Is_Valid_Tour (T : Tour) return Boolean
     with Global => null;
   --  True iff T is a permutation of T'First .. T'Last.

   function Build_Heuristic (D : Dist_Matrix) return Heuristic_Matrix
     with Pre => D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then D'Length (1) >= 2
            and then D'Length (1) <= Max_Cities,
          Global => null;
   --  η_ij = 1/d_ij for d_ij > 0; Big_Heuristic on diagonal / zero edges.

   function Edge_Weight
     (Tau_IJ : Non_Negative;
      Eta_IJ : Non_Negative;
      Alpha  : Non_Negative;
      Beta   : Non_Negative) return Non_Negative
     with Global => null;
   --  τ^α · η^β (0^0 treated as 1 for educational stability).

   function Transition_Probability
     (From        : City_Index;
      To          : City_Index;
      Tau         : Pheromone_Matrix;
      Eta         : Heuristic_Matrix;
      Visited     : Tour;
      Visit_Count : Natural;
      Alpha       : Non_Negative;
      Beta        : Non_Negative) return Unit_Interval
     with Pre => Tau'First (1) = Tau'First (2)
            and then Tau'Last (1) = Tau'Last (2)
            and then Eta'First (1) = Tau'First (1)
            and then Eta'Last (1) = Tau'Last (1)
            and then Eta'First (2) = Tau'First (2)
            and then Eta'Last (2) = Tau'Last (2)
            and then From in Tau'Range (1)
            and then To in Tau'Range (1)
            and then Visited'First = Tau'First (1)
            and then Visited'Last = Tau'Last (1)
            and then Visit_Count <= Natural (Tau'Length (1)),
          Global => null;
   --  p_From→To among cities not in Visited (1 .. Visit_Count). Returns 0 if
   --  To is already visited or the total weight of allowed cities is 0.

   ---------------------------------------------------------------------------
   -- Pheromone core: Init_Pheromone / Construct_Tour / Update_Pheromone /
   -- Colony_Update / Solve_TSP
   ---------------------------------------------------------------------------

   procedure Init_Pheromone
     (Tau : out Pheromone_Matrix; Initial : Non_Negative := 1.0)
     with Pre => Tau'First (1) = Tau'First (2)
            and then Tau'Last (1) = Tau'Last (2)
            and then Tau'Length (1) >= 2
            and then Tau'Length (1) <= Max_Cities,
          Global => null;
   --  Fill τ with Initial; set diagonal to 0.

   procedure Construct_Tour
     (T     : out Tour;
      Tau   : Pheromone_Matrix;
      Eta   : Heuristic_Matrix;
      Alpha : Non_Negative;
      Beta  : Non_Negative;
      State : in out RNG_State)
     with Pre => T'First = Tau'First (1)
            and then T'Last = Tau'Last (1)
            and then Tau'First (1) = Tau'First (2)
            and then Tau'Last (1) = Tau'Last (2)
            and then Eta'First (1) = Tau'First (1)
            and then Eta'Last (1) = Tau'Last (1)
            and then Eta'First (2) = Tau'First (2)
            and then Eta'Last (2) = Tau'Last (2)
            and then T'Length >= 2
            and then T'Length <= Max_Cities,
          Global => null;
   --  One ant: random start city, then repeatedly pick next unused city with
   --  probability ∝ τ^α η^β. Writes a full valid tour into T.

   procedure Update_Pheromone
     (Tau     : in out Pheromone_Matrix;
      T       : Tour;
      Length  : Non_Negative;
      Rho     : Unit_Interval;
      Q       : Non_Negative;
      Deposit : Boolean := True)
     with Pre => Tau'First (1) = Tau'First (2)
            and then Tau'Last (1) = Tau'Last (2)
            and then T'First = Tau'First (1)
            and then T'Last = Tau'Last (1),
          Global => null;
   --  Evaporate τ ← (1−ρ)τ, then if Deposit and Length > 0 add Q/Length on
   --  each edge of T (both directions). Single-tour convenience wrapper.

   procedure Colony_Update
     (Tau       : in out Pheromone_Matrix;
      N         : City_Count;
      Tours     : Tour_Array;
      Lengths   : Length_Array;
      Used      : Ant_Count;
      Rho       : Unit_Interval;
      Q         : Non_Negative;
      Best_Only : Boolean;
      Best_Idx  : Ant_Count)
     with Pre => Tau'First (1) = Tau'First (2)
            and then Tau'Last (1) = Tau'Last (2)
            and then Natural (Tau'Length (1)) = Natural (N)
            and then Tours'First = 1
            and then Lengths'First = 1
            and then Used in Tours'Range
            and then Used in Lengths'Range
            and then Best_Idx in 1 .. Used,
          Global => null;
   --  Evaporate once; deposit Δτ = Q/L on edges of every ant (or only Best_Idx
   --  when Best_Only). Symmetric deposit on (i,j) and (j,i).

   function Solve_TSP
     (D   : Dist_Matrix;
      Cfg : Config) return Result
     with Pre => D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then D'Length (1) >= 2
            and then D'Length (1) <= Max_Cities,
          Global => null;
   --  Classical Ant System on distance matrix D. Returns best tour + length
   --  over Max_Iterations colony constructions.

end Ant_Colony_Optimization;
