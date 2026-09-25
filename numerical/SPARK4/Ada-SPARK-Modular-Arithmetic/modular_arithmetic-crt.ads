--  Version: 0.001
--  Modular_Arithmetic.CRT: Chinese Remainder Theorem for pairwise coprime
--  moduli (two-modulus form and array form), proved with GNATprove.
--
--  Uniqueness: if the moduli are pairwise coprime, there is exactly one
--  X with 0 <= X < M1 * ... * Mk and X mod Mi = Ri for all i; every other
--  solution differs from it by a multiple of the product.  For two moduli
--  this is proved as Lemma_Crt2_Unique; the functions below return that
--  unique smallest solution.

pragma Ada_2022;

--  See modular_arithmetic.ads: work-around for GNAT 12 (variants are
--  proved by GNATprove, not checked at run time).
pragma Assertion_Policy (Subprogram_Variant => Ignore);

package Modular_Arithmetic.CRT
  with SPARK_Mode => On, Pure
is

   --  PROOF-LATER: Importance 9/10, Urgency 4/10, SPARK4
   function Crt2
     (R1 : Natural_64; M1 : Modulus_Type;
      R2 : Natural_64; M2 : Modulus_Type) return Natural_64
     with Global => null,
          Pre  => R1 < M1 and then R2 < M2
                  and then Gcd (M1, M2) = 1
                  and then Wide (M1) * Wide (M2) <= Max_Modulus,
          Post => Wide (Crt2'Result) < Wide (M1) * Wide (M2)
                  and then Crt2'Result mod M1 = R1
                  and then Crt2'Result mod M2 = R2;
   --  REQ-013: the X in 0 .. M1*M2-1 with X = R1 (mod M1), X = R2 (mod M2).

   --  PROOF-LATER: Importance 7/10, Urgency 3/10, SPARK4
   procedure Lemma_Crt2_Unique (X, Y : Natural_64; M1, M2 : Modulus_Type)
     with Ghost,
          Global => null,
          Pre  => Gcd (M1, M2) = 1
                  and then Wide (M1) * Wide (M2) <= Max_Modulus
                  and then Wide (X) < Wide (M1) * Wide (M2)
                  and then Wide (Y) < Wide (M1) * Wide (M2)
                  and then X mod M1 = Y mod M1
                  and then X mod M2 = Y mod M2,
          Post => X = Y;
   --  REQ-015: the two-modulus solution below M1*M2 is unique.

   type Congruence is record
      R : Natural_64;      --  residue
      M : Modulus_Type;    --  modulus
   end record;

   Max_Congruences : constant := 64;
   --  More than 62 moduli >= 2 cannot have a product below 2**63.

   subtype Congruence_Index is Positive range 1 .. Max_Congruences;

   type Congruence_Array is
     array (Congruence_Index range <>) of Congruence;

   --  PROOF-LATER: Importance 3/10, Urgency 1/10, Ada
   function Sat_Mul (P : Wide; M : Modulus_Type) return Wide is
     (if P > Max_Modulus / Wide (M) then Max_Modulus + 1 else P * Wide (M))
     with Global => null,
          Pre  => P in 1 .. Max_Modulus + 1;
   --  P * M, saturated at Max_Modulus + 1 ("too big").

   --  PROOF-LATER: Importance 4/10, Urgency 2/10, SPARK3
   function Prefix_Product (C : Congruence_Array; K : Natural) return Wide
   is (if K < C'First then 1
       else Sat_Mul (Prefix_Product (C, K - 1), C (K).M))
     with Global => null,
          Pre  => K <= C'Last,
          Post => Prefix_Product'Result in 1 .. Max_Modulus + 1,
          Subprogram_Variant => (Decreases => K);
   --  M(First) * ... * M(K), saturated at Max_Modulus + 1.

   --  PROOF-LATER: Importance 3/10, Urgency 1/10, Ada
   function Product_Fits (C : Congruence_Array) return Boolean is
     (for all K in C'Range => Prefix_Product (C, K) <= Max_Modulus)
     with Global => null;

   --  PROOF-LATER: Importance 3/10, Urgency 1/10, Ada
   function Pairwise_Coprime (C : Congruence_Array) return Boolean is
     (for all I in C'Range =>
        (for all J in C'Range =>
           (if I /= J then Gcd (C (I).M, C (J).M) = 1)))
     with Global => null;

   --  PROOF-LATER: Importance 9/10, Urgency 5/10, SPARK4
   function Crt_Array (C : Congruence_Array) return Natural_64
     with Global => null,
          Pre  => C'Length >= 1
                  and then (for all I in C'Range => C (I).R < C (I).M)
                  and then Pairwise_Coprime (C)
                  and then Product_Fits (C),
          Post => Wide (Crt_Array'Result) < Prefix_Product (C, C'Last)
                  and then (for all I in C'Range =>
                              Crt_Array'Result mod C (I).M = C (I).R);
   --  REQ-014: array form, folding Crt2 over the congruences.

end Modular_Arithmetic.CRT;
