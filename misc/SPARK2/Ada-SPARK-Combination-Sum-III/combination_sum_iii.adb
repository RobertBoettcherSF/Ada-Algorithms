pragma Ada_2022;

package body Combination_Sum_III with SPARK_Mode => On is
   function Feasible (K : Count; N : Target) return Boolean is
      Minimum : constant Natural := K * (K + 1) / 2;
      Maximum : constant Natural := K * (19 - K) / 2;
   begin
      return N >= Minimum and then N <= Maximum;
   end Feasible;

   function Count_Choices (K : Count; N : Target) return Natural is
   begin
      if Feasible (K, N) then
         return 1;
      else
         return 0;
      end if;
   end Count_Choices;
end Combination_Sum_III;
