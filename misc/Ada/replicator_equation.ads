-- replicator_equation.ads
-- Specification for the Replicator Equation algorithm and its variants.

package Replicator_Equation is

   -- Strong typing for algorithm-specific data
   type Population_Vector is array (Positive range <>) of Float;
   type Payoff_Matrix is array (Positive range <>, Positive range <>) of Float;

   -- Exceptions for error handling
   Dimension_Mismatch  : exception;
   Invalid_Population  : exception;
   Zero_Average_Fitness : exception;

   -- HELPER FUNCTIONS

   -- Normalizes a population vector so that all frequencies sum to 1.0.
   -- Handles floating point drift.
   function Normalize (Population : Population_Vector) return Population_Vector;

   -- Calculates the linear fitness f_i(x) = (A * x)_i
   function Calculate_Fitness (Population : Population_Vector; Payoff : Payoff_Matrix) return Population_Vector;

   -- Calculates average fitness phi(x) = x^T * A * x
   function Average_Fitness (Population : Population_Vector; Fitness : Population_Vector) return Float;


   -- ALGORITHM VARIANTS

   -- 1. Standard Discrete Replicator Equation
   -- x_i(t+1) = x_i(t) * [f_i(x(t)) / phi(x(t))]
   function Step_Discrete (Population : Population_Vector; Payoff : Payoff_Matrix) return Population_Vector;

   -- 2. Standard Continuous Replicator Equation (using Euler method integration)
   -- dx_i/dt = x_i(t) * [f_i(x(t)) - phi(x(t))]
   function Step_Continuous (
      Population : Population_Vector; 
      Payoff     : Payoff_Matrix; 
      Delta_T    : Float
   ) return Population_Vector;

   -- 3. Replicator-Mutator Equation (Continuous, Euler integration)
   -- dx_i/dt = Sum_j [ x_j * f_j(x) * Q_ji ] - x_i * phi(x)
   -- Q is the Mutation_Matrix where Q(j,i) is the probability of mutating from j to i.
   function Step_Mutator_Continuous (
      Population      : Population_Vector;
      Payoff          : Payoff_Matrix;
      Mutation_Matrix : Payoff_Matrix;
      Delta_T         : Float
   ) return Population_Vector;

   -- 4. Asymmetric Bipartite Graph Replicator (Discrete, Two-Population)
   -- Pop_A evolves via Payoff_A against Pop_B. Pop_B evolves via Payoff_B against Pop_A.
   procedure Step_Asymmetric_Discrete (
      Population_A : in out Population_Vector;
      Population_B : in out Population_Vector;
      Payoff_A     : in     Payoff_Matrix;
      Payoff_B     : in     Payoff_Matrix
   );

end Replicator_Equation;
