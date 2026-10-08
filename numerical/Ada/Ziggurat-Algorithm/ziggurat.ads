-- ziggurat.ads
-- Ziggurat Algorithm Package Specification
-- Implements rejection sampling for Normal and Exponential distributions.

package Ziggurat is
   -- Strong typing: Define a custom floating-point type for high precision calculations
   type Real is digits 15;

   -- Initializes the precomputed tables and the pseudo-random number generator (PRNG).
   -- This is called automatically during package elaboration, but can be called 
   -- manually to re-seed the determinism.
   procedure Initialize (Seed : Integer := 1);

   -- Variant 1: Generates a normally distributed random number 
   -- (Mean/mu = 0.0, Standard Deviation/sigma = 1.0)
   function Random_Normal return Real;

   -- Variant 2: Generates an exponentially distributed random number 
   -- (Rate/lambda = 1.0)
   function Random_Exponential return Real;

end Ziggurat;
