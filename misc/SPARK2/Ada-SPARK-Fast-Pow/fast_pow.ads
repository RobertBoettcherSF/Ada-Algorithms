pragma SPARK_Mode (On);

--  Fast modular power: B ** E mod M for any Natural B and E and any
--  Positive M, by left-to-right square-and-multiply over the 31 bits of E.
--  Every intermediate is below M <= 2 ** 31 - 1, so each product is below
--  2 ** 62 and fits Long_Long_Integer.
package Fast_Pow is
   type Pow_Result is record
      Value : Natural;
      Steps : Natural;   --  squaring steps: one per bit of E, 31 in all
   end record;

   --  One step: X ** 2 * (B if Odd) mod M.
   function Sq_Mul (X, B : Natural; Odd : Boolean; M : Positive) return Natural is
     (Natural (((Long_Long_Integer (X) * Long_Long_Integer (X)) mod Long_Long_Integer (M)
                * (if Odd then Long_Long_Integer (B mod M) else 1)) mod Long_Long_Integer (M)))
   with Pre => X < M, Post => Sq_Mul'Result < M;

   --  The definition by halving: B ** 0 = 1 and
   --  B ** E = (B ** (E / 2)) ** 2 * (B if E is odd).
   function Mod_Pow (B, E : Natural; M : Positive) return Natural
   with
     Ghost,
     Post               => Mod_Pow'Result < M,
     Subprogram_Variant => (Decreases => E);

   --  2 ** I; the proof checks the doubling steps it uses.
   subtype Bit_Count is Natural range 0 .. 31;
   function Pow2 (I : Bit_Count) return Long_Long_Integer is
     (case I is
        when 0 => 1, when 1 => 2, when 2 => 4, when 3 => 8, when 4 => 16,
        when 5 => 32, when 6 => 64, when 7 => 128, when 8 => 256,
        when 9 => 512, when 10 => 1_024, when 11 => 2_048, when 12 => 4_096,
        when 13 => 8_192, when 14 => 16_384, when 15 => 32_768,
        when 16 => 65_536, when 17 => 131_072, when 18 => 262_144,
        when 19 => 524_288, when 20 => 1_048_576, when 21 => 2_097_152,
        when 22 => 4_194_304, when 23 => 8_388_608, when 24 => 16_777_216,
        when 25 => 33_554_432, when 26 => 67_108_864, when 27 => 134_217_728,
        when 28 => 268_435_456, when 29 => 536_870_912,
        when 30 => 1_073_741_824, when 31 => 2_147_483_648)
   with Ghost;

   function Power_Mod (B, E : Natural; M : Positive) return Pow_Result
   with
     Global => null,
     Post   => Power_Mod'Result.Value = Mod_Pow (B, E, M) and then Power_Mod'Result.Steps = 31;

private
   function Mod_Pow (B, E : Natural; M : Positive) return Natural is
     (if E = 0 then 1 mod M else Sq_Mul (Mod_Pow (B, E / 2, M), B, E mod 2 = 1, M));
end Fast_Pow;
