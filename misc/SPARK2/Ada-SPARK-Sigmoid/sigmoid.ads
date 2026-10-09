pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  The logistic function as a whole percentage:
--  Percent (X_Milli) = round half up of 100 / (1 + e ** (-x)) for
--  x = X_Milli / 1000, for every Integer X_Milli.
--
--  For x >= 0 the value is computed exactly from S, the Taylor
--  polynomial of e ** x with Terms + 1 terms, as a fraction Num / Den
--  of Big_Integers (Horner's rule: S = 1 + x/1 (1 + x/2 (... (1 + x/Terms)))):
--  100 / (1 + 1 / S) rounded half up is (201 Num + Den) / (2 (Num + Den))
--  in integer division.  For x < 0, Percent is 100 - Percent (-x)
--  (the logistic function is symmetric and a tie at a half is
--  impossible, since e ** x is irrational for x /= 0).
--
--  Accuracy: S < e ** x, and the error is below 2 x ** 41 / 41!, under
--  1e-20 for 0 <= x <= ln 199 = 5.2933.  The answer is 100 exactly when
--  S >= 199, and S grows with x, so every x past ln 199 gives 100, as
--  the true value does.  Inside, no value of 100 / (1 + e ** (-x)) on
--  the 1/1000 grid is closer than 1.67e-5 to a rounding boundary, so the
--  truncation never changes the result (tested against Long_Float exp
--  on every X_Milli in -8000 .. 8000; the values themselves are not
--  provable here, SPARK has no e: tests/SOURCES.txt).
package Sigmoid with SPARK_Mode => On is

   subtype Probability is Integer range 0 .. 100;

   --  Degree of the Taylor polynomial.
   Terms : constant := 40;

   --  Round half up of 100 / (1 + 1 / S (X / 1000)) for X >= 0.
   function Right_Half (X : Big_Integer) return Probability
   with Global => null,
        Pre    => X >= 0,
        Post   => Right_Half'Result >= 50 and then (if X = 0 then Right_Half'Result = 50);

   function Percent (X_Milli : Integer) return Probability is
     (if X_Milli >= 0 then Right_Half (To_Big_Integer (X_Milli))
      else 100 - Right_Half (-To_Big_Integer (X_Milli)))
   with Global => null,
        Post   => (if X_Milli >= 0 then Percent'Result >= 50 else Percent'Result <= 50);

   --  Symmetry: Percent (-x) = 100 - Percent (x).
   procedure Lemma_Symmetry (X_Milli : Integer)
   with Ghost, Global => null,
        Pre  => X_Milli > Integer'First,
        Post => Percent (X_Milli) + Percent (-X_Milli) = 100;

   --  The old whole-number interface: X in whole units, X * 1000 must fit
   --  Integer (the limit of the range).
   subtype Input is Integer range -2_147_483 .. 2_147_483;
   function Evaluate (X : Input) return Probability is (Percent (X * 1000))
   with Global => null;

end Sigmoid;
