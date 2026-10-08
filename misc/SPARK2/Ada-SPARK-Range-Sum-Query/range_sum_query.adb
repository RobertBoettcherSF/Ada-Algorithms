pragma Ada_2022;
package body Range_Sum_Query with SPARK_Mode => On is
   function Sum (A : Values; Left, Right : Index) return Natural is
      Total : Natural := 0;
   begin
      for I in Left .. Right loop
         pragma Loop_Invariant (Total <= 10 * (I - Left));
         Total := Total + A (I);
      end loop;
      return Total;
   end Sum;
end Range_Sum_Query;
