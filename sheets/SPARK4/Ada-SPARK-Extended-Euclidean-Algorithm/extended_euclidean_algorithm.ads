--  Extended_Euclidean_Algorithm — Ada/SPARK Level 4 educational package
--  for the extended Euclidean algorithm: gcd(a,b) together with Bézout
--  coefficients x,y such that
--
--      a·x + b·y = gcd(a,b)
--
--  Also: quotients a/g and b/g, coprimality, and modular multiplicative
--  inverse when gcd(a,m)=1 (Pre replaces Invalid_Argument).
--
--  SPARK port of Ada-Extended-Euclidean-Algorithm: nonnegative educational
--  operands (0 .. Max_Educational), signed Integer Bézout coefficients,
--  no exceptions. Package name Extended_Euclidean_Algorithm (files
--  extended_euclidean_algorithm.*) for SPARK-series consistency; non-SPARK
--  sibling keeps the shorter Extended_Euclidean name.
--
--  Reference: https://en.wikipedia.org/wiki/Extended_Euclidean_algorithm
--  Note: Wikipedia spelling is Euclidean (not the common misspelling
--  "Euclidian"). Closest SPARK sibling: Ada-SPARK-Euclidean-Algorithm.

package Extended_Euclidean_Algorithm
  with SPARK_Mode => On
is

   --  Soft classroom bound. Small enough that classroom products fit in
   --  Integer; Bézout identity is checked by tests (not claimed in Post).
   Max_Educational : constant Integer := 1_000;

   subtype Educational is Integer range 0 .. Max_Educational;

   Coeff_Bound : constant Integer := Max_Educational + 1;

   type Extended_Gcd_Result is record
      Gcd : Educational := 0;
      X   : Integer     := 0;
      Y   : Integer     := 0;
   end record;

   type Quotient_Pair is record
      A_Over_G : Educational := 0;
      B_Over_G : Educational := 0;
   end record;

   function Divides (D, N : Educational) return Boolean is
     (D /= 0 and then N rem D = 0)
   with Global => null;

   function Mod_Nonneg (A, M : Educational) return Educational
     with
       Global => null,
       Pre    => M > 0,
       Post   => Mod_Nonneg'Result < M
                 and then Mod_Nonneg'Result = A rem M;

   function Is_Modular_Inverse
     (A, Inv, M : Educational) return Boolean
     with
       Global => null,
       Pre    => M > 1 and then Inv < M;

   function Verify_Bezout
     (A, B : Educational; R : Extended_Gcd_Result) return Boolean
     with
       Global => null,
       Pre    =>
         R.X in -Coeff_Bound .. Coeff_Bound
         and then R.Y in -Coeff_Bound .. Coeff_Bound;

   function Gcd (A, B : Educational) return Educational
     with
       Global => null,
       Post   =>
         (if A = 0 and then B = 0 then
            Gcd'Result = 0
          elsif B = 0 then
            Gcd'Result = A
          elsif A = 0 then
            Gcd'Result = B
          else
            Gcd'Result > 0);

   --  Iterative extended Euclidean (Wikipedia). Post: Gcd zero-cases /
   --  positivity only. Bézout A·X+B·Y=Gcd is checked by tests.
   function Extended_Gcd (A, B : Educational) return Extended_Gcd_Result
     with
       Global => null,
       Post   =>
         (if A = 0 and then B = 0 then
            Extended_Gcd'Result.Gcd = 0
          elsif B = 0 then
            Extended_Gcd'Result.Gcd = A
          elsif A = 0 then
            Extended_Gcd'Result.Gcd = B
          else
            Extended_Gcd'Result.Gcd > 0);

   function Are_Coprime (A, B : Educational) return Boolean
     with
       Global => null,
       Post   => Are_Coprime'Result = (Gcd (A, B) = 1);

   function Quotients_By_Gcd (A, B : Educational) return Quotient_Pair
     with
       Global => null,
       Post   =>
         (if Gcd (A, B) = 0 then
            Quotients_By_Gcd'Result.A_Over_G = 0
            and then Quotients_By_Gcd'Result.B_Over_G = 0
          else
            Quotients_By_Gcd'Result.A_Over_G = A / Gcd (A, B)
            and then Quotients_By_Gcd'Result.B_Over_G = B / Gcd (A, B));

   function Modular_Inverse (A, M : Educational) return Educational
     with
       Global => null,
       Pre    => M > 1 and then A < M and then Are_Coprime (A, M),
       Post   => Modular_Inverse'Result < M;

end Extended_Euclidean_Algorithm;
