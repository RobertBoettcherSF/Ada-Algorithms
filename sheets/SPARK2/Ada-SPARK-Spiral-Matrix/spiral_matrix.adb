pragma Ada_2022;

package body Spiral_Matrix with SPARK_Mode => On is
   function Traverse (Input : Matrix) return Sequence is
      Result : Sequence := (others => 0);
   begin
      Result (1) := Input (1, 1);
      Result (2) := Input (1, 2);
      Result (3) := Input (1, 3);
      Result (4) := Input (2, 3);
      Result (5) := Input (3, 3);
      Result (6) := Input (3, 2);
      Result (7) := Input (3, 1);
      Result (8) := Input (2, 1);
      Result (9) := Input (2, 2);
      return Result;
   end Traverse;
end Spiral_Matrix;
