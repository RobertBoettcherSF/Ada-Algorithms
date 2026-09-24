pragma Ada_2022;

package body Car_Pooling with SPARK_Mode => On is
   function Feasible (T : Trips; Limit : Capacity) return Boolean is
      Load : Capacity := 0;
   begin
      for I in Index loop
         pragma Loop_Invariant (Load <= Passengers'Last * (I - Index'First));
         Load := Load + T (I).People;
      end loop;
      return Load <= Limit;
   end Feasible;
end Car_Pooling;
