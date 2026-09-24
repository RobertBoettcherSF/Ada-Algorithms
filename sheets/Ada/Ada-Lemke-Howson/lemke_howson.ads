-- lemke_howson.ads
-- Specification for the Lemke-Howson algorithm for finding a Nash Equilibrium.

package Lemke_Howson is

   -- Strong typing: Define a custom floating-point type for precise calculations
   type Real is digits 15;

   -- Vectors and Matrices for game payoffs and strategy probabilities
   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;

   -- Equilibrium record with discriminants to support dynamically sized games
   type Equilibrium (M, N : Positive) is record
      P1 : Vector (1 .. M);
      P2 : Vector (1 .. N);
   end record;

   -- Custom exception for boundary and validation cases
   Invalid_Input : exception;
   Unbounded_Problem : exception;

   -- Variant Support: The primary variant in Lemke-Howson is the choice of the 
   -- initial label to drop. Different dropped labels yield different equilibria.
   -- Dropped_Label must be in the range 1 .. M + N.
   function Solve
     (A, B          : Matrix;
      Dropped_Label : Positive := 1) return Equilibrium;

end Lemke_Howson;
