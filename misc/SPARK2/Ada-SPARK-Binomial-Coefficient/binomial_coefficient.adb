pragma Ada_2022;
pragma SPARK_Mode (On);

package body Binomial_Coefficient is

   function Choose (N, K : Input) return Result is
      --  Row (J) = C (I, J) after row I; entries beyond I stay 0.
      Row : Row_Type := [0 => 1, others => 0];
   begin
      for I in 1 .. N loop
         pragma Loop_Invariant (Row = Pascal_Row (I - 1));
         declare
            Prev : constant Row_Type := Row with Ghost;
            Cur  : constant Row_Type := Pascal_Row (I) with Ghost;
         begin
            pragma Assert (Cur = Next (Prev, I));
            --  Right to left, so Row (J - 1) still holds row I - 1.
            for J in reverse 1 .. I loop
               pragma Loop_Invariant
                 (for all M in Input => Row (M) = (if M > J then Cur (M) else Prev (M)));
               Row (J) := Row (J) + Row (J - 1);
            end loop;
            pragma Assert (for all M in Input => Row (M) = Cur (M));
         end;
      end loop;
      return Row (K);
   end Choose;
end Binomial_Coefficient;
