--  Euclidean algorithm — Ada 2023 educational package.
--  Classical gcd via successive remainders (Wikipedia).
--  Primary source:
--  https://en.wikipedia.org/wiki/Euclidean_algorithm
--  Note: sheet title may say "Euclidian"; Wikipedia spelling is Euclidean.
--  Sibling (README only): Ada-Extended-Euclidean-Algorithm — do not `with`.

pragma Ada_2022;

package Euclidean
  with SPARK_Mode => Off
is

   --  Soft classroom bound for demo operands.
   Max_Educational : constant Long_Integer := 1_000_000;

   Invalid_Argument : exception;

   function Abs_LI (N : Long_Integer) return Long_Integer
     with Global => null;

   --  Classical Euclidean gcd; result ≥ 0. Gcd(0, 0) = 0.
   function Gcd (A, B : Long_Integer) return Long_Integer
     with Global => null;

   --  Least common multiple. Lcm(0, 0) = 0; otherwise |A*B|/Gcd(A,B)
   --  with overflow guard for educational sizes (raises Invalid_Argument
   --  if |A| or |B| exceed Max_Educational when both nonzero).
   function Lcm (A, B : Long_Integer) return Long_Integer
     with Global => null;

   --  True iff Gcd(A, B) = 1.
   function Are_Coprime (A, B : Long_Integer) return Boolean
     with Global => null;

   --  Number of division steps (remainder iterations) until r = 0.
   --  Gcd(0,0) counts as 0 steps.
   function Division_Steps (A, B : Long_Integer) return Natural
     with Global => null;

   --  Binary (Stein's) gcd — educational alternate; same result as Gcd.
   function Binary_Gcd (A, B : Long_Integer) return Long_Integer
     with Global => null;

end Euclidean;
