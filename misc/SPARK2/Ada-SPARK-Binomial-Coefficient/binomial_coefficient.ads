pragma Ada_2022;
pragma SPARK_Mode (On);

--  Binomial coefficients C (N, K) for N <= 30 by Pascal's rule, one row
--  at a time. C (N, K) <= 2 ** N <= 2 ** 30, so every value fits Result.
package Binomial_Coefficient is
   subtype Input is Natural range 0 .. 30;
   subtype Result is Natural range 0 .. 2 ** 30;

   --  2 ** N. The tests regenerate every entry by doubling.
   function Pow2 (N : Input) return Result is
     (case N is
        when 0 => 1, when 1 => 2, when 2 => 4, when 3 => 8, when 4 => 16,
        when 5 => 32, when 6 => 64, when 7 => 128, when 8 => 256,
        when 9 => 512, when 10 => 1_024, when 11 => 2_048, when 12 => 4_096,
        when 13 => 8_192, when 14 => 16_384, when 15 => 32_768,
        when 16 => 65_536, when 17 => 131_072, when 18 => 262_144,
        when 19 => 524_288, when 20 => 1_048_576, when 21 => 2_097_152,
        when 22 => 4_194_304, when 23 => 8_388_608, when 24 => 16_777_216,
        when 25 => 33_554_432, when 26 => 67_108_864, when 27 => 134_217_728,
        when 28 => 268_435_456, when 29 => 536_870_912,
        when 30 => 1_073_741_824)
   with Ghost;

   type Row_Type is array (Input) of Result;

   --  Pascal's rule: row N from row N - 1, entry J = P (J) + P (J - 1).
   function Next (P : Row_Type; N : Input) return Row_Type
   with
     Ghost,
     Pre => N >= 1 and then (for all J in Input => P (J) <= Pow2 (N - 1));

   --  Row N of Pascal's triangle, C (N, J) for J in Input (0 beyond N).
   --  Each row is built once, so contract checks at run time stay cheap.
   function Pascal_Row (N : Input) return Row_Type
   with
     Ghost,
     Post               =>
       (for all J in Input =>
          Pascal_Row'Result (J) <= Pow2 (N)
          and then (if J > N then Pascal_Row'Result (J) = 0)),
     Subprogram_Variant => (Decreases => N);

   function Choose (N, K : Input) return Result
   with
     Global => null,
     Post   => Choose'Result = Pascal_Row (N) (K);

private
   function Next (P : Row_Type; N : Input) return Row_Type is
     ([for J in Input => (if J = 0 then 1 else P (J) + P (J - 1))]);

   function Pascal_Row (N : Input) return Row_Type is
     (if N = 0 then [0 => 1, others => 0] else Next (Pascal_Row (N - 1), N));
end Binomial_Coefficient;
