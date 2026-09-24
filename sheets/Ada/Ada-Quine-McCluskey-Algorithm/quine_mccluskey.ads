with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Vectors;

package Quine_McCluskey is
   -- Strong typing: Define an array type for minterms and don't-cares
   type Minterm_Array is array (Positive range <>) of Natural;
   Empty_Minterm_Array : constant Minterm_Array (1 .. 0) := (others => 0);

   -- List of string representations of prime implicants (e.g., "10-1", "0-1-")
   package String_Vectors is new Ada.Containers.Indefinite_Vectors 
     (Index_Type => Positive, Element_Type => String);
   subtype Implicant_List is String_Vectors.Vector;

   -- Exceptions for error handling and boundary edge cases
   Invalid_Input_Error : exception;

   -----------------------------------------------------------------------------
   -- Core Variants (As mentioned in Wikipedia)
   -----------------------------------------------------------------------------
   
   -- VARIANT 1: Find all Prime Implicants (Step 1 of the algorithm)
   -- Incorporates "Don't Cares" to maximize grouping sizes.
   function Get_Prime_Implicants 
     (Num_Vars   : Positive; 
      Minterms   : Minterm_Array; 
      Dont_Cares : Minterm_Array := Empty_Minterm_Array) return Implicant_List;

   -- VARIANT 2: Heuristic / Greedy Minimization (Prime Implicant Chart step)
   -- Solves the chart using essential prime implicants and a greedy approach 
   -- for the cyclic core. Faster, but not mathematically guaranteed minimum.
   function Minimize_Greedy 
     (Num_Vars   : Positive; 
      Minterms   : Minterm_Array; 
      Dont_Cares : Minterm_Array := Empty_Minterm_Array) return Implicant_List;

   -- VARIANT 3: Exact Minimization (Petrick's Method Equivalence)
   -- Uses recursive backtracking (exact set cover) to solve the cyclic core.
   -- Guarantees the absolute minimum number of terms to cover the function.
   function Minimize_Exact 
     (Num_Vars   : Positive; 
      Minterms   : Minterm_Array; 
      Dont_Cares : Minterm_Array := Empty_Minterm_Array) return Implicant_List;

   -----------------------------------------------------------------------------
   -- Helper Functions (Exposed for V&V Unit Testing)
   -----------------------------------------------------------------------------
   function Count_Ones (S : String) return Natural;
   function Differs_By_One (S1, S2 : String) return Boolean;
   function Merge (S1, S2 : String) return String;
   function Covers (PI : String; Minterm : Natural) return Boolean;

end Quine_McCluskey;
