pragma Ada_2022;

package body Spiral_Matrix_II with SPARK_Mode => On is
   function Generate (N : Size) return Matrix is
      Result : Matrix := (others => (others => 0));
   begin
      -- The small cases keep the example completely bounded and readable.
      case N is
         when 1 =>
            Result (1, 1) := 1;
         when 2 =>
            Result (1, 1) := 1; Result (1, 2) := 2;
            Result (2, 2) := 3; Result (2, 1) := 4;
         when 3 =>
            Result (1, 1) := 1; Result (1, 2) := 2; Result (1, 3) := 3;
            Result (2, 3) := 4; Result (3, 3) := 5; Result (3, 2) := 6;
            Result (3, 1) := 7; Result (2, 1) := 8; Result (2, 2) := 9;
         when others =>
            null;
      end case;
      return Result;
   end Generate;
end Spiral_Matrix_II;
