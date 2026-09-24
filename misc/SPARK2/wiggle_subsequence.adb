pragma Ada_2022;
pragma SPARK_Mode (On);
package body Wiggle_Subsequence is
   function Wiggle_Length (First, Second, Third : Value) return Length is
   begin
      if (First < Second and then Second > Third)
        or else (First > Second and then Second < Third) then
         return 3;
      elsif First /= Second or else Second /= Third then
         return 2;
      else
         return 1;
      end if;
   end Wiggle_Length;
end Wiggle_Subsequence;
