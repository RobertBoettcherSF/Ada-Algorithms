--  =========================================================================
--  Package: Quantum_Annealing
--  Description: Implements Quantum Annealing algorithms for combinatorial
--               optimization (Ising spin glass model / QUBO), including
--               adiabatic evolution, transverse field heuristic annealing,
--               and various scheduling strategies (Linear, Exponential, Diabatic).
--  =========================================================================

package Quantum_Annealing is

   type Spin is range -1 .. 1;
   type Spin_Index is range 1 .. 32;
   type Spin_Array is array (Spin_Index range <>) of Spin;

   type Coupling_Value is new Float;
   type Field_Value is new Float;
   type Energy_Value is new Float;
   type Step_Count is range 1 .. 100_000;
   type Probability_Value is new Float range 0.0 .. 1.0;

   type Coupling_Matrix is array (Spin_Index range <>, Spin_Index range <>) of Coupling_Value;
   type External_Field_Array is array (Spin_Index range <>) of Field_Value;

   type Schedule_Kind is (Linear, Exponential, Diabatic);

   type Annealing_Config is record
      Steps         : Step_Count;
      Initial_Field : Field_Value;
      Final_Field   : Field_Value;
      Schedule      : Schedule_Kind;
   end record;

   -- Exceptions
   Invalid_Problem_Size      : exception;
   Invalid_Schedule          : exception;
   Matrix_Dimension_Mismatch : exception;

   -- Computes the classical Ising energy (Hamiltonian) for a given spin configuration.
   function Compute_Ising_Energy
     (Spins     : Spin_Array;
      Couplings : Coupling_Matrix;
      Fields    : External_Field_Array) return Energy_Value
      with Pre  => Spins'Length > 0
                and then Couplings'Length(1) = Spins'Length
                and then Couplings'Length(2) = Spins'Length
                and then Fields'Length = Spins'Length;

   -- Adiabatic Quantum Annealing (Exact Schrödinger state vector evolution for small systems N <= 6)
   procedure Adiabatic_Quantum_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Config       : in Annealing_Config;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
      with Pre  => Couplings'Length(1) > 0
                and then Couplings'Length(1) = Couplings'Length(2)
                and then Fields'Length = Couplings'Length(1)
                and then Couplings'Length(1) <= 6;

   -- Transverse Field Simulated Annealing (Heuristic Monte Carlo with quantum tunneling for larger systems)
   procedure Transverse_Field_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Config       : in Annealing_Config;
      Seed         : in Natural;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
      with Pre  => Couplings'Length(1) > 0
                and then Couplings'Length(1) = Couplings'Length(2)
                and then Fields'Length = Couplings'Length(1);

   -- Linear Schedule Annealing Variant
   procedure Linear_Schedule_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Steps        : in Step_Count;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
      with Pre  => Couplings'Length(1) > 0
                and then Couplings'Length(1) = Couplings'Length(2)
                and then Fields'Length = Couplings'Length(1);

   -- Exponential Schedule Annealing Variant
   procedure Exponential_Schedule_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Steps        : in Step_Count;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
      with Pre  => Couplings'Length(1) > 0
                and then Couplings'Length(1) = Couplings'Length(2)
                and then Fields'Length = Couplings'Length(1);

   -- Diabatic Quantum Annealing Variant (accelerated transition to exploit tunneling through barriers)
   procedure Diabatic_Quantum_Anneal
     (Couplings    : in Coupling_Matrix;
      Fields       : in External_Field_Array;
      Config       : in Annealing_Config;
      Best_Spins   : out Spin_Array;
      Final_Energy : out Energy_Value)
      with Pre  => Couplings'Length(1) > 0
                and then Couplings'Length(1) = Couplings'Length(2)
                and then Fields'Length = Couplings'Length(1);

end Quantum_Annealing;
