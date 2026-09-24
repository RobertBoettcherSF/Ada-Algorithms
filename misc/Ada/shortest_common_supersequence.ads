-- shortest_common_supersequence.ads
--
-- Description:
-- Implementation of the Shortest Common Supersequence (SCS) algorithm 
-- as described on Wikipedia.
-- 
-- Variants Implemented:
-- 1. Exact Dynamic Programming SCS length and string construction for 2 sequences.
-- 2. Greedy Iterative Approximation for k-sequences (NP-hard approximation).

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Shortest_Common_Supersequence is

   -- Strong typing for algorithm-specific data structure (array of sequences)
   type Unbounded_String_Array is array (Positive range <>) of Unbounded_String;

   -- Custom Exceptions
   Empty_Array_Error : exception;

   -- =========================================================================
   -- Variant 1: Two Input Sequences (Exact DP approach) O(nm)
   -- =========================================================================
   
   -- Calculates the length of the Shortest Common Supersequence.
   function SCS_Length (X, Y : String) return Natural;

   -- Constructs and returns the actual Shortest Common Supersequence string.
   function SCS_String (X, Y : String) return String;


   -- =========================================================================
   -- Variant 2: Multiple (k) Input Sequences (Approximation)
   -- =========================================================================
   -- Finding SCS for k > 2 sequences is NP-hard. This function implements 
   -- an iterative greedy approximation algorithm that folds the SCS computation
   -- over the sequence array.
   
   function SCS_Multiple (Strings : Unbounded_String_Array) return String;

end Shortest_Common_Supersequence;
