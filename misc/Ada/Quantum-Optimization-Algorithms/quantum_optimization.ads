-------------------------------------------------------------------------------
-- Package: Quantum_Optimization                                             --
-- Description: Ada 2023 implementation of Quantum Optimization Algorithms   --
--              based on ISO/IEC 8652:2023 standard.                         --
-------------------------------------------------------------------------------

package Quantum_Optimization is

   -- Domain-specific types with strict typing enforcement
   type Cost_Value is delta 0.001 digits 12 range -1_000_000.0 .. 1_000_000.0;
   type Parameter_Angle is digits 8 range -6.2831853 .. 6.2831853; -- Radians within [-2pi, 2pi]
   type Iteration_Count is range 0 .. 10_000;
   type Qubit_Index is range 1 .. 64;

   type Angle_Array is array (Positive range <>) of Parameter_Angle;
   type Cost_Array is array (Positive range <>) of Cost_Value;

   -- Named exceptions for domain error handling
   Invalid_Parameter    : exception;
   Constraint_Violation : exception;
   Optimization_Error   : exception;

   -- Variant 1: Standard Quantum Approximate Optimization Algorithm (QAOA)
   -- Evaluates combinatorial optimization cost using alternating cost and mixer Hamiltonians.
   function Run_QAOA 
     (Layers     : Positive;
      Betas      : Angle_Array;
      Gammas     : Angle_Array;
      Max_Iter   : Iteration_Count) return Cost_Value
   with
      Pre  => Betas'Length = Layers and then Gammas'Length = Layers and then Max_Iter > 0,
      Post => Run_QAOA'Result >= -1_000_000.0;

   -- Variant 2: Multi-Angle QAOA
   -- Extends standard QAOA by allowing distinct angle parameters per qubit across layers.
   function Run_Multi_Angle_QAOA
     (Layers     : Positive;
      Num_Qubits : Qubit_Index;
      Angles     : Angle_Array;
      Max_Iter   : Iteration_Count) return Cost_Value
   with
      Pre  => Angles'Length >= Layers * Positive (Num_Qubits) and then Max_Iter > 0,
      Post => Run_Multi_Angle_QAOA'Result >= -1_000_000.0;

   -- Variant 3: Quantum Alternating Operator Ansatz
   -- Solves constrained optimization problems with custom alternating mixer operators.
   function Run_Alternating_Operator_Ansatz
     (Layers         : Positive;
      Betas          : Angle_Array;
      Gammas         : Angle_Array;
      Has_Constraint : Boolean) return Cost_Value
   with
      Pre  => Betas'Length = Layers and then Gammas'Length = Layers,
      Post => Run_Alternating_Operator_Ansatz'Result >= -1_000_000.0;

   -- Variant 4: Quantum Annealing Simulation
   -- Simulates transverse field annealing and quantum tunneling through potential energy barriers.
   function Run_Quantum_Annealing
     (Initial_Field    : Parameter_Angle;
      Cooling_Steps    : Positive;
      Tunneling_Factor : Parameter_Angle) return Cost_Value
   with
      Pre  => Initial_Field > 0.0 and then Cooling_Steps > 0 and then Tunneling_Factor >= 0.0,
      Post => Run_Quantum_Annealing'Result <= 0.0;

   -- Variant 5: Variational Quantum Eigensolver (VQE)
   -- Hybrid quantum-classical algorithm for estimating ground-state energy of physical systems.
   function Run_VQE
     (Ansatz_Depth : Positive;
      Parameters   : Angle_Array;
      Max_Iter     : Iteration_Count) return Cost_Value
   with
      Pre  => Ansatz_Depth > 0 and then Parameters'Length > 0 and then Max_Iter > 0,
      Post => Run_VQE'Result >= -1_000_000.0;

end Quantum_Optimization;
