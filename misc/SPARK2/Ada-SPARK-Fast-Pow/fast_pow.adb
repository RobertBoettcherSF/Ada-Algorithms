pragma SPARK_Mode (On);

package body Fast_Pow is
   function Power_Mod (B, E : Natural; M : Positive) return Pow_Result is
      W      : Natural := 2 ** 30;   --  the weight of bit I
      Prefix : Natural := 0;         --  the bits of E above bit I
      Rest   : Natural := E;         --  the bits of E from bit I down
      R      : Natural := 1 mod M;   --  B ** Prefix mod M
      Steps  : Natural := 0;
      Bit    : Natural;
   begin
      for I in reverse 0 .. 30 loop
         pragma Loop_Invariant
           (Long_Long_Integer (W) = Pow2 (I)
            and then Long_Long_Integer (E) = Long_Long_Integer (Prefix) * (2 * Pow2 (I)) + Long_Long_Integer (Rest)
            and then Long_Long_Integer (Rest) < 2 * Pow2 (I)
            and then R = Mod_Pow (B, Prefix, M)
            and then Steps = 30 - I);
         Bit := (if Rest >= W then 1 else 0);
         Rest := Rest - Bit * W;
         Prefix := 2 * Prefix + Bit;
         R := Sq_Mul (R, B, Bit = 1, M);
         Steps := Steps + 1;
         if I > 0 then
            W := W / 2;
         end if;
      end loop;
      return (Value => R, Steps => Steps);
   end Power_Mod;
end Fast_Pow;
