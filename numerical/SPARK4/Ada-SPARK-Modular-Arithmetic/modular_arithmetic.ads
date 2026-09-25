--  Version: 0.001
--  Modular_Arithmetic: proved arithmetic on residues 0 .. N-1 for any
--  modulus 2 <= N <= 2**63-1 (SPARK, GNATprove).  Every operation is
--  related to the mathematical "mod" through its postcondition; exact
--  intermediates use the 128-bit type Wide, so nothing can overflow.
--  See README.md for the requirement IDs (REQ-xxx) quoted below.

pragma Ada_2022;

--  GNAT 12 rejects Subprogram_Variant on recursive expression functions
--  when assertions are enabled (-gnata); variants are proved by GNATprove
--  (termination), so run-time checking of them is switched off.
pragma Assertion_Policy (Subprogram_Variant => Ignore);

package Modular_Arithmetic
  with SPARK_Mode => On, Pure
is

   type Wide is range -(2**127) .. 2**127 - 1;
   --  Double-width (128-bit) signed integer used for exact intermediate
   --  values (products of two 63-bit numbers, Bezout coefficients).

   Max_Modulus : constant := 2**63 - 1;

   subtype Natural_64 is Long_Long_Integer range 0 .. Max_Modulus;
   subtype Modulus_Type is Long_Long_Integer range 2 .. Max_Modulus;

   subtype Wide_Nat is Wide range 0 .. Max_Modulus;
   subtype Wide_Pos is Wide range 1 .. Max_Modulus;
   subtype Mag63 is Wide range -Max_Modulus .. Max_Modulus;
   subtype Mag126 is Wide range -(2**126 - 1) .. 2**126 - 1;
   --  Any product of two Mag63 values is a Mag126 value, and any sum of
   --  two Mag126 values fits in Wide.

   ------------------------------------------------------------------
   --  Ring operations (REQ-001 .. REQ-005)
   ------------------------------------------------------------------

   --  PROOF-LATER: Importance 5/10, Urgency 2/10, SPARK4
   function Reduce (A : Natural_64; N : Modulus_Type) return Natural_64 is
     (A mod N)
     with Global => null,
          Post => Reduce'Result < N
                  and then Wide (Reduce'Result) = Wide (A) mod Wide (N);
   --  A mod N (REQ-001).

   --  PROOF-LATER: Importance 8/10, Urgency 3/10, SPARK4
   function Add_Mod (A, B : Natural_64; N : Modulus_Type) return Natural_64
     with Global => null,
          Pre  => A < N and then B < N,
          Post => Add_Mod'Result < N
                  and then Wide (Add_Mod'Result)
                           = (Wide (A) + Wide (B)) mod Wide (N);
   --  (A + B) mod N without a wider type (REQ-002).

   --  PROOF-LATER: Importance 8/10, Urgency 3/10, SPARK4
   function Sub_Mod (A, B : Natural_64; N : Modulus_Type) return Natural_64
     with Global => null,
          Pre  => A < N and then B < N,
          Post => Sub_Mod'Result < N
                  and then Wide (Sub_Mod'Result)
                           = (Wide (A) - Wide (B)) mod Wide (N);
   --  (A - B) mod N, always in 0 .. N-1 (REQ-003).

   --  PROOF-LATER: Importance 6/10, Urgency 2/10, SPARK4
   function Neg_Mod (A : Natural_64; N : Modulus_Type) return Natural_64
     with Global => null,
          Pre  => A < N,
          Post => Neg_Mod'Result < N
                  and then Wide (Neg_Mod'Result) = (-Wide (A)) mod Wide (N);
   --  (-A) mod N (REQ-004).

   --  PROOF-LATER: Importance 10/10, Urgency 4/10, SPARK4
   function Mul_Mod (A, B : Natural_64; N : Modulus_Type) return Natural_64
     with Global => null,
          Pre  => A < N and then B < N,
          Post => Mul_Mod'Result < N
                  and then Wide (Mul_Mod'Result)
                           = (Wide (A) * Wide (B)) mod Wide (N);
   --  (A * B) mod N via an exact 128-bit product (REQ-005).

   ------------------------------------------------------------------
   --  Exponentiation (REQ-006)
   ------------------------------------------------------------------

   function Pow_Spec (B, E : Natural_64; N : Modulus_Type) return Natural_64
   is (if E = 0 then 1
       else
         (declare
            H : constant Natural_64 := Pow_Spec (B, E / 2, N);
            S : constant Natural_64 := Mul_Mod (H, H, N);
          begin
            (if E mod 2 = 0 then S else Mul_Mod (S, B, N))))
     with Ghost,
          Global => null,
          Pre  => B < N,
          Post => Pow_Spec'Result < N,
          Subprogram_Variant => (Decreases => E);
   --  Specification of B**E mod N: B**0 = 1, B**(2h) = (B**h)**2,
   --  B**(2h+1) = (B**h)**2 * B.  Lemma_Pow_Succ proves that this is the
   --  ordinary power (B**(E+1) = B**E * B).

   procedure Lemma_Pow_Succ (B, E : Natural_64; N : Modulus_Type)
     with Ghost,
          Global => null,
          Pre  => B < N and then E < Max_Modulus,
          Post => Pow_Spec (B, E + 1, N) = Mul_Mod (Pow_Spec (B, E, N), B, N),
          Subprogram_Variant => (Decreases => E);

   --  PROOF-LATER: Importance 9/10, Urgency 4/10, SPARK4
   function Pow_Mod (B, E : Natural_64; N : Modulus_Type) return Natural_64
     with Global => null,
          Pre  => B < N,
          Post => Pow_Mod'Result < N
                  and then Pow_Mod'Result = Pow_Spec (B, E, N),
          Subprogram_Variant => (Decreases => E);
   --  B**E mod N by square-and-multiply (recursion depth <= 63).

   ------------------------------------------------------------------
   --  Gcd, Bezout, inverse (REQ-007 .. REQ-010)
   ------------------------------------------------------------------

   type Bezout is record
      G    : Natural_64;
      X, Y : Mag63;
   end record;

   function Max1 (A : Natural_64) return Wide is
     (if A = 0 then 1 else Wide (A));

   --  PROOF-LATER: Importance 9/10, Urgency 4/10, SPARK4
   function Extended_Gcd (A, B : Natural_64) return Bezout
     with Global => null,
          Post => (declare
                     R : constant Bezout := Extended_Gcd'Result;
                   begin
                     (if A = 0 and then B = 0 then R.G = 0
                      else R.G > 0
                           and then Wide (A) mod Wide (R.G) = 0
                           and then Wide (B) mod Wide (R.G) = 0
                           and then R.G <= Natural_64'Max (A, B))
                     and then Wide (A) * R.X + Wide (B) * R.Y = Wide (R.G)
                     and then abs R.X <= Max1 (B)
                     and then abs R.Y <= Max1 (A)
                     and then ((R.X >= 0 and then R.Y <= 0)
                               or else (R.X <= 0 and then R.Y >= 0)));
   --  G = gcd (A, B) with Bezout coefficients A*X + B*Y = G (REQ-007).
   --  G divides A and B, and every common divisor of A and B divides
   --  A*X + B*Y = G, so G is the greatest common divisor.

   --  PROOF-LATER: Importance 7/10, Urgency 2/10, SPARK4
   function Gcd (A, B : Natural_64) return Natural_64 is
     (Extended_Gcd (A, B).G)
     with Global => null;
   --  REQ-008.

   --  PROOF-LATER: Importance 6/10, Urgency 2/10, SPARK4
   function Is_Unit (A : Natural_64; N : Modulus_Type) return Boolean is
     (Gcd (A, N) = 1)
     with Global => null;
   --  A is invertible modulo N (REQ-009).

   --  PROOF-LATER: Importance 10/10, Urgency 4/10, SPARK4
   function Inverse (A : Natural_64; N : Modulus_Type) return Natural_64
     with Global => null,
          Pre  => Is_Unit (A, N),
          Post => Inverse'Result < N
                  and then (Wide (A) * Wide (Inverse'Result)) mod Wide (N)
                           = 1;
   --  Multiplicative inverse via extended Euclid (REQ-010).

   ------------------------------------------------------------------
   --  Orbits and orders (REQ-011, REQ-012)
   ------------------------------------------------------------------

   --  PROOF-LATER: Importance 5/10, Urgency 2/10, SPARK3
   function Orbit_Length (A : Natural_64; N : Modulus_Type) return Natural_64
     with Global => null,
          Post => Orbit_Length'Result in 1 .. N
                  and then Wide (Orbit_Length'Result) * Wide (Gcd (A, N))
                           = Wide (N)
                  and then (Wide (Orbit_Length'Result) * Wide (A))
                           mod Wide (N) = 0;
   --  Number of distinct values in 0, A, 2A, 3A, ... (mod N), which is
   --  N / gcd (A, N) (REQ-011).

   --  PROOF-LATER: Importance 5/10, Urgency 2/10, SPARK3
   function Multiplicative_Order
     (A : Natural_64; N : Modulus_Type) return Natural_64
     with Global => null,
          Pre  => A < N,
          Post => Multiplicative_Order'Result < N
                  and then
                  (if Multiplicative_Order'Result > 0 then
                     Pow_Spec (A, Multiplicative_Order'Result, N) = 1
                     and then (for all J in 1 .. Multiplicative_Order'Result - 1
                               => Pow_Spec (A, J, N) /= 1)
                   else
                     (for all J in 1 .. N - 1 => Pow_Spec (A, J, N) /= 1));
   --  Smallest K >= 1 with A**K = 1 (mod N); 0 if there is none, which
   --  happens exactly when A is not a unit.  Linear search: O(order)
   --  multiplications, meant for small moduli (REQ-012).

end Modular_Arithmetic;
