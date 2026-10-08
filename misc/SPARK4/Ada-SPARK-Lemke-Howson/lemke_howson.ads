package Lemke_Howson with SPARK_Mode => On is

   --  The maximum number of strategies per player. Bounded to allow static allocation
   --  and robust formal verification in SPARK.
   Max_Strategies : constant := 5;
   
   subtype Strategy_Count is Positive range 1 .. Max_Strategies;

   --  Use a custom high-precision floating point type for solver calculations.
   type Real is new Long_Float;

   type Matrix is array (Strategy_Count range <>, Strategy_Count range <>) of Real;
   type Vector is array (Strategy_Count range <>) of Real;

   --  Labels correspond to the hyperplanes of the two polytopes.
   --  For an M x N game, valid labels are 1 .. M + N.
   subtype Label_Type is Positive range 1 .. 2 * Max_Strategies;

   --  A generic Nash Equilibrium container.
   type Nash_Equilibrium (M, N : Strategy_Count) is record
      P1_Strategy : Vector (1 .. M);
      P2_Strategy : Vector (1 .. N);
   end record;

   --  Finds one Nash equilibrium using the Lemke-Howson algorithm.
   --  A is Player 1's payoff matrix.
   --  B is Player 2's payoff matrix.
   --  M is the number of strategies for Player 1 (Rows).
   --  N is the number of strategies for Player 2 (Columns).
   --
   --  Initial_Drop: The algorithm variant/choice. Dropping different initial labels
   --  allows the algorithm to traverse different paths in the polytope and potentially
   --  find different Nash equilibria in games with multiple equilibria.
   function Find_Equilibrium
     (A : Matrix;
      B : Matrix;
      M : Strategy_Count;
      N : Strategy_Count;
      Initial_Drop : Label_Type := 1) return Nash_Equilibrium
   with
     Global => null,
     Pre =>
       A'First (1) = 1 and then A'Last (1) = M and then
       A'First (2) = 1 and then A'Last (2) = N and then
       B'First (1) = 1 and then B'Last (1) = M and then
       B'First (2) = 1 and then B'Last (2) = N and then
       Initial_Drop <= M + N;

end Lemke_Howson;
