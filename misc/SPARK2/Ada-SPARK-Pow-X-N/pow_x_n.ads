pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers;
use Ada.Numerics.Big_Numbers.Big_Integers;

--  Integer power X ** N by repeated squaring, for every Integer X and
--  every Natural N. Ok is True exactly when X ** N fits in Integer; then
--  Result is X ** N, otherwise Result is 0.
--
--  The limit is the one of the result type and is decided by the code,
--  not by a range on the inputs: X ** N fits Integer for every N when X is
--  -1, 0 or 1, and for no N >= 32 otherwise (abs X ** N >= 2 ** 32, see
--  Lemma_Big). In between, the code finds the overflow while it squares.
package Pow_X_N with SPARK_Mode => On is

   function Sq (H : Big_Integer) return Big_Integer is (H * H) with Ghost;

   --  X ** N in mathematical integers, by halving N.
   function Pow (X : Big_Integer; N : Natural) return Big_Integer
   with Ghost, Subprogram_Variant => (Decreases => N);
   function Pow (X : Big_Integer; N : Natural) return Big_Integer is
     (if N = 0 then To_Big_Integer (1)
      elsif N mod 2 = 0 then Sq (Pow (X, N / 2))
      else X * Sq (Pow (X, N / 2)));

   function Fits (V : Big_Integer) return Boolean is
     (In_Range (V, To_Big_Integer (Integer'First), To_Big_Integer (Integer'Last)))
   with Ghost;

   --  "X ** N fits in Integer". The short cut for abs X >= 2 and N >= 32
   --  keeps the contract cheap to check at run time; Lemma_Big proves that
   --  it gives the same answer as Fits (Pow (X, N)).
   function Fits_Power (X : Integer; N : Natural) return Boolean is
     (X in -1 .. 1 or else (N <= 31 and then Fits (Pow (To_Big_Integer (X), N))))
   with Ghost;

   procedure Power (X : Integer; N : Natural; Result : out Integer; Ok : out Boolean)
   with
     Global => null,
     Post   => Ok = Fits_Power (X, N)
               and then (if Ok then To_Big_Integer (Result) = Pow (To_Big_Integer (X), N)
                         else Result = 0);

   --  The short cut in Fits_Power is right: for abs X >= 2 and N >= 32,
   --  X ** N does not fit. (Proof only; never called.)
   procedure Lemma_Big (X : Integer; N : Natural)
   with
     Ghost,
     Global => null,
     Pre    => X not in -1 .. 1 and then N >= 32,
     Post   => not Fits (Pow (To_Big_Integer (X), N));

end Pow_X_N;
