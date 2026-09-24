--  ========================================================================
--  Package: Quantum_Counting
--  Description: Ada 2023 implementation of the Quantum Counting Algorithm
--               and its variants based on Grover's search and QPE (Wikipedia).
--  ========================================================================

with Ada.Numerics;

package Quantum_Counting is

   -- Domain-specific strong types
   type Database_Capacity is range 1 .. 2**30;
   type Precision_Bits is range 1 .. 30;
   type Solution_Count is range 0 .. 2**30;
   type Phase_Radians is digits 15 range 0.0 .. 2.0 * Ada.Numerics.Pi;

   -- Result types for algorithm variants
   type Existence_Status is (Exists_Solutions, No_Solutions, Undetermined);

   type Search_Result is record
      Found       : Boolean;
      Index       : Database_Capacity;
      Iterations  : Natural;
   end record;

   -- Named exceptions for robust error handling
   Invalid_Parameters : exception;
   Estimation_Error   : exception;

   -- Variant 1: Standard Quantum Counting Estimation
   -- Estimates the number of solutions k in a database of size N using t precision bits.
   function Estimate_Solutions
     (N         : Database_Capacity;
      T_Bits    : Precision_Bits;
      Actual_K  : Solution_Count) return Solution_Count
   with
     Pre  => Solution_Count (N) >= Actual_K,
     Post => Estimate_Solutions'Result <= Solution_Count (N),
     Global => null;

   -- Variant 2: Quantum Existence Problem
   -- Determines whether at least one solution exists in the search space.
   function Check_Existence
     (N        : Database_Capacity;
      T_Bits   : Precision_Bits;
      Actual_K : Solution_Count) return Existence_Status
   with
     Pre  => Solution_Count (N) >= Actual_K,
     Global => null;

   -- Variant 3: Grover's Search with Initially Unknown Number of Solutions
   -- Combines quantum counting estimation with Grover search iterations.
   function Search_Unknown_Solutions
     (N        : Database_Capacity;
      T_Bits   : Precision_Bits;
      Actual_K : Solution_Count;
      Target   : Database_Capacity) return Search_Result
   with
     Pre  => Target <= N and then Solution_Count (N) >= Actual_K,
     Global => null;

   -- Helper / Sub-variant: Compute Grover Operator Eigenvalue Phase Theta
   function Compute_Theta
     (N        : Database_Capacity;
      Actual_K : Solution_Count) return Phase_Radians
   with
     Pre  => Solution_Count (N) >= Actual_K and then N > 0,
     Post => Compute_Theta'Result >= 0.0 and then Compute_Theta'Result <= Ada.Numerics.Pi,
     Global => null;

   -- Helper: Validate input parameters
   procedure Validate_Inputs
     (N      : Database_Capacity;
      T_Bits : Precision_Bits)
   with
     Pre  => True,
     Post => True,
     Global => null;

end Quantum_Counting;
