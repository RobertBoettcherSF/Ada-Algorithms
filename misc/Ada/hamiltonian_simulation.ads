--  =========================================================================
--  Package: Hamiltonian_Simulation
--  Description: Implements Hamiltonian simulation algorithms for quantum
--               systems based on product formulas (Trotter-Suzuki) and
--               Taylor series expansions, following ISO/IEC 8652:2023 (Ada 2023).
--  =========================================================================

package Hamiltonian_Simulation is

   --  Custom domain types and subtypes
   type Simulation_Time is new Long_Float range 0.0 .. 1_000.0;
   type Step_Count is range 1 .. 1_000_000;
   type Qubit_Index is range 0 .. 3; -- Supporting up to 4 qubits (16 state amplitudes)
   type State_Index is range 0 .. 15;
   subtype Taylor_Order is Positive range 1 .. 10;

   type Complex_Number is record
      Re : Long_Float := 0.0;
      Im : Long_Float := 0.0;
   end record;

   type State_Vector is array (State_Index range <>) of Complex_Number;

   --  Pauli operator types for Hamiltonian terms
   type Pauli_Type is (Identity, Sigma_X, Sigma_Y, Sigma_Z);
   
   type Pauli_Term is record
      Op_Type      : Pauli_Type;
      Coefficient  : Long_Float;
      Target_Qubit : Qubit_Index;
   end record;

   type Term_Array is array (Positive range <>) of Pauli_Term;

   --  Exceptions
   Invalid_Hamiltonian : exception;
   Invalid_Simulation_Parameters : exception;

   --  Validation helper
   function Validate_Terms (Terms : Term_Array; Num_Qubits : Positive) return Boolean
     with Post => Validate_Terms'Result = True or else (raise Invalid_Hamiltonian);

   --  Variant 1: First-Order Product Formula (Trotterization)
   procedure Simulate_Trotter_1st
     (Initial_State : in     State_Vector;
      Terms         : in     Term_Array;
      Time          : in     Simulation_Time;
      Steps         : in     Step_Count;
      Num_Qubits    : in     Positive;
      Final_State   :    out State_Vector)
     with Pre  => Initial_State'Length = 2 ** Num_Qubits
                 and then Terms'Length > 0
                 and then Num_Qubits in 1 .. 4,
          Post => Final_State'Length = Initial_State'Length;

   --  Variant 2: Second-Order Product Formula (Strang Splitting)
   procedure Simulate_Trotter_2nd
     (Initial_State : in     State_Vector;
      Terms         : in     Term_Array;
      Time          : in     Simulation_Time;
      Steps         : in     Step_Count;
      Num_Qubits    : in     Positive;
      Final_State   :    out State_Vector)
     with Pre  => Initial_State'Length = 2 ** Num_Qubits
                 and then Terms'Length > 0
                 and then Num_Qubits in 1 .. 4,
          Post => Final_State'Length = Initial_State'Length;

   --  Variant 3: Truncated Taylor Series Simulation
   procedure Simulate_Taylor
     (Initial_State : in     State_Vector;
      Terms         : in     Term_Array;
      Time          : in     Simulation_Time;
      Order         : in     Taylor_Order;
      Num_Qubits    : in     Positive;
      Final_State   :    out State_Vector)
     with Pre  => Initial_State'Length = 2 ** Num_Qubits
                 and then Terms'Length > 0
                 and then Num_Qubits in 1 .. 4,
          Post => Final_State'Length = Initial_State'Length;

   --  Analytical error estimation helpers
   function Estimate_Trotter_Error
     (Terms : Term_Array; Time : Simulation_Time; Steps : Step_Count; Order : Positive)
      return Long_Float
     with Pre => Terms'Length > 0 and Steps > 0;

end Hamiltonian_Simulation;
