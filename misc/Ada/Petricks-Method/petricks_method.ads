with Interfaces;

package Petricks_Method is
   pragma Preelaborate;

   -- Maximum number of Prime Implicants supported to allow efficient 64-bit mask operations
   Max_Prime_Implicants : constant := 64;

   type Prime_Implicant_ID is new Positive range 1 .. Max_Prime_Implicants;

   -- Array of Prime Implicants (e.g., used to construct clauses or inspect solutions)
   type PI_Array is array (Positive range <>) of Prime_Implicant_ID;

   -- A subset of Prime Implicants representing a valid cover (a solution).
   -- Bounded up to Max_Prime_Implicants to avoid unconstrained array complexities.
   type Solution is record
      Count : Natural range 0 .. Max_Prime_Implicants := 0;
      PIs   : PI_Array (1 .. Max_Prime_Implicants) := [others => 1];
   end record;

   type Solution_List is array (Positive range <>) of Solution;

   -- Represents a single column in the prime implicant chart (a Sum of PIs).
   type Clause is private;
   type Clause_List is array (Positive range <>) of Clause;

   -- Map for associating a cost (e.g., number of literals) with each Prime Implicant.
   type Cost_Map is array (Prime_Implicant_ID range <>) of Natural;

   -- Exceptions
   Empty_Chart_Error      : exception;
   Empty_Clause_Error     : exception;
   Unsolvable_Chart_Error : exception;
   Missing_Cost_Error     : exception;

   -- Clause Construction
   function Empty_Clause return Clause;
   function Add (C : Clause; PI : Prime_Implicant_ID) return Clause
     with Post => C /= Add'Result; -- Simplistic check to satisfy contract usage
     
   function Create_Clause (PIs : PI_Array) return Clause
     with Pre => PIs'Length > 0;

   -----------------------------------------------------------------------------
   -- Core Algorithm: Petrick's Method
   -----------------------------------------------------------------------------
   -- Expands the Product-of-Sums (Chart) into a Sum-of-Products and returns
   -- ALL non-dominated (minimal) combinations of Prime Implicants.
   function Multiply_And_Simplify (Chart : Clause_List) return Solution_List
     with Pre => Chart'Length > 0;

   -----------------------------------------------------------------------------
   -- Variant 1: Minimum Terms
   -----------------------------------------------------------------------------
   -- Filters the full simplified expression to return only the solutions 
   -- that use the absolute minimum number of Prime Implicants.
   function Minimum_Terms (Chart : Clause_List) return Solution_List
     with Pre => Chart'Length > 0;

   -----------------------------------------------------------------------------
   -- Variant 2: Minimum Cost Terms
   -----------------------------------------------------------------------------
   -- Filters the full simplified expression to return only the solutions 
   -- that yield the lowest total cost based on the provided Cost_Map.
   function Minimum_Cost_Terms (Chart : Clause_List; Costs : Cost_Map) return Solution_List
     with Pre => Chart'Length > 0;

private
   -- We encode a Clause (Sum of PIs) as a 64-bit unsigned integer bitmask.
   -- Bit 0 represents PI 1, Bit 1 represents PI 2, etc.
   type Clause is record
      Mask : Interfaces.Unsigned_64 := 0;
   end record;
end Petricks_Method;
