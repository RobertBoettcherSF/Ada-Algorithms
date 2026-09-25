--  Version: 0.001
--  Modular_Arithmetic.Ring: the ring Z/NZ for a fixed modulus N, as a
--  generic package.  Residue is 0 .. N-1; all operations delegate to the
--  proved operations of Modular_Arithmetic and carry the same contracts.
--
--     package Z97 is new Modular_Arithmetic.Ring (97);
--     X : Z97.Residue := Z97.Mul (Z97.Reduce (1234), 5);

pragma Ada_2022;

generic
   Modulus : Modulus_Type;
package Modular_Arithmetic.Ring
  with SPARK_Mode => On, Pure
is

   N : constant Modulus_Type := Modulus;
   --  The modulus of this instance.

   subtype Residue is Natural_64 range 0 .. Modulus - 1;

   --  PROOF-LATER: Importance 5/10, Urgency 4/10, SPARK3
   function Reduce (A : Natural_64) return Residue is
     (Modular_Arithmetic.Reduce (A, Modulus))
     with Global => null,
          Post => Wide (Reduce'Result) = Wide (A) mod Wide (Modulus);

   --  PROOF-LATER: Importance 5/10, Urgency 4/10, SPARK3
   function Add (A, B : Residue) return Residue is
     (Add_Mod (A, B, Modulus))
     with Global => null,
          Post => Wide (Add'Result) = (Wide (A) + Wide (B)) mod Wide (Modulus);

   --  PROOF-LATER: Importance 5/10, Urgency 4/10, SPARK3
   function Sub (A, B : Residue) return Residue is
     (Sub_Mod (A, B, Modulus))
     with Global => null,
          Post => Wide (Sub'Result) = (Wide (A) - Wide (B)) mod Wide (Modulus);

   --  PROOF-LATER: Importance 5/10, Urgency 4/10, SPARK3
   function Neg (A : Residue) return Residue is
     (Neg_Mod (A, Modulus))
     with Global => null,
          Post => Wide (Neg'Result) = (-Wide (A)) mod Wide (Modulus);

   --  PROOF-LATER: Importance 6/10, Urgency 4/10, SPARK3
   function Mul (A, B : Residue) return Residue is
     (Mul_Mod (A, B, Modulus))
     with Global => null,
          Post => Wide (Mul'Result) = (Wide (A) * Wide (B)) mod Wide (Modulus);

   --  PROOF-LATER: Importance 6/10, Urgency 4/10, SPARK3
   function Pow (A : Residue; E : Natural_64) return Residue is
     (Pow_Mod (A, E, Modulus))
     with Global => null,
          Post => Pow'Result = Pow_Spec (A, E, Modulus);

   --  PROOF-LATER: Importance 4/10, Urgency 3/10, SPARK3
   function Is_Unit (A : Residue) return Boolean is
     (Modular_Arithmetic.Is_Unit (A, Modulus))
     with Global => null;

   --  PROOF-LATER: Importance 6/10, Urgency 4/10, SPARK3
   function Inverse (A : Residue) return Residue is
     (Modular_Arithmetic.Inverse (A, Modulus))
     with Global => null,
          Pre  => Is_Unit (A),
          Post => (Wide (A) * Wide (Inverse'Result)) mod Wide (Modulus) = 1;

   --  PROOF-LATER: Importance 4/10, Urgency 3/10, SPARK3
   function Orbit_Length (A : Residue) return Natural_64 is
     (Modular_Arithmetic.Orbit_Length (A, Modulus))
     with Global => null,
          Post => Orbit_Length'Result in 1 .. Modulus;

   --  PROOF-LATER: Importance 4/10, Urgency 3/10, SPARK3
   function Order (A : Residue) return Natural_64 is
     (Multiplicative_Order (A, Modulus))
     with Global => null,
          Post => Order'Result < Modulus;

end Modular_Arithmetic.Ring;
