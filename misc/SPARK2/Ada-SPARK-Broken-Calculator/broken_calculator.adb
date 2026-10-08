pragma Ada_2022;
pragma SPARK_Mode (On);
package body Broken_Calculator is
   --  Work backwards from Target: halve it when even, otherwise add one, until it is at most
   --  Start; the remaining distance is covered by decrements. Each pass of the loop halves once,
   --  so five passes bring any target <= 32 down to 1.
   function Minimum_Operations (Start, Target : Operand) return Value is
      type Bounds is array (1 .. 5) of Positive;
      Bound : constant Bounds := [16, 8, 4, 2, 1];
      T : Operand := Target;
      Ops : Natural range 0 .. 10 := 0;
   begin
      for H in Bound'Range loop
         exit when T <= Start;
         pragma Assert (T <= (if H = 1 then 32 else Bound (H - 1)));
         if T mod 2 = 1 then
            T := T + 1;
            Ops := Ops + 1;
         end if;
         T := T / 2;
         Ops := Ops + 1;
         pragma Loop_Invariant (T <= Bound (H));
         pragma Loop_Invariant (Ops <= 2 * H);
         pragma Loop_Invariant (2 * T > Start);
      end loop;
      pragma Assert (T <= Start);
      pragma Assert (Ops = 0 or else 2 * T > Start);
      return Ops + (Start - T);
   end Minimum_Operations;
end Broken_Calculator;
