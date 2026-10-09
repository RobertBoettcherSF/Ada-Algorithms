pragma Ada_2022;

package body Guess_Number_Higher_Or_Lower with SPARK_Mode => On is

   --  2 ** K - 1 for K in 0 .. 6.
   function Full (K : Probe_Count) return Natural is
     (case K is
        when 0 => 0, when 1 => 1, when 2 => 3, when 3 => 7,
        when 4 => 15, when 5 => 31, when 6 => 63)
   with Ghost;

   function Guess_Number (N : Number; Secret : Number) return Result is
      Lo     : Number := 1;
      Hi     : Number := N;
      Mid    : Number;
      Probes : Probe_Count := 0;
   begin
      loop
         --  Secret is in Lo .. Hi, and that range has at most
         --  2 ** (guesses left) - 1 numbers.
         pragma Loop_Invariant (Secret in Lo .. Hi);
         pragma Loop_Invariant (Probes < Max_Probes (N));
         pragma Loop_Invariant (Hi - Lo + 1 <= Full (Max_Probes (N) - Probes));
         pragma Loop_Variant (Decreases => Hi - Lo);
         Mid := Lo + (Hi - Lo) / 2;
         Probes := Probes + 1;
         case Probe (Secret, Mid) is
            when Equal =>
               return (Answer => Mid, Probes => Probes);
            when Lower =>
               Hi := Mid - 1;
            when Higher =>
               Lo := Mid + 1;
         end case;
      end loop;
   end Guess_Number;
end Guess_Number_Higher_Or_Lower;
