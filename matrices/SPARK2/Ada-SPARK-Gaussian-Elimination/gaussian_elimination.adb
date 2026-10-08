pragma Ada_2022;
package body Gaussian_Elimination with SPARK_Mode => On is
   function Eliminate (Augmented : Input_Matrix) return Reduced_Matrix is
      Result : Reduced_Matrix := [others => [others => 0]];
      --  row swap when the pivot is zero and the other row can supply one
      Swap : constant Boolean := Augmented (1, 1) = 0 and then Augmented (2, 1) /= 0;
      Top : constant Row := (if Swap then 2 else 1);
      Bottom : constant Row := (if Swap then 1 else 2);
      Pivot : constant Long_Long_Integer := Long_Long_Integer (Augmented (Top, 1));
      Factor : constant Long_Long_Integer := Long_Long_Integer (Augmented (Bottom, 1));
   begin
      for C in Column loop
         Result (1, C) := Long_Long_Integer (Augmented (Top, C));
      end loop;
      if Pivot = 0 then
         --  first column all zero: nothing to eliminate, keep the second equation
         for C in Column loop
            Result (2, C) := Long_Long_Integer (Augmented (Bottom, C));
         end loop;
      else
         Result (2, 1) := 0;
         for C in 2 .. Column'Last loop
            Result (2, C) := Long_Long_Integer (Augmented (Bottom, C)) * Pivot
              - Long_Long_Integer (Augmented (Top, C)) * Factor;
         end loop;
      end if;
      return Result;
   end Eliminate;
end Gaussian_Elimination;
