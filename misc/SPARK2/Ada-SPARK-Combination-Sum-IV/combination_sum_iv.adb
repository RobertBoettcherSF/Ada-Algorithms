pragma Ada_2022;

package body Combination_Sum_IV with SPARK_Mode => On is
   subtype Index is Natural range 0 .. 12;

   function Count_Ordered_Ways (N : Target) return Natural is
      Ways : array (Index) of Natural := (0 => 1, others => 0);
   begin
      if N >= 1 then
         for T in Index range 1 .. N loop
            Ways (T) := Ways (T - 1);
            if T >= 2 then
               Ways (T) := Ways (T) + Ways (T - 2);
            end if;
            if T >= 3 then
               Ways (T) := Ways (T) + Ways (T - 3);
            end if;
         end loop;
      end if;
      return Ways (N);
   end Count_Ordered_Ways;
end Combination_Sum_IV;
