pragma SPARK_Mode (On);

package body Mean_Variance is
   function Mean (Samples : Sample_Array) return Integer is
      Total : Integer range -10 .. 10 := 0;
   begin
      for I in Index loop
         Total := Total + Samples (I);
      end loop;
      return Total / Sample_Count;
   end Mean;

   function Variance (Samples : Sample_Array) return Integer is
      Average : constant Integer := Mean (Samples);
      Total   : Integer range 0 .. 80 := 0;
      Diff    : Integer range -4 .. 4;
      Square  : Integer range 0 .. 16;
   begin
      for I in Index loop
         Diff := Samples (I) - Average;
         Square := Diff * Diff;
         pragma Assert (Total + Square <= 80);
         Total := Total + Square;
      end loop;
      return Total / Sample_Count;
   end Variance;
end Mean_Variance;
