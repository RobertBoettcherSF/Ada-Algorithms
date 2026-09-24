pragma SPARK_Mode (On);

package body Nth_Ugly_Number is
   function Is_Ugly (N : Number) return Boolean is
      Value : Natural := N;
   begin
      for Step in 1 .. 10 loop
         pragma Loop_Invariant (Value >= 1);
         if Value mod 2 = 0 then
            Value := Value / 2;
         end if;
         if Value mod 3 = 0 then
            Value := Value / 3;
         end if;
         if Value mod 5 = 0 then
            Value := Value / 5;
         end if;
      end loop;
      return Value = 1;
   end Is_Ugly;

   function Compute (N : Input) return Number is
      Seen   : Natural range 0 .. 32 := 0;
      Answer : Number := 1;
   begin
      for Candidate in Number loop
         pragma Loop_Invariant (Seen <= N);
         exit when Seen = N;
         if Is_Ugly (Candidate) and then Seen < N then
            Seen := Seen + 1;
            Answer := Candidate;
         end if;
      end loop;
      return Answer;
   end Compute;
end Nth_Ugly_Number;
