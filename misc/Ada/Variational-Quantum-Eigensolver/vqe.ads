-- vqe.ads
with Ada.Exceptions;

package VQE is
   
   -- Strong typing for scientific floating point calculations
   type Float_Type is digits 15;
   
   -- Custom type for algorithm parameters (ansatz angles/weights)
   type Vector is array (Positive range <>) of Float_Type;
   
   -- VQE Ansatz variants described in literature
   type Ansatz_Type is 
     (Hardware_Efficient, 
      Unitary_Coupled_Cluster, 
      QAOA);
      
   -- Classical optimization algorithms
   type Optimizer_Type is 
     (Gradient_Descent, 
      SPSA); -- Simultaneous Perturbation Stochastic Approximation

   -- Hamiltonian structure for the observable
   type Hamiltonian is record
      Base_Energy : Float_Type;
      Complexity  : Positive;
   end record;

   -- Exceptions for edge cases
   Dimension_Error     : exception;
   Optimization_Failed : exception;

   -- Subprogram declarations
   
   -- Evaluates the expectation value <psi(theta) | H | psi(theta)>
   -- Simulates the quantum circuit execution.
   function Expectation_Value
     (H      : Hamiltonian;
      Ansatz : Ansatz_Type;
      Params : Vector) return Float_Type;

   -- Classical optimizer loop
   function Optimize
     (H             : Hamiltonian;
      Ansatz        : Ansatz_Type;
      Opt_Method    : Optimizer_Type;
      Initial_Guess : Vector;
      Learning_Rate : Float_Type := 0.05;
      Tolerance     : Float_Type := 1.0e-5;
      Max_Iter      : Positive   := 1000) return Vector;

private
   
   -- Helper functions for optimization
   function Calculate_Gradient
     (H      : Hamiltonian;
      Ansatz : Ansatz_Type;
      Params : Vector) return Vector;
      
   function Calculate_SPSA_Gradient
     (H      : Hamiltonian;
      Ansatz : Ansatz_Type;
      Params : Vector) return Vector;

end VQE;
