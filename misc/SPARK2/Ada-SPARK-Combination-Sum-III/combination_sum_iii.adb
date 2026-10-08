pragma Ada_2022;

package body Combination_Sum_III with SPARK_Mode => On is
   function Feasible (K : Count; N : Target) return Boolean is
      Minimum : constant Natural := K * (K + 1) / 2;
      Maximum : constant Natural := K * (19 - K) / 2;
   begin
      return N >= Minimum and then N <= Maximum;
   end Feasible;

   function Count_Choices (K : Count; N : Target) return Natural is
      --  every subset of the digits 1 .. 9: bit D - 1 of Mask set = digit D chosen
      Found : Natural range 0 .. 512 := 0;
      Bits : Natural range 0 .. 511;
      Size : Natural range 0 .. 9;
      Sum : Natural range 0 .. 45;
   begin
      for Mask in 0 .. 511 loop
         pragma Loop_Invariant (Found <= Mask);
         Bits := Mask;
         Size := 0;
         Sum := 0;
         for D in 1 .. 9 loop
            pragma Loop_Invariant (Size <= D - 1 and then Sum <= (D - 1) * D / 2);
            if Bits mod 2 = 1 then
               Size := Size + 1;
               Sum := Sum + D;
            end if;
            Bits := Bits / 2;
         end loop;
         if Size = K and then Sum = N then
            Found := Found + 1;
         end if;
      end loop;
      return Found;
   end Count_Choices;
end Combination_Sum_III;
