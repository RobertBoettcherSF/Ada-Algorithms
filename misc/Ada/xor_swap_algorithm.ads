with Interfaces; use Interfaces;

package Xor_Swap_Algorithm is

   -- Use Unsigned_32 to allow bitwise XOR operations (Ada's standard Integer does not support bitwise natively)
   type Data_Type is new Unsigned_32;
   type Data_Array is array (Natural range <>) of Data_Type;

   -- =========================================================================
   -- VARIANT 1: Standard Preemptive/Direct XOR Swap
   -- =========================================================================
   -- Standard XOR swap algorithm for two distinct variables.
   -- WARNING: If used on pointers/references to the same memory location, 
   -- it will zero out the value (Aliasing problem).
   procedure Swap (X, Y : in out Data_Type);

   -- =========================================================================
   -- VARIANT 2: Safe XOR Swap (Aliasing-Aware)
   -- =========================================================================
   -- This variant specifically checks for memory/index aliasing before swapping.
   -- It resolves the primary vulnerability of XOR swaps mentioned in the literature.
   procedure Swap_Elements (Arr : in out Data_Array; I, J : Natural);

   -- =========================================================================
   -- VARIANT 3: Array Reversal using XOR Swap
   -- =========================================================================
   -- Reverses an array in place using the XOR swap algorithm.
   -- Safely handles odd-length arrays by utilizing the Safe XOR Swap variant 
   -- to prevent zeroing out the middle element.
   procedure Reverse_Array (Arr : in out Data_Array);

end Xor_Swap_Algorithm;
