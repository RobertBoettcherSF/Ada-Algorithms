pragma Ada_2022;
package body Gaussian_Elimination with SPARK_Mode => On is
   function Eliminate (Augmented : Input_Matrix) return Reduced_Matrix is
      Result : Reduced_Matrix := (others => (others => 0));
      Pivot : constant Long_Long_Integer := Long_Long_Integer (Augmented (1, 1));
      Factor : constant Long_Long_Integer := Long_Long_Integer (Augmented (2, 1));
   begin
      for C in Column loop
         Result (1, C) := Long_Long_Integer (Augmented (1, C));
      end loop;
      Result (2, 1) := 0;
      for C in 2 .. Column'Last loop
         Result (2, C) := Long_Long_Integer (Augmented (2, C)) * Pivot
           - Long_Long_Integer (Augmented (1, C)) * Factor;
      end loop;
      return Result;
   end Eliminate;
end Gaussian_Elimination;
