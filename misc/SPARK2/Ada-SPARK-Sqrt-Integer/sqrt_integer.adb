pragma Ada_2022;

package body Sqrt_Integer with SPARK_Mode => On is

   subtype Small is Wide range 0 .. 2 ** 17;

   --  2 ** I for the 16 trial bits (checked by the proof: Bit starts at
   --  2 ** 15, is halved each step and must equal Pow2 (I)).
   function Pow2 (I : Natural) return Small is
     (case I is
        when 0 => 1, when 1 => 2, when 2 => 4, when 3 => 8, when 4 => 16,
        when 5 => 32, when 6 => 64, when 7 => 128, when 8 => 256,
        when 9 => 512, when 10 => 1_024, when 11 => 2_048, when 12 => 4_096,
        when 13 => 8_192, when 14 => 16_384, when others => 32_768)
   with Ghost, Pre => I <= 15;

   function Sqrt (N : Number) return Sqrt_Result is
      R     : Small := 0;          --  bits kept so far
      Bit   : Small := 2 ** 15;    --  the bit tried in this step
      Cand  : Small;
      Steps : Step_Count := 0;
   begin
      for I in reverse 0 .. 15 loop
         --  N < 2 ** 32 = (0 + 2 * 2 ** 15) ** 2 at the start.
         pragma Loop_Invariant (Bit = Pow2 (I));
         pragma Loop_Invariant (R <= 2 ** 16 - 2 * Bit);
         pragma Loop_Invariant (R * R <= Wide (N));
         pragma Loop_Invariant (Wide (N) < (R + 2 * Bit) * (R + 2 * Bit));
         pragma Loop_Invariant (Steps = 15 - I);
         Cand := R + Bit;
         Steps := Steps + 1;
         if Cand * Cand <= Wide (N) then
            R := Cand;               --  N < (R_old + 2 Bit) ** 2 = (R + Bit) ** 2
         end if;
         pragma Assert (Wide (N) < (R + Bit) * (R + Bit));
         if I > 0 then
            pragma Assert (Pow2 (I) = 2 * Pow2 (I - 1));
            Bit := Bit / 2;          --  Bit = 2 * Pow2 (I - 1), so 2 * new Bit = old Bit
         end if;
      end loop;
      --  Now N < (R + 1) ** 2 and R * R <= N <= Natural'Last.
      if R > Wide (Root'Last) then
         pragma Assert (R * R >= R * (Wide (Root'Last) + 1));
         pragma Assert (R * (Wide (Root'Last) + 1) >= (Wide (Root'Last) + 1) * (Wide (Root'Last) + 1));
         pragma Assert (False);
      end if;
      return (Root => Natural (R), Steps => Steps);
   end Sqrt;
end Sqrt_Integer;
