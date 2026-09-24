--  =========================================================================
--  Package: Quantum_Sort
--  Description: Ada 2023 implementation of Quantum Sorting algorithm variants
--               and models (Comparison, Parallel Network, Frequency, and
--               Space-Bounded) based on quantum algorithmic principles.
--  =========================================================================

package Quantum_Sort is

   type Element_Value is range -10_000 .. 10_000;
   type Index_Type is range 1 .. 10_000;
   type Element_Array is array (Index_Type range <>) of Element_Value;

   --  Exception raised for invalid input parameters or constraints
   Invalid_Input_Size : exception;

   --  Helper function to verify if an array is in non-decreasing order
   function Is_Sorted (Arr : Element_Array) return Boolean;

   --  Variant 1: Quantum Comparison Sort model (Insertion Sort representation)
   procedure Sort_Comparison (Arr : in out Element_Array)
     with Post => Is_Sorted (Arr);

   --  Variant 2: Quantum Parallel Network Sort model (Shell Sort network representation)
   procedure Sort_Parallel_Network (Arr : in out Element_Array)
     with Post => Is_Sorted (Arr);

   --  Variant 3: Quantum Frequency / Distribution Sort model (Selection Sort representation)
   procedure Sort_Frequency (Arr : in out Element_Array)
     with Post => Is_Sorted (Arr);

   --  Variant 4: Space-Bounded Quantum Sort model (Cocktail Shaker Sort representation)
   procedure Sort_Space_Bounded (Arr : in out Element_Array)
     with Post => Is_Sorted (Arr);

end Quantum_Sort;
