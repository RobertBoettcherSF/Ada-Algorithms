pragma Ada_2022;
package body Squares_Of_A_Sorted_Array with SPARK_Mode => On is
   --  X <= Y implies X * X <= Y * Y for magnitudes
   procedure Lemma_Square_Mono (X, Y : Natural)
     with Ghost, Global => null, Pre => X <= Y and then Y <= 32, Post => X * X <= Y * Y
   is
   begin
      pragma Assert (X * X <= X * Y);
      pragma Assert (X * Y <= Y * Y);
   end Lemma_Square_Mono;

   function Squares (A : Sorted_Array) return Square_Array is
      Result : Square_Array := [others => 0];
      L : Index := 1;          --  A (L .. R) is still to be placed
      R : Index := Length;
      Mag : Natural range 0 .. 32;             --  magnitude placed now
      Last_Mag : Natural range 0 .. 32 := 32;  --  magnitude placed at Pos + 1
   begin
      for Pos in reverse Index loop
         pragma Loop_Invariant (R - L = Pos - 1);
         pragma Loop_Invariant (for all K in L .. R => abs A (K) <= Last_Mag);
         pragma Loop_Invariant (Pos = Length or else Result (Pos + 1) = Last_Mag * Last_Mag);
         pragma Loop_Invariant (for all K in Pos + 1 .. Length - 1 => Result (K) <= Result (K + 1));
         if abs A (L) > abs A (R) then
            Mag := abs A (L);
            if L < R then
               L := L + 1;
            end if;
         else
            Mag := abs A (R);
            if L < R then
               R := R - 1;
            end if;
         end if;
         pragma Assert (Mag <= Last_Mag);
         Lemma_Square_Mono (Mag, Last_Mag);
         Result (Pos) := Mag * Mag;
         Last_Mag := Mag;
      end loop;
      return Result;
   end Squares;
end Squares_Of_A_Sorted_Array;
